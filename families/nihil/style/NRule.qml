import QtQuick

// The poster's rule: a hairline with small labels set into it, at the start, the middle and the end. A label left
// empty lets the line run through.
Item {
    id: root

    property string start: ""
    property string middle: ""
    property string end: ""
    property color ink: NihilStyle.inkSoft
    property color lineColor: NihilStyle.hair
    readonly property real room: NihilStyle.s(12)

    implicitHeight: NihilStyle.s(14)

    NLabel { id: a; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: root.start; color: root.ink; visible: text.length > 0 }
    NLabel { id: m; anchors.centerIn: parent; text: root.middle; color: root.ink; visible: text.length > 0 }
    NLabel { id: z; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: root.end; color: root.ink; visible: text.length > 0 }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: a.visible ? a.width + root.room : 0
        width: (m.visible ? m.x - root.room : (z.visible ? z.x - root.room : root.width)) - x
        height: 1
        color: root.lineColor
    }
    Rectangle {
        visible: m.visible
        anchors.verticalCenter: parent.verticalCenter
        x: m.x + m.width + root.room
        width: (z.visible ? z.x - root.room : root.width) - x
        height: 1
        color: root.lineColor
    }
}
