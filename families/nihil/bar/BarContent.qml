pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// The bar's three groups on one line, each piece standing alone on the wallpaper: the left keys (quick controls,
// NiHiL's menu), the middle (Start, search, the apps), the right (the tray's chevron and the status pill).
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
        spacing: NihilStyle.gap
        y: root.atBottom ? root.height - NihilStyle.barMargin - height + root.lift : NihilStyle.barMargin - root.lift
        height: NihilStyle.button
    }

    Group {
        id: leftGroup
        x: NihilStyle.edge
        NButton {
            icon: "toggle_on"
            lit: NihilState.controlOpen
            onClicked: NihilState.toggle("control")
        }
        NButton {
            id: menuKey
            square: true
            lit: NihilState.menuOpen
            onClicked: NihilState.toggle("menu")
            NihilMark {
                anchors.centerIn: parent
                size: menuKey.width * 0.42
                color: menuKey.ink
                grid: true
            }
        }
    }

    Group {
        id: centerGroup
        x: Math.round((root.width - width) / 2)
        NButton {
            id: startKey
            lit: NihilState.startOpen
            onClicked: NihilState.toggle("start")
            NihilMark {
                anchors.centerIn: parent
                size: startKey.width * 0.38
                color: startKey.ink
                ground: startKey.color
            }
        }
        NButton {
            visible: NihilStyle.options?.bar?.showSearch ?? true
            width: NihilStyle.s(150)
            onClicked: NihilState.toggle("start")
            Row {
                anchors.verticalCenter: parent.verticalCenter
                x: NihilStyle.s(18)
                spacing: NihilStyle.s(12)
                NIcon { anchors.verticalCenter: parent.verticalCenter; text: "search"; size: NihilStyle.s(22) }
                NText {
                    anchors.verticalCenter: parent.verticalCenter
                    serif: true
                    text: Translation.tr("Search")
                    font.pixelSize: NihilStyle.textLarge
                }
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
            icon: NihilState.trayOpen ? "keyboard_arrow_down" : "keyboard_arrow_up"
            iconSize: NihilStyle.s(28)
            split: !NihilState.trayOpen
            lit: NihilState.trayOpen
            onClicked: NihilState.toggle("tray")
        }
        StatusPill {
            onClicked: NihilState.toggle("control")
        }
    }
}
