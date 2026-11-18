pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// Volume and brightness as a pill over the bar: the glyph on a round piece, the level as a row of dots lit from the
// left, the figure at the end. It shows when the level moves and leaves after a moment.
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
            implicitWidth: pill.width
            implicitHeight: pill.height
            mask: Region {}

            NButton {
                id: pill
                width: NihilStyle.s(320)
                height: NihilStyle.button
                opacity: root.shown ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: NihilStyle.calm } }
                NButton {
                    x: NihilStyle.s(4); y: NihilStyle.s(4)
                    width: parent.height - NihilStyle.s(8); height: width
                    lit: true
                    icon: root.glyph
                    iconSize: NihilStyle.s(20)
                }
                DotGrid {
                    x: parent.height + NihilStyle.s(4)
                    width: parent.width - x - figure.width - NihilStyle.s(24)
                    anchors.verticalCenter: parent.verticalCenter
                    height: width / 16
                    columns: 16
                    rows: 1
                    level: root.level
                    columnFirst: false
                    litColor: NihilStyle.ink
                    offColor: NihilStyle.pieceRaised
                }
                NText {
                    id: figure
                    anchors.right: parent.right
                    anchors.rightMargin: NihilStyle.s(18)
                    anchors.verticalCenter: parent.verticalCenter
                    mono: true
                    text: Math.round(root.level * 100)
                }
            }
        }
    }
}
