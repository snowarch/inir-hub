import QtQuick
import QtQuick.Window
import "Glyphs.js" as Glyphs

// One of NiHiL's own glyphs (Glyphs.js), drawn at the screen's real pixels in one ink.
Item {
    id: root

    property string text: ""
    property real size: NihilStyle.s(20)
    property color color: NihilStyle.ink
    property real weight: 2

    readonly property string _ink: "rgb(" + Math.round(root.color.r * 255) + "," + Math.round(root.color.g * 255) + ","
        + Math.round(root.color.b * 255) + ")"
    readonly property real _px: Math.ceil(root.size * (Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1))

    implicitWidth: root.size
    implicitHeight: root.size
    width: root.size
    height: root.size
    opacity: root.color.a

    Image {
        anchors.fill: parent
        sourceSize: Qt.size(root._px, root._px)
        source: Glyphs.url(root.text, root._ink, root.weight)
        fillMode: Image.PreserveAspectFit
        smooth: true
    }
}
