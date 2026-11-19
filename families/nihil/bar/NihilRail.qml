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

// The rail: NiHiL's panel, an ornament of glass standing beside the desktop like the tab bar beside a visionOS window.
// From its start: the mark (the deck), the workspaces as a column of lights with the windows of the one on show, then,
// from its end, the tray, the machine, the time and the way out. Every key names itself in a hint beside the rail.
Item {
    id: rail

    required property string output
    required property var screen

    readonly property var panel: Config.options?.nihil?.panel
    readonly property bool vertical: NihilStyle.railVertical
    readonly property string edge: NihilStyle.railEdge
    readonly property var workspaces: NihilState.workspacesOn(rail.output)
    readonly property int at: NihilState.activeIndexOn(rail.output)
    readonly property var windows: NihilState.windowsOn(rail.workspaces[rail.at]?.id)
    readonly property real key: NihilStyle.railThickness - NihilStyle.s(12)
    // What the pointer rests on: { text, item }, shown by the stage as a hint beside the rail.
    property var hint: null
    readonly property alias glass: body
    // In the overview the rail may drop its glass and keep only its keys.
    property bool clear: false

    function tell(item: var, text: string, on: bool): void {
        if (on) rail.hint = { text, item }
        else if (rail.hint?.item === item) rail.hint = null
    }

    NGlass {
        id: body
        anchors.fill: parent
        radius: NihilStyle.railFloats ? Math.min(NihilStyle.r(26), NihilStyle.railThickness / 2) : 0
        shadow: NihilStyle.railFloats ? 1 : 0
        tracks: true
        opacity: rail.clear ? 0 : 1
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: NihilStyle.calm } }
    }

    // A round key, the way visionOS draws them: quiet glass, a brighter plate under the pointer, solid light when on.
    component RailKey: MouseArea {
        id: k
        property string glyph: ""
        property string name: ""
        property bool lit: false
        readonly property color ink: k.lit ? NihilStyle.accentInk : NihilStyle.ink
        default property alias inner: holder.data
        Layout.alignment: Qt.AlignCenter
        implicitWidth: rail.key
        implicitHeight: rail.key
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        Accessible.role: Accessible.Button
        Accessible.name: k.name
        onContainsMouseChanged: rail.tell(k, k.name, k.containsMouse)
        Rectangle {
            anchors.fill: parent
            radius: Math.min(width, height) / 2
            color: k.lit ? NihilStyle.accent : k.pressed ? NihilStyle.chosen : k.containsMouse ? NihilStyle.pieceRaised : "transparent"
            scale: k.pressed ? 0.94 : 1
            Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
            Behavior on scale { NumberAnimation { duration: NihilStyle.quick; easing.type: Easing.OutCubic } }
        }
        NIcon {
            anchors.centerIn: parent
            visible: k.glyph.length > 0
            text: k.glyph
            size: NihilStyle.s(19)
            color: k.ink
        }
        Item { id: holder; anchors.fill: parent }
    }

    // A hairline that parts the rail's groups.
    component Parting: Rectangle {
        Layout.alignment: Qt.AlignCenter
        implicitWidth: rail.vertical ? NihilStyle.s(18) : 1
        implicitHeight: rail.vertical ? 1 : NihilStyle.s(18)
        color: NihilStyle.hair
    }

    GridLayout {
        id: column
        anchors.fill: parent
        anchors.margins: NihilStyle.s(6)
        flow: rail.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: rail.vertical ? -1 : 1
        columns: rail.vertical ? 1 : -1
        rowSpacing: NihilStyle.s(4)
        columnSpacing: NihilStyle.s(4)

        RailKey {
            id: lead
            name: Translation.tr("Apps and search")
            lit: NihilState.deckOpen && NihilState.askedOn === rail.output
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) NihilState.toggleOverview("windows")
                else if (NihilState.deckOpen) NihilState.dismiss()
                else { NihilState.askedOn = rail.output; NihilState.show(NihilState.lastPage) }
            }
            NMark {
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
                model: rail.workspaces
                MouseArea {
                    id: space
                    required property var modelData
                    required property int index
                    readonly property bool active: space.index === rail.at
                    readonly property int count: NihilState.windowsOn(space.modelData.id).length
                    Layout.alignment: Qt.AlignCenter
                    implicitWidth: rail.vertical ? rail.key : (space.active ? NihilStyle.s(40) : NihilStyle.s(18))
                    implicitHeight: rail.vertical ? (space.active ? NihilStyle.s(40) : NihilStyle.s(18)) : rail.key
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: Translation.tr("Workspace %1").arg(space.index + 1)
                    onContainsMouseChanged: rail.tell(space, space.count > 0
                        ? Translation.tr("Workspace %1 · %2 windows").arg(space.index + 1).arg(space.count)
                        : Translation.tr("Workspace %1").arg(space.index + 1), space.containsMouse)
                    onClicked: NiriService.switchToWorkspaceById(space.modelData.id)
                    Behavior on implicitHeight { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
                    Behavior on implicitWidth { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
                    Rectangle {
                        anchors.centerIn: parent
                        readonly property real thin: space.active ? NihilStyle.s(6) : space.containsMouse ? NihilStyle.s(8) : space.count > 0 ? NihilStyle.s(6) : NihilStyle.s(5)
                        readonly property real long_: space.active ? NihilStyle.s(28) : thin
                        width: rail.vertical ? thin : long_
                        height: rail.vertical ? long_ : thin
                        radius: Math.min(width, height) / 2
                        color: space.active ? NihilStyle.accent : Qt.alpha(NihilStyle.ink, space.containsMouse ? 0.9 : space.count > 0 ? 0.66 : 0.26)
                        Behavior on width { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
                    }
                }
            }
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => NihilState.stepWorkspace(rail.output, event.angleDelta.y > 0 ? -1 : 1)
            }
        }

        // The windows of the workspace on show: the one with the keys sits on a plate, marked on the rail's outer side.
        GridLayout {
            Layout.alignment: Qt.AlignCenter
            visible: (rail.panel?.windows ?? true) && rail.windows.length > 0
            flow: column.flow
            rows: column.rows
            columns: column.columns
            rowSpacing: NihilStyle.s(2)
            columnSpacing: NihilStyle.s(2)
            Parting { Layout.margins: NihilStyle.s(4) }
            Repeater {
                model: rail.windows.slice(0, rail.panel?.windowsMax ?? 8)
                RailKey {
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
                        color: win.modelData.is_focused ? NihilStyle.pieceRaised : "transparent"
                    }
                    NAppIcon {
                        anchors.centerIn: parent
                        appId: win.modelData.app_id ?? ""
                        size: NihilStyle.s(24)
                        opacity: win.modelData.is_focused || win.containsMouse ? 1 : 0.72
                    }
                    // The mark on the outer side of the rail.
                    Rectangle {
                        visible: win.modelData.is_focused
                        width: rail.vertical ? NihilStyle.s(3) : NihilStyle.s(14)
                        height: rail.vertical ? NihilStyle.s(14) : NihilStyle.s(3)
                        radius: NihilStyle.s(2)
                        color: NihilStyle.accent
                        x: rail.vertical ? (rail.edge === "left" ? -NihilStyle.s(6) : parent.width + NihilStyle.s(3)) : (parent.width - width) / 2
                        y: rail.vertical ? (parent.height - height) / 2 : (rail.edge === "top" ? -NihilStyle.s(6) : parent.height + NihilStyle.s(3))
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: !rail.vertical
            Layout.fillHeight: rail.vertical
        }

        // The tray: left opens the app (or its menu when that is all it has), middle its second action, right its menu.
        GridLayout {
            Layout.alignment: Qt.AlignCenter
            visible: rail.panel?.tray ?? true
            flow: column.flow
            rows: column.rows
            columns: column.columns
            rowSpacing: 0
            columnSpacing: 0
            Repeater {
                model: [...TrayService.pinnedItems, ...TrayService.unpinnedItems]
                RailKey {
                    id: trayItem
                    required property var modelData
                    implicitHeight: rail.vertical ? NihilStyle.s(32) : rail.key
                    implicitWidth: rail.vertical ? rail.key : NihilStyle.s(32)
                    name: trayItem.modelData?.tooltipTitle || trayItem.modelData?.title || trayItem.modelData?.id || ""
                    lit: false
                    function openMenu(): void {
                        const at = trayItem.mapToItem(null, trayItem.width / 2, trayItem.height / 2)
                        trayMenu.show(trayItem.modelData, rail.screen, Qt.point(at.x, at.y), rail.edge)
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
                        Behavior on opacity { NumberAnimation { duration: NihilStyle.quick } }
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
        RailKey {
            id: status
            name: Translation.tr("Control")
            lit: NihilState.controlOpen
            implicitWidth: rail.vertical ? rail.key : machine.implicitWidth + NihilStyle.s(20)
            implicitHeight: rail.vertical ? machine.implicitHeight + NihilStyle.s(20) : rail.key
            onClicked: NihilState.toggleOn("control", rail.output)
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
                    color: status.ink
                }
                NIcon {
                    Layout.alignment: Qt.AlignCenter
                    visible: Bluetooth.defaultAdapter?.enabled ?? false
                    text: BluetoothStatus.connected ? "bluetooth_connected" : "bluetooth"
                    size: NihilStyle.s(17)
                    color: status.ink
                }
                NIcon {
                    Layout.alignment: Qt.AlignCenter
                    text: (Audio.sink?.audio?.muted ?? false) ? "volume_mute" : "volume_up"
                    size: NihilStyle.s(17)
                    color: status.ink
                }
                NIcon {
                    Layout.alignment: Qt.AlignCenter
                    visible: Battery.available
                    readonly property int step: Math.min(6, Math.floor(Battery.percentage * 7))
                    text: Battery.isCharging ? "battery_charging_full" : Battery.percentage > 0.95 ? "battery_full" : "battery_" + step + "_bar"
                    size: NihilStyle.s(17)
                    color: Battery.isLowAndNotCharging && !status.lit ? NihilStyle.danger : status.ink
                }
            }
        }

        // The time: hours over minutes on a vertical rail, one line on a horizontal one. Opens Today; a light marks
        // notifications waiting.
        RailKey {
            id: clock
            name: DateTime.date
            lit: NihilState.todayOpen
            implicitWidth: rail.vertical ? rail.key : time.implicitWidth + NihilStyle.s(24)
            implicitHeight: rail.vertical ? time.implicitHeight + NihilStyle.s(18) : rail.key
            onClicked: NihilState.toggleOn("today", rail.output)
            readonly property var parts: String(DateTime.time).split(":")
            Column {
                id: time
                anchors.centerIn: parent
                visible: rail.vertical
                spacing: -NihilStyle.s(2)
                NText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: clock.parts[0] ?? ""
                    figures: true
                    font.pixelSize: NihilStyle.s(16)
                    font.weight: Font.DemiBold
                    color: clock.ink
                }
                NText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: String(clock.parts.slice(1).join(":")).replace(/\s.*$/, "")
                    figures: true
                    font.pixelSize: NihilStyle.s(16)
                    font.weight: Font.Light
                    color: clock.lit ? clock.ink : NihilStyle.inkSoft
                }
            }
            Row {
                anchors.centerIn: parent
                visible: !rail.vertical
                spacing: NihilStyle.s(8)
                NText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: DateTime.date
                    color: clock.lit ? clock.ink : NihilStyle.inkSoft
                }
                NText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: DateTime.time
                    figures: true
                    font.pixelSize: NihilStyle.s(16)
                    font.weight: Font.DemiBold
                    color: clock.ink
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
                color: clock.lit ? NihilStyle.accentInk : NihilStyle.accent
            }
        }

        RailKey {
            glyph: "power"
            name: Translation.tr("Power")
            lit: NihilState.powerOpen
            onClicked: { NihilState.askedOn = rail.output; NihilState.toggle("power") }
        }
    }

    NihilTrayMenu { id: trayMenu }
}
