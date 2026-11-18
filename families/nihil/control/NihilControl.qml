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

// Quick controls: one block in the corner over the machine's state. The two radios lead, on paper while on; what plays;
// the two levels; eight keys. A radio's corner and the volume's key open their lists in the same block.
NPopup {
    id: root

    open: NihilState.controlOpen
    namespace: "nihil:control"
    onDismissed: NihilState.controlOpen = false
    // The list a key leads to (wifi, bluetooth, output, input); empty is the block itself.
    property string page: ""
    onOpenChanged: if (!root.open) root.page = ""

    readonly property real g: NihilStyle.seam
    readonly property real wide: NihilStyle.s(372)
    readonly property real half: (root.wide - root.g) / 2
    readonly property real unit: (root.wide - root.g * 3) / 4
    readonly property var monitor: Brightness.getMonitorForScreen(root.screen)
    readonly property bool hasBrightness: Number.isFinite(root.monitor?.brightness)
    readonly property bool muted: Audio.sink?.audio?.muted ?? false
    // Airplane: every radio off. Turning it off brings Wi-Fi back; Bluetooth stays as the person leaves it.
    readonly property bool airplane: !Network.wifiEnabled && !BluetoothStatus.enabled

    BluetoothToggle { id: bt }
    NetworkToggle { id: net }
    NightLightToggle { id: night }
    IdleInhibitorToggle { id: awake }
    PowerProfilesToggle { id: profile }
    DarkModeToggle { id: darkMode }
    ScreenSnipToggle { id: snip }

    // A radio: on paper while on, what it is joined to in heavy type, its corner leading to the list.
    component Radio: NTile {
        id: radio
        property string glyph: ""
        property string name: ""
        property bool usable: true
        signal opened()
        width: root.half
        height: NihilStyle.s(104)
        interactive: radio.usable
        ink: !radio.usable ? NihilStyle.dotOff : radio.paper ? NihilStyle.onPlate : NihilStyle.ink
        NIcon {
            x: radio.pad
            y: NihilStyle.s(36)
            text: radio.glyph
            size: NihilStyle.s(24)
            color: radio.ink
        }
        NText {
            x: radio.pad
            width: radio.width - radio.pad * 2
            anchors.bottom: parent.bottom
            anchors.bottomMargin: NihilStyle.s(10)
            text: radio.name
            font.pixelSize: NihilStyle.textLarge
            font.weight: Font.Black
            color: radio.ink
        }
        NButton {
            visible: radio.usable
            x: radio.width - width - NihilStyle.s(6)
            y: NihilStyle.s(6)
            width: NihilStyle.s(32); height: width
            tone: Qt.alpha(radio.ink, 0.12)
            ink: radio.ink
            icon: "chevron_right"
            iconSize: NihilStyle.s(18)
            onClicked: radio.opened()
        }
    }

    // A key of the last rows: its glyph above, its word at the foot, on paper while on.
    component Key: NButton {
        id: key
        property string glyph: ""
        property string word: ""
        property bool usable: true
        width: root.unit
        height: NihilStyle.s(76)
        square: true
        interactive: key.usable
        ink: !key.usable ? NihilStyle.dotOff : key.lit ? NihilStyle.onAccent : key.paper ? NihilStyle.onPlate : NihilStyle.ink
        NIcon {
            x: NihilStyle.s(10)
            y: NihilStyle.s(10)
            text: key.glyph
            size: NihilStyle.s(22)
            color: key.ink
        }
        NText {
            x: NihilStyle.s(10)
            width: key.width - NihilStyle.s(14)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: NihilStyle.s(8)
            text: key.word
            font.pixelSize: NihilStyle.textMicro
            font.weight: Font.Bold
            color: key.ink
        }
    }

    NRack {
        id: rack
        width: root.wide
        height: NihilStyle.s(104 + 116 + 72 * 2 + 76 * 2) + root.g * 5
        x: parent.width - width - NihilStyle.edge
        y: root.barBottom ? parent.height - height - root.edgeBottom : root.edgeTop

        NTile {
            anchors.fill: parent
            visible: root.page.length > 0
            ControlList {
                x: NihilStyle.s(8)
                y: NihilStyle.s(8)
                width: rack.width - NihilStyle.s(16)
                height: rack.height - NihilStyle.s(16)
                page: root.page
                onPageChanged: root.page = page
                onBack: root.page = ""
            }
        }

        Column {
            visible: root.page.length === 0
            spacing: root.g

            Row {
                spacing: root.g
                Radio {
                    caption: Translation.tr("Wi-Fi")
                    glyph: Network.ethernet ? "lan" : Network.wifiEnabled ? "wifi" : "wifi_off"
                    name: Network.ethernet ? Translation.tr("Wired")
                        : net.toggled ? (Network.networkName || Translation.tr("On")) : Translation.tr("Off")
                    paper: net.toggled || Network.ethernet
                    onClicked: net.mainAction()
                    onRightClicked: root.page = "wifi"
                    onOpened: root.page = "wifi"
                }
                Radio {
                    caption: Translation.tr("Bluetooth")
                    glyph: bt.toggled ? "bluetooth" : "bluetooth_disabled"
                    name: !bt.available ? Translation.tr("None")
                        : BluetoothStatus.connected ? BluetoothStatus.activeDeviceSummary(true)
                        : bt.toggled ? Translation.tr("On") : Translation.tr("Off")
                    paper: bt.toggled
                    usable: bt.available
                    onClicked: bt.mainAction()
                    onRightClicked: root.page = "bluetooth"
                    onOpened: root.page = "bluetooth"
                }
            }

            NPlayer {
                width: root.wide
                height: NihilStyle.s(116)
                live: root.open
            }

            NFader {
                width: root.wide
                height: NihilStyle.s(72)
                caption: Translation.tr("Volume")
                value: root.muted ? 0 : Audio.value
                figure: root.muted ? Translation.tr("Mute") : Math.round(Audio.value * 100) + "%"
                opens: true
                onMoved: value => Audio.setSinkVolume(value)
                onOpened: root.page = "output"
            }
            NFader {
                width: root.wide
                height: NihilStyle.s(72)
                caption: Translation.tr("Brightness")
                enabled: root.hasBrightness
                ink: root.hasBrightness ? NihilStyle.ink : NihilStyle.dotOff
                value: root.hasBrightness ? root.monitor.brightness : 0
                figure: root.hasBrightness ? Math.round(root.monitor.brightness * 100) + "%" : "--"
                onMoved: value => root.monitor?.setBrightness(Math.max(0.01, value))
            }

            Row {
                spacing: root.g
                Key {
                    glyph: "nightlight"
                    word: Translation.tr("Night")
                    paper: night.toggled
                    onClicked: night.mainAction()
                }
                Key {
                    glyph: "coffee"
                    word: Translation.tr("Awake")
                    paper: awake.toggled
                    onClicked: awake.mainAction()
                }
                Key {
                    glyph: "dark_mode"
                    word: Translation.tr("Dark")
                    paper: darkMode.toggled
                    onClicked: darkMode.mainAction()
                }
                Key {
                    glyph: "flight"
                    word: Translation.tr("Airplane")
                    paper: root.airplane
                    onClicked: {
                        if (root.airplane) { Network.enableWifi(true); return }
                        Network.enableWifi(false)
                        if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = false
                    }
                }
            }

            Row {
                spacing: root.g
                Key {
                    glyph: "energy_savings_leaf"
                    word: Translation.tr("Saver")
                    paper: profile.toggled
                    usable: profile.available
                    onClicked: profile.mainAction()
                }
                Key {
                    glyph: "screenshot_region"
                    word: Translation.tr("Snip")
                    onClicked: {
                        NihilState.controlOpen = false
                        snip.mainAction()
                    }
                }
                Key {
                    glyph: "settings"
                    word: Translation.tr("Settings")
                    onClicked: NihilState.toggle("menu")
                }
                Key {
                    glyph: "power_settings_new"
                    word: Translation.tr("Power")
                    lit: true
                    onClicked: NihilState.toggle("power")
                }
            }
        }
    }
}
