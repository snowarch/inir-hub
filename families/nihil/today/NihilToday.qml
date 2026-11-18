pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// Today, over the time: the day on paper, how much of it is gone, the month as a grid of steps, then every notification
// as a tile of its own, newest first, under a head that silences or clears them.
NPopup {
    id: root

    open: NihilState.todayOpen
    namespace: "nihil:today"
    onDismissed: NihilState.todayOpen = false

    readonly property var notices: [...Notifications.list].sort((a, b) => b.time - a.time)
    readonly property real g: NihilStyle.seam

    Component.onCompleted: Notifications.ensureInitialized()

    NRack {
        id: rack
        width: NihilStyle.s(372)
        readonly property real room: root.height - root.edgeTop - root.edgeBottom
        height: Math.min(rack.room, calendar.height + head.height + list.wanted + root.g * 2)
        x: parent.width - width - NihilStyle.edge
        y: root.barBottom ? parent.height - height - root.edgeBottom : root.edgeTop

        TodayCalendar {
            id: calendar
            width: rack.width
            live: root.open
        }

        Row {
            id: head
            y: calendar.height + root.g
            height: NihilStyle.s(56)
            spacing: root.g

            NTile {
                id: tally
                width: rack.width - silence.width - clear.width - root.g * 2
                height: parent.height
                NFigure {
                    id: count
                    x: tally.pad
                    anchors.verticalCenter: parent.verticalCenter
                    size: NihilStyle.s(30)
                    text: String(root.notices.length)
                    color: NihilStyle.ink
                }
                NCaps {
                    anchors.left: count.right
                    anchors.leftMargin: NihilStyle.s(8)
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr("Notifications")
                    color: NihilStyle.inkSoft
                }
            }
            NButton {
                id: silence
                width: NihilStyle.s(56); height: parent.height
                square: true
                icon: Notifications.silent ? "notifications_off" : "notifications"
                iconSize: NihilStyle.s(22)
                lit: Notifications.silent
                onClicked: Notifications.toggleSilent()
            }
            NButton {
                id: clear
                width: NihilStyle.s(56); height: parent.height
                square: true
                icon: "delete_sweep"
                iconSize: NihilStyle.s(22)
                interactive: root.notices.length > 0
                ink: root.notices.length > 0 ? NihilStyle.ink : NihilStyle.dotOff
                onClicked: Notifications.discardAllNotifications()
            }
        }

        Item {
            id: list
            readonly property real wanted: root.notices.length > 0 ? Math.min(NihilStyle.s(380), notes.implicitHeight) : NihilStyle.s(120)
            y: head.y + head.height + root.g
            width: rack.width
            height: rack.height - y

            NScroller {
                id: scroller
                anchors.fill: parent
                visible: root.notices.length > 0
                Column {
                    id: notes
                    width: scroller.innerWidth
                    spacing: root.g
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
            NTile {
                anchors.fill: parent
                visible: root.notices.length === 0
                Column {
                    anchors.centerIn: parent
                    spacing: NihilStyle.s(2)
                    NText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Translation.tr("All caught up")
                        font.pixelSize: NihilStyle.textLarge
                        font.weight: Font.Black
                    }
                    NCaps {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Notifications.silent ? Translation.tr("Do not disturb is on") : Translation.tr("New notifications land here")
                        color: NihilStyle.inkSoft
                    }
                }
            }
        }
    }
}
