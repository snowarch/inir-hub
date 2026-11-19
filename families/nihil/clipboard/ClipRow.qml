pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.nihil.style

// One copied thing on one line. The marked one stands solid in the light; what it holds is read beside the list.
MouseArea {
    id: root

    required property var row
    property bool marked: false

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

    height: NihilStyle.s(48)
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.used()

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.marked ? NihilStyle.accent : "transparent"
        Behavior on color { ColorAnimation { duration: NihilStyle.durationShort } }
    }
    NIcon {
        id: mark
        x: NihilStyle.s(18)
        anchors.verticalCenter: parent.verticalCenter
        text: root.image ? "image" : root.row.pinned ? "pin" : "page"
        size: NihilStyle.s(18)
        color: root.marked ? NihilStyle.accentText : root.row.pinned ? NihilStyle.accent : NihilStyle.textSecondary
    }
    NText {
        anchors.left: mark.right
        anchors.leftMargin: NihilStyle.s(12)
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.s(18)
        anchors.verticalCenter: parent.verticalCenter
        text: root.image ? root.picture : root.raw.replace(/\s+/g, " ").trim()
        textFormat: Text.PlainText
        color: root.marked ? NihilStyle.accentText : NihilStyle.text
    }
}
