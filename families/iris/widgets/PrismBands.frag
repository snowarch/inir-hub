#version 440
// Prism's spectrum laid on whatever a face draws (PrismSpectrum.qml, worn as a `layer.effect`): the item's own coverage
// kept, its colour replaced by the person's Prism light (IrisStyle.prismStops) running along `axis`, so a trace, a bar or a figure carries
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
    // The spectrum's stops, violet to red (IrisStyle.prismStops).
    vec4 s0; vec4 s1; vec4 s2; vec4 s3; vec4 s4; vec4 s5; vec4 s6;
} u;
layout(binding = 1) uniform sampler2D source;

// The spectrum's seven stops, violet to red, from IrisStyle.prismStops (the shell's one source of Prism's light).
vec3 spectrum(float t) {
    float x = clamp(t, 0.0, 1.0) * 6.0;
    vec3 a = x < 1.0 ? u.s0.rgb : x < 2.0 ? u.s1.rgb : x < 3.0 ? u.s2.rgb : x < 4.0 ? u.s3.rgb : x < 5.0 ? u.s4.rgb : u.s5.rgb;
    vec3 b = x < 1.0 ? u.s1.rgb : x < 2.0 ? u.s2.rgb : x < 3.0 ? u.s3.rgb : x < 4.0 ? u.s4.rgb : x < 5.0 ? u.s5.rgb : u.s6.rgb;
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
