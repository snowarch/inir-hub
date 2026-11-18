import QtQuick
import qs.modules.common
import qs.modules.nihil.style

// The title bar of every printed window: ruled ink either side of the window's name, cut out in paper.
Rectangle {
    id: root
    property string title: ""
    readonly property real d: IrisStyle.density

    implicitHeight: Math.round(28 * root.d)
    color: IrisStyle.text

    Column {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: Math.round(2 * root.d)
        Repeater {
            model: 5
            Rectangle {
                required property int index
                width: parent.width
                height: Math.max(1, Math.round(root.d))
                color: IrisStyle.surfaceOpaque
            }
        }
    }
    Rectangle {
        anchors.centerIn: parent
        width: label.implicitWidth + Math.round(20 * root.d)
        height: parent.height
        color: IrisStyle.text
        Text {
            id: label
            anchors.centerIn: parent
            text: root.title
            color: IrisStyle.surfaceOpaque
            font.family: IrisStyle.fontMono
            font.pixelSize: Math.round(20 * root.d)
            renderType: Text.NativeRendering
        }
    }
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: IrisStyle.edgeWidth
        color: IrisStyle.text
    }
}
