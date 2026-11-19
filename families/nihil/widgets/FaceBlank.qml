import QtQuick
import qs.modules.nihil.style

// What a face says while it has nothing to show: what is missing and, when there is room, what brings it.
Column {
    id: root

    required property var face
    property string glyph: "info"
    property string title: ""
    property string detail: ""

    anchors.centerIn: parent
    width: parent.width
    spacing: root.face.dp(4)

    NIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.glyph
        size: root.face.dp(28)
        color: root.face.foregroundSecondary
    }
    NText {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.title
        color: root.face.foreground
        elide: Text.ElideRight
        font.pixelSize: root.face.dp(14)
    }
    NText {
        width: parent.width
        visible: root.detail.length > 0 && !root.face.small
        horizontalAlignment: Text.AlignHCenter
        text: root.detail
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
        font.pixelSize: root.face.dp(12)
        color: root.face.foregroundSecondary
    }
}
