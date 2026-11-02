import QtQuick
import QtQuick.Shapes
import qs.modules.iris.style

// A die (型抜き): a stroke or a fill on the shell's one form (IrisStyle.outline). A stroke is laid inside the die so a 1 px
// rule lands on a whole pixel; `dashed` draws an inactive die. `texture` fills it with a texture provider of its own size
// (a frosted piece of the scene) instead of `fill`.
Item {
    id: root
    property color fill: "transparent"
    property color stroke: "transparent"
    property real strokeWidth: 0
    property bool dashed: false
    property real radius: IrisStyle.formOf(Math.min(root.width, root.height))
    property Item texture: null

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.fill
            fillItem: root.texture
            strokeColor: root.strokeWidth > 0 ? root.stroke : "transparent"
            strokeWidth: root.strokeWidth
            strokeStyle: root.dashed ? ShapePath.DashLine : ShapePath.SolidLine
            dashPattern: [2, 2]
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.FlatCap
            PathPolyline { path: IrisStyle.outline(root.width, root.height, root.radius, root.strokeWidth / 2) }
        }
    }
}
