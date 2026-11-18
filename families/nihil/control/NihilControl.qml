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

// Quick controls on one pane of glass in the corner: the two radios, what plays, the two levels and eight keys. A radio's
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

    // A radio: its glyph lit while on, what it is joined to, the chevron to its list.
    component Radio: Rectangle {
        id: radio

        property string glyph: ""
        property string name: ""
        property string state_: ""
        property bool on: false
        property bool usable: true

        signal tapped()
        signal opened()

        width: (root.inner - NihilStyle.gap) / 2
        height: NihilStyle.s(64)
        radius: NihilStyle.rCard
        color: tap.containsMouse ? NihilStyle.pieceRaised : NihilStyle.piece
        opacity: radio.usable ? 1 : 0.5
        Behavior on color { ColorAnimation { duration: NihilStyle.quick } }

        MouseArea {
            id: tap
            anchors.fill: parent
            enabled: radio.usable
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: radio.tapped()
        }

        Rectangle {
            id: disc
            x: NihilStyle.s(10)
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(38)
            height: NihilStyle.s(38)
            radius: width / 2
            color: radio.on ? NihilStyle.accent : NihilStyle.pieceRaised
            Behavior on color { ColorAnimation { duration: NihilStyle.quick } }

            NIcon {
                anchors.centerIn: parent
                text: radio.glyph
                size: NihilStyle.s(20)
                color: radio.on ? NihilStyle.onAccent : NihilStyle.ink
            }
        }

        Column {
            anchors.left: disc.right
            anchors.leftMargin: NihilStyle.s(10)
            anchors.right: more.left
            anchors.verticalCenter: parent.verticalCenter

            NText {
                width: parent.width
                text: radio.name
                elide: Text.ElideRight
                font.weight: Font.Medium
            }
            NText {
                width: parent.width
                text: radio.state_
                elide: Text.ElideRight
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
            }
        }

        NButton {
            id: more
            visible: radio.usable
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(4)
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(28)
            height: NihilStyle.s(28)
            icon: "chevron_right"
            iconSize: NihilStyle.s(16)
            onClicked: radio.opened()
        }
    }

    // A level: its key on the left, the slider, and the way to its list when it has one.
    component Level: Row {
        id: level

        property string glyph: ""
        property real value: 0
        property bool lit: false
        property bool opens: false

        signal keyed()
        signal moved(real value)
        signal opened()

        width: root.inner
        height: NihilStyle.s(36)
        spacing: NihilStyle.s(8)

        NButton {
            width: NihilStyle.s(36)
            height: NihilStyle.s(36)
            icon: level.glyph
            lit: level.lit
            onClicked: level.keyed()
        }
        NSlider {
            anchors.verticalCenter: parent.verticalCenter
            width: level.width - NihilStyle.s(36) - NihilStyle.s(8)
                - (level.opens ? NihilStyle.s(36) : 0)
            value: level.value
            onMoved: value => level.moved(value)
        }
        NButton {
            visible: level.opens
            width: NihilStyle.s(28)
            height: NihilStyle.s(36)
            icon: "chevron_right"
            iconSize: NihilStyle.s(16)
            onClicked: level.opened()
        }
    }

    // One of the eight keys: a round glyph over its word.
    component Key: Column {
        id: key

        property string glyph: ""
        property string word: ""
        property bool on: false
        property bool usable: true

        signal tapped()

        width: root.inner / 4
        spacing: NihilStyle.s(4)
        opacity: key.usable ? 1 : 0.5

        NButton {
            anchors.horizontalCenter: parent.horizontalCenter
            enabled: key.usable
            width: NihilStyle.s(52)
            height: NihilStyle.s(52)
            radius: width / 2
            icon: key.glyph
            iconSize: NihilStyle.s(22)
            lit: key.on
            onClicked: key.tapped()
        }
        NText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: key.word
            elide: Text.ElideRight
            font.pixelSize: NihilStyle.textSmall
            color: NihilStyle.inkSoft
        }
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
            spacing: NihilStyle.s(14)

            Row {
                spacing: NihilStyle.gap

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

            Item {
                visible: !!root.player
                width: root.inner
                height: visible ? NihilStyle.s(44) : 0

                Column {
                    anchors.left: parent.left
                    anchors.right: transport.left
                    anchors.rightMargin: NihilStyle.gap
                    anchors.verticalCenter: parent.verticalCenter

                    NText {
                        width: parent.width
                        text: root.player?.trackTitle ?? ""
                        elide: Text.ElideRight
                        font.weight: Font.Medium
                    }
                    NText {
                        width: parent.width
                        text: root.player?.trackArtist ?? ""
                        elide: Text.ElideRight
                        font.pixelSize: NihilStyle.textSmall
                        color: NihilStyle.inkSoft
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
                glyph: root.muted ? "volume_mute" : "volume_up"
                lit: root.muted
                value: root.muted ? 0 : Audio.value
                opens: true
                onKeyed: if (Audio.sink?.audio) Audio.sink.audio.muted = !root.muted
                onMoved: value => Audio.setSinkVolume(value)
                onOpened: root.page = "output"
            }
            Level {
                visible: root.hasBrightness
                glyph: "light_mode"
                value: root.hasBrightness ? root.monitor.brightness : 0
                onMoved: value => root.monitor?.setBrightness(Math.max(0.01, value))
            }

            Grid {
                columns: 4
                rowSpacing: NihilStyle.s(10)

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
