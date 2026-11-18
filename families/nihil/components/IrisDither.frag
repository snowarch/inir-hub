#version 440
// A flat screen of ink: the tone a one-bit surface has instead of grey.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 ink;
    // xy: the drawn size in pixels; z: the side of a cell; w: how much of the surface is ink, 0 to 1.
    vec4 frame;
} u;

const float screenTable[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void main() {
    ivec2 at = ivec2(mod(floor(qt_TexCoord0 * u.frame.xy / u.frame.z), 4.0));
    fragColor = (screenTable[at.y * 4 + at.x] + 0.5) / 16.0 < u.frame.w ? u.ink * u.qt_Opacity : vec4(0.0);
}
