pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.nihil.style

// One copied thing: two lines of the text, or what picture it is; a pin and a cross while the hand is on it. Pinned
// rows carry the pin lit.
Rectangle {
    id: root

    required property var row
    property bool marked: false
    readonly property bool hovered: hand.containsMouse || pin.hovered || drop.hovered
    signal used()

    readonly property string raw: root.row.pinned ? String(root.row.text) : String(root.row.entry).replace(/^\d+\t/, "")
    readonly property bool image: !root.row.pinned && Cliphist.entryIsImage(root.row.entry)
    readonly property string picture: {
        if (!root.image) return ""
        const found = root.raw.match(/binary data (.+?) (\w+) (\d+)x(\d+)/)
        return found ? Translation.tr("Image · %1 · %2×%3 · %4").arg(found[2].toUpperCase()).arg(found[3]).arg(found[4]).arg(found[1])
            : Translation.tr("Image")
    }

    height: Math.max(NihilStyle.s(50), words.implicitHeight + NihilStyle.s(22))
    radius: NihilStyle.rowRadius
    color: root.marked ? NihilStyle.pieceHover : NihilStyle.pieceRaised
    Behavior on color { ColorAnimation { duration: NihilStyle.quick } }

    MouseArea {
        id: hand
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.used()
    }

    Rectangle {
        visible: root.marked
        x: NihilStyle.s(6)
        anchors.verticalCenter: parent.verticalCenter
        width: NihilStyle.s(4); height: parent.height - NihilStyle.s(24)
        radius: width / 2
        color: NihilStyle.accent
    }

    NIcon {
        id: glyph
        x: NihilStyle.s(16)
        anchors.verticalCenter: parent.verticalCenter
        text: root.image ? "image" : root.row.pinned ? "push_pin" : "notes"
        size: NihilStyle.s(18)
        color: root.row.pinned ? NihilStyle.accent : NihilStyle.inkSoft
    }

    NText {
        id: words
        anchors.left: glyph.right
        anchors.leftMargin: NihilStyle.s(12)
        anchors.right: tools.left
        anchors.rightMargin: NihilStyle.s(8)
        anchors.verticalCenter: parent.verticalCenter
        text: root.image ? root.picture : root.raw.replace(/\s+/g, " ").trim()
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        maximumLineCount: 2
        color: root.image ? NihilStyle.inkSoft : NihilStyle.ink
    }

    Row {
        id: tools
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.s(8)
        anchors.verticalCenter: parent.verticalCenter
        spacing: NihilStyle.s(4)
        opacity: root.hovered || root.marked ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: NihilStyle.quick } }
        NButton {
            id: pin
            visible: root.row.pinned || Cliphist.isPinnable(root.row.entry)
            width: NihilStyle.s(32); height: width
            tone: "transparent"
            icon: "push_pin"
            iconSize: NihilStyle.s(16)
            lit: root.row.pinned
            onClicked: root.row.pinned ? Cliphist.unpin(root.row.text) : Cliphist.pinEntry(root.row.entry)
        }
        NButton {
            id: drop
            visible: !root.row.pinned
            width: NihilStyle.s(32); height: width
            tone: "transparent"
            icon: "close"
            iconSize: NihilStyle.s(16)
            onClicked: Cliphist.deleteEntry(root.row.entry)
        }
    }
}
