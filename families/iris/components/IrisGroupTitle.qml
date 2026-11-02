import QtQuick
import qs.modules.iris.style

// A group's name as a widget heads itself (his 11-02: the widgets are the look): its glyph and its name in its colour,
// the anchor the eye jumps between on a long page. Every Settings layout's group head draws it.
Row {
    id: root
    property string text: ""
    property string glyph: "settings"
    property color tint: IrisStyle.identity.gray
    property real size: IrisStyle.typeHeadline
    property real maxWidth: 400
    readonly property color voice: IrisStyle.iconColour === "mono" ? IrisStyle.text : IrisStyle.iconHue(root.tint)
    spacing: Math.round(root.size * 0.42)

    IrisSquircle {
        id: mark
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(root.size * 1.15)
        height: width
        tint: root.tint
        glyph: root.glyph
    }
    IrisText {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, root.maxWidth - mark.width - root.spacing)
        elide: Text.ElideRight
        text: root.text
        color: root.voice
        font.family: IrisStyle.fontTitle
        font.pixelSize: root.size
        font.weight: IrisStyle.weight(Font.Bold)
        Accessible.role: Accessible.Heading
    }
}
