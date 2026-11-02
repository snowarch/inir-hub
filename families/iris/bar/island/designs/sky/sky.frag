#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 dims;
    float sun;      // 0 at sunrise, 1 at sunset, past them under the horizon
    float moonAt;   // the same for the moon
    float phase;    // 0 new, .5 full
    float south;    // 1 under the equator: the lit side flips
    float pathFrom; // where the free sky starts and ends along the body
    float pathTo;
    float cover;    // cloud
    float rain;
    float snow;
    float fog;
    float storm;
    float wash;     // a light scheme lifts the whole painting so dark ink reads on it
    float drift;    // the clouds' place, moved once a minute
};

const float PI = 3.14159265;
float hash(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 6; i++) { v += a * noise(p); p = p * 2.03 + vec2(17.0, 9.0); a *= 0.5; }
    return v;
}
float along(float t) { return mix(pathFrom, pathTo, t) * dims.x; }

void main() {
    vec2 px = qt_TexCoord0 * dims;
    float H = dims.y;
    float up = 1.0 - qt_TexCoord0.y;
    float e = sin(PI * clamp(sun, -0.5, 1.5));
    if (sun < 0.0 || sun > 1.0) e = -abs(e);
    float dusk = smoothstep(-0.34, 0.0, e);
    float day = smoothstep(0.02, 0.46, e);

    vec3 top = mix(mix(vec3(0.016, 0.024, 0.075), vec3(0.075, 0.095, 0.260), dusk), vec3(0.030, 0.150, 0.430), day);
    vec3 mid = mix(mix(vec3(0.030, 0.048, 0.125), vec3(0.340, 0.200, 0.400), dusk), vec3(0.070, 0.270, 0.640), day);
    vec3 low = mix(mix(vec3(0.060, 0.085, 0.190), vec3(0.960, 0.470, 0.240), dusk), vec3(0.280, 0.550, 0.860), day);
    vec3 col = up > 0.45 ? mix(mid, top, (up - 0.45) / 0.55) : mix(low, mid, up / 0.45);

    vec2 sunAt = vec2(along(clamp(sun, 0.0, 1.0)), H * (0.92 - 0.66 * sin(PI * clamp(sun, 0.0, 1.0))));
    float warm = 1.0 - smoothstep(0.0, 0.5, e);
    float sunUp = smoothstep(-0.03, 0.03, sun) * (1.0 - smoothstep(0.97, 1.03, sun));

    // The light of a low sun lies along the horizon, far past its disc.
    float reach = abs(px.x - sunAt.x) / dims.x;
    col += vec3(1.0, 0.45, 0.16) * dusk * (1.0 - day) * exp(-reach * 3.4) * (1.0 - up) * (1.0 - up) * 0.75;

    vec2 q = vec2(px.x / H * 0.62 + drift, px.y / H * 1.5);
    float shape = fbm(q * 1.5);
    float edge = 1.0 - cover * 0.72 - 0.08;
    float cloud = smoothstep(edge, edge + 0.20, shape + up * 0.10) * step(0.01, cover);
    vec2 toSun = normalize(sunAt - px + vec2(0.001));
    float lit = clamp((shape - fbm((q + toSun * 0.11) * 1.5)) * 5.0 + 0.55, 0.0, 1.0);

    if (sunUp > 0.0) {
        float dist = length((px - sunAt) * vec2(0.7, 1.0));
        float r = H * 0.155;
        vec3 ink = mix(vec3(1.0, 0.975, 0.90), vec3(1.0, 0.62, 0.28), warm);
        float veil = 1.0 - 0.72 * cloud;
        col += ink * exp(-dist / (H * 0.55)) * 0.34 * sunUp * veil;
        col += ink * exp(-dist / (H * 0.18)) * 0.40 * sunUp * veil;
        col = mix(col, ink, (1.0 - smoothstep(r - 0.7, r + 0.7, length(px - sunAt))) * sunUp * (1.0 - 0.55 * cloud));
    }

    float star = step(0.986, hash(floor(px * 0.5))) * (0.35 + 0.65 * hash(floor(px * 0.5) + 3.0));
    col += vec3(0.84, 0.90, 1.0) * star * (1.0 - dusk) * (1.0 - cover) * smoothstep(0.1, 0.5, up);

    if (moonAt > 0.0 && moonAt < 1.0) {
        float r = H * 0.25;
        vec2 c = vec2(along(moonAt), H * (0.84 - 0.48 * sin(PI * moonAt)));
        vec2 m = (px - c) / r;
        float d = length(m);
        float seen = mix(1.0, 0.42, day);
        col += vec3(0.46, 0.52, 0.72) * exp(-d * 1.3) * 0.30 * (1.0 - day);
        if (d < 1.1) {
            float side = (phase < 0.5 ? m.x : -m.x) * (south > 0.5 ? -1.0 : 1.0);
            float k = cos(2.0 * PI * phase) * sqrt(max(0.0, 1.0 - m.y * m.y));
            float sunward = smoothstep(k - 0.09, k + 0.09, side);
            float maria = fbm(m * 2.4 + vec2(5.0, 2.0));
            vec3 ground = mix(vec3(0.97, 0.94, 0.84), vec3(0.62, 0.60, 0.56), smoothstep(0.42, 0.66, maria));
            vec3 limb = col + vec3(0.075, 0.09, 0.13) * (1.0 - day);
            float disc = 1.0 - smoothstep(0.97, 1.03, d);
            col = mix(col, mix(limb, ground, sunward * seen), disc);
        }
    }

    vec3 white = mix(mix(vec3(0.17, 0.19, 0.30), vec3(0.98, 0.62, 0.50), dusk), vec3(0.97, 0.98, 1.0), day);
    vec3 shade = mix(mix(vec3(0.07, 0.085, 0.15), vec3(0.34, 0.20, 0.34), dusk), vec3(0.58, 0.64, 0.74), day);
    float weight = smoothstep(0.55, 1.0, cover);
    vec3 body = mix(shade, white, mix(lit, lit * 0.45, weight));
    col = mix(col, body, cloud * 0.94);
    col = mix(col, col * vec3(0.46, 0.48, 0.58), storm);

    if (rain > 0.0) {
        vec2 r = vec2(px.x + px.y * 0.34, px.y * 0.11);
        float lane = floor(r.x / 2.0);
        float run = step(0.90, hash(vec2(lane, floor(r.y + hash(vec2(lane, 1.0)) * 7.0))));
        col = mix(col, vec3(0.74, 0.82, 0.94), run * 0.34 * rain * smoothstep(0.0, 0.4, 1.0 - up + 0.2));
    }
    if (snow > 0.0) {
        vec2 g = px / 5.0;
        vec2 o = vec2(hash(floor(g)), hash(floor(g) + 7.0));
        float flake = 1.0 - smoothstep(0.6, 1.4, length((fract(g) - o) * 5.0));
        col = mix(col, vec3(0.96, 0.97, 1.0), flake * step(0.72, hash(floor(g) + 2.0)) * 0.85 * snow);
    }
    if (fog > 0.0) {
        float bank = fbm(vec2(px.x / H * 0.42 + drift, up * 2.3)) * 0.65 + (1.0 - up) * 0.55;
        col = mix(col, mix(vec3(0.16, 0.18, 0.25), vec3(0.74, 0.77, 0.81), dusk * 0.5 + day * 0.5), clamp(bank, 0.0, 1.0) * 0.82 * fog);
    }

    // An overcast sky is a dark one, and the white time still reads on it.

    col *= 1.0 - 0.58 * cover * cover;

    col = mix(col, vec3(0.90, 0.925, 0.965), wash);
    col += (hash(px + 0.5) - 0.5) / 180.0;
    fragColor = vec4(col, 1.0) * qt_Opacity;
}
