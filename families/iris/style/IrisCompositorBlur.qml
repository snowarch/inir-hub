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
    property int radius: 32
    property string background: "glass"
    // Rin Liquid Glass optical parameters (rin.appearance.toml).
    property real liquidBevel: 64
    property real liquidDepth: 210
    property real liquidIor: 1.52
    property real liquidDispersion: 0.40
    property real liquidFrost: 0.40
    property real liquidBulge: 0.05
    property var elsewhere: []
    readonly property bool usable: root.available && root.enabled
    // Whether the compositor blurs behind the shell at all: Niri 26.04+ and Rin through the background-effect regions
    // each surface publishes, Umbriel through the layer rule written below (it has no background-effect protocol).
    readonly property bool active: CompositorService.isUmbriel
        ? Appearance.effectsEnabled && (Config.options?.performance?.compositorBlur ?? true) && root.umbrielRules
        : CompositorService.isRin
            ? Appearance.compositorBlurActive && root.enabled
            : Appearance.compositorBlurActive
    // The theme module writes Umbriel's blur rules only into a config that is iNiR's (15-umbriel.sh). Under any other
    // (a first login, a person's own), nothing blurs behind the shell: compositor glass would leave a thin veil over a
    // sharp desktop, so iRiS stays solid instead.
    property bool umbrielRules: false
    FileView {
        id: umbrielConfig
        path: CompositorService.isUmbriel ? Directories.configPath + "/umbriel/config.toml" : ""
        watchChanges: true
        onFileChanged: umbrielConfig.reload()
        onLoaded: root.umbrielRules = /^# iNiR — Umbriel configuration/m.test(umbrielConfig.text())
        onLoadFailed: root.umbrielRules = false
    }

    function _applyRinState(state: var): void {
        if (!state || typeof state !== "object") return
        if (typeof state.blur === "boolean") root.enabled = state.blur
        if (typeof state["blur-radius"] === "number") root.radius = Math.round(state["blur-radius"])
        if (typeof state.background === "string" && state.background.length > 0) root.background = state.background
        if (typeof state["liquid-bevel"] === "number") root.liquidBevel = Math.round(state["liquid-bevel"])
        if (typeof state["liquid-depth"] === "number") root.liquidDepth = Math.round(state["liquid-depth"])
        if (typeof state["liquid-ior"] === "number") root.liquidIor = state["liquid-ior"]
        if (typeof state["liquid-dispersion"] === "number") root.liquidDispersion = state["liquid-dispersion"]
        if (typeof state["liquid-frost"] === "number") root.liquidFrost = state["liquid-frost"]
        if (typeof state["liquid-bulge"] === "number") root.liquidBulge = state["liquid-bulge"]
    }

    // Rin says which settings domains changed, whoever wrote them: read the appearance again then.
    Connections {
        target: NiriService
        enabled: CompositorService.isRin
        function onRinSettingsChanged(domains: var): void {
            if (domains.includes("rin.appearance")) root.reload()
        }
    }

    function reload(): void {
        if (CompositorService.isRin && !rinReader.running) rinReader.running = true
        else if (CompositorService.niriNative && !reader.running) reader.running = true
    }
    Component.onCompleted: root.reload()

    // Umbriel blurs layer surfaces by its own layer rules: the theme module writes the one compositor glass asks for
    // into the generated file Umbriel includes, so picking the mode is all it takes.
    readonly property string glassMode: String(Config.options?.iris?.appearance?.glass?.mode ?? "off")
    onGlassModeChanged: if (CompositorService.isUmbriel && Config.ready && !umbrielRules.running) umbrielRules.running = true
    Process {
        id: umbrielRules
        command: ["bash", Quickshell.shellPath("scripts/colors/modules/15-umbriel.sh")]
    }

    Process {
        id: rinReader
        command: ["rin", "msg", "settings", "read", "rin.appearance"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const state = JSON.parse(text.trim())
                    if (!state || state.error) return
                    root.available = true
                    root._applyRinState(state)
                } catch (e) {}
            }
        }
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
