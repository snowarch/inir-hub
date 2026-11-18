pragma Singleton

import QtQuick
import Quickshell
import qs.modules.common

// Every measure, ink and material of NiHiL, all of it driven by `nihil.look`.
Singleton {
    id: root

    readonly property var look: Config.options?.nihil?.look ?? ({})
    function opt(key: string, fallback: var): var {
        const value = root.look?.[key]
        return value === undefined || value === null ? fallback : value
    }
    function clamp(value: real, low: real, high: real): real { return Math.max(low, Math.min(high, value)) }

    readonly property var m3: Appearance.m3colors
    readonly property bool dark: root.m3?.darkmode ?? true

    readonly property var palettes: ({
        obsidian: { base: "#0A0A0A", mid: "#536878", high: "#E5E4E2", flareA: "#8CB9CC", flareB: "#E5E4E2" },
        amber: { base: "#070B1A", mid: "#1B2A55", high: "#F2A33C", flareA: "#F2A33C", flareB: "#E8542B" },
        azure: { base: "#141414", mid: "#004A6B", high: "#BFD8E3", flareA: "#00638E", flareB: "#8CB9CC" },
        ember: { base: "#0D0706", mid: "#5C1410", high: "#FF7A3C", flareA: "#FF4A1C", flareB: "#FFB347" },
        ultramarine: { base: "#05061A", mid: "#1A1FB8", high: "#E08A4F", flareA: "#2A35E8", flareB: "#D9793F" }
    })
    readonly property string paletteName: String(root.opt("palette", "obsidian"))
    readonly property var palette: root.paletteName === "wallpaper"
        ? { base: root.m3.m3surface, mid: root.m3.m3primaryContainer, high: root.m3.m3primary,
            flareA: root.m3.m3primary, flareB: root.m3.m3tertiary }
        : (root.palettes[root.paletteName] ?? root.palettes.obsidian)

    readonly property color base: root.palette.base
    readonly property color mid: root.palette.mid
    readonly property color high: root.palette.high
    readonly property color flareA: root.palette.flareA
    readonly property color flareB: root.palette.flareB

    readonly property color ink: root.dark ? "#F4F3F0" : "#101114"
    readonly property color inkSoft: Qt.alpha(root.ink, 0.66)
    readonly property color inkFaint: Qt.alpha(root.ink, 0.38)
    readonly property color accent: root.high
    readonly property color onAccent: (0.299 * root.accent.r + 0.587 * root.accent.g + 0.114 * root.accent.b) > 0.55
        ? "#0A0A0A" : "#FFFFFF"
    readonly property color line: Qt.alpha(root.ink, 0.1)
    readonly property color piece: Qt.alpha(root.ink, 0.07)
    readonly property color pieceRaised: Qt.alpha(root.ink, 0.13)
    readonly property color scrim: Qt.alpha("#000000", 0.45)

    // Glass
    readonly property real glassOpacity: root.clamp(Number(root.opt("glass", 0.42)), 0.05, 1)
    readonly property color glassTint: root.dark
        ? Qt.alpha(Qt.tint(root.base, Qt.alpha(root.mid, 0.16)), root.glassOpacity)
        : Qt.alpha("#EEF0F2", root.glassOpacity + 0.2)
    readonly property bool blur: Boolean(root.opt("blur", true))
    readonly property real glassGrain: Number(root.opt("grain", 0.5))
    readonly property real glassRim: Number(root.opt("rim", 0.7))
    readonly property real glassFlare: Number(root.opt("flare", 0.6))

    // Measure
    readonly property real scale: root.clamp(Number(root.opt("scale", 1)), 0.75, 1.5)
    function s(px: real): real { return Math.round(px * root.scale) }
    readonly property real corners: root.clamp(Number(root.opt("corners", 1)), 0, 2)
    function r(px: real): real { return Math.round(px * root.corners * root.scale) }
    readonly property real rPanel: root.r(22)
    readonly property real rCard: root.r(16)
    readonly property real rKey: root.r(11)
    readonly property real tileRadius: root.rKey
    readonly property real gap: root.s(8)
    readonly property real edge: root.s(10)
    readonly property real barHeight: root.s(36)

    // Type
    readonly property FontLoader sans: FontLoader { source: Qt.resolvedUrl("../assets/fonts/HankenGrotesk.ttf") }
    readonly property string systemFont: String(Config.options?.appearance?.typography?.mainFont ?? "sans-serif")
    readonly property string grotesk: String(root.opt("font", "grotesk")) === "system" || root.sans.status !== FontLoader.Ready
        ? root.systemFont : root.sans.name
    readonly property real textSmall: root.s(12)
    readonly property real textBody: root.s(14)
    readonly property real textLarge: root.s(18)
    readonly property real textTitle: root.s(28)

    // Motion: `motion` multiplies every duration, 0 turns movement off.
    readonly property real motion: root.clamp(Number(root.opt("motion", 1)) * Number(Config.options?.nihil?.motion?.speed ?? 1), 0, 4)
    function ms(value: real): int { return Math.round(value * root.motion) }
    readonly property int quick: root.ms(120)
    readonly property int calm: root.ms(240)
    readonly property int slow: root.ms(420)
}
