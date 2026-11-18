#version 440
// One-bit print of the wallpaper: each cell of the screen reads the picture's light and an 8x8 ordered screen decides
// whether it is ink or paper.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    // xy: the drawn size in pixels; z: the side of a printed cell in pixels.
    vec4 frame;
} u;
layout(binding = 1) uniform sampler2D source;

const float screenTable[64] = float[64](
     0.0, 32.0,  8.0, 40.0,  2.0, 34.0, 10.0, 42.0,
    48.0, 16.0, 56.0, 24.0, 50.0, 18.0, 58.0, 26.0,
    12.0, 44.0,  4.0, 36.0, 14.0, 46.0,  6.0, 38.0,
    60.0, 28.0, 52.0, 20.0, 62.0, 30.0, 54.0, 22.0,
     3.0, 35.0, 11.0, 43.0,  1.0, 33.0,  9.0, 41.0,
    51.0, 19.0, 59.0, 27.0, 49.0, 17.0, 57.0, 25.0,
    15.0, 47.0,  7.0, 39.0, 13.0, 45.0,  5.0, 37.0,
    63.0, 31.0, 55.0, 23.0, 61.0, 29.0, 53.0, 21.0
);

void main() {
    float side = max(1.0, u.frame.z);
    vec2 cell = floor(qt_TexCoord0 * u.frame.xy / side);
    vec3 picture = textureLod(source, (cell + 0.5) * side / u.frame.xy, log2(side)).rgb;
    float light = dot(picture, vec3(0.2126, 0.7152, 0.0722));
    // Ink wants deep blacks and clean paper: the tones are pressed toward both ends before the screen.
    light = smoothstep(0.06, 0.82, pow(light, 0.8));
    ivec2 at = ivec2(mod(cell, 8.0));
    float paper = light > (screenTable[at.y * 8 + at.x] + 0.5) / 64.0 ? 1.0 : 0.0;
    fragColor = vec4(vec3(paper), 1.0) * u.qt_Opacity;
}
