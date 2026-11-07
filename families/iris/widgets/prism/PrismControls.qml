pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets

// Controls in Prism: the name on the tab, the volume on the flap, the switches as round keys across the pane (lit in
// the widget's colour while on) and the levels on the foot. A switch for something the machine lacks (no Wi-Fi card,
// no Bluetooth, no microphone) is not drawn at all.
PrismFolder {
    id: root

    readonly property var monitor: Brightness.getMonitorForScreen(root.QsWindow?.window?.screen ?? null)
    readonly property real volume: Math.min(1, Audio.value ?? 0)
    readonly property bool muted: Audio.sink?.audio?.muted ?? false
    readonly property var keys: [
        { key: "wifi", there: Network.wifi || Network.ethernet, lit: Network.ethernet || Network.wifiEnabled,
            glyph: Network.ethernet ? "lan" : Network.wifiEnabled ? "wifi" : "wifi_off",
            label: Network.ethernet ? Translation.tr("Ethernet") : (Network.networkName || Translation.tr("Wi-Fi")) },
        { key: "bluetooth", there: BluetoothStatus.available, lit: BluetoothStatus.enabled,
            glyph: BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled", label: Translation.tr("Bluetooth") },
        { key: "focus", there: true, lit: Notifications.manualDndActive,
            glyph: Notifications.manualDndActive ? "do_not_disturb_on" : "do_not_disturb_off", label: Translation.tr("Focus") },
        { key: "nightLight", there: true, lit: Hyprsunset.active, glyph: "nightlight", label: Translation.tr("Night light") },
        { key: "awake", there: true, lit: Idle.inhibit, glyph: "coffee", label: Translation.tr("Keep awake") },
        { key: "gameMode", there: true, lit: GameMode.active, glyph: "sports_esports", label: Translation.tr("Game mode") },
        { key: "mic", there: Audio.source !== null, lit: Audio.source !== null && !Audio.micMuted,
            glyph: Audio.micMuted ? "mic_off" : "mic", label: Translation.tr("Microphone") },
        { key: "darkMode", there: true, lit: Appearance.m3colors.darkmode,
            glyph: Appearance.m3colors.darkmode ? "dark_mode" : "light_mode", label: Translation.tr("Dark mode") }
    ].filter(entry => entry.there && Boolean(root.widget.familyOption("tile." + entry.key, true)))
    readonly property int perLine: root.small ? 3 : root.medium ? 5 : 4
    readonly property var shown: root.keys.slice(0, root.large ? 8 : root.perLine)
    readonly property real disc: root.pick(40, 46, 50)
    readonly property real gap: root.perLine > 1 ? (root.innerWidth - root.perLine * root.disc) / (root.perLine - 1) : 0
    readonly property bool levels: Boolean(root.widget.familyOption("sliders", true))
    readonly property string lit: root.keys.filter(entry => entry.lit).map(entry => entry.label).join(" · ")

    function flip(key: string): void {
        if (key === "wifi") Network.toggleWifi()
        else if (key === "bluetooth") { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled }
        else if (key === "focus") Notifications.toggleSilent()
        else if (key === "nightLight") Hyprsunset.toggle()
        else if (key === "awake") Idle.toggleInhibit()
        else if (key === "gameMode") GameMode.toggle()
        else if (key === "mic") Audio.toggleMicMute()
        else if (key === "darkMode") Appearance.toggleDarkMode()
    }

    tabGlyph: "toggle_on"
    tabText: Translation.tr("Controls")
    // The volume when there is an output; without one, how many switches are on.
    readonly property bool sounding: Audio.sink !== null
    readonly property int lights: root.keys.filter(entry => entry.lit).length
    readonly property string volumeGlyph: root.muted ? "volume_off" : root.volume < 0.34 ? "volume_mute" : root.volume < 0.67 ? "volume_down" : "volume_up"
    flapGlyph: root.sounding ? root.volumeGlyph : ""
    flapText: root.sounding ? Math.round(root.volume * 100) + "%" : Translation.tr("%1 on").arg(root.lights)

    // ── the pane: the switches, as round keys ──
    Repeater {
        model: root.shown
        Rectangle {
            id: key
            required property var modelData
            required property int index
            readonly property int line: Math.floor(key.index / root.perLine)
            readonly property int lines: Math.ceil(root.shown.length / root.perLine)
            readonly property real block: key.lines * root.disc + (key.lines - 1) * root.dp(12)
            x: Math.round(root.inset + (key.index % root.perLine) * (root.disc + root.gap))
            y: Math.round(root.paneMiddle - key.block / 2 + key.line * (root.disc + root.dp(12)))
            width: root.disc
            height: root.disc
            radius: width / 2
            color: key.modelData.lit ? root.shelf : keyHover.hovered ? root.fillHover : root.fill
            scale: keyTap.pressed ? 0.93 : 1
            Behavior on color { ColorAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
            Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
            MaterialSymbol {
                anchors.centerIn: parent
                text: key.modelData.glyph
                fill: key.modelData.lit ? 1 : 0
                iconSize: Math.round(root.disc * 0.46)
                color: key.modelData.lit ? root.inkOnShelf : root.ink
            }
            HoverHandler { id: keyHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { id: keyTap; gesturePolicy: TapHandler.WithinBounds; onTapped: root.flip(key.modelData.key) }
            Accessible.role: Accessible.CheckBox
            Accessible.name: key.modelData.label
            Accessible.checked: key.modelData.lit
        }
    }

    // ── the foot: the levels, and on the large face what is on ──
    IrisCapsuleSlider {
        id: volumeLevel
        visible: root.levels && root.sounding
        x: root.inset
        y: Math.round(root.footTop + (root.large ? root.dp(28) : (root.footHeight - height) / 2 - root.dp(2)))
        width: root.innerWidth
        height: root.pick(30, 30, 36)
        muted: root.muted
        icon: root.volumeGlyph
        value: root.volume
        fillColor: root.nothing ? root.ink : IrisStyle.appleAccentFill
        inkOnFill: root.nothing ? IrisStyle.surface : IrisStyle.appleInkOnAccentFill
        Accessible.name: Translation.tr("Volume")
        onMoved: next => Audio.setSinkVolume(next)
        onIconClicked: Audio.toggleMute()
    }
    IrisCapsuleSlider {
        visible: root.large && root.levels && root.monitor !== null && root.sounding
        x: root.inset
        y: volumeLevel.y + volumeLevel.height + root.dp(12)
        width: root.innerWidth
        height: volumeLevel.height
        icon: "light_mode"
        value: root.monitor?.brightness ?? 0
        fillColor: volumeLevel.fillColor
        inkOnFill: volumeLevel.inkOnFill
        Accessible.name: Translation.tr("Brightness")
        onMoved: next => root.monitor?.setBrightness(next)
    }
    // What is on: under the levels on the large face, in their place when the levels are off or there is no output.
    FaceText {
        readonly property bool alone: !volumeLevel.visible
        visible: root.large || alone
        face: root
        x: root.inset
        width: root.innerWidth
        y: Math.round(alone ? root.footTop + (root.footHeight - height) / 2 - root.dp(2) : root.height - root.inset - height)
        text: root.lit.length > 0 ? root.lit : Translation.tr("Everything is off")
        color: root.inkSecondary
        size: 13
        weight: Font.Medium
        elide: Text.ElideRight
    }
}
