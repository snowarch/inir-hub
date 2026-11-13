import QtQuick
import QtQuick.Shapes
import qs.modules.common.functions
import qs.modules.iris.style

// The Prism insignia: a glass triangle in the ink, a thread of light entering its left face and the spectrum leaving
// its right one. Drawn on a 100-unit grid and scaled to the host's size; small, the fan keeps three bands. A host that
// asks for a colour other than the accent (a lit tile's ink) gets the whole mark in that colour.
Item {
    id: root
    property Item host: null
    property color ink: !root.host || Qt.colorEqual(root.host.color, IrisStyle.accent) ? IrisStyle.text : root.host.color
    readonly property bool mono: !!root.host && !Qt.colorEqual(root.host.color, IrisStyle.accent)
    readonly property real size: Math.min(width, height)
    readonly property real unit: root.size / 100
    readonly property bool small: root.size < 40
    // The spectrum, the shell's one (IrisStyle.prismStops, violet to red); in one colour, that ink fading.
    readonly property var stops: IrisStyle.prismStops
    function tone(index: int): color {
        return root.mono ? ColorUtils.applyAlpha(root.ink, 0.25 + 0.6 * index / 6) : root.stops[index]
    }
    // The fan leaves the right face from one point: one sweep of light, no band between its colours.
    readonly property real upper: Math.atan2(50 - 36, 38) * 180 / Math.PI
    readonly property real lower: Math.atan2(50 - 60, 38) * 180 / Math.PI
    function at(index: int): real { return (root.upper - root.lower) / 360 * index / 6 }

    Shape {
        width: 100
        height: 100
        anchors.centerIn: parent
        scale: root.unit
        preferredRendererType: Shape.CurveRenderer
        // The beam, from the lower left into the left face.
        ShapePath {
            strokeWidth: root.small ? 4.5 : 2.5
            strokeColor: root.ink
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            startX: 3; startY: 63
            PathLine { x: 34; y: 51 }
        }
        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillGradient: ConicalGradient {
                centerX: 60; centerY: 50
                angle: root.lower
                GradientStop { position: root.at(0); color: root.tone(0) }
                GradientStop { position: root.at(1); color: root.tone(1) }
                GradientStop { position: root.at(2); color: root.tone(2) }
                GradientStop { position: root.at(3); color: root.tone(3) }
                GradientStop { position: root.at(4); color: root.tone(4) }
                GradientStop { position: root.at(5); color: root.tone(5) }
                GradientStop { position: root.at(6); color: root.tone(6) }
            }
            startX: 60; startY: 50
            PathLine { x: 98; y: 36 }
            PathLine { x: 98; y: 60 }
            PathLine { x: 60; y: 50 }
        }
        // The glass: drawn last so the light meets its faces.
        ShapePath {
            strokeWidth: root.small ? 5.5 : 3.5
            strokeColor: root.ink
            joinStyle: ShapePath.RoundJoin
            fillColor: ColorUtils.applyAlpha(root.ink, 0.08)
            startX: 50; startY: 14
            PathLine { x: 84; y: 80 }
            PathLine { x: 16; y: 80 }
            PathLine { x: 50; y: 14 }
        }
    }
}
