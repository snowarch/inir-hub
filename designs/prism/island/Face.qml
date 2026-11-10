pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.iris.components

// Prism's Island face: the hour is the prism. A thread of white light enters from the strip's start and meets the time;
// the spectrum leaves its far side as a fan, from a point, wider and softer as it goes (Prism's refraction, the one in
// its Settings hero). Beam and fan are equally long, so the hour stays in the middle of the strip. At rest the light is
// low; under the pointer it comes up full. Only the rest belongs to it: a song rides as the engine's wings, the rest of
// the Island's moments are the engine's.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    // How far the light runs on each side of the hour, and the air between it and the figures.
    readonly property real reach: Math.round(Math.max(20 * root.d, root.h * 0.78))
    readonly property real gap: Math.round(6 * root.d)
    readonly property real contentWidth: clock.implicitWidth + 2 * (root.reach + root.gap)
    readonly property real line: Math.max(1.5, Math.round(2 * root.d))
    readonly property real mid: root.height / 2
    // The light climbs as it crosses the hour, lower left to upper right like the refraction in Prism's hero: the beam
    // enters from below the middle, the fan leaves above it, wider than it came.
    readonly property real rise: Math.round(root.h * 0.16)
    readonly property real fanTop: root.mid - root.rise - Math.round(root.h * 0.2)
    readonly property real fanFoot: root.mid - root.rise + Math.round(root.h * 0.2)

    // The light's strength: quiet at rest, full under the pointer.
    property real glow: hover.hovered ? 1 : 0.72 // iris-literal: the light at rest, a quiet share of full
    Behavior on glow { NumberAnimation { duration: IrisStyle.motionEnabled ? 280 : 0; easing.type: Easing.OutCubic } }
    HoverHandler { id: hover }

    // White light on a dark body, the ink on a light one.
    readonly property color white: IrisStyle.text
    // Prism's spectrum, red to violet top to bottom: the refraction recipe's stops, the colours of its hero. On a light
    // body each is taken a fifth toward the ink so the yellow still reads.
    readonly property var spectrum: ["#fd1443", "#fd9017", "#fef23d", "#26e033", "#4289fd", "#7a9afd", "#d518fd"] // iris-literal: Prism's refraction spectrum
    readonly property var bands: root.spectrum.map(tone => IrisStyle.light ? ColorUtils.mix(Qt.color(tone), root.white, 0.8) : Qt.color(tone))

    IrisClock {
        id: clock
        anchors.centerIn: parent
        family: IrisStyle.figureFace(pixelSize)
        minorFamily: family
        pixelSize: root.island?.figureSize ?? IrisStyle.typeHeadline
        separatorColor: IrisStyle.textSecondary
    }

    // The beam: a thread from the strip's start, below the middle, brightening as it reaches the hour.
    Shape {
        x: clock.x - root.gap - root.reach
        width: root.reach
        height: root.height
        opacity: root.glow
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: root.line
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            strokeGradient: LinearGradient {
                x1: 0; y1: 0
                x2: root.reach; y2: 0
                GradientStop { position: 0; color: ColorUtils.applyAlpha(root.white, 0) }
                GradientStop { position: 0.6; color: ColorUtils.applyAlpha(root.white, 0.5) }
                GradientStop { position: 1; color: root.white }
            }
            startX: 0; startY: root.mid + root.rise
            PathLine { x: root.reach; y: root.mid }
        }
    }

    // One band of the fan: from the point to its share of the far edge, white where the bands meet, full through the
    // middle, fading at the strip's end.
    component Band: ShapePath {
        id: bandPath
        required property int index
        readonly property color tone: root.bands[bandPath.index] ?? root.white
        strokeWidth: -1
        strokeColor: "transparent"
        fillGradient: LinearGradient {
            x1: 0; y1: 0
            x2: fan.width; y2: 0
            GradientStop { position: 0; color: root.white }
            GradientStop { position: 0.16; color: bandPath.tone }
            GradientStop { position: 0.7; color: bandPath.tone }
            GradientStop { position: 1; color: ColorUtils.applyAlpha(bandPath.tone, 0.15) }
        }
        startX: 0; startY: root.mid
        PathLine { x: fan.width; y: root.fanTop + bandPath.index * fan.band }
        PathLine { x: fan.width; y: root.fanTop + (bandPath.index + 1) * fan.band }
        PathLine { x: 0; y: root.mid }
    }

    // The fan: the seven bands from one point.
    Shape {
        id: fan
        x: clock.x + clock.width + root.gap
        width: root.reach
        height: root.height
        opacity: root.glow
        preferredRendererType: Shape.CurveRenderer
        readonly property real band: (root.fanFoot - root.fanTop) / 7
        Band { index: 0 }
        Band { index: 1 }
        Band { index: 2 }
        Band { index: 3 }
        Band { index: 4 }
        Band { index: 5 }
        Band { index: 6 }
    }
}
