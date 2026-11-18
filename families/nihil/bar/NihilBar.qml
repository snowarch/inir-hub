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

// A thin smoked strip. Left: where you are, as dots that grow for the workspace in front, and the window that has
// the keys. Centre: the day and the time. Right: the tray and the machine as icons. What is open sits on a raised
// plate; what is under the pointer gets a faint one.
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
        readonly property int at: NihilState.activeIndexOn(bar.output)
        readonly property var focused: (NiriService.windows ?? []).find(win => win.is_focused
            && win.workspace_id === bar.workspaces[bar.at]?.id) ?? null
        readonly property bool clear: NihilState.overviewOpen && (bar.panel?.overviewStyle ?? "same") === "transparent"

        screen: bar.modelData
        readonly property bool bare: NihilState.windowsOn(bar.workspaces[bar.at]?.id).length === 0
        visible: (Config.options?.nihil?.modules?.panel ?? true) && bar.listed && (GlobalStates.barOpen ?? true)
            && (bar.visibility === "always" || NihilState.overviewOpen || (bar.visibility === "desktop" && bar.bare))
        color: "transparent"
        implicitHeight: NihilStyle.barHeight
        exclusiveZone: bar.visibility === "always" ? NihilStyle.barHeight : 0
        WlrLayershell.namespace: "quickshell:nihil-panel"
        WlrLayershell.layer: bar.visibility === "always" ? WlrLayer.Top : WlrLayer.Overlay
        anchors { left: true; right: true; top: !bar.bottom; bottom: bar.bottom }

        BackgroundEffect.blurRegion: CompositorService.blurRegions && NihilStyle.blur && !bar.clear ? glass.region : null

        NGlass {
            id: glass
            anchors.fill: parent
            radius: 0
            shadow: 0
            rim: 0
            tracks: true
            tint: Qt.alpha(NihilStyle.void_, NihilStyle.glassOpacity * 0.9)
            opacity: bar.clear ? 0 : 1
            light: Qt.point(bar.width * 0.5, bar.bottom ? bar.height : 0)
            Behavior on opacity { NumberAnimation { duration: NihilStyle.calm } }
        }

        component Key: MouseArea {
            id: key
            property bool lit: false
            readonly property color ink: key.lit || key.containsMouse ? NihilStyle.ink : NihilStyle.inkSoft
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            height: bar.height
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: NihilStyle.s(5)
                anchors.bottomMargin: NihilStyle.s(5)
                radius: height / 2
                color: key.lit ? NihilStyle.chosen : NihilStyle.piece
                border.width: key.lit ? 1 : 0
                border.color: NihilStyle.hair
                opacity: key.lit || key.containsMouse ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: NihilStyle.quick } }
            }
        }

        // Left: the workspaces as dots, the one in front drawn long in the accent.
        Key {
            id: lead
            anchors.left: parent.left
            anchors.leftMargin: NihilStyle.s(8)
            width: dots.implicitWidth + NihilStyle.s(24)
            lit: NihilState.overviewOpen
            Accessible.role: Accessible.Button
            Accessible.name: Translation.tr("Activities")
            onClicked: mouse => NihilState.toggleOverview(mouse.button === Qt.RightButton ? "apps" : "windows")
            onWheel: wheel => NihilState.stepWorkspace(bar.output, wheel.angleDelta.y > 0 ? -1 : 1)
            Row {
                id: dots
                anchors.centerIn: parent
                spacing: NihilStyle.s(5)
                Repeater {
                    model: bar.workspaces
                    Rectangle {
                        required property var modelData
                        readonly property bool filled: NihilState.windowsOn(modelData.id).length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: modelData.is_active ? NihilStyle.s(20) : NihilStyle.s(6)
                        height: NihilStyle.s(6)
                        radius: height / 2
                        color: modelData.is_active ? NihilStyle.accent : filled ? Qt.alpha(NihilStyle.ink, 0.55) : Qt.alpha(NihilStyle.ink, 0.2)
                        Behavior on width { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutQuint } }
                        Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
                    }
                }
            }
        }
        NText {
            id: title
            anchors.left: lead.right
            anchors.leftMargin: NihilStyle.s(10)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, Math.max(0, middle.x - x - NihilStyle.s(40)))
            visible: (bar.panel?.windowTitle ?? true) && bar.focused !== null && width > NihilStyle.s(30)
            text: AppSearch.lookupDesktopEntry(bar.focused?.app_id ?? "")?.name ?? String(bar.focused?.app_id ?? "")
            font.pixelSize: NihilStyle.textSmall
            font.weight: Font.Medium
            color: NihilStyle.inkSoft
        }

        // Centre: the day, then the time.
        Key {
            id: middle
            anchors.horizontalCenter: parent.horizontalCenter
            width: timeRow.implicitWidth + NihilStyle.s(28)
            lit: NihilState.todayOpen
            Accessible.role: Accessible.Button
            Accessible.name: Translation.tr("Calendar and notifications")
            onClicked: NihilState.toggle("today")
            Row {
                id: timeRow
                anchors.centerIn: parent
                spacing: NihilStyle.s(8)
                NText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: DateTime.date
                    font.pixelSize: NihilStyle.textSmall
                    font.weight: Font.Medium
                    color: middle.lit || middle.containsMouse ? NihilStyle.inkSoft : NihilStyle.inkFaint
                }
                NText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: DateTime.time
                    figures: true
                    font.pixelSize: NihilStyle.textBody
                    font.weight: Font.DemiBold
                    color: NihilStyle.ink
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Notifications.list.length > 0
                    width: NihilStyle.s(6)
                    height: width
                    radius: width / 2
                    color: NihilStyle.accent
                }
            }
        }

        // Right: the tray, then the machine as words.
        Row {
            id: right
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(8)
            height: parent.height
            spacing: NihilStyle.s(2)

            // The tray as the other families keep it (pinned first, quiet ones out when the shell says so). Left
            // opens the app or its menu when that is all it has, middle is its second action, right its menu,
            // the wheel its scroll.
            Repeater {
                model: [...TrayService.pinnedItems, ...TrayService.unpinnedItems]
                MouseArea {
                    id: trayItem
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(28)
                    height: NihilStyle.s(28)
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: trayItem.modelData?.tooltipTitle || trayItem.modelData?.title || trayItem.modelData?.id || ""
                    readonly property bool asked: trayMenu.item === trayItem.modelData
                    function openMenu(): void {
                        const at = trayItem.mapToItem(null, trayItem.width / 2, 0)
                        trayMenu.show(trayItem.modelData, bar.screen, Qt.point(at.x, 0), bar.bottom)
                    }
                    onClicked: mouse => {
                        const app = trayItem.modelData
                        if (!app) return
                        if (mouse.button === Qt.MiddleButton) app.secondaryActivate()
                        else if (mouse.button === Qt.RightButton || app.onlyMenu) {
                            if (app.hasMenu) trayItem.openMenu()
                            else app.secondaryActivate()
                        } else if (!TrayService.smartToggle(app)) app.activate()
                    }
                    onWheel: wheel => trayItem.modelData?.scroll(wheel.angleDelta.y || wheel.angleDelta.x, wheel.angleDelta.y === 0)
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: trayItem.asked ? NihilStyle.chosen : NihilStyle.piece
                        visible: trayItem.asked || trayItem.containsMouse
                    }
                    Image {
                        anchors.centerIn: parent
                        width: NihilStyle.s(16)
                        height: NihilStyle.s(16)
                        sourceSize: Qt.size(width * 2, height * 2)
                        source: trayItem.modelData ? TrayService.getSafeIcon(trayItem.modelData) : ""
                        opacity: trayItem.containsMouse || trayItem.asked ? 1 : 0.78
                    }
                    Rectangle {
                        visible: trayItem.modelData?.status === Status.NeedsAttention
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: NihilStyle.s(4)
                        width: NihilStyle.s(6)
                        height: width
                        radius: width / 2
                        color: NihilStyle.accent
                    }
                }
            }

            Item { width: NihilStyle.s(10); height: 1 }

            Key {
                id: status
                width: statusRow.implicitWidth + NihilStyle.s(24)
                lit: NihilState.controlOpen
                Accessible.role: Accessible.Button
                Accessible.name: Translation.tr("Quick settings")
                onClicked: NihilState.toggle("control")
                onWheel: wheel => {
                    const sink = Audio.sink?.audio
                    if (sink) sink.volume = NihilStyle.clamp(sink.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05), 0, 1)
                }
                Row {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: NihilStyle.s(14)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: NihilStyle.s(5)
                        NIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Network.ethernet ? "lan" : Network.wifiEnabled ? "wifi" : "wifi_off"
                            size: NihilStyle.s(13)
                            color: status.ink
                        }
                        NLabel {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: (bar.panel?.statusWords ?? true)
                            text: Network.ethernet ? Translation.tr("Wired") : Network.wifiEnabled ? (Network.networkName || Translation.tr("Wi-Fi")) : Translation.tr("Offline")
                            width: Math.min(implicitWidth, NihilStyle.s(110))
                            color: status.ink
                        }
                    }
                    NIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Bluetooth.defaultAdapter?.enabled ?? false
                        text: "bluetooth"
                        size: NihilStyle.s(13)
                        color: status.ink
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: NihilStyle.s(5)
                        NIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (Audio.sink?.audio?.muted ?? false) ? "volume_mute" : "volume_up"
                            size: NihilStyle.s(13)
                            color: status.ink
                        }
                        NLabel {
                            anchors.verticalCenter: parent.verticalCenter
                            text: String(Math.round((Audio.sink?.audio?.volume ?? 0) * 100))
                            color: status.ink
                        }
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Battery.available
                        spacing: NihilStyle.s(4)
                        NIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            readonly property int step: Math.min(6, Math.floor(Battery.percentage * 7))
                            text: Battery.isCharging ? "battery_charging_full" : Battery.percentage > 0.95 ? "battery_full" : "battery_" + step + "_bar"
                            size: NihilStyle.s(14)
                            color: Battery.isLowAndNotCharging ? NihilStyle.danger : status.ink
                        }
                        NText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(Battery.percentage * 100) + "%"
                            figures: true
                            font.pixelSize: NihilStyle.textSmall
                            font.weight: Font.Medium
                            color: status.ink
                        }
                    }
                }
            }
        }

        NihilTrayMenu { id: trayMenu }
    }
}
