pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
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
    // The spectrum is the shell's one (IrisStyle.prismStops, violet to red): soft and even, leaning to the accent.
    readonly property var stops: IrisStyle.prismStops

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

    // The fan (pin-spectrum-burst, pin-prism-beam): one sweep of light from a point, its colours running into each
    // other with no band between them, red above and violet below, wider and fainter as it leaves.
    Item {
        id: fan
        x: clock.x + clock.width + root.gap
        width: root.reach
        height: root.height
        opacity: root.glow
        readonly property real degrees: 180 / Math.PI
        readonly property real upper: Math.atan2(root.mid - root.fanTop, fan.width) * fan.degrees
        readonly property real lower: Math.atan2(root.mid - root.fanFoot, fan.width) * fan.degrees
        readonly property real sweep: (fan.upper - fan.lower) / 360
        function at(index: int): real { return fan.sweep * index / 6 }

        Shape {
            id: light
            anchors.fill: parent
            visible: false
            layer.enabled: true
            layer.smooth: true
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1
                strokeColor: "transparent"
                fillGradient: ConicalGradient {
                    centerX: 0; centerY: root.mid
                    angle: fan.lower
                    GradientStop { position: fan.at(0); color: root.stops[0] }
                    GradientStop { position: fan.at(1); color: root.stops[1] }
                    GradientStop { position: fan.at(2); color: root.stops[2] }
                    GradientStop { position: fan.at(3); color: root.stops[3] }
                    GradientStop { position: fan.at(4); color: root.stops[4] }
                    GradientStop { position: fan.at(5); color: root.stops[5] }
                    GradientStop { position: fan.at(6); color: root.stops[6] }
                }
                startX: 0; startY: root.mid
                PathLine { x: fan.width; y: root.fanTop }
                PathLine { x: fan.width; y: root.fanFoot }
                PathLine { x: 0; y: root.mid }
            }
        }
        // Full where it leaves the hour, gone at the strip's end.
        Rectangle {
            id: fall
            anchors.fill: parent
            visible: false
            layer.enabled: true
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "white" } // iris-literal: a mask's alpha
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.8) } // iris-literal: a mask's alpha
                GradientStop { position: 1; color: "transparent" }
            }
        }
        MultiEffect {
            anchors.fill: parent
            source: light
            maskEnabled: true
            maskSource: fall
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
    }
}
