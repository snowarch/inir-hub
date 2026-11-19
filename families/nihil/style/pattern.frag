#version 440
// NiHiL's pattern: what the overview can stand on. Matte black with film grain and a vignette, lit by one source.
// pattern 0 beam (white light entering from a corner and opening into its colours), 1 fluted (light seen through ribbed
// glass, as vertical streaks), 2 haze (a low spectral glow under the black), 3 void (grain and vignette only).
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 box;
    float seed;
    float pattern;
    float grain;
    float glow;
    float rainbow;
    vec4 base;
    vec4 highlight;
    vec4 highlightTint;
};
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
float noise(float x) {
    float i = floor(x), f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(hash(vec2(i, seed * 91.0)), hash(vec2(i + 1.0, seed * 91.0)), f);
}
vec3 spectrum(float t) {
    t = clamp(t, 0.0, 1.0);
    vec3 hue = clamp(abs(fract(vec3(0.0, 0.6667, 0.3333) + t * 0.82 + 0.02) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
    vec3 duo = t < 0.5 ? mix(highlight.rgb, vec3(0.95), t * 2.0) : mix(vec3(0.95), highlightTint.rgb, t * 2.0 - 1.0);
    return mix(duo, hue, rainbow);
}
void main() {
    vec2 uv = qt_TexCoord0;
    vec2 p = uv * box;
    float aspect = box.x / max(box.y, 1.0);
    vec3 col = base.rgb;

    // The paper: a faint lift in the middle, the corners falling to black.
    vec2 q = (uv - 0.5) * vec2(aspect, 1.0);
    col += vec3(0.035) * exp(-dot(q, q) * 2.2);

    if (pattern < 0.5) {
        // Beam: from a point above the left third, slanting down to the right, widening into colour.
        vec2 src = vec2(mix(0.08, 0.42, fract(seed * 3.7)), -0.08);
        vec2 dir = normalize(vec2(0.78, 0.62));
        vec2 rel = (uv - src) * vec2(aspect, 1.0);
        float along = dot(rel, dir);
        float across = dot(rel, vec2(-dir.y, dir.x));
        float widen = 0.006 + max(along, 0.0) * 0.16;
        float t = across / widen * 0.5 + 0.5;
        float inBeam = smoothstep(-0.2, 0.25, t) * smoothstep(1.2, 0.75, t) * step(0.0, along);
        float fade = exp(-max(along, 0.0) * 1.1);
        col += spectrum(t) * inBeam * fade * 0.34 * glow;
        // The white core where it enters, and a bloom at the source.
        col += vec3(1.0) * exp(-abs(across) / (0.004 + along * 0.02)) * exp(-along * 3.0) * 0.25 * glow * step(0.0, along);
        vec2 s = rel;
        col += vec3(0.9) * exp(-dot(s, s) * 160.0) * 0.35 * glow;
    } else if (pattern < 1.5) {
        // Fluted: tall streaks of light through ribs, coloured at their edges, strongest on one side.
        float ribW = 0.018 + fract(seed * 5.3) * 0.01;
        float x = uv.x / ribW;
        float ph = fract(x);
        float rib = floor(x);
        float lens = pow(sin(ph * 3.14159), 6.0);
        float side = smoothstep(0.3, 1.0, uv.x) * (0.4 + 0.6 * noise(rib * 0.7));
        float vertical = smoothstep(0.0, 0.25, uv.y) * smoothstep(1.0, 0.55, uv.y) + 0.35 * smoothstep(0.65, 1.0, uv.y);
        float hueT = fract(rib * 0.031 + seed + uv.y * 0.4);
        col += spectrum(hueT) * lens * side * vertical * 0.22 * glow;
        col += vec3(0.8) * pow(lens, 4.0) * side * vertical * 0.08 * glow;
    } else if (pattern < 2.5) {
        // Haze: a slow wash of colour pooled low, as light behind frosted glass.
        vec2 h = (uv - vec2(0.5 + (seed - 0.5) * 0.6, 1.05)) * vec2(aspect * 0.6, 1.4);
        float pool = exp(-dot(h, h) * 2.0);
        col += spectrum(fract(uv.x * 0.8 + seed)) * pool * 0.2 * glow;
    }

    // Vignette and grain, always.
    col *= 1.0 - smoothstep(0.55, 1.25, length(q)) * 0.55;
    col += (hash(floor(p) + 0.5) - 0.5) * (0.06 + grain * 0.06);
    fragColor = vec4(max(col, 0.0), 1.0) * qt_Opacity;
}
