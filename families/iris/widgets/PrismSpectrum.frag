#version 440
// Prism's spectrum laid on whatever a face draws (PrismSpectrum.qml, worn as a `layer.effect`): the item's own coverage
// kept, its colour replaced by the refraction's seven stops running along `axis`, so a trace, a bar or a figure carries
// the light split. `span` picks the part of the spectrum the item runs through; `white` keeps that much of white at the
// start, as the beam is white before it breaks.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    // xy: direction across the item (unit, in its 0..1 box); z: where the spectrum starts (0 violet), w: where it ends.
    vec4 axis;
    // x: white kept at the start (0..1); y: 1 for white light only (Nothing); z: brightness; w: unused.
    vec4 tone;
} u;
layout(binding = 1) uniform sampler2D source;

vec3 spectrum(float t) {
    const vec3 c0 = vec3(0.835, 0.086, 0.992); // iris-literal: #D516FD, the spectrum's violet
    const vec3 c1 = vec3(0.475, 0.267, 0.992); // iris-literal: #7944FD
    const vec3 c2 = vec3(0.259, 0.537, 0.992); // iris-literal: #4289FD
    const vec3 c3 = vec3(0.149, 0.878, 0.200); // iris-literal: #26E033
    const vec3 c4 = vec3(0.996, 0.949, 0.239); // iris-literal: #FEF23D
    const vec3 c5 = vec3(0.992, 0.412, 0.090); // iris-literal: #FD6917
    const vec3 c6 = vec3(0.992, 0.078, 0.263); // iris-literal: #FD1443, the spectrum's red
    float x = clamp(t, 0.0, 1.0) * 6.0;
    vec3 a = x < 1.0 ? c0 : x < 2.0 ? c1 : x < 3.0 ? c2 : x < 4.0 ? c3 : x < 5.0 ? c4 : c5;
    vec3 b = x < 1.0 ? c1 : x < 2.0 ? c2 : x < 3.0 ? c3 : x < 4.0 ? c4 : x < 5.0 ? c5 : c6;
    return mix(a, b, smoothstep(0.0, 1.0, fract(x)));
}

void main() {
    vec4 s = texture(source, qt_TexCoord0);
    float along = clamp(dot(qt_TexCoord0 - vec2(0.5), u.axis.xy) + 0.5, 0.0, 1.0);
    vec3 hue = spectrum(mix(u.axis.z, u.axis.w, along));
    // White before the break: the first `white` of the run fades from white into the colours.
    float split = smoothstep(0.0, max(u.tone.x, 1e-3), along);
    hue = mix(vec3(1.0), hue, u.tone.x > 0.0 ? split : 1.0);
    hue = mix(hue, vec3(1.0), u.tone.y);
    fragColor = vec4(hue * u.tone.z * s.a, s.a) * u.qt_Opacity;
}
