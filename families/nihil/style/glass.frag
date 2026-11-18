#version 440
// NiHiL's one material: tinted glass with grain, a chromatic rim lit from one point, and a flare where that light lands.
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
    vec4 tint;
    vec4 rimA;
    vec4 rimB;
    vec4 flareA;
    vec4 flareB;
};
float rounded(vec2 p, vec2 half_, float r) {
    vec2 q = abs(p) - half_ + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float band(float d) { return smoothstep(1.5, 0.0, abs(d)); }
void main() {
    vec2 p = qt_TexCoord0 * (box + 2.0 * pad) - pad;
    vec2 c = box * 0.5;
    float r = min(radius, min(c.x, c.y));
    float d = rounded(p - c, c, r);
    float inside = smoothstep(0.75, -0.75, d);

    vec2 toLight = p - lightAt;
    float reach = max(box.x, box.y) * 0.5 + 1.0;
    float bloom = exp(-dot(toLight, toLight) / (reach * reach));
    float streak = exp(-abs(toLight.y) / (box.y * 0.07 + 2.0)) * exp(-abs(toLight.x) / (box.x * 0.6 + 1.0));
    float power = flare + ignite * 0.8;
    vec3 flareInk = mix(flareA.rgb, flareB.rgb, clamp(length(toLight) / reach, 0.0, 1.0));
    vec3 body = tint.rgb + flareInk * (bloom * 0.34 + streak * 0.22) * power;
    body += vec3(0.05) * pow(1.0 - clamp(p.y / box.y, 0.0, 1.0), 3.0);
    body += (hash(floor(gl_FragCoord.xy)) - 0.5) * grain * 0.1;
    float bodyAlpha = clamp(tint.a + (bloom * 0.2 + streak * 0.14) * power, 0.0, 1.0);

    vec2 out_ = normalize(p - c + 0.0001);
    vec2 lightDir = normalize(lightAt - c + 0.0001);
    float lit = 0.3 + 0.7 * max(0.0, dot(out_, lightDir));
    float edge = rim * lit * (1.0 + ignite);
    vec3 rimInk = vec3(band(d + 0.8) * rimA.r, band(d) * mix(rimA.g, rimB.g, 0.5), band(d - 0.8) * rimB.b) * edge;
    float rimAlpha = band(d) * clamp(edge, 0.0, 1.0);

    float drop = (1.0 - inside) * exp(-max(d, 0.0) / (pad * 0.42 + 1.0)) * 0.42 * shadow;
    vec3 rgb = body * inside + rimInk;
    float alpha = max(bodyAlpha * inside, rimAlpha);
    alpha = alpha + drop * (1.0 - alpha);
    fragColor = vec4(rgb, alpha) * qt_Opacity;
}
