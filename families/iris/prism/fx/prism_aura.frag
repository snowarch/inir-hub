#version 440
// The panel's air (his 11-15: the poster's colour "transmitido a todo el panel ... sin que afecte la legibilidad"):
// the page's three colours as wide, very soft blooms from the top of the window and one low in a far corner, seen
// where the canvas shows (the gutters, the side column, round the cards), over the canvas. Dark: light screened over the night. Light: a wash of pigment on paper. Static: it draws again
// only when the window's size, the page or a colour changes.
// One frame for every copy: a copy laid over the edge of the scrolled column (`band`) draws the same air at the same
// place and fades out along its height, so rows passing under it melt into the air instead of into a flat veil.
// Over iRiS's glass (his 11-16) the canvas is a veil: over the compositor's blur it lets it through by the Tint, over
// the wallpaper's glass it lies on the blurred wallpaper sampled where the panel sits on the screen.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;     // this copy's size, px
    vec4 frame;    // where this copy sits in the whole window (x, y) and the window's size (w, h), px
    vec4 c1;
    vec4 c2;
    vec4 c3;
    vec4 ground;   // the canvas; a = 1 dark (screened light), 0 light (pigment)
    vec4 band;     // a = 0: the whole air, opaque. a = 1: fade out downward over this copy; a = -1: fade in downward
    float seed;
    float strength;
    float radius;  // the window's corners, px
    vec4 glass;    // x: 0 the solid canvas, 1 a veil over the compositor's blur, 2 the wallpaper's glass under it; y: the veil
    vec4 screen;   // where the window's top-left lies on the screen (x, y) and the screen's size (z, w), px
} u;
layout(binding = 1) uniform sampler2D backdrop;

float draw(float k) { return fract(sin(u.seed * 12.9898 + k * 78.233) * 43758.5453); }
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}
float bloomOf(vec2 p, vec2 at, vec2 size) {
    vec2 d = (p - at) / size;
    return exp(-dot(d, d));
}

void main() {
    vec2 px = qt_TexCoord0 * u.size;
    vec2 at = px + u.frame.xy;           // this pixel in the window
    vec2 w = max(u.frame.zw, vec2(1.0));
    vec2 p = at / w;

    // Three blooms hung from the top edge, each where the page's seed puts it, wide and shallow so the colour lies
    // along the top like light over a horizon; a fourth, faint, low in the far corner.
    float a1 = bloomOf(p, vec2(mix(0.0, 0.3, draw(1.0)), -0.05), vec2(mix(0.4, 0.55, draw(2.0)), 0.55));
    float a2 = bloomOf(p, vec2(mix(0.4, 0.65, draw(3.0)), -0.1), vec2(mix(0.35, 0.5, draw(4.0)), 0.6));
    float a3 = bloomOf(p, vec2(mix(0.82, 1.05, draw(5.0)), mix(0.1, 0.4, draw(6.0))), vec2(mix(0.25, 0.35, draw(7.0)), 0.5));
    float a4 = bloomOf(p, vec2(mix(0.55, 1.0, draw(8.0)), 1.05), vec2(0.4, 0.35)) * 0.6;
    float amount = a1 + a2 + a3 + a4;
    vec3 colour = (u.c1.rgb * a1 + u.c2.rgb * a2 + u.c3.rgb * a3 + u.c2.rgb * a4) / max(amount, 1e-3);
    amount = clamp(amount, 0.0, 1.0);
    // Over glass the blur behind carries the colour: the page's air only tints it.
    amount = amount * amount * (3.0 - 2.0 * amount) * u.strength * (u.glass.x > 0.5 ? 0.6 : 1.0);
    vec3 ground = u.ground.rgb;
    if (u.glass.x > 1.5) {
        vec3 behind = texture(backdrop, (u.screen.xy + at) / max(u.screen.zw, vec2(1.0))).rgb;
        ground = mix(behind, ground, u.glass.y);
    }

    // Film grain, a trace, so the wash never bands on an 8-bit screen.
    float n = 0.5 * (hash(floor(at)) + hash(floor(at * 0.5) * 1.37 + 3.1));
    float speck = (n - 0.5) * 0.02;

    vec3 rgb;
    if (u.ground.a > 0.5) {
        vec3 lit = colour * amount;
        rgb = 1.0 - (1.0 - ground) * (1.0 - lit);
    } else {
        rgb = mix(ground, colour, amount);
    }
    rgb = clamp(rgb + vec3(speck), 0.0, 1.0);

    // The window's round corners, in the window's frame.
    vec2 q = abs(at - w * 0.5) - w * 0.5 + vec2(u.radius);
    float edge = min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - u.radius;
    float alpha = clamp(0.5 - edge, 0.0, 1.0);
    if (u.band.a != 0.0) {
        float t = qt_TexCoord0.y;
        t = u.band.a > 0.0 ? t : 1.0 - t;
        alpha *= 1.0 - smoothstep(0.0, 1.0, t);
    }
    // Over the compositor's blur the canvas covers only by the veil; everything else is opaque.
    if (u.glass.x > 0.5 && u.glass.x < 1.5) alpha *= u.glass.y;
    fragColor = vec4(rgb * alpha, alpha) * u.qt_Opacity;
}
