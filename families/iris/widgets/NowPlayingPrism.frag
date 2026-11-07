#version 440
// Prism, the Now Playing face's body (NowPlayingPrism.qml): a folder of frosted glass. Its dark tab carries the player;
// beside it a shorter flap lit in the song's colour holds the hour; a clearer pane of glass laid across the whole width
// holds the song; the folder's foot runs under it. One beam of white light enters low on the left, breaks on the pane
// into its spectrum and fans out to the upper right, seen diffused through the frost (more through the pane than through
// the body). Grain on the glass, a rim lit from above, the folder's shadow on the desktop and the pane's on the folder.
// Static: it draws again only when a value changes.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    // xy: the face's size; zw: how far this item reaches past the face on each side (shadow and glow room).
    vec4 frame;
    // x: the lit flap's right edge; y: the tab's right edge; z: the flap's top; w: one device pixel in item units.
    vec4 folder;
    // x: the body's corners; y: the tab's top right; z: the flap's top right; w: the pane's corners.
    vec4 radii;
    // The pane: left, top, right, bottom.
    vec4 pane;
    // xy: where the white beam enters; zw: where it breaks into colour.
    vec4 beam;
    // x: the fan's direction (radians, screen y down); y: its half spread; z: how much light passes (0 paused,
    // 1 playing); w: 1 for white light only (Nothing).
    vec4 fan;
    // The body's own colour, not premultiplied.
    vec4 tone;
    // The flap's colour (the song's), not premultiplied; a: how far it glows.
    vec4 shelf;
    // x: 1 on a light scheme (paper glass); y: 1 when frost is lent (glass material); z: grain; w: shadow strength.
    vec4 look;
} u;
layout(binding = 1) uniform sampler2D frost;

float box(vec2 p, vec4 rect, vec4 r) {
    vec2 c = (rect.xy + rect.zw) * 0.5;
    vec2 h = (rect.zw - rect.xy) * 0.5;
    vec2 q0 = p - c;
    // top-left, top-right, bottom-right, bottom-left
    float radius = q0.x < 0.0 ? (q0.y < 0.0 ? r.x : r.w) : (q0.y < 0.0 ? r.y : r.z);
    radius = min(radius, min(h.x, h.y));
    vec2 q = abs(q0) - h + radius;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

// The union with a fillet: where the tab steps down to the shelf the edge turns in a smooth S, as a folder's does.
float smoothUnion(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// x: the folder's outline; y: the dark tab; z: the lit flap.
vec3 metrics(vec2 p) {
    vec2 size = u.frame.xy;
    float R = u.radii.x;
    float tabD = box(p, vec4(0.0, 0.0, u.folder.y, size.y), vec4(R, u.radii.y, R, R));
    float flapD = box(p, vec4(u.folder.y - R, u.folder.z, u.folder.x, size.y), vec4(R, u.radii.z, R, R));
    // The foot under the pane, the whole width (its top is hidden by the pane).
    float footD = box(p, vec4(0.0, 0.5 * (u.pane.y + u.pane.w), size.x, size.y), vec4(R));
    return vec3(min(smoothUnion(tabD, flapD, u.radii.y * 0.6), footD), tabD, flapD);
}

// The beam's seven colours (a prism's spectrum is the same in every theme and scheme).
vec3 spectrum(float t) {
    const vec3 c0 = vec3(0.835, 0.086, 0.992); // iris-literal: #D516FD, the spectrum's violet
    const vec3 c1 = vec3(0.475, 0.267, 0.992); // iris-literal: #7944FD
    const vec3 c2 = vec3(0.259, 0.537, 0.992); // iris-literal: #4289FD
    const vec3 c3 = vec3(0.149, 0.878, 0.200); // iris-literal: #26E033
    const vec3 c4 = vec3(0.996, 0.949, 0.239); // iris-literal: #FEF23D
    const vec3 c5 = vec3(0.992, 0.412, 0.090); // iris-literal: #FD6917
    const vec3 c6 = vec3(0.992, 0.078, 0.263); // iris-literal: #FD1443, the spectrum's red
    float x = clamp(t, 0.0, 1.0) * 6.0;
    vec3 a = x < 1.0 ? c0 : x < 2.0 ? c1 : x < 3.0 ? c2 : x < 4.0 ? c3 : x < 5.0 ? c4 : c5;
    vec3 b = x < 1.0 ? c1 : x < 2.0 ? c2 : x < 3.0 ? c3 : x < 4.0 ? c4 : x < 5.0 ? c5 : c6;
    return mix(a, b, smoothstep(0.0, 1.0, fract(x)));
}

// The light at p: rgb as it adds, seen through frost of `blur` (px of softening).
vec3 light(vec2 p, float blur) {
    vec2 from = u.beam.xy;
    vec2 at = u.beam.zw;
    float scale = u.frame.y;
    // The white beam, entering to the break.
    vec2 seg = at - from;
    float t = clamp(dot(p - from, seg) / max(dot(seg, seg), 1e-3), 0.0, 1.0);
    float d = length(p - (from + seg * t));
    float core = 0.012 * scale + blur * 0.6;
    float white = exp(-(d * d) / (core * core)) * (0.55 + 0.45 * t) + 0.32 * exp(-d / (0.06 * scale + blur));
    vec3 sum = vec3(white);
    // The fan: forward of the break, its colour by angle, white where it leaves the pane and splitting with distance.
    vec2 v = p - at;
    float r = length(v);
    vec2 axis = vec2(cos(u.fan.x), sin(u.fan.x));
    float ahead = dot(v, axis);
    if (ahead > 0.0) {
        float side = (atan(v.y, v.x) - u.fan.x);
        side = atan(sin(side), cos(side));
        float k = side / max(u.fan.y, 1e-3);
        float soft = 0.18 + blur / max(r, 1.0);
        float inside = 1.0 - smoothstep(1.0 - soft, 1.0 + soft, abs(k));
        // Figma's second and third blurred copies: a wide soft bloom the colours spill into past the fan's edges.
        float bloom = 0.4 * exp(-0.7 * k * k);
        float split = smoothstep(0.0, 0.3 * scale, r);
        vec3 hue = mix(vec3(1.0), spectrum(0.5 + 0.5 * clamp(k, -1.0, 1.0)), split * (1.0 - u.fan.w));
        float fade = exp(-r / (1.15 * scale)) * smoothstep(0.0, 0.05 * scale, ahead);
        sum += hue * (inside + bloom) * fade * (0.95 - 0.3 * split);
    }
    // Where it breaks, a flare.
    sum += vec3(0.6) * exp(-r / (0.05 * scale + blur));
    return sum;
}

float hash(vec2 p) {
    p = fract(p * vec2(443.897, 441.423));
    p += dot(p, p.yx + 19.19);
    return fract((p.x + p.y) * p.x);
}

vec4 over(vec4 top, vec4 under) { return top + under * (1.0 - top.a); }

void main() {
    vec2 size = u.frame.xy;
    vec2 p = qt_TexCoord0 * (size + 2.0 * u.frame.zw) - u.frame.zw;
    float px = max(u.folder.w, 0.25);
    bool paper = u.look.x > 0.5;

    vec3 m = metrics(p);
    float body = m.x;
    float tab = m.y;
    float flap = m.z;
    float paneD = box(p, u.pane, vec4(u.radii.w));
    float all = min(body, paneD);
    float aa = px * 0.75;
    float inBody = 1.0 - smoothstep(-aa, aa, body);
    float inPane = 1.0 - smoothstep(-aa, aa, paneD);
    // The lit flap: inside it and out of the tab (the tab's foot curves over its top), above the foot.
    float lit = inBody * smoothstep(-aa, aa, tab) * (1.0 - smoothstep(-aa, aa, flap)) * step(p.y, u.pane.w);

    vec4 col = vec4(0.0);

    // The shadow of the whole, on the desktop.
    float lift = 0.022 * size.y;
    float spread = 0.06 * size.y;
    float shadowD = min(metrics(p - vec2(0.0, lift)).x, box(p - vec2(0.0, lift), u.pane, vec4(u.radii.w)));
    // The lit flap throws light, not shadow, where it stands above the pane.
    float flapSide = smoothstep(u.folder.y - u.radii.y, u.folder.y + u.radii.y, p.x) * (1.0 - smoothstep(u.pane.y - spread, u.pane.y, p.y));
    float shade = (1.0 - smoothstep(-spread, spread * 1.6, shadowD)) * u.look.w * (paper ? 0.45 : 1.0) * (1.0 - 0.85 * flapSide);
    col = vec4(0.0, 0.0, 0.0, shade * (1.0 - inBody) * (1.0 - inPane));

    // The flap's glow on the desktop above and right of it, never over the tab.
    float glow = exp(-max(flap, 0.0) / max(u.shelf.a, 1.0)) * smoothstep(0.0, 4.0 * px, body)
        * smoothstep(u.folder.y - u.radii.y, u.folder.y + u.radii.y, p.x) * step(p.y, u.pane.y) * (1.0 - inPane);
    vec3 glowRgb = u.shelf.rgb * glow * (paper ? 0.6 : 0.85);
    col = over(vec4(glowRgb, glow * (paper ? 0.55 : 0.4)), col);

    // The glass's own colour over what the frost shows of the desktop.
    vec4 under = u.look.y > 0.5 ? texture(frost, clamp(p / size, 0.0, 1.0)) : vec4(0.0);
    vec4 glass = vec4(u.tone.rgb * u.tone.a, u.tone.a) + under * (1.0 - u.tone.a);

    // Body, with the pane's shadow on it.
    float paneShade = 1.0 - smoothstep(-0.03 * size.y, 0.05 * size.y, box(p - vec2(0.0, 0.02 * size.y), u.pane, vec4(u.radii.w)));
    vec4 bodyCol = glass;
    bodyCol.rgb *= 1.0 - paneShade * (paper ? 0.08 : 0.32);
    // The flap: the song's colour, a little brighter toward its top, where the light comes from.
    vec3 shelfRgb = u.shelf.rgb * (1.0 + 0.1 * smoothstep(u.pane.y, u.folder.z, p.y));
    bodyCol = mix(bodyCol, vec4(shelfRgb, 1.0), lit);

    // The pane: the same glass, frosted further and lifted (Figma's 16 % white radial fill).
    vec2 paneC = vec2(mix(u.pane.x, u.pane.z, 0.3), u.pane.y);
    float lift16 = (paper ? 0.42 : 0.1) * (1.0 - smoothstep(0.0, length(u.pane.zw - u.pane.xy) * 0.9, length(p - paneC)));
    vec4 paneCol = glass + vec4(vec3(lift16), 0.0) * glass.a;
    paneCol.rgb = min(paneCol.rgb, vec3(glass.a));

    col = over(bodyCol * inBody * (1.0 - inPane), col);
    col = over(paneCol * inPane, col * (1.0 - inPane));

    // The light: through the body's frost, then the pane's thicker frost; not on the lit flap.
    float through = max(inBody * (1.0 - lit), inPane) * u.fan.z;
    if (through > 0.0) {
        float blurBody = 0.018 * size.y;
        float blurPane = 0.045 * size.y;
        vec3 l = mix(light(p, blurBody), light(p, blurPane), inPane);
        if (paper) {
            // Paper glass takes the light as tinted film: white is lost in white, the colours stay as a wash.
            float lum = dot(l, vec3(0.2126, 0.7152, 0.0722));
            vec3 tint = l / max(max(l.r, max(l.g, l.b)), 1e-3);
            float a = clamp(lum, 0.0, 1.0) * 0.5 * through;
            col.rgb = mix(col.rgb, tint * col.a, a * (1.0 - 0.75 * smoothstep(0.85, 1.0, min(tint.r, min(tint.g, tint.b)))));
            col.rgb += vec3(0.22) * clamp(lum - 0.6, 0.0, 1.0) * through * col.a;
        } else {
            // Dark glass adds it, as light does.
            col.rgb += l * 0.62 * through;
        }
    }

    // Grain on the glass, as a frosted pane has (fixed per pixel: it never shimmers).
    float covered = max(inBody, inPane);
    float n = hash(floor(p / px)) - 0.5;
    col.rgb += vec3(n * u.look.z * covered * col.a);

    // The rims, lit from above and fading downward (Figma's 0.5 px stroke, white to clear).
    vec2 e = vec2(0.5 * px, 0.0);
    vec2 nBody = normalize(vec2(metrics(p + e.xy).x - metrics(p - e.xy).x, metrics(p + e.yx).x - metrics(p - e.yx).x) + 1e-5);
    vec2 nPane = normalize(vec2(box(p + e.xy, u.pane, vec4(u.radii.w)) - box(p - e.xy, u.pane, vec4(u.radii.w)),
        box(p + e.yx, u.pane, vec4(u.radii.w)) - box(p - e.yx, u.pane, vec4(u.radii.w))) + 1e-5);
    float lineBody = (1.0 - smoothstep(0.0, px * 1.1, abs(body + 0.5 * px))) * (1.0 - inPane);
    float linePane = 1.0 - smoothstep(0.0, px * 1.1, abs(paneD + 0.5 * px));
    float fromTopBody = 0.25 + 0.75 * clamp(-nBody.y, 0.0, 1.0);
    float fromTopPane = 0.3 + 0.7 * clamp(-nPane.y, 0.0, 1.0);
    float rimBody = lineBody * fromTopBody * (paper ? 0.55 : 0.2) * (1.0 - lit);
    float rimPane = linePane * fromTopPane * (paper ? 0.9 : 0.42);
    col.rgb = mix(col.rgb, vec3(col.a), clamp(rimBody + rimPane, 0.0, 1.0));
    // On paper the lower edges take a hairline of shade instead, so the glass keeps its outline on white.
    if (paper) {
        float under2 = (lineBody * (1.0 - lit) + linePane) * clamp(nBody.y + nPane.y, 0.0, 1.0) * 0.12;
        col.rgb *= 1.0 - under2;
    }

    fragColor = col * u.qt_Opacity;
}
