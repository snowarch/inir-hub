pragma Singleton

import QtQuick
import qs.modules.common
import qs.modules.common.functions

QtObject {
    id: root

    readonly property var options: Config.options?.iris ?? ({})
    readonly property var appearance: root.options?.appearance ?? ({})

    readonly property bool island: true

    // --- Recompose: one clock for structural change -------------------------
    // An option that changes what a surface is *made of* (the Island's
    // composition, its clock, its bubbles, a panel's sections) is never applied
    // while the shapes are visible: every such value is published here, latched,
    // and swapped at the bottom of one shared dip. Consumers read the latched
    // value and multiply their content by `recompose`, so a recomposition is one
    // transition for the whole family instead of one animation per part racing
    // the others. Geometry still springs across the swap: the silhouette is
    // continuous, its contents are replaced (DESIGN §0.4).
    readonly property var structuralPaths: ["bar.composition", "bar.clockStyle", "bar.trailing",
        "bar.auxiliary", "bar.pieces", "bar.navItems", "bar.desktopBlocks", "bar.mediaBlocks",
        "controlCenter.sections", "controlCenter.controls"]
    function readPath(path: string): var {
        let node = root.options
        for (const part of path.split(".")) {
            if (node === undefined || node === null) return undefined
            node = node[part]
        }
        return node
    }
    readonly property var structuralSource: {
        const out = {}
        for (const path of root.structuralPaths) {
            const value = root.readPath(path)
            out[path] = value === undefined ? null : (Array.isArray(value) ? Array.from(value) : value)
        }
        return out
    }
    readonly property string structuralKey: JSON.stringify(root.structuralSource)
    property var structure: root.structuralSource
    property real recomposeValue: 1
    readonly property real recompose: root.recomposeValue
    readonly property bool recomposing: root.recomposeValue < 0.999
    function structuralValue(path: string, fallback: var): var {
        const value = root.structure?.[path]
        return value === undefined || value === null ? fallback : value
    }
    onStructuralKeyChanged: {
        if (!root.motionEnabled) { root.structure = root.structuralSource; return }
        root.recomposeIn.stop()
        root.recomposeOut.restart()
    }
    readonly property NumberAnimation recomposeOut: NumberAnimation {
        target: root; property: "recomposeValue"; to: 0
        duration: root.duration(80); easing.type: Easing.OutQuad
        onFinished: {
            root.structure = root.structuralSource
            root.recomposeIn.restart()
        }
    }
    readonly property NumberAnimation recomposeIn: NumberAnimation {
        target: root; property: "recomposeValue"; to: 1
        duration: root.duration(200); easing.type: Easing.BezierSpline; easing.bezierCurve: root.emergeCurve
    }

    readonly property bool cluster: String(root.structuralValue("bar.composition", "unified")) === "cluster"

    readonly property real density: Math.max(0.8, Math.min(1.35, Number(root.appearance?.density ?? 1.0)))
    // Density scales geometry only; type has its own scale.
    readonly property real typeScale: Math.max(0.75, Math.min(1.6, (Appearance.fontSizeScale ?? 1.0) * root.tweak("text", 0.85, 1.25)))

    readonly property var theme: root.appearance?.theme ?? ({})
    function hueOf(name: string, fallback: int): real {
        const value = Number(root.theme?.[name] ?? fallback)
        return (((isNaN(value) ? fallback : value) % 360) + 360) % 360 / 360
    }
    function tweak(name: string, low: real, high: real): real {
        const value = Number(root.theme?.[name] ?? 100)
        return Math.max(low, Math.min(high, (isNaN(value) ? 100 : value) / 100 * IrisMood.factor(name)))
    }
    function surfaceRadius(id: string, fallback: int): int {
        const radius = Number(root.appearance?.surfaces?.[id]?.radius ?? 0)
        return radius > 0 ? Math.round(radius * root.density) : fallback
    }
    function surfaceLight(id: string, light: color): color {
        const mode = String(root.appearance?.surfaces?.[id]?.light ?? "inherit")
        return mode === "off" ? Qt.color("transparent") : mode === "wallpaper" ? root.wallpaperLight : light
    }
    readonly property int radius: Math.round(Math.max(16, Math.min(40, Number(root.appearance?.expandedRadius ?? 28))) * root.density)
    readonly property int radiusSmall: Math.max(4, Math.round(root.radius * 0.58))
    readonly property int radiusTiny: Math.max(3, Math.round(root.radius * 0.36))
    readonly property int gap: Math.max(4, Math.round(8 * root.density))
    readonly property int gapLarge: Math.max(8, Math.round(14 * root.density))
    readonly property int spaceSmall: Math.max(4, Math.round(6 * root.density))
    readonly property int spaceMedium: Math.max(6, Math.round(10 * root.density))
    readonly property int spaceLarge: Math.max(10, Math.round(16 * root.density))

    readonly property var presets: ({
        iris: { fill: 1.0, shape: 1.0, textStrong: 0.82, textSecondary: 0.62, textTertiary: 0.40,
            subtext: "#aeaeb2", muted: "#8e8e93", hairline: "#262628", hairlineStrong: "#48484a" },
        soft: { fill: 0.78, shape: 1.22, textStrong: 0.78, textSecondary: 0.58, textTertiary: 0.36,
            subtext: "#a1a1a6", muted: "#838388", hairline: "#1f1f21", hairlineStrong: "#3a3a3c" },
        crisp: { fill: 1.12, shape: 0.7, textStrong: 0.86, textSecondary: 0.66, textTertiary: 0.42,
            subtext: "#b4b4b9", muted: "#929297", hairline: "#2c2c2e", hairlineStrong: "#545456" },
        round: { fill: 0.9, shape: 1.5, textStrong: 0.8, textSecondary: 0.6, textTertiary: 0.38,
            subtext: "#a8a8ad", muted: "#8a8a8f", hairline: "#222224", hairlineStrong: "#404042" },
        angular: { fill: 1.08, shape: 0.42, textStrong: 0.86, textSecondary: 0.64, textTertiary: 0.42,
            subtext: "#b0b0b5", muted: "#909095", hairline: "#2a2a2c", hairlineStrong: "#505052" },
        contrast: { fill: 1.6, shape: 1.0, textStrong: 0.94, textSecondary: 0.8, textTertiary: 0.6,
            subtext: "#d1d1d6", muted: "#aeaeb2", hairline: "#3a3a3c", hairlineStrong: "#6c6c70" }
    })
    readonly property string presetName: root.presets[root.appearance?.preset ?? ""] ? root.appearance.preset : "iris"
    readonly property var preset: root.presets[root.presetName]

    readonly property string fontMain: {
        const configured = String(root.appearance?.fontFamily ?? "")
        return configured.length > 0 ? configured : "Noto Sans"
    }
    readonly property string fontTitle: {
        const configured = String(root.appearance?.titleFontFamily ?? "")
        return configured.length > 0 ? configured : "Readex Pro"
    }
    readonly property int figureWeight: ({ light: Font.Light, regular: Font.Normal })[root.appearance?.figureWeight ?? "bold"] ?? Font.Bold
    readonly property string fontNumbers: {
        const configured = String(root.appearance?.numbersFontFamily ?? "")
        return configured.length > 0 ? configured : "Rubik"
    }

    readonly property color canvas: Appearance.colors.colLayer0Base
    readonly property var materials: ({ black: "#000000", graphite: "#141416", midnight: "#0a0d17" })
    function materialOf(seed, fallback): color {
        const c = Qt.color(seed)
        if (!c.valid || c.hslHue < 0 || c.hslSaturation < 0.08) return fallback
        return Qt.hsla(c.hslHue, Math.max(0.28, Math.min(0.55, c.hslSaturation)), 0.09, 1)
    }
    readonly property color wallpaperMaterial: root.materialOf(Appearance.wallpaperDominantColor,
        root.materialOf(Appearance.colors.colPrimary, root.materials.graphite))
    readonly property color themeMaterial: {
        const background = Qt.color(Appearance.m3colors.m3background)
        return background.hslLightness <= 0.2 ? Qt.rgba(background.r, background.g, background.b, 1)
            : root.materialOf(Appearance.colors.colPrimary, root.materials.graphite)
    }
    function materialSwatch(name: string): color {
        if (name === "theme") return root.themeMaterial
        return name === "wallpaper" ? root.wallpaperMaterial : (root.materials[name] ?? root.materials.black)
    }
    readonly property color surfaceOpaque: root.materialSwatch(root.theme?.surface ?? "black")
    readonly property bool plainBlack: (root.theme?.surface ?? "black") === "black"
    readonly property color surfaceHighOpaque: root.plainBlack ? "#1c1c1e" : ColorUtils.mix(root.text, root.surfaceOpaque, 0.1)
    readonly property color surfaceHighestOpaque: root.plainBlack ? "#2c2c2e" : ColorUtils.mix(root.text, root.surfaceOpaque, 0.17)
    readonly property real tintAmount: Math.max(0, Math.min(1, Number(root.appearance?.tint ?? 0) / 100))
    readonly property color tintSeed: root.legibleAccent(Appearance.wallpaperDominantColor, root.accent)
    function tinted(base: color, strength: real): color {
        return root.tintAmount <= 0 ? base : ColorUtils.mix(base, root.tintSeed, 1 - strength * root.tintAmount)
    }
    readonly property color surface: root.surfaceOpaque
    readonly property color bodySurface: root.surfaceOpaque
    readonly property color surfaceHigh: root.tinted(root.surfaceHighOpaque, 0.16)
    readonly property color surfaceHighest: root.tinted(root.surfaceHighestOpaque, 0.2)
    readonly property color field: root.surfaceHighestOpaque
    readonly property color text: "#f5f5f7"
    readonly property color subtext: root.preset.subtext
    readonly property color muted: root.preset.muted
    function legibleAccent(seed, fallback): color {
        const c = Qt.color(seed)
        if (!c.valid || c.hslHue < 0 || c.hslSaturation < 0.12) return fallback
        return Qt.hsla(c.hslHue, Math.max(0.42, Math.min(0.8, c.hslSaturation)),
            Math.max(0.72, Math.min(0.82, c.hslLightness)), 1)
    }
    readonly property color themeAccent: root.legibleAccent(Appearance.colors.colPrimary, "#a8c7fa")
    readonly property var accents: ({ blue: "#a8c7fa", mint: "#8de0bd", rose: "#ffb2c4", lilac: "#d2baff" })
    readonly property var highlights: ({ orange: "#ff9f0a", yellow: "#ffd60a", red: "#ff6961", pink: "#ff6482", green: "#30d158" })
    readonly property color accent: {
        const choice = root.appearance?.accent ?? "blue"
        if (choice === "theme") return root.themeAccent
        if (choice === "wallpaper") return root.legibleAccent(Appearance.wallpaperDominantColor, root.themeAccent)
        if (choice === "custom") return Qt.hsla(root.hueOf("accentHue", 212), 0.7, 0.78, 1)
        return root.accents[choice] ?? root.accents.blue
    }
    readonly property color onAccent: Qt.color("#101318")
    readonly property color accentContainer: ColorUtils.mix(root.surface, root.accent, 0.78)
    readonly property color onAccentContainer: ColorUtils.mix(root.accent, root.text, 0.65)
    function vividHighlight(seed, fallback): color {
        const c = Qt.color(seed)
        if (!c.valid || c.hslHue < 0 || c.hslSaturation < 0.1) return fallback
        return Qt.hsla(c.hslHue, Math.max(0.62, Math.min(0.95, c.hslSaturation + 0.2)),
            Math.max(0.54, Math.min(0.66, c.hslLightness)), 1)
    }
    readonly property color secondaryAccent: {
        const choice = root.appearance?.highlight ?? "orange"
        if (choice === "accent") return root.accent
        if (choice === "theme") return root.vividHighlight(Appearance.colors.colTertiary, root.highlights.orange)
        if (choice === "custom") return Qt.hsla(root.hueOf("highlightHue", 32), 0.92, 0.58, 1)
        if (choice === "wallpaper") return root.vividHighlight(Appearance.colors.colSecondary,
            root.vividHighlight(Appearance.wallpaperDominantColor, root.highlights.orange))
        return root.highlights[choice] ?? root.highlights.orange
    }
    readonly property string auraName: ["off", "subtle", "vivid"].includes(root.appearance?.aura ?? "")
        ? root.appearance.aura : "subtle"
    readonly property real auraStrength: ({ off: 0, subtle: 0.2, vivid: 0.36 })[root.auraName]
    readonly property color wallpaperLight: root.vividHighlight(Appearance.wallpaperDominantColor,
        root.vividHighlight(Appearance.colors.colPrimary, root.accent))
    function surfaceWidth(id: string, fallback: int): int {
        const width = Number(root.appearance?.surfaces?.[id]?.width ?? 0)
        return width > 0 ? Math.round(width * root.density) : fallback
    }
    readonly property int lightContour: Math.max(4, Math.round(6 * root.density))
    readonly property int lightJoinContour: root.lightContour + Math.round(root.fuseDeep / 3)
    readonly property int lightReach: Math.round(92 * root.density * root.tweak("lightReach", 0.5, 3))
    function aura(light: color): color { return ColorUtils.applyAlpha(light, root.auraStrength * light.a) }
    function auraFading(light: color): color { return ColorUtils.applyAlpha(light, root.auraStrength * light.a * 0.35) }
    function skyLight(glyph: string): color {
        switch (glyph) {
        case "clear_day": return root.identity.orange
        case "partly_cloudy_day": return root.identity.sky
        case "cloud": case "foggy": return root.identity.gray
        case "rainy": return root.identity.blue
        case "thunderstorm": return root.identity.purple
        case "weather_snowy": case "cloudy_snowing": case "weather_hail": return root.identity.sky
        case "bedtime": case "partly_cloudy_night": return root.identity.indigo
        default: return root.wallpaperLight
        }
    }
    readonly property string badgeStyle: String(root.theme?.badge ?? "alert")
    readonly property color badge: root.badgeStyle === "accent" ? root.accent
        : root.badgeStyle === "highlight" ? root.secondaryAccent
        : root.badgeStyle === "neutral" ? root.surfaceHighestOpaque
        : root.identity.red
    readonly property color onBadge: root.badgeStyle === "alert" ? root.onTint
        : root.badgeStyle === "neutral" ? root.text
        : root.badgeStyle === "highlight" ? root.onTintFor(root.secondaryAccent) : root.onAccent
    readonly property color badgeInk: root.badgeStyle === "alert" ? root.danger
        : root.badgeStyle === "neutral" ? root.text : root.badge
    readonly property color success: "#8de0a3"
    readonly property color danger: "#ff6961"
    readonly property color onDanger: Qt.color("#160000")
    function line(base: color): color {
        const t = root.tweak("lines", 0, 2)
        return t <= 1 ? ColorUtils.mix(base, root.surfaceOpaque, t) : ColorUtils.mix(root.text, base, (t - 1) * 0.35)
    }
    readonly property color hairline: root.line(root.preset.hairline)
    readonly property color hairlineStrong: root.line(root.preset.hairlineStrong)
    readonly property color selection: "#303034"
    readonly property color selectionHover: "#404044"
    readonly property color selectionText: "#ffffff"
    readonly property color scrim: Appearance.colors.colScrim

    function fillAlpha(level: real): real { return Math.min(0.5, level * root.preset.fill * root.tweak("fill", 0.3, 2)) }
    readonly property color fillInk: root.tinted(root.text, 0.22)
    readonly property color fillQuiet: ColorUtils.applyAlpha(root.fillInk, root.fillAlpha(0.08))
    readonly property color fill: ColorUtils.applyAlpha(root.fillInk, root.fillAlpha(0.12))
    readonly property color fillHover: ColorUtils.applyAlpha(root.fillInk, root.fillAlpha(0.18))
    readonly property color fillActive: ColorUtils.applyAlpha(root.fillInk, root.fillAlpha(0.26))
    readonly property color fillStrong: ColorUtils.applyAlpha(root.fillInk, Math.min(0.9, 0.6 * root.preset.fill * root.tweak("fill", 0.3, 2)))
    function tintFill(tint: color): color { return ColorUtils.applyAlpha(tint, root.fillAlpha(0.18)) }
    function tintFillHover(tint: color): color { return ColorUtils.applyAlpha(tint, root.fillAlpha(0.28)) }
    function tintBorder(tint: color): color { return ColorUtils.applyAlpha(tint, 0.7) }

    function textLevel(level: real): real { return Math.min(1, level * root.tweak("contrast", 0.6, 1.5)) }
    readonly property color textStrong: ColorUtils.applyAlpha(root.text, root.textLevel(root.preset.textStrong))
    readonly property color textSecondary: ColorUtils.applyAlpha(root.text, root.textLevel(root.preset.textSecondary))
    readonly property color textTertiary: ColorUtils.applyAlpha(root.text, root.textLevel(root.preset.textTertiary))
    function strongOf(ink: color): color { return ColorUtils.applyAlpha(ink, root.textLevel(root.preset.textStrong)) }
    function secondaryOf(ink: color): color { return ColorUtils.applyAlpha(ink, root.textLevel(root.preset.textSecondary)) }
    function tertiaryOf(ink: color): color { return ColorUtils.applyAlpha(ink, root.textLevel(root.preset.textTertiary)) }
    readonly property color border: ColorUtils.applyAlpha(root.text, Math.min(0.5, 0.12 * root.preset.fill * root.tweak("lines", 0, 2)))
    readonly property color borderStrong: ColorUtils.applyAlpha(root.text, Math.min(0.6, 0.28 * root.preset.fill * root.tweak("lines", 0, 2)))
    readonly property color rim: (root.theme?.rim ?? true) ? root.border : Qt.color("transparent")
    readonly property color onTint: "#ffffff"
    function onTintFor(tint: color): color { return tint.hslLightness > 0.6 ? root.onAccent : root.onTint }

    readonly property color veilLight: ColorUtils.applyAlpha(root.surface, 0.22)
    readonly property color veil: ColorUtils.applyAlpha(root.surface, 0.42)
    readonly property color veilStrong: ColorUtils.applyAlpha(root.surface, 0.62)
    readonly property color veilHeavy: ColorUtils.applyAlpha(root.surface, 0.76)
    readonly property color shadow: Qt.rgba(0, 0, 0, Math.min(0.9, 0.55 * root.tweak("shadow", 0, 1.6)))
    readonly property color material: ColorUtils.applyAlpha(root.surfaceHigh, 0.68)
    readonly property color onMedia: "#ffffff"
    readonly property color onMediaSecondary: ColorUtils.applyAlpha(root.onMedia, 0.72)
    readonly property color onMediaFill: ColorUtils.applyAlpha(root.onMedia, 0.2)
    readonly property color onMediaFillHover: ColorUtils.applyAlpha(root.onMedia, 0.3)
    readonly property color mediaScrim: Qt.rgba(0, 0, 0, 0.34)
    readonly property color plateShadow: Qt.rgba(0, 0, 0, Math.min(0.9, 0.36 * root.tweak("shadow", 0, 1.6)))
    function skyWash(light: color): color { return ColorUtils.applyAlpha(light, 0.46) }
    function skyWashFade(light: color): color { return ColorUtils.applyAlpha(light, 0.05) }

    readonly property QtObject identity: QtObject {
        readonly property color blue: "#0a84ff"
        readonly property color sky: "#64d2ff"
        readonly property color teal: "#30b0c7"
        readonly property color green: "#34c759"
        readonly property color yellow: "#e0a800"
        readonly property color orange: "#ff9f0a"
        readonly property color red: "#ff453a"
        readonly property color pink: "#ff375f"
        readonly property color indigo: "#5e5ce6"
        readonly property color purple: "#bf5af2"
        readonly property color lavender: "#b4a0ff"
        readonly property color gray: "#8e8e93"
    }

    function identityColor(name: string): color { return root.identity[name] ?? root.identity.lavender }

    readonly property real shapeScale: root.preset.shape * root.tweak("shape", 0.3, 1.6)
    function corner(px: real): int { return Math.max(2, Math.round(px * root.shapeScale * root.density)) }
    readonly property int radiusPanel: root.corner(30)   // Control Center, Settings frame
    readonly property int radiusSheet: root.corner(26)   // Spotlight, media card, wallpaper picker
    readonly property int radiusPlate: root.corner(22)   // widget and lock plates, dialogs, blocks
    readonly property int radiusCard: root.corner(18)    // side-panel sections, menus
    readonly property int radiusTile: root.corner(14)    // grouped cards, tiles, results
    readonly property int radiusRow: root.corner(10)     // list rows, menu items, small buttons
    readonly property int radiusChip: root.corner(7)     // chips, thumbnails, small marks
    readonly property int radiusMicro: root.corner(4)    // bars inside skeletons, swatches
    readonly property int fuse: Math.max(2, Math.round(8 * root.density * root.tweak("melt", 0, 2)))
    readonly property int fuseDeep: Math.max(4, Math.round(30 * root.density * root.tweak("melt", 0, 2)))
    readonly property real islandBandScale: Math.max(32, Math.min(64, Number(root.options?.bar?.height ?? 42))) / 42
    readonly property int fuseEdge: Math.max(8, Math.round(56 * root.density * root.islandBandScale
        * Math.max(0.2, Math.min(2, Number(root.options?.bar?.notchCurve ?? 100) / 100))))
    readonly property int weld: Math.max(2, Math.round(3 * root.density))
    readonly property string pieceShape: String(root.theme?.pieceShape ?? "circle")
    function pieceRadius(size: real): real {
        const half = size / 2
        if (root.pieceShape === "squircle") return Math.min(half, size * 0.34 * Math.max(0.6, root.shapeScale))
        if (root.pieceShape === "square") return Math.min(half, size * 0.22 * Math.max(0.6, root.shapeScale))
        return half
    }
    function iconRadius(size: real): int { return Math.round(size * 0.26 * Math.min(1.2, root.shapeScale)) }

    readonly property real panelPadding: Math.round(24 * root.density)
    readonly property real sectionGap: Math.round(24 * root.density)
    readonly property real controlHeight: Math.round(38 * root.density)
    readonly property real compactControlHeight: Math.round(32 * root.density)
    readonly property real headerHeight: Math.round(54 * root.typeScale)
    readonly property real accentRuleWidth: Math.round(24 * root.density)
    readonly property real accentRuleHeight: Math.max(2, Math.round(3 * root.density))

    readonly property bool motionEnabled: (root.appearance?.motion ?? true) && Appearance.animationsEnabled
        && root.appearance?.morph !== "instant"
    function duration(ms: int): int {
        return root.motionEnabled ? Appearance.calcEffectiveDuration(ms) : 0
    }

    readonly property var curves: ({ expressive: [0.16, 1, 0.3, 1], standard: [0.2, 0, 0, 1], gentle: [0.4, 0, 0.2, 1], swift: [0.3, 0.9, 0.2, 1], fold: [0.3, 0, 0.2, 1] })
    readonly property var directCurve: {
        const name = String(root.theme?.curve ?? "expressive")
        if (name !== "custom") return root.curves[name] ?? root.curves.expressive
        const p = root.theme?.curvePoints ?? []
        const at = (i, low, high, fallback) => Math.max(low, Math.min(high, Number(p[i] ?? fallback)))
        return [at(0, 0, 1, 0.16), at(1, -0.5, 1.5, 1), at(2, 0, 1, 0.3), at(3, -0.5, 1.5, 1)]
    }
    readonly property var morphStyles: ({
        direct: { curve: true, emerge: { response: 1.8 }, recede: { response: 1.2, curve: "fold" }, move: { response: 1 },
            rise: 0.3, span: 0.35, fall: 0.12, reveal: "drop" },
        liquid: { emerge: { response: 1.9, bounce: 0.22 }, recede: { response: 1.3, bounce: 0 }, move: { response: 1.15, bounce: 0.08 },
            rise: 0.34, span: 0.42, fall: 0.24, reveal: "drop" },
        glide: { emerge: { response: 2.1, bounce: 0 }, recede: { response: 1.5, bounce: 0 }, move: { response: 1.35, bounce: 0 },
            rise: 0.3, span: 0.5, fall: 0.28, reveal: "drop" },
        snap: { emerge: { response: 1.25, bounce: 0.06 }, recede: { response: 0.95, bounce: 0 }, move: { response: 0.85, bounce: 0 },
            rise: 0.18, span: 0.34, fall: 0.2, reveal: "fade" },
        elastic: { emerge: { response: 2.2, bounce: 0.34 }, recede: { response: 1.4, bounce: 0 }, move: { response: 1.5, bounce: 0.24 },
            rise: 0.36, span: 0.4, fall: 0.28, reveal: "inflate" },
        instant: { emerge: { response: 1, bounce: 0 }, recede: { response: 1, bounce: 0 }, move: { response: 1, bounce: 0 },
            rise: 0.01, span: 0.01, fall: 0.01, reveal: "fade" }
    })
    readonly property string morphName: root.morphStyles[root.appearance?.morph ?? ""] ? root.appearance.morph : "direct"
    readonly property var morph: root.morphStyles[root.morphName]

    readonly property string revealName: String(root.morph?.reveal ?? "curtain")
    readonly property real absorbShare: 0.55
    readonly property real pullLag: 1.8
    readonly property real dropRise: Math.max(0, Math.min(0.7, 0.06 + 0.4 * (root.tweak("contentTiming", 0.3, 1.7) - 1)))
    readonly property real dropSpan: 0.3
    readonly property bool revealDrops: root.revealName === "drop" && root.motionEnabled
    readonly property bool revealInflates: root.revealName === "inflate" && root.motionEnabled
    readonly property bool revealFades: root.revealName === "fade" || !root.motionEnabled

    readonly property int baseDuration: Math.max(100, Math.min(400, Number(root.appearance?.motionDuration ?? 220)))
    function resolveSpring(entry: var, fallbackResponse: real, timeTweak: string): var {
        const response = Math.round(root.baseDuration * Math.max(0.2, Number(entry?.response ?? fallbackResponse)) * root.tweak(timeTweak, 0.4, 2.5))
        const bounce = Number(entry?.bounce ?? 0) * root.tweak("bounce", 0, 2)
        const curve = !root.morph?.curve ? null : entry?.curve ? root.curves[entry.curve] : root.directCurve
        return { response: root.duration(response), bounce: curve ? 0 : Math.max(0, Math.min(0.6, bounce)), curve: curve }
    }
    readonly property var emergeSpring: root.resolveSpring(root.morph?.emerge, 1.9, "openTime")
    readonly property var recedeSpring: root.resolveSpring(root.morph?.recede, 1.3, "openTime")
    readonly property var moveSpring: root.resolveSpring(root.morph?.move, 1.15, "moveTime")
    function surfaceSpeed(id: string): real {
        return id.length === 0 ? 1 : Math.max(0.4, Math.min(2.5, Number(root.appearance?.surfaces?.[id]?.speed ?? 100) / 100))
    }
    function springFor(intent: string, surface: string): var {
        const base = intent === "move" ? root.moveSpring : intent === "emerge" ? root.emergeSpring : root.recedeSpring
        const speed = root.surfaceSpeed(surface)
        return speed === 1 ? base : Object.assign({}, base, { response: Math.round(base.response / speed) })
    }
    function pressScale(base: real): real { return 1 - (1 - base) * root.tweak("press", 0, 2) }

    function springState(t: real, bounce: real): var {
        const w = 2 * Math.PI
        const zeta = 1 - bounce
        if (zeta < 0.9999) {
            const wd = w * Math.sqrt(1 - zeta * zeta)
            const e = Math.exp(-zeta * w * t)
            const b = -zeta * w / wd
            const c = Math.cos(wd * t), s = Math.sin(wd * t)
            const d = e * (-c + b * s)
            return { y: 1 + d, v: -zeta * w * d + e * (wd * s + b * wd * c) }
        }
        const e = Math.exp(-w * t)
        return { y: 1 - (1 + w * t) * e, v: w * w * t * e }
    }
    function springSettle(bounce: real): real {
        let last = 0
        for (let t = 0; t < 4; t += 0.004)
            if (Math.abs(root.springState(t, bounce).y - 1) >= 0.002) last = t
        return Math.max(0.4, last)
    }
    // At most ten segments: Qt 6.11 segfaults on a 12-segment BezierSpline.
    function springCurve(bounce: real): var {
        const segments = 8
        const settle = root.springSettle(bounce)
        const points = []
        for (let i = 0; i < segments; ++i) {
            const u0 = i / segments, u1 = (i + 1) / segments, h = 1 / segments
            const a = root.springState(u0 * settle, bounce)
            const last = i === segments - 1
            const b = last ? { y: 1, v: 0 } : root.springState(u1 * settle, bounce)
            points.push(u0 + h / 3, a.y + a.v * settle * h / 3, u1 - h / 3, b.y - b.v * settle * h / 3, u1, b.y)
        }
        return points
    }
    function curveOf(spring: var): var {
        return spring.curve ? spring.curve.concat([1, 1]) : root.springCurve(spring.bounce)
    }
    function durationOf(spring: var): int {
        return spring.curve ? spring.response : Math.round(spring.response * root.springSettle(spring.bounce))
    }
    function cubicBezier(curve: var, x: real): real {
        if (x <= 0) return 0
        if (x >= 1) return 1
        const cx = 3 * curve[0], bx = 3 * (curve[2] - curve[0]) - cx, ax = 1 - cx - bx
        const cy = 3 * curve[1], by = 3 * (curve[3] - curve[1]) - cy, ay = 1 - cy - by
        let t = x
        for (let i = 0; i < 8; ++i) {
            const fx = ((ax * t + bx) * t + cx) * t - x
            const d = (3 * ax * t + 2 * bx) * t + cx
            if (Math.abs(fx) < 1e-5 || Math.abs(d) < 1e-6) break
            t = Math.max(0, Math.min(1, t - fx / d))
        }
        return ((ay * t + by) * t + cy) * t
    }
    readonly property var emergeCurve: root.curveOf(root.emergeSpring)
    readonly property var recedeCurve: root.curveOf(root.recedeSpring)
    readonly property var moveCurve: root.curveOf(root.moveSpring)
    readonly property int emergeDuration: root.durationOf(root.emergeSpring)
    readonly property int recedeDuration: root.durationOf(root.recedeSpring)
    readonly property int moveDuration: root.durationOf(root.moveSpring)
    readonly property real contentRise: Math.min(0.95, Number(root.morph?.rise ?? 0.34) * root.tweak("contentTiming", 0.3, 1.7))
    readonly property real contentSpan: Math.max(0.01, Number(root.morph?.span ?? 0.42))
    readonly property real contentFall: Math.max(0.02, Number(root.morph?.fall ?? 0.24))
    function ramp(t: real, rise: real, span: real): real {
        return Math.max(0, Math.min(1, (t - rise) / Math.max(0.01, span)))
    }
    function contentAt(t: real): real { return root.ramp(t, root.contentRise, root.contentSpan) }
    // A floating body's shadow arrives with its settle, never under a shape that is still growing.
    function shadowAt(t: real): real { return Math.pow(Math.max(0, Math.min(1, t)), 4) }

    readonly property int morphDuration: root.moveDuration
    readonly property int settleDuration: root.emergeDuration
    readonly property int revealDuration: duration(140)
    readonly property int feedbackDuration: duration(100)
    readonly property int feedbackEasing: Easing.OutCubic
    readonly property var morphCurve: root.moveCurve
}
