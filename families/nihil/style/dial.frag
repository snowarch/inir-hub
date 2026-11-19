#version 440
// A dial: ticks around three quarters of a circle, lit up to the level, a track in the middle and a soft
// bloom where the level stands. The open quarter faces down.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 box;
    float level;
    float ticks;
    vec4 tickColor;
    vec4 fillColor;
    vec4 trackColor;
};

const float PI = 3.14159265;

void main() {
    vec2 c = box * 0.5;
    vec2 p = qt_TexCoord0 * box - c;
    float R = min(c.x, c.y);
    float r = length(p);
    float theta = mod(-atan(p.x, p.y), 2.0 * PI);
    float gap = PI * 0.25;
    float span = 2.0 * PI - 2.0 * gap;
    float t = (theta - gap) / span;

    float heart = R * 0.7;
    vec4 color = trackColor * smoothstep(heart + 0.7, heart - 0.7, r);
    float catchLine = exp(-pow((r - heart) / 0.8, 2.0)) * smoothstep(R * 0.2, -R * 0.7, p.y);
    color += tickColor * catchLine * 0.8;

    if (t > -0.02 && t < 1.02) {
        float f = t * ticks;
        float n = floor(f + 0.5);
        bool major = mod(n, 5.0) < 0.5;
        float inner = R * (major ? 0.79 : 0.85);
        float outer = R * 0.98;
        float along = abs(f - n) / ticks * span * r;
        float half_ = major ? 1.15 : 0.8;
        float cover = smoothstep(half_ + 0.6, half_ - 0.6, along)
            * smoothstep(inner - 0.6, inner + 0.6, r) * smoothstep(outer + 0.6, outer - 0.6, r);
        cover *= step(0.0, n) * step(n, ticks);
        float on = step(n / ticks, level + 0.0001) * step(0.0001, level);
        color += mix(tickColor, fillColor, on) * cover * (1.0 - color.a);

        float tip = exp(-pow((t - level) * span * r / (R * 0.2), 2.0)) * exp(-pow((r - R * 0.9) / (R * 0.12), 2.0));
        color += fillColor * tip * 0.3 * step(0.0001, level) * (1.0 - color.a);
    }
    fragColor = color * qt_Opacity;
}
