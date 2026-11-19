#version 440
// NiHiL's glass. A smoked pane over the compositor's blur: brighter at its top, a thickness of light just inside
// its edge, a specular edgeLight that catches a light from the upper left (and its faint echo at the lower right), a broad
// sheen across the pane, the pointer's light when the pane follows it, and a soft shadow. `material` shapes the body:
// 0 smoke, 1 frost (paler, coarser grain), 2 fluted (vertical ribs), 3 prism (the edgeLight splits into the spectrum).
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 box;
    vec2 lightPosition;
    float pad;
    float radius;
    float edgeLight;
    float edgeGlow;
    float grain;
    float activeGlow;
    float shadow;
    float material;
    float ribWidth;
    vec4 tint;
    vec4 highlight;
    vec4 highlightTint;
};

float rounded(vec2 p, vec2 half_, float r) {
    vec2 q = abs(p) - half_ + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void main() {
    vec2 p = qt_TexCoord0 * (box + 2.0 * pad) - pad;
    vec2 c = box * 0.5;
    float r = min(radius, min(c.x, c.y));
    float d = rounded(p - c, c, r);
    float inside = smoothstep(0.75, -0.75, d);
    vec2 uv = clamp(p / max(box, vec2(1.0)), 0.0, 1.0);
    // Is the tint light (paper) or dark (smoke)?
    float paper = step(0.5, dot(tint.rgb, vec3(0.2126, 0.7152, 0.0722)));
    vec3 white = vec3(1.0);

    vec3 body = tint.rgb;
    float bodyAlpha = tint.a;
    // A pane under a lamp: a little brighter along its top.
    body += white * 0.045 * pow(1.0 - uv.y, 1.6) * (1.0 - paper * 0.6);
    body -= white * 0.025 * pow(uv.y, 2.0) * (1.0 - paper);

    // The glass's thickness: light gathered just inside the edge, strongest along the top.
    float depth = -d;
    float thick = exp(-max(depth, 0.0) / 7.0) * (0.55 + 0.45 * (1.0 - uv.y));
    body += white * thick * 0.07 * edgeLight;

    // A broad sheen across the pane, falling from the upper left.
    vec2 diag = normalize(vec2(1.0, 0.62));
    float across = dot(p / max(box.x, 1.0), diag);
    float sheen = exp(-pow((across - 0.18) / 0.22, 2.0)) * (1.0 - uv.y * 0.7);
    body += white * sheen * 0.035 * edgeGlow * (1.0 - paper * 0.5);

    // The pointer's light, when the pane follows it.
    vec2 toLight = p - lightPosition;
    float reach = max(min(box.x, box.y) * 0.9, 60.0);
    float near = exp(-dot(toLight, toLight) / (reach * reach));
    body += mix(white, highlight.rgb, 0.25) * near * 0.06 * edgeGlow;

    // What is active glows up from its bottom edge in the light's colour.
    float fromBottom = (box.y - p.y) / max(box.y, 1.0);
    float mid = (uv.x - 0.5) * 2.0;
    float glow = exp(-fromBottom * fromBottom * 10.0) * exp(-mid * mid * 0.8) * activeGlow;
    vec3 glowInk = mix(highlight.rgb, highlightTint.rgb, uv.x);
    body += glowInk * glow * 0.35;
    bodyAlpha = min(1.0, bodyAlpha + glow * 0.15);

    if (material > 0.5 && material < 1.5) {
        body = mix(body, white * (0.5 + paper * 0.45), 0.08);
        bodyAlpha = min(1.0, bodyAlpha + 0.08);
    } else if (material > 1.5 && material < 2.5) {
        float w = max(ribWidth, 3.0);
        float ph = fract(p.x / w);
        body += white * 0.04 * sin(ph * 3.14159) * (0.5 + 0.5 * (1.0 - uv.y));
        body -= white * 0.03 * smoothstep(0.9, 1.0, ph);
    }

    body += (hash(floor(gl_FragCoord.xy) + 0.5) - 0.5) * grain * (material > 0.5 && material < 1.5 ? 0.07 : 0.035);

    // The specular edgeLight: where the edge faces the light it is bright, opposite it a faint echo, between them a hairline.
    vec2 outward = normalize(p - c + 0.0001);
    vec2 sun = normalize(vec2(-0.55, -0.83));
    float facing = max(0.0, dot(outward, sun));
    float echo = max(0.0, dot(outward, -sun));
    float edgeBand = smoothstep(1.25, 0.0, abs(d + 0.6));
    float catchLight = edgeLight * (0.09 + 0.62 * pow(facing, 3.0) + 0.2 * pow(echo, 4.0) + 0.25 * near * edgeGlow);
    vec3 rimInk = mix(white, highlight.rgb, 0.18) * catchLight;
    if (material > 2.5) {
        // Prism: the edgeLight splits as a lens edge would, warm on one side, cool on the other.
        float t = atan(outward.y, outward.x) / 6.28318 + 0.5;
        vec3 spectrum = 0.5 + 0.5 * cos(6.28318 * (t * 1.6 + vec3(0.0, 0.33, 0.67)));
        rimInk = mix(rimInk, spectrum * (catchLight + 0.18 * edgeLight), 0.7);
    }
    rimInk += glowInk * glow * 0.6 * edgeLight;
    float rimAlpha = edgeBand * clamp(catchLight * (paper > 0.5 ? 0.8 : 1.0) + glow * 0.4, 0.0, 1.0);
    if (paper > 0.5) rimInk = mix(rimInk, white, 0.6);

    // A soft shadow, a little below the pane.
    float sd = rounded(p - c - vec2(0.0, pad * 0.18), c, r);
    float drop = (1.0 - inside) * exp(-max(sd, 0.0) / (pad * 0.38 + 1.0)) * 0.22 * shadow;

    vec3 rgb = body * inside * bodyAlpha;
    float alpha = bodyAlpha * inside;
    rgb = rgb * (1.0 - rimAlpha) + rimInk * rimAlpha;
    alpha = max(alpha, rimAlpha);
    alpha = alpha + drop * (1.0 - alpha);
    fragColor = vec4(rgb, alpha) * qt_Opacity;
}
