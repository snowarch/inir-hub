pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Bluetooth
import Quickshell.Widgets
import qs
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// The bar: a strip of glass along one edge in three zones (start, centre, end). Each part (NiHiL's key, the
// workspaces, the windows, what plays, the tray, the status, the clock and the power key) stands in the zone Settings
// gives it, or nowhere. The zones never overlap: the windows give up room first, and the tray keeps a few icons out
// and shows the rest behind one key.
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
    readonly property real gap: NihilStyle.s(10)
    // What the pointer rests on: { text, item }, shown by the stage as a hint beside the bar.
    property var hint: null
    readonly property alias glass: body
    // In the overview the bar may drop its glass and keep only its keys.
    property bool clear: false

    // The parts in their order along the bar, and the zone each one stands in.
    readonly property var order: ["logo", "workspaces", "windows", "media", "tray", "status", "clock", "power"]
    readonly property var factory: ({ logo: "start", workspaces: "start", windows: "start", media: "center",
                                      tray: "end", status: "end", clock: "end", power: "end" })
    function placeOf(part: string): string {
        const asked = String(bar.panel?.parts?.[part] ?? bar.factory[part])
        return ["start", "center", "end"].includes(asked) ? asked : "off"
    }
    function partsIn(zone: string): var { return bar.order.filter(part => bar.placeOf(part) === zone) }
    readonly property var startParts: bar.partsIn("start")
    readonly property var centerParts: bar.partsIn("center")
    readonly property var endParts: bar.partsIn("end")

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

    // A round key: quiet glass, a brighter plate under the pointer, solid accent when on.
    component BarKey: MouseArea {
        id: k
        property string glyph: ""
        property string name: ""
        property bool highlighted: false
        readonly property color foreground: k.highlighted ? NihilStyle.accentText : NihilStyle.text
        default property alias inner: holder.data
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

    // A hairline that parts two groups.
    component Parting: Rectangle {
        implicitWidth: bar.vertical ? NihilStyle.s(18) : 1
        implicitHeight: bar.vertical ? 1 : NihilStyle.s(18)
        color: NihilStyle.border
    }

    // One zone: its parts packed towards its own end of the bar.
    component Zone: GridLayout {
        id: zone
        property var parts: []
        property bool packEnd: false
        flow: bar.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: bar.vertical ? -1 : 1
        columns: bar.vertical ? 1 : -1
        rowSpacing: NihilStyle.s(4)
        columnSpacing: NihilStyle.s(4)
        Item { visible: zone.packEnd; Layout.fillWidth: !bar.vertical; Layout.fillHeight: bar.vertical }
        Repeater {
            model: zone.parts
            Loader {
                id: slot
                required property string modelData
                readonly property bool windowsPart: slot.modelData === "windows"
                Layout.alignment: Qt.AlignCenter
                // The windows take what room is left and no more than they need.
                Layout.fillWidth: slot.windowsPart && !bar.vertical
                Layout.fillHeight: slot.windowsPart && bar.vertical
                Layout.minimumWidth: slot.windowsPart && !bar.vertical ? 0 : -1
                Layout.minimumHeight: slot.windowsPart && bar.vertical ? 0 : -1
                Layout.maximumWidth: slot.windowsPart && !bar.vertical ? slot.implicitWidth : Number.POSITIVE_INFINITY
                Layout.maximumHeight: slot.windowsPart && bar.vertical ? slot.implicitHeight : Number.POSITIVE_INFINITY
                visible: slot.modelData !== "media" || !!MprisController.activePlayer
                sourceComponent: ({ logo: logoPart, workspaces: workspacesPart, windows: windowsPart, media: mediaPart,
                                    tray: trayPart, status: statusPart, clock: clockPart, power: powerPart })[slot.modelData] ?? null
            }
        }
        Item { visible: !zone.packEnd; Layout.fillWidth: !bar.vertical; Layout.fillHeight: bar.vertical }
    }

    Item {
        id: track
        anchors.fill: parent
        anchors.margins: NihilStyle.s(6)
        readonly property real length: bar.vertical ? track.height : track.width
        readonly property real centerLength: bar.centerParts.length === 0 ? 0
            : bar.vertical ? center.implicitHeight : center.implicitWidth
        // Each side zone keeps clear of the centre; without one, the zone holding the windows takes what the other leaves.
        readonly property real half: (track.length - track.centerLength) / 2 - bar.gap
        readonly property bool windowsAtEnd: bar.placeOf("windows") === "end"
        readonly property real startLength: bar.centerParts.length > 0 ? track.half
            : track.windowsAtEnd ? (bar.vertical ? start.implicitHeight : start.implicitWidth)
            : track.length - (bar.vertical ? end.implicitHeight : end.implicitWidth) - bar.gap
        readonly property real endLength: bar.centerParts.length > 0 ? track.half
            : track.windowsAtEnd ? track.length - track.startLength - bar.gap
            : (bar.vertical ? end.implicitHeight : end.implicitWidth)

        Zone {
            id: start
            parts: bar.startParts
            width: bar.vertical ? track.width : Math.max(0, track.startLength)
            height: bar.vertical ? Math.max(0, track.startLength) : track.height
        }
        Zone {
            id: center
            parts: bar.centerParts
            visible: bar.centerParts.length > 0
            anchors.centerIn: parent
            width: bar.vertical ? track.width : implicitWidth
            height: bar.vertical ? implicitHeight : track.height
        }
        Zone {
            id: end
            parts: bar.endParts
            packEnd: true
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: bar.vertical ? track.width : Math.max(0, track.endLength)
            height: bar.vertical ? Math.max(0, track.endLength) : track.height
        }
    }

    Component {
        id: logoPart
        BarKey {
            name: Translation.tr("Dashboard")
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
    }

    // The workspaces: as dots (the one on show a long light, those holding windows brighter) or as numbers.
    Component {
        id: workspacesPart
        GridLayout {
            id: spaces
            readonly property bool numbers: (bar.panel?.workspaceStyle ?? "dots") === "numbers"
            flow: bar.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
            rows: bar.vertical ? -1 : 1
            columns: bar.vertical ? 1 : -1
            rowSpacing: spaces.numbers ? NihilStyle.s(2) : 0
            columnSpacing: spaces.numbers ? NihilStyle.s(2) : 0
            Repeater {
                model: bar.workspaces
                MouseArea {
                    id: space
                    required property var modelData
                    required property int index
                    readonly property bool active: space.index === bar.at
                    readonly property int count: NihilState.windowsOn(space.modelData.id).length
                    readonly property real across: spaces.numbers ? NihilStyle.s(30) : space.active ? NihilStyle.s(40) : NihilStyle.s(18)
                    Layout.alignment: Qt.AlignCenter
                    implicitWidth: bar.vertical ? bar.key : space.across
                    implicitHeight: bar.vertical ? space.across : bar.key
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
                        readonly property real thin: spaces.numbers ? NihilStyle.s(26)
                            : space.active ? NihilStyle.s(6) : space.containsMouse ? NihilStyle.s(8) : space.count > 0 ? NihilStyle.s(6) : NihilStyle.s(5)
                        readonly property real long_: spaces.numbers ? NihilStyle.s(26) : space.active ? NihilStyle.s(28) : thin
                        width: bar.vertical ? thin : long_
                        height: bar.vertical ? long_ : thin
                        radius: Math.min(width, height) / 2
                        color: space.active ? NihilStyle.accent
                            : spaces.numbers ? (space.containsMouse ? NihilStyle.fillHover : "transparent")
                            : Qt.alpha(NihilStyle.text, space.containsMouse ? 0.9 : space.count > 0 ? 0.66 : 0.26)
                        Behavior on width { NumberAnimation { duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: NihilStyle.durationShort } }
                        NText {
                            anchors.centerIn: parent
                            visible: spaces.numbers
                            text: String(space.index + 1)
                            figures: true
                            font.pixelSize: NihilStyle.textSmall
                            font.weight: space.active ? Font.DemiBold : Font.Medium
                            color: space.active ? NihilStyle.accentText : space.count > 0 ? NihilStyle.text : NihilStyle.textTertiary
                        }
                    }
                }
            }
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => NihilState.stepWorkspace(bar.output, event.angleDelta.y > 0 ? -1 : 1)
            }
        }
    }

    // The windows of the workspace on show, as many as fit: the focused one sits on a plate, marked on the outer side.
    Component {
        id: windowsPart
        Item {
            id: list
            readonly property real step: bar.key + NihilStyle.s(2)
            readonly property real lead: NihilStyle.s(10)
            readonly property int wanted: Math.min(bar.windows.length, bar.panel?.windowsMax ?? 8)
            readonly property real room: bar.vertical ? list.height : list.width
            readonly property int fits: Math.max(0, Math.min(list.wanted, Math.floor((list.room - list.lead) / list.step)))
            visible: list.wanted > 0
            implicitWidth: bar.vertical ? bar.key : list.lead + list.wanted * list.step
            implicitHeight: bar.vertical ? list.lead + list.wanted * list.step : bar.key
            Parting {
                x: bar.vertical ? (parent.width - width) / 2 : NihilStyle.s(4)
                y: bar.vertical ? NihilStyle.s(4) : (parent.height - height) / 2
            }
            Grid {
                x: bar.vertical ? 0 : list.lead
                y: bar.vertical ? list.lead : 0
                rows: bar.vertical ? -1 : 1
                columns: bar.vertical ? 1 : -1
                spacing: NihilStyle.s(2)
                Repeater {
                    model: bar.windows.slice(0, list.fits)
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
                        Rectangle {
                            visible: win.modelData.is_focused
                            width: bar.vertical ? NihilStyle.s(3) : NihilStyle.s(14)
                            height: bar.vertical ? NihilStyle.s(14) : NihilStyle.s(3)
                            radius: NihilStyle.s(2)
                            color: NihilStyle.accent
                            // On the plate's side towards the screen's edge.
                            x: bar.vertical ? (bar.edge === "left" ? NihilStyle.s(1) : parent.width - width - NihilStyle.s(1)) : (parent.width - width) / 2
                            y: bar.vertical ? (parent.height - height) / 2 : (bar.edge === "top" ? NihilStyle.s(1) : parent.height - height - NihilStyle.s(1))
                        }
                    }
                }
            }
        }
    }

    // What plays: its cover and title on a horizontal bar, the cover alone on a vertical one. Click opens Media, the
    // middle button plays or pauses, the right one skips; the wheel sets the volume.
    Component {
        id: mediaPart
        BarKey {
            id: media
            readonly property var player: MprisController.activePlayer
            readonly property string title: MprisController.titleOf(media.player) || (media.player?.identity ?? "")
            readonly property string artist: MprisController.artistOf(media.player)
            readonly property string art: MprisController.artUrlOf(media.player) || (media.player?.trackArtUrl ?? "")
            name: media.artist.length > 0 ? media.title + " · " + media.artist : media.title
            highlighted: NihilState.mediaOpen
            implicitWidth: bar.vertical ? bar.key : Math.min(NihilStyle.s(300), line.implicitWidth + NihilStyle.s(16))
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) media.player?.togglePlaying()
                else if (mouse.button === Qt.RightButton) media.player?.next()
                else NihilState.toggleOn("media", bar.output)
            }
            onWheel: wheel => {
                const sink = Audio.sink?.audio
                if (sink) sink.volume = NihilStyle.clamp(sink.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05), 0, 1)
            }
            Row {
                id: line
                anchors.verticalCenter: parent.verticalCenter
                x: bar.vertical ? (parent.width - cover.width) / 2 : NihilStyle.s(6)
                spacing: NihilStyle.s(9)
                ClippingRectangle {
                    id: cover
                    width: bar.key - NihilStyle.s(10)
                    height: width
                    radius: width / 2
                    color: media.highlighted ? Qt.alpha(NihilStyle.accentText, 0.15) : NihilStyle.fillHover
                    NIcon {
                        anchors.centerIn: parent
                        visible: coverArt.status !== Image.Ready
                        text: media.player?.isPlaying ? "music" : "pause"
                        size: NihilStyle.s(14)
                        color: media.foreground
                    }
                    Image {
                        id: coverArt
                        anchors.fill: parent
                        source: media.art
                        sourceSize: Qt.size(width * 2, height * 2)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: media.player?.isPlaying ? 1 : 0.5
                    }
                }
                NText {
                    visible: !bar.vertical
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, NihilStyle.s(240))
                    text: media.title
                    font.weight: Font.Medium
                    color: media.foreground
                }
            }
        }
    }

    // The tray, a few icons on the bar and the rest behind one key: left opens the app (or its menu when that is all it
    // has), middle its second action, right its menu.
    Component {
        id: trayPart
        GridLayout {
            id: tray
            readonly property var items: [...TrayService.pinnedItems, ...TrayService.unpinnedItems]
            readonly property int most: Math.max(1, bar.panel?.trayMax ?? 6)
            readonly property bool crowded: tray.items.length > tray.most
            property bool spread: false
            flow: bar.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
            rows: bar.vertical ? -1 : 1
            columns: bar.vertical ? 1 : -1
            rowSpacing: 0
            columnSpacing: 0
            visible: tray.items.length > 0
            Repeater {
                model: tray.spread || !tray.crowded ? tray.items : tray.items.slice(0, tray.most - 1)
                BarKey {
                    id: trayItem
                    required property var modelData
                    Layout.alignment: Qt.AlignCenter
                    implicitHeight: bar.vertical ? NihilStyle.s(32) : bar.key
                    implicitWidth: bar.vertical ? bar.key : NihilStyle.s(32)
                    name: trayItem.modelData?.tooltipTitle || trayItem.modelData?.title || trayItem.modelData?.id || ""
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
            BarKey {
                visible: tray.crowded
                Layout.alignment: Qt.AlignCenter
                implicitHeight: bar.vertical ? NihilStyle.s(32) : bar.key
                implicitWidth: bar.vertical ? bar.key : NihilStyle.s(32)
                glyph: tray.spread ? "close" : "more_horiz"
                name: tray.spread ? Translation.tr("Fewer") : Translation.tr("%1 more").arg(tray.items.length - tray.most + 1)
                onClicked: tray.spread = !tray.spread
            }
        }
    }

    // The status: network, Bluetooth, sound and battery in one key that opens Control; the wheel sets the volume.
    Component {
        id: statusPart
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
            Grid {
                id: machine
                anchors.centerIn: parent
                rows: bar.vertical ? -1 : 1
                columns: bar.vertical ? 1 : -1
                spacing: NihilStyle.s(9)
                NIcon {
                    text: Network.ethernet ? "lan" : Network.wifiEnabled ? "wifi" : "wifi_off"
                    size: NihilStyle.s(17)
                    color: status.foreground
                }
                NIcon {
                    visible: Bluetooth.defaultAdapter?.enabled ?? false
                    text: BluetoothStatus.connected ? "bluetooth_connected" : "bluetooth"
                    size: NihilStyle.s(17)
                    color: status.foreground
                }
                NIcon {
                    text: (Audio.sink?.audio?.muted ?? false) ? "volume_mute" : "volume_up"
                    size: NihilStyle.s(17)
                    color: status.foreground
                }
                NIcon {
                    visible: Battery.available
                    readonly property int step: Math.min(6, Math.floor(Battery.percentage * 7))
                    text: Battery.isCharging ? "battery_charging_full" : Battery.percentage > 0.95 ? "battery_full" : "battery_" + step + "_bar"
                    size: NihilStyle.s(17)
                    color: Battery.isLowAndNotCharging && !status.highlighted ? NihilStyle.danger : status.foreground
                }
            }
        }
    }

    // The time: hours over minutes on a vertical bar, the date and time in one line on a horizontal one. Opens Today; a
    // light marks notifications waiting.
    Component {
        id: clockPart
        BarKey {
            id: clock
            name: DateTime.date
            highlighted: NihilState.todayOpen
            readonly property var parts: String(DateTime.time).split(":")
            implicitWidth: bar.vertical ? bar.key : wide.implicitWidth + NihilStyle.s(24)
            implicitHeight: bar.vertical ? tall.implicitHeight + NihilStyle.s(18) : bar.key
            onClicked: NihilState.toggleOn("today", bar.output)
            Column {
                id: tall
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
                id: wide
                anchors.centerIn: parent
                visible: !bar.vertical
                spacing: NihilStyle.s(8)
                NText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: bar.panel?.date ?? true
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
    }

    Component {
        id: powerPart
        BarKey {
            glyph: "power"
            name: Translation.tr("Power")
            highlighted: NihilState.powerOpen
            onClicked: { NihilState.askedOn = bar.output; NihilState.toggle("power") }
        }
    }

    NihilTrayMenu { id: trayMenu }
}
