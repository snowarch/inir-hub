pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// One notification: the app's mark, who sent it and when, the summary and the body, then its actions. A click opens it,
// resting on it keeps it, the cross on the body's line lets it go.
MouseArea {
    id: root

    required property var notice
    property bool alone: true

    implicitHeight: Math.max(NihilStyle.s(64), words.implicitHeight + (root.alone ? 0 : NihilStyle.s(20)))
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    Accessible.role: Accessible.Button
    Accessible.name: root.notice.summary
    onEntered: Notifications.cancelTimeout(root.notice.id)
    onClicked: Notifications.attemptInvokeAction(root.notice.id, "default")

    NWell {
        anchors.fill: parent
        visible: !root.alone
        radius: NihilStyle.rCard
        hovered: root.containsMouse
    }
    NAppIcon {
        id: mark
        x: root.alone ? 0 : NihilStyle.s(12)
        y: NihilStyle.s(12)
        appId: root.notice.icon
        size: NihilStyle.s(40)
    }
    Column {
        id: words
        x: mark.x + mark.width + NihilStyle.s(12)
        y: root.alone ? NihilStyle.s(10) : NihilStyle.s(10)
        width: parent.width - x - (root.alone ? 0 : NihilStyle.s(12))
        spacing: NihilStyle.s(2)

        Item {
            width: parent.width
            height: title.implicitHeight
            NText {
                id: title
                width: parent.width - now.implicitWidth - NihilStyle.gap
                text: root.notice.summary || root.notice.app
                font.weight: Font.Medium
                color: root.notice.critical ? NihilStyle.danger : NihilStyle.ink
            }
            NText {
                id: now
                anchors.right: parent.right
                text: Translation.tr("Now")
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkFaint
            }
        }
        NText {
            width: parent.width - NihilStyle.s(30)
            visible: text.length > 0
            text: root.notice.body
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 2
            font.pixelSize: NihilStyle.textSmall
            color: NihilStyle.inkSoft
        }
        Row {
            visible: root.notice.actions.length > 0
            topPadding: NihilStyle.gap
            bottomPadding: NihilStyle.s(4)
            spacing: NihilStyle.s(6)
            Repeater {
                model: root.notice.actions
                NButton {
                    required property var modelData
                    required property int index
                    height: NihilStyle.s(32)
                    label: modelData.text
                    lit: index === 0
                    onClicked: Notifications.attemptInvokeAction(root.notice.id, modelData.id)
                }
            }
        }
    }
    NButton {
        anchors.right: parent.right
        anchors.rightMargin: root.alone ? -NihilStyle.s(6) : NihilStyle.s(6)
        y: NihilStyle.s(30)
        width: NihilStyle.s(28)
        height: width
        radius: width / 2
        opacity: root.containsMouse || containsMouse ? 1 : 0
        icon: "close"
        iconSize: NihilStyle.s(14)
        Accessible.name: Translation.tr("Dismiss")
        onClicked: Notifications.discardNotification(root.notice.id)
    }
}
