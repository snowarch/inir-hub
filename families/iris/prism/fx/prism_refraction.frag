#version 440
// Prism's hero: a white beam enters from the lower left, meets a point and fans into the spectrum, with a frosted
// glass card over it that sees the same light blurred and bent. One static pass, drawn only when its size changes.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;        // px
    vec4 beam;        // origin x, y, prism x, y (px)
    vec4 fan;         // spread (rad), length (px), intensity, turn (rad)
    vec4 glass;       // card x, y, w, h (px)
    vec4 glassLook;   // card radius, bend, frost, opacity
    vec4 bg;          // the black under the light
    float radius;     // the hero's own corners
    float grain;
} u;

const vec3 STOPS[7] = vec3[7](
    vec3(0.835, 0.094, 0.992), // #D518FD
    vec3(0.478, 0.604, 0.992), // #7A9AFD
    vec3(0.259, 0.537, 0.992), // #4289FD
    vec3(0.149, 0.878, 0.200), // #26E033
    vec3(0.996, 0.949, 0.239), // #FEF23D
    vec3(0.992, 0.565, 0.090), // #FD9017
    vec3(0.992, 0.078, 0.263)  // #FD1443
);

vec3 spectrum(float s) {
    float x = clamp(s, 0.0, 1.0) * 6.0;
    int i = int(floor(x));
    if (i >= 6) return STOPS[6];
    return mix(STOPS[i], STOPS[i + 1], smoothstep(0.0, 1.0, fract(x)));
}

float roundedBox(vec2 p, vec2 half_, float r) {
    vec2 q = abs(p) - half_ + vec2(r);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// The light at a point; soft > 1 widens every falloff (the glass's frost).
vec3 field(vec2 q, float soft) {
    vec2 o = u.beam.xy;
    vec2 p = u.beam.zw;
    vec2 axis = p - o;
    float len = length(axis);
    vec2 dir = axis / max(len, 1.0);

    // The beam: a tight white core and a wide glow, fading in from where it enters.
    float t = clamp(dot(q - o, dir) / len, 0.0, 1.0);
    float d = length(q - (o + dir * t * len));
    float core = exp(-d * d / (2.0 * pow(1.6 * soft, 2.0)));
    float glow = exp(-d / (14.0 * soft)) * 0.42;
    float enter = smoothstep(0.0, 0.35, t);
    vec3 light = vec3(core + glow) * enter * step(dot(q - p, dir), 0.0);

    // The fan: past the point, each angle a colour, white at the start and coloured further out.
    float c = cos(u.fan.w), s = sin(u.fan.w);
    vec2 fdir = vec2(dir.x * c - dir.y * s, dir.x * s + dir.y * c);
    vec2 v = q - p;
    float along = dot(v, fdir);
    float across = fdir.x * v.y - fdir.y * v.x;
    float angle = atan(across, max(along, 1e-3));
    float half_ = u.fan.x * 0.5;
    float edge = 0.05 * soft;
    float inside = smoothstep(half_ + edge, half_ - edge, abs(angle)) * step(0.0, along);
    float band = angle / u.fan.x + 0.5;
    float reach = exp(-max(along, 0.0) / u.fan.y);
    float whiten = 1.0 - smoothstep(0.0, u.fan.y * 0.28, along);
    vec3 colour = mix(spectrum(band), vec3(1.0), whiten * 0.85);
    // The ray at the fan's heart carries on, brighter than the rest.
    float spine = exp(-abs(across) / (3.0 * soft + along * 0.02)) * 0.55 * step(0.0, along) * reach;
    light += colour * inside * reach * u.fan.z + vec3(spine);

    // Plus-lighter flares where the beam breaks: one wide oval, one tight.
    vec2 f = q - p;
    float flare = exp(-(pow(f.x / (60.0 * soft), 2.0) + pow(f.y / (22.0 * soft), 2.0))) * 0.6;
    float hot = exp(-dot(f, f) / pow(5.0 * soft, 2.0)) * 1.2;
    light += vec3(0.86, 0.90, 1.0) * flare + vec3(hot);
    return light;
}

vec3 tone(vec3 x) { return vec3(1.0) - exp(-x * 1.25); }

void main() {
    vec2 q = qt_TexCoord0 * u.size;
    vec3 col = u.bg.rgb + tone(field(q, 1.0));

    // The glass card: the same light frosted and bent toward its middle, a faint white wash from its top-left,
    // an edge lit on the side the light comes from, and finer grain.
    vec2 centre = u.glass.xy + u.glass.zw * 0.5;
    float card = roundedBox(q - centre, u.glass.zw * 0.5, u.glassLook.x);
    float inCard = 1.0 - smoothstep(-0.75, 0.75, card);
    if (inCard > 0.0) {
        vec2 bent = q + (centre - q) * u.glassLook.y;
        vec3 frosted = u.bg.rgb * 0.6 + tone(field(bent, u.glassLook.z)) * 0.82;
        vec2 rel = (q - u.glass.xy) / u.glass.zw;
        float wash = exp(-dot(rel, rel) * 1.6) * 0.16;
        frosted += vec3(wash) + vec3(0.05);
        float rim = 1.0 - smoothstep(0.0, 1.4, abs(card + 0.7));
        float lit = mix(0.9, 0.14, clamp((rel.x + rel.y) * 0.5, 0.0, 1.0));
        frosted += vec3(rim * lit * 0.55);
        frosted += (hash(q * 1.7) - 0.5) * 0.05;
        col = mix(col, frosted, inCard * u.glassLook.w);
    } else {
        // Its shadow on the light behind.
        float shade = exp(-max(card, 0.0) / 18.0) * 0.28;
        col *= 1.0 - shade;
    }

    col += (hash(q + 17.0) - 0.5) * u.grain;
    float outer = roundedBox(q - u.size * 0.5, u.size * 0.5, u.radius);
    float a = (1.0 - smoothstep(-0.75, 0.75, outer)) * u.qt_Opacity;
    fragColor = vec4(clamp(col, 0.0, 1.0) * a, a);
}
