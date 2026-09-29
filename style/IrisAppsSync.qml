pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.services

// Hands the shell's own surface to the colour pipeline, so the terminals and apps sit on the material the person chose.
Item {
    id: root
    visible: false

    readonly property string path: `${Directories.stateUserPath}/generated/iris-surface.json`
    // The wallpaper colour theme only: a preset is its own palette, and the Theme material reads colors.json back.
    readonly property bool wanted: ThemeService.irisMaterialApps && ThemeService.isAutoTheme && IrisStyle.materialName !== "theme"
    readonly property string seed: root.wanted ? root.hex(IrisStyle.appsSurface) : ""
    property string applied: ""
    property bool loaded: false

    function hex(c: color): string {
        const part = v => ("0" + Math.round(v * 255).toString(16)).slice(-2)
        return "#" + part(c.r) + part(c.g) + part(c.b)
    }

    // A slider or a scheme switch settles before the pipeline runs once: the apps are recoloured by a full generation.
    Timer {
        id: settle
        interval: 350
        onTriggered: root.push()
    }
    function push(): void {
        if (!root.loaded || root.seed === root.applied) return
        root.applied = root.seed
        Quickshell.execDetached(["/usr/bin/bash", "-c", 'mkdir -p "$(dirname "$1")" && printf \'{"seed": "%s"}\\n\' "$2" > "$1"', "iris-surface", root.path, root.seed])
        ThemeService.regenerateAutoTheme()
    }
    onSeedChanged: if (root.loaded) settle.restart()

    FileView {
        path: root.path
        printErrors: false
        onLoaded: {
            try { root.applied = String(JSON.parse(text()).seed ?? "") } catch (e) { root.applied = "" }
            root.loaded = true
            if (root.seed !== root.applied) settle.restart()
        }
        onLoadFailed: {
            root.applied = ""
            root.loaded = true
            if (root.seed !== "") settle.restart()
        }
    }
}
