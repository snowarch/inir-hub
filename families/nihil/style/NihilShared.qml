import QtQuick
import qs.services
import qs.modules.common.functions

// NiHiL's tokens under the names shared surfaces read (the base's FamilyStyle), so a surface no family draws for itself,
// and a widget without a face of its own, still wears the sheet: black glass, one light, no bounce.
QtObject {
    readonly property bool light: !NihilStyle.dark
    readonly property bool glassy: true
    readonly property bool motionEnabled: NihilStyle.ms(100) > 0
    readonly property real density: 1

    readonly property color accent: NihilStyle.accent
    readonly property color secondaryAccent: NihilStyle.highlightTint
    readonly property color wallpaperLight: NihilStyle.highlight
    readonly property color text: NihilStyle.text
    readonly property color textStrong: NihilStyle.text
    readonly property color textSecondary: NihilStyle.textSecondary
    readonly property color textTertiary: NihilStyle.textTertiary
    readonly property color subtext: NihilStyle.textSecondary
    readonly property color surface: NihilStyle.glassTint
    readonly property color bodySurface: NihilStyle.menuBackground
    readonly property color surfaceHigh: NihilStyle.surface
    readonly property color surfaceHighest: ColorUtils.mix(NihilStyle.surface, NihilStyle.text, 0.92)
    readonly property color raised: NihilStyle.fillHover
    readonly property color fill: NihilStyle.fill
    readonly property color fillQuiet: NihilStyle.inset
    readonly property color fillHover: NihilStyle.fillHover
    readonly property color fillActive: NihilStyle.fillPressed
    readonly property color border: NihilStyle.border
    readonly property color hairlineStrong: Qt.alpha(NihilStyle.text, 0.18)
    readonly property color danger: NihilStyle.danger
    readonly property color success: NihilStyle.dark ? "#7BD88F" : "#1F8A4C"
    readonly property color inkOnAccent: NihilStyle.accentText
    readonly property color onTint: "#FFFFFF"
    readonly property color inkOnLight: "#101217"
    readonly property color inkOnDark: "#F3F4F6"
    readonly property color onMedia: "#FFFFFF"
    readonly property color onMediaSecondary: Qt.alpha("#FFFFFF", 0.72)
    readonly property color onMediaFill: Qt.alpha("#FFFFFF", 0.18)
    readonly property color highlightOnMedia: NihilStyle.accent
    readonly property color dangerOnMedia: "#FF7B72"
    readonly property color veilStrong: Qt.alpha(NihilStyle.background, 0.62)
    readonly property color scrim: NihilStyle.scrim
    readonly property color shadow: Qt.alpha("#000000", 0.4)
    readonly property color plateShadow: Qt.alpha("#000000", 0.28)

    readonly property var widgetPaletteNames: ["wallpaper", "mono"]
    readonly property string toastSkin: ""

    readonly property string fontMain: NihilStyle.fontFamily
    readonly property string fontNumbers: NihilStyle.fontFamily
    readonly property string fontTitle: NihilStyle.titleFontFamily
    readonly property real typeScale: NihilStyle.scale
    readonly property int typeFootnote: NihilStyle.textCaption - 1
    readonly property int typeMeta: NihilStyle.textCaption
    readonly property int typeLabel: NihilStyle.textBody
    readonly property int typeTitle: NihilStyle.textLarge

    readonly property int radiusChip: Math.round(NihilStyle.radiusSmall * 0.75)
    readonly property int radiusRow: NihilStyle.radiusSmall
    readonly property int radiusTile: NihilStyle.radiusSmall
    readonly property int radiusCard: NihilStyle.radiusCard
    readonly property int radiusPlate: NihilStyle.r(22)
    readonly property int radiusSheet: NihilStyle.radiusWindow
    readonly property int radiusPanel: NihilStyle.radiusPanel
    readonly property int spaceSmall: NihilStyle.spacing
    readonly property real shapeScale: NihilStyle.corners

    readonly property int revealDuration: NihilStyle.durationShort
    readonly property int feedbackDuration: NihilStyle.durationShort
    readonly property int moveDuration: NihilStyle.durationMedium
    readonly property int morphDuration: NihilStyle.durationMedium
    readonly property int emergeDuration: NihilStyle.durationMedium
    readonly property int recedeDuration: NihilStyle.durationShort
    readonly property var moveCurve: [0.16, 1, 0.3, 1, 1, 1]
    readonly property var morphCurve: [0.16, 1, 0.3, 1, 1, 1]
    readonly property var emergeCurve: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var recedeCurve: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property int feedbackEasing: Easing.OutCubic
    readonly property string morphName: ""

    function duration(ms: int): int { return NihilStyle.ms(ms) }
    function pressScale(base: real): real { return base }
    function weight(base: int): int { return base }
    function concentric(outer: real, inset: real, floor: real): int { return Math.max(Math.round(floor), Math.round(outer - inset)) }
    function concentricPad(outer: real, floor: real): int { return Math.max(Math.round(floor), Math.round(outer * 0.3 + 7)) }
    function iconRadius(size: real): int { return Math.round(size * 0.26) }
    function tintFill(tint: color): color { return ColorUtils.applyAlpha(tint, 0.13) }
    function tintFillHover(tint: color): color { return ColorUtils.applyAlpha(tint, 0.2) }
    function tintBorder(tint: color): color { return ColorUtils.applyAlpha(tint, 0.7) }
    function containerOf(c: color): color { return ColorUtils.mix(NihilStyle.background, c, NihilStyle.dark ? 0.72 : 0.8) }
    function onTintFor(tint: color): color {
        return ColorUtils.contrastRatio("#FFFFFF", tint) >= ColorUtils.contrastRatio("#101217", tint) ? "#FFFFFF" : "#101217"
    }
    function onContainerOf(c: color): color { return onTintFor(containerOf(c)) }
    function identityOf(c: color): color { return c }
    function deepAccent(seed, fallback): color {
        const c = Qt.color(seed)
        return c.valid ? c : (fallback ?? "#101217")
    }
    function markOn(seed: color, sample: var, darkText: bool, contrast: real): color {
        return sample ? Lume.mark(seed, sample.level, sample.spread, darkText, contrast) : seed
    }
    function legibleVeil(material: string, level: real, spread: real, strength: real): real {
        return material === "clear" ? 0 : Lume.veil(level, spread, 1, NihilStyle.background, NihilStyle.text, 4.5, 0.3 * strength, 0.86)
    }
    function widgetPalette(name: string, vibrance: real): var {
        return name === "mono" ? [NihilStyle.text, NihilStyle.textSecondary, NihilStyle.textTertiary] : [NihilStyle.accent, NihilStyle.highlight, NihilStyle.highlightTint]
    }
}
