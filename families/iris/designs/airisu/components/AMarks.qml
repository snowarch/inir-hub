import QtQuick
import QtQuick.Shapes
import qs.modules.iris.style

// Crop marks (トンボ): how AIRISU says a piece is held by the keyboard or chosen. Four marks stand outside the piece at its
// corners, `gap` away, each a stretch of the piece's own outline grown by the gap; they never touch it and never close
// round it. They come in from twice the gap in one detent, so the piece reads as being registered, not lit.
Item {
    id: root
    property bool shown: false
    property color color: Airisu.ink
    property int gap: Airisu.m
    property int arm: Math.max(3, Math.min(2 * Airisu.m, Math.round(Math.min(root.width, root.height) / 3)))
    property real stroke: Airisu.hair
    // The piece's radius, so the marks stay parallel to its corners.
    property real radius: IrisStyle.formOf(Math.min(root.width, root.height))

    property real reach: root.shown ? root.gap : 2 * root.gap
    Behavior on reach {
        enabled: Airisu.moving
        NumberAnimation { duration: Airisu.detent; easing.type: Easing.BezierSpline; easing.bezierCurve: Airisu.curve }
    }

    Loader {
        active: root.shown
        sourceComponent: Shape {
            id: marks
            readonly property real g: root.reach
            readonly property real a: root.arm
            readonly property real w: root.width
            readonly property real h: root.height
            // Half a stroke in, so a hairline lands on whole pixels.
            readonly property real o: root.stroke % 2 === 1 ? 0.5 : 0
            // One mark, around the corner at (cx, cy) with quadrant signs (sx, sy): an arm, the arc, an arm.
            function mark(sx: real, sy: real): var {
                const g = marks.g - marks.o, a = marks.a, r = root.radius + g
                const x0 = sx < 0 ? root.radius : marks.w - root.radius, y0 = sy < 0 ? root.radius : marks.h - root.radius
                const line = [Qt.point(x0 + sx * r, y0 - sy * a)]
                for (let i = 0; i <= 6; ++i) {
                    const t = i / 6 * Math.PI / 2
                    line.push(Qt.point(x0 + sx * r * Math.cos(t), y0 + sy * r * Math.sin(t)))
                }
                line.push(Qt.point(x0 - sx * a, y0 + sy * r))
                return line
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: root.color
                strokeWidth: root.stroke
                capStyle: ShapePath.FlatCap
                joinStyle: ShapePath.RoundJoin
                PathMultiline {
                    paths: [marks.mark(-1, -1), marks.mark(1, -1), marks.mark(-1, 1), marks.mark(1, 1)]
                }
            }
        }
    }
}
