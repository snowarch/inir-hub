#version 440
// One pass of the iRiS field. Every body iRiS draws on an output is a rounded
// box in a signed-distance field, smooth-unioned: a shape that comes near
// another does not overlap it — the two fuse, and pulling them apart draws a
// neck that thins and lets go. One silhouette, however many things are on it.
//
// A body that paints itself (anything that clips its content, carries a
// hairline, or must stay opaque for reasons of its own) stays in the field for
// the joins it makes. The field is drawn *under* every body, and every body iRiS
// paints is opaque black, so the field fills the whole union and lets the bodies
// cover what they cover. It used to subtract their interiors instead, and that
// subtraction was what made a closing card look like it was switching off the
// piece underneath it: a body on its way out punched its own shape out of the
// bodies it passed over, and they came back the instant it finished. A hole in
// the material is not a morph.
//
// There is one pass, over the bounding box of what it has to draw: `viewport` is
// where it sits on the output and every shape is given in screen pixels. One
// pass and not one per cluster, because the cost of this is per ShaderEffect and
// not per pixel — four small passes measured five times the CPU of a single
// large one, on the same bodies.
//
// Shapes are one vec4 each because a ShaderEffect maps no uniform array: `shapeN` is
// (centre.x, centre.y, half.x, half.y) in screen pixels, `cornersN` its corner radii
// (upper left, upper right, lower right, lower left), `linkN` how it meets the others.
//
// Four shaders come out of this file (`field-bench.py build`): the plain one, and with
// FIELD_GLOW, FIELD_LEAK or FIELD_STREAK the texture that lights its bodies. IrisField.qml
// picks by IrisStyle's texture. Every look in one shader was 36000 instructions on Tiger
// Lake: SIMD8 only, 323 spills, the lag of every Intel laptop (testers, 11-02). What holds
// it down: no per-pixel array of the bodies (each element is registers for the whole
// pass), one walk over them bounded by how many there are, a far body rejected by two
// comparisons. `field-bench.py intel` reads what the compiler makes of it.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    // This pass: where it sits on the output, and how big it is.
    vec4 viewport;
    // The output, so the frame can be evaluated in screen space from any pass.
    vec2 screen;
    // x: the default join depth, in pixels, used by the frame. y: 1 while the
    // frame is part of the field. z: the frame's band. w: its inner corner radius.
    vec4 field;
    vec4 tint;
    // The hairline that holds the silhouette over dark windows. One outline for
    // one shape: drawn from the union, so it never crosses a weld, and drawn
    // over the bodies that paint themselves so theirs is the same line.
    vec4 rim;
    // x: how wide that hairline is, in pixels. y: 1 while it is drawn.
    vec4 edge;
    vec4 shape0; vec4 shape1; vec4 shape2; vec4 shape3;
    vec4 shape4; vec4 shape5; vec4 shape6; vec4 shape7;
    vec4 shape8; vec4 shape9; vec4 shape10; vec4 shape11;
    vec4 shape12; vec4 shape13; vec4 shape14; vec4 shape15;
    vec4 shape16; vec4 shape17; vec4 shape18; vec4 shape19;
    vec4 corners0; vec4 corners1; vec4 corners2; vec4 corners3;
    vec4 corners4; vec4 corners5; vec4 corners6; vec4 corners7;
    vec4 corners8; vec4 corners9; vec4 corners10; vec4 corners11;
    vec4 corners12; vec4 corners13; vec4 corners14; vec4 corners15;
    vec4 corners16; vec4 corners17; vec4 corners18; vec4 corners19;
    // How each body meets the rest.
    // x: how deep its joins are. A body that is an extension of what opened it melts
    // generously; a satellite beside the Island keeps a crisp edge. The pair takes the depth
    // of whichever body is folded in later, which is the one that arrived: the thing that
    // grew is what decides how it meets what it grew from.
    // y: whom it melts into: 0 nothing, -1 the frame, n the shape at n - 1. A body melts only
    // into what it grew from. Folding every body into the union of everything before it made
    // a panel melt into the satellites beside its origin, and a morph that sticks to whatever
    // is near is a simulation of one.
    // z: a second body it belongs to, same encoding: a satellite grows out of the Island and
    // rests on the edge, and melts into both.
    // w: its material: 0 solid, 1 glass over the blurred wallpaper, 2 glass the compositor
    // blurs from behind. 4 more when it paints itself: such a body brings its own shadow.
    vec4 link0; vec4 link1; vec4 link2; vec4 link3;
    vec4 link4; vec4 link5; vec4 link6; vec4 link7;
    vec4 link8; vec4 link9; vec4 link10; vec4 link11;
    vec4 link12; vec4 link13; vec4 link14; vec4 link15;
    vec4 link16; vec4 link17; vec4 link18; vec4 link19;
    // x: 1 once the blurred wallpaper is ready. y: the frame's material, same
    // encoding. z: how much of the tint stays over glass. w: the glass edge light.
    vec4 glass;
    // How far the band's inner line swells on each side (left, top, right,
    // bottom) with the music, and x: the travelling phase of that swell.
    vec4 edgeWave;
    vec4 waveClock;
    // x: appearance (0 sculpted, 1 etched, 2 satin); y: music level;
    // z: light opacity; w: treatment width in screen pixels.
    vec4 frameLight;
    vec4 frameInk;
    // Where this field's window sits on its output (x, y) and the output's size (z, w), so a
    // field in a small window (a menu) samples the wallpaper glass at the right place.
    vec4 scene;
    // Left, top, right, bottom of an inner rectangle nothing reaches: its pixels skip the whole pass.
    vec4 quiet;
    // x: how many bodies the table holds. y: how far past a silhouette anything draws, in pixels. z: 1 with any glass.
    vec4 extent;
    // The colour that lights the cut edge of blurred glass (IrisStyle.glassEdgeColour).
    vec4 sheen;
    // A body's light (IrisStyle.bodyTop, bodyFoot): lit from above, as Ricelin's card. rgb: what its tint leans to at the
    // top and at the foot, a: how far. Both 0 for a texture that lights itself.
    vec4 bodyTop;
    vec4 bodyFoot;
    // x: light where the edge faces up, y: the line elsewhere, z: its width in pixels, w: 1 when solid bodies wear it too.
    vec4 edgeGlass;
    // Afterglow (IrisStyle.afterglow*). x: on, y: chrome, z: bloom, w: signal, each 0..1.
    vec4 glowMix;
    // rgb: the grade's shadow hue; a: 1 on a paper scheme.
    vec4 glowShadow;
    // rgb: the grade's key light; a: atmosphere 0..1.
    vec4 glowLight;
    // rgb: the bloom's colour; a: its radius in pixels.
    vec4 glowBloom;
    // x: bevel width, y: scanline pitch, z: convergence, all in pixels.
    vec4 glowShape;
    // The shadow the bodies cast (IrisStyle.shadow): one shadow of the joined silhouette, so a weld or a notch's
    // shoulders cast with the body and two bodies that meet never darken twice. Bodies that paint themselves bring
    // their own. Premultiplied, as Qt hands a QML color to a shader.
    vec4 shade;
    // x: how far down it falls, y: its blur, in pixels; z: 1 while it is drawn.
    vec4 shadeShape;
    // Light leak (IrisStyle.leak*): one light per output, the same IrisLeakWallpaper.frag lays over the wallpaper.
    // x: on, y: light, z: spill, w: prism, each 0..1.
    vec4 leakMix;
    // x: grain, y: streaks, each 0..1; z: the grain's size, w: how far the spill reaches, in pixels.
    vec4 leakGrain;
    // x: how deep the rim that faces the light burns, in pixels, one for every body so a weld never steps; y: the
    // band's share of the spill; z: how strongly the frame's band is exposed (Light leak › Frame), blended into the bodies
    // welded to it by nearness, never cut at a shoulder.
    vec4 leakShape;
    // The grade, warm end to cool end. leakStop0.a: 1 on a paper scheme.
    vec4 leakStop0; vec4 leakStop1; vec4 leakStop2; vec4 leakStop3; vec4 leakStop4;
    // rgb: the white the grade's hottest light runs to.
    vec4 leakCore;
    // Three sources. At: centre in the output's uv, radii in output heights. Form: x rotation (radians), y intensity,
    // z a ring's width in radii (0: a disc), w how much brighter its upper side is (-1..1). Hue: where on the grade,
    // x + y·distance + z·up + w·across.
    vec4 leakAt0; vec4 leakAt1; vec4 leakAt2;
    vec4 leakForm0; vec4 leakForm1; vec4 leakForm2;
    vec4 leakHue0; vec4 leakHue1; vec4 leakHue2;
    // A body that wears a picture as its material (the Island's player wears its cover). x: that body's index + 1,
    // 0 for none; y: how much of the picture shows, 0..1; z: the picture's width over its height; w: how far past the
    // band's inner line it takes to come in, in pixels (0: it runs into the band).
    vec4 artLane;
    // Light streak (IrisStyle.streakMix): x on, y aurora, z light, w trails; each hue's w is where its curtain hangs
    // across the output, 0..1.
    vec4 streakMix;
    vec4 streakHue0; vec4 streakHue1; vec4 streakHue2;
    // xy: the light's place on the output, under the Island (px); z: one device pixel; w: how far the light falls past a
    // silhouette (IrisStyle.streakReach).
    vec4 streakSource;
    // What each body moved over the last frames (centre xy, half size zw): a long exposure of its lit edge.
    vec4 trail0; vec4 trail1; vec4 trail2; vec4 trail3; vec4 trail4; 
    vec4 trail5; vec4 trail6; vec4 trail7; vec4 trail8; vec4 trail9; 
    vec4 trail10; vec4 trail11; vec4 trail12; vec4 trail13; vec4 trail14; 
    vec4 trail15; vec4 trail16; vec4 trail17; vec4 trail18; vec4 trail19;
} u;
layout(binding = 1) uniform sampler2D backdrop;
// The wallpaper before the blur: glass materialises from it to `backdrop` as its frost rises.
layout(binding = 2) uniform sampler2D clearBackdrop;
// The picture `artLane` names, premultiplied.
layout(binding = 3) uniform sampler2D art;

const float FAR = 1e8;

float roundedBox(vec2 p, vec2 centre, vec2 halfSize, float radius) {
    float r = min(radius, min(halfSize.x, halfSize.y));
    vec2 q = abs(p - centre) - (halfSize - r);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// A large round corner is continuous (a squircle, Apple's continuous corner): the curve leaves the straight edge with
// no jump in curvature, where a circular arc starts bending at once. It is the quartic superellipse |x|^4 + |y|^4 = R^4
// over SQUIRCLE_REACH times the radius, which puts its apex where the circle's is (1 - 1/sqrt2 = k (1 - 2^-1/4)), so a
// body looks as round as its radius says and only the shoulder softens. The quartic's value is divided by its gradient
// to read as a distance near the edge (the rims and the glass lip sit there). A capsule's ends stay circular, as Apple's
// do. IrisBlurRegion.squircled draws the same corner by rows.
const float SQUIRCLE_REACH = 1.8409;

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

// A body has a radius per corner (upper left, upper right, lower right, lower left): a menu nests the one corner that
// faces the frame's or a fillet's curve and keeps its own at the other three. Each quadrant is the box with its own
// corner's radius all round, which is that corner exactly: a squircle's reach stops at the body's half, and the straight
// runs between them read no radius.
float bodyBox(vec2 p, vec2 centre, vec2 halfSize, vec4 corners) {
    vec2 d = p - centre;
    return squircleBox(p, centre, halfSize, d.y < 0.0 ? (d.x < 0.0 ? corners.x : corners.y) : (d.x < 0.0 ? corners.w : corners.z));
}

#ifdef FIELD_GLOW
// The chrome bevel's environment by elevation e: -1 ground, 0 horizon, 1 sky.
vec3 chromeAt(float e, vec3 sky, vec3 hot, vec3 ground, vec3 deep) {
    vec3 c = e > 0.0 ? mix(hot, sky, smoothstep(0.0, 0.75, e)) : mix(ground, deep, smoothstep(0.0, 0.55, -e));
    return c + hot * exp(-(e * e) / 0.014) * 0.6;
}

float bayer4(vec2 p) {
    ivec2 i = ivec2(mod(floor(p), 4.0));
    int k = i.x + i.y * 4;
    float m = k == 0 ? 0.0 : k == 1 ? 8.0 : k == 2 ? 2.0 : k == 3 ? 10.0 : k == 4 ? 12.0 : k == 5 ? 4.0 : k == 6 ? 14.0 : k == 7 ? 6.0
        : k == 8 ? 3.0 : k == 9 ? 11.0 : k == 10 ? 1.0 : k == 11 ? 9.0 : k == 12 ? 15.0 : k == 13 ? 7.0 : k == 14 ? 13.0 : 5.0;
    return m / 16.0 - 0.5;
}
#endif

// Polynomial smooth minimum: the join is a fillet `k` pixels deep, which is what
// makes two bodies read as one that swelled rather than two that overlap.
float smoothUnion(float a, float b, float k) {
    if (k <= 0.001)
        return min(a, b);
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

vec4 shapeAt(int i) {
    if (i < 8) {
        if (i < 4) return i == 0 ? u.shape0 : i == 1 ? u.shape1 : i == 2 ? u.shape2 : u.shape3;
        return i == 4 ? u.shape4 : i == 5 ? u.shape5 : i == 6 ? u.shape6 : u.shape7;
    }
    if (i < 16) {
        if (i < 12) return i == 8 ? u.shape8 : i == 9 ? u.shape9 : i == 10 ? u.shape10 : u.shape11;
        return i == 12 ? u.shape12 : i == 13 ? u.shape13 : i == 14 ? u.shape14 : u.shape15;
    }
    return i == 16 ? u.shape16 : i == 17 ? u.shape17 : i == 18 ? u.shape18 : u.shape19;
}

vec4 cornersAt(int i) {
    if (i < 8) {
        if (i < 4) return i == 0 ? u.corners0 : i == 1 ? u.corners1 : i == 2 ? u.corners2 : u.corners3;
        return i == 4 ? u.corners4 : i == 5 ? u.corners5 : i == 6 ? u.corners6 : u.corners7;
    }
    if (i < 16) {
        if (i < 12) return i == 8 ? u.corners8 : i == 9 ? u.corners9 : i == 10 ? u.corners10 : u.corners11;
        return i == 12 ? u.corners12 : i == 13 ? u.corners13 : i == 14 ? u.corners14 : u.corners15;
    }
    return i == 16 ? u.corners16 : i == 17 ? u.corners17 : i == 18 ? u.corners18 : u.corners19;
}

vec4 linkAt(int i) {
    if (i < 8) {
        if (i < 4) return i == 0 ? u.link0 : i == 1 ? u.link1 : i == 2 ? u.link2 : u.link3;
        return i == 4 ? u.link4 : i == 5 ? u.link5 : i == 6 ? u.link6 : u.link7;
    }
    if (i < 16) {
        if (i < 12) return i == 8 ? u.link8 : i == 9 ? u.link9 : i == 10 ? u.link10 : u.link11;
        return i == 12 ? u.link12 : i == 13 ? u.link13 : i == 14 ? u.link14 : u.link15;
    }
    return i == 16 ? u.link16 : i == 17 ? u.link17 : i == 18 ? u.link18 : u.link19;
}

// What a join names at p: the frame, or the body at `name - 1`; FAR when it isn't there.
float joinedAt(float name, vec2 p, float frame) {
    if (name < 0.0)
        return frame;
    int j = int(name + 0.5) - 1;
    vec4 s = shapeAt(j);
    return s.z > 0.0 && s.w > 0.0 ? bodyBox(p, s.xy, s.zw, cornersAt(j)) : FAR * 10.0;
}

// A body's say in what a point takes from the bodies around it, by how near it is. Only how they compare counts: it falls
// by e every 12 px, so one 60 px further off than the nearest is nothing. Measured from zero so the walk needn't know the
// final silhouette to add it up; clamped where a float still holds the sum of twenty.
float nearnessOf(float d) {
    return exp(-clamp(d, -700.0, 700.0) / 12.0);
}

#ifdef FIELD_STREAK
vec4 trailAt(int i) {
    if (i == 0) return u.trail0;
    if (i == 1) return u.trail1;
    if (i == 2) return u.trail2;
    if (i == 3) return u.trail3;
    if (i == 4) return u.trail4;
    if (i == 5) return u.trail5;
    if (i == 6) return u.trail6;
    if (i == 7) return u.trail7;
    if (i == 8) return u.trail8;
    if (i == 9) return u.trail9;
    if (i == 10) return u.trail10;
    if (i == 11) return u.trail11;
    if (i == 12) return u.trail12;
    if (i == 13) return u.trail13;
    if (i == 14) return u.trail14;
    if (i == 15) return u.trail15;
    if (i == 16) return u.trail16;
    if (i == 17) return u.trail17;
    if (i == 18) return u.trail18;
    return u.trail19;
}

// Light streak's aurora: three curtains of the person's colours hang across the output, each where its hue says, its
// fold swaying down the screen and fine rays running along it. Static. Returns the hue at q; glow is how much curtain
// is there. IrisStreakPlate.frag keeps a copy: change both.
vec3 streakCurtains(vec2 q, vec2 size, out float glow) {
    vec3 sum = vec3(0.0);
    float weight = 0.0;
    for (int k = 0; k < 3; ++k) {
        vec4 h = k == 0 ? u.streakHue0 : (k == 1 ? u.streakHue1 : u.streakHue2);
        float fk = float(k);
        float down = q.y / size.y;
        float sway = 0.07 * sin(down * 3.4 + fk * 2.1) + 0.025 * sin(down * 9.0 - fk * 1.7);
        float x = (q.x / size.x - h.w - sway) / 0.2;
        float rays = 0.74 + 0.26 * sin(q.x * 0.031 + fk * 1.3 + 2.2 * sin(q.y * 0.0037 + fk));
        float c = exp(-x * x) * rays;
        sum += h.rgb * c;
        weight += c;
    }
    glow = clamp(weight, 0.0, 1.0);
    return sum / max(weight, 1e-3);
}
#endif

// How much of a Gaussian-blurred edge reaches a point `x` sigmas outside it: 0.5 erfc(x / sqrt 2), with erf from an
// exp-only tanh (GLSL ES 1.00 has no tanh).
float blurredEdge(float x) {
    float y = x * 0.70710678;
    float t = 2.0 * y * (1.12838 + 0.10091 * y * y);
    float erfApprox = 1.0 - 2.0 / (exp(clamp(t, -30.0, 30.0)) + 1.0);
    return 0.5 - 0.5 * erfApprox;
}

// Interleaved gradient noise (Jimenez 2014): a dither under a level of 8 bits breaks the bands a blurred wallpaper and
// a long shadow ramp leave, without a texture.
float ign(vec2 p) {
    return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

#ifdef FIELD_LEAK
// Light leak. IrisLeakWallpaper.frag and IrisLeakPlate.frag keep copies of leakHash, leakNoise, leakRamp and
// leakLight, and IrisLeakPlate.frag of the bodies' film below: change all three.
float leakHash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float leakNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(leakHash(i), leakHash(i + vec2(1.0, 0.0)), f.x),
               mix(leakHash(i + vec2(0.0, 1.0)), leakHash(i + vec2(1.0, 1.0)), f.x), f.y);
}

vec3 leakRamp(float t) {
    float s = clamp(t, 0.0, 1.0) * 4.0;
    vec3 a = s < 1.0 ? u.leakStop0.rgb : s < 2.0 ? u.leakStop1.rgb : s < 3.0 ? u.leakStop2.rgb : u.leakStop3.rgb;
    vec3 b = s < 1.0 ? u.leakStop1.rgb : s < 2.0 ? u.leakStop2.rgb : s < 3.0 ? u.leakStop3.rgb : u.leakStop4.rgb;
    float f = s - min(floor(s), 3.0);
    return mix(a, b, f * f * (3.0 - 2.0 * f));
}

// The leak's exposure at a point of the output, in pixels: three soft shapes of light (a lens, an orb, a beam), each
// spread per channel by the prism (red reaches furthest, as through a lens and a film's halation), their edges
// scattered by the grain (the grain-gradient look of the textures it comes from), broken into streaks, then exposed
// like film (1 - e^-x) so a hot core whitens instead of clipping. `wash` is the colour every point takes, lit or not;
// `toward` the way the light comes from at that point (unit, y down), so an edge burns only where it faces it.
vec3 leakLight(vec2 at, vec2 size, float scatter, out vec3 wash, out vec2 toward) {
    float aspect = size.x / max(size.y, 1.0);
    vec2 q = at / max(size.y, 1.0);
    float prism = u.leakMix.w;
    vec3 sum = vec3(0.0);
    float tone = 0.0;
    float weights = 0.0;
    vec2 from = vec2(0.0);
    for (int i = 0; i < 3; ++i) {
        vec4 place = i == 0 ? u.leakAt0 : i == 1 ? u.leakAt1 : u.leakAt2;
        vec4 form = i == 0 ? u.leakForm0 : i == 1 ? u.leakForm1 : u.leakForm2;
        vec4 hue = i == 0 ? u.leakHue0 : i == 1 ? u.leakHue1 : u.leakHue2;
        if (form.y <= 0.0)
            continue;
        vec2 d = q - vec2(place.x * aspect, place.y);
        float c = cos(form.x);
        float s = sin(form.x);
        d = vec2(c * d.x + s * d.y, c * d.y - s * d.x) / max(place.zw, vec2(1e-3));
        float rho = length(d);
        float up = -d.y / max(rho, 1e-4);
        float t = hue.x + hue.y * rho + hue.z * up * min(1.0, rho * 2.5) + hue.w * d.x;
        float strength = form.y * max(0.0, 1.0 + form.w * up);
        float weight = strength / (1.0 + 2.0 * rho * rho);
        tone += weight * t;
        weights += weight;
        // Down the shape's own slope (its scaled, rotated distance taken back to the screen), so a thin horizon lights
        // the edges that face it, not the ones that face its centre.
        vec2 slope = d / max(place.zw, vec2(1e-3));
        slope = vec2(c * slope.x - s * slope.y, s * slope.x + c * slope.y);
        from -= slope / max(length(slope), 1e-4) * weight;
        vec3 ramp = leakRamp(t) * strength;
        for (int ch = 0; ch < 3; ++ch) {
            float spread = float(ch - 1);
            float r = rho * (1.0 + prism * 0.07 * spread);
            // The grain scatters where the shape ends, so its edge dissolves into grain instead of ending.
            float x = (form.z > 0.0 ? (r - 1.0) / form.z : r) * (1.0 + scatter);
            float x2 = x * x;
            // A body of light with a soft shoulder and a faint glow past it: light that leaks has no hard edge.
            float fall = exp(-1.6 * x2 * (1.0 + x2)) + 0.1 / (1.0 + 5.0 * x2);
            sum[ch] += ramp[ch] * fall;
        }
    }
    float streak = 0.5 * leakNoise(vec2(at.x / 7.0, at.y / 260.0)) + 0.5 * leakNoise(vec2(at.x / 23.0, at.y / 140.0));
    sum *= mix(1.0, 0.5 + streak, u.leakGrain.y);
    // Exposed like film: the hue holds while the light rises.
    float peak = max(sum.r, max(sum.g, sum.b));
    float exposed = 1.0 - exp(-1.4 * peak);
    vec3 hue = sum / max(peak, 1e-4);
    // The colour every point takes, lit or not: the light's own hue where it is strong, the grade where it fades,
    // at full saturation (max channel 1). It is what turns a body into a grain gradient.
    // It drifts along the grade across the screen, so each body carries its own stretch of the gradient.
    float drift = (0.6 * at.x / max(size.x, 1.0) + 0.4 * at.y / max(size.y, 1.0) - 0.5) * 0.5;
    vec3 grade = leakRamp((weights > 1e-4 ? tone / weights : 0.0) + drift);
    wash = mix(grade, hue, smoothstep(0.05, 0.6, exposed));
    wash /= max(max(wash.r, max(wash.g, wash.b)), 1e-3);
    toward = from / max(length(from), 1e-4);
    // Its core runs to the grade's own white: the colour lives where the light fades, as on film.
    return mix(hue * exposed, u.leakCore.rgb * exposed, 0.6 * smoothstep(0.5, 1.0, exposed));
}
#endif

void main() {
    vec2 p = u.viewport.xy + qt_TexCoord0 * max(u.viewport.zw, vec2(1.0));
    if (p.x > u.quiet.x && p.y > u.quiet.y && p.x < u.quiet.z && p.y < u.quiet.w) {
        fragColor = vec4(0.0);
        return;
    }
    float united = FAR * 10.0;

    // The frame is the complement of the screen's inner rounded rectangle: every
    // pixel outside it is material, so the band and its concentric inner corners
    // come out of the same formula the bodies use, and a body that reaches the
    // edge fuses with it instead of sitting on it.
    float frameDistance = FAR * 10.0;
    // Places can render their own field in a window inset by the band.
    // Sample the frame in output coordinates so their joins stay aligned.
    vec2 frameP = p + u.scene.xy;
    vec2 size = max(u.scene.zw, vec2(1.0));
    // The band one shadow's fall lower.
    float frameCast = FAR * 10.0;
#ifdef FIELD_GLOW
    // Afterglow's normal comes from the joined field with every corner at least the bevel (a tighter corner creased the
    // bevel along its diagonal).
    float bevel = max(1.0, u.glowShape.x);
    float frameN = FAR * 10.0;
#endif
    if (u.field.y > 0.5) {
        vec2 lo = vec2(u.field.z);
        vec2 hi = size - vec2(u.field.z);
        // Four sines a pixel, only while music swells the band.
        if (u.edgeWave != vec4(0.0)) {
            float t = u.waveClock.x;
            float alongY = 0.60 + 0.24 * sin(frameP.y * 0.011 + t) + 0.16 * sin(frameP.y * 0.027 - t * 1.4);
            float alongX = 0.60 + 0.24 * sin(frameP.x * 0.009 - t) + 0.16 * sin(frameP.x * 0.023 + t * 1.2);
            lo += vec2(u.edgeWave.x * alongY, u.edgeWave.y * alongX);
            hi -= vec2(u.edgeWave.z * alongY, u.edgeWave.w * alongX);
        }
        vec2 frameCentre = (lo + hi) * 0.5;
        vec2 frameHalf = max((hi - lo) * 0.5, vec2(0.0));
        frameDistance = -squircleBox(frameP, frameCentre, frameHalf, u.field.w);
        united = frameDistance;
        frameCast = -squircleBox(frameP - vec2(0.0, u.shadeShape.x), frameCentre, frameHalf, u.field.w);
#ifdef FIELD_GLOW
        frameN = -squircleBox(frameP, frameCentre, frameHalf, max(u.field.w, bevel));
#endif
    }
    float frameClusterDistance = frameDistance;

    // Material is blended by a soft minimum of distances, so where a solid body
    // melts into glass the fillet shades from one to the other instead of cutting.
    vec3 weights = vec3(0.0);
    // How far the glass under this pixel has materialised: glass comes in by its blur, not by fading. A body still
    // arriving carries it in its material's fraction (1 - 0.4 * (1 - frost)); everything else is fully frosted.
    float frostSum = 0.0;
    bool anyGlass = u.extent.z > 0.5;
    if (anyGlass && u.field.y > 0.5) {
        float w = exp(-clamp(frameDistance, -40.0, 40.0) / 2.0);
        weights += w * vec3(u.glass.y < 0.5 ? 1.0 : 0.0, u.glass.y > 0.5 && u.glass.y < 1.5 ? 1.0 : 0.0, u.glass.y > 1.5 ? 1.0 : 0.0);
        frostSum += u.glass.y > 0.5 ? w : 0.0;
    }
    // Each body runs top to foot across itself; the band runs across the output, so a body welded to its top edge starts
    // where the band stands and one welded to its foot ends there. Blended by nearness, so a weld shades, never steps.
    bool bodyLit = u.bodyTop.a + u.bodyFoot.a > 0.001;
    int artAt = int(u.artLane.x + 0.5) - 1;
    bool wearsArt = artAt >= 0 && artAt < 20 && u.artLane.y > 0.001;
    bool leans = bodyLit || wearsArt;
    float along = 0.0;
    float nearness = 0.0;
    float artNear = 0.0;
    float artDistance = FAR * 10.0;
    if (leans && u.field.y > 0.5 && frameDistance < 61.0) {
        float w = nearnessOf(frameDistance);
        along += w * clamp(frameP.y / size.y, 0.0, 1.0);
        nearness += w;
    }
#ifdef FIELD_GLOW
    // Its light is blended by nearness so a join shades from one body into the other instead of creasing. The frame and
    // the bodies welded to it are one chassis lit across the output: a Dock lit from its own top met the dark band at its
    // shoulders as a second object. A floating body is lit across itself.
    float unitedN = frameN;
    float gouraudSum = 0.0;
    float lipSum = 0.0;
    float weightSum = 0.0;
    vec2 across = clamp(frameP / size, 0.0, 1.0);
    float chassisLight = mix(mix(1.0, 0.82, across.x), mix(0.34, 0.22, across.x), across.y);
    if (u.field.y > 0.5) {
        float w = nearnessOf(frameDistance);
        gouraudSum += w * chassisLight;
        lipSum += w * bevel;
        weightSum += w;
    }
#endif
#ifdef FIELD_STREAK
    // Light streak's light past a silhouette faces the light by a softened field: the nearest body's normal jumps where
    // two bodies are equally near (between two bubbles) and cut the fall into straight-edged strips.
    float soft = 0.35 * max(1.0, u.streakSource.w);
    float unitedN = frameDistance;
#endif
    // What the compositor's blur region holds (IrisBlurRegion): the compositor-glass bodies and their joins with
    // each other; the band and its joins only while the frame is compositor glass too.
    float held = FAR * 10.0;
    // The shadow's silhouette, one fall lower: the bodies that don't paint themselves and their joins; `withFrame` those
    // grown out of the frame, joined with it. Deep inside a body it is worked out by nobody: nothing casts on what is opaque.
    bool shadowed = u.shadeShape.z > 0.5 && u.shade.a > 0.0;
    vec2 ps = p - vec2(0.0, u.shadeShape.x);
    float alone = FAR * 10.0;
    float withFrame = FAR * 10.0;
    // Nothing draws past `extent.y` and nearness stops at 60: a body further off than that is two comparisons.
    float cull = u.extent.y + 64.0;
    int count = int(u.extent.x + 0.5);
    for (int i = 0; i < count; ++i) {
        vec4 s = shapeAt(i);
        vec2 past = abs(p - s.xy) - s.zw;
        if (s.z <= 0.0 || s.w <= 0.0 || max(past.x, past.y) > cull)
            continue;
        vec4 link = linkAt(i);
        vec4 corners = cornersAt(i);
        float d = bodyBox(p, s.xy, s.zw, corners);
        float k = max(0.0, link.x);
        bool casts = link.w < 3.0;
        float m = casts ? link.w : link.w - 4.0;
        united = min(united, d);
        if (m > 1.5)
            held = min(held, d);
        casts = casts && shadowed;
        float dCast = casts && d > -u.shadeShape.x - 2.0 ? bodyBox(ps, s.xy, s.zw, corners) : d;
        if (casts)
            alone = min(alone, dCast);
        if (anyGlass) {
            float w = exp(-clamp(d, -40.0, 40.0) / 2.0);
            weights += w * vec3(m < 0.5 ? 1.0 : 0.0, m > 0.5 && m < 1.5 ? 1.0 : 0.0, m > 1.5 ? 1.0 : 0.0);
            frostSum += m > 0.5 ? w * clamp(1.0 - (floor(m + 0.5) - m) / 0.4, 0.0, 1.0) : 0.0;
        }
        if (leans && d < 61.0) {
            float w = nearnessOf(d);
            along += w * clamp((p.y - s.y + s.w) / max(2.0 * s.w, 1.0), 0.0, 1.0);
            nearness += w;
            if (i == artAt) {
                artNear = w;
                artDistance = d;
            }
        }
#ifdef FIELD_GLOW
        float dN = bodyBox(p, s.xy, s.zw, max(corners, vec4(bevel)));
        unitedN = min(unitedN, dN);
        {
            bool welded = u.field.y > 0.5 && (link.y < -0.5 || link.z < -0.5);
            float w = nearnessOf(d);
            vec2 t = clamp((p - s.xy + s.zw) / max(2.0 * s.zw, vec2(1.0)), 0.0, 1.0);
            gouraudSum += w * (welded ? chassisLight : mix(mix(1.0, 0.82, t.x), mix(0.34, 0.22, t.x), t.y));
            // A small body wears a lip in proportion, never a panel's; blended like the light, so it never steps at a weld.
            lipSum += w * min(bevel, max(2.0, 0.3 * min(s.z, s.w)));
            weightSum += w;
        }
#endif
#ifdef FIELD_STREAK
        unitedN = smoothUnion(unitedN, d, soft);
#endif
        // The joins, each only between a body and the one it belongs to. A smooth union is never above the plain one, so
        // taking the minimum adds the fillet there and nowhere else.
        for (int n = 0; n < 2; ++n) {
            float name = n == 0 ? link.y : link.z;
            if (name > -0.5 && name < 0.5)
                continue;
            float other = joinedAt(name, p, frameDistance);
            if (other > FAR)
                continue;
            float fused = smoothUnion(other, d, k);
            united = min(united, fused);
#ifdef FIELD_GLOW
            unitedN = min(unitedN, smoothUnion(name < 0.0 ? frameN : other, dN, k));
#endif
            if (name < 0.0) {
                frameClusterDistance = min(frameClusterDistance, fused);
                if (casts)
                    withFrame = min(withFrame, smoothUnion(frameCast, dCast, k));
            } else {
                float mate = linkAt(int(name + 0.5) - 1).w;
                if (m > 1.5 && (mate < 3.0 ? mate : mate - 4.0) > 1.5)
                    held = min(held, fused);
                if (casts && mate < 3.0)
                    alone = min(alone, smoothUnion(joinedAt(name, ps, frameDistance), dCast, k));
            }
        }
    }

    // How deep a point sits in the material, for what a texture draws inside it (Afterglow's bevel and bloom, Light leak's
    // burn). A body welded to the frame that only meets the band's inner line (the Island at rest, the widget bar) unites
    // with it by a smooth minimum just k/4 deep along that line, and the bevel and the burn drew it as a crease across
    // the body. For the depth alone that seam is filled: the silhouette stays as it is, the inside whole.
#if defined(FIELD_GLOW) || defined(FIELD_LEAK) || defined(FIELD_STREAK)
    float inner = united;
    if (u.field.y > 0.5 && united < 0.0) {
        // The band at rest: what is welded to it stays there while music swells it.
        vec2 lo = vec2(u.field.z) - u.scene.xy;
        vec2 hi = size - vec2(u.field.z) - u.scene.xy;
        float deeper = united;
        for (int i = 0; i < count; ++i) {
            vec4 s = shapeAt(i);
            vec4 link = linkAt(i);
            if (s.z <= 0.0 || s.w <= 0.0 || (link.y > -0.5 && link.z > -0.5))
                continue;
            vec4 corners = cornersAt(i);
            float r = min(max(max(corners.x, corners.y), max(corners.z, corners.w)), min(s.z, s.w));
            float under = u.field.z + 2.0;
            vec2 a = s.xy - s.zw;
            vec2 b = s.xy + s.zw;
            // A strip over the run of each side that meets the band, from a radius inside the body to past the band. It runs
            // on into the corners as far as their curve stays within the crease's depth of the band (k/4): beyond that the
            // lobe a rounded corner leaves at the weld keeps its own edge.
            float k = max(0.0, link.x);
            float c = min(r, 0.25 * k + 1.5);
            float e = sqrt(max(0.0, r * r - (r - c) * (r - c)));
            vec2 run = min(s.zw, s.zw - r + e);
            if (s.w > r + 0.5) {
                if (abs(a.x - lo.x) < 3.0)
                    deeper = min(deeper, roundedBox(p, vec2((lo.x - under + a.x + r) * 0.5, s.y), vec2((a.x + r - lo.x + under) * 0.5, run.y), 0.0));
                if (abs(b.x - hi.x) < 3.0)
                    deeper = min(deeper, roundedBox(p, vec2((b.x - r + hi.x + under) * 0.5, s.y), vec2((hi.x + under - b.x + r) * 0.5, run.y), 0.0));
            }
            if (s.z > r + 0.5) {
                if (abs(a.y - lo.y) < 3.0)
                    deeper = min(deeper, roundedBox(p, vec2(s.x, (lo.y - under + a.y + r) * 0.5), vec2(run.x, (a.y + r - lo.y + under) * 0.5), 0.0));
                if (abs(b.y - hi.y) < 3.0)
                    deeper = min(deeper, roundedBox(p, vec2(s.x, (b.y - r + hi.y + under) * 0.5), vec2(run.x, (hi.y + under - b.y + r) * 0.5), 0.0));
            }
        }
        inner = mix(united, deeper, smoothstep(2.0, 5.0, united - deeper));
    }
#endif
    // Derivatives at the top level: inside a branch that differs between neighbours they are undefined.
    // The gradient in the item's own space (y down on every backend): screen derivatives run y up on OpenGL.
    vec2 dp = vec2(dFdx(p.x), dFdy(p.y));
    dp = vec2(abs(dp.x) > 1e-6 ? dp.x : 1.0, abs(dp.y) > 1e-6 ? dp.y : 1.0);
    vec2 unitedSlope = vec2(dFdx(united), dFdy(united)) / dp;
#if defined(FIELD_GLOW) || defined(FIELD_STREAK)
    vec2 normalSlope = vec2(dFdx(unitedN), dFdy(unitedN)) / dp;
#endif
    if (united > u.extent.y) {
        fragColor = vec4(0.0);
        return;
    }
    // One pixel of coverage, so the contour stays crisp at any scale.
    float coverage = 1.0 - smoothstep(-0.7, 0.7, united);
    vec3 paint = u.tint.rgb;
    if (leans && united < 1.0) {
        if (bodyLit)
            paint = mix(mix(u.tint.rgb, u.bodyTop.rgb, u.bodyTop.a), mix(u.tint.rgb, u.bodyFoot.rgb, u.bodyFoot.a), along / max(nearness, 1e-4));
        // The picture is the body's material, not a rectangle laid inside it: it fills the silhouette the field draws,
        // shoulders and fillets included, and gives way to what the body is welded to by the same nearness the light
        // uses, so a player melts into the band and the strip instead of ending on a straight line inside a curve.
        if (wearsArt && artNear > 0.0) {
            vec4 s = shapeAt(artAt);
            vec2 box = max(2.0 * s.zw, vec2(1.0));
            float aspect = max(u.artLane.z, 1e-3);
            vec2 cover = box.x / box.y > aspect ? vec2(box.x, box.x / aspect) : vec2(box.y * aspect, box.y);
            // An explicit level: implicit derivatives are undefined in a branch that differs between neighbours.
            vec4 picture = textureLod(art, clamp((p - s.xy) / cover + 0.5, 0.0, 1.0), 0.0);
            // Welded to the frame the band keeps its own material and the picture rises out of it, by the distance to
            // the band, so the shoulders and the fillets shade with it.
            float risen = u.field.y > 0.5 && u.artLane.w > 0.0 ? smoothstep(0.0, u.artLane.w, frameDistance) : 1.0;
            // Inside its own body the picture owns the pixel even where another body overlaps it (the strip a grown
            // page swallows); past its edge it shares by nearness.
            float owned = max(artNear / max(nearness, 1e-4), 1.0 - smoothstep(-12.0, 0.0, artDistance));
            paint = mix(paint, picture.rgb + paint * (1.0 - picture.a), u.artLane.y * risen * owned);
        }
    }
    float fillAlpha = coverage * u.tint.a * u.qt_Opacity;
    vec3 colour = paint * fillAlpha;
    float alpha = fillAlpha;
    vec3 share = anyGlass ? weights / max(1e-4, weights.x + weights.y + weights.z) : vec3(1.0, 0.0, 0.0);
    float frosting = weights.y + weights.z > 1e-4 ? clamp(frostSum / (weights.y + weights.z), 0.0, 1.0) : 1.0;
    float frostTint = u.glass.z * frosting;
    // With the frame in another material (the music frame's wallpaper glass, whose band moves every frame) the
    // region carries no band and no join to it, so compositor glass there was a thin tint over the unblurred scene:
    // the fillets under a body and the band beside it showed sharp through. There the band's own material holds.
    if (u.field.y > 0.5 && u.glass.y < 1.5 && share.z > 0.0) {
        float fillet = min(frameDistance, held) - frameClusterDistance;
        float band = max(smoothstep(0.0, 1.0, fillet), 1.0 - smoothstep(-0.7, 0.7, frameDistance));
        float given = share.z * band * smoothstep(-1.5, -0.5, held);
        share.z -= given;
        if (u.glass.y > 0.5) share.y += given; else share.x += given;
    }
    if (u.glass.x < 0.5) { share.x += share.y; share.y = 0.0; }
    vec2 sceneAt = clamp((p + u.scene.xy) / max(u.scene.zw, vec2(1.0)), 0.0, 1.0);
    vec3 behind = share.y > 0.0 ? texture(backdrop, sceneAt).rgb : vec3(0.0);
    if (share.y > 0.0 && frosting < 0.999)
        behind = mix(texture(clearBackdrop, sceneAt).rgb, behind, frosting);
    if (share.x < 0.999) {
        float a = coverage * u.qt_Opacity;
        vec4 solid = vec4(paint, 1.0) * u.tint.a;
        vec4 glassy = vec4(mix(behind, paint, frostTint), 1.0);
        vec4 blurred = vec4(paint * frostTint, frostTint);
        vec4 mixed = (solid * share.x + glassy * share.y + blurred * share.z) * a;
        colour = mixed.rgb;
        alpha = mixed.a;
    }
    // Where nothing opaque covers it. Worked out here, so the silhouette's distances are gone before a texture needs the
    // registers. A body grown out of the frame casts its fillet with the band less the band's own share, so the shoulders
    // cast and the band does not.
    float thrown = 0.0;
    if (shadowed && (coverage < 1.0 || share.z > 0.0)) {
        float sigma = max(1.0, u.shadeShape.y * 0.5);
        thrown = alone < FAR ? blurredEdge(alone / sigma) : 0.0;
        if (withFrame < FAR)
            thrown = max(thrown, max(0.0, blurredEdge(withFrame / sigma) - blurredEdge(frameCast / sigma)));
    }
#ifdef FIELD_GLOW
    {
        bool paper = u.glowShadow.a > 0.5;
        float radiusBloom = max(1.0, u.glowBloom.a);
        float lip = weightSum > 0.0 ? lipSum / weightSum : bevel;
        float gouraud = weightSum > 0.0 ? gouraudSum / weightSum : 0.6;
        // Normals from the joined field (per-body normals break at welds), near edges only; the rest faces up.
        vec2 grad = abs(united) < bevel + 3.5 * radiusBloom + 2.0 ? normalSlope : vec2(0.0, -1.0);
        float slopeLength = length(grad);
        vec2 n = grad / max(slopeLength, 1e-4);
        float facing = dot(n, vec2(-0.42, -0.91));
        // A smooth union is not a true distance inside its fillet: measured by its own slope the bevel keeps its width.
        float depth = -inner / clamp(slopeLength, 0.5, 1.0);
        float atmosphere = u.glowLight.a;
        float chrome = u.glowMix.y;
        float bloom = u.glowMix.z;
        float signal = u.glowMix.w;
        vec3 shade = u.glowShadow.rgb;
        vec3 key = u.glowLight.rgb;

        vec3 base = alpha > 1e-4 ? colour / alpha : u.tint.rgb;
        vec3 lit = paper
            ? base * mix(vec3(1.0), mix(shade, key, gouraud), atmosphere * 0.16) * mix(0.9, 1.0, gouraud)
            : base + shade * atmosphere * (0.05 + 0.42 * (1.0 - gouraud) * (1.0 - gouraud)) + key * atmosphere * 0.14 * gouraud * gouraud;

        // Paper: one pearl lip, no dark ground band (it read as a second contour).
        vec3 sky = paper ? vec3(1.0) : key * 0.92;
        vec3 hot = paper ? mix(key, vec3(1.0), 0.7) : mix(key, vec3(1.0), 0.55);
        vec3 ground = paper ? mix(lit, vec3(1.0), 0.25) : lit * 0.5 + shade * (0.55 + 0.6 * atmosphere);
        vec3 deep = lit;
        // Misconverged guns at more than a fraction of a pixel drew a rainbow outline round every body.
        float spread = paper ? 0.0 : min(0.6, u.glowShape.z * signal);
        vec3 env = vec3(0.0);
        vec3 amount = vec3(0.0);
        for (int c = 0; c < 3; ++c) {
            float d = depth + n.x * spread * float(c - 1);
            float t = clamp(d / lip, 0.0, 1.0);
            float slope = (1.0 - t) * (1.0 - t * 0.5);
            float e = (-n.y * 0.95 - n.x * 0.3) * (slope * 1.55 - 0.55) - 0.12 * (1.0 - slope);
            vec3 reflected = chromeAt(e, sky, hot, ground, deep);
            env[c] = reflected[c];
            amount[c] = (1.0 - smoothstep(0.8, 1.0, t)) * chrome;
        }
        vec3 material = mix(lit, env, amount);
        material += u.glowBloom.rgb * bloom * (paper ? 0.12 : 0.3) * exp(-max(depth, 0.0) / radiusBloom) * (0.35 + 0.65 * max(facing, 0.0));
        float a = mix(alpha, coverage * u.qt_Opacity, max(amount.r, max(amount.g, amount.b)));
        colour = min(material, vec3(1.0)) * a;
        alpha = a;

        // The band round the screen blooms at half: it is a frame, not a light. Paper never blooms: it read as a white cloud.
        if (united > 0.0 && !paper) {
            float halo = bloom * exp(-united / radiusBloom) * (0.45 + 0.55 * max(facing, 0.0)) * (1.0 - coverage) * u.qt_Opacity;
            // By nearness, not by a threshold: a switch at the band drew a line out of every shoulder.
            if (u.field.y > 0.5)
                halo *= 1.0 - 0.5 * exp(-max(frameDistance - united, 0.0) / 24.0);
            colour += u.glowBloom.rgb * halo * 0.42;
        }
        float pitch = max(2.0, u.glowShape.y);
        float line = 0.5 + 0.5 * cos(6.2831853 * (frameP.y + 0.5) / pitch);
        colour *= 1.0 - signal * (paper ? 0.1 : 0.3) * (1.0 - line);
        colour += bayer4(frameP) * (1.5 / 255.0) * alpha;
        colour = max(colour, vec3(0.0));
    }
#endif
    // Light leak: every body is film exposed by one light per output: a grain gradient of the grade inside (photo paper
    // on a paper scheme), the edge that faces the light burnt and split, a halation spilling past the silhouette whose
    // tail breaks into grain. Glass keeps its frost and the light scatters in it. Nothing here depends on which body a
    // pixel belongs to, so the band, the Dock and a bubble are one material through every weld.
#ifdef FIELD_LEAK
    {
        float reach = max(1.0, u.leakGrain.w);
        if (united < 4.0 * reach) {
            bool paper = u.leakStop0.a > 0.5;
            // The frame's own exposure (Texture › Frame) shades into the bodies' over a weld instead of stepping at it.
            float banded = u.field.y > 0.5 ? exp(-max(frameDistance - united, 0.0) / 24.0) : 0.0;
            float exposure = mix(1.0, u.leakShape.z, banded);
            float light = u.leakMix.y * exposure;
            float spill = u.leakMix.z * exposure * mix(1.0, u.leakShape.y, banded);
            float grain = u.leakGrain.x;
            float prism = u.leakMix.w;
            vec2 cell = floor(frameP);
            float g = 0.6 * leakHash(cell) + 0.4 * leakNoise(frameP / max(1.0, u.leakGrain.z)) - 0.5;
            vec3 wash;
            vec2 toward;
            vec3 leak = leakLight(frameP, size, g * grain, wash, toward);
            vec3 chroma = vec3(leakHash(cell + 31.0), leakHash(cell + 57.0), leakHash(cell + 83.0)) - 0.5;
            float lv = max(leak.r, max(leak.g, leak.b));
            float grained = clamp(lv + g * grain * 0.12, 0.0, 1.0);
            // One lip for every body, and an edge burns only where it faces the light, as the edge a leak enters film by:
            // a lip sized per body stepped where the thin band met the Dock, and a burn on every side outlined each body.
            float slope = length(unitedSlope);
            vec2 outward = unitedSlope / max(slope, 1e-4);
            float facing = smoothstep(-0.1, 0.8, dot(outward, toward));
            float depth = max(0.0, -inner / clamp(slope, 0.5, 1.0));
            float lip = max(1.0, u.leakShape.x);
            float burn = light * lv * facing * exp(-depth / lip);
            // A lit edge splits the light as a cut prism does: the grade's spectrum across the first pixels in, its warm end
            // outermost. Only where the light is strong.
            float band = clamp(depth / (1.5 + 4.0 * prism), 0.0, 1.0);
            float split = smoothstep(0.3, 0.8, lv) * facing * light * prism * (1.0 - band) * (1.0 - band) * 1.6;
            vec3 spectrum = leakRamp(band);
            const vec3 lumaW = vec3(0.2126, 0.7152, 0.0722);
            vec3 base = u.tint.rgb;
            vec3 frost = mix(behind, u.tint.rgb, frostTint);
            float a = coverage * u.qt_Opacity;
            vec3 solidC = vec3(0.0);
            vec3 glassC = vec3(0.0);
            if (paper) {
                // Photo paper toned by the light: the grade's pastel everywhere, the light's own colour where it lands, lifted
                // toward white there, warmer at the edge it enters by. Never darker than dark ink reads on (4.5:1). Glass
                // is the same paper over its own frost.
                vec3 pastel = mix(vec3(1.0), wash, 0.6);
                for (int k = 0; k < 2; ++k) {
                    if ((k == 0 ? share.x : 1.0 - share.x) < 0.001)
                        continue;
                    vec3 m = k == 0 ? base : (share.y > share.z ? frost : base);
                    m = mix(m, m * pastel * 1.05, min(1.0, light * (0.6 + 0.5 * grained)));
                    m *= mix(vec3(1.0), leak / max(lv, 1e-3), 0.35 * lv * light);
                    m += (vec3(1.0) - m) * leak * light * 0.45;
                    m *= mix(vec3(1.0), wash, 0.5 * burn);
                    m *= mix(vec3(1.0), spectrum * 1.15, min(1.0, split * 0.6));
                    m *= 1.0 + g * grain * 0.2;
                    m += chroma * grain * 0.035;
                    float lum = dot(m * m, lumaW);
                    m = mix(m, vec3(1.0), max(0.0, 0.24 - lum) / max(1.0 - lum, 1e-3));
                    if (k == 0) solidC = m; else glassC = m;
                }
            } else {
                if (share.x > 0.001) {
                    // Smoked film over the light: its shapes show through, the grade tints what they miss, and it rolls off
                    // toward the luminance light text reads on (4.5:1) slowly enough that the light keeps its shape.
                    // What comes through is the light's own hue at full saturation (wash), never its white core: a
                    // bright light behind smoked glass reads as deep amber, not as grey.
                    vec3 m = base * 0.7 + u.leakStop4.rgb * 0.035 + vec3(0.014, 0.010, 0.008);
                    m += wash * (0.75 * lv + 0.3 + 0.4 * grained) * light;
                    float lum = dot(m * m, lumaW);
                    float held = 0.16 * lum / (lum + 0.16);
                    m *= sqrt(held / max(lum, 1e-5));
                    m += (g * (0.06 + 0.9 * sqrt(held)) + 0.012) * grain + chroma * grain * 0.04;
                    solidC = m;
                }
                if (share.x < 0.999) {
                    // Glass keeps its frost and the light scatters in it: through the whole pane as in a diffuser, and
                    // in from the edge that faces it as into an edge-lit pane, fading a few lips in. Screen-blended and
                    // held to a small lift over what the frost already is, so the tint (and Lume) keep text readable.
                    vec3 under = share.y > share.z ? frost : base;
                    float edgeLit = facing * exp(-depth / (8.0 * lip));
                    vec3 scatter = clamp((leak * (0.45 + 0.9 * edgeLit) + wash * (0.06 + 0.14 * grained)) * light, 0.0, 1.0);
                    vec3 m = vec3(1.0) - (vec3(1.0) - under) * (vec3(1.0) - scatter);
                    float lift = max(0.0, dot(m * m, lumaW) - dot(under * under, lumaW));
                    m = mix(under, m, 0.12 / (0.12 + lift));
                    m += (g * (0.05 + 0.5 * lv * light) + 0.006) * grain + chroma * grain * 0.025;
                    glassC = m;
                }
            }
            // What the edge facing the light adds, on every material.
            vec3 edgeLight = paper ? vec3(0.0) : leak * burn + spectrum * split * 0.8;
            vec3 dither = vec3((ign(cell) - 0.5) / 255.0);
            vec4 solidOut = vec4(clamp(solidC + edgeLight + dither, 0.0, 1.0), 1.0) * u.tint.a;
            vec4 glassOut = vec4(clamp(glassC + edgeLight + dither, 0.0, 1.0), 1.0);
            // Compositor glass: the material at the glass tint, and the light lit in the blur under it too (a light layer
            // over the compositor's blur, the only way to reach it).
            vec4 heldOut = vec4(clamp(glassC + edgeLight + dither, 0.0, 1.0) * frostTint, frostTint);
            heldOut.rgb += clamp((leak * (0.3 + 0.7 * facing * exp(-depth / (8.0 * lip))) + wash * 0.05 * grained) * light, 0.0, 1.0)
                * (1.0 - u.glass.z) * 0.6;
            vec4 body = (solidOut * share.x + glassOut * share.y + heldOut * share.z) * a;
            colour = body.rgb;
            alpha = body.a;
            if (united > -0.7) {
                vec3 fall = exp(-max(united, 0.0) / (reach * vec3(1.0 + 0.6 * prism, 1.0, 1.0 - 0.35 * prism)));
                float tail = smoothstep(0.0, 2.5 * reach, united);
                float dust = leakHash(floor(frameP * 0.5) + 17.0) - 0.5;
                // Ends before the pass does (IrisStyle.leakReach), or its last level draws a seam.
                float window = 1.0 - smoothstep(2.4 * reach, 3.8 * reach, united);
                vec3 halo = leak * fall * window * spill * (paper ? 0.45 : 0.85) * (0.35 + 0.65 * facing)
                    * max(0.0, 1.0 + grain * (0.6 + 1.4 * tail) * dust);
                colour += halo * (1.0 - coverage) * u.qt_Opacity;
            }
        }
    }
#endif
    // Light streak: iRiS as a long exposure. The light hangs under the Island: every edge that faces it carries a streak
    // (a hot core on its first device pixel, a fall a few pixels in, a little light past it), hottest by the Island and
    // thinning away from it. Inside, the person's colours hang as aurora curtains, strongest near the edges and quiet
    // deep in, where text sits, held under the luminance its ink reads on. A body in motion leaves its trail.
#ifdef FIELD_STREAK
    {
        float reach = max(1.0, u.streakSource.w);
        float glow;
        vec3 hue = streakCurtains(frameP, size, glow);
        if (united < reach) {
            const vec3 lumaW = vec3(0.2126, 0.7152, 0.0722);
            float px = max(u.streakSource.z, 0.05);
            vec2 toward = u.streakSource.xy - frameP;
            float dist = length(toward);
            float diag = length(size);
            float slope = length(unitedSlope);
            vec2 outward = unitedSlope / max(slope, 1e-4);
            // Two lights. The lamp under the Island is the brightest thing on screen and falls off fast; its sky is Apple's top
            // edge, a thin even light on every edge turned toward the Island, so the Dock and a panel over the lamp keep a horizon.
            vec2 sky = u.streakSource.xy - size * 0.5;
            float lamp = smoothstep(0.0, 0.85, dot(outward, toward / max(dist, 1e-3)));
            float skyward = smoothstep(0.2, 0.95, dot(outward, sky / max(length(sky), 1e-3)));
            float facing = max(lamp, 0.6 * skyward);
            float away = smoothstep(0.1, -0.7, max(dot(outward, toward / max(dist, 1e-3)), dot(outward, sky / max(length(sky), 1e-3))));
            float taper = 0.2 + 0.8 * exp(-dist / (0.2 * diag));
            float depth = max(0.0, -inner / clamp(slope, 0.5, 1.0));
            float lightAmt = u.streakMix.z * (lamp * taper + 0.42 * skyward);
            float auroraAmt = u.streakMix.y * (0.35 + 0.65 * glow) * taper;
            if (alpha > 1e-4) {
                vec3 base = colour / alpha;
                float baseLum = dot(base * base, lumaW);
                bool paper = baseLum > 0.25;
                // The edge glows in the curtain's colour, as edge-lit glass does: strongest on the side that faces the
                // light, a few pixels in, then quiet where text sits.
                float rim = exp(-depth / (reach * 0.22)) * (0.3 + 0.7 * facing);
                float deep = exp(-depth / (reach * 1.2)) * 0.25 * glow;
                vec3 m = paper
                    ? mix(base, base * mix(vec3(1.0), hue * 1.35, 0.55), min(1.0, auroraAmt * (rim * 0.8 + deep)))
                    : base + hue * auroraAmt * (rim * 1.1 + deep * 0.35);
                // Apple's depth: the edge away from the light darkens as the facing one brightens.
                m *= 1.0 - 0.35 * away * u.streakMix.z * exp(-depth / (reach * 0.08));
                if (!paper) {
                    float lum = dot(m * m, lumaW);
                    float cap = max(baseLum, 0.2 * lum / (lum + 0.2));
                    m *= sqrt(min(1.0, cap / max(lum, 1e-5)));
                } else {
                    float lum = dot(m * m, lumaW);
                    m = mix(m, vec3(1.0), max(0.0, 0.26 - lum) / max(1.0 - lum, 1e-3));
                }
                colour = clamp(m, 0.0, 1.0) * alpha;
            }
            // The horizon: one hot device pixel on every edge that faces the light.
            // A streak: two and a half pixels by the Island, one far from it.
            float core = (1.0 - smoothstep(0.6 * px, (1.0 + 1.9 * taper) * px, depth)) * coverage * u.qt_Opacity;
            float hot = clamp(core * lightAmt * 1.7, 0.0, 1.0);
            colour = mix(hue, vec3(1.0), 0.65) * hot + colour * (1.0 - hot);
            alpha = hot + alpha * (1.0 - hot);
            // The aurora rises off the horizon onto what is behind: a tight bright fall and a long soft one, in the
            // curtain's colour, ending before the pass does.
            if (united > -0.7) {
                float past = max(united, 0.0);
                float window = 1.0 - smoothstep(0.6 * reach, reach, past);
                float rise = exp(-past / (reach * 0.06)) * 0.45 + exp(-past / (reach * 0.4)) * 0.55;
                vec2 softOut = normalSlope / max(length(normalSlope), 1e-4);
                float softFacing = smoothstep(0.0, 0.85, dot(softOut, toward / max(dist, 1e-3)));
                float lit = (u.streakMix.z * 1.15 + auroraAmt * 1.1) * softFacing * taper * (0.7 + 1.3 * exp(-dist / (0.12 * diag))) * rise * window * (1.0 - coverage) * u.qt_Opacity;
                colour += mix(hue, vec3(1.0), 0.15 * exp(-past / (reach * 0.05))) * lit;
                alpha += lit * 0.12;
            }
        }
        if (u.streakMix.w > 0.001 && united > -0.7) {
            float smear = 0.0;
            for (int i = 0; i < count; ++i) {
                vec4 s = shapeAt(i);
                vec4 tr = trailAt(i);
                float moved = abs(tr.x) + abs(tr.y) + abs(tr.z) + abs(tr.w);
                if (s.z <= 0.0 || s.w <= 0.0 || moved < 0.5)
                    continue;
                // A trail is soft past any corner's shape: one radius for the whole body, six times over.
                vec4 corners = cornersAt(i);
                float r = max(max(corners.x, corners.y), max(corners.z, corners.w));
                float soft = max(1.5, moved / 10.0);
                for (int k = 1; k <= 6; ++k) {
                    float t = float(k) / 6.0;
                    float d = roundedBox(p, s.xy - tr.xy * t, max(s.zw - tr.zw * t, vec2(0.5)), r);
                    smear = max(smear, (1.0 - smoothstep(-soft, soft, d)) * (1.0 - t));
                }
            }
            smear *= (1.0 - coverage) * u.streakMix.w * u.qt_Opacity;
            colour += mix(hue, vec3(1.0), 0.3) * smear * 0.6;
            alpha += smear * 0.22;
        }
    }
#endif
    // Glass has a cut edge that catches the light from above, like Liquid Glass: bright where it faces up, a faint
    // line elsewhere, in the scene's own light. Without it wallpaper glass over a dimmed desktop has no edge at
    // all, and compositor blur's 1-bit edge (a wl_region, no AA in Niri) reads as a step instead of glass.
    float glassShare = max(share.y + share.z, u.edgeGlass.w);
    if (glassShare > 0.0) {
        float depth = -united;
        vec2 g = unitedSlope;
        float facing = clamp(-g.y / max(length(g), 1e-4), 0.0, 1.0);
        // Both edges are counted in device pixels (u.edge.z: one of them in the field's units), so 1 stays one crisp
        // screen pixel at any output scale.
        float px = max(u.edge.z, 0.05);
        float lip = coverage * (1.0 - smoothstep((u.edgeGlass.z - 0.5) * px, (u.edgeGlass.z + 0.5) * px, depth));
        float seal = lip * mix(u.edgeGlass.y, u.edgeGlass.x, facing * facing) * glassShare * u.sheen.a * u.qt_Opacity * frosting;
        colour = u.sheen.rgb * seal + colour * (1.0 - seal);
        alpha = seal + alpha * (1.0 - seal);
    }
    if (u.edge.y > 0.5) {
        // A band just inside the silhouette, so it lands on the body's own edge
        // rather than half outside it.
        float px = max(u.edge.z, 0.05);
        float inner = 1.0 - smoothstep(-0.7 * px, 0.7 * px, united + max(0.5, u.edge.x) * px);
        float rimAlpha = max(0.0, coverage - inner) * u.rim.a * u.qt_Opacity;
        colour = u.rim.rgb * rimAlpha + colour * (1.0 - rimAlpha);
        alpha = rimAlpha + alpha * (1.0 - rimAlpha);
    }
    // The light follows the frame and the bodies actually joined to it. A
    // floating body has no frame join and keeps its own material and contour.
    if (u.field.y > 0.5 && u.frameLight.x > 0.5 && u.frameLight.y > 0.001) {
        float inside = max(0.0, -frameClusterDistance);
        float wall = 1.0 - smoothstep(-0.7, 0.7, frameClusterDistance);
        float width = max(1.0, u.frameLight.w);
        float etched = 1.0 - smoothstep(0.0, width, abs(inside - 1.25));
        float satin = exp(-inside / (width * 2.4));
        float treatment = u.frameLight.x < 1.5 ? etched : satin;
        float lightAlpha = coverage * wall * treatment * u.frameLight.y * u.frameLight.z * u.qt_Opacity;
        colour = u.frameInk.rgb * lightAlpha + colour * (1.0 - lightAlpha);
        alpha = lightAlpha + alpha * (1.0 - lightAlpha);
    }
    // Under glass the body shows what is behind it: the shadow stays outside, never a grey film inside.
    float room = (1.0 - coverage * (share.y + share.z)) * (1.0 - alpha);
    if (room > 0.001) {
        float reachHere = thrown * u.qt_Opacity * room;
        colour += u.shade.rgb * reachHere;
        alpha += u.shade.a * reachHere;
    }
    // Wallpaper glass is a half-resolution blur stretched over the body and a lit body is a long, shallow ramp: eight bits
    // of either band. A dither under one level breaks the bands (a shadow's ramp is short enough not to need it).
    float ramp = (bodyLit ? 1.0 : share.y) * coverage;
    if (ramp > 0.0)
        colour = max(colour + (ign(floor(frameP)) - 0.5) * (1.0 / 255.0) * ramp, vec3(0.0));
    fragColor = vec4(colour, alpha);
}
