#version 440
// The sheet. One signed distance holds the band, the slab and the tags, welded with polynomial coves; `limbP` bends the
// band into the limb of a dark disc. The contour is one lit line, and one light travels along it: a hot point with a bloom
// to each side and a short anamorphic streak. Everything is measured from the edge the sheet hangs from.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 area;
    float flip;
    float band;
    float fuse;
    float slabR;
    float tagR;
    vec4 slab;
    vec4 tagA;
    vec4 tagB;
    vec2 hot;
    float reach;
    float power;
    vec4 aurora;
    float auroraP;
    float limbP;
    float limbY;
    float limbR;
    float rim;
    float flare;
    float grain;
    float veil;
    vec4 tint;
    vec4 voidInk;
    vec4 rimInk;
    vec4 specA;
    vec4 specB;
};

float box(vec2 p, vec4 r, float radius) {
    vec2 half_ = r.zw * 0.5;
    vec2 q = abs(p - r.xy - half_) - half_ + radius;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}
float smin(float a, float b, float k) {
    if (k < 0.001) return min(a, b);
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}
// A body pulled out of the band: its coves and corners shrink with what is out, so it leaves no bump when it folds away.
float weld(float d, vec2 p, vec4 r, float radius) {
    float out_ = r.y + r.w - band;
    if (out_ <= 0.25 || r.z <= 0.5) return d;
    return smin(d, box(p, r, min(radius, min(r.z * 0.5, out_))), min(fuse, out_ * 0.8));
}
vec3 straight(vec4 c) { return c.a > 0.0001 ? c.rgb / c.a : c.rgb; }
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void main() {
    vec2 p = vec2(qt_TexCoord0.x, flip > 0.5 ? 1.0 - qt_TexCoord0.y : qt_TexCoord0.y) * area;

    float d = p.y - band;
    d = weld(d, p, slab, slabR);
    d = weld(d, p, tagA, tagR);
    d = weld(d, p, tagB, tagR);
    if (limbP > 0.0) {
        float disc = limbR - length(p - vec2(area.x * 0.5, limbY + limbR));
        d = mix(d, disc, limbP);
    }

    float inside = smoothstep(0.8, -0.8, d);
    float away = max(d, 0.0);

    // Under the sheet: a soft shade on the desktop, or the dark of the disc.
    float shadeA = exp(-away / 46.0) * 0.26 * (1.0 - limbP) * veil;
    vec3 rgb = voidInk.rgb * limbP;
    float a = max(shadeA, limbP);

    vec3 body = straight(tint);
    float bodyA = tint.a * veil;
    body += (hash(floor(gl_FragCoord.xy) + 0.5) - 0.5) * grain * 0.035;

    vec2 toHot = p - hot;
    float heat = exp(-dot(toHot, toHot) / (reach * reach)) * power;
    vec3 ink = mix(specA.rgb, specB.rgb, smoothstep(-reach, reach, toHot.x));

    vec3 lit = body * bodyA;
    if (auroraP > 0.0) {
        float up = (aurora.y - p.y) / max(aurora.w, 1.0);
        float across = (p.x - aurora.x) / max(aurora.z, 1.0);
        float rise = exp(-up * up) * exp(-across * across) * auroraP * step(p.y, aurora.y + 2.0);
        vec3 tone = mix(specA.rgb, specB.rgb, smoothstep(-1.0, 1.0, across));
        lit += tone * rise * 0.5;
        bodyA = min(1.0, bodyA + rise * 0.3);
    }
    rgb = mix(rgb, lit, inside);
    a = mix(a, bodyA, inside);

    float outer = exp(-away / 30.0) * step(0.0, d) * heat * veil;
    float inner = exp(min(d, 0.0) / 16.0) * step(d, 0.0) * heat * veil;
    float edge = exp(-d * d / 1.1) * veil;
    float streak = exp(-toHot.y * toHot.y / 1.7) * exp(-pow(toHot.x / (reach * 0.62), 2.0)) * power * flare * veil;

    vec3 light = ink * (outer * 0.34 + inner * 0.42) * flare;
    light += rimInk.rgb * edge * rim;
    light += (ink * 0.9 + 0.5) * edge * heat * 1.25 * rim;
    light += (ink * 0.5 + 0.5) * streak * 0.55;

    rgb += light;
    a = clamp(max(a + (outer * 0.2 + edge * rimInk.a * rim + edge * heat + streak * 0.5) * (1.0 - a), max(rgb.r, max(rgb.g, rgb.b))), 0.0, 1.0);
    fragColor = vec4(rgb, a) * qt_Opacity;
}
