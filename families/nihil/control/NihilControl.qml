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

// Quick controls as one printed sheet under glass in the corner: the two radios set large, what plays, the two levels
// with their figures and a table of eight keys. A radio's
// chevron and the volume's open their lists on the same pane.
NPopup {
    id: root

    open: NihilState.controlOpen
    namespace: "nihil:control"
    blurPieces: [pane.region]
    onDismissed: NihilState.controlOpen = false

    // The list on show: "wifi", "bluetooth", "output" or "input". Empty is the controls themselves.
    property string page: ""
    onOpenChanged: if (!root.open) root.page = ""

    readonly property bool barBottom: (Config.options?.nihil?.panel?.position ?? "top") === "bottom"
    readonly property real inset: NihilStyle.s(14)
    readonly property real wide: NihilStyle.s(372)
    readonly property real inner: root.wide - root.inset * 2
    readonly property var monitor: Brightness.getMonitorForScreen(root.screen)
    readonly property bool hasBrightness: Number.isFinite(root.monitor?.brightness)
    readonly property bool muted: Audio.sink?.audio?.muted ?? false
    readonly property bool airplane: !Network.wifiEnabled && !BluetoothStatus.enabled
    readonly property var player: MprisController.activePlayer

    BluetoothToggle { id: bt }
    NetworkToggle { id: net }
    NightLightToggle { id: night }
    IdleInhibitorToggle { id: awake }
    PowerProfilesToggle { id: profile }
    DarkModeToggle { id: darkMode }
    ScreenSnipToggle { id: snip }

    // A radio: a column of the sheet. Its name in small capitals, its state set large, the chevron to its list. On, a
    // line of light runs down its edge.
    component Radio: MouseArea {
        id: radio

        property string glyph: ""
        property string name: ""
        property string state_: ""
        property bool on: false
        property bool usable: true

        signal tapped()
        signal opened()

        width: (root.inner - 1) / 2
        height: NihilStyle.s(78)
        enabled: radio.usable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        opacity: radio.usable ? 1 : 0.45
        onClicked: radio.tapped()

        Rectangle {
            anchors.fill: parent
            radius: NihilStyle.r(6)
            color: NihilStyle.ink
            opacity: radio.containsMouse ? 0.06 : 0
            Behavior on opacity { NumberAnimation { duration: NihilStyle.quick } }
        }
        NSpectrum {
            vertical: true
            x: 0
            y: NihilStyle.s(10)
            width: NihilStyle.s(2)
            height: parent.height - NihilStyle.s(20)
            opacity: radio.on ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: NihilStyle.calm } }
        }
        NIcon {
            x: NihilStyle.s(12)
            y: NihilStyle.s(12)
            text: radio.glyph
            size: NihilStyle.s(15)
            color: radio.on ? NihilStyle.ink : NihilStyle.inkSoft
        }
        NLabel {
            x: NihilStyle.s(34)
            y: NihilStyle.s(12)
            width: parent.width - x - NihilStyle.s(36)
            height: NihilStyle.s(15)
            text: radio.name
        }
        NDisplay {
            x: NihilStyle.s(12)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: NihilStyle.s(10)
            width: parent.width - NihilStyle.s(44)
            text: radio.state_
            elide: Text.ElideRight
            size: NihilStyle.s(26)
            bloom: radio.on ? 0.6 : 0
            color: radio.on ? NihilStyle.ink : NihilStyle.inkSoft
        }
        NButton {
            visible: radio.usable
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(4)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: NihilStyle.s(8)
            width: NihilStyle.s(28)
            height: NihilStyle.s(28)
            icon: "chevron_right"
            iconSize: NihilStyle.s(16)
            onClicked: radio.opened()
        }
    }

    // A level: its name and figure on a line, the slider under it. The name mutes, the chevron opens its list.
    component Level: Column {
        id: level

        property string name: ""
        property string glyph: ""
        property real value: 0
        property bool lit: false
        property bool opens: false

        signal keyed()
        signal moved(real value)
        signal opened()

        width: root.inner
        spacing: NihilStyle.s(4)

        Item {
            width: parent.width
            height: NihilStyle.s(28)

            MouseArea {
                id: keyArea
                width: keyRow.implicitWidth
                height: parent.height
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: level.keyed()

                Row {
                    id: keyRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: NihilStyle.s(8)
                    NIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: level.glyph
                        size: NihilStyle.s(15)
                        color: level.lit ? NihilStyle.live : keyArea.containsMouse ? NihilStyle.ink : NihilStyle.inkSoft
                    }
                    NLabel {
                        anchors.verticalCenter: parent.verticalCenter
                        text: level.name
                        strong: keyArea.containsMouse
                    }
                }
            }
            NDisplay {
                anchors.right: more.visible ? more.left : parent.right
                anchors.rightMargin: more.visible ? NihilStyle.s(4) : 0
                anchors.verticalCenter: parent.verticalCenter
                text: String(Math.round(level.value * 100)).padStart(2, "0")
                size: NihilStyle.s(24)
                bloom: 0.4
            }
            NButton {
                id: more
                visible: level.opens
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(24)
                height: NihilStyle.s(24)
                icon: "chevron_right"
                iconSize: NihilStyle.s(14)
                onClicked: level.opened()
            }
        }
        NSlider {
            width: parent.width
            value: level.value
            onMoved: value => level.moved(value)
        }
    }

    // One of the eight keys: a cell of the sheet's table, its glyph over its word. On, the cell is a bone plate.
    component Key: MouseArea {
        id: key

        property string glyph: ""
        property string word: ""
        property bool on: false
        property bool usable: true

        signal tapped()

        width: root.inner / 4
        height: NihilStyle.s(66)
        enabled: key.usable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        opacity: key.usable ? 1 : 0.4
        onClicked: key.tapped()

        Rectangle {
            anchors.fill: parent
            anchors.margins: NihilStyle.s(3)
            radius: NihilStyle.r(6)
            color: NihilStyle.ink
            opacity: key.on ? 1 : key.containsMouse ? 0.08 : 0
            Behavior on opacity { NumberAnimation { duration: NihilStyle.quick } }
        }
        NSpark {
            visible: key.on
            x: parent.width - size - NihilStyle.s(4)
            y: NihilStyle.s(4)
            size: NihilStyle.s(12)
            tint: NihilStyle.void_
        }
        NIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            y: NihilStyle.s(14)
            text: key.glyph
            size: NihilStyle.s(19)
            color: key.on ? NihilStyle.void_ : NihilStyle.ink
        }
        NLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: NihilStyle.s(11)
            width: parent.width - NihilStyle.s(8)
            horizontalAlignment: Text.AlignHCenter
            text: key.word
            color: key.on ? NihilStyle.void_ : NihilStyle.inkSoft
        }
    }

    component Hair: Rectangle {
        width: root.inner
        height: 1
        color: NihilStyle.hair
    }

    NGlass {
        id: pane

        width: root.wide
        height: root.page.length > 0 ? NihilStyle.s(520) : controls.implicitHeight + root.inset * 2
        x: parent.width - width - NihilStyle.edge
        y: root.barBottom ? parent.height - height - NihilStyle.barHeight - NihilStyle.edge * 2
            : NihilStyle.barHeight + NihilStyle.edge * 2
        ignite: root.open ? 0.5 : 0
        Behavior on height { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        ControlList {
            x: root.inset
            y: root.inset
            width: root.inner
            height: pane.height - root.inset * 2
            visible: root.page.length > 0
            page: root.page
            onPicked: page => root.page = page
            onBack: root.page = ""
        }

        Column {
            id: controls
            x: root.inset
            y: root.inset
            width: root.inner
            visible: root.page.length === 0
            spacing: NihilStyle.s(12)

            // The sheet's head: what it is, and the hour it is read at.
            Item {
                width: root.inner
                height: NihilStyle.s(18)
                NLabel { anchors.verticalCenter: parent.verticalCenter; text: Translation.tr("Control"); strong: true }
                NLabel { anchors.centerIn: parent; text: "▶ ⋈ ◀"; color: NihilStyle.inkFaint }
                NLabel { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: DateTime.time }
            }
            Hair {}

            Row {
                Radio {
                    glyph: Network.ethernet ? "lan" : Network.wifiEnabled ? "wifi" : "wifi_off"
                    name: Translation.tr("Wi-Fi")
                    state_: Network.ethernet ? Translation.tr("Wired")
                        : net.toggled ? (Network.networkName || Translation.tr("On")) : Translation.tr("Off")
                    on: net.toggled || Network.ethernet
                    onTapped: net.mainAction()
                    onOpened: root.page = "wifi"
                }
                Rectangle { width: 1; height: NihilStyle.s(78); color: NihilStyle.hair }
                Radio {
                    glyph: bt.toggled ? "bluetooth" : "bluetooth_disabled"
                    name: Translation.tr("Bluetooth")
                    state_: !bt.available ? Translation.tr("None")
                        : BluetoothStatus.connected ? BluetoothStatus.activeDeviceSummary(true)
                        : bt.toggled ? Translation.tr("On") : Translation.tr("Off")
                    on: bt.toggled
                    usable: bt.available
                    onTapped: bt.mainAction()
                    onOpened: root.page = "bluetooth"
                }
            }
            Hair {}

            Item {
                visible: !!root.player
                width: root.inner
                height: visible ? NihilStyle.s(44) : 0

                Column {
                    anchors.left: parent.left
                    anchors.right: transport.left
                    anchors.rightMargin: NihilStyle.gap
                    anchors.verticalCenter: parent.verticalCenter

                    NLabel {
                        width: parent.width
                        text: root.player?.trackArtist ?? ""
                    }
                    NText {
                        width: parent.width
                        text: root.player?.trackTitle ?? ""
                        elide: Text.ElideRight
                        font.weight: Font.DemiBold
                    }
                }

                Row {
                    id: transport
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    NButton {
                        icon: "previous"
                        onClicked: root.player?.previous()
                    }
                    NButton {
                        icon: root.player?.isPlaying ? "pause" : "play"
                        lit: root.player?.isPlaying ?? false
                        onClicked: root.player?.togglePlaying()
                    }
                    NButton {
                        icon: "next"
                        onClicked: root.player?.next()
                    }
                }
            }

            Level {
                name: Translation.tr("Sound")
                glyph: root.muted ? "volume_mute" : "volume_up"
                lit: root.muted
                value: root.muted ? 0 : Audio.value
                opens: true
                onKeyed: if (Audio.sink?.audio) Audio.sink.audio.muted = !root.muted
                onMoved: value => Audio.setSinkVolume(value)
                onOpened: root.page = "output"
            }
            Level {
                name: Translation.tr("Light")
                visible: root.hasBrightness
                glyph: "light_mode"
                value: root.hasBrightness ? root.monitor.brightness : 0
                onMoved: value => root.monitor?.setBrightness(Math.max(0.01, value))
            }

            Hair {}
            Grid {
                columns: 4

                Key {
                    glyph: "bedtime"
                    word: Translation.tr("Night")
                    on: night.toggled
                    onTapped: night.mainAction()
                }
                Key {
                    glyph: "bolt"
                    word: Translation.tr("Awake")
                    on: awake.toggled
                    onTapped: awake.mainAction()
                }
                Key {
                    glyph: "contrast"
                    word: Translation.tr("Dark")
                    on: darkMode.toggled
                    onTapped: darkMode.mainAction()
                }
                Key {
                    glyph: "flight"
                    word: Translation.tr("Airplane")
                    on: root.airplane
                    onTapped: {
                        if (root.airplane) {
                            Network.enableWifi(true)
                            return
                        }
                        Network.enableWifi(false)
                        if (Bluetooth.defaultAdapter)
                            Bluetooth.defaultAdapter.enabled = false
                    }
                }
                Key {
                    glyph: "leaf"
                    word: Translation.tr("Saver")
                    on: profile.toggled
                    usable: profile.available
                    onTapped: profile.mainAction()
                }
                Key {
                    glyph: "screenshot"
                    word: Translation.tr("Snip")
                    onTapped: {
                        NihilState.controlOpen = false
                        snip.mainAction()
                    }
                }
                Key {
                    glyph: "settings"
                    word: Translation.tr("Settings")
                    onTapped: {
                        NihilState.controlOpen = false
                        Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "settings"])
                    }
                }
                Key {
                    glyph: "power"
                    word: Translation.tr("Power")
                    onTapped: {
                        NihilState.controlOpen = false
                        NihilState.toggle("power")
                    }
                }
            }
        }
    }
}
