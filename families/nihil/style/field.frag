#version 440
// The procedural field: warped grainy light over black. form 0 drift, 1 eclipse arc, 2 fluted streaks, 3 stippled ridge.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 box;
    float seed;
    float form;
    float grain;
    float glow;
    vec4 base;
    vec4 mid;
    vec4 high;
    vec4 spark;
};
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
    float sum = 0.0, amp = 0.5;
    for (int i = 0; i < 5; ++i) { sum += amp * noise(p); p = p * 2.03 + 17.0; amp *= 0.5; }
    return sum;
}
void main() {
    float aspect = box.x / max(box.y, 1.0);
    vec2 uv = vec2(qt_TexCoord0.x * aspect, qt_TexCoord0.y);
    vec2 s = uv * 1.6 + seed * 3.17;
    vec2 warp = vec2(fbm(s + 1.7), fbm(s + 9.2));
    float light = fbm(s + warp * 1.8);
    vec2 centre = vec2(aspect * (0.3 + fract(seed * 0.73) * 0.4), 0.55 + fract(seed * 0.41) * 0.25);
    float m = int(form + 0.5);
    if (m == 1) {
        float ring = abs(length(uv - centre) - 0.42);
        light = light * 0.25 + exp(-ring * 16.0) * smoothstep(-0.2, 0.5, uv.y - centre.y + 0.3);
    } else if (m == 2) {
        float flute = 0.5 + 0.5 * sin(uv.x * 92.0 + warp.x * 7.0);
        light = pow(light, 1.4) * (0.45 + 0.75 * pow(flute, 2.0));
    } else if (m == 3) {
        float ridge = 0.62 - 0.3 * fbm(vec2(uv.x * 2.4 + seed, seed)) - uv.y * 0.15;
        float fall = smoothstep(0.0, 0.34, uv.y - ridge) * exp(-(uv.y - ridge) * 3.4);
        light = fall * 1.25 * step(hash(floor(gl_FragCoord.xy * 0.75)), 0.28 + fall * 0.9);
    } else {
        light = smoothstep(0.28, 0.82, light);
    }
    light = clamp(light * glow, 0.0, 1.0);
    vec3 ink = mix(base.rgb, mid.rgb, smoothstep(0.0, 0.45, light));
    ink = mix(ink, high.rgb, smoothstep(0.42, 0.85, light));
    ink += spark.rgb * pow(light, 5.0) * 0.7;
    ink += (hash(gl_FragCoord.xy + seed) - 0.5) * grain * 0.16;
    fragColor = vec4(ink, 1.0) * qt_Opacity;
}
