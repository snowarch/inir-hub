pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.iris.style
import "../corner"

// One section of Sources as a Settings card: its eyebrow and title, then what it holds.
Rectangle {
    id: root
    property string eyebrow: ""
    property string title: ""
    default property alias content: body.data
    readonly property real d: IrisStyle.density
    implicitHeight: body.implicitHeight + 2 * Math.round(18 * root.d)
    radius: IrisStyle.radiusCard
    color: CornerSkin.card
    border.width: CornerSkin.edgeWidth
    border.color: CornerSkin.edge
    ColumnLayout {
        id: body
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Math.round(18 * root.d) }
        spacing: Math.round(10 * root.d)
        CornerHeading { eyebrow: root.eyebrow; title: root.title; visible: root.title.length > 0 }
    }
}
