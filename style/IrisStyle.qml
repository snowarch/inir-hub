pragma Singleton

import QtQuick
import qs.modules.common
import qs.modules.common.functions

QtObject {
    id: root

    readonly property var options: Config.options?.iris ?? ({})
    readonly property var appearance: root.options?.appearance ?? ({})

    // iRiS has one design, the Island. Kept as a constant for user modules built
    // against the SDK before the early compact-bar design was removed.
    readonly property bool island: true
    readonly property bool cluster: (root.options?.bar?.composition ?? "unified") === "cluster"

    readonly property real density: Math.max(0.8, Math.min(1.35, Number(root.appearance?.density ?? 1.0)))
    // Density owns geometry; the shell-wide typography scale owns type. Do not
    // multiply both controls or an ordinary 125% dense layout plus 145% text
    // becomes an unusable 181% type scale.
    readonly property real typeScale: Math.max(0.75, Math.min(1.6, Appearance.fontSizeScale ?? 1.0))
    readonly property int radius: Math.round(Math.max(16, Math.min(40, Number(root.appearance?.expandedRadius ?? 28))) * root.density)
    readonly property int radiusSmall: Math.max(4, Math.round(root.radius * 0.58))
    readonly property int radiusTiny: Math.max(3, Math.round(root.radius * 0.36))
    readonly property int gap: Math.max(4, Math.round(8 * root.density))
    readonly property int gapLarge: Math.max(8, Math.round(14 * root.density))
    readonly property int spaceSmall: Math.max(4, Math.round(6 * root.density))
    readonly property int spaceMedium: Math.max(6, Math.round(10 * root.density))
    readonly property int spaceLarge: Math.max(10, Math.round(16 * root.density))

    readonly property string fontMain: {
        const configured = String(root.appearance?.fontFamily ?? "")
        return configured.length > 0 ? configured : "Noto Sans"
    }
    // Three voices: a neutral text face, a wide display face for titles and a
    // rounded face for figures (clocks, timers, levels) — the way a Live
    // Activity sets its numbers apart from its labels. All ship with iNiR.
    readonly property string fontTitle: {
        const configured = String(root.appearance?.titleFontFamily ?? "")
        return configured.length > 0 ? configured : "Readex Pro"
    }
    // Weight of large figures (clocks): light, regular or bold.
    readonly property int figureWeight: ({ light: Font.Light, regular: Font.Normal })[root.appearance?.figureWeight ?? "bold"] ?? Font.Bold
    readonly property string fontNumbers: {
        const configured = String(root.appearance?.numbersFontFamily ?? "")
        return configured.length > 0 ? configured : "Rubik"
    }

    // A fixed family palette: iRiS never mutates with Material II's Global Style.
    readonly property color canvas: Appearance.colors.colLayer0Base
    readonly property color surfaceOpaque: "#000000"
    readonly property color surfaceHighOpaque: "#1c1c1e"
    readonly property color surfaceHighestOpaque: "#2c2c2e"
    readonly property color surface: root.surfaceOpaque
    readonly property color surfaceHigh: root.surfaceHighOpaque
    readonly property color surfaceHighest: root.surfaceHighestOpaque
    readonly property color field: root.surfaceHighestOpaque
    readonly property color text: "#f5f5f7"
    readonly property color subtext: "#aeaeb2"
    readonly property color muted: "#8e8e93"
    function legibleAccent(seed, fallback): color {
        const c = Qt.color(seed)
        if (!c.valid || c.hslHue < 0 || c.hslSaturation < 0.12) return fallback
        return Qt.hsla(c.hslHue, Math.max(0.42, Math.min(0.8, c.hslSaturation)),
            Math.max(0.72, Math.min(0.82, c.hslLightness)), 1)
    }
    readonly property color accent: {
        const choice = root.appearance?.accent ?? "blue"
        if (choice === "wallpaper") return root.legibleAccent(Appearance.colors.colPrimary, "#a8c7fa")
        return ({ mint: "#8de0bd", rose: "#ffb2c4", lilac: "#d2baff" })[choice] ?? "#a8c7fa"
    }
    readonly property color onAccent: Qt.color("#101318")
    readonly property color accentContainer: ColorUtils.mix(root.surface, root.accent, 0.78)
    readonly property color onAccentContainer: ColorUtils.mix(root.accent, root.text, 0.65)
    // The highlight marks what is glanced: the clock separator, the day number,
    // timers. Orange unless the user picks another, or follows the accent.
    readonly property color secondaryAccent: {
        const choice = root.appearance?.highlight ?? "orange"
        if (choice === "accent") return root.accent
        return ({ yellow: "#ffd60a", red: "#ff6961", pink: "#ff6482", green: "#30d158" })[choice] ?? "#ff9f0a"
    }
    readonly property color success: "#8de0a3"
    readonly property color danger: "#ff6961"
    readonly property color onDanger: Qt.color("#160000")
    readonly property color hairline: "#262628"
    readonly property color hairlineStrong: "#48484a"
    readonly property color selection: "#303034"
    readonly property color selectionHover: "#404044"
    readonly property color selectionText: "#ffffff"
    readonly property color scrim: Appearance.colors.colScrim

    readonly property real panelPadding: Math.round(24 * root.density)
    readonly property real sectionGap: Math.round(24 * root.density)
    readonly property real controlHeight: Math.round(38 * root.density)
    readonly property real compactControlHeight: Math.round(32 * root.density)
    readonly property real headerHeight: Math.round(54 * root.typeScale)
    readonly property real accentRuleWidth: Math.round(24 * root.density)
    readonly property real accentRuleHeight: Math.max(2, Math.round(3 * root.density))

    readonly property bool motionEnabled: (root.appearance?.motion ?? true) && Appearance.animationsEnabled
    function duration(ms: int): int {
        return root.motionEnabled ? Appearance.calcEffectiveDuration(ms) : 0
    }

    // Liquid morph: front-loaded ease with a long, visible settle tail
    // (cubic-bezier(0.16, 1, 0.3, 1)). Owned by iRiS so the island morphs as one
    // object without importing another family's motion singleton.
    readonly property int morphDuration: duration(Math.max(100, Math.min(400, Number(root.appearance?.motionDuration ?? 220))))
    // Geometry that opens or closes a shape settles on the same curve for
    // longer: the curve is front-loaded, so the extra time is only the liquid
    // tail, not a slower start. Moving between shapes already open (page
    // switches, sections resizing) uses the plain morph duration.
    readonly property int settleDuration: duration(Math.round(Math.max(100, Math.min(400, Number(root.appearance?.motionDuration ?? 220))) * 1.8))
    readonly property int revealDuration: duration(140)
    readonly property int feedbackDuration: duration(100)
    readonly property var morphCurve: [0.16, 1, 0.3, 1, 1, 1]
}
