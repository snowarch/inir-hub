import QtQuick
import qs.modules.iris.widgets

// One event on a Prism folder: its calendar's colour as a bar, the title, and when under it (or at its right).
Item {
    id: line
    required property var face
    required property var event
    property string when: ""
    property bool beside: false
    readonly property real gap: line.face.dp(10)
    implicitHeight: line.beside ? title.height : title.height + whenText.height

    Rectangle {
        width: line.face.dp(3)
        height: line.height - line.face.dp(4)
        y: line.face.dp(2)
        radius: width / 2
        color: IrisFaceData.eventTint(line.event, line.face.shelf)
    }
    FaceText {
        id: title
        face: line.face
        x: line.gap
        width: line.width - x - (line.beside ? whenText.implicitWidth + line.gap : 0)
        text: IrisFaceData.eventTitle(line.event)
        size: line.face.type(13, 14, 16)
        weight: Font.DemiBold
        elide: Text.ElideRight
    }
    FaceText {
        id: whenText
        face: line.face
        x: line.beside ? line.width - width : line.gap
        y: line.beside ? Math.round((title.height - height) / 2) : title.height
        width: line.beside ? implicitWidth : line.width - line.gap
        text: line.when
        color: line.face.inkSecondary
        size: line.face.type(11, 12, 13)
        weight: Font.Medium
        elide: Text.ElideRight
        font.features: ({ "tnum": 1 })
    }
}
