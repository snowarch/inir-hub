pragma ComponentBehavior: Bound

// The last minute as a horizon, in the Material face's ink: what came in rises above the line, what went out hangs
// under it, both on one scale (traffic.js `levels`), the newest second at the right edge. Until a minute is kept the
// trace grows in from the right. The iRiS faces draw the same horizon with the family's FaceArea.
import QtQuick
import QtQuick.Shapes
import qs.modules.common.functions
import "traffic.js" as Logic

Item {
    id: root

    // Heights 0..1, newest last.
    property var downs: []
    property var ups: []
    // The share of the minute kept so far.
    property real filled: 1
    property real stroke: 2
    property color inTint: "transparent"
    property color outTint: "transparent"
    property color axis: "transparent"
    property real fade: 0.28
    // Where the line sits: what came in takes the room above it.
    property real split: 0.56

    readonly property real axisY: Math.round(root.height * root.split)
    readonly property real from: 1 - Math.max(0, Math.min(1, root.filled))

    function yOf(level: real, below: bool): real {
        return below ? root.axisY + level * (root.height - root.axisY - root.stroke)
            : root.axisY - level * (root.axisY - root.stroke)
    }
    function trace(values: var, below: bool): string {
        if (root.width <= 0 || values.length < 2)
            return ""
        const span = Math.max(0.001, 1 - root.from)
        const steps = Math.max(8, Math.ceil(span * 96))
        let d = ""
        for (let i = 0; i <= steps; i++) {
            const t = root.from + span * i / steps
            d += (i === 0 ? "M " : " L ") + (t * root.width).toFixed(1) + " " + root.yOf(Logic.smooth(values, (t - root.from) / span), below).toFixed(1)
        }
        return d
    }
    function closed(d: string): string {
        return d.length > 0 ? d + " L " + root.width + " " + root.axisY + " L " + (root.from * root.width).toFixed(1) + " " + root.axisY + " Z" : ""
    }
    readonly property string inLine: root.trace(root.downs, false)
    readonly property string outLine: root.trace(root.ups, true)

    Rectangle {
        width: parent.width
        height: 1
        y: root.axisY
        color: root.axis
    }
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0; x2: 0; y2: root.axisY
                GradientStop { position: 0; color: ColorUtils.applyAlpha(root.inTint, root.fade) }
                GradientStop { position: 1; color: ColorUtils.applyAlpha(root.inTint, 0) }
            }
            PathSvg { path: root.closed(root.inLine) }
        }
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: root.height; x2: 0; y2: root.axisY
                GradientStop { position: 0; color: ColorUtils.applyAlpha(root.outTint, root.fade) }
                GradientStop { position: 1; color: ColorUtils.applyAlpha(root.outTint, 0) }
            }
            PathSvg { path: root.closed(root.outLine) }
        }
        ShapePath {
            strokeColor: root.inTint
            strokeWidth: root.stroke
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            fillColor: "transparent"
            PathSvg { path: root.inLine }
        }
        ShapePath {
            strokeColor: root.outTint
            strokeWidth: root.stroke
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            fillColor: "transparent"
            PathSvg { path: root.outLine }
        }
    }
}
