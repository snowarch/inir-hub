pragma Singleton

import QtQuick
import Quickshell
import qs.modules.common

// Every measure, ink and material of NiHiL, all of it driven by `nihil.look`.
// Graphite smoked glass, one typeface, one accent. Light lives at the edges of the glass: a specular line on top and
// a soft glow rising from the bottom edge of what is active. Nothing is decoration.
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

    // Each palette is the accent and the two lights its glow mixes.
    readonly property var palettes: ({
        aurora: { accent: "#A3B1FF", a: "#6F7CFF", b: "#C08BFF" },
        mono: { accent: "#ECECEE", a: "#B9BDC6", b: "#ECECEE" },
        ember: { accent: "#FF9A6B", a: "#FF5A36", b: "#FFB45C" },
        ice: { accent: "#8AD4FF", a: "#3FA9FF", b: "#7C8CFF" },
        moss: { accent: "#A9DDB1", a: "#4FBF8A", b: "#C6E38A" },
        wallpaper: { accent: "", a: "", b: "" }
    })
    // Names from earlier NiHiL land on the closest light.
    readonly property var _renamed: ({ spectral: "aurora", obsidian: "mono", amber: "ember", azure: "ice", ultramarine: "aurora" })
    readonly property string paletteName: {
        const name = String(root.opt("palette", "aurora"))
        const known = root._renamed[name] ?? name
        return root.palettes[known] ? known : "aurora"
    }
    readonly property var palette: root.palettes[root.paletteName]
    readonly property bool fromWallpaper: root.paletteName === "wallpaper"
    readonly property color accent: root.fromWallpaper ? Qt.lighter(root.m3.m3primary, 1.15) : root.palette.accent
    readonly property color specA: root.fromWallpaper ? root.m3.m3primary : root.palette.a
    readonly property color specB: root.fromWallpaper ? root.m3.m3tertiary : root.palette.b
    readonly property color accentInk: "#0C0D10"

    // Ink: warm graphite, never pure black or pure white.
    readonly property color void_: "#0C0D10"
    readonly property color carbon: "#16171C"
    readonly property color ink: "#F2F2F4"
    readonly property color inkSoft: Qt.alpha(root.ink, 0.64)
    readonly property color inkFaint: Qt.alpha(root.ink, 0.38)
    readonly property color hair: Qt.alpha(root.ink, 0.09)
    readonly property color line: Qt.alpha(root.ink, 0.07)
    readonly property color piece: Qt.alpha(root.ink, 0.055)
    readonly property color pieceRaised: Qt.alpha(root.ink, 0.1)
    // What is chosen: a raised plate of light glass. `accent` is for what is on.
    readonly property color chosen: Qt.alpha(root.ink, 0.13)
    readonly property color scrim: Qt.alpha("#000000", 0.45)
    readonly property color live: root.accent
    readonly property color danger: "#FF6B6B"

    // Glass.
    // "smoke", "frost", "fluted" or "prism".
    readonly property string material: String(root.opt("material", "smoke"))
    readonly property int form: ({ smoke: 0, frost: 1, fluted: 2, prism: 3 })[root.material] ?? 0
    readonly property real glassOpacity: root.clamp(Number(root.opt("glass", 0.62)), 0.05, 1)
    readonly property color glassTint: Qt.alpha("#17181D", root.glassOpacity)
    // Menus and lists that open over other controls: dense enough to read over anything, whatever the glass is set to.
    readonly property color menuTint: Qt.alpha("#141519", Math.max(0.95, root.glassOpacity))
    readonly property bool blur: Boolean(root.opt("blur", true))
    readonly property real glassGrain: root.clamp(Number(root.opt("grain", 0.25)), 0, 1.5)
    readonly property real glassRim: root.clamp(Number(root.opt("rim", 0.7)), 0, 1.5)
    readonly property real glassFlare: root.clamp(Number(root.opt("flare", 0.5)), 0, 1.5)
    readonly property real ribs: root.s(Number(root.opt("ribs", 14)))

    // Measure.
    readonly property real scale: root.clamp(Number(root.opt("scale", 1)), 0.75, 1.5)
    function s(px: real): real { return Math.round(px * root.scale) }
    readonly property real corners: root.clamp(Number(root.opt("corners", 1)), 0, 2)
    function r(px: real): real { return Math.round(px * root.corners * root.scale) }
    readonly property real rPanel: root.r(22)
    readonly property real rCard: root.r(16)
    readonly property real rKey: root.r(10)
    readonly property real tileRadius: root.rKey
    readonly property real gap: root.s(8)
    readonly property real edge: root.s(12)
    readonly property real barHeight: root.s(36)

    // Type: Geist for everything, set by weight and size alone.
    readonly property FontLoader sans: FontLoader { source: Qt.resolvedUrl("../assets/fonts/Geist.ttf") }
    readonly property string systemFont: String(Config.options?.appearance?.typography?.mainFont ?? "sans-serif")
    readonly property string grotesk: String(root.opt("font", "geist")) === "system" || root.sans.status !== FontLoader.Ready
        ? root.systemFont : root.sans.name
    readonly property string display: String(root.opt("display", "geist")) === "system" ? root.systemFont : root.grotesk
    readonly property real textLabel: root.s(11)
    readonly property real textSmall: root.s(12)
    readonly property real textBody: root.s(13)
    readonly property real textLarge: root.s(16)
    readonly property real textTitle: root.s(24)
    readonly property real textHero: root.s(56)

    // Motion: `motion` multiplies every duration, 0 turns movement off.
    readonly property real motion: root.clamp(Number(root.opt("motion", 1)) * Number(Config.options?.nihil?.motion?.speed ?? 1), 0, 4)
    function ms(value: real): int { return Math.round(value * root.motion) }
    readonly property int quick: root.ms(120)
    readonly property int calm: root.ms(260)
    readonly property int slow: root.ms(460)
}
