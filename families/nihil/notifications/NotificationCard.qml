pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// One notification on glass: the app's mark, who sent it, the summary and the body, then its actions. A click opens it,
// resting on it keeps it, the cross lets it go. An urgent one glows from its edge.
NGlass {
    id: root

    required property var notification

    readonly property bool critical: root.notification.urgency === "critical"
    readonly property var actions: (root.notification.actions ?? []).slice(0, 3)

    implicitHeight: content.implicitHeight + NihilStyle.s(32)
    radius: NihilStyle.rCard

    ignite: root.critical ? 0.8 : 0.15

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: Notifications.cancelTimeout(root.notification.notificationId)
        onClicked: Notifications.attemptInvokeAction(root.notification.notificationId, "default")
    }

    Row {
        id: content
        x: NihilStyle.s(16)
        y: NihilStyle.s(16)
        width: root.width - NihilStyle.s(32)
        spacing: NihilStyle.s(12)

        NAppIcon {
            appId: root.notification.appIcon || root.notification.appName
            size: NihilStyle.s(36)
        }

        Column {
            width: content.width - NihilStyle.s(48) - dismiss.width
            spacing: NihilStyle.s(3)

            NText {
                width: parent.width
                text: root.notification.appName + "  ·  " + Translation.tr("Now")
                font.pixelSize: NihilStyle.textLabel
                font.weight: Font.Medium
                color: root.critical ? NihilStyle.danger : NihilStyle.inkSoft
            }
            NText {
                width: parent.width
                text: root.notification.summary
                elide: Text.ElideRight
                font.pixelSize: NihilStyle.textBody
                font.weight: Font.DemiBold
                color: NihilStyle.ink
            }
            NText {
                width: parent.width
                visible: text.length > 0
                text: root.notification.body
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
            }
            Row {
                visible: root.actions.length > 0
                topPadding: NihilStyle.s(8)
                spacing: NihilStyle.gap

                Repeater {
                    model: root.actions
                    delegate: NButton {
                        required property var modelData
                        required property int index
                        label: modelData.text
                        lit: index === 0
                        onClicked: Notifications.attemptInvokeAction(root.notification.notificationId, modelData.identifier)
                    }
                }
            }
        }

        NButton {
            id: dismiss
            width: NihilStyle.s(28)
            height: NihilStyle.s(28)
            iconSize: NihilStyle.s(14)
            icon: "close"
            onClicked: Notifications.discardNotification(root.notification.notificationId)
        }
    }
}
