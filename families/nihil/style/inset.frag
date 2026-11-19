#version 440
// An inset: a shallow recess in the glass, shaded along its top edge and lit along its bottom one. `highlighted` raises
// an aurora in the light's two colours from the lower edge and draws its hot line.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 box;
    float radius;
    float highlighted;
    float hover;
    vec4 fill;
    vec4 shade;
    vec4 edge;
    vec4 glow;
    vec4 highlight;
    vec4 highlightTint;
};

vec3 straight(vec4 c) { return c.a > 0.0001 ? c.rgb / c.a : c.rgb; }

float rounded(vec2 p, vec2 half_, float r) {
    vec2 q = abs(p) - half_ + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    vec2 p = qt_TexCoord0 * box;
    vec2 c = box * 0.5;
    float d = rounded(p - c, c, min(radius, min(c.x, c.y)));
    float inside = smoothstep(0.6, -0.6, d);

    float a = fill.a + hover * glow.a * 0.03;
    vec3 rgb = mix(straight(fill), straight(glow), hover * 0.5) * a;

    float top = pow(clamp(1.0 - p.y / 3.0, 0.0, 1.0), 2.0) * shade.a;
    rgb *= 1.0 - top;
    a += top * (1.0 - a);

    float lower = smoothstep(c.y, box.y, p.y) * exp(-pow((d + 0.75) / 0.9, 2.0)) * edge.a;
    rgb += straight(edge) * lower;
    a += lower * (1.0 - a);

    vec3 tone = mix(highlight.rgb, highlightTint.rgb, qt_TexCoord0.x);
    float fromBottom = (box.y - p.y) / min(box.y * 0.42, 26.0);
    float across = (p.x - c.x) / (box.x * 0.46);
    float rise = exp(-fromBottom * fromBottom) * exp(-across * across) * highlighted;
    rgb += tone * rise * 0.2;
    a += rise * 0.14 * (1.0 - a);

    float hot = exp(-pow((box.y - p.y - 0.75) / 0.8, 2.0)) * exp(-pow((p.x - c.x) / (box.x * 0.34), 2.0)) * highlighted;
    rgb += (tone * 0.6 + 0.4) * hot;
    a += hot * (1.0 - a);

    fragColor = vec4(rgb, a) * inside * qt_Opacity;
}
