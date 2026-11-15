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

// One number in 0..1 for each question asked of a seed.
float draw(float seed, float k) {
    return fract(sin(seed * 12.9898 + k * 78.233) * 43758.5453);
}

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

    // Every shape is drawn from the seed (his 11-15: "procedural ... que no se repita"): how many swells cross the box,
    // how high they ride, where the mass gathers, which way the colours run, and a second bloom of its own. Waves
    // are counted across the width, so a long folder band and a poster both get one or two slow swoops.
    float X = qt_TexCoord0.x;
    float cycles = mix(0.45, 1.15, draw(s, 1.0));
    float phase = draw(s, 2.0) * 6.2832;
    float amp = mix(0.12, 0.3, draw(s, 3.0));
    float wave = sin(X * cycles * 6.2832 + phase)
        + mix(0.15, 0.45, draw(s, 4.0)) * sin(X * cycles * mix(2.1, 3.4, draw(s, 5.0)) * 6.2832 - phase * 1.7);
    vec2 q = p;
    q.x += 0.06 * sin(q.y * 2.3 + s * 0.7);
    float centre = u.shape.z + amp * wave;
    float thick = u.shape.w * mix(0.85, 1.25, draw(s, 6.0))
        * (0.72 + 0.32 * sin(X * mix(0.6, 1.8, draw(s, 7.0)) * 6.2832 + draw(s, 8.0) * 6.2832));
    float d = (q.y - centre) / max(thick, 0.05);

    // Its mass gathers round the focus (nudged by the seed) and thins out toward the edges, so text has a calm side.
    float fx = (u.shape.y + (draw(s, 9.0) - 0.5) * 0.4) * aspect;
    float reach = max(aspect * mix(0.38, 0.6, draw(s, 10.0)), 0.9);
    float mass = exp(-pow((p.x - fx) / reach, 2.0));

    // Three widths of one blur: the body, a wide bloom round it and a soft core, so its edge melts as a lens's would.
    float body = exp(-d * d * 1.1) * mass;
    float haze = exp(-d * d * 0.22) * mass * 0.42;
    float core = exp(-d * d * 3.2) * mass;

    // A second bloom away from the ribbon, round and very soft: the colour field of the posters, never the same twice.
    vec2 bloomAt = vec2(mix(0.15, 0.95, draw(s, 11.0)) * aspect, u.shape.z + mix(-0.35, 0.35, draw(s, 12.0)));
    float bloomSize = mix(0.55, 1.05, draw(s, 13.0)) * max(u.shape.w * 2.2, 0.5);
    float bloom = exp(-dot(p - bloomAt, p - bloomAt) / (bloomSize * bloomSize)) * mix(0.25, 0.5, draw(s, 14.0));

    // Colour along the ribbon, bent by the distance from its core; the core takes the third colour in places.
    float flip = draw(s, 15.0) < 0.5 ? 1.0 : -1.0;
    float along = clamp(flip * (p.x - fx) / (reach * 1.6) + 0.5 + 0.18 * d, 0.0, 1.0);
    // Which of the three leads is the seed's too, so neighbours on one page differ in colour as well as in shape.
    float turn = floor(draw(s, 18.0) * 3.0);
    vec3 k1 = turn < 0.5 ? u.c1.rgb : turn < 1.5 ? u.c2.rgb : u.c3.rgb;
    vec3 k2 = turn < 0.5 ? u.c2.rgb : turn < 1.5 ? u.c3.rgb : u.c1.rgb;
    vec3 k3 = turn < 0.5 ? u.c3.rgb : turn < 1.5 ? u.c1.rgb : u.c2.rgb;
    vec3 colour = mix(k1, k2, smoothstep(0.0, 1.0, along));
    float pulse = 0.5 + 0.5 * sin(X * mix(2.0, 5.0, draw(s, 16.0)) + s * 3.0);
    colour = mix(colour, k3, core * 0.55 * pulse);
    float lead = body + haze;
    colour = mix(colour, mix(k3, k1, draw(s, 17.0)), bloom / max(lead + bloom, 1e-3));
    body = body + bloom;

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
