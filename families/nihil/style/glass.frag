#version 440
// NiHiL's glass. A smoked sheet with film grain, a hairline sheen on its top edge and a rim that splits light into its
// colours where the light falls. `form` shapes the body: 0 smoke, 1 frost, 2 fluted (vertical ribs that bend the light),
// 3 prism (a dispersed beam crossing the sheet from the light). `spark` is a four-point flare sitting on the light.
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
    float rainbow;
    float spark;
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
// t across the spectrum: the rainbow, or the palette's two lights with white between them.
vec3 spectrum(float t) {
    t = clamp(t, 0.0, 1.0);
    vec3 hue = clamp(abs(fract(vec3(0.0, 0.6667, 0.3333) + t * 0.82 + 0.02) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
    hue = mix(vec3(dot(hue, vec3(0.333))), hue, 0.86);
    vec3 duo = t < 0.5 ? mix(specA.rgb, vec3(0.96), t * 2.0) : mix(vec3(0.96), specB.rgb, t * 2.0 - 1.0);
    return mix(duo, hue, rainbow);
}

void main() {
    vec2 p = qt_TexCoord0 * (box + 2.0 * pad) - pad;
    vec2 c = box * 0.5;
    float r = min(radius, min(c.x, c.y));
    float d = rounded(p - c, c, r);
    float inside = smoothstep(0.6, -0.6, d);
    float power = flare + ignite * 0.9;

    vec2 toLight = p - lightAt;
    float reach = max(box.x, box.y) * 0.62 + 1.0;
    float bloom = exp(-dot(toLight, toLight) / (reach * reach));

    vec3 body = tint.rgb;
    float bodyAlpha = tint.a;
    // A slow fall of light from the top, the way a sheet held under a lamp reads.
    float fall = 1.0 - clamp(p.y / max(box.y, 1.0), 0.0, 1.0);
    body += vec3(0.035) * fall * fall;
    body += vec3(0.05) * bloom * power;

    if (form > 0.5 && form < 1.5) {
        // Frost: paler, the grain coarser.
        body = mix(body, vec3(0.62), 0.06);
        bodyAlpha = min(1.0, bodyAlpha + 0.05);
    } else if (form > 1.5 && form < 2.5) {
        // Fluted: each rib a lens, bright on the side toward the light, its edge fringed.
        float w = max(ribs, 3.0);
        float ph = fract(p.x / w);
        float lens = sin(ph * 3.14159);
        float side = (ph - 0.5) * sign(lightAt.x - p.x + 0.001);
        float lit = exp(-abs(p.x - lightAt.x) / (box.x * 0.38 + 1.0));
        body += vec3(0.05) * lens * (0.4 + 0.6 * fall);
        body += vec3(0.09) * max(side, 0.0) * lit * power;
        float edgeRib = smoothstep(0.9, 1.0, ph) + smoothstep(0.1, 0.0, ph);
        body += spectrum(fract(p.x / (w * 7.0) + p.y / box.y * 0.3)) * edgeRib * lit * 0.16 * power;
    } else if (form > 2.5) {
        // Prism: a beam leaves the light at a slant and opens into its colours across the sheet.
        vec2 dir = normalize(vec2(0.82, 0.57));
        vec2 nrm = vec2(-dir.y, dir.x);
        float along = dot(toLight, dir);
        float across = dot(toLight, nrm);
        float widen = 6.0 + max(along, 0.0) * 0.32;
        float t = across / widen * 0.5 + 0.5;
        float beam = smoothstep(0.0, 0.15, t) * smoothstep(1.0, 0.85, t) * step(0.0, along);
        beam *= exp(-max(along, 0.0) / (reach * 1.6));
        body += spectrum(t) * beam * 0.42 * power;
        bodyAlpha = min(1.0, bodyAlpha + beam * 0.12 * power);
    }

    float g = hash(floor(gl_FragCoord.xy) + 0.5) - 0.5;
    body += g * grain * (form > 0.5 && form < 1.5 ? 0.11 : 0.075);

    // The rim: three thin bands, one per colour, pushed apart where the light hits.
    vec2 outward = normalize(p - c + 0.0001);
    vec2 lightDir = normalize(lightAt - c + 0.0001);
    float facing = max(0.0, dot(outward, lightDir));
    float lit = 0.18 + 0.82 * pow(facing, 1.6);
    float split = 0.7 + 1.6 * facing * rim;
    float bandR = smoothstep(1.1, 0.0, abs(d + split));
    float bandG = smoothstep(1.1, 0.0, abs(d));
    float bandB = smoothstep(1.1, 0.0, abs(d - split));
    float hueAt = fract(atan(outward.y, outward.x) / 6.2832 + 0.5);
    vec3 fringe = spectrum(hueAt);
    vec3 rimInk = mix(vec3(bandG), vec3(bandR, bandG, bandB) * (0.55 + 0.45 * fringe) * 1.4, clamp(rim, 0.0, 1.0));
    float edge = rim * lit * (0.55 + ignite * 0.9);
    rimInk *= edge;
    float rimAlpha = max(max(bandR, bandG), bandB) * clamp(edge, 0.0, 1.0);

    // Sheen: one bright hairline just inside the top edge.
    float sheen = smoothstep(1.2, 0.0, abs(d + 1.4)) * smoothstep(c.y * 0.9, 0.0, p.y) * 0.22;
    body += vec3(sheen);

    // Four-point flare on the light.
    vec2 s = toLight;
    float star = 0.0;
    if (spark > 0.0) {
        float k = 0.9 / (spark + 0.01);
        star = exp(-abs(s.x) * 0.05 * k) * exp(-abs(s.y) * 1.1 * k)
             + exp(-abs(s.y) * 0.05 * k) * exp(-abs(s.x) * 1.1 * k);
        star += exp(-dot(s, s) / (60.0 * spark * spark + 1.0)) * 0.8;
        star *= spark;
    }

    float drop = (1.0 - inside) * exp(-max(d, 0.0) / (pad * 0.38 + 1.0)) * 0.5 * shadow;
    vec3 rgb = body * inside + rimInk + vec3(star);
    float alpha = max(bodyAlpha * inside, max(rimAlpha, clamp(star, 0.0, 1.0)));
    alpha = alpha + drop * (1.0 - alpha);
    rgb = rgb * (alpha > 0.0 ? 1.0 : 0.0);
    fragColor = vec4(rgb, alpha) * qt_Opacity;
}
