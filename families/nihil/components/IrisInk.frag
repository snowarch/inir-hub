#version 440
// A picture printed in one bit: its light through an ordered screen, its edge cut clean.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    // xy: the drawn size in pixels; z: the side of a printed cell.
    vec4 frame;
} u;
layout(binding = 1) uniform sampler2D source;

const float screenTable[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void main() {
    vec2 cell = floor(qt_TexCoord0 * u.frame.xy / u.frame.z);
    vec4 c = texture(source, (cell + 0.5) * u.frame.z / u.frame.xy);
    if (c.a < 0.5) { fragColor = vec4(0.0); return; }
    float light = dot(c.rgb / c.a, vec3(0.2126, 0.7152, 0.0722));
    ivec2 at = ivec2(mod(cell, 4.0));
    float paper = smoothstep(0.26, 0.68, light) > (screenTable[at.y * 4 + at.x] + 0.5) / 16.0 ? 1.0 : 0.0;
    fragColor = vec4(vec3(paper), 1.0) * u.qt_Opacity;
}
