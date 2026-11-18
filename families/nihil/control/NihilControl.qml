pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.nihil.style
import qs.modules.nihil.state

// Quick controls: one piece in the screen's corner over the status pill, four cells wide. Bluetooth and Airplane
// keys beside the lit Wi-Fi tile; the record beside brightness (filled in ink) and volume (in the signal); two
// toggles and Settings; Energy Saver, dark mode and the screen snip.
NPopup {
    id: root

    open: NihilState.controlOpen
    namespace: "nihil:control"
    onDismissed: NihilState.controlOpen = false
    // The list a key leads to (wifi, bluetooth, output, input), shown in this same piece; empty is the grid.
    property string page: ""
    onOpenChanged: if (!root.open) root.page = ""

    readonly property real c: NihilStyle.cell
    readonly property real g: NihilStyle.cellGap
    readonly property var monitor: Brightness.getMonitorForScreen(root.screen)
    // Airplane: every radio off. Turning it off brings Wi-Fi back; Bluetooth stays as the person leaves it.
    readonly property bool airplane: !Network.wifiEnabled && !BluetoothStatus.enabled

    BluetoothToggle { id: bt }
    NetworkToggle { id: net }
    NightLightToggle { id: night }
    IdleInhibitorToggle { id: awake }
    PowerProfilesToggle { id: profile }
    DarkModeToggle { id: darkMode }
    ScreenSnipToggle { id: snip }

    NCard {
        id: card
        width: NihilStyle.cells(4) + NihilStyle.panelPad * 2
        height: NihilStyle.cells(2) * 2 + root.c * 2 + root.g * 3 + NihilStyle.panelPad * 2
        x: parent.width - width - NihilStyle.edge
        y: root.barBottom ? parent.height - height - root.edgeBottom : root.edgeTop

        ControlList {
            width: parent.width
            height: parent.height
            visible: root.page.length > 0
            page: root.page
            onPageChanged: root.page = page
            onBack: root.page = ""
        }

        Column {
            spacing: root.g
            visible: root.page.length === 0

            Row {
                spacing: root.g
                Column {
                    spacing: root.g
                    NKey {
                        width: NihilStyle.cells(2); height: root.c
                        glyph: "bluetooth"
                        label: Translation.tr("Bluetooth")
                        lit: bt.toggled
                        enabled: bt.available
                        opacity: bt.available ? 1 : 0.5
                        opens: bt.available
                        onClicked: bt.mainAction()
                        onRightClicked: root.page = "bluetooth"
                        onOpened: root.page = "bluetooth"
                    }
                    NKey {
                        width: NihilStyle.cells(2); height: root.c
                        glyph: "flight"
                        label: Translation.tr("Airplane Mode")
                        stacked: true
                        lit: root.airplane
                        onClicked: {
                            if (root.airplane) { Network.enableWifi(true); return }
                            Network.enableWifi(false)
                            if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = false
                        }
                    }
                }
                NButton {
                    width: NihilStyle.cells(2); height: width
                    square: true
                    radius: NihilStyle.s(18)
                    lit: net.toggled
                    onClicked: net.mainAction()
                    onRightClicked: root.page = "wifi"
                    // The corner leads to the networks; the rest of the tile turns Wi-Fi on and off.
                    NButton {
                        width: NihilStyle.s(32); height: width
                        x: parent.width - width - NihilStyle.s(8)
                        y: NihilStyle.s(8)
                        tone: net.toggled ? Qt.rgba(0, 0, 0, 0.14) : NihilStyle.pieceRaised
                        ink: net.toggled ? NihilStyle.onAccent : NihilStyle.ink
                        icon: "chevron_right"
                        iconSize: NihilStyle.s(18)
                        onClicked: root.page = "wifi"
                    }
                    Column {
                        anchors.centerIn: parent
                        spacing: NihilStyle.s(8)
                        NIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: net.icon
                            size: NihilStyle.s(30)
                            color: net.toggled ? NihilStyle.onAccent : NihilStyle.ink
                        }
                        NText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.min(implicitWidth, NihilStyle.cells(2) - NihilStyle.s(20))
                            figures: true
                            text: net.toggled ? (Network.networkName || Translation.tr("Wi-Fi")) : Translation.tr("Wi-Fi")
                            color: net.toggled ? NihilStyle.onAccent : NihilStyle.ink
                        }
                    }
                }
            }

            Row {
                spacing: root.g
                MusicDisc {
                    width: NihilStyle.cells(2); height: width
                    live: root.open
                }
                NLevel {
                    width: root.c; height: NihilStyle.cells(2)
                    value: Number.isFinite(root.monitor?.brightness) ? root.monitor.brightness : 0
                    label: Number.isFinite(root.monitor?.brightness) ? Math.round(value * 100) + "%" : "--"
                    fill: NihilStyle.ink
                    fillInk: NihilStyle.piece
                    icon: "light_mode"
                    opacity: root.monitor ? 1 : 0.5
                    onMoved: v => root.monitor?.setBrightness(Math.max(0.01, v))
                }
                NLevel {
                    width: root.c; height: NihilStyle.cells(2)
                    value: Audio.sink?.audio?.muted ? 0 : Audio.value
                    icon: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                    opens: true
                    onMoved: v => Audio.setSinkVolume(v)
                    onOpened: root.page = "output"
                }
            }

            Row {
                spacing: root.g
                NButton {
                    width: root.c; height: root.c
                    tone: NihilStyle.pieceRaised
                    icon: night.icon
                    lit: night.toggled
                    onClicked: night.mainAction()
                }
                NButton {
                    width: root.c; height: root.c
                    tone: NihilStyle.pieceRaised
                    icon: awake.icon
                    lit: awake.toggled
                    onClicked: awake.mainAction()
                }
                NKey {
                    width: NihilStyle.cells(2); height: root.c
                    glyph: "settings"
                    label: Translation.tr("Settings")
                    onClicked: {
                        NihilState.closeAll()
                        NihilState.toggle("menu")
                    }
                }
            }

            Row {
                spacing: root.g
                NKey {
                    width: NihilStyle.cells(2); height: root.c
                    glyph: "energy_savings_leaf"
                    label: Translation.tr("Energy Saver")
                    stacked: true
                    lit: profile.toggled
                    enabled: profile.available
                    opacity: profile.available ? 1 : 0.5
                    onClicked: profile.mainAction()
                }
                NButton {
                    width: root.c; height: root.c
                    tone: NihilStyle.pieceRaised
                    icon: darkMode.icon
                    lit: darkMode.toggled
                    onClicked: darkMode.mainAction()
                }
                NButton {
                    width: root.c; height: root.c
                    tone: NihilStyle.pieceRaised
                    icon: "screenshot_region"
                    onClicked: {
                        NihilState.controlOpen = false
                        snip.mainAction()
                    }
                }
            }
        }
    }
}
