pragma Singleton

import QtQuick
import Quickshell
import qs.modules.common
import qs.services

// Every measure, ink and material of NiHiL, all of it driven by `nihil.look`.
// Vitrine: neutral smoked glass over the blurred desktop, a specular rim where the light catches it, white type, and what
// is on drawn as a solid pill in one light (pearl by default, or the wallpaper's own colour).
Singleton {
    id: root

    readonly property var look: Config.options?.nihil?.look ?? ({})
    function opt(key: string, fallback: var): var {
        const value = root.look?.[key]
        return value === undefined || value === null ? fallback : value
    }
    function clamp(value: real, low: real, high: real): real { return Math.max(low, Math.min(high, value)) }

    // NiHiL keeps its own scheme: nothing here is read from the shell's Material colours.
    readonly property string scheme: String(root.opt("scheme", "dark")) === "light" ? "light" : "dark"
    readonly property bool dark: root.scheme === "dark"

    // One light per palette. "pearl" is the glass's own white (ink on dark, ink on light); "wallpaper" takes the most
    // vivid colour the picture itself holds.
    readonly property var palettes: ({
        pearl: { light: "" },
        wallpaper: { light: "" },
        glacier: { light: "#9CCBF2" },
        sage: { light: "#A8D5A2" },
        coral: { light: "#FF8D72" },
        gold: { light: "#F1C76B" }
    })
    // Names from earlier NiHiL land on the closest light; anything unknown on pearl.
    readonly property var _renamed: ({ filament: "pearl", copper: "gold", amber: "gold", signal: "coral", ember: "coral",
        ice: "glacier", azure: "glacier", moss: "sage" })
    readonly property string paletteName: {
        const name = String(root.opt("palette", "pearl"))
        const known = root._renamed[name] ?? name
        return root.palettes[known] ? known : "pearl"
    }
    readonly property bool fromWallpaper: root.paletteName === "wallpaper"
    readonly property bool pearl: root.paletteName === "pearl"

    ColorQuantizer {
        id: pictureColours
        source: root.fromWallpaper ? Wallpapers.effectiveWallpaperUrl : ""
        depth: 4
        rescaleSize: 64
    }
    readonly property color pictureLight: {
        let best = "#9CCBF2"
        let score = 0.12
        for (const colour of pictureColours.colors ?? []) {
            const vivid = colour.hslSaturation * (1 - Math.abs(colour.hslLightness - 0.55))
            if (vivid > score) { score = vivid; best = colour }
        }
        return best
    }
    readonly property color seed: root.fromWallpaper ? root.pictureLight : root.pearl ? root.ink : root.palettes[root.paletteName].light
    // The light at the lightness that reads on this glass: pale on dark, deep on light.
    function tone(c: color, lightness: real): color {
        return Qt.hsla(Math.max(0, c.hslHue), Math.min(c.hslSaturation, root.dark ? 0.85 : 0.6), lightness, 1)
    }
    function luma(c: color): real { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    readonly property color accent: root.pearl ? root.ink
        : root.dark ? root.tone(root.seed, Math.max(0.7, root.seed.hslLightness)) : root.tone(root.seed, 0.36)
    readonly property color accentInk: root.luma(root.accent) > 0.5 ? "#0D0E11" : "#F7F8FA"
    // The light the rim and the glow are drawn in: white for pearl, the light itself otherwise.
    readonly property color specA: root.pearl ? "#FFFFFF" : root.accent
    readonly property color specB: root.pearl ? "#DCE6FF" : Qt.lighter(root.accent, 1.25)

    // The glass and what is written on it: neutral graphite and neutral paper.
    readonly property color void_: root.dark ? "#0F1013" : "#F1F2F5"
    readonly property color carbon: root.dark ? "#1A1B20" : "#E4E6EB"
    readonly property color ink: root.dark ? "#F5F6F8" : "#121317"
    readonly property color inkSoft: Qt.alpha(root.ink, root.dark ? 0.66 : 0.68)
    readonly property color inkFaint: Qt.alpha(root.ink, root.dark ? 0.4 : 0.46)
    readonly property color hair: Qt.alpha(root.ink, 0.1)
    readonly property color line: Qt.alpha(root.ink, 0.07)
    readonly property color piece: Qt.alpha(root.ink, root.dark ? 0.06 : 0.05)
    readonly property color pieceRaised: Qt.alpha(root.ink, root.dark ? 0.11 : 0.09)
    readonly property color chosen: Qt.alpha(root.ink, 0.14)
    // A well: a place pressed into the glass, darker at its top edge, caught by the light along its bottom one.
    readonly property color well: Qt.alpha(root.dark ? "#000000" : "#FFFFFF", root.dark ? 0.18 : 0.45)
    readonly property color wellShade: Qt.alpha("#000000", root.dark ? 0.4 : 0.08)
    readonly property color wellEdge: Qt.alpha("#FFFFFF", root.dark ? 0.07 : 0.6)
    readonly property color rimInk: root.dark ? Qt.alpha("#FFFFFF", 0.18) : Qt.alpha("#000000", 0.12)
    readonly property color scrim: Qt.alpha("#000000", 0.42)
    readonly property color live: root.accent
    readonly property color danger: root.dark ? "#FF7B72" : "#C62F2F"

    // Glass.
    // "smoke", "frost", "fluted" or "prism".
    readonly property string material: String(root.opt("material", "smoke"))
    readonly property int form: ({ smoke: 0, frost: 1, fluted: 2, prism: 3 })[root.material] ?? 0
    readonly property real glassOpacity: root.clamp(Number(root.opt("glass", 0.62)), 0.05, 1)
    readonly property color glassTint: Qt.alpha(root.void_, root.glassOpacity)
    // Menus and lists that open over other controls: dense enough to read over anything, whatever the glass is set to.
    readonly property color menuTint: Qt.alpha(root.void_, Math.max(0.95, root.glassOpacity))
    readonly property bool blur: Boolean(root.opt("blur", true))
    readonly property real glassGrain: root.clamp(Number(root.opt("grain", 0.25)), 0, 1.5)
    readonly property real glassRim: root.clamp(Number(root.opt("rim", 1)), 0, 1.5)
    readonly property real glassFlare: root.clamp(Number(root.opt("flare", 1)), 0, 1.5)
    readonly property real ribs: root.s(Number(root.opt("ribs", 14)))

    // Measure.
    readonly property real scale: root.clamp(Number(root.opt("scale", 1)), 0.75, 1.5)
    function s(px: real): real { return Math.round(px * root.scale) }
    readonly property real corners: root.clamp(Number(root.opt("corners", 1)), 0, 2)
    function r(px: real): real { return Math.round(px * root.corners * root.scale) }
    readonly property real rSheet: root.r(30)
    readonly property real rPanel: root.r(26)
    readonly property real rCard: root.r(18)
    readonly property real rKey: root.r(12)
    readonly property real tileRadius: root.rKey
    readonly property real gap: root.s(8)
    readonly property real edge: root.s(16)

    // The rail: NiHiL's panel, a column (or a row) of glass along one edge of the screen.
    readonly property var panel: Config.options?.nihil?.panel
    // "left", "right", "top" or "bottom". Earlier NiHiL kept only top and bottom, which still mean what they said.
    readonly property string railEdge: {
        const at = String(root.panel?.position ?? "left")
        return ["left", "right", "top", "bottom"].includes(at) ? at : "left"
    }
    readonly property bool railVertical: root.railEdge === "left" || root.railEdge === "right"
    // "float" stands off every edge as an island; "edge" runs the whole side.
    readonly property bool railFloats: String(root.panel?.style ?? "float") !== "edge"
    readonly property real railThickness: root.s(Number(root.panel?.thickness ?? 52))
    readonly property real railMargin: root.railFloats ? root.s(Number(root.panel?.margin ?? 10)) : 0
    // What the rail takes from its edge, margins included.
    readonly property real railRoom: root.railThickness + root.railMargin

    // Type: Geist for everything, set by weight and size alone.
    readonly property FontLoader sans: FontLoader { source: Qt.resolvedUrl("../assets/fonts/Geist.ttf") }
    readonly property string systemFont: String(Config.options?.appearance?.typography?.mainFont ?? "sans-serif")
    readonly property string grotesk: String(root.opt("font", "geist")) === "system" || root.sans.status !== FontLoader.Ready
        ? root.systemFont : root.sans.name
    readonly property string display: String(root.opt("display", "geist")) === "system" ? root.systemFont : root.grotesk
    readonly property real textLabel: root.s(12)
    readonly property real textSmall: root.s(13)
    readonly property real textBody: root.s(14)
    readonly property real textLarge: root.s(17)
    readonly property real textTitle: root.s(22)
    readonly property real textFigure: root.s(34)
    readonly property real textHero: root.s(56)

    // Motion: `motion` multiplies every duration, 0 turns movement off.
    readonly property real motion: root.clamp(Number(root.opt("motion", 1)) * Number(Config.options?.nihil?.motion?.speed ?? 1), 0, 4)
    function ms(value: real): int { return Math.round(value * root.motion) }
    readonly property int quick: root.ms(120)
    readonly property int calm: root.ms(260)
    readonly property int slow: root.ms(460)
}
