#version 440
// A four-point flare: two thin rays crossed on a small bloom, the light of a lens on glass.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 tint;
};
void main() {
    vec2 p = (qt_TexCoord0 - 0.5) * 2.0;
    float rays = exp(-abs(p.y) * 60.0) * pow(1.0 - min(abs(p.x), 1.0), 2.5)
               + exp(-abs(p.x) * 60.0) * pow(1.0 - min(abs(p.y), 1.0), 2.5);
    float core = exp(-dot(p, p) * 40.0);
    float halo = exp(-dot(p, p) * 7.0) * 0.25;
    float a = clamp(rays * 0.9 + core + halo, 0.0, 1.0);
    vec3 rgb = mix(tint.rgb, vec3(1.0), core);
    fragColor = vec4(rgb * a, a) * qt_Opacity;
}
