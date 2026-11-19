pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// Volume and brightness, on a tag pulled from the band when a level moves: the glyph, the ruler and the figure. The hand
// keeps it out and can set the level on it.
Item {
    id: root

    property var screen: null
    // This screen's sheet is the one that shows it.
    property bool here: false

    readonly property string position: Config.options?.nihil?.osd?.position ?? "bottom"
    readonly property bool enabled_: root.position !== "off"
    readonly property bool atStart: root.position.endsWith("Left")
    readonly property bool atEnd: root.position.endsWith("Right")
    readonly property int holdMs: Config.options?.nihil?.osd?.holdMs ?? 1400

    property string kind: "volume"
    property bool shown: false
    property bool ready: false
    readonly property bool wanted: root.shown && root.here

    readonly property var monitor: Brightness.getMonitorForScreen?.(root.screen) ?? null
    readonly property bool muted: root.kind === "volume" && (Audio.sink?.audio?.muted ?? false)
    readonly property real level: root.kind === "volume" ? (root.muted ? 0 : Audio.value ?? 0) : (root.monitor?.brightness ?? 0)
    readonly property string glyph: root.kind === "brightness" ? "light_mode"
        : (root.muted || root.level <= 0) ? "volume_off"
        : root.level < 0.5 ? "volume_down" : "volume_up"
    // Where the needle stands on the tag: the sheet's light gathers under it.
    readonly property real needle: ruler.x + ruler.width * NihilStyle.clamp(root.level, 0, 1)

    implicitWidth: NihilStyle.s(420)
    implicitHeight: NihilStyle.s(72)
    width: implicitWidth
    height: implicitHeight

    function show(kind: string): void {
        if (!root.enabled_ || !root.ready || !root.here || GameMode.suppressNiriToast)
            return
        root.kind = kind
        root.shown = true
        if (!hand.hovered) hide.restart()
    }

    // Levels settle while the shell starts; nothing shows for those.
    Timer { interval: 1500; running: true; onTriggered: root.ready = true }
    Timer { id: hide; interval: root.holdMs; onTriggered: root.shown = false }

    HoverHandler {
        id: hand
        onHoveredChanged: {
            if (hand.hovered) hide.stop()
            else if (root.shown) hide.restart()
        }
    }

    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged(): void { if (Audio.ready) root.show("volume") }
        function onMutedChanged(): void { if (Audio.ready) root.show("volume") }
    }
    Connections {
        target: Brightness
        function onBrightnessChanged(): void { root.show("brightness") }
    }
    Connections {
        target: GlobalStates
        function onOsdVolumeOpenChanged(): void {
            if (!GlobalStates.osdVolumeOpen) return
            root.show("volume")
            GlobalStates.osdVolumeOpen = false
        }
        function onOsdBrightnessOpenChanged(): void {
            if (!GlobalStates.osdBrightnessOpen) return
            root.show("brightness")
            GlobalStates.osdBrightnessOpen = false
        }
    }

    NIcon {
        id: mark
        x: NihilStyle.s(22)
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        size: NihilStyle.s(20)
        color: root.muted ? NihilStyle.danger : NihilStyle.ink
    }
    NSlider {
        id: ruler
        x: mark.x + mark.width + NihilStyle.s(12)
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - NihilStyle.s(76)
        height: NihilStyle.s(36)
        name: root.kind === "volume" ? Translation.tr("Sound") : Translation.tr("Light")
        value: root.level
        onMoved: value => {
            if (root.kind === "volume") Audio.setSinkVolume(value)
            else root.monitor?.setBrightness(Math.max(0.01, value))
        }
    }
    NText {
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.s(22)
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(root.level * 100)
        figures: true
        font.pixelSize: NihilStyle.s(26)
        font.weight: Font.ExtraLight
    }
}
