pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Bluetooth
import qs
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// The band's writing. Left: NiHiL's mark, the workspaces as a ruler whose active tick is a solid key, the window that has
// the keys. Centre: the day and the time. Right: the tray, then the machine in one capsule.
Item {
    id: bar

    required property string output
    required property var screen
    property bool flipped: false

    readonly property var panel: Config.options?.nihil?.panel
    readonly property var workspaces: NihilState.workspacesOn(bar.output)
    readonly property int at: NihilState.activeIndexOn(bar.output)
    readonly property var focused: (NiriService.windows ?? []).find(win => win.is_focused
        && win.workspace_id === bar.workspaces[bar.at]?.id) ?? null
    readonly property real pad: NihilStyle.s(20)

    // The workspaces are the ticks of a ruler; the one on show is a solid key that carries its number.
    function dashLength(workspace: var): real {
        return workspace?.is_active ? NihilStyle.s(34) : NihilStyle.s(14)
    }
    // Where the sheet's light rests: the middle of the active dash.
    readonly property real lightX: {
        let x = dashes.x
        for (let n = 0; n < bar.at; n++) x += bar.dashLength(bar.workspaces[n]) + dashes.spacing
        return x + bar.dashLength(bar.workspaces[bar.at]) / 2
    }

    component Key: MouseArea {
        id: key
        property bool lit: false
        readonly property color ink: key.lit ? NihilStyle.accentInk : NihilStyle.ink
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        height: bar.height
    }

    Key {
        id: lead
        x: bar.pad - NihilStyle.s(6)
        width: NihilStyle.s(32)
        lit: NihilState.overviewOpen
        Accessible.role: Accessible.Button
        Accessible.name: Translation.tr("Activities")
        onClicked: mouse => NihilState.toggleOverview(mouse.button === Qt.RightButton ? "apps" : "windows")
        NMark {
            anchors.centerIn: parent
            size: NihilStyle.s(20)
        }
    }

    Row {
        id: dashes
        x: lead.x + lead.width + NihilStyle.s(14)
        height: parent.height
        spacing: NihilStyle.s(6)
        Repeater {
            model: bar.workspaces
            MouseArea {
                id: dash
                required property var modelData
                required property int index
                readonly property bool active: dash.index === bar.at
                width: bar.dashLength(dash.modelData)
                height: bar.height
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: Translation.tr("Workspace %1").arg(dash.index + 1)
                onClicked: NiriService.switchToWorkspaceById(dash.modelData.id)
                Behavior on width { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
                readonly property bool holds: NihilState.windowsOn(dash.modelData.id).length > 0
                Rectangle {
                    anchors.centerIn: parent
                    width: dash.active ? parent.width : NihilStyle.s(2)
                    height: dash.active ? NihilStyle.s(22) : dash.holds ? NihilStyle.s(16) : NihilStyle.s(8)
                    radius: dash.active ? height / 2 : 1
                    color: dash.active ? NihilStyle.accent : Qt.alpha(NihilStyle.ink, dash.containsMouse ? 0.9 : dash.holds ? 0.62 : 0.3)
                    Behavior on width { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
                }
                NText {
                    anchors.centerIn: parent
                    visible: dash.active
                    text: dash.index + 1
                    figures: true
                    font.pixelSize: NihilStyle.textLabel
                    font.weight: Font.DemiBold
                    color: NihilStyle.accentInk
                }
            }
        }
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => NihilState.stepWorkspace(bar.output, event.angleDelta.y > 0 ? -1 : 1)
        }
    }

    Row {
        id: title
        x: dashes.x + dashes.width + NihilStyle.s(22)
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, middle.x - x - NihilStyle.s(32))
        spacing: NihilStyle.s(10)
        visible: (bar.panel?.windowTitle ?? true) && bar.focused !== null && width > NihilStyle.s(40)
        NText {
            id: appName
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, title.width)
            text: AppSearch.lookupDesktopEntry(bar.focused?.app_id ?? "")?.name ?? String(bar.focused?.app_id ?? "")
            font.weight: Font.Medium
        }
        NText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, title.width - appName.width - title.spacing)
            text: String(bar.focused?.title ?? "")
            color: NihilStyle.inkSoft
        }
    }

    Key {
        id: middle
        anchors.horizontalCenter: parent.horizontalCenter
        width: clock.implicitWidth + NihilStyle.s(28)
        lit: NihilState.todayOpen
        Accessible.role: Accessible.Button
        Accessible.name: Translation.tr("Calendar and notifications")
        onClicked: NihilState.toggleOn("today", bar.output)
        Row {
            id: clock
            anchors.centerIn: parent
            spacing: NihilStyle.s(10)
            NText {
                anchors.verticalCenter: parent.verticalCenter
                text: DateTime.date
                color: middle.lit || middle.containsMouse ? NihilStyle.ink : NihilStyle.inkSoft
            }
            NText {
                anchors.verticalCenter: parent.verticalCenter
                text: DateTime.time
                figures: true
                font.pixelSize: NihilStyle.s(20)
                font.weight: Font.Light
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: Notifications.list.length > 0
                width: NihilStyle.s(5)
                height: width
                radius: width / 2
                color: NihilStyle.accent
            }
        }
    }

    Row {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: bar.pad - NihilStyle.s(8)
        height: parent.height
        spacing: NihilStyle.s(4)

        // Left opens the app, or its menu when that is all it has; middle is its second action, right its menu.
        Repeater {
            model: [...TrayService.pinnedItems, ...TrayService.unpinnedItems]
            MouseArea {
                id: trayItem
                required property var modelData
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(30)
                height: bar.height
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: trayItem.modelData?.tooltipTitle || trayItem.modelData?.title || trayItem.modelData?.id || ""
                readonly property bool asked: trayMenu.item === trayItem.modelData
                function openMenu(): void {
                    const at = trayItem.mapToItem(null, trayItem.width / 2, 0)
                    trayMenu.show(trayItem.modelData, bar.screen, Qt.point(at.x, 0), bar.flipped)
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
                Image {
                    anchors.centerIn: parent
                    width: NihilStyle.s(17)
                    height: NihilStyle.s(17)
                    sourceSize: Qt.size(width * 2, height * 2)
                    source: trayItem.modelData ? TrayService.getSafeIcon(trayItem.modelData) : ""
                    opacity: trayItem.containsMouse || trayItem.asked ? 1 : 0.62
                    Behavior on opacity { NumberAnimation { duration: NihilStyle.quick } }
                }
                Rectangle {
                    visible: trayItem.modelData?.status === Status.NeedsAttention
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: NihilStyle.s(13)
                    width: NihilStyle.s(4)
                    height: width
                    radius: width / 2
                    color: NihilStyle.accent
                }
            }
        }

        Item { width: NihilStyle.s(14); height: 1 }

        Key {
            id: status
            width: statusRow.implicitWidth + NihilStyle.s(28)
            lit: NihilState.controlOpen
            Accessible.role: Accessible.Button
            Accessible.name: Translation.tr("Quick settings")
            onClicked: NihilState.toggleOn("control", bar.output)
            onWheel: wheel => {
                const sink = Audio.sink?.audio
                if (sink) sink.volume = NihilStyle.clamp(sink.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05), 0, 1)
            }
            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: NihilStyle.s(30)
                radius: height / 2
                color: status.lit ? NihilStyle.accent : status.containsMouse ? NihilStyle.pieceRaised : NihilStyle.piece
                Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
            }
            Row {
                id: statusRow
                anchors.centerIn: parent
                spacing: NihilStyle.s(14)
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: NihilStyle.s(6)
                    NIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Network.ethernet ? "lan" : Network.wifiEnabled ? "wifi" : "wifi_off"
                        size: NihilStyle.s(18)
                        color: status.ink
                    }
                    NText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: bar.panel?.statusWords ?? false
                        width: Math.min(implicitWidth, NihilStyle.s(110))
                        text: Network.ethernet ? Translation.tr("Wired") : Network.wifiEnabled ? (Network.networkName || Translation.tr("Wi-Fi")) : Translation.tr("Offline")
                        color: status.ink
                    }
                }
                NIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Bluetooth.defaultAdapter?.enabled ?? false
                    text: "bluetooth"
                    size: NihilStyle.s(18)
                    color: status.ink
                }
                NIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: (Audio.sink?.audio?.muted ?? false) ? "volume_mute" : "volume_up"
                    size: NihilStyle.s(18)
                    color: status.ink
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Battery.available
                    spacing: NihilStyle.s(4)
                    NIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        readonly property int step: Math.min(6, Math.floor(Battery.percentage * 7))
                        text: Battery.isCharging ? "battery_charging_full" : Battery.percentage > 0.95 ? "battery_full" : "battery_" + step + "_bar"
                        size: NihilStyle.s(18)
                        color: Battery.isLowAndNotCharging ? NihilStyle.danger : status.ink
                    }
                    NText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String(Math.round(Battery.percentage * 100))
                        figures: true
                        font.weight: Font.Medium
                        color: status.ink
                    }
                }
            }
        }
    }

    NihilTrayMenu { id: trayMenu }
}
