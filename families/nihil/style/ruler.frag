#version 440
// A level read on a ruler: fine marks, a longer one every ten, those under the level lit in the light's two colours, and
// a needle of white light where it stands.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 box;
    float level;
    float cell;
    float needle;
    vec4 mark;
    vec4 specA;
    vec4 specB;
    vec4 needleInk;
};

vec3 straight(vec4 c) { return c.a > 0.0001 ? c.rgb / c.a : c.rgb; }

void main() {
    vec2 p = qt_TexCoord0 * box;
    float my = box.y * 0.5;
    float span = box.x - 3.0;
    float x = p.x - 1.5;
    float at = level * span;

    float k = floor(x / cell + 0.5);
    float cx = k * cell;
    float major = mod(k, 10.0) < 0.5 ? 1.0 : 0.0;
    float reach = box.y * (major > 0.5 ? 0.3 : 0.17);
    float tick = smoothstep(1.05, 0.35, abs(x - cx)) * smoothstep(reach + 0.5, reach - 0.5, abs(p.y - my));
    tick *= step(-0.5, cx) * step(cx, span + 0.5);

    float on = smoothstep(0.5, -0.5, cx - at);
    vec3 ink = mix(specA.rgb, specB.rgb, clamp(cx / max(at, 1.0), 0.0, 1.0));
    float a = tick * mix(mark.a, 1.0, on);
    vec3 rgb = mix(straight(mark), ink, on) * a;

    float dx = x - at;
    float glow = exp(-dx * dx / 42.0) * exp(-pow((p.y - my) / (box.y * 0.46), 2.0)) * 0.42 * needle;
    rgb += specA.rgb * glow;
    a += glow * 0.6 * (1.0 - a);

    float line = smoothstep(1.7, 0.7, abs(dx)) * smoothstep(my + 0.5, my - 0.5, abs(p.y - my)) * needle;
    rgb = mix(rgb, needleInk.rgb * line, line);
    a = max(a, line);

    fragColor = vec4(rgb, a) * qt_Opacity;
}
