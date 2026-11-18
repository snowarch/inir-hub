#version 440
// Light streak over a surface IrisField does not draw (desktop widgets, IrisSurface): the field's aurora and the streak
// on the edges that face the light under the Island, sampled where the plate sits on its output, laid over the plate's
// own fill. Static: it draws again only when its window does.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    // Same encoding as IrisField.frag.
    vec4 streakMix;
    vec4 streakHue0; vec4 streakHue1; vec4 streakHue2;
    // xy: the light on the output; z: one device pixel; w: the fall's reach (px).
    vec4 streakSource;
    // xy: the plate's top-left on its output, zw: the output's size, in pixels.
    vec4 plate;
    // xy: the plate's size.
    vec4 body;
    // Corner radii: top-left, top-right, bottom-right, bottom-left.
    vec4 corners;
    // The plate's own colour, not premultiplied: what the aurora is held against.
    vec4 tone;
} u;

float roundedCorner(vec2 p, vec2 halfSize, vec4 r) {
    float radius = p.x < 0.0 ? (p.y < 0.0 ? r.x : r.w) : (p.y < 0.0 ? r.y : r.z);
    radius = min(radius, min(halfSize.x, halfSize.y));
    vec2 q = abs(p) - halfSize + radius;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

// Copy of IrisField.frag's: change both.
vec3 streakCurtains(vec2 q, vec2 size, out float glow) {
    vec3 sum = vec3(0.0);
    float weight = 0.0;
    for (int k = 0; k < 3; ++k) {
        vec4 h = k == 0 ? u.streakHue0 : (k == 1 ? u.streakHue1 : u.streakHue2);
        float fk = float(k);
        float down = q.y / size.y;
        float sway = 0.07 * sin(down * 3.4 + fk * 2.1) + 0.025 * sin(down * 9.0 - fk * 1.7);
        float x = (q.x / size.x - h.w - sway) / 0.2;
        float rays = 0.74 + 0.26 * sin(q.x * 0.031 + fk * 1.3 + 2.2 * sin(q.y * 0.0037 + fk));
        float c = exp(-x * x) * rays;
        sum += h.rgb * c;
        weight += c;
    }
    glow = clamp(weight, 0.0, 1.0);
    return sum / max(weight, 1e-3);
}

void main() {
    vec2 size = max(u.body.xy, vec2(1.0));
    vec2 local = qt_TexCoord0 * size;
    vec2 screen = max(u.plate.zw, vec2(1.0));
    vec2 q = u.plate.xy + local;
    float d = roundedCorner(local - size * 0.5, size * 0.5, u.corners);
    // Analytic slope of the box: the outward normal.
    float e = 0.5;
    vec2 grad = vec2(roundedCorner(local + vec2(e, 0.0) - size * 0.5, size * 0.5, u.corners) - roundedCorner(local - vec2(e, 0.0) - size * 0.5, size * 0.5, u.corners),
        roundedCorner(local + vec2(0.0, e) - size * 0.5, size * 0.5, u.corners) - roundedCorner(local - vec2(0.0, e) - size * 0.5, size * 0.5, u.corners));
    vec2 outward = grad / max(length(grad), 1e-4);
    float coverage = 1.0 - smoothstep(-0.7, 0.7, d);
    if (coverage <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }
    const vec3 lumaW = vec3(0.2126, 0.7152, 0.0722);
    float reach = max(1.0, u.streakSource.w);
    float px = max(u.streakSource.z, 0.05);
    float glow;
    vec3 hue = streakCurtains(q, screen, glow);
    vec2 toward = u.streakSource.xy - q;
    float dist = length(toward);
    float diag = length(screen);
    // Two lights. The lamp under the Island is the brightest thing on screen and falls off fast; its sky is Apple's top
    // edge, a thin even light on every edge turned toward the Island, so the Dock and a panel over the lamp keep a horizon.
    vec2 sky = u.streakSource.xy - screen * 0.5;
    float lamp = smoothstep(0.0, 0.85, dot(outward, toward / max(dist, 1e-3)));
    float skyward = smoothstep(0.2, 0.95, dot(outward, sky / max(length(sky), 1e-3)));
    float facing = max(lamp, 0.6 * skyward);
    float away = smoothstep(0.1, -0.7, max(dot(outward, toward / max(dist, 1e-3)), dot(outward, sky / max(length(sky), 1e-3))));
    float taper = 0.2 + 0.8 * exp(-dist / (0.2 * diag));
    float depth = max(0.0, -d);
    float lightAmt = u.streakMix.z * (lamp * taper + 0.42 * skyward);
    float auroraAmt = u.streakMix.y * (0.35 + 0.65 * glow) * taper;
    vec3 base = u.tone.rgb;
    float baseLum = dot(base * base, lumaW);
    bool paper = baseLum > 0.25;
    float rim = exp(-depth / (reach * 0.22)) * (0.3 + 0.7 * facing);
    float deep = exp(-depth / (reach * 1.2)) * 0.25 * glow;
    // Laid over the fill: a light plate takes the aurora as a pastel tint, a dark one as light held under what its ink
    // reads on; the edge away from the light darkens.
    vec4 over;
    if (paper) {
        float a = min(1.0, auroraAmt * (rim * 0.8 + deep)) * 0.45;
        over = vec4(base * hue * 1.35 * a, a);
    } else {
        float headroom = clamp((0.2 - baseLum) / 0.2, 0.25, 1.0);
        over = vec4(hue * auroraAmt * (rim * 1.1 + deep * 0.35) * headroom, 0.0);
    }
    float dark = 0.35 * away * u.streakMix.z * exp(-depth / (reach * 0.08));
    over = vec4(0.0, 0.0, 0.0, dark) + over * (1.0 - dark);
    float hot = clamp((1.0 - smoothstep(0.6 * px, (1.0 + 1.9 * taper) * px, depth)) * lightAmt * 1.7, 0.0, 1.0);
    over = vec4(mix(hue, vec3(1.0), 0.65) * hot, hot) + over * (1.0 - hot);
    fragColor = over * coverage * u.qt_Opacity * u.tone.a;
}
