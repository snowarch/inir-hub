#version 440
// A full ring of ticks. `level` lights them clockwise from the top; `pointer` lights the ones round an angle and draws
// the longest tick there. A recess sits at the heart.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 box;
    float ticks;
    float level;
    float pointer;
    float spread;
    vec4 mark;
    vec4 light;
    vec4 recess;
};

const float TAU = 6.28318531;

float apart(float a, float b) { return abs(mod(a - b + TAU * 0.5, TAU) - TAU * 0.5); }

void main() {
    vec2 c = box * 0.5;
    vec2 p = qt_TexCoord0 * box - c;
    float R = min(c.x, c.y);
    float r = length(p);
    float theta = mod(atan(p.x, -p.y), TAU);

    float heart = R * 0.82;
    vec4 color = recess * smoothstep(heart + 0.7, heart - 0.7, r);

    float f = theta / TAU * ticks;
    float n = floor(f + 0.5);
    float at = mod(n, ticks);
    float angle = at / ticks * TAU;
    bool aimed = spread > 0.0 && apart(angle, pointer) < TAU / ticks * 0.5;
    bool major = mod(at, 5.0) < 0.5;
    float inner = R * (aimed ? 0.84 : major ? 0.89 : 0.93);
    float outer = R * 0.995;
    float along = abs(f - n) / ticks * TAU * r;
    float half_ = aimed ? 1.7 : major ? 1.15 : 0.8;
    float cover = smoothstep(half_ + 0.6, half_ - 0.6, along)
        * smoothstep(inner - 0.6, inner + 0.6, r) * smoothstep(outer + 0.6, outer - 0.6, r);

    float filled = step(at + 0.5, level * ticks);
    float near = spread > 0.0 ? smoothstep(spread, spread * 0.3, apart(angle, pointer)) : 0.0;
    color += mix(mark, light, max(filled, near)) * cover * (1.0 - color.a);
    fragColor = color * qt_Opacity;
}
