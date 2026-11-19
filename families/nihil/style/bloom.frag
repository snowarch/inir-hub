#version 440
// A soft light around a point: it falls away to nothing, with no edge to see.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 tone;
    float strength;
};

void main() {
    vec2 p = qt_TexCoord0 * 2.0 - 1.0;
    float r = dot(p, p);
    float fall = exp(-r * 4.5) * smoothstep(1.0, 0.5, r) * strength;
    vec3 ink = tone.a > 0.0001 ? tone.rgb / tone.a : tone.rgb;
    fragColor = vec4(ink * fall, fall * 0.7) * qt_Opacity;
}
