pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// Volume and brightness as two tiles over the bar: the glyph on the signal's, the level in strokes and the figure on the
// other. It shows when the level moves and leaves after a moment.
Scope {
    id: root

    property string kind: "volume"
    property bool shown: false
    // Kept a moment after it hides, so it fades instead of vanishing.
    property bool resident: false
    property bool ready: false
    readonly property var monitor: Brightness.getMonitorForScreen?.(GlobalStates.focusedScreen ?? Quickshell.screens[0]) ?? null
    readonly property real level: root.kind === "volume" ? (Audio.sink?.audio?.muted ? 0 : Audio.value ?? 0)
        : (root.monitor?.brightness ?? 0)
    readonly property string glyph: root.kind === "brightness" ? "light_mode"
        : (Audio.sink?.audio?.muted || root.level <= 0) ? "volume_off" : "volume_up"

    function show(kind: string): void {
        if (!root.ready || GameMode.suppressNiriToast) return
        root.kind = kind
        root.shown = true
        root.resident = true
        release.stop()
        hide.restart()
    }

    Timer { interval: 1500; running: true; onTriggered: root.ready = true }
    Timer { id: hide; interval: 1400; onTriggered: { root.shown = false; release.restart() } }
    Timer { id: release; interval: 400; onTriggered: root.resident = false }

    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() { if (Audio.ready) root.show("volume") }
        function onMutedChanged() { if (Audio.ready) root.show("volume") }
    }
    Connections {
        target: Brightness
        function onBrightnessChanged() { root.show("brightness") }
    }
    Connections {
        target: GlobalStates
        function onOsdVolumeOpenChanged() { if (GlobalStates.osdVolumeOpen) { root.show("volume"); GlobalStates.osdVolumeOpen = false } }
        function onOsdBrightnessOpenChanged() { if (GlobalStates.osdBrightnessOpen) { root.show("brightness"); GlobalStates.osdBrightnessOpen = false } }
    }

    LazyLoader {
        active: root.resident
        component: PanelWindow {
            screen: GlobalStates.focusedScreen ?? Quickshell.screens[0]
            color: "transparent"
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:nihilOsd"
            WlrLayershell.layer: WlrLayer.Overlay
            readonly property bool barBottom: Config.options?.nihil?.bar?.bottom ?? true
            anchors { bottom: barBottom; top: !barBottom }
            margins { bottom: barBottom ? NihilStyle.barZone : 0; top: barBottom ? 0 : NihilStyle.barZone }
            implicitWidth: pill.implicitWidth
            implicitHeight: pill.implicitHeight
            mask: Region {}

            Row {
                id: pill
                spacing: NihilStyle.seam
                opacity: root.shown ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: NihilStyle.calm } }

                NButton {
                    width: NihilStyle.s(56); height: width
                    square: true
                    interactive: false
                    lit: true
                    icon: root.glyph
                    iconSize: NihilStyle.s(26)
                }
                NTile {
                    id: meter
                    width: NihilStyle.s(320); height: NihilStyle.s(56)
                    NTicks {
                        x: meter.pad
                        anchors.verticalCenter: parent.verticalCenter
                        width: meter.width - meter.pad * 2 - figure.width - NihilStyle.s(14)
                        height: NihilStyle.s(24)
                        count: 32
                        level: root.level
                        marked: true
                    }
                    NFigure {
                        id: figure
                        anchors.right: parent.right
                        anchors.rightMargin: meter.pad
                        anchors.verticalCenter: parent.verticalCenter
                        width: NihilStyle.s(50)
                        horizontalAlignment: Text.AlignRight
                        size: NihilStyle.s(28)
                        text: Math.round(root.level * 100)
                        color: meter.ink
                    }
                }
            }
        }
    }
}
