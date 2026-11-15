#version 440
// Prism's art material (his 11-15 references, `.claude/ref/language`): a ribbon of colour flowing across the box,
// blurred like the posters' airbrush: a wide bloom round a soft body, never a hard edge or a dithered one, with a film
// grain fine enough to read as paper and to keep the bloom from banding. Dark: light added over the night. Light:
// pigment on paper.
// One static pass: it draws again only when a size, a colour or the seed changes.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;     // px
    vec4 c1;       // the ribbon's start
    vec4 c2;       // its end
    vec4 c3;       // its core
    vec4 paper;    // rgb, a = 1 dark (light added), 0 light (pigment), 2 bare (the colour alone, no ground: a glow over a sheet)
    vec4 shape;    // seed, focus x, focus y (0..1), thickness
    vec4 radii;    // corners: top-left, top-right, bottom-right, bottom-left (px)
    float grain;
    float fade;    // from this fraction of the height down the ribbon fades out (1: never), so words below read
    float side;    // over this fraction of the width from the left the ribbon fades in (0: a hard start)
} u;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// A box with its own radius at each corner, centred on p (y grows down).
float cornerBox(vec2 p, vec2 half_, vec4 r) {
    float rr = p.x < 0.0 ? (p.y < 0.0 ? r.x : r.w) : (p.y < 0.0 ? r.y : r.z);
    vec2 q = abs(p) - half_ + vec2(rr);
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - rr;
}

void main() {
    vec2 px = qt_TexCoord0 * u.size;
    float h = max(u.size.y, 1.0);
    // Measured in heights, so a wide band and a tall poster both carry a ribbon of the same character.
    vec2 p = px / h;
    float aspect = u.size.x / h;
    float s = u.shape.x;

    // The ribbon's path: a slow wave with a quicker one riding it, the whole field warped a little so it never reads
    // as a sine.
    vec2 q = p;
    q.x += 0.10 * sin(q.y * 2.3 + s * 0.7);
    float centre = u.shape.z + 0.26 * sin(q.x * 1.25 + s * 2.1) + 0.08 * sin(q.x * 3.2 - s * 1.3);
    float thick = u.shape.w * (0.62 + 0.30 * sin(q.x * 0.85 + s));
    float d = (q.y - centre) / max(thick, 0.05);

    // Its mass gathers round the focus and thins out toward the edges, so text has a calm side.
    float fx = u.shape.y * aspect;
    float reach = max(aspect * 0.46, 0.9);
    float mass = exp(-pow((p.x - fx) / reach, 2.0));

    // Three widths of one blur: the body, a wide bloom round it and a soft core, so its edge melts as a lens's would.
    float body = exp(-d * d * 1.5) * mass;
    float haze = exp(-d * d * 0.36) * mass * 0.34;
    float core = exp(-d * d * 4.5) * mass;

    // Colour along the ribbon, bent by the distance from its core; the core takes the third colour in places.
    float along = clamp((p.x - fx) / (reach * 1.6) + 0.5 + 0.18 * d, 0.0, 1.0);
    vec3 colour = mix(u.c1.rgb, u.c2.rgb, smoothstep(0.0, 1.0, along));
    float pulse = 0.5 + 0.5 * sin(q.x * 1.9 + s * 3.0);
    colour = mix(colour, u.c3.rgb, core * 0.6 * pulse);

    float amount = clamp(body + haze, 0.0, 1.0) * (1.0 - 0.92 * smoothstep(u.fade, u.fade + 0.3, qt_TexCoord0.y));
    amount *= smoothstep(0.0, max(u.side, 1e-4), qt_TexCoord0.x);
    amount = amount * amount * (3.0 - 2.0 * amount);
    // Film grain: two octaves averaged so no single pixel stands out, strongest in the colour, a trace on the ground.
    float n = 0.5 * (hash(floor(px) + s * 17.0) + hash(floor(px * 0.5) * 1.37 + 3.1));
    float speck = (n - 0.5) * u.grain * (0.3 + 0.7 * amount);

    vec3 rgb;
    if (u.paper.a > 0.5) {
        // Light over the night: screened, so colours glow without washing to white.
        vec3 lit = colour * amount * 1.15;
        rgb = 1.0 - (1.0 - u.paper.rgb) * (1.0 - lit);
    } else {
        // Pigment on paper.
        rgb = mix(u.paper.rgb, colour, amount * 0.94);
        rgb *= 1.0 - core * 0.06;
    }
    rgb = clamp(rgb + vec3(speck), 0.0, 1.0);

    float edge = cornerBox(px - u.size * 0.5, u.size * 0.5, u.radii);
    float alpha = clamp(0.5 - edge, 0.0, 1.0);
    if (u.paper.a > 1.5) {
        // Bare: only the colour, as much of it as the ribbon holds, over whatever lies below.
        float a = clamp(amount + speck * amount, 0.0, 1.0) * alpha;
        fragColor = vec4(colour * a, a) * u.qt_Opacity;
        return;
    }
    fragColor = vec4(rgb * alpha, alpha) * u.qt_Opacity;
}
