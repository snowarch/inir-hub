pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// One notification kept in Today: the app's mark, its name and when, the summary and two lines of body. A tap does its
// first action, the cross lets it go.
Rectangle {
    id: root

    required property var entry

    readonly property string body: String(root.entry?.body ?? "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim()
    readonly property bool critical: root.entry?.urgency === "critical"

    function when(time: real): string {
        const minutes = Math.floor((Date.now() - time) / 60000)
        if (minutes < 1)
            return Translation.tr("Now")
        if (minutes < 60)
            return Translation.tr("%1 min").arg(minutes)
        const then = new Date(time)
        if (then.toDateString() === new Date().toDateString())
            return Qt.formatTime(then, Config.options?.time?.format ?? "hh:mm")
        return then.toLocaleDateString(Qt.locale(), "d MMM")
    }

    height: Math.max(words.implicitHeight + NihilStyle.s(20), NihilStyle.s(60))
    radius: NihilStyle.r(6)
    color: Qt.alpha(NihilStyle.ink, tap.containsMouse ? 0.06 : 0)
    Behavior on color { ColorAnimation { duration: NihilStyle.quick } }

    // A ruled list: a hairline under each notice, a line of light on the edge of one that is critical.
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: NihilStyle.line }
    NSpectrum {
        visible: root.critical
        vertical: true
        width: NihilStyle.s(2)
        height: parent.height - NihilStyle.s(16)
        y: NihilStyle.s(8)
    }

    MouseArea {
        id: tap
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifications.attemptInvokeAction(root.entry.notificationId, root.entry?.actions?.[0]?.identifier ?? "default")
    }

    NAppIcon {
        id: mark
        x: NihilStyle.s(10)
        y: NihilStyle.s(10)
        appId: root.entry?.appIcon || root.entry?.appName || ""
        size: NihilStyle.s(32)
    }

    Column {
        id: words
        x: mark.x + mark.width + NihilStyle.s(10)
        y: NihilStyle.s(10)
        width: parent.width - x - NihilStyle.s(36)

        spacing: NihilStyle.s(2)

        NLabel {
            width: parent.width
            text: (root.entry?.appName ?? "") + "   " + root.when(root.entry?.time ?? Date.now())
            strong: root.critical
        }
        NText {
            width: parent.width
            text: root.entry?.summary ?? ""
            elide: Text.ElideRight
            font.weight: Font.DemiBold
        }
        NText {
            width: parent.width
            visible: root.body.length > 0
            text: root.body
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.pixelSize: NihilStyle.textSmall
            color: NihilStyle.inkSoft
        }
    }

    NButton {
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.s(4)
        y: NihilStyle.s(4)
        width: NihilStyle.s(28)
        height: NihilStyle.s(28)
        icon: "close"
        iconSize: NihilStyle.s(14)
        opacity: tap.containsMouse || containsMouse ? 1 : 0
        onClicked: Notifications.discardNotification(root.entry.notificationId)
    }
}
