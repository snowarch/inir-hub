pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// The bar: three blocks of tiles on the screen's edge. Start, the menu and the workspaces; search and the apps;
// the tray, the machine's state, what waits to be read and the time.
Item {
    id: root

    required property var screen
    property bool atBottom: true
    property bool tucked: false
    readonly property alias groupLeft: leftGroup
    readonly property alias groupCenter: centerGroup
    readonly property alias groupRight: rightGroup
    property real lift: root.tucked ? NihilStyle.barZone : 0
    Behavior on lift { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }

    component Group: Row {
        spacing: NihilStyle.seam
        y: root.atBottom ? root.height - NihilStyle.barMargin - height + root.lift : NihilStyle.barMargin - root.lift
        height: NihilStyle.button
    }

    Group {
        id: leftGroup
        x: NihilStyle.edge
        NButton {
            id: startKey
            paper: !NihilState.startOpen
            lit: NihilState.startOpen
            onClicked: NihilState.toggle("start")
            NihilMark {
                anchors.centerIn: parent
                size: startKey.width * 0.5
                color: startKey.ink
                ground: startKey.color
            }
        }
        NButton {
            id: menuKey
            lit: NihilState.menuOpen
            onClicked: NihilState.toggle("menu")
            NihilMark {
                anchors.centerIn: parent
                size: menuKey.width * 0.42
                color: menuKey.ink
                grid: true
            }
        }
        Workspaces {
            visible: CompositorService.isNiri && spaces.length > 0
            screen: root.screen
        }
    }

    Group {
        id: centerGroup
        x: Math.round((root.width - width) / 2)
        NButton {
            id: searchKey
            visible: NihilStyle.options?.bar?.showSearch ?? true
            width: NihilStyle.s(196)
            onClicked: NihilState.toggle("start")
            NIcon {
                x: NihilStyle.s(14)
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                size: NihilStyle.s(20)
                color: searchKey.ink
            }
            NText {
                x: NihilStyle.s(44)
                anchors.verticalCenter: parent.verticalCenter
                text: Translation.tr("Search")
                font.pixelSize: NihilStyle.textBody
                font.weight: Font.DemiBold
                color: searchKey.ink
            }
        }
        Repeater {
            model: (NihilStyle.options?.bar?.showApps ?? true) ? TaskbarApps.apps.filter(app => app.appId !== "SEPARATOR") : []
            delegate: AppCircle {}
        }
    }

    Group {
        id: rightGroup
        x: root.width - NihilStyle.edge - width
        NButton {
            width: NihilStyle.s(30)
            icon: NihilState.trayOpen ? "expand_more" : "expand_less"
            iconSize: NihilStyle.s(20)
            lit: NihilState.trayOpen
            onClicked: NihilState.toggle("tray")
        }
        StatusPill {
            lit: NihilState.controlOpen
            onClicked: NihilState.toggle("control")
        }
        NButton {
            id: countKey
            visible: Notifications.list.length > 0
            width: Math.max(NihilStyle.button, count.implicitWidth + NihilStyle.s(20))
            lit: !Notifications.silent
            onClicked: NihilState.toggle("today")
            NFigure {
                id: count
                anchors.centerIn: parent
                size: NihilStyle.s(22)
                text: String(Notifications.list.length)
                color: countKey.ink
            }
        }
        NButton {
            id: clockKey
            readonly property string day: {
                DateTime.timeDisplay
                return Qt.locale().toString(new Date(), "ddd d")
            }
            width: times.implicitWidth + NihilStyle.s(24)
            paper: !NihilState.todayOpen
            lit: NihilState.todayOpen
            onClicked: NihilState.toggle("today")
            Column {
                id: times
                anchors.centerIn: parent
                spacing: -NihilStyle.s(2)
                NFigure {
                    anchors.horizontalCenter: parent.horizontalCenter
                    size: NihilStyle.s(21)
                    text: DateTime.timeDisplay
                    color: clockKey.ink
                }
                NCaps {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: clockKey.day
                    font.pixelSize: NihilStyle.s(9)
                    color: clockKey.ink
                }
            }
        }
    }
}
