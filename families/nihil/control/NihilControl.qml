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

// Quick controls as a glass pane in the corner, built of raised cards: the time with settings and power at hand, the
// two radios, what plays, the two levels and six keys. A radio's chevron and the volume's open their lists on the
// same pane.
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
    readonly property real inset: NihilStyle.s(12)
    readonly property real wide: NihilStyle.s(380)
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

    // A card: a raised piece of the pane.
    component Card: Rectangle {
        radius: NihilStyle.rCard
        color: NihilStyle.piece
        border.width: 1
        border.color: NihilStyle.line
    }

    // A radio: a card with its round badge, its name and what it is on. The badge fills with the accent when on; the
    // chevron opens its list.
    component Radio: MouseArea {
        id: radio

        property string glyph: ""
        property string name: ""
        property string state_: ""
        property bool on: false
        property bool usable: true

        signal tapped()
        signal opened()

        width: (root.inner - NihilStyle.s(8)) / 2
        height: NihilStyle.s(64)
        enabled: radio.usable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        opacity: radio.usable ? 1 : 0.45
        onClicked: radio.tapped()

        Card {
            anchors.fill: parent
            color: radio.containsMouse ? NihilStyle.pieceRaised : NihilStyle.piece
            Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
        }
        Rectangle {
            id: badge
            x: NihilStyle.s(12)
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(34)
            height: width
            radius: width / 2
            color: radio.on ? NihilStyle.accent : NihilStyle.pieceRaised
            Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
            NIcon {
                anchors.centerIn: parent
                text: radio.glyph
                size: NihilStyle.s(17)
                color: radio.on ? NihilStyle.accentInk : NihilStyle.ink
            }
        }
        Column {
            anchors.left: badge.right
            anchors.leftMargin: NihilStyle.s(10)
            anchors.right: chevron.left
            anchors.verticalCenter: parent.verticalCenter
            NText {
                width: parent.width
                text: radio.name
                font.weight: Font.DemiBold
            }
            NText {
                width: parent.width
                text: radio.state_
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
            }
        }
        NButton {
            id: chevron
            visible: radio.usable
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(4)
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(26)
            height: NihilStyle.s(26)
            icon: "chevron_right"
            iconSize: NihilStyle.s(16)
            onClicked: radio.opened()
        }
    }

    // A level: its glyph (which mutes), the slider, the share as a quiet figure and the chevron to its list.
    component Level: Item {
        id: level

        property string name: ""
        property string glyph: ""
        property real value: 0
        property bool lit: false
        property bool opens: false

        signal keyed()
        signal moved(real value)
        signal opened()

        width: root.inner - NihilStyle.s(24)
        height: NihilStyle.s(34)

        NButton {
            id: keyButton
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(30)
            height: NihilStyle.s(30)
            icon: level.glyph
            iconSize: NihilStyle.s(17)
            lit: level.lit
            Accessible.name: level.name
            onClicked: level.keyed()
        }
        NSlider {
            anchors.left: keyButton.right
            anchors.leftMargin: NihilStyle.s(8)
            anchors.right: figure.left
            anchors.rightMargin: NihilStyle.s(10)
            anchors.verticalCenter: parent.verticalCenter
            value: level.value
            onMoved: value => level.moved(value)
        }
        NText {
            id: figure
            anchors.right: more.visible ? more.left : parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(34)
            horizontalAlignment: Text.AlignRight
            text: Math.round(level.value * 100) + "%"
            figures: true
            font.pixelSize: NihilStyle.textSmall
            color: NihilStyle.inkSoft
        }
        NButton {
            id: more
            visible: level.opens
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(26)
            height: NihilStyle.s(26)
            icon: "chevron_right"
            iconSize: NihilStyle.s(15)
            onClicked: level.opened()
        }
    }

    // One of the six keys: a pill with its glyph and word. On, it is a raised plate with the glyph in the accent.
    component Key: MouseArea {
        id: key

        property string glyph: ""
        property string word: ""
        property bool on: false
        property bool usable: true

        signal tapped()

        width: (root.inner - NihilStyle.s(16)) / 3
        height: NihilStyle.s(40)
        enabled: key.usable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        opacity: key.usable ? 1 : 0.4
        onClicked: key.tapped()

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: key.on ? NihilStyle.chosen : key.containsMouse ? NihilStyle.pieceRaised : NihilStyle.piece
            border.width: 1
            border.color: key.on ? NihilStyle.hair : NihilStyle.line
            Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
        }
        Row {
            anchors.centerIn: parent
            spacing: NihilStyle.s(7)
            NIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: key.glyph
                size: NihilStyle.s(16)
                color: key.on ? NihilStyle.accent : NihilStyle.inkSoft
            }
            NText {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, key.width - NihilStyle.s(44))
                text: key.word
                font.pixelSize: NihilStyle.textSmall
                font.weight: key.on ? Font.DemiBold : Font.Medium
                color: key.on ? NihilStyle.ink : NihilStyle.inkSoft
            }
        }
    }

    NGlass {
        id: pane

        width: root.wide
        height: root.page.length > 0 ? NihilStyle.s(520) : controls.implicitHeight + root.inset * 2
        x: parent.width - width - NihilStyle.edge
        y: root.barBottom ? parent.height - height - NihilStyle.barHeight - NihilStyle.edge * 2
            : NihilStyle.barHeight + NihilStyle.edge * 2
        ignite: root.open ? 0.35 : 0
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

            // The head: the day, then settings and power at hand.
            Item {
                width: root.inner
                height: NihilStyle.s(30)
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: NihilStyle.s(4)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: NihilStyle.s(10)
                    NText {
                        anchors.baseline: parent.children[1].baseline
                        text: DateTime.time
                        figures: true
                        font.pixelSize: NihilStyle.textLarge
                        font.weight: Font.DemiBold
                    }
                    NText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: DateTime.date
                        font.pixelSize: NihilStyle.textSmall
                        color: NihilStyle.inkSoft
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: NihilStyle.s(4)
                    NButton {
                        width: NihilStyle.s(30)
                        height: NihilStyle.s(30)
                        icon: "settings"
                        iconSize: NihilStyle.s(16)
                        Accessible.name: Translation.tr("Settings")
                        onClicked: {
                            NihilState.controlOpen = false
                            Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "settings"])
                        }
                    }
                    NButton {
                        width: NihilStyle.s(30)
                        height: NihilStyle.s(30)
                        icon: "power_settings_new"
                        iconSize: NihilStyle.s(16)
                        Accessible.name: Translation.tr("Power")
                        onClicked: {
                            NihilState.controlOpen = false
                            NihilState.toggle("power")
                        }
                    }
                }
            }

            Row {
                spacing: NihilStyle.s(8)
                Radio {
                    glyph: Network.ethernet ? "lan" : Network.wifiEnabled ? "wifi" : "wifi_off"
                    name: Translation.tr("Wi-Fi")
                    state_: Network.ethernet ? Translation.tr("Wired")
                        : net.toggled ? (Network.networkName || Translation.tr("On")) : Translation.tr("Off")
                    on: net.toggled || Network.ethernet
                    onTapped: net.mainAction()
                    onOpened: root.page = "wifi"
                }
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
            Card {
                visible: !!root.player
                width: root.inner
                height: visible ? NihilStyle.s(60) : 0

                Image {
                    id: art
                    x: NihilStyle.s(10)
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(40)
                    height: width
                    sourceSize: Qt.size(width * 2, height * 2)
                    fillMode: Image.PreserveAspectCrop
                    source: root.player?.trackArtUrl ?? ""
                    visible: status === Image.Ready
                }
                Column {
                    anchors.left: art.visible ? art.right : parent.left
                    anchors.leftMargin: NihilStyle.s(12)
                    anchors.right: transport.left
                    anchors.rightMargin: NihilStyle.gap
                    anchors.verticalCenter: parent.verticalCenter

                    NText {
                        width: parent.width
                        text: root.player?.trackTitle ?? ""
                        font.weight: Font.DemiBold
                    }
                    NText {
                        width: parent.width
                        text: root.player?.trackArtist ?? ""
                        font.pixelSize: NihilStyle.textSmall
                        color: NihilStyle.inkSoft
                    }
                }

                Row {
                    id: transport
                    anchors.right: parent.right
                    anchors.rightMargin: NihilStyle.s(6)
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

            Card {
                width: root.inner
                height: levelColumn.implicitHeight + NihilStyle.s(16)
                Column {
                    id: levelColumn
                    x: NihilStyle.s(12)
                    y: NihilStyle.s(8)
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
                }
            }

            Grid {
                columns: 3
                spacing: NihilStyle.s(8)

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
            }
        }
    }
}
