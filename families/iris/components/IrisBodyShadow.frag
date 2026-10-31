#version 440
// A Kiri body's soft shadow (IrisBodyShadow): RectangularShadow's falloff (Qt's rectangularshadow.frag, the CSS
// box-shadow ramp) laid on the distance to the body's own outline (IrisField.frag kiriBox). Qt's shrinks the box by most
// of the blur and measures from there, so every corner comes out round: under a body cut at 45° with two square
// corners, its shade went missing at the square ones. Measured from the outline, straight edges ramp the same and each
// corner keeps its shape.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    // Premultiplied, as Qt hands a QML color to a shader.
    vec4 shade;
    // xy: the effect's size in pixels, z: how far it reaches past the body on each side, w: spread.
    vec4 box;
    // x: the body's radius (its Kiri outline, IrisField.frag kiriBox), y: the blur (RectangularShadow.blur).
    vec4 cut;
} u;

// IrisField.frag squircleBox and kiriBox, the same outline the field draws.
const float SQUIRCLE_REACH = 1.8409;
float roundedBox(vec2 p, vec2 centre, vec2 halfSize, float radius) {
    float r = min(radius, min(halfSize.x, halfSize.y));
    vec2 q = abs(p - centre) - (halfSize - r);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}
float squircleBox(vec2 p, vec2 centre, vec2 halfSize, float radius) {
    float m = min(halfSize.x, halfSize.y);
    float r = min(radius, m);
    if (r < 0.5 || r >= m - 0.5)
        return roundedBox(p, centre, halfSize, radius);
    float reach = min(r * SQUIRCLE_REACH, m);
    vec2 q = abs(p - centre) - (halfSize - reach);
    if (q.x <= 0.0 || q.y <= 0.0)
        return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - reach;
    vec2 q2 = q * q;
    vec2 q4 = q2 * q2;
    float l = sqrt(sqrt(q4.x + q4.y));
    vec2 gradient = q2 * q / (l * l * l);
    return (l - reach) / length(gradient);
}
float kiriBox(vec2 p, vec2 centre, vec2 halfSize, float radius) {
    vec2 d = p - centre;
    float r = min(radius, 0.56 * min(halfSize.x, halfSize.y));
    if (d.x * d.y >= 0.0 || r < 0.5)
        return squircleBox(p, centre, halfSize, r);
    float e = 0.55 * r;
    vec2 q = abs(d);
    vec2 s = halfSize - e;
    float l = halfSize.x + halfSize.y - 1.5 * r - e * 1.41421356;
    float inside = max(max(q.x - s.x, q.y - s.y), (q.x + q.y - l) * 0.70710678);
    if (inside <= 0.0)
        return inside - e;
    vec2 a = vec2(s.x, l - s.x);
    vec2 b = vec2(l - s.y, s.y);
    vec2 ab = b - a;
    float t = clamp(dot(q - a, ab) / dot(ab, ab), 0.0, 1.0);
    float dist = length(q - a - ab * t);
    dist = min(dist, q.y <= a.y ? abs(q.x - s.x) : length(q - a));
    dist = min(dist, q.x <= b.x ? abs(q.y - s.y) : length(q - b));
    return dist - e;
}

void main() {
    vec2 p = qt_TexCoord0 * u.box.xy;
    vec2 centre = u.box.xy * 0.5;
    vec2 halfSize = max(centre - vec2(u.box.z), vec2(0.5));
    // Qt's ramp: full until 0.8 blur inside the edge, gone 1.3 blur outside it, squared.
    float d = kiriBox(p, centre, halfSize, u.cut.x) - u.box.w + 0.8 * u.cut.y;
    float a = 1.0 - smoothstep(0.0, max(1.0, 2.1 * u.cut.y), d);
    fragColor = u.shade * (a * a) * u.qt_Opacity;
}
