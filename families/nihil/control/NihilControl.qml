pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.models.quickToggles
import qs.modules.nihil.style
import qs.modules.nihil.state

// The machine as an instrument panel: two dials, two radios, six round keys, what plays and the way out. What is on is
// solid in the light. A radio's arrow, or a right click on a dial, opens its list on the same slab.
Item {
    id: root

    property var screen: null
    property bool flipped: false
    property real room: 0
    property bool open: false

    // The list on show: "wifi", "bluetooth", "output" or "input". Empty is the controls themselves.
    property string page: ""
    onOpenChanged: if (!root.open) root.page = ""

    readonly property real side: NihilStyle.s(24)
    readonly property real inner: root.width - root.side * 2
    readonly property real headPad: NihilStyle.s(16)
    // Where the light gathers, under the last row.
    readonly property real footPad: NihilStyle.s(54)
    readonly property var monitor: Brightness.getMonitorForScreen(root.screen)
    readonly property bool hasBrightness: Number.isFinite(root.monitor?.brightness)
    readonly property bool muted: Audio.sink?.audio?.muted ?? false
    readonly property bool airplane: !Network.wifiEnabled && !BluetoothStatus.enabled
    readonly property var player: MprisController.activePlayer

    implicitWidth: NihilStyle.s(520)
    implicitHeight: root.page.length > 0 ? Math.min(NihilStyle.s(600), root.room)
        : controls.implicitHeight + root.headPad + root.footPad

    BluetoothToggle { id: bt }
    NetworkToggle { id: net }
    NightLightToggle { id: night }
    IdleInhibitorToggle { id: awake }
    PowerProfilesToggle { id: profile }
    DarkModeToggle { id: darkMode }
    ScreenSnipToggle { id: snip }

    function span(seconds: real): string {
        const minutes = Math.round(seconds / 60)
        const hours = Math.floor(minutes / 60)
        return hours > 0 ? Translation.tr("%1 h %2 min").arg(hours).arg(minutes % 60) : Translation.tr("%1 min").arg(minutes)
    }
    readonly property string machine: {
        // Without a battery there is nothing to tell here: the deck's side already says how long the machine is up.
        if (!Battery.available)
            return ""
        const share = Math.round(Battery.percentage * 100) + " %"
        const left = Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty
        if (!(left > 0))
            return Battery.isCharging ? Translation.tr("%1, charging").arg(share) : share
        return (Battery.isCharging ? Translation.tr("%1, full in %2") : Translation.tr("%1, %2 left")).arg(share).arg(root.span(left))
    }

    // A radio: a wide pill, solid in the light while on. The end of the pill opens its list.
    component Radio: MouseArea {
        id: radio

        property string glyph: ""
        property string name: ""
        property string note: ""
        property bool on: false
        property bool usable: true
        readonly property color inkOn: radio.on ? NihilStyle.accentInk : NihilStyle.ink

        signal tapped()
        signal opened()

        width: (root.inner - NihilStyle.gap) / 2
        height: NihilStyle.s(68)
        enabled: radio.usable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        opacity: radio.usable ? 1 : 0.45
        Accessible.role: Accessible.Button
        Accessible.name: radio.name
        Accessible.checkable: true
        Accessible.checked: radio.on
        onClicked: radio.tapped()

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: radio.on ? NihilStyle.accent : radio.containsMouse ? NihilStyle.pieceRaised : NihilStyle.piece
            Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
        }
        NIcon {
            id: radioGlyph
            x: NihilStyle.s(22)
            anchors.verticalCenter: parent.verticalCenter
            text: radio.glyph
            size: NihilStyle.s(22)
            color: radio.inkOn
        }
        Column {
            anchors.left: radioGlyph.right
            anchors.leftMargin: NihilStyle.s(14)
            anchors.right: arrow.left
            anchors.rightMargin: NihilStyle.s(4)
            anchors.verticalCenter: parent.verticalCenter
            NText {
                width: parent.width
                text: radio.name
                font.pixelSize: NihilStyle.textBody
                font.weight: Font.DemiBold
                color: radio.inkOn
            }
            NText {
                width: parent.width
                text: radio.note
                font.pixelSize: NihilStyle.textSmall
                color: Qt.alpha(radio.inkOn, 0.66)
            }
        }
        NButton {
            id: arrow
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(14)
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(36)
            height: width
            visible: radio.usable
            tone: radio.on ? Qt.alpha(NihilStyle.accentInk, 0.1) : NihilStyle.piece
            icon: "chevron_right"
            iconSize: NihilStyle.s(16)
            Accessible.name: Translation.tr("More")
            onClicked: radio.opened()
        }
    }

    // A round key, solid in the light while on, its word under it.
    component Key: MouseArea {
        id: key

        property string glyph: ""
        property string word: ""
        property bool on: false
        property bool usable: true

        signal tapped()

        width: root.inner / 6
        height: NihilStyle.s(86)
        enabled: key.usable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        opacity: key.usable ? 1 : 0.4
        Accessible.role: Accessible.Button
        Accessible.name: key.word
        Accessible.checkable: true
        Accessible.checked: key.on
        onClicked: key.tapped()

        Rectangle {
            id: disc
            anchors.horizontalCenter: parent.horizontalCenter
            width: NihilStyle.s(56)
            height: width
            radius: width / 2
            color: key.on ? NihilStyle.accent : key.containsMouse ? NihilStyle.pieceRaised : NihilStyle.piece
            scale: key.pressed ? 0.94 : 1
            Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
            Behavior on scale { NumberAnimation { duration: NihilStyle.quick } }
            NIcon {
                anchors.centerIn: parent
                text: key.glyph
                size: NihilStyle.s(22)
                color: key.on ? NihilStyle.accentInk : NihilStyle.ink
            }
        }
        NText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: Math.min(implicitWidth, parent.width - NihilStyle.s(4))
            text: key.word
            font.pixelSize: NihilStyle.textLabel
            color: key.on ? NihilStyle.ink : NihilStyle.inkSoft
        }
    }

    ControlList {
        x: root.side
        y: root.flipped ? root.footPad : root.headPad
        width: root.inner
        height: root.height - root.headPad - root.footPad
        visible: root.page.length > 0
        page: root.page
        onPicked: page => root.page = page
        onBack: root.page = ""
    }

    Column {
        id: controls
        x: root.side
        y: root.flipped ? root.footPad : root.headPad
        width: root.inner
        visible: root.page.length === 0
        spacing: NihilStyle.s(14)

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: NihilStyle.s(24)
            NDial {
                word: Translation.tr("Sound")
                glyph: root.muted ? "volume_off" : "volume_up"
                value: root.muted ? 0 : Audio.value
                keyed: true
                onTapped: if (Audio.sink?.audio) Audio.sink.audio.muted = !root.muted
                onMoved: value => Audio.setSinkVolume(value)
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: root.page = "output"
                }
            }
            NDial {
                word: root.hasBrightness ? Translation.tr("Light") : Translation.tr("Microphone")
                glyph: root.hasBrightness ? "light_mode" : (Audio.source?.audio?.muted ? "mic_off" : "mic")
                value: root.hasBrightness ? root.monitor.brightness : (Audio.source?.audio?.volume ?? 0)
                keyed: !root.hasBrightness
                onTapped: if (Audio.source?.audio) Audio.source.audio.muted = !Audio.source.audio.muted
                onMoved: value => {
                    if (root.hasBrightness) root.monitor?.setBrightness(Math.max(0.01, value))
                    else if (Audio.source?.audio) Audio.source.audio.volume = value
                }
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    enabled: !root.hasBrightness
                    onTapped: root.page = "input"
                }
            }
        }

        Column {
            width: parent.width
            spacing: NihilStyle.gap
            Row {
                spacing: NihilStyle.gap
                Radio {
                    glyph: Network.ethernet ? "lan" : Network.wifiEnabled ? "wifi" : "wifi_off"
                    name: Translation.tr("Wi-Fi")
                    note: Network.ethernet ? Translation.tr("Wired")
                        : net.toggled ? (Network.networkName || Translation.tr("On")) : Translation.tr("Off")
                    on: net.toggled || Network.ethernet
                    onTapped: net.mainAction()
                    onOpened: root.page = "wifi"
                }
                Radio {
                    glyph: bt.toggled ? "bluetooth" : "bluetooth_disabled"
                    name: Translation.tr("Bluetooth")
                    note: !bt.available ? Translation.tr("None")
                        : BluetoothStatus.connected ? BluetoothStatus.activeDeviceSummary(true)
                        : bt.toggled ? Translation.tr("On") : Translation.tr("Off")
                    on: bt.toggled
                    usable: bt.available
                    onTapped: bt.mainAction()
                    onOpened: root.page = "bluetooth"
                }
            }
            Row {
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
                    on: NihilStyle.dark
                    onTapped: {
                        const dark = !NihilStyle.dark
                        Config.setNestedValue("nihil.look.scheme", dark ? "dark" : "light")
                        if (darkMode.toggled !== dark) darkMode.mainAction()
                    }
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

        // What plays: its cover is the tile, darkened until the words read, with the round white key.
        ClippingRectangle {
            visible: !!root.player
            width: parent.width
            height: NihilStyle.s(112)
            radius: NihilStyle.r(26)
            color: NihilStyle.carbon

            Image {
                id: cover
                anchors.fill: parent
                asynchronous: true
                sourceSize.width: parent.width
                fillMode: Image.PreserveAspectCrop
                source: root.player?.trackArtUrl ?? ""
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.alpha("#0B0C0F", 0.86) }
                    GradientStop { position: 1; color: Qt.alpha("#0B0C0F", cover.status === Image.Ready ? 0.42 : 0.86) }
                }
            }
            Column {
                x: NihilStyle.s(22)
                anchors.right: transport.left
                anchors.rightMargin: NihilStyle.s(12)
                anchors.verticalCenter: parent.verticalCenter
                spacing: NihilStyle.s(3)
                NText {
                    width: parent.width
                    text: root.player?.trackTitle ?? ""
                    font.pixelSize: NihilStyle.textLarge
                    font.weight: Font.Medium
                    color: "#F5F6F8"
                }
                NText {
                    width: parent.width
                    text: root.player?.trackArtist ?? ""
                    font.pixelSize: NihilStyle.textSmall
                    color: Qt.alpha("#F5F6F8", 0.7)
                }
            }
            Row {
                id: transport
                anchors.right: parent.right
                anchors.rightMargin: NihilStyle.s(16)
                anchors.verticalCenter: parent.verticalCenter
                spacing: NihilStyle.s(6)
                MouseArea {
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(36)
                    height: width
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: Translation.tr("Previous")
                    onClicked: root.player?.previous()
                    NIcon { anchors.centerIn: parent; text: "previous"; size: NihilStyle.s(20); color: "#F5F6F8" }
                }
                MouseArea {
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(56)
                    height: width
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: root.player?.isPlaying ? Translation.tr("Pause") : Translation.tr("Play")
                    onClicked: root.player?.togglePlaying()
                    Rectangle { anchors.fill: parent; radius: width / 2; color: "#F5F6F8" }
                    NIcon { anchors.centerIn: parent; text: root.player?.isPlaying ? "pause" : "play"; size: NihilStyle.s(24); color: "#0B0C0F" }
                }
                MouseArea {
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(36)
                    height: width
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: Translation.tr("Next")
                    onClicked: root.player?.next()
                    NIcon { anchors.centerIn: parent; text: "next"; size: NihilStyle.s(20); color: "#F5F6F8" }
                }
            }
        }

        Item {
            width: parent.width
            height: NihilStyle.s(36)
            visible: root.machine.length > 0
            NText {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: NihilStyle.s(4)
                anchors.verticalCenter: parent.verticalCenter
                text: root.machine
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
            }
        }
    }
}
