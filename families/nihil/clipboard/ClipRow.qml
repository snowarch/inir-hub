pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.nihil.style

// One copied thing: two lines of the text, or what picture it is, with a pin and a cross while the hand is on it.
Rectangle {
    id: root

    required property var row
    property bool marked: false
    readonly property bool hovered: hand.containsMouse || pin.containsMouse || drop.containsMouse

    readonly property string raw: root.row.pinned ? String(root.row.text) : String(root.row.entry).replace(/^\d+\t/, "")
    readonly property bool image: !root.row.pinned && Cliphist.entryIsImage(root.row.entry)
    readonly property string picture: {
        if (!root.image)
            return ""
        const found = root.raw.match(/binary data (.+?) (\w+) (\d+)x(\d+)/)
        return found ? Translation.tr("Image, %1, %2 by %3, %4").arg(found[2].toUpperCase()).arg(found[3]).arg(found[4]).arg(found[1])
            : Translation.tr("Image")
    }

    signal used()

    height: Math.max(NihilStyle.s(48), words.implicitHeight + NihilStyle.s(20))
    radius: NihilStyle.rKey
    color: root.marked ? NihilStyle.pieceRaised : "transparent"
    Behavior on color { ColorAnimation { duration: NihilStyle.quick } }

    MouseArea {
        id: hand
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.used()
    }

    NIcon {
        id: mark
        x: NihilStyle.s(12)
        anchors.verticalCenter: parent.verticalCenter
        text: root.image ? "image" : root.row.pinned ? "pin" : "page"
        size: NihilStyle.s(18)
        color: root.row.pinned ? NihilStyle.accent : NihilStyle.inkSoft
    }

    NText {
        id: words
        anchors.left: mark.right
        anchors.leftMargin: NihilStyle.s(12)
        anchors.right: tools.left
        anchors.rightMargin: NihilStyle.s(8)
        anchors.verticalCenter: parent.verticalCenter
        text: root.image ? root.picture : root.raw.replace(/\s+/g, " ").trim()
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
        color: root.image ? NihilStyle.inkSoft : NihilStyle.ink
    }

    Row {
        id: tools
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.s(6)
        anchors.verticalCenter: parent.verticalCenter
        spacing: NihilStyle.s(2)
        opacity: root.hovered || root.marked ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: NihilStyle.quick } }

        NButton {
            id: pin
            visible: root.row.pinned || Cliphist.isPinnable(root.row.entry)
            width: NihilStyle.s(32)
            height: NihilStyle.s(32)
            icon: "pin"
            iconSize: NihilStyle.s(16)
            lit: root.row.pinned
            onClicked: root.row.pinned ? Cliphist.unpin(root.row.text) : Cliphist.pinEntry(root.row.entry)
        }
        NButton {
            id: drop
            visible: !root.row.pinned
            width: NihilStyle.s(32)
            height: NihilStyle.s(32)
            icon: "close"
            iconSize: NihilStyle.s(16)
            onClicked: Cliphist.deleteEntry(root.row.entry)
        }
    }
}
