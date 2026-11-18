pragma Singleton

import QtQuick
import Quickshell
import qs.modules.common

// Every measure, ink and material of NiHiL, all of it driven by `nihil.look`.
// The language is a poster under glass: bone type on matte black, smoked glass that splits light at its rim, and the
// spectrum kept for light only (rims, flares, the one live mark). Everything else is ink.
Singleton {
    id: root

    readonly property var look: Config.options?.nihil?.look ?? ({})
    function opt(key: string, fallback: var): var {
        const value = root.look?.[key]
        return value === undefined || value === null ? fallback : value
    }
    function clamp(value: real, low: real, high: real): real { return Math.max(low, Math.min(high, value)) }

    readonly property var m3: Appearance.m3colors
    readonly property bool dark: true

    // The light each palette splits into. `rainbow` 1 is the whole spectrum, 0 the two lights with white between.
    readonly property var palettes: ({
        spectral: { a: "#FF5B3A", b: "#4CC9FF", rainbow: 1, ink: "#EDEAE3", void_: "#0B0B0C" },
        mono: { a: "#F4F2EE", b: "#C9CDD4", rainbow: 0, ink: "#EDEAE3", void_: "#0A0A0A" },
        ember: { a: "#FF3D1F", b: "#FFB547", rainbow: 0, ink: "#F1E9DF", void_: "#0D0908" },
        ice: { a: "#7FDBFF", b: "#A994FF", rainbow: 0, ink: "#E8ECF1", void_: "#090B0E" },
        wallpaper: { a: "", b: "", rainbow: 0.35, ink: "#EDEAE3", void_: "#0B0B0C" }
    })
    // Names from the first NiHiL land on the closest light.
    readonly property var _renamed: ({ obsidian: "spectral", amber: "ember", azure: "ice", ultramarine: "ice" })
    readonly property string paletteName: {
        const name = String(root.opt("palette", "spectral"))
        const known = root._renamed[name] ?? name
        return root.palettes[known] ? known : "spectral"
    }
    readonly property var palette: root.palettes[root.paletteName]
    readonly property color specA: root.paletteName === "wallpaper" ? root.m3.m3primary : root.palette.a
    readonly property color specB: root.paletteName === "wallpaper" ? root.m3.m3tertiary : root.palette.b
    readonly property real rainbow: root.palette.rainbow

    // Ink.
    readonly property color void_: root.palette.void_
    readonly property color carbon: Qt.lighter(root.void_, 1.9)
    readonly property color ink: root.palette.ink
    readonly property color inkSoft: Qt.alpha(root.ink, 0.62)
    readonly property color inkFaint: Qt.alpha(root.ink, 0.34)
    readonly property color hair: Qt.alpha(root.ink, 0.16)
    readonly property color line: Qt.alpha(root.ink, 0.1)
    readonly property color piece: Qt.alpha(root.ink, 0.06)
    readonly property color pieceRaised: Qt.alpha(root.ink, 0.12)
    readonly property color scrim: Qt.alpha("#000000", 0.5)
    // What is chosen is a bone plate with black type on it; the spectrum only lights it.
    readonly property color accent: root.ink
    readonly property color onAccent: root.void_
    // The one live mark: the warm end of the light.
    readonly property color live: root.specA
    // Kept for surfaces that still ask by the old names.
    readonly property color base: root.void_
    readonly property color mid: root.carbon
    readonly property color high: root.ink
    readonly property color flareA: root.specA
    readonly property color flareB: root.specB

    // Glass.
    // "smoke", "frost", "fluted" or "prism".
    readonly property string material: String(root.opt("material", "smoke"))
    readonly property int form: ({ smoke: 0, frost: 1, fluted: 2, prism: 3 })[root.material] ?? 0
    readonly property real glassOpacity: root.clamp(Number(root.opt("glass", 0.58)), 0.05, 1)
    readonly property color glassTint: Qt.alpha(Qt.tint(root.void_, Qt.alpha("#1A1B1F", 0.5)), root.glassOpacity)
    readonly property bool blur: Boolean(root.opt("blur", true))
    readonly property real glassGrain: root.clamp(Number(root.opt("grain", 0.55)), 0, 1.5)
    readonly property real glassRim: root.clamp(Number(root.opt("rim", 0.75)), 0, 1.5)
    readonly property real glassFlare: root.clamp(Number(root.opt("flare", 0.6)), 0, 1.5)
    readonly property real ribs: root.s(Number(root.opt("ribs", 14)))
    // Four-point flares on what is live.
    readonly property bool sparks: Boolean(root.opt("sparks", true))

    // Measure.
    readonly property real scale: root.clamp(Number(root.opt("scale", 1)), 0.75, 1.5)
    function s(px: real): real { return Math.round(px * root.scale) }
    readonly property real corners: root.clamp(Number(root.opt("corners", 1)), 0, 2)
    function r(px: real): real { return Math.round(px * root.corners * root.scale) }
    readonly property real rPanel: root.r(18)
    readonly property real rCard: root.r(12)
    readonly property real rKey: root.r(7)
    readonly property real tileRadius: root.rKey
    readonly property real gap: root.s(8)
    readonly property real edge: root.s(12)
    readonly property real barHeight: root.s(34)

    // Type: a condensed display face for what leads, a grotesk for the rest, small capitals for labels.
    readonly property FontLoader sans: FontLoader { source: Qt.resolvedUrl("../assets/fonts/HankenGrotesk.ttf") }
    readonly property FontLoader condensed: FontLoader { source: Qt.resolvedUrl("../assets/fonts/Anton-Regular.ttf") }
    readonly property string systemFont: String(Config.options?.appearance?.typography?.mainFont ?? "sans-serif")
    readonly property string grotesk: String(root.opt("font", "grotesk")) === "system" || root.sans.status !== FontLoader.Ready
        ? root.systemFont : root.sans.name
    // "condensed", "grotesk" or "system".
    readonly property string displayChoice: String(root.opt("display", "condensed"))
    readonly property bool displayCondensed: root.displayChoice === "condensed" && root.condensed.status === FontLoader.Ready
    readonly property string display: root.displayCondensed ? root.condensed.name
        : root.displayChoice === "system" ? root.systemFont : root.grotesk
    readonly property real textLabel: root.s(10)
    readonly property real textSmall: root.s(12)
    readonly property real textBody: root.s(13)
    readonly property real textLarge: root.s(17)
    readonly property real textTitle: root.s(30)
    readonly property real textHero: root.s(64)
    readonly property real labelTracking: root.s(1.6)

    // Motion: `motion` multiplies every duration, 0 turns movement off.
    readonly property real motion: root.clamp(Number(root.opt("motion", 1)) * Number(Config.options?.nihil?.motion?.speed ?? 1), 0, 4)
    function ms(value: real): int { return Math.round(value * root.motion) }
    readonly property int quick: root.ms(120)
    readonly property int calm: root.ms(260)
    readonly property int slow: root.ms(460)
}
