pragma Singleton

import QtQuick
import Quickshell
import qs.modules.common
import qs.services

// Every colour, measure and material of NiHiL, all of it driven by `nihil.look`: neutral smoked glass over the blurred
// desktop, a bright edge where the light catches it, white text, and what is active drawn as a solid pill in the accent.
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

    // The accents. "white" follows the text colour (white on dark, near black on light); "wallpaper" takes the most
    // vivid colour of the picture.
    readonly property var accents: ({
        white: "",
        wallpaper: "",
        blue: "#9CCBF2",
        green: "#A8D5A2",
        orange: "#FF8D72",
        yellow: "#F1C76B"
    })
    readonly property string accentName: {
        const name = String(root.opt("accent", "white"))
        return root.accents[name] !== undefined ? name : "white"
    }
    readonly property bool fromWallpaper: root.accentName === "wallpaper"
    readonly property bool monochrome: root.accentName === "white"

    ColorQuantizer {
        id: pictureColours
        source: root.fromWallpaper ? Wallpapers.effectiveWallpaperUrl : ""
        depth: 4
        rescaleSize: 64
    }
    readonly property color wallpaperColor: {
        let best = "#9CCBF2"
        let score = 0.12
        for (const colour of pictureColours.colors ?? []) {
            const vivid = colour.hslSaturation * (1 - Math.abs(colour.hslLightness - 0.55))
            if (vivid > score) { score = vivid; best = colour }
        }
        return best
    }
    readonly property color baseColor: root.fromWallpaper ? root.wallpaperColor : root.monochrome ? root.text : root.accents[root.accentName]
    // A colour at the lightness that reads on this glass: pale on dark, deep on light.
    function tone(c: color, lightness: real): color {
        return Qt.hsla(Math.max(0, c.hslHue), Math.min(c.hslSaturation, root.dark ? 0.85 : 0.6), lightness, 1)
    }
    function luma(c: color): real { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    readonly property color accent: root.monochrome ? root.text
        : root.dark ? root.tone(root.baseColor, Math.max(0.7, root.baseColor.hslLightness)) : root.tone(root.baseColor, 0.36)
    readonly property color accentText: root.luma(root.accent) > 0.5 ? "#0D0E11" : "#F7F8FA"
    // The colour the glass edge and its glow are drawn in: white for the white accent, the accent otherwise.
    readonly property color highlight: root.monochrome ? "#FFFFFF" : root.accent
    readonly property color highlightTint: root.monochrome ? "#DCE6FF" : Qt.lighter(root.accent, 1.25)

    // The glass and what is written on it: neutral graphite and neutral paper.
    readonly property color background: root.dark ? "#0F1013" : "#F1F2F5"
    readonly property color surface: root.dark ? "#1A1B20" : "#E4E6EB"
    readonly property color text: root.dark ? "#F5F6F8" : "#121317"
    readonly property color textSecondary: Qt.alpha(root.text, root.dark ? 0.66 : 0.68)
    readonly property color textTertiary: Qt.alpha(root.text, root.dark ? 0.4 : 0.46)
    readonly property color border: Qt.alpha(root.text, 0.1)
    readonly property color fill: Qt.alpha(root.text, root.dark ? 0.06 : 0.05)
    readonly property color fillHover: Qt.alpha(root.text, root.dark ? 0.11 : 0.09)
    readonly property color fillPressed: Qt.alpha(root.text, 0.14)
    // An inset: a place pressed into the glass, darker along its top edge, lit along its bottom one.
    readonly property color inset: Qt.alpha(root.dark ? "#000000" : "#FFFFFF", root.dark ? 0.18 : 0.45)
    readonly property color insetShadow: Qt.alpha("#000000", root.dark ? 0.4 : 0.08)
    readonly property color insetHighlight: Qt.alpha("#FFFFFF", root.dark ? 0.07 : 0.6)
    readonly property color outline: root.dark ? Qt.alpha("#FFFFFF", 0.18) : Qt.alpha("#000000", 0.12)
    readonly property color scrim: Qt.alpha("#000000", 0.42)
    readonly property color danger: root.dark ? "#FF7B72" : "#C62F2F"

    // Glass.
    // "smoke", "frost", "fluted" or "prism".
    readonly property string material: String(root.opt("material", "smoke"))
    readonly property int materialIndex: ({ smoke: 0, frost: 1, fluted: 2, prism: 3 })[root.material] ?? 0
    readonly property real glassOpacity: root.clamp(Number(root.opt("glass", 0.62)), 0.05, 1)
    readonly property color glassTint: Qt.alpha(root.background, root.glassOpacity)
    // Menus and lists that open over other controls: dense enough to read over anything, whatever the glass is set to.
    readonly property color menuBackground: Qt.alpha(root.background, Math.max(0.95, root.glassOpacity))
    readonly property bool blur: Boolean(root.opt("blur", true))
    readonly property real glassGrain: root.clamp(Number(root.opt("grain", 0.25)), 0, 1.5)
    readonly property real glassEdgeLight: root.clamp(Number(root.opt("edgeLight", 1)), 0, 1.5)
    readonly property real glassEdgeGlow: root.clamp(Number(root.opt("edgeGlow", 1)), 0, 1.5)
    readonly property real ribWidth: root.s(Number(root.opt("ribWidth", 14)))

    // Measure.
    readonly property real scale: root.clamp(Number(root.opt("scale", 1)), 0.75, 1.5)
    function s(px: real): real { return Math.round(px * root.scale) }
    readonly property real corners: root.clamp(Number(root.opt("corners", 1)), 0, 2)
    function r(px: real): real { return Math.round(px * root.corners * root.scale) }
    readonly property real radiusWindow: root.r(30)
    readonly property real radiusPanel: root.r(26)
    readonly property real radiusCard: root.r(18)
    readonly property real radiusSmall: root.r(12)
    readonly property real spacing: root.s(8)
    readonly property real screenMargin: root.s(16)

    // The bar: NiHiL's panel, a column (or a row) of glass along one edge of the screen.
    readonly property var panel: Config.options?.nihil?.panel
    // "left", "right", "top" or "bottom".
    readonly property string barEdge: {
        const at = String(root.panel?.position ?? "left")
        return ["left", "right", "top", "bottom"].includes(at) ? at : "left"
    }
    readonly property bool barVertical: root.barEdge === "left" || root.barEdge === "right"
    // "float" stands clear of the edge with round ends; "edge" runs the whole side.
    readonly property bool barFloats: String(root.panel?.style ?? "float") !== "edge"
    readonly property real barThickness: root.s(Number(root.panel?.thickness ?? 52))
    readonly property real barMargin: root.barFloats ? root.s(Number(root.panel?.margin ?? 10)) : 0
    // What the bar takes from its edge, margins included.
    readonly property real barSpace: root.barThickness + root.barMargin

    // Type: Geist for everything, set by weight and size alone.
    readonly property FontLoader sans: FontLoader { source: Qt.resolvedUrl("../assets/fonts/Geist.ttf") }
    readonly property string systemFont: String(Config.options?.appearance?.typography?.mainFont ?? "sans-serif")
    readonly property string fontFamily: String(root.opt("font", "geist")) === "system" || root.sans.status !== FontLoader.Ready
        ? root.systemFont : root.sans.name
    readonly property string titleFontFamily: String(root.opt("titleFont", "geist")) === "system" ? root.systemFont : root.fontFamily
    readonly property real textCaption: root.s(12)
    readonly property real textSmall: root.s(13)
    readonly property real textBody: root.s(14)
    readonly property real textLarge: root.s(17)
    readonly property real textTitle: root.s(22)
    readonly property real textHeadline: root.s(34)
    readonly property real textDisplay: root.s(56)

    // Motion: `motion` multiplies every duration, 0 turns movement off.
    readonly property real motion: root.clamp(Number(root.opt("motion", 1)) * Number(Config.options?.nihil?.motion?.speed ?? 1), 0, 4)
    function ms(value: real): int { return Math.round(value * root.motion) }
    readonly property int durationShort: root.ms(120)
    readonly property int durationMedium: root.ms(260)
    readonly property int durationLong: root.ms(460)
}
