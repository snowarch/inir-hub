pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// Volume and brightness as one capsule of glass: the level is a filament of light with a flare at its tip. It comes up
// when a level moves and leaves after a moment.
Scope {
    id: root

    readonly property string position: Config.options?.nihil?.osd?.position ?? "bottom"
    readonly property bool enabled: root.position !== "off"
    readonly property bool atTop: root.position.startsWith("top")
    readonly property bool atBottom: root.position.startsWith("bottom")
    readonly property bool atLeft: root.position.endsWith("Left")
    readonly property bool atRight: root.position.endsWith("Right")
    readonly property int holdMs: Config.options?.nihil?.osd?.holdMs ?? 1400
    readonly property real clearance: NihilStyle.barHeight + NihilStyle.edge * 2

    property string kind: "volume"
    property bool shown: false
    // Kept a moment after it hides, so it fades instead of vanishing.
    property bool resident: false
    property bool ready: false

    readonly property var monitor: Brightness.getMonitorForScreen?.(GlobalStates.focusedScreen ?? Quickshell.screens[0]) ?? null
    readonly property bool muted: root.kind === "volume" && (Audio.sink?.audio?.muted ?? false)
    readonly property real level: root.kind === "volume" ? (root.muted ? 0 : Audio.value ?? 0) : (root.monitor?.brightness ?? 0)
    readonly property string glyph: root.kind === "brightness" ? "light_mode"
        : (root.muted || root.level <= 0) ? "volume_off"
        : root.level < 0.5 ? "volume_down" : "volume_up"

    function show(kind: string): void {
        if (!root.enabled || !root.ready || GameMode.suppressNiriToast)
            return
        root.kind = kind
        root.shown = true
        root.resident = true
        release.stop()
        hide.restart()
    }

    // Levels settle while the shell starts; nothing shows for those.
    Timer { interval: 1500; running: true; onTriggered: root.ready = true }
    Timer { id: hide; interval: root.holdMs; onTriggered: { root.shown = false; release.restart() } }
    Timer { id: release; interval: NihilStyle.slow; onTriggered: root.resident = false }

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

    LazyLoader {
        active: root.resident
        component: PanelWindow {
            screen: GlobalStates.focusedScreen ?? Quickshell.screens[0]
            color: "transparent"
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:nihilOsd"
            WlrLayershell.layer: WlrLayer.Overlay
            anchors { top: root.atTop; bottom: root.atBottom; left: root.atLeft; right: root.atRight }
            margins {
                top: root.atTop ? root.clearance : 0
                bottom: root.atBottom ? root.clearance : 0
                left: root.atLeft ? NihilStyle.edge : 0
                right: root.atRight ? NihilStyle.edge : 0
            }
            implicitWidth: capsule.width + NihilStyle.s(48)
            implicitHeight: capsule.height + NihilStyle.s(48)
            mask: Region {}
            BackgroundEffect.blurRegion: CompositorService.blurRegions && NihilStyle.blur ? capsule.region : null

            NGlass {
                id: capsule
                anchors.centerIn: parent
                width: NihilStyle.s(340)
                height: NihilStyle.s(56)
                radius: height / 2
                opacity: root.shown ? 1 : 0
                scale: root.shown ? 1 : 0.94
                Behavior on opacity { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }

                NIcon {
                    id: mark
                    x: NihilStyle.s(20)
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.glyph
                    size: NihilStyle.s(22)
                    color: NihilStyle.ink
                }

                Item {
                    id: track
                    anchors.left: mark.right
                    anchors.leftMargin: NihilStyle.s(16)
                    anchors.right: figure.left
                    anchors.rightMargin: NihilStyle.s(14)
                    anchors.verticalCenter: parent.verticalCenter
                    height: NihilStyle.s(2)

                    readonly property real reach: track.width * Math.max(0, Math.min(1, root.level))

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: NihilStyle.inkFaint
                    }
                    Rectangle {
                        width: track.reach
                        height: parent.height
                        radius: height / 2
                        color: NihilStyle.accent
                        Behavior on width { NumberAnimation { duration: NihilStyle.quick; easing.type: Easing.OutCubic } }
                    }
                    // The flare: a soft halo and a hot core riding the tip of the filament.
                    Repeater {
                        model: [{ size: 26, alpha: 0.16 }, { size: 13, alpha: 0.34 }, { size: 5, alpha: 1 }]
                        delegate: Rectangle {
                            required property var modelData
                            width: NihilStyle.s(modelData.size)
                            height: width
                            radius: width / 2
                            x: track.reach - width / 2
                            y: (track.height - height) / 2
                            color: modelData.alpha === 1 ? NihilStyle.ink : NihilStyle.accent
                            opacity: root.level > 0 ? modelData.alpha : 0
                            Behavior on x { NumberAnimation { duration: NihilStyle.quick; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                NText {
                    id: figure
                    anchors.right: parent.right
                    anchors.rightMargin: NihilStyle.s(20)
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(34)
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(root.level * 100)
                    font.pixelSize: NihilStyle.textBody
                    figures: true
                    color: NihilStyle.inkSoft
                }
            }
        }
    }
}
