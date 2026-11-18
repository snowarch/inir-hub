pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Bluetooth
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// The panel: workspaces and the overview on the left, the time in the middle, the machine's state on the right.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        required property var modelData
        readonly property var panel: Config.options?.nihil?.panel
        readonly property bool bottom: (bar.panel?.position ?? "top") === "bottom"
        readonly property string visibility: bar.panel?.visibility ?? "always"
        readonly property var outputs: Array.from(bar.panel?.screenList ?? [])
        readonly property bool listed: bar.outputs.length === 0 || bar.outputs.includes(bar.modelData.name)
        readonly property string output: bar.modelData.name
        readonly property var workspaces: NihilState.workspacesOn(bar.output)

        screen: bar.modelData
        readonly property bool bare: NihilState.windowsOn(bar.workspaces.find(ws => ws.is_active)?.id).length === 0
        visible: (Config.options?.nihil?.modules?.panel ?? true) && bar.listed && (GlobalStates.barOpen ?? true)
            && (bar.visibility === "always" || NihilState.overviewOpen || (bar.visibility === "desktop" && bar.bare))
        color: "transparent"
        implicitHeight: NihilStyle.barHeight
        exclusiveZone: bar.visibility === "always" ? NihilStyle.barHeight : 0
        WlrLayershell.namespace: "quickshell:nihil-panel"
        WlrLayershell.layer: bar.visibility === "always" ? WlrLayer.Top : WlrLayer.Overlay
        anchors { left: true; right: true; top: !bar.bottom; bottom: bar.bottom }

        BackgroundEffect.blurRegion: CompositorService.blurRegions && NihilStyle.blur ? glass.region : null

        NGlass {
            id: glass
            anchors.fill: parent
            radius: 0
            shadow: 0
            tracks: true
            opacity: NihilState.overviewOpen && (bar.panel?.overviewStyle ?? "same") === "transparent" ? 0 : 1
            light: Qt.point(bar.width * 0.5, bar.bottom ? bar.height : 0)
        }

        // Left: the overview's button is the workspace indicator.
        NButton {
            id: activities
            anchors.left: parent.left
            anchors.leftMargin: NihilStyle.s(6)
            anchors.verticalCenter: parent.verticalCenter
            height: NihilStyle.s(26)
            width: dots.implicitWidth + NihilStyle.s(22)
            radius: height / 2
            lit: NihilState.overviewOpen
            Accessible.name: Translation.tr("Activities")
            onClicked: mouse => {
                if (mouse?.button === Qt.RightButton) NihilState.toggleOverview("apps")
                else NihilState.toggleOverview("windows")
            }
            onWheel: wheel => NihilState.stepWorkspace(bar.output, wheel.angleDelta.y > 0 ? -1 : 1)
            Row {
                id: dots
                anchors.centerIn: parent
                spacing: NihilStyle.s(5)
                Repeater {
                    model: bar.workspaces
                    Rectangle {
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter
                        width: modelData.is_active ? NihilStyle.s(22) : NihilStyle.s(7)
                        height: NihilStyle.s(7)
                        radius: height / 2
                        color: activities.ink
                        opacity: modelData.is_active ? 1 : 0.45
                        Behavior on width { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }

        // Centre: the time opens the calendar and notifications.
        NButton {
            anchors.centerIn: parent
            height: NihilStyle.s(26)
            id: timeKey
            width: clock.implicitWidth + NihilStyle.s(24)
            radius: height / 2
            lit: NihilState.todayOpen
            Accessible.name: Translation.tr("Calendar and notifications")
            onClicked: NihilState.toggle("today")
            NText {
                id: clock
                anchors.centerIn: parent
                figures: true
                text: DateTime.date + "   " + DateTime.time
                font.weight: Font.DemiBold
                color: timeKey.ink
            }
        }

        // Right: tray, then the status that opens quick settings.
        Row {
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(6)
            anchors.verticalCenter: parent.verticalCenter
            spacing: NihilStyle.s(4)

            Repeater {
                model: SystemTray.items
                MouseArea {
                    id: trayItem
                    required property SystemTrayItem modelData
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(26)
                    height: NihilStyle.s(26)
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button !== Qt.RightButton) { trayItem.modelData.activate(); return }
                        if (!trayItem.modelData.hasMenu) { trayItem.modelData.secondaryActivate(); return }
                        const at = trayItem.mapToItem(bar.contentItem, 0, trayItem.height)
                        trayItem.modelData.display(bar, at.x, at.y)
                    }
                    Image {
                        anchors.centerIn: parent
                        width: NihilStyle.s(16)
                        height: NihilStyle.s(16)
                        sourceSize: Qt.size(width, height)
                        source: trayItem.modelData.icon
                    }
                }
            }

            NButton {
                id: status
                anchors.verticalCenter: parent.verticalCenter
                height: NihilStyle.s(26)
                width: glyphs.implicitWidth + NihilStyle.s(20)
                radius: height / 2
                lit: NihilState.controlOpen
                Accessible.name: Translation.tr("Quick settings")
                onClicked: NihilState.toggle("control")
                Row {
                    id: glyphs
                    anchors.centerIn: parent
                    spacing: NihilStyle.s(8)
                    NIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Network.ethernet ? "lan" : Network.wifiEnabled ? "wifi" : "wifi_off"
                        size: NihilStyle.s(15)
                        color: status.ink
                    }
                    NIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Bluetooth.defaultAdapter?.enabled ?? false
                        text: "bluetooth"
                        size: NihilStyle.s(15)
                        color: status.ink
                    }
                    NIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (Audio.sink?.audio?.muted ?? false) ? "volume_mute" : "volume_up"
                        size: NihilStyle.s(15)
                        color: status.ink
                    }
                    NText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Battery.available
                        figures: true
                        text: Math.round(Battery.percentage * 100) + "%"
                        font.pixelSize: NihilStyle.textSmall
                        font.weight: Font.DemiBold
                        color: status.ink
                    }
                }
            }
        }
    }
}
