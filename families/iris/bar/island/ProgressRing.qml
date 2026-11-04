pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// An Item, not the Shape itself: a Shape takes its implicit size from its paths, so in a layout the radius fed the
// size it was computed from (a binding loop on radiusX).
Item {
    id: ring
    property real progress: 0
    property color tint: IrisStyle.text
    property real stroke: Math.max(2, 2.5 * IrisStyle.density)
    // Under 360 the ring opens at the bottom: a gauge (an activity ring of a streak).
    property real sweep: 360
    readonly property real startAt: ring.sweep >= 360 ? -90 : 90 + (360 - ring.sweep) / 2
    readonly property real radius: Math.max(0, Math.min(ring.width, ring.height) / 2 - ring.stroke / 2)
    readonly property real level: Math.max(0, Math.min(1, ring.progress))

    // A Design may draw it its own way (AIRISU: the needle gauge's 270° arc).
    IrisSkin { id: ringSkin; part: "ring" }
    Shape {
        visible: !ringSkin.active
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: IrisStyle.tintFill(ring.tint)
            strokeWidth: ring.stroke
            fillColor: "transparent"
            capStyle: ring.sweep >= 360 ? ShapePath.FlatCap : ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.radius
                radiusY: ring.radius
                startAngle: ring.startAt
                sweepAngle: ring.sweep
            }
        }
        ShapePath {
            strokeColor: IrisStyle.arcInk(ring.tint, 2 * Math.PI * ring.radius * ring.level, ring.stroke)
            strokeWidth: ring.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.radius
                radiusY: ring.radius
                startAngle: ring.startAt
                sweepAngle: ring.sweep * ring.level
            }
        }
    }
}
