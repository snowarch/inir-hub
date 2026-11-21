pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.style
import qs.services
import qs.modules.shared.background.widgets

// Desktop widgets under iRiS: its faces (`widget.familyDesign`) and the other designs it wears.
WidgetLook {
    id: look

    readonly property var options: Config.options?.iris?.widgets ?? ({})

    // Glass turns to frost over a bright wallpaper only when asked; off, the scheme keeps its own ink and accents and
    // Lume's shadow carries them: bare faces turned black over every light patch against that switch (10-31). The switch
    // speaks of bright wallpapers: a light scheme's dark ink over a dark one has nothing to read on, so it follows it.
    adaptsToWallpaper: IrisStyle.light || Boolean(Config.getNestedValue("iris.widgets.brightWallpapers", false))
    schemeInk: !look.adaptsToWallpaper
    legibleAlways: Boolean(look.options.legibleAlways ?? false)
    shadowsBare: true
    // With the wallpaper unread iRiS keeps its light ink; the shell's light mode says nothing about what is under a bare widget.
    unreadIsLight: false
    unreadInk: IrisStyle.inkOnDark
    restBackdrop: IrisStyle.inkOnLight
    inkLight: IrisStyle.inkOnDark
    inkDark: IrisStyle.inkOnLight

    density: IrisStyle.density
    labelSize: IrisStyle.typeLabel
    metaSize: IrisStyle.typeMeta
    valueSize: IrisStyle.typeMeta
    sheetTitleSize: IrisStyle.typeTitle
    metaCapitalization: Font.MixedCase
    metaSpacing: 0
    controlInk: IrisStyle.text
    valueInk: IrisStyle.textSecondary
    quietInk: IrisStyle.textTertiary
    feedbackDuration: IrisStyle.feedbackDuration
    rowRadius: IrisStyle.radiusRow
    tintedKeys: true
    chipEdge: 1
    chipEdgeColor: IrisStyle.tintBorder(IrisStyle.accent)
    tagFill: IrisStyle.raised
    tagInk: IrisStyle.text
    tagSize: IrisStyle.typeFootnote
    guideRadius: Math.round(Math.max(0, Math.min(40, look.options.radius ?? 22)) * IrisStyle.density)
    guideFill: IrisStyle.tintFill(IrisStyle.accent)
    function rowFill(hovered: bool): color { return hovered ? IrisStyle.fillHover : IrisStyle.fillQuiet }
    function markRadius(size: real): real { return IrisStyle.iconRadius(size) }
    function chipInk(selected: bool): color { return selected ? IrisStyle.text : IrisStyle.textSecondary }
    function chipGlyphInk(selected: bool): color { return selected ? IrisStyle.accent : look.chipInk(selected) }
    function chipFill(selected: bool, hovered: bool): color {
        return selected ? IrisStyle.tintFill(IrisStyle.accent) : hovered ? IrisStyle.fillHover : IrisStyle.fill
    }

    // Widgets keep the black Island material but can borrow the wallpaper: its generated hues are lifted into a range
    // that reads on black, and the plate can carry a trace of the same hue. Greyscale seeds keep iRiS blue.
    readonly property string paletteName: {
        const name = String(look.options.tint ?? "wallpaper")
        return IrisStyle.widgetPaletteNames.includes(name) ? name : "wallpaper"
    }
    function paletteFor(lightBackdrop: bool): var { return IrisStyle.widgetPaletteFor(look.paletteName, lightBackdrop) }
    readonly property var palette: look.paletteFor(IrisStyle.light)
    readonly property color accent: look.palette[0]
    readonly property color accent2: look.palette[1]
    readonly property color accent3: look.palette[2]
    readonly property color tintedPlate: ColorUtils.mix(IrisStyle.surface, look.accent, 0.82)
    readonly property bool rim: Boolean(look.options.rim ?? false)
    readonly property var materials: ["glass", "solid", "tinted"]
    readonly property string sharedMaterial: String(look.options.material ?? "glass")
    // The glass behind every widget: its own amount, so a clear Settings glass and milky widgets (or the reverse) can live together.
    readonly property real blur: Math.max(0, Math.min(100, Number(look.options.blur ?? 100))) / 100

    // The widget's own switch wins; left alone it follows the shared material, where Transparent means no plate.
    // Bare is how a widget's own Material drawing stands (big digits, an image); worn as an iRiS face it is a card like
    // every other one (his 11-07: the clock and the day stood bare under Prism).
    function plateByDefault(widget: var): bool { return (!widget.bare || Boolean(widget.familyFaced)) && look.sharedMaterial !== "clear" }
    function material(widget: var): string {
        if (widget && !widget.showBackground) return "clear"
        const own = String(widget?._readConfigKey("iris.material") ?? "auto")
        return look.materials.includes(own) ? own : look.materials.includes(look.sharedMaterial) ? look.sharedMaterial : "glass"
    }
    function plate(widget: var): color { return look.material(widget) === "tinted" ? look.tintedPlate : IrisStyle.surface }
    function outline(widget: var): string {
        if (widget && !widget.showBorder) return "none"
        const value = String(look.options.outline ?? "auto")
        return ["auto", "always", "none"].includes(value) ? value : "auto"
    }
    function surfaceOpacity(widget: var): real {
        const own = Number(widget?._readConfigKey("iris.opacity") ?? -1)
        const value = own >= 20 ? own : Number(look.options.opacity ?? 100)
        return Math.max(0, Math.min(100, Number.isFinite(value) ? value : 100)) / 100
    }

    function resetValues(widget: var): var {
        return widget.hasFamilyFace ? { "iris.material": "auto", "iris.design": "auto", "iris.opacity": -1 } : ({})
    }
    // Widgets that keep their own material or opacity, and the verbs over the shared one.
    readonly property var ownSurfaces: DesktopWidgetDesign.scan(["iris.material", "iris.opacity"],
        (key, value) => key === "iris.opacity" ? Number(value) >= 20 : look.materials.includes(String(value)))
    readonly property int ownSurfaceCount: new Set(look.ownSurfaces.map(entry => entry.output + "::" + entry.widget)).size
    function matchSurfaces(): string {
        const count = look.ownSurfaceCount
        if (count === 0) return "Every widget already follows the shared material"
        Config.setNestedValues(DesktopWidgetDesign.cleared(look.ownSurfaces, key => key === "iris.opacity" ? -1 : "auto"))
        return "matched " + count
    }
    // The shared Material picked (Settings, the shelf's Look page) is what every widget wears from then on: Transparent
    // takes every plate away, any other brings them back and drops each widget's own material. Writing the key alone left
    // widgets whose plate had been switched on by hand, or that chose a material of their own, out of step (his 11-07).
    function wearMaterial(next: string): void {
        Config.setNestedValue("iris.widgets.material", next)
        DesktopWidgetOptions.setEvery("showBackground", next !== "clear")
        if (next === "clear") return
        const own = look.ownSurfaces.filter(entry => entry.key === "iris.material")
        if (own.length > 0) Config.setNestedValues(DesktopWidgetDesign.cleared(own, () => "auto"))
    }
    // Prism's cut works the same way: the one picked for every widget is what each wears from then on. A form picked
    // in a widget's sheet kept it out of step, the weather on Board and the others on cuts of their own (his 11-20).
    readonly property var ownPrismForms: DesktopWidgetDesign.scan(["iris.prism"],
        (key, value) => value !== undefined && value !== null && !["", "auto"].includes(String(value)))
    function wearPrismForm(next: string): void {
        Config.setNestedValue("iris.widgets.prism", next)
        if (look.ownPrismForms.length > 0) Config.setNestedValues(DesktopWidgetDesign.cleared(look.ownPrismForms, () => "auto"))
    }
    function matchPrismForms(): void { look.wearPrismForm(String(look.options.prism ?? "quiet")) }
    function materialAction(action: string): string {
        const now = look.sharedMaterial
        if (action === "match") return look.matchSurfaces()
        if (action === "status") return now + " · " + look.ownSurfaceCount + " widgets with their own material or opacity"
        if (action === "toggle" || action === "clear" || action === "glass") {
            const show = action === "toggle" ? DesktopWidgetOptions.everyState("showBackground") === "false" : action === "glass"
            if (action === "glass" && now === "clear") Config.setNestedValue("iris.widgets.material", "glass")
            else if (!show && now !== "clear" && action === "clear") Config.setNestedValue("iris.widgets.material", "clear")
            DesktopWidgetOptions.setEvery("showBackground", show)
            return show ? "glass" : "clear"
        }
        return "Use status, match, toggle, clear or glass"
    }

    function plated(widget: var): bool {
        return widget.familyFaced ? look.material(widget) !== "clear"
            : widget.widgetHasSurface && (widget.backgroundOpacity > 0 || widget.effectiveBlur)
    }
    function readsRegion(widget: var): bool {
        const material = look.material(widget)
        return material === "glass" || material === "clear"
    }
    function plateColor(widget: var): color {
        const onLight = widget.forceDarkInk ? true : widget.forceLightInk ? false
            : IrisStyle.light || (look.material(widget) === "glass" && widget.glassInkOnLight)
        return onLight && !IrisStyle.light ? IrisStyle.frost
            : !onLight && IrisStyle.light ? IrisStyle.darkSurfaceOpaque
            : look.plate(widget)
    }

    function bodyFamily(widget: var): string { return widget.familyDesign ? IrisStyle.fontMain : Appearance.font.family.main }
    function numbersFamily(widget: var): string { return IrisStyle.fontNumbers }
    function titleFamily(widget: var): string { return widget.familyDesign ? IrisStyle.fontMain : Appearance.font.family.main }
    // Display type: one chosen weight for titles and figures, with the slight negative tracking large numerals use.
    function titleWeight(widget: var): int {
        return widget.familyDesign ? ({ light: Font.Light, regular: Font.Medium, bold: Font.Bold })[String(look.options.weight ?? "regular")] ?? Font.Medium
            : Font.DemiBold
    }
    function titleTracking(widget: var): real { return widget.familyDesign ? -0.4 : 0 }
    // Shouting caps are Material/Instrument grammar; iRiS uses sentence case.
    function capitalization(widget: var): int { return widget.familyDesign ? Font.MixedCase : Font.AllUppercase }
    function caseOf(widget: var, text: string): string {
        return widget.familyDesign ? text.charAt(0).toUpperCase() + text.slice(1) : text.toUpperCase()
    }
    function controlRadius(widget: var): real { return widget.familyDesign ? Math.round(12 * IrisStyle.density) : Appearance.rounding.normal }
    function cardRadius(widget: var): real {
        return widget.familyDesign ? Math.round(Math.max(0, Math.min(40, look.options.radius ?? 22)) * IrisStyle.density)
            : Appearance.rounding.extralarge
    }

    function semanticSet(widget: var, role: string): var {
        const plated = widget.widgetHasSurface
        const onLight = plated
            ? (widget.forceDarkInk ? true : widget.forceLightInk ? false
                : IrisStyle.light || (look.material(widget) === "glass" && widget.glassInkOnLight))
            : widget.inkOnLight
        const pal = look.paletteFor(onLight)
        const ink = onLight ? (IrisStyle.light ? IrisStyle.text : IrisStyle.inkOnLight)
            : (IrisStyle.light ? IrisStyle.inkOnDark : IrisStyle.text)
        const plate = onLight && !IrisStyle.light ? IrisStyle.frost
            : !onLight && IrisStyle.light ? IrisStyle.darkSurfaceOpaque
            : look.plate(widget)
        if (role === "surface") {
            return { color: plated ? ink : widget.colText,
                onColor: onLight ? IrisStyle.inkOnDark : IrisStyle.inkOnLight,
                container: plate, onContainer: ink }
        }
        const warmSeed = look.paletteName === "mono" ? pal[1]
            : look.paletteName === "wallpaper" ? pal[0]
            : IrisStyle.widgetRoleFor("highlight", onLight, IrisStyle.secondaryAccent)
        const seed = role === "signal" ? IrisStyle.widgetRoleFor("danger", onLight, IrisStyle.danger)
            : role === "success" ? IrisStyle.widgetRoleFor("success", onLight, IrisStyle.success)
            : role === "warning" ? warmSeed
            : role === "tertiary" ? pal[2]
            : role === "secondary" ? pal[1] : pal[0]
        const sample = plated || widget.regionBrightness < 0 ? null
            : { level: widget.regionBrightness, spread: widget.regionBrightnessSpread }
        const shown = sample ? IrisStyle.markOn(seed, sample, onLight, 4.5) : seed
        return { color: shown, onColor: IrisStyle.onTintFor(shown),
            container: ColorUtils.mix(plate, shown, 0.84), onContainer: ink }
    }
}
