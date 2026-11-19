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
    property bool open: false

    readonly property var notices: [...Notifications.list].sort((a, b) => b.time - a.time)
    readonly property real side: NihilStyle.s(28)


    Component.onCompleted: Notifications.ensureInitialized()

    TodayCalendar {
        id: calendar
        x: root.side
        y: root.side
        width: Math.min(NihilStyle.s(360), root.width * 0.42)
        height: root.height - root.side * 2
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
            width: parent.width - keys.width - NihilStyle.spacing
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
                highlighted: Notifications.silent
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

        NEmpty {
            anchors.centerIn: list
            visible: root.notices.length === 0
            icon: Notifications.silent ? "notifications_paused" : "notifications"
            title: Translation.tr("All caught up")
            note: Notifications.silent ? Translation.tr("Do not disturb is on") : Translation.tr("New notifications land here")
        }
    }
}
