pragma Singleton

import QtQuick
import Quickshell
import qs.modules.common
import qs.services

// Every measure, ink and material of NiHiL, all of it driven by `nihil.look`.
// An instrument panel: warm black glass, one filament of light, and what is on drawn solid in that light.
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

    // One light per palette. "wallpaper" takes the most vivid colour the picture itself holds.
    readonly property var palettes: ({
        filament: { light: "#F2E6D4" },
        copper: { light: "#E9A26A" },
        signal: { light: "#FF6A3D" },
        glacier: { light: "#BBD6E4" },
        sage: { light: "#B7CFA3" },
        wallpaper: { light: "" }
    })
    // Names from earlier NiHiL land on the closest light; anything unknown on the filament.
    readonly property var _renamed: ({ ember: "copper", amber: "copper", ice: "glacier", azure: "glacier", moss: "sage" })
    readonly property string paletteName: {
        const name = String(root.opt("palette", "filament"))
        const known = root._renamed[name] ?? name
        return root.palettes[known] ? known : "filament"
    }
    readonly property bool fromWallpaper: root.paletteName === "wallpaper"

    ColorQuantizer {
        id: pictureColours
        source: root.fromWallpaper ? Wallpapers.effectiveWallpaperUrl : ""
        depth: 4
        rescaleSize: 64
    }
    readonly property color pictureLight: {
        let best = root.palettes.filament.light
        let score = 0.12
        for (const colour of pictureColours.colors ?? []) {
            const vivid = colour.hslSaturation * (1 - Math.abs(colour.hslLightness - 0.55))
            if (vivid > score) { score = vivid; best = colour }
        }
        return best
    }
    readonly property color seed: root.fromWallpaper ? root.pictureLight : root.palettes[root.paletteName].light
    // The light at the lightness that reads on this sheet: pale on black, deep on paper.
    function tone(c: color, lightness: real): color {
        return Qt.hsla(Math.max(0, c.hslHue), Math.min(c.hslSaturation, root.dark ? 0.9 : 0.62), lightness, 1)
    }
    readonly property color accent: root.dark ? root.tone(root.seed, Math.max(0.68, root.seed.hslLightness)) : root.tone(root.seed, 0.3)
    readonly property color accentInk: root.dark ? "#0C0A08" : "#FBF8F3"
    readonly property color specA: root.accent
    readonly property color specB: root.accent

    // The sheet and what is written on it: warm black and warm paper, never a blue-grey.
    readonly property color void_: root.dark ? "#0C0A08" : "#EFEAE2"
    readonly property color carbon: root.dark ? "#171411" : "#E5DFD5"
    readonly property color ink: root.dark ? "#F5F0E8" : "#17130E"
    readonly property color inkSoft: Qt.alpha(root.ink, root.dark ? 0.62 : 0.68)
    readonly property color inkFaint: Qt.alpha(root.ink, root.dark ? 0.38 : 0.46)
    readonly property color hair: Qt.alpha(root.ink, 0.1)
    readonly property color line: Qt.alpha(root.ink, 0.07)
    readonly property color piece: Qt.alpha(root.ink, 0.045)
    readonly property color pieceRaised: Qt.alpha(root.ink, 0.09)
    readonly property color chosen: Qt.alpha(root.ink, 0.12)
    // A well: a place pressed into the glass, darker at its top edge, caught by the light along its bottom one.
    readonly property color well: Qt.alpha(root.ink, root.dark ? 0.035 : 0.05)
    readonly property color wellShade: Qt.alpha("#000000", root.dark ? 0.45 : 0.1)
    readonly property color wellEdge: Qt.alpha(root.dark ? "#FFFFFF" : "#000000", root.dark ? 0.06 : 0.07)
    readonly property color rimInk: root.dark ? Qt.alpha("#FFFFFF", 0.16) : Qt.alpha("#000000", 0.14)
    readonly property color scrim: Qt.alpha("#000000", 0.45)
    readonly property color live: root.accent
    readonly property color danger: root.dark ? "#FF7B72" : "#C62F2F"

    // Glass.
    // "smoke", "frost", "fluted" or "prism".
    readonly property string material: String(root.opt("material", "smoke"))
    readonly property int form: ({ smoke: 0, frost: 1, fluted: 2, prism: 3 })[root.material] ?? 0
    readonly property real glassOpacity: root.clamp(Number(root.opt("glass", 0.74)), 0.05, 1)
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
    readonly property real rPanel: root.r(28)
    readonly property real rCard: root.r(18)
    readonly property real rKey: root.r(12)
    readonly property real tileRadius: root.rKey
    readonly property real gap: root.s(8)
    readonly property real edge: root.s(16)
    readonly property real barHeight: root.s(44)
    // How wide the coves are where a body is pulled out of the sheet.
    readonly property real fuse: root.s(30)

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
