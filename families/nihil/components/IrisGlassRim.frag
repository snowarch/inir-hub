#version 440
// Glass in one pass (IrisGlassRim): a rounded body with its sheen, and a rim whose light fades down from the top and
// whose lip rises from the bottom. Replaces a masked layer per rim (two offscreen textures and a MultiEffect each).
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    // Colours, premultiplied (Qt hands a QML color to a shader premultiplied).
    vec4 fill;    // the body, flat
    vec4 sheen;   // over the body, linear from the top to fade.z
    vec4 base;    // the rim, all round
    vec4 lit;     // the rim's light, full at the top, smoothly gone at fade.x
    vec4 lip;     // the rim's lip, rising smoothly from fade.y to full at the bottom
    vec4 fade;    // x: top light gone, y: lip starts, z: sheen gone (0..1 down the height), w: unused
    vec4 box;     // xy: size in px, z: corner radius, w: rim width in px
    float aa;     // one device pixel, in px
} u;

vec4 over(vec4 src, vec4 dst) {
    return src + dst * (1.0 - src.a);
}

void main() {
    vec2 half_ = 0.5 * u.box.xy;
    vec2 px = qt_TexCoord0 * u.box.xy;
    float r = min(u.box.z, min(half_.x, half_.y));
    vec2 q = abs(px - half_) - (half_ - r);
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
    float aa = max(u.aa, 1e-3);
    float inside = clamp(0.5 - d / aa, 0.0, 1.0);
    if (inside <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }
    float ring = inside * clamp(0.5 + (d + u.box.w) / aa, 0.0, 1.0);
    float y = qt_TexCoord0.y;

    vec4 c = u.fill * inside;
    c = over(u.sheen * (inside * clamp(1.0 - y / max(u.fade.z, 1e-4), 0.0, 1.0)), c);
    c = over(u.base * ring, c);
    c = over(u.lit * (ring * smoothstep(0.0, 1.0, clamp(1.0 - y / max(u.fade.x, 1e-4), 0.0, 1.0))), c);
    c = over(u.lip * (ring * smoothstep(0.0, 1.0, clamp((y - u.fade.y) / max(1.0 - u.fade.y, 1e-4), 0.0, 1.0))), c);
    fragColor = c * u.qt_Opacity;
}
