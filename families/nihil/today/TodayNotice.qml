pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// One notification kept in Today: the app's glyph on a round piece, its name and when, the summary and two lines of
// body. A tap does its first action, the cross lets it go.
Rectangle {
    id: root

    required property var notice
    readonly property string body: String(root.notice?.body ?? "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim()
    readonly property bool critical: root.notice?.urgency === "critical"

    function when(time: real): string {
        const minutes = Math.floor((Date.now() - time) / 60000)
        if (minutes < 1) return Translation.tr("Now")
        if (minutes < 60) return Translation.tr("%1 min").arg(minutes)
        const then = new Date(time)
        const today = new Date()
        if (then.toDateString() === today.toDateString()) return Qt.formatTime(then, Config.options?.time?.format ?? "hh:mm")
        return then.toLocaleDateString(Qt.locale(), "d MMM")
    }

    height: words.implicitHeight + NihilStyle.s(24)
    radius: NihilStyle.rowRadius
    color: tap.containsMouse ? NihilStyle.pieceHover : NihilStyle.pieceRaised
    Behavior on color { ColorAnimation { duration: NihilStyle.quick } }

    MouseArea {
        id: tap
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const action = root.notice?.actions?.[0]?.identifier ?? "default"
            Notifications.attemptInvokeAction(root.notice.notificationId, action)
        }
    }

    Rectangle {
        id: glyph
        x: NihilStyle.s(12); y: NihilStyle.s(12)
        width: NihilStyle.s(34); height: width; radius: width / 2
        color: root.critical ? NihilStyle.accent : NihilStyle.piece
        IconImage {
            anchors.centerIn: parent
            implicitSize: NihilStyle.s(18)
            source: Quickshell.iconPath(root.notice?.appIcon || AppSearch.guessIcon(root.notice?.appName ?? ""), "dialog-information")
        }
    }

    Column {
        id: words
        x: glyph.x + glyph.width + NihilStyle.s(12)
        y: NihilStyle.s(12)
        width: parent.width - x - close.width - NihilStyle.s(14)
        spacing: NihilStyle.s(2)
        Row {
            width: parent.width
            spacing: NihilStyle.s(6)
            NText {
                width: Math.min(implicitWidth, parent.width - stamp.width - parent.spacing)
                text: root.notice?.appName ?? ""
                font.pixelSize: NihilStyle.textSmall
                color: root.critical ? NihilStyle.accent : NihilStyle.inkSoft
            }
            NText {
                id: stamp
                figures: true
                text: "· " + root.when(root.notice?.time ?? Date.now())
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
            }
        }
        NText {
            width: parent.width
            text: root.notice?.summary ?? ""
            font.weight: Font.Medium
        }
        NText {
            width: parent.width
            visible: text.length > 0
            text: root.body
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 2
            font.pixelSize: NihilStyle.textSmall
            color: NihilStyle.inkSoft
        }
    }

    NButton {
        id: close
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.s(8)
        y: NihilStyle.s(8)
        width: NihilStyle.s(28); height: width
        tone: "transparent"
        icon: "close"
        iconSize: NihilStyle.s(16)
        opacity: tap.containsMouse || close.hovered ? 1 : 0.45
        onClicked: Notifications.discardNotification(root.notice.notificationId)
    }
}
