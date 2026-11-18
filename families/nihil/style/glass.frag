#version 440
// NiHiL's glass. A graphite sheet over the blur with a faint grain, a specular line along its top edge, a hairline rim
// and, on what is active, a soft light rising from its bottom edge in the palette's two colours. `form` shapes the
// body: 0 smoke, 1 frost, 2 fluted (vertical reeds), 3 prism (a beam crossing the sheet from the light).
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 box;
    vec2 lightAt;
    float pad;
    float radius;
    float rim;
    float flare;
    float grain;
    float ignite;
    float shadow;
    float form;
    float ribs;
    vec4 tint;
    vec4 specA;
    vec4 specB;
};

float rounded(vec2 p, vec2 half_, float r) {
    vec2 q = abs(p) - half_ + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void main() {
    vec2 p = qt_TexCoord0 * (box + 2.0 * pad) - pad;
    vec2 c = box * 0.5;
    float r = min(radius, min(c.x, c.y));
    float d = rounded(p - c, c, r);
    float inside = smoothstep(0.6, -0.6, d);
    vec2 uv = clamp(p / max(box, vec2(1.0)), 0.0, 1.0);

    vec3 body = tint.rgb;
    float bodyAlpha = tint.a;
    // A sheet under a lamp: a touch brighter at the top.
    body += vec3(0.03) * pow(1.0 - uv.y, 2.0);

    // The pointer's light, when the piece tracks it.
    vec2 toLight = p - lightAt;
    float reach = max(box.x, box.y) * 0.55 + 1.0;
    float near = exp(-dot(toLight, toLight) / (reach * reach));
    body += vec3(0.035) * near * flare;

    // The glow from the bottom edge: wide and low, warmer at one side, cooler at the other.
    float power = flare * 0.22 + ignite;
    float fromBottom = (box.y - p.y) / max(box.y, 1.0);
    float across = (uv.x - 0.5) * 2.0;
    float glow = exp(-fromBottom * fromBottom * 9.0) * exp(-across * across * 0.9);
    vec3 glowInk = mix(specA.rgb, specB.rgb, uv.x);
    body += glowInk * glow * 0.42 * power;
    bodyAlpha = min(1.0, bodyAlpha + glow * 0.18 * power);

    if (form > 0.5 && form < 1.5) {
        // Frost: paler, the grain a little coarser.
        body = mix(body, vec3(0.55), 0.06);
        bodyAlpha = min(1.0, bodyAlpha + 0.06);
    } else if (form > 1.5 && form < 2.5) {
        // Fluted: each reed a lens, lit on its upper half.
        float w = max(ribs, 3.0);
        float ph = fract(p.x / w);
        body += vec3(0.035) * sin(ph * 3.14159) * (0.5 + 0.5 * (1.0 - uv.y));
        body -= vec3(0.03) * smoothstep(0.92, 1.0, ph);
    } else if (form > 2.5) {
        // Prism: a soft beam from the light, opening into the palette's two colours.
        vec2 dir = normalize(vec2(0.82, 0.57));
        vec2 nrm = vec2(-dir.y, dir.x);
        float along = dot(toLight, dir);
        float side = dot(toLight, nrm);
        float widen = 8.0 + max(along, 0.0) * 0.3;
        float t = side / widen * 0.5 + 0.5;
        float beam = smoothstep(0.0, 0.3, t) * smoothstep(1.0, 0.7, t) * step(0.0, along);
        beam *= exp(-max(along, 0.0) / (reach * 1.4));
        body += mix(specA.rgb, specB.rgb, t) * beam * 0.22 * (flare + ignite);
    }

    body += (hash(floor(gl_FragCoord.xy) + 0.5) - 0.5) * grain * (form > 0.5 && form < 1.5 ? 0.06 : 0.035);

    // Rim: a hairline, brightest where the edge faces up, plus a faint coloured lift where the glow touches it.
    vec2 outward = normalize(p - c + 0.0001);
    float up = max(0.0, -outward.y);
    float band = smoothstep(1.0, 0.0, abs(d + 0.5));
    float rimLight = rim * (0.07 + 0.3 * pow(up, 2.0));
    vec3 rimInk = vec3(rimLight) + glowInk * glow * power * 0.5 * rim;
    float rimAlpha = band * clamp(rimLight + glow * power * 0.4, 0.0, 1.0);

    float drop = (1.0 - inside) * exp(-max(d, 0.0) / (pad * 0.34 + 1.0)) * 0.42 * shadow;
    vec3 rgb = body * inside * bodyAlpha + rimInk * band;
    float alpha = max(bodyAlpha * inside, rimAlpha);
    alpha = alpha + drop * (1.0 - alpha);
    fragColor = vec4(rgb, alpha) * qt_Opacity;
}
