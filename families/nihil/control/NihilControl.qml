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

// The machine, on the slab pulled from the band's right end: the two levels, the two radios, six keys, what plays and the
// way out. What is on is lit from below. A radio's arrow and the sound's open their lists on the same slab.
Item {
    id: root

    property var screen: null
    property bool flipped: false
    property real room: 0
    property bool open: false

    // The list on show: "wifi", "bluetooth", "output" or "input". Empty is the controls themselves.
    property string page: ""
    onOpenChanged: if (!root.open) root.page = ""

    readonly property real side: NihilStyle.s(20)
    readonly property real inner: root.width - root.side * 2
    readonly property real headPad: NihilStyle.s(16)
    // Where the light gathers, under the last row.
    readonly property real footPad: NihilStyle.s(54)
    readonly property var monitor: Brightness.getMonitorForScreen(root.screen)
    readonly property bool hasBrightness: Number.isFinite(root.monitor?.brightness)
    readonly property bool muted: Audio.sink?.audio?.muted ?? false
    readonly property bool airplane: !Network.wifiEnabled && !BluetoothStatus.enabled
    readonly property var player: MprisController.activePlayer

    implicitWidth: NihilStyle.s(448)
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
        if (!Battery.available)
            return DateTime.uptime ? Translation.tr("Up for %1").arg(DateTime.uptime) : ""
        const share = Math.round(Battery.percentage * 100) + " %"
        const left = Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty
        if (!(left > 0))
            return Battery.isCharging ? Translation.tr("%1, charging").arg(share) : share
        return (Battery.isCharging ? Translation.tr("%1, full in %2") : Translation.tr("%1, %2 left")).arg(share).arg(root.span(left))
    }

    // A level: its glyph (which mutes), the word, the ruler and the figure. A list hides behind the figure.
    component Level: NWell {
        id: level

        property string word: ""
        property string glyph: ""
        property real value: 0
        property bool opens: false
        property bool keyed: false

        signal tapped()
        signal moved(real value)
        signal opened()

        width: root.inner
        height: NihilStyle.s(58)
        radius: NihilStyle.rCard
        hovered: under.hovered

        HoverHandler { id: under }

        MouseArea {
            id: keyArea
            x: NihilStyle.s(8)
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(32)
            height: width
            enabled: level.keyed
            hoverEnabled: true
            cursorShape: level.keyed ? Qt.PointingHandCursor : Qt.ArrowCursor
            Accessible.role: Accessible.Button
            Accessible.name: level.word
            onClicked: level.tapped()
            NIcon {
                anchors.centerIn: parent
                text: level.glyph
                size: NihilStyle.s(20)
                color: keyArea.containsMouse ? NihilStyle.accent : NihilStyle.ink
            }
        }
        NText {
            x: NihilStyle.s(46)
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(66)
            text: level.word
        }
        NSlider {
            x: NihilStyle.s(118)
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x - NihilStyle.s(50)
            height: NihilStyle.s(30)
            name: level.word
            value: level.value
            onMoved: value => level.moved(value)
        }
        NText {
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(16)
            anchors.verticalCenter: parent.verticalCenter
            visible: !more.visible
            text: Math.round(level.value * 100)
            figures: true
            font.pixelSize: NihilStyle.s(15)
        }
        NButton {
            id: more
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(8)
            anchors.verticalCenter: parent.verticalCenter
            visible: level.opens && under.hovered
            width: NihilStyle.s(32)
            height: width
            tone: "transparent"
            icon: "chevron_right"
            iconSize: NihilStyle.s(16)
            Accessible.name: Translation.tr("More")
            onClicked: level.opened()
        }
    }

    // A radio: its glyph and name, what it is on under them. Lit while on.
    component Radio: MouseArea {
        id: radio

        property string glyph: ""
        property string name: ""
        property string note: ""
        property bool on: false
        property bool usable: true

        signal tapped()
        signal opened()

        width: (root.inner - NihilStyle.gap) / 2
        height: NihilStyle.s(84)
        enabled: radio.usable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        opacity: radio.usable ? 1 : 0.45
        Accessible.role: Accessible.Button
        Accessible.name: radio.name
        Accessible.checkable: true
        Accessible.checked: radio.on
        onClicked: radio.tapped()

        NWell {
            anchors.fill: parent
            radius: NihilStyle.rCard
            lit: radio.on ? 1 : 0
            hovered: radio.containsMouse
        }
        NIcon {
            id: radioGlyph
            x: NihilStyle.s(16)
            y: NihilStyle.s(14)
            text: radio.glyph
            size: NihilStyle.s(22)
        }
        NText {
            anchors.left: radioGlyph.right
            anchors.leftMargin: NihilStyle.s(10)
            anchors.right: arrow.left
            anchors.verticalCenter: radioGlyph.verticalCenter
            text: radio.name
            font.pixelSize: NihilStyle.s(15)
            font.weight: Font.Medium
        }
        NText {
            x: NihilStyle.s(16)
            y: NihilStyle.s(44)
            width: parent.width - x * 2
            text: radio.note
            font.pixelSize: NihilStyle.textSmall
            color: NihilStyle.inkSoft
        }
        NButton {
            id: arrow
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(8)
            y: NihilStyle.s(9)
            width: NihilStyle.s(32)
            height: width
            visible: radio.usable
            opacity: radio.containsMouse || arrow.containsMouse ? 1 : 0
            tone: "transparent"
            icon: "chevron_right"
            iconSize: NihilStyle.s(16)
            Accessible.name: Translation.tr("More")
            onClicked: radio.opened()
        }
    }

    // One of the six keys: the glyph over its word.
    component Key: MouseArea {
        id: key

        property string glyph: ""
        property string word: ""
        property bool on: false
        property bool usable: true

        signal tapped()

        width: (root.inner - NihilStyle.gap * 2) / 3
        height: NihilStyle.s(76)
        enabled: key.usable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        opacity: key.usable ? 1 : 0.4
        Accessible.role: Accessible.Button
        Accessible.name: key.word
        Accessible.checkable: true
        Accessible.checked: key.on
        onClicked: key.tapped()

        NWell {
            anchors.fill: parent
            radius: NihilStyle.rCard
            lit: key.on ? 0.9 : 0
            hovered: key.containsMouse
        }
        NIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            y: NihilStyle.s(14)
            text: key.glyph
            size: NihilStyle.s(20)
            color: key.on ? NihilStyle.ink : NihilStyle.inkSoft
        }
        NText {
            anchors.horizontalCenter: parent.horizontalCenter
            y: NihilStyle.s(44)
            width: Math.min(implicitWidth, parent.width - NihilStyle.s(12))
            text: key.word
            font.pixelSize: NihilStyle.textSmall
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

        Column {
            width: parent.width
            spacing: NihilStyle.gap
            Level {
                word: Translation.tr("Sound")
                glyph: root.muted ? "volume_off" : "volume_up"
                value: root.muted ? 0 : Audio.value
                keyed: true
                opens: true
                onTapped: if (Audio.sink?.audio) Audio.sink.audio.muted = !root.muted
                onMoved: value => Audio.setSinkVolume(value)
                onOpened: root.page = "output"
            }
            Level {
                visible: root.hasBrightness
                word: Translation.tr("Light")
                glyph: "light_mode"
                value: root.hasBrightness ? root.monitor.brightness : 0
                onMoved: value => root.monitor?.setBrightness(Math.max(0.01, value))
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
            Grid {
                columns: 3
                spacing: NihilStyle.gap
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

        NWell {
            visible: !!root.player
            width: parent.width
            height: NihilStyle.s(92)
            radius: NihilStyle.r(20)

            ClippingRectangle {
                id: art
                x: NihilStyle.s(14)
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(64)
                height: width
                radius: NihilStyle.r(14)
                color: NihilStyle.pieceRaised
                NIcon {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready
                    text: "music_note"
                    size: NihilStyle.s(24)
                    color: NihilStyle.inkFaint
                }
                Image {
                    id: cover
                    anchors.fill: parent
                    asynchronous: true
                    sourceSize: Qt.size(art.width * 2, art.height * 2)
                    fillMode: Image.PreserveAspectCrop
                    source: root.player?.trackArtUrl ?? ""
                }
            }
            Column {
                anchors.left: art.right
                anchors.leftMargin: NihilStyle.s(14)
                anchors.right: transport.left
                anchors.rightMargin: NihilStyle.gap
                anchors.verticalCenter: parent.verticalCenter
                spacing: NihilStyle.s(3)
                NText {
                    width: parent.width
                    text: root.player?.trackTitle ?? ""
                    font.pixelSize: NihilStyle.s(15)
                    font.weight: Font.Medium
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
                anchors.rightMargin: NihilStyle.s(8)
                anchors.verticalCenter: parent.verticalCenter
                spacing: NihilStyle.s(2)
                NButton {
                    anchors.verticalCenter: parent.verticalCenter
                    tone: "transparent"
                    radius: width / 2
                    icon: "previous"
                    iconSize: NihilStyle.s(20)
                    Accessible.name: Translation.tr("Previous")
                    onClicked: root.player?.previous()
                }
                NButton {
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(44)
                    height: width
                    radius: width / 2
                    lit: true
                    icon: root.player?.isPlaying ? "pause" : "play"
                    iconSize: NihilStyle.s(20)
                    Accessible.name: root.player?.isPlaying ? Translation.tr("Pause") : Translation.tr("Play")
                    onClicked: root.player?.togglePlaying()
                }
                NButton {
                    anchors.verticalCenter: parent.verticalCenter
                    tone: "transparent"
                    radius: width / 2
                    icon: "next"
                    iconSize: NihilStyle.s(20)
                    Accessible.name: Translation.tr("Next")
                    onClicked: root.player?.next()
                }
            }
        }

        Item {
            width: parent.width
            height: NihilStyle.s(36)
            NText {
                anchors.left: parent.left
                anchors.right: ways.left
                anchors.leftMargin: NihilStyle.s(4)
                anchors.rightMargin: NihilStyle.gap
                anchors.verticalCenter: parent.verticalCenter
                text: root.machine
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
            }
            Row {
                id: ways
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: NihilStyle.s(2)
                NButton {
                    radius: width / 2
                    tone: "transparent"
                    icon: "settings"
                    Accessible.name: Translation.tr("Settings")
                    onClicked: {
                        NihilState.controlOpen = false
                        Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "settings"])
                    }
                }
                NButton {
                    radius: width / 2
                    tone: "transparent"
                    icon: "lock"
                    Accessible.name: Translation.tr("Lock")
                    onClicked: {
                        NihilState.controlOpen = false
                        Session.lock()
                    }
                }
                NButton {
                    radius: width / 2
                    tone: "transparent"
                    icon: "power_settings_new"
                    Accessible.name: Translation.tr("Power")
                    onClicked: {
                        NihilState.controlOpen = false
                        NihilState.toggle("power")
                    }
                }
            }
        }
    }
}
