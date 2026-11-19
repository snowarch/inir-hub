pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// The day, on the slab pulled from under the clock: the date and the month on one side with what comes next, what arrived
// on the other, newest first.
Item {
    id: root

    property var screen: null
    property bool flipped: false
    property real room: 0
    property bool open: false

    readonly property var notices: [...Notifications.list].sort((a, b) => b.time - a.time)
    readonly property real side: NihilStyle.s(28)
    readonly property real headPad: NihilStyle.s(20)
    readonly property real footPad: NihilStyle.s(26)

    implicitWidth: NihilStyle.s(900)
    implicitHeight: Math.min(NihilStyle.s(660), root.room)

    Component.onCompleted: Notifications.ensureInitialized()

    TodayCalendar {
        id: calendar
        x: root.side
        y: root.flipped ? root.footPad : root.headPad
        width: NihilStyle.s(350)
        height: root.height - root.headPad - root.footPad
        live: root.open
    }

    Item {
        id: arrived
        x: calendar.x + calendar.width + NihilStyle.s(40)
        y: calendar.y
        width: root.width - x - root.side
        height: calendar.height

        NDisplay {
            id: heading
            width: parent.width - keys.width - NihilStyle.gap
            height: NihilStyle.s(52)
            text: Translation.tr("Notifications")
            size: NihilStyle.s(34)
            font.weight: Font.ExtraLight
        }
        Row {
            id: keys
            anchors.right: parent.right
            anchors.verticalCenter: heading.verticalCenter
            spacing: NihilStyle.s(2)
            NButton {
                radius: width / 2
                tone: "transparent"
                icon: Notifications.silent ? "notifications_paused" : "bell"
                lit: Notifications.silent
                Accessible.name: Translation.tr("Do not disturb")
                onClicked: Notifications.toggleSilent()
            }
            NButton {
                visible: root.notices.length > 0
                radius: width / 2
                tone: "transparent"
                icon: "delete_sweep"
                Accessible.name: Translation.tr("Clear all")
                onClicked: Notifications.discardAllNotifications()
            }
        }

        ListView {
            id: list
            y: heading.height + NihilStyle.s(16)
            width: parent.width
            height: parent.height - y
            clip: true
            spacing: NihilStyle.s(9)
            boundsBehavior: Flickable.StopAtBounds
            model: root.notices
            delegate: TodayNotice {
                id: notice
                required property var modelData
                width: list.width
                entry: notice.modelData
            }
        }

        Column {
            anchors.centerIn: list
            visible: root.notices.length === 0
            spacing: NihilStyle.s(6)
            NIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Notifications.silent ? "notifications_paused" : "notifications"
                size: NihilStyle.s(28)
                color: NihilStyle.inkFaint
            }
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Translation.tr("All caught up")
                font.pixelSize: NihilStyle.s(15)
            }
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Notifications.silent ? Translation.tr("Do not disturb is on") : Translation.tr("New notifications land here")
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
            }
        }
    }
}
