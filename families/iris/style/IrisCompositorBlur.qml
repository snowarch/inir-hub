pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common

Singleton {
    id: root

    property bool available: true
    property bool enabled: true
    property string strength: "balanced"
    property real noise: 0.02
    property real saturation: 1.5
    property var elsewhere: []
    readonly property bool usable: root.available && root.enabled

    function reload(): void {
        if (CompositorService.niriNative && !reader.running) reader.running = true
    }
    Component.onCompleted: root.reload()

    // Umbriel blurs layer surfaces by its own layer rules: the theme module writes the one compositor glass asks for
    // into the generated file Umbriel includes, so picking the mode is all it takes.
    readonly property string glassMode: String(Config.options?.iris?.appearance?.glass?.mode ?? "wallpaper")
    onGlassModeChanged: if (CompositorService.isUmbriel && Config.ready && !umbrielRules.running) umbrielRules.running = true
    Process {
        id: umbrielRules
        command: ["bash", Quickshell.shellPath("scripts/colors/modules/15-umbriel.sh")]
    }

    Process {
        id: reader
        command: [Quickshell.shellPath("scripts/lib/accel-run"), "niri-config", "get-blur"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const state = JSON.parse(text)
                    if (state.error) return
                    root.available = state.available
                    root.enabled = state.enabled
                    root.strength = state.strength
                    root.noise = state.noise
                    root.saturation = state.saturation
                    root.elsewhere = state.elsewhere ?? []
                } catch (e) {}
            }
        }
    }
}
