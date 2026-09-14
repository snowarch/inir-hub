pragma Singleton

import QtQuick
import qs.modules.common
import qs.modules.common.functions

QtObject {
    id: root

    readonly property var options: Config.options?.iris ?? ({})
    readonly property var appearance: root.options?.appearance ?? ({})

    readonly property bool island: String(root.appearance?.design ?? "island") !== "classic"
    readonly property bool cluster: root.island && (root.options?.bar?.composition ?? "unified") === "cluster"

    readonly property real density: Math.max(0.8, Math.min(1.35, Number(root.appearance?.density ?? 1.0)))
    // Density owns geometry; the shell-wide typography scale owns type. Do not
    // multiply both controls or an ordinary 125% dense layout plus 145% text
    // becomes an unusable 181% type scale.
    readonly property real typeScale: Math.max(0.75, Math.min(1.6, Appearance.fontSizeScale ?? 1.0))
    // iRiS is deliberately tighter than the expressive Material families.
    // Keep the user radius preference, but resolve it through a compact chassis
    // so panels read as authored shell chrome instead of generic cards.
    readonly property int radius: Math.round((root.island ? Math.max(16, Math.min(40, Number(root.appearance?.expandedRadius ?? 28))) : Math.max(6, Number(root.appearance?.radius ?? 12))) * root.density)
    readonly property int radiusSmall: Math.max(4, Math.round(root.radius * 0.58))
    readonly property int radiusTiny: Math.max(3, Math.round(root.radius * 0.36))
    readonly property int gap: Math.max(4, Math.round(8 * root.density))
    readonly property int gapLarge: Math.max(8, Math.round(14 * root.density))
    readonly property int spaceSmall: Math.max(4, Math.round(6 * root.density))
    readonly property int spaceMedium: Math.max(6, Math.round(10 * root.density))
    readonly property int spaceLarge: Math.max(10, Math.round(16 * root.density))

    readonly property string fontMain: {
        const configured = String(root.appearance?.fontFamily ?? "")
        return configured.length > 0 ? configured : root.island ? "Noto Sans" : Appearance.font.family.main
    }
    readonly property string fontTitle: {
        const configured = String(root.appearance?.titleFontFamily ?? "")
        return configured.length > 0 ? configured : root.island ? root.fontMain : Appearance.font.family.title
    }
    readonly property string fontNumbers: root.island ? root.fontMain : "Rubik"

    // Reuse iNiR's established technical palette rather than binding iRiS to
    // whichever Global Style happens to be active. Wallpaper palette generation
    // still feeds these tokens through Appearance.inir.
    readonly property color canvas: Appearance.colors.colLayer0Base
    readonly property color surfaceOpaque: root.island ? "#000000" : Appearance.colors.colLayer1Base
    readonly property color surfaceHighOpaque: root.island ? "#1c1c1e" : Appearance.colors.colLayer2Base
    readonly property color surfaceHighestOpaque: root.island ? "#2c2c2e" : Appearance.colors.colLayer3Base
    readonly property color surface: root.surfaceOpaque
    readonly property color surfaceHigh: root.surfaceHighOpaque
    readonly property color surfaceHighest: root.surfaceHighestOpaque
    readonly property color field: root.surfaceHighestOpaque
    readonly property color text: root.island ? "#f5f5f7" : Appearance.inir.colText
    readonly property color subtext: root.island ? "#aeaeb2" : Appearance.inir.colTextSecondary
    readonly property color muted: root.island ? "#8e8e93" : Appearance.inir.colTextMuted
    readonly property color accent: root.island ? "#a8c7fa" : Appearance.inir.colPrimary
    readonly property color onAccent: root.island ? "#101318" : Appearance.inir.colOnPrimary
    readonly property color accentContainer: root.island ? "#243044" : Appearance.inir.colPrimaryContainer
    readonly property color onAccentContainer: root.island ? "#d9e6ff" : Appearance.inir.colOnPrimaryContainer
    readonly property color secondaryAccent: root.island ? "#ff9f0a" : Appearance.inir.colTertiary
    readonly property color danger: root.island ? "#ff6961" : Appearance.inir.colError
    readonly property color onDanger: root.island ? "#160000" : Appearance.inir.colOnError
    readonly property color hairline: root.island ? "#262628" : Appearance.inir.colBorderSubtle
    readonly property color hairlineStrong: root.island ? "#48484a" : Appearance.inir.colBorder
    readonly property color selection: root.island ? "#303034" : Appearance.inir.colSelection
    readonly property color selectionHover: root.island ? "#404044" : Appearance.inir.colSelectionHover
    readonly property color selectionText: root.island ? "#ffffff" : Appearance.inir.colOnSelection
    readonly property color scrim: Appearance.colors.colScrim

    readonly property real panelPadding: Math.round((root.island ? 24 : 18) * root.density)
    readonly property real sectionGap: Math.round((root.island ? 24 : 18) * root.density)
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
    readonly property int revealDuration: duration(140)
    readonly property int feedbackDuration: duration(100)
    readonly property var morphCurve: [0.16, 1, 0.3, 1, 1, 1]
}
