pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.style
import qs.services
import qs.modules.shared.background.widgets

// Desktop widgets under iRiS: its faces (`widget.widgetIris`) and the other designs it wears.
WidgetLook {
    id: look

    readonly property var options: Config.options?.iris?.widgets ?? ({})

    // Glass turns to frost over a bright wallpaper only when asked; off, the scheme keeps its own ink and accents and
    // Lume's shadow carries them: bare faces turned black over every light patch against that switch (10-31).
    adaptsToWallpaper: Boolean(Config.getNestedValue("iris.widgets.brightWallpapers", false))
    schemeInk: !look.adaptsToWallpaper
    legibleAlways: Boolean(look.options.legibleAlways ?? false)
    shadowsBare: true
    // With the wallpaper unread iRiS keeps its light ink; the shell's light mode says nothing about what is under a bare widget.
    unreadIsLight: false
    unreadInk: IrisStyle.inkOnDark
    restBackdrop: IrisStyle.inkOnLight
    inkLight: IrisStyle.inkOnDark
    inkDark: IrisStyle.inkOnLight

    // Widgets keep the black Island material but can borrow the wallpaper: its generated hues are lifted into a range
    // that reads on black, and the plate can carry a trace of the same hue. Greyscale seeds keep iRiS blue.
    readonly property string paletteName: {
        const name = String(look.options.tint ?? "wallpaper")
        return IrisStyle.widgetPaletteNames.includes(name) ? name : "wallpaper"
    }
    readonly property real vibrance: Math.max(0, Math.min(100, Number(look.options.vibrance ?? 85))) / 100
    readonly property var palette: IrisStyle.widgetPalette(look.paletteName, look.vibrance)
    readonly property color accent: look.palette[0]
    readonly property color accent2: look.palette[1]
    readonly property color accent3: look.palette[2]
    readonly property color tintedPlate: ColorUtils.mix(IrisStyle.surface, look.accent, 0.82)
    readonly property bool rim: Boolean(look.options.rim ?? false)
    readonly property var materials: ["glass", "clear", "solid", "tinted"]

    function material(widget: var): string {
        // the widget's Background switch, the same one every family's edit mode turns off for all
        if (!widget.showBackground) return "clear"
        const own = String(widget._readConfigKey("iris.material") ?? "auto")
        const shared = String(look.options.material ?? "glass")
        return look.materials.includes(own) ? own : look.materials.includes(shared) ? shared : "glass"
    }
    function plate(widget: var): color { return look.material(widget) === "tinted" ? look.tintedPlate : IrisStyle.surface }
    function outline(widget: var): string {
        if (!widget.showBorder) return "none"
        const value = String(look.options.outline ?? "auto")
        return ["auto", "always", "none"].includes(value) ? value : "auto"
    }
    function surfaceOpacity(widget: var): real {
        const own = Number(widget._readConfigKey("iris.opacity") ?? -1)
        const value = own >= 20 ? own : Number(look.options.opacity ?? 100)
        return Math.max(0, Math.min(100, Number.isFinite(value) ? value : 100)) / 100
    }

    function plated(widget: var): bool {
        return widget.irisFaced ? look.material(widget) !== "clear"
            : widget.widgetHasSurface && (widget.backgroundOpacity > 0 || widget.effectiveBlur)
    }
    function readsRegion(widget: var): bool {
        const material = look.material(widget)
        return widget.irisFaced && (material === "glass" || material === "clear")
    }
    function plateColor(widget: var): color {
        return widget.widgetIris && widget.forceDarkInk ? ColorUtils.mix(IrisStyle.text, IrisStyle.accent, 0.98)
            : widget.widgetIris && widget.forceLightInk ? IrisStyle.surface
            : widget.widgetSemanticContainer(widget.widgetSurfaceRole)
    }

    function bodyFamily(widget: var): string { return widget.widgetIris ? IrisStyle.fontMain : Appearance.font.family.main }
    function numbersFamily(widget: var): string { return IrisStyle.fontNumbers }
    function titleFamily(widget: var): string { return widget.widgetIris ? IrisStyle.fontMain : Appearance.font.family.main }
    // Display type: one chosen weight for titles and figures, with the slight negative tracking large numerals use.
    function titleWeight(widget: var): int {
        return widget.widgetIris ? ({ light: Font.Light, regular: Font.Medium, bold: Font.Bold })[String(look.options.weight ?? "regular")] ?? Font.Medium
            : Font.DemiBold
    }
    function titleTracking(widget: var): real { return widget.widgetIris ? -0.4 : 0 }
    // Shouting caps are Material/Instrument grammar; iRiS uses sentence case.
    function capitalization(widget: var): int { return widget.widgetIris ? Font.MixedCase : Font.AllUppercase }
    function caseOf(widget: var, text: string): string {
        return widget.widgetIris ? text.charAt(0).toUpperCase() + text.slice(1) : text.toUpperCase()
    }
    function controlRadius(widget: var): real { return widget.widgetIris ? Math.round(12 * IrisStyle.density) : Appearance.rounding.normal }
    function cardRadius(widget: var): real {
        return widget.widgetIris ? Math.round(Math.max(0, Math.min(40, look.options.radius ?? 22)) * IrisStyle.density)
            : Appearance.rounding.extralarge
    }

    function semanticSet(widget: var, role: string): var {
        if (widget.widgetIris) {
            const lifted = role === "surface" ? IrisStyle.text
                : role === "signal" ? IrisStyle.danger
                : role === "success" ? IrisStyle.success
                : role === "warning" ? IrisStyle.secondaryAccent
                : role === "tertiary" ? look.accent3
                : role === "secondary" ? look.accent2 : look.accent
            const onLight = widget.inkOnLight && !widget.widgetHasSurface
            const sample = widget.widgetHasSurface || widget.regionBrightness < 0 || !look.adaptsToWallpaper ? null
                : { level: widget.regionBrightness, spread: widget.regionBrightnessSpread }
            const foreground = role === "surface" ? (onLight ? IrisStyle.inkOnLight : lifted)
                : sample ? IrisStyle.markOn(lifted, sample, onLight, 3)
                : onLight ? IrisStyle.deepAccent(lifted, IrisStyle.inkOnLight) : lifted
            const plate = look.plate(widget)
            return { color: foreground, onColor: IrisStyle.surface,
                container: role === "surface" ? plate : ColorUtils.mix(plate, IrisStyle.text, 0.9),
                onContainer: IrisStyle.text }
        }
        // Bare Material widgets under iRiS (iNstrument, Readout) draw with the same three accents as the faces. Their
        // neutral is the ink itself and their states the Island's, never the scheme's tones, which follow the shell's
        // mode rather than the wallpaper. With adaptation off the accents keep their hue and the Lume shadow holds them.
        if (!widget.widgetHasSurface) {
            const onLight = widget.inkOnLight
            if (role === "surface")
                return { color: widget.colText, onColor: onLight ? IrisStyle.inkOnDark : IrisStyle.inkOnLight,
                    container: ColorUtils.mix(IrisStyle.surface, widget.colText, 0.9), onContainer: IrisStyle.text }
            const seed = role === "signal" ? IrisStyle.dangerOnMedia : role === "warning" ? IrisStyle.highlightOnMedia
                : role === "success" ? (IrisStyle.light ? Lume.mark(IrisStyle.success, 0.35, 0, false, 3) : IrisStyle.success)
                : role === "tertiary" ? look.accent3 : role === "secondary" ? look.accent2 : look.accent
            const sample = widget.regionBrightness < 0 || !look.adaptsToWallpaper ? null
                : { level: widget.regionBrightness, spread: widget.regionBrightnessSpread }
            const shown = sample ? IrisStyle.markOn(seed, sample, onLight, 3)
                : onLight ? IrisStyle.deepAccent(seed, IrisStyle.inkOnLight) : seed
            return { color: shown, onColor: IrisStyle.onTintFor(seed),
                container: ColorUtils.mix(IrisStyle.surface, seed, 0.78), onContainer: IrisStyle.text }
        }
        return look.plainSet(widget, role)
    }
}
