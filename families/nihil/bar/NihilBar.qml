pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Bluetooth
import qs
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// The bar: NiHiL's panel, an ornament of glass standing beside the desktop like the tab bar beside a visionOS window.
// From its start: the mark (the dashboard), the workspaces as a column of lights with the windows of the one on show, then,
// from its end, the tray, the machine, the time and the way out. Every key names itself in a hint beside the bar.
Item {
    id: bar

    required property string output
    required property var screen

    readonly property var panel: Config.options?.nihil?.panel
    readonly property bool vertical: NihilStyle.barVertical
    readonly property string edge: NihilStyle.barEdge
    readonly property var workspaces: NihilState.workspacesOn(bar.output)
    readonly property int at: NihilState.activeIndexOn(bar.output)
    readonly property var windows: NihilState.windowsOn(bar.workspaces[bar.at]?.id)
    readonly property real key: NihilStyle.barThickness - NihilStyle.s(12)
    // What the pointer rests on: { text, item }, shown by the stage as a hint beside the bar.
    property var hint: null
    readonly property alias glass: body
    // In the overview the bar may drop its glass and keep only its keys.
    property bool clear: false

    function tell(item: var, text: string, on: bool): void {
        if (on) bar.hint = { text, item }
        else if (bar.hint?.item === item) bar.hint = null
    }

    NGlass {
        id: body
        anchors.fill: parent
        radius: NihilStyle.barFloats ? Math.min(NihilStyle.r(26), NihilStyle.barThickness / 2) : 0
        shadow: NihilStyle.barFloats ? 1 : 0
        followPointer: true
        opacity: bar.clear ? 0 : 1
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: NihilStyle.durationMedium } }
    }

    // A round key, the way visionOS draws them: quiet glass, a brighter plate under the pointer, solid light when on.
    component BarKey: MouseArea {
        id: k
        property string glyph: ""
        property string name: ""
        property bool highlighted: false
        readonly property color foreground: k.highlighted ? NihilStyle.accentText : NihilStyle.text
        default property alias inner: holder.data
        Layout.alignment: Qt.AlignCenter
        implicitWidth: bar.key
        implicitHeight: bar.key
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        Accessible.role: Accessible.Button
        Accessible.name: k.name
        onContainsMouseChanged: bar.tell(k, k.name, k.containsMouse)
        Rectangle {
            anchors.fill: parent
            radius: Math.min(width, height) / 2
            color: k.highlighted ? NihilStyle.accent : k.pressed ? NihilStyle.fillPressed : k.containsMouse ? NihilStyle.fillHover : "transparent"
            scale: k.pressed ? 0.94 : 1
            Behavior on color { ColorAnimation { duration: NihilStyle.durationShort } }
            Behavior on scale { NumberAnimation { duration: NihilStyle.durationShort; easing.type: Easing.OutCubic } }
        }
        NIcon {
            anchors.centerIn: parent
            visible: k.glyph.length > 0
            text: k.glyph
            size: NihilStyle.s(19)
            color: k.foreground
        }
        Item { id: holder; anchors.fill: parent }
    }

    // A hairline that parts the bar's groups.
    component Parting: Rectangle {
        Layout.alignment: Qt.AlignCenter
        implicitWidth: bar.vertical ? NihilStyle.s(18) : 1
        implicitHeight: bar.vertical ? 1 : NihilStyle.s(18)
        color: NihilStyle.border
    }

    GridLayout {
        id: column
        anchors.fill: parent
        anchors.margins: NihilStyle.s(6)
        flow: bar.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: bar.vertical ? -1 : 1
        columns: bar.vertical ? 1 : -1
        rowSpacing: NihilStyle.s(4)
        columnSpacing: NihilStyle.s(4)

        BarKey {
            id: lead
            name: Translation.tr("Apps and search")
            highlighted: NihilState.dashboardOpen && NihilState.askedOn === bar.output
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) NihilState.toggleOverview("windows")
                else if (NihilState.dashboardOpen) NihilState.dismiss()
                else { NihilState.askedOn = bar.output; NihilState.show(NihilState.lastPage) }
            }
            NLogo {
                anchors.centerIn: parent
                size: NihilStyle.s(22)
            }
        }

        Parting {}

        // The workspaces: the one on show is a long light, those holding windows a dot, the empty ones a faint one.
        GridLayout {
            id: spaces
            Layout.alignment: Qt.AlignCenter
            flow: column.flow
            rows: column.rows
            columns: column.columns
            rowSpacing: 0
            columnSpacing: 0
            Repeater {
                model: bar.workspaces
                MouseArea {
                    id: space
                    required property var modelData
                    required property int index
                    readonly property bool active: space.index === bar.at
                    readonly property int count: NihilState.windowsOn(space.modelData.id).length
                    Layout.alignment: Qt.AlignCenter
                    implicitWidth: bar.vertical ? bar.key : (space.active ? NihilStyle.s(40) : NihilStyle.s(18))
                    implicitHeight: bar.vertical ? (space.active ? NihilStyle.s(40) : NihilStyle.s(18)) : bar.key
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: Translation.tr("Workspace %1").arg(space.index + 1)
                    onContainsMouseChanged: bar.tell(space, space.count > 0
                        ? Translation.tr("Workspace %1 · %2 windows").arg(space.index + 1).arg(space.count)
                        : Translation.tr("Workspace %1").arg(space.index + 1), space.containsMouse)
                    onClicked: NiriService.switchToWorkspaceById(space.modelData.id)
                    Behavior on implicitHeight { NumberAnimation { duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic } }
                    Behavior on implicitWidth { NumberAnimation { duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic } }
                    Rectangle {
                        anchors.centerIn: parent
                        readonly property real thin: space.active ? NihilStyle.s(6) : space.containsMouse ? NihilStyle.s(8) : space.count > 0 ? NihilStyle.s(6) : NihilStyle.s(5)
                        readonly property real long_: space.active ? NihilStyle.s(28) : thin
                        width: bar.vertical ? thin : long_
                        height: bar.vertical ? long_ : thin
                        radius: Math.min(width, height) / 2
                        color: space.active ? NihilStyle.accent : Qt.alpha(NihilStyle.text, space.containsMouse ? 0.9 : space.count > 0 ? 0.66 : 0.26)
                        Behavior on width { NumberAnimation { duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: NihilStyle.durationShort } }
                    }
                }
            }
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => NihilState.stepWorkspace(bar.output, event.angleDelta.y > 0 ? -1 : 1)
            }
        }

        // The windows of the workspace on show: the one with the keys sits on a plate, marked on the bar's outer side.
        GridLayout {
            Layout.alignment: Qt.AlignCenter
            visible: (bar.panel?.windows ?? true) && bar.windows.length > 0
            flow: column.flow
            rows: column.rows
            columns: column.columns
            rowSpacing: NihilStyle.s(2)
            columnSpacing: NihilStyle.s(2)
            Parting { Layout.margins: NihilStyle.s(4) }
            Repeater {
                model: bar.windows.slice(0, bar.panel?.windowsMax ?? 8)
                BarKey {
                    id: win
                    required property var modelData
                    name: (AppSearch.lookupDesktopEntry(win.modelData.app_id ?? "")?.name ?? String(win.modelData.app_id ?? ""))
                        + (String(win.modelData.title ?? "").length > 0 ? " · " + win.modelData.title : "")
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) NiriService.closeWindow(win.modelData.id)
                        else if (mouse.button === Qt.RightButton) NihilState.windowAction("minimize", win.modelData)
                        else NiriService.focusWindow(win.modelData.id)
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: win.modelData.is_focused ? NihilStyle.fillHover : "transparent"
                    }
                    NAppIcon {
                        anchors.centerIn: parent
                        appId: win.modelData.app_id ?? ""
                        size: NihilStyle.s(24)
                        opacity: win.modelData.is_focused || win.containsMouse ? 1 : 0.72
                    }
                    // The mark on the outer side of the bar.
                    Rectangle {
                        visible: win.modelData.is_focused
                        width: bar.vertical ? NihilStyle.s(3) : NihilStyle.s(14)
                        height: bar.vertical ? NihilStyle.s(14) : NihilStyle.s(3)
                        radius: NihilStyle.s(2)
                        color: NihilStyle.accent
                        x: bar.vertical ? (bar.edge === "left" ? -NihilStyle.s(6) : parent.width + NihilStyle.s(3)) : (parent.width - width) / 2
                        y: bar.vertical ? (parent.height - height) / 2 : (bar.edge === "top" ? -NihilStyle.s(6) : parent.height + NihilStyle.s(3))
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: !bar.vertical
            Layout.fillHeight: bar.vertical
        }

        // The tray: left opens the app (or its menu when that is all it has), middle its second action, right its menu.
        GridLayout {
            Layout.alignment: Qt.AlignCenter
            visible: bar.panel?.tray ?? true
            flow: column.flow
            rows: column.rows
            columns: column.columns
            rowSpacing: 0
            columnSpacing: 0
            Repeater {
                model: [...TrayService.pinnedItems, ...TrayService.unpinnedItems]
                BarKey {
                    id: trayItem
                    required property var modelData
                    implicitHeight: bar.vertical ? NihilStyle.s(32) : bar.key
                    implicitWidth: bar.vertical ? bar.key : NihilStyle.s(32)
                    name: trayItem.modelData?.tooltipTitle || trayItem.modelData?.title || trayItem.modelData?.id || ""
                    highlighted: false
                    function openMenu(): void {
                        const at = trayItem.mapToItem(null, trayItem.width / 2, trayItem.height / 2)
                        trayMenu.show(trayItem.modelData, bar.screen, Qt.point(at.x, at.y), bar.edge)
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
                        opacity: trayItem.containsMouse || trayMenu.item === trayItem.modelData ? 1 : 0.66
                        Behavior on opacity { NumberAnimation { duration: NihilStyle.durationShort } }
                    }
                    Rectangle {
                        visible: trayItem.modelData?.status === Status.NeedsAttention
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: NihilStyle.s(5)
                        width: NihilStyle.s(5)
                        height: width
                        radius: width / 2
                        color: NihilStyle.accent
                    }
                }
            }
        }

        // The machine: network, Bluetooth, sound and battery in one key that opens Control; the wheel sets the volume.
        BarKey {
            id: status
            name: Translation.tr("Control")
            highlighted: NihilState.controlOpen
            implicitWidth: bar.vertical ? bar.key : machine.implicitWidth + NihilStyle.s(20)
            implicitHeight: bar.vertical ? machine.implicitHeight + NihilStyle.s(20) : bar.key
            onClicked: NihilState.toggleOn("control", bar.output)
            onWheel: wheel => {
                const sink = Audio.sink?.audio
                if (sink) sink.volume = NihilStyle.clamp(sink.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05), 0, 1)
            }
            GridLayout {
                id: machine
                anchors.centerIn: parent
                flow: column.flow
                rows: column.rows
                columns: column.columns
                rowSpacing: NihilStyle.s(9)
                columnSpacing: NihilStyle.s(10)
                NIcon {
                    Layout.alignment: Qt.AlignCenter
                    text: Network.ethernet ? "lan" : Network.wifiEnabled ? "wifi" : "wifi_off"
                    size: NihilStyle.s(17)
                    color: status.foreground
                }
                NIcon {
                    Layout.alignment: Qt.AlignCenter
                    visible: Bluetooth.defaultAdapter?.enabled ?? false
                    text: BluetoothStatus.connected ? "bluetooth_connected" : "bluetooth"
                    size: NihilStyle.s(17)
                    color: status.foreground
                }
                NIcon {
                    Layout.alignment: Qt.AlignCenter
                    text: (Audio.sink?.audio?.muted ?? false) ? "volume_mute" : "volume_up"
                    size: NihilStyle.s(17)
                    color: status.foreground
                }
                NIcon {
                    Layout.alignment: Qt.AlignCenter
                    visible: Battery.available
                    readonly property int step: Math.min(6, Math.floor(Battery.percentage * 7))
                    text: Battery.isCharging ? "battery_charging_full" : Battery.percentage > 0.95 ? "battery_full" : "battery_" + step + "_bar"
                    size: NihilStyle.s(17)
                    color: Battery.isLowAndNotCharging && !status.highlighted ? NihilStyle.danger : status.foreground
                }
            }
        }

        // The time: hours over minutes on a vertical bar, one line on a horizontal one. Opens Today; a light marks
        // notifications waiting.
        BarKey {
            id: clock
            name: DateTime.date
            highlighted: NihilState.todayOpen
            implicitWidth: bar.vertical ? bar.key : time.implicitWidth + NihilStyle.s(24)
            implicitHeight: bar.vertical ? time.implicitHeight + NihilStyle.s(18) : bar.key
            onClicked: NihilState.toggleOn("today", bar.output)
            readonly property var parts: String(DateTime.time).split(":")
            Column {
                id: time
                anchors.centerIn: parent
                visible: bar.vertical
                spacing: -NihilStyle.s(2)
                NText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: clock.parts[0] ?? ""
                    figures: true
                    font.pixelSize: NihilStyle.s(16)
                    font.weight: Font.DemiBold
                    color: clock.foreground
                }
                NText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: String(clock.parts.slice(1).join(":")).replace(/\s.*$/, "")
                    figures: true
                    font.pixelSize: NihilStyle.s(16)
                    font.weight: Font.Light
                    color: clock.highlighted ? clock.foreground : NihilStyle.textSecondary
                }
            }
            Row {
                anchors.centerIn: parent
                visible: !bar.vertical
                spacing: NihilStyle.s(8)
                NText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: DateTime.date
                    color: clock.highlighted ? clock.foreground : NihilStyle.textSecondary
                }
                NText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: DateTime.time
                    figures: true
                    font.pixelSize: NihilStyle.s(16)
                    font.weight: Font.DemiBold
                    color: clock.foreground
                }
            }
            Rectangle {
                visible: Notifications.list.length > 0
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: NihilStyle.s(3)
                width: NihilStyle.s(6)
                height: width
                radius: width / 2
                color: clock.highlighted ? NihilStyle.accentText : NihilStyle.accent
            }
        }

        BarKey {
            glyph: "power"
            name: Translation.tr("Power")
            highlighted: NihilState.powerOpen
            onClicked: { NihilState.askedOn = bar.output; NihilState.toggle("power") }
        }
    }

    NihilTrayMenu { id: trayMenu }
}
