pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// Today, over the status pill: the day in dots and its month as round cells, then every notification, newest first,
// with Do not disturb and Clear at their head.
NPopup {
    id: root

    open: NihilState.todayOpen
    namespace: "nihil:today"
    onDismissed: NihilState.todayOpen = false

    readonly property var notices: [...Notifications.list].sort((a, b) => b.time - a.time)

    Component.onCompleted: Notifications.ensureInitialized()

    NCard {
        id: card
        width: NihilStyle.s(360)
        readonly property real room: root.height - root.edgeTop - root.edgeBottom
        height: Math.min(room, calendar.height + head.height + list.wanted + NihilStyle.cellGap * 2 + pad * 2)
        x: parent.width - width - NihilStyle.edge
        y: root.barBottom ? parent.height - height - root.edgeBottom : root.edgeTop

        TodayCalendar {
            id: calendar
            width: parent.width
            live: root.open
        }

        Item {
            id: head
            y: calendar.height + NihilStyle.cellGap
            width: parent.width
            height: NihilStyle.s(44)
            NText {
                anchors.verticalCenter: parent.verticalCenter
                x: NihilStyle.s(6)
                text: root.notices.length > 0
                    ? Translation.tr("%1 notifications").arg(root.notices.length) : Translation.tr("Notifications")
                font.pixelSize: NihilStyle.textBody
                font.weight: Font.DemiBold
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: NihilStyle.s(8)
                NButton {
                    width: NihilStyle.s(36); height: width
                    tone: NihilStyle.pieceRaised
                    icon: Notifications.silent ? "notifications_off" : "notifications"
                    iconSize: NihilStyle.s(18)
                    lit: Notifications.silent
                    onClicked: Notifications.toggleSilent()
                }
                NButton {
                    visible: root.notices.length > 0
                    width: clearWord.implicitWidth + NihilStyle.s(28); height: NihilStyle.s(36)
                    tone: NihilStyle.pieceRaised
                    onClicked: Notifications.discardAllNotifications()
                    NText {
                        id: clearWord
                        anchors.centerIn: parent
                        text: Translation.tr("Clear")
                        font.pixelSize: NihilStyle.textSmall
                        font.weight: Font.Medium
                    }
                }
            }
        }

        Item {
            id: list
            readonly property real wanted: root.notices.length > 0 ? Math.min(NihilStyle.s(460), notes.implicitHeight) : NihilStyle.s(150)
            y: head.y + head.height + NihilStyle.cellGap
            width: parent.width
            height: parent.height - y

            NScroller {
                id: scroller
                anchors.fill: parent
                visible: root.notices.length > 0
                spacing: NihilStyle.s(6)
                Column {
                    id: notes
                    width: scroller.innerWidth
                    spacing: NihilStyle.s(6)
                    Repeater {
                        model: root.notices
                        delegate: TodayNotice {
                            required property var modelData
                            width: notes.width
                            notice: modelData
                        }
                    }
                }
            }
            NEmpty {
                anchors.centerIn: parent
                width: parent.width - NihilStyle.s(40)
                visible: root.notices.length === 0
                glyph: Notifications.silent ? "notifications_off" : "notifications_none"
                title: Translation.tr("All caught up")
                line: Notifications.silent ? Translation.tr("Do not disturb is on") : Translation.tr("New notifications land here")
            }
        }
    }
}
