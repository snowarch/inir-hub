pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// Today as a glass pane under the time: the day named, the month on a card, then every notification newest first
// under the keys that silence or clear them.
NPopup {
    id: root

    open: NihilState.todayOpen
    namespace: "nihil:today"
    blurPieces: [pane.region]
    onDismissed: NihilState.todayOpen = false

    readonly property bool barBottom: (Config.options?.nihil?.panel?.position ?? "top") === "bottom"
    readonly property var notices: [...Notifications.list].sort((a, b) => b.time - a.time)
    readonly property real inset: NihilStyle.s(16)

    Component.onCompleted: Notifications.ensureInitialized()

    NGlass {
        id: pane

        readonly property real room: parent.height - NihilStyle.barHeight - NihilStyle.edge * 3

        width: NihilStyle.s(384)
        height: Math.min(pane.room, calendar.height + head.height + list.wanted + root.inset * 2 + NihilStyle.gap * 2)
        x: Math.round((parent.width - width) / 2)
        y: root.barBottom ? parent.height - height - NihilStyle.barHeight - NihilStyle.edge * 2
            : NihilStyle.barHeight + NihilStyle.edge * 2
        ignite: root.open ? 0.35 : 0
        Behavior on height { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        TodayCalendar {
            id: calendar
            x: root.inset
            y: root.inset
            width: pane.width - root.inset * 2
            live: root.open
        }

        Item {
            id: head
            x: root.inset
            y: calendar.y + calendar.height + NihilStyle.gap
            width: pane.width - root.inset * 2
            height: NihilStyle.s(36)

            NText {
                anchors.left: parent.left
                anchors.leftMargin: NihilStyle.s(4)
                anchors.verticalCenter: parent.verticalCenter
                text: Translation.tr("Notifications")
                font.weight: Font.DemiBold
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: NihilStyle.s(4)

                NButton {
                    icon: Notifications.silent ? "notifications_paused" : "bell"
                    lit: Notifications.silent
                    onClicked: Notifications.toggleSilent()
                }
                NButton {
                    visible: root.notices.length > 0
                    icon: "delete_sweep"
                    onClicked: Notifications.discardAllNotifications()
                }
            }
        }

        Item {
            id: list

            readonly property real wanted: root.notices.length > 0
                ? Math.min(NihilStyle.s(380), notes.implicitHeight) : NihilStyle.s(96)

            x: root.inset
            y: head.y + head.height + NihilStyle.gap
            width: pane.width - root.inset * 2
            height: pane.height - y - root.inset

            Flickable {
                anchors.fill: parent
                visible: root.notices.length > 0
                clip: true
                contentHeight: notes.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: notes
                    width: list.width
                    spacing: NihilStyle.s(6)

                    Repeater {
                        model: root.notices
                        delegate: TodayNotice {
                            id: notice
                            required property var modelData
                            width: notes.width
                            entry: notice.modelData
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                visible: root.notices.length === 0
                spacing: NihilStyle.s(4)

                NIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Notifications.silent ? "notifications_paused" : "notifications"
                    size: NihilStyle.s(26)
                    color: NihilStyle.inkFaint
                }
                NText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Translation.tr("All caught up")
                    font.weight: Font.DemiBold
                    color: NihilStyle.inkSoft
                }
                NLabel {
                    color: NihilStyle.inkFaint
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Notifications.silent ? Translation.tr("Do not disturb is on") : Translation.tr("New notifications land here")
                }
            }
        }
    }
}
