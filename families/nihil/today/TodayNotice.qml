pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// One notification kept: the app's mark, the summary and when, the body under them. A tap does its first action; the
// cross on the body's line lets it go.
MouseArea {
    id: root

    required property var entry

    readonly property string body: String(root.entry?.body ?? "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim()
    readonly property bool critical: root.entry?.urgency === "critical"

    function when(time: real): string {
        const minutes = Math.floor((DateTime.clock.date.getTime() - time) / 60000)
        if (minutes < 1) return Translation.tr("Now")
        if (minutes < 60) return Translation.tr("%1 min").arg(minutes)
        const then = new Date(time)
        if (then.toDateString() === new Date().toDateString())
            return Qt.formatTime(then, Config.options?.time?.format ?? "hh:mm")
        return then.toLocaleDateString(Translation.locale, "d MMM")
    }

    height: Math.max(NihilStyle.s(76), words.implicitHeight + NihilStyle.s(30))
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    Accessible.role: Accessible.Button
    Accessible.name: root.entry?.summary ?? ""
    onClicked: Notifications.attemptInvokeAction(root.entry.notificationId, root.entry?.actions?.[0]?.identifier ?? "default")

    Rectangle {
        anchors.fill: parent
        radius: NihilStyle.r(22)
        color: root.containsMouse || drop.containsMouse ? NihilStyle.fillHover : NihilStyle.fill
        Behavior on color { ColorAnimation { duration: NihilStyle.durationShort } }
    }
    NAppIcon {
        id: mark
        x: NihilStyle.s(16)
        anchors.verticalCenter: parent.verticalCenter
        appId: root.entry?.appIcon || root.entry?.appName || ""
        size: NihilStyle.s(42)
    }
    Column {
        id: words
        x: mark.x + mark.width + NihilStyle.s(12)
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - NihilStyle.s(14)
        spacing: NihilStyle.s(3)
        Item {
            width: parent.width
            height: title.implicitHeight
            NText {
                id: title
                width: parent.width - time.implicitWidth - NihilStyle.spacing
                text: root.entry?.summary || root.entry?.appName || ""
                font.weight: Font.Medium
                color: root.critical ? NihilStyle.danger : NihilStyle.text
            }
            NText {
                id: time
                anchors.right: parent.right
                text: root.when(root.entry?.time ?? Date.now())
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.textTertiary
            }
        }
        NText {
            width: parent.width - NihilStyle.s(30)
            visible: text.length > 0
            text: root.body
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 2
            font.pixelSize: NihilStyle.textSmall
            color: NihilStyle.textSecondary
        }
    }
    NButton {
        id: drop
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.s(8)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: NihilStyle.s(6)
        width: NihilStyle.s(28)
        height: width
        radius: width / 2
        opacity: root.containsMouse || drop.containsMouse ? 1 : 0
        icon: "close"
        iconSize: NihilStyle.s(14)
        Accessible.name: Translation.tr("Dismiss")
        onClicked: Notifications.discardNotification(root.entry.notificationId)
    }
}
