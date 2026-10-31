import QtQuick
import QtQuick.Shapes
import qs.modules.iris.style

// A plate in a Kiri Design's silhouette (IrisStyle.fieldChamfer): the upper-left and lower-right corners round, the
// upper-right and lower-left cut at 45° with eased ends (IrisStyle.kiriOutline), so a plate laid over a body (a hover, a
// press, an open piece) follows its outline.
// A ring round a plate (`stroke`, laid inside the outline so a whole-pixel rule stays whole) takes `cutLength` grown by
// how far it stands out, so its cut runs parallel to the plate's.
// Built only while it shows or masks: under a round Design every row carried a hidden Shape and its pen.
Item {
    id: root
    property color color: "transparent"
    property color stroke: "transparent"
    property real strokeWidth: 0
    property real cutLength: IrisStyle.chamferCut
    readonly property real cut: root.cutLength
    readonly property real s: root.strokeWidth / 2
    Loader {
        anchors.fill: parent
        active: root.visible || root.layer.enabled
        sourceComponent: Shape {
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: root.color
                strokeColor: root.strokeWidth > 0 ? root.stroke : "transparent"
                strokeWidth: root.strokeWidth
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: IrisStyle.kiriOutline(root.width, root.height, root.cutLength, root.s) }
            }
        }
    }
}
