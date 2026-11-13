pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.services
import qs.modules.iris.style
import qs.modules.iris.pieces
import qs.modules.iris.frame
import qs.modules.iris.control
import qs.modules.iris.state
import qs.modules.iris.background
import qs.modules.iris.widgets
import qs
import qs.modules.shared.background.widgets
import "root:modules/common/widgets/GlyphArt.js" as Glyphs

QtObject {
    id: root

    function plain(value: var): var {
        if (value === null || value === undefined || typeof value !== "object") return value
        if (value.length !== undefined && typeof value !== "string") return Array.from(value, item => root.plain(item))
        const out = {}
        for (const key of Object.keys(value)) out[key] = root.plain(value[key])
        return out
    }
    function same(a: var, b: var): bool {
        return JSON.stringify(root.plain(a)) === JSON.stringify(root.plain(b))
    }
    // The Organic wave's curated scenes, as one bundle over every key any of them sets (a key a scene leaves out is kept).
    readonly property var waveKeys: {
        const keys = []
        for (const scene of OrganicEdgeConfig.scenePresets)
            for (const key of Object.keys(scene.values)) if (!keys.includes(key)) keys.push(key)
        return keys
    }
    function waveScene(name: string, label: string, glyph: string): var {
        const scene = OrganicEdgeConfig.scenePresets.find(entry => entry.name === name)
        return { label: label, value: name, glyph: glyph, values: root.waveKeys.map(key => scene?.values[key] !== undefined ? scene.values[key] : null) }
    }
    function waveShown(): bool { return Boolean(Config.options?.background?.edgeWidgets?.organic?.enable) }
    // ── The Edge wave (Organic edge), whole, in Now Playing, after the group's own rows (`trail`) ──
    function edge(key: string, label: string, kind: string, extra: var): var {
        return Object.assign({ section: "player", group: "Edge wave", path: OrganicEdgeConfig.path + "." + key, label: label, kind: kind,
            fallback: OrganicEdgeConfig.defaults[key], visibleWhen: "iris.surround.music=widget", showIf: () => Boolean(Config.options?.background?.edgeWidgets?.organic?.enable), tune: true, trail: true }, extra ?? {})
    }
    function edgeChoices(list: var): var { return list.map(entry => ({ label: entry[1], value: entry[0] })) }
    readonly property var edgeRows: [
        root.edge("edges", "Sides", "pieces", { part: "Where", choices: root.edgeChoices([["top", "Top"], ["right", "Right"], ["bottom", "Bottom"], ["left", "Left"]]), tune: false }),
        root.edge("respectPanels", "Respect bars and dock", "switch", { part: "Where" }),
        root.edge("joinMode", "Corner relationship", "choice", { part: "Where", choices: root.edgeChoices([["auto", "Join connected edges"], ["separate", "Keep edges separate"]]) }),
        ...[["span", "Edge length", 10, 100, 5, " %"], ["position", "Position along edge", 0, 100, 1, " %"], ["depth", "Field depth", 24, 600, 4, " px"],
            ["inset", "Screen inset", 0, 160, 2, " px"], ["cornerRadius", "Screen corner radius", 0, 160, 2, " px"], ["cornerBlend", "Corner handoff", 0, 100, 5, " %"],
            ["taper", "Endpoint softness", 0, 50, 1, " %"], ["topScale", "Top reach", 10, 200, 5, " %"], ["rightScale", "Right reach", 10, 200, 5, " %"],
            ["bottomScale", "Bottom reach", 10, 200, 5, " %"], ["leftScale", "Left reach", 10, 200, 5, " %"]]
            .map(entry => root.edge(entry[0], entry[1], "range", { part: "Where", min: entry[2], max: entry[3], step: entry[4], unit: entry[5] })),
        root.edge("style", "Material", "choice", { part: "Material", choices: root.edgeChoices([["silk", "Silk"], ["aurora", "Aurora"], ["contour", "Contour"], ["liquid", "Liquid"]]) }),
        root.edge("shape", "Contour language", "choice", { part: "Material", choices: root.edgeChoices([["flow", "Flow"], ["ribbon", "Ribbon"], ["cells", "Pulse cells"], ["filament", "Filament"]]) }),
        root.edge("colorMode", "Color movement", "choice", { part: "Material", choices: root.edgeChoices([["flow", "Flow"], ["spectrum", "Spectrum"], ["pulse", "Beat"], ["static", "Static"]]) }),
        root.edge("effectMode", "Light behavior", "choice", { part: "Material", choices: root.edgeChoices([["clean", "Clean"], ["shimmer", "Harmonic shimmer"], ["echo", "Pulse echo"], ["prism", "Spectral prism"],
            ["bloom", "Bass bloom"], ["caustic", "Liquid caustics"], ["afterglow", "Peak afterglow"]]) }),
        ...[["primaryColor", "Primary"], ["secondaryColor", "Secondary"], ["tertiaryColor", "Tertiary"]]
            .map(entry => root.edge(entry[0], entry[1], "text", { part: "Material", placeholder: String(OrganicEdgeConfig.defaults[entry[0]]), showIf: () => Boolean(Config.options?.background?.edgeWidgets?.organic?.enable)
                && String(Config.getNestedValue(OrganicEdgeConfig.path + ".palette", "theme")) === "custom" })),
        ...[["thickness", "Body weight", 5, 70, 1], ["bodyOpacity", "Body opacity", 0, 100, 5], ["crestStrength", "Crest brightness", 0, 150, 5], ["detail", "Contour detail", 0, 100, 5],
            ["glow", "Glow intensity", 0, 100, 5], ["glowSpread", "Glow spread", 0, 100, 5], ["effectStrength", "Effect strength", 0, 100, 5],
            ["colorSpeed", "Color travel", 0, 100, 5], ["colorIntensity", "Color intensity", 0, 150, 5]]
            .map(entry => root.edge(entry[0], entry[1], "range", { part: "Material", min: entry[2], max: entry[3], step: entry[4], unit: " %" })),
        root.edge("hueShift", "Hue shift", "range", { part: "Material", min: -180, max: 180, step: 5, unit: "°" }),
        root.edge("restPresence", "Rest presence", "range", { part: "Music", min: 0, max: 100, step: 5, unit: " %" }),
        root.edge("frequencyProfile", "Frequency focus", "choice", { part: "Music", choices: root.edgeChoices([["flat", "Balanced"], ["bass", "Bass"], ["warm", "Warm"], ["vocal", "Vocals"], ["treble", "Treble"], ["smile", "Bass + treble"]]) }),
        root.edge("flowDirection", "Travel direction", "choice", { part: "Music", choices: root.edgeChoices([["clockwise", "Clockwise"], ["counterclockwise", "Counter-clockwise"]]) }),
        ...[["motionSpeed", "Motion speed", 0, 250, 5, " %"], ["idleMotion", "Ambient motion", 0, 100, 5, " %"], ["sensitivity", "Audio sensitivity", 0, 200, 5, " %"],
            ["audioRange", "Audio range", 0, 150, 5, " %"], ["pulse", "Beat pulse", 0, 150, 5, " %"], ["beatGlow", "Beat glow", 0, 150, 5, " %"],
            ["transientStrength", "Transient punch", 0, 150, 5, " %"], ["attack", "Attack speed", 20, 250, 5, " %"], ["release", "Release speed", 20, 250, 5, " %"],
            ["smoothing", "Audio smoothing", 0, 8, 1, ""], ["bassDrive", "Bass drive", 0, 150, 5, " %"], ["trebleDrive", "Treble shimmer", 0, 150, 5, " %"],
            ["compression", "Frequency separation", 0, 100, 5, " %"], ["accentStrength", "Frequency emphasis", 0, 100, 5, " %"]]
            .map(entry => root.edge(entry[0], entry[1], "range", { part: "Music", min: entry[2], max: entry[3], step: entry[4], unit: entry[5] })),
        root.edge("screenList", "Screens", "pieces", { part: "Where", choicesFrom: "screens", description: "None chosen shows it on every screen.", showIf: () => Boolean(Config.options?.background?.edgeWidgets?.organic?.enable) && Quickshell.screens.length > 1 })
    ]

    // An icon row is keyed by its piece inside one shared list, not by its own path.
    function currentValue(spec: var): var {
        if (spec.widget) return DesktopWidgetOptions.read(spec)
        if (spec.widgetDesign) return DesktopWidgetDesign.current
        // The family's own glass through the compositor keeps its values here; the base only writes them.
        if (spec.comp === "blur") return IrisCompositorBlur[spec.read ?? spec.key]
        if (spec.comp) return CompositorConfig.value(spec)
        if (spec.kind === "niriMotion") return NiriAnimationPresets.activeId
        // A row over something that is not config (Night Light, game mode) reads it live.
        if (spec.state) return spec.state()
        if (spec.kind === "icon") return IrisPieces.chosenGlyph(String(spec.piece ?? ""))
        if (/^iris\.bubbles\.extras\.\w+\.enable$/.test(String(spec.path ?? "")) && IrisPieces.listedOnIsland(String(spec.path).split(".")[3]))
            return false
        // A flags row lists the keys of one object that are on.
        if (spec.flags) return Object.keys(Config.getNestedValue(spec.flags, ({})) ?? ({})).filter(key => Boolean(Config.getNestedValue(spec.flags + "." + key, true)))
        if (spec.bundle) {
            if (spec.keyed) return String(Config.getNestedValue(spec.bundle[0], "") ?? "")
            // A null in a choice's values is a key that choice leaves as it is (iRiS keeps whatever Material variant was set).
            const now = spec.bundle.map(path => String(Config.getNestedValue(path, "") ?? ""))
            return (spec.choices ?? []).find(choice => choice.values.every((value, index) => value === null || String(value) === now[index]))?.value ?? ""
        }
        return Config.getNestedValue(spec.path, spec.fallback)
    }
    // The gallery's own rows mean nothing while one of Material's pickers opens instead.
    function ownGallery(): bool { return String(Config.options?.iris?.wallpaper?.picker ?? "iris") !== "material" }
    // ── The way back. Every change made in Settings goes on this visit's history, said nowhere (his 11-07: the island
    // on every change was in the way): Ctrl+Z puts the value before it back and Ctrl+Shift+Z brings it again.
    // A burst on one row (wheel notches, digits, a drag's steps) is one change. A family switch keeps the shell's own
    // transition and a display change its Keep or Revert, so neither goes on it.
    property var history: []
    property var ahead: []
    // The value a row held before a drag started previewing it in memory (Config.previewNestedValue), by row.
    property var held: ({})
    readonly property bool canUndo: root.history.length > 0
    readonly property bool canRedo: root.ahead.length > 0
    function rowKey(spec: var): string {
        return String(spec.path ?? (spec.comp !== undefined ? spec.comp + ":" + spec.key : spec.piece ?? spec.id ?? spec.label ?? ""))
    }
    function undoable(spec: var): bool {
        return spec.path !== "panelFamily" && spec.comp !== "display" && spec.kind !== "action"
    }
    function hold(spec: var): void {
        const key = root.rowKey(spec)
        if (!(key in root.held)) root.held[key] = root.plain(root.currentValue(spec))
    }
    function remember(entry: var): void {
        root.history = root.history.concat([entry]).slice(-40)
        root.ahead = []
    }
    function forget(): void {
        root.history = []
        root.ahead = []
        root.held = ({})
    }
    function commit(spec: var, next: var): void {
        const key = root.rowKey(spec)
        if (!root.undoable(spec)) { delete root.held[key]; root.write(spec, next); return }
        const before = key in root.held ? root.held[key] : root.plain(root.currentValue(spec))
        delete root.held[key]
        root.write(spec, next)
        const after = root.plain(next)
        // A bundle reads back as the choice it now matches; one it matched none of has no way back.
        if (spec.bundle && !spec.keyed && String(before ?? "").length === 0) return
        const last = root.history[root.history.length - 1]
        const now = Date.now()
        if (last && last.kind === "change" && last.key === key && now - last.at < 2500) {
            const merged = Object.assign({}, last, { at: now, steps: [{ spec: spec, before: last.steps[0].before, after: after }] })
            const rest = root.history.slice(0, -1)
            // Back where the burst began: nothing changed.
            if (root.same(merged.steps[0].before, after)) { root.history = rest; return }
            root.history = rest.concat([merged])
            root.ahead = []
            return
        }
        if (root.same(before, after)) return
        root.remember({ kind: "change", key: key, at: now, steps: [{ spec: spec, before: before, after: after }] })
    }
    // Restore defaults: every changed row of the page back to its factory value at once, as one change with one Undo.
    function restore(specs: var): void {
        const steps = specs.filter(spec => root.modified(spec)).map(spec => ({ spec: spec, before: root.plain(root.currentValue(spec)), after: root.plain(root.factory(spec)) }))
        if (steps.length === 0) return
        root.apply(steps, "after")
        root.remember({ kind: "restore", key: "", at: Date.now(), steps: steps })
    }
    // A preset worn from Settings: the whole look (or only its colours) is one change with one Undo, said by its name.
    function wearTheme(theme: var): void {
        if (!theme) return
        const designRow = root.settings.find(spec => spec.widgetDesign) ?? null
        const rows = [{ path: "iris.appearance.themeId", fallback: "iris" }].concat(IrisThemes.paths)
            .map(entry => entry.path === "iris.widgets.design" && designRow ? designRow : entry)
        const read = () => rows.map(spec => root.plain(spec.widgetDesign ? root.currentValue(spec) : Config.getNestedValue(spec.path, spec.fallback)))
        // The one it replaces is named only when it was worn as it is (a modified or colours-only one has no name).
        const was = IrisThemes.active && !IrisThemes.modified && !IrisThemes.coloursOnly ? IrisThemes.active : null
        const before = read()
        IrisThemes.choose(theme)
        const after = read()
        const steps = rows.map((spec, index) => ({ spec: spec, before: before[index], after: after[index] }))
            .filter(step => !root.same(step.before, step.after))
        if (steps.length === 0) return
        const row = root.settings.find(spec => spec.kind === "themes") ?? null
        root.remember({ kind: "theme", key: "theme", at: Date.now(), row: row, steps: steps,
            say: String(theme.name ?? ""), swatch: String(IrisThemes.swatch(theme).accent),
            sayBefore: was ? String(was.name ?? "") : "", swatchBefore: was ? String(IrisThemes.swatch(was).accent) : "" })
    }
    // A theme of the person's deleted from Settings: its file goes at once and Undo writes it back.
    function dropTheme(theme: var): void {
        if (!theme?.user) return
        const kept = IrisThemes.parse(IrisThemes.exportText(theme), String(theme.id))
        if (!kept) return
        IrisThemes.remove(kept.id)
        root.remember({ kind: "dropTheme", key: "theme:" + kept.id, at: Date.now(), row: root.settings.find(spec => spec.kind === "themes") ?? null,
            steps: [], glyph: "delete", name: String(theme.name ?? ""), say: Translation.tr("Deleted"), sayBefore: Translation.tr("Restored"),
            swatch: String(IrisThemes.swatch(theme).accent), back: () => IrisThemes.write(kept), again: () => IrisThemes.remove(kept.id) })
    }
    // A plain key is written with the others in one revision (each its own write rebuilt every row of the page once
    // per key); a row with its own way to write takes it.
    function apply(steps: var, side: string): void {
        const batch = ({})
        let plainCount = 0
        for (const step of steps) {
            const spec = step.spec
            const bare = spec.path && spec.path !== "panelFamily" && spec.path !== "iris.bar.pieces" && !spec.widget && !spec.widgetDesign && !spec.comp
                && spec.kind !== "icon" && !spec.set && !spec.flags && !spec.bundle && !spec.numeric && !/^iris\.bubbles\.extras\./.test(String(spec.path))
            if (bare) { batch[spec.path] = step[side]; plainCount++; if (spec.regen) root.regenerate.restart() }
            else root.write(spec, step[side])
        }
        if (plainCount > 0) Config.setNestedValues(batch)
    }
    function undo(): bool {
        const entry = root.history[root.history.length - 1]
        if (!entry) return false
        root.history = root.history.slice(0, -1)
        if (entry.back) entry.back()
        else root.apply(entry.steps.slice().reverse(), "before")
        root.ahead = root.ahead.concat([entry])
        return true
    }
    function redo(): bool {
        const entry = root.ahead[root.ahead.length - 1]
        if (!entry) return false
        root.ahead = root.ahead.slice(0, -1)
        if (entry.again) entry.again()
        else root.apply(entry.steps, "after")
        root.history = root.history.concat([entry])
        return true
    }
    // ── Home's pins from any row: right-click or press and hold a row, "Pin to Home"; Ctrl+Z takes it back.
    readonly property var homeSpec: ({ path: "iris.appearance.settingsHome", kind: "list", label: "Home" })
    function homeList(): var {
        return Array.from(Config.options?.iris?.appearance?.settingsHome ?? root.homeDefault).map(entry => String(entry))
    }
    // What Home can hold, looked up per row: scanning the list for every row of every page cost Prism's sidebar 180 ms
    // on each write (11-07).
    readonly property var homeValues: root.homeCandidates.reduce((all, entry) => { all[entry.value] = true; return all }, ({}))
    function pinValue(spec: var): string {
        const value = String(spec.id ?? spec.path ?? "")
        return value.length > 0 && root.homeValues[value] === true ? value : ""
    }
    function onHome(spec: var): bool {
        const value = root.pinValue(spec)
        return value.length > 0 && root.homeList().includes(value)
    }
    function togglePin(spec: var): void {
        const value = root.pinValue(spec)
        if (value.length === 0) return
        const before = root.homeList()
        const pinning = !before.includes(value)
        const after = pinning ? before.concat([value]) : before.filter(entry => entry !== value)
        Config.setNestedValue(root.homeSpec.path, after)
        root.remember({ kind: pinning ? "pin" : "unpin", key: "home:" + value, at: Date.now(), row: spec, steps: [{ spec: root.homeSpec, before: before, after: after }] })
    }
    // A value in words, as a row says it: a switch On or Off, a choice its name, a range its figure.
    function say(spec: var, value: var): string {
        if (spec.kind === "switch" || spec.kind === "toggle") return (spec.invert ? !value : Boolean(value)) ? Translation.tr("On") : Translation.tr("Off")
        if (spec.kind === "range" || spec.kind === "level") return Number.isFinite(Number(value)) ? root.rangeText(spec, value) : ""
        // A config list is a sequence, not an Array: one of a single piece says its name, more say how many.
        if (value && typeof value === "object" && Number.isFinite(value.length)) {
            const one = value.length === 1 ? root.choicesOf(spec).find(entry => String(entry.value) === String(value[0])) : null
            return one ? Translation.tr(String(one.label ?? "")) : Translation.tr("%1 chosen").arg(value.length)
        }
        const choice = root.choicesOf(spec).find(entry => String(entry.value) === String(value))
        if (choice) return Translation.tr(String(choice.label ?? ""))
        if (spec.kind === "text" || spec.kind === "hue") return String(value ?? "").length > 0 && String(value).length <= 22 ? String(value) : ""
        return ""
    }
    // A switch heading its group is named by the group ("Day and night: On", not "A theme for each: On").
    function leads(spec: var): bool {
        if (spec.kind !== "switch" || !spec.group || spec.mirror) return false
        const first = root.settings.find(entry => entry.section === spec.section && entry.group === spec.group && !entry.mirror)
        return !!first && first.path === spec.path
    }
    // The swatch a choice draws, when it is a colour (Accent, Signal).
    function swatchOf(spec: var, value: var): var {
        const choice = root.choicesOf(spec).find(entry => String(entry.value) === String(value))
        return choice?.swatch ?? null
    }
    // A notice option written, then shown on the Island as it now is (Settings shows, it does not describe).
    function writeAndShow(path: string, next: var, sample: string): void {
        Config.setNestedValue(path, next)
        if (sample.length > 0) Qt.callLater(() => IrisState.noticeSample = { kind: sample, at: Date.now() })
    }
    property int sampleIndex: 0
    readonly property var sampleKinds: ["accessory", "charge", "upcoming", "focus", "unlock", "shelf", "battery", "timers"]
    function showNextSample(): void {
        IrisState.noticeSample = { kind: root.sampleKinds[root.sampleIndex % root.sampleKinds.length], at: Date.now() }
        root.sampleIndex++
    }
    function write(spec: var, next: var): void {
        // A family switch goes through the shell's transition, never a bare config write.
        if (spec.path === "panelFamily") Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "panelFamily", "set", String(next)])
        else if (spec.widget) DesktopWidgetOptions.write(spec, next)
        else if (spec.widgetDesign) DesktopWidgetDesign.apply(String(next))
        else if (spec.comp) {
            if (spec.comp === "blur") IrisCompositorBlur[spec.read ?? spec.key] = next
            CompositorConfig.set(spec, next)
        }
        else if (spec.kind === "icon") IrisPieces.setGlyph(String(spec.piece ?? ""), String(next ?? ""))
        else if (spec.set) spec.set(next)
        else if (spec.flags) {
            const on = Array.from(next ?? []).map(entry => String(entry))
            const updates = ({})
            root.choicesOf(spec).forEach(choice => updates[spec.flags + "." + choice.value] = on.includes(String(choice.value)))
            Config.setNestedValues(updates)
        }
        else if (spec.bundle) {
            const choice = (spec.choices ?? []).find(candidate => candidate.value === next)
            if (choice) {
                const updates = {}
                spec.bundle.forEach((path, index) => { if (choice.values[index] !== null) updates[path] = choice.values[index] })
                Config.setNestedValues(updates)
            }
        }
        else if (spec.path === "iris.bar.pieces") {
            const updates = { "iris.bar.pieces": Array.from(next ?? []) }
            const before = Array.from(Config.options?.iris?.bar?.pieces ?? []).map(entry => String(entry))
            for (const id of Array.from(next ?? []).map(entry => String(entry)))
                if (!before.includes(id) && (Config.options?.iris?.bubbles?.extras?.[id]?.enable ?? false))
                    updates["iris.bubbles.extras." + id + ".enable"] = false
            Config.setNestedValues(updates)
        }
        else if (/^iris\.bubbles\.extras\.\w+\.(enable|place)$/.test(String(spec.path))) {
            const id = String(spec.path).split(".")[3]
            const updates = ({})
            updates[spec.path] = next
            const place = String(spec.path).endsWith(".place") ? String(next)
                : String(Config.options?.iris?.bubbles?.extras?.[id]?.place ?? IrisPieces.defaultPlace)
            const floating = (spec.path.endsWith(".enable") ? Boolean(next) : true) && place !== "island"
            const listed = Array.from(Config.options?.iris?.bar?.pieces ?? []).map(entry => String(entry))
            if (floating && listed.includes(id)) updates["iris.bar.pieces"] = listed.filter(entry => entry !== id)
            Config.setNestedValues(updates)
        }
        // A number typed as text (coordinates) is stored as a number; anything unreadable as 0, which means unset.
        else if (spec.numeric) Config.setNestedValue(spec.path, Number.isFinite(parseFloat(next)) ? parseFloat(next) : 0)
        else Config.setNestedValue(spec.path, next)
        if (spec.regen) root.regenerate.restart()
    }
    // Values switchwall reads that ThemeService's live signature does not watch: one regeneration after the last change.
    // The base wrote the family's glass section: its mirror reads it back.
    readonly property Connections compositorWrites: Connections {
        target: CompositorConfig
        function onWritten(section: string): void { if (section === "blur") IrisCompositorBlur.reload() }
    }
    readonly property Timer regenerate: Timer { interval: 500; onTriggered: Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--noswitch"]) }
    // A leading "!" negates either form, so a row can hide on one value of a choice.
    function choicesOf(spec: var): var {
        if (spec.comp === "display") return CompositorConfig.displayChoices(spec.key)
        if (spec.choicesFrom === "compositor") return CompositorConfig.choicesFor(spec)
        if (spec.choicesFrom === "cursors") return CompositorConfig.cursorThemes.map(name => ({ label: name.replace(/[_-]/g, " "), value: name }))
        if (spec.choicesFrom === "irisModules") return (CustomWidgets.widgets ?? [])
            .filter(widget => String(widget.faces?.iris?.path ?? "").length > 0)
            .map(widget => ({ label: String(widget.name ?? widget.id), value: "custom:" + widget.id }))
        // Recording sources by the names PipeWire gives them; a system source is an output's monitor.
        if (spec.choicesFrom === "primaryScreens") return [{ label: "Auto", value: "" }].concat(Quickshell.screens.map(screen => ({ label: String(screen.name), value: String(screen.name) })))
        if (spec.choicesFrom === "monitorSources") return [{ label: "Default output", value: "" }].concat(Audio.outputDevices.map(node => ({ label: Audio.friendlyDeviceName(node), value: String(node.name) + ".monitor" })))
        if (spec.choicesFrom === "microphones") return [{ label: "Default microphone", value: "" }].concat(Audio.inputDevices.map(node => ({ label: Audio.friendlyDeviceName(node), value: String(node.name) })))
        if (spec.choicesFrom === "iconThemes") { IconThemeService.ensureInitialized(); return IconThemeService.availableThemes.map(name => ({ label: String(name).replace(/[_-]/g, " "), value: String(name) })) }
        if (spec.choicesFrom === "colourThemes") return root.colourThemeIds.map(id => ({ label: id === "auto" ? "Wallpaper" : String(ThemePresets.getPreset(id).name), value: id }))
        if (spec.choicesFrom) return DesktopWidgetOptions.choicesFor(String(spec.choicesFrom))
        return spec.choices ?? []
    }
    // A scheme's tuning is listed only when that scheme can be the one in use: the one chosen, or dark and light under Auto.
    function schemeShown(name: string): bool {
        const choice = String(Config.getNestedValue("iris.appearance.scheme", "auto"))
        if (choice !== "auto") return choice === name
        return IrisStyle.colourTheme === "iris-ink" ? name === "ink" : name !== "ink"
    }
    // The Island across its whole edge (Shelf, and Menu bar and Pods on top or bottom): its zones replace the bubbles.
    function islandZoned(): bool {
        const bar = Config.options?.iris?.bar ?? ({})
        const layout = String(bar.layout ?? "island")
        const upright = ["left", "right"].includes(String(bar.position ?? "top"))
        return layout === "full" || !upright && (layout === "menubar" || layout === "pods")
    }
    // Whether the engine draws this part of the open Island: Ledger and Tiles, or a Design, draw their own.
    // Whether the engine draws this part of the Island under the worn design (IrisStyle.islandDesignParts): a row
    // that tunes the engine's part acts on nothing while a design draws its own. A face is drawn only across an edge.
    function islandEngineDraws(part: string): bool {
        if (IrisDesign.skin(({ "Face.qml": "islandFace", "Nav.qml": "islandNav", "Desktop.qml": "islandDesktop" })[part] ?? "").length > 0) return false
        if (part === "Face.qml" && root.islandUpright()) return true
        return !(IrisStyle.islandDesignParts[String(Config.options?.iris?.bar?.design ?? "halo")] ?? []).includes(part)
    }
    // The design the resting Island wears now, while it draws its own face (a shell Design that skins the face keeps it).
    function islandFace(id: string): bool {
        return !root.islandUpright() && IrisDesign.skin("islandFace").length === 0 && String(Config.options?.iris?.bar?.design ?? "halo") === id
    }
    // The palettes of the edge designs (IrisStyle.islandLight), in the order Settings offers them.
    readonly property var islandLights: [{label:"Spectrum",value:"spectrum",glyph:"looks"},{label:"Accent",value:"accent",glyph:"palette"},{label:"Day",value:"day",glyph:"wb_twilight"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Sunset",value:"sunset",glyph:"wb_sunny"},{label:"Ocean",value:"ocean",glyph:"water"},{label:"Mint",value:"mint",glyph:"eco"}]
    readonly property var ringCounts: [{label:"Day",value:"day"},{label:"Week",value:"week"},{label:"Month",value:"month"},{label:"Year",value:"year"},{label:"Battery",value:"battery"}]
    function islandUpright(): bool { return ["left", "right"].includes(String(Config.options?.iris?.bar?.position ?? "top")) }
    // How the compositor arranges windows now; one that knows a single way says "scrolling".
    function layoutMode(): string {
        return CompositorConfig.has("layout", "mode") ? String(CompositorConfig.value({ comp: "layout", key: "mode", fallback: "scrolling" })) : "scrolling"
    }
    function cornersUsed(): bool {
        return ["top-left", "top-right", "bottom-left", "bottom-right"].some(corner => String(CompositorConfig.value({ comp: "corners", key: corner, fallback: "" })).length > 0)
    }
    // What the worn Design and the compositor in use allow, whatever other options say: a long Prism page splits
    // by these rows, so a switch that shows or hides its neighbours never moves the page under the reader (his 11-10).
    function fits(spec: var): bool {
        // What the worn Design decides for itself is not offered while it is worn: a locked row was one more thing to read.
        const paths = spec.bundle ?? (spec.path ? [String(spec.path)] : [])
        if (paths.length > 0 && paths.every(path => IrisDesign.owns(path))) return false
        // A compositor row shows only where the compositor in use can do it (CompositorConfig.has).
        return !spec.comp || CompositorConfig.has(String(spec.comp), String(spec.key))
    }
    function shown(spec: var): bool {
        if (!root.fits(spec)) return false
        if (spec.showIf && !spec.showIf()) return false
        const when = String(spec.visibleWhen ?? "")
        if (when.length === 0) return true
        const negated = when.startsWith("!")
        const rest = negated ? when.slice(1) : when
        const on = rest.includes("=")
            ? String(Config.getNestedValue(rest.split("=")[0], "")) === rest.split("=")[1]
            : Boolean(Config.getNestedValue(rest, false))
        return negated ? !on : on
    }
    // What a row reads with nothing set: a compositor row asks the compositor when it knows (Umbriel's own files and
    // defaults), the rest keeps the row's fallback.
    function factory(spec: var): var {
        if (spec.comp && spec.comp !== "blur") {
            const known = CompositorConfig.factory(spec)
            if (known !== undefined) return known
        }
        return spec.fallback
    }
    function resettable(spec: var): bool {
        if (spec.comp) return spec.comp !== "blur" && CompositorConfig.factory(spec) !== undefined
        // `restorable`: a row outside iRiS's keys that still has one factory value (the glyph wallpaper, a widget's own options).
        return spec.fallback !== undefined && (spec.restorable === true
            || (spec.bundle ?? [String(spec.path ?? "")]).every(path => String(path).startsWith("iris.")))
    }
    // A range reads in its display unit, with as many decimals as its step needs there.
    function rangeText(spec: var, value: var): string {
        if (spec.zeroLabel && Number(value) === 0) return String(spec.zeroLabel)
        const scale = Number(spec.scale ?? 1)
        const shownStep = Math.abs(Number(spec.step ?? 1) * scale)
        const decimals = shownStep > 0 && shownStep < 1 ? Math.min(2, Math.ceil(-Math.log10(shownStep) - 1e-9)) : 0
        // Percent sits on the figure ("40%"), other units keep their space ("12 px").
        return Number(Number(value) * scale).toFixed(decimals).replace(/(\.\d*?)0+$/, "$1").replace(/\.$/, "") + String(spec.unit ?? "").replace(/^ %$/, "%")
    }
    function modified(spec: var): bool {
        return root.resettable(spec) && !root.same(root.currentValue(spec), root.factory(spec))
    }
    // Fine-tuning folds behind a group's "Fine-tune" row: a range nudges what a choice already decided, so ranges fold
    // unless a row says `tune: false`; any row can join with `tune: true`. What differs from its default never folds.
    // The one choice list open in place on the page (IrisSetting.listKey); a section change closes it.
    property string openList: ""
    function fineTune(spec: var): bool {
        return spec.tune !== undefined ? Boolean(spec.tune) : spec.kind === "range"
    }
    // What differed from its default when its area opened: a value set while the page is up never refolds it under the
    // pointer (a group closed on every change, 10-25). The next area settles it again.
    property var _seen: ({})
    property int seenEpoch: 0
    function changedWhenSeen(spec: var): bool {
        void root.seenEpoch
        const key = String(spec.path ?? spec.label ?? "")
        if (!(key in root._seen)) root._seen[key] = root.changed(spec)
        return root._seen[key]
    }
    function settle(): void {
        root._seen = ({})
        root.seenEpoch++
    }
    function foldsAway(spec: var): bool { return root.fineTune(spec) && !root.changedWhenSeen(spec) }
    function changed(spec: var): bool {
        const factory = root.factory(spec)
        return factory !== undefined && !root.same(root.currentValue(spec), factory)
    }

    readonly property bool widgetGlass: DesktopWidgetDesign.current === "iris"
    // iRiS's faces draw the widgets (iRiS or Prism): the material, corners, weight and opacity rows reach them.
    readonly property bool widgetFaces: ["iris", "prism"].includes(DesktopWidgetDesign.current)
    readonly property var pairings: [
        { label: "iRiS", value: "iris", values: ["", "", ""] },
        { label: "Inter", value: "pro", values: ["Inter", "Inter Display", "Rubik"] },
        { label: "Rounded", value: "rounded", values: ["Rubik", "Rubik", ""] },
        { label: "Classic", value: "classic", values: ["Noto Sans", "Readex Pro", ""] },
        { label: "Montserrat", value: "montserrat", values: ["Montserrat", "Montserrat", "Montserrat"] },
        { label: "Archivo", value: "archivo", values: ["Archivo", "Archivo SemiExpanded", "Archivo SemiExpanded"] },
        { label: "Flex", value: "flex", values: ["Roboto Flex", "Roboto Flex", "Roboto Flex"] },
        { label: "Technical", value: "technical", values: ["Space Grotesk", "Space Grotesk", "JetBrainsMono Nerd Font"] }
    ].filter(pairing => pairing.values.every(face => face.length === 0 || face === IrisStyle.faceText || Qt.fontFamilies().includes(face)))

    // The palettes iRiS lists (every one is still in the shared Themes page): what the apps wear, one swatch each.
    // What each scheme calls its materials: the three stored names stay black, graphite and midnight.
    // In words, what the solver makes of each (inir-accel's washi: its iris and paper tables). Read by the row that shows
    // it: read here, the scheme it depends on rebuilt every row of Settings on each switch.
    function materialDetail(at: int): string {
        return (IrisStyle.ink ? ["Cream paper", "Tan paper", "Blue-grey paper"]
            : IrisStyle.light ? ["Warm white", "Light grey", "Cool grey"] : ["Pure black", "Neutral dark grey", "Blue black"])[at]
    }
    readonly property var materialChoices: {
        return ["black", "graphite", "midnight"].map((name, at) => ({ get label() { return IrisStyle.materialLabel(name) }, value: name,
                get detail() { return root.materialDetail(at) }, get swatch() { return IrisStyle.materialSwatch(name) } }))
            .concat([{ label: "Wallpaper", value: "wallpaper", detail: "Your wallpaper's hue", get swatch() { return IrisStyle.materialSwatch("wallpaper") } },
                { label: "Theme", value: "theme", detail: "Your theme's colour", get swatch() { return IrisStyle.materialSwatch("theme") } }])
    }
    // A paper scheme's levels: tone and warmth together (inir-accel's washi paper_levels, same numbers), each tile
    // painted with the paper the solver gives it on the current material.
    function paperChoices(scheme: string): var {
        const levels = scheme === "ink"
            ? [["Shironeri", "shironeri", 14, 30], ["Kinari", "kinari", 0, 50], ["Torinoko", "torinoko", -10, 68], ["Sumi", "sumi", -24, 52]]
            : scheme === "dark"
            ? [["Night", "night", 0, 20], ["Kuro", "kuro", 40, 42], ["Sumi", "sumi", 50, 62], ["Usuzumi", "usuzumi", 68, 50]]
            : [["Bright", "bright", 6, 0], ["Soft", "soft", -8, 38], ["Calm", "calm", -18, 55]]
        // Dark's papers also set its style: Night is the style's own, the others are ink at night (washi).
        return levels.map(level => ({ label: level[0], value: level[1],
            values: scheme === "dark" ? [level[2], level[3], level[1] === "night" ? "style" : "ink"] : [level[2], level[3]],
            get palette() {
                const p = IrisWashi.palette(scheme)
                const of = (hex, fallback) => hex ? Qt.color(String(hex)) : fallback
                const own = scheme === "dark" && level[1] === "night" ? p?.materials?.[IrisStyle.materialName] : null
                return { dark: scheme === "dark", bg: of(own ?? p?.papers?.[level[1]], IrisStyle.surfaceOpaque), fg: of(p?.text, IrisStyle.text),
                    dots: [p?.accent, p?.highlight, p?.identity?.green].map(hex => of(hex, IrisStyle.identity.gray)) }
            },
            get swatch() { return this.palette.bg } }))
    }
    function schemeName(name: string): string {
        return Translation.tr(({ dark: "Dark mode", ink: "Ink", light: "Light mode" })[name] ?? "Dark mode")
    }
    // The state of what this row depends on, said where the person is looking, so a row never reads as broken.
    // A Design with its own palette offers its colour first (AIRISU's vermilion seal, its kerria amber).
    function designChoice(table: string): var {
        return IrisDesign.palette.length > 0 ? [{ label: IrisDesign.name, value: "design", get swatch() { return IrisStyle[table].design } }] : []
    }
    function followNote(): string {
        if (!IrisStyle.followsTheme) return ""
        const preset = ThemePresets.getPreset(IrisStyle.colourTheme)
        return Translation.tr("Follows the %1 colour theme. Turn off Match the shell to choose your own.").arg(String(preset.name))
    }
    function themeNote(): string {
        return IrisStyle.followsTheme ? Translation.tr("Applied to the shell, your terminals and the apps switched on under App colours.")
            : IrisStyle.colourTheme === "auto" ? "" : Translation.tr("Applied to your terminals and apps. The shell keeps its own colours: Match the shell is off.")
    }
    // Where the mode in use comes from, so Auto never reads as a mystery: a colour theme, the wallpaper or the last choice.
    function schemeNote(): string {
        const note = root.schemeSource()
        const darkTerminals = IrisStyle.light && Boolean(Config.getNestedValue("appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode", false))
        return darkTerminals ? note + ". " + Translation.tr("Terminals stay dark: Terminals always dark is on under App colours.") : note
    }
    function schemeSource(): string {
        const name = root.schemeName(IrisStyle.scheme)
        const choice = String(Config.getNestedValue("iris.appearance.scheme", "auto"))
        const themed = IrisStyle.colourTheme !== "auto"
        const presetName = themed ? String(ThemePresets.getPreset(IrisStyle.colourTheme).name) : ""
        if (choice === "auto") {
            if (themed) return Translation.tr("In use: %1, set by the %2 colour theme").arg(name).arg(presetName)
            return Config.getNestedValue("appearance.wallpaperTheming.autoDarkLightMode", false)
                ? Translation.tr("In use: %1, from the wallpaper").arg(name) : Translation.tr("In use: %1, from your last choice").arg(name)
        }
        const themeDark = themed ? Boolean(ThemePresets.getPreset(IrisStyle.colourTheme).colors?.darkmode) : (choice === "dark")
        if (themed && themeDark !== (choice === "dark")) return Translation.tr("In use: %1. Your apps follow the %2 colour theme.").arg(name).arg(presetName)
        return Translation.tr("In use: %1").arg(name)
    }
    // A neutral line is drawn in the hairline's ink: with Material › Lines at 0 % it is drawn at nothing, so say so.
    function edgeNote(): string {
        return IrisStyle.edgeStyle === "line" && IrisStyle.rim.a <= 0
            ? Translation.tr("Material › Lines is at 0 %, so a neutral line does not show: raise Lines or pick Accent.") : ""
    }
    // The login screen is a theme installed once for the whole system; until it is, its rows say where it comes from.
    function loginNote(): string {
        return MaterialThemeLoader.loginScreenInstalled ? "" : Translation.tr("Not installed yet: run iNiR's setup and choose Extras, Install ii-pixel-sddm.")
    }
    // What an area has to say before you ask: rows that cannot answer and why, settings that cancel each other, pinned
    // apps that are gone. Every Settings layout marks these where it marks trouble.
    // Every area's notes in one pass ({ section: [note] }). Notes read live state (moods, apps, the frame), so the caller
    // takes them when it wants them, never as a binding: bound, they were redone every frame of Settings' morph.
    function notesBySection(): var {
        const out = {}
        for (const spec of root.settings) {
            if (spec.mirror || !root.shown(spec)) continue
            const section = String(spec.section ?? "")
            const text = spec.note ? String(spec.note() ?? "") : ""
            const locked = spec.locked ? Boolean(spec.locked()) : false
            const add = note => (out[section] = out[section] ?? []).push(note)
            if (text.length > 0 && (locked || spec.warns === true))
                add({ path: String(spec.path ?? ""), group: String(spec.group ?? ""), label: String(spec.label ?? ""), text: text })
            if (String(spec.view ?? "").endsWith("IrisDockPinned.qml")) {
                for (const id of (Config.options?.apps?.pinned ?? []).map(String)) {
                    const who = AppSearch.appIdentity(id, "")
                    if (!who.installed) {
                        const told = root.appNameOf(id)
                        add({ path: "apps.pinned", group: String(spec.group ?? ""), label: String(spec.label ?? ""), app: id, kind: told.kind,
                            text: Translation.tr("%1 is pinned but no longer installed.").arg(who.name && who.name !== id ? String(who.name) : told.name) })
                    }
                }
            }
        }
        return out
    }
    // An app id said as people say it: "com.valvesoftware.Steam" or "steam-flatpak" is Steam, and how it came (Flatpak).
    function appNameOf(id: string): var {
        let raw = String(id ?? "").replace(/\.desktop$/i, "")
        let kind = ""
        if (/^[a-z0-9-]+(\.[A-Za-z0-9_-]+){2,}$/.test(raw)) { kind = "Flatpak"; raw = raw.split(".").pop() }
        const packaging = { flatpak: "Flatpak", snap: "Snap", appimage: "AppImage" }
        const noise = ["bin", "git", "desktop", "stable", "beta", "nightly", "missing", "native", "wayland", "x11", "app"]
        const words = raw.split(/[-_ .]+/).filter(word => {
            const low = word.toLowerCase()
            if (packaging[low]) { kind = kind || packaging[low]; return false }
            return word.length > 0 && !noise.includes(low)
        })
        const name = (words.length > 0 ? words : [raw]).map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(" ")
        return { name: name, kind: kind }
    }
    // Adaptive works by nudging fills, lines, corners, shadows and light a few tens of percent: this says what it is doing now.
    function adaptiveNote(): string {
        if (Number(Config.getNestedValue("iris.appearance.adaptive", 0)) <= 0) return Translation.tr("Off: your values apply as they are.")
        if (!IrisMood.sampled) return Translation.tr("Reading the wallpaper…")
        const pct = name => { const v = Math.round((IrisMood.factor(name) - 1) * 100); return (v < 0 ? "−" : "+") + Math.abs(v) + " %" }
        return Translation.tr("Now: fills %1, lines %2, corners %3, shadows %4, light %5").arg(pct("fill")).arg(pct("lines")).arg(pct("shape")).arg(pct("shadow")).arg(pct("lightReach"))
    }
    readonly property var colourThemeIds: ["auto", "iris-ink", "catppuccin-latte", "sakura", "zen-garden", "vitesse-light", "catppuccin-mocha",
        "catppuccin-macchiato", "catppuccin-frappe", "rose-pine", "tokyo-night", "nord", "gruvbox-material", "kanagawa", "everforest",
        "dracula", "one-dark", "material-black"]
    readonly property var colourThemeChoices: root.colourThemeIds.map(id => {
        const preset = ThemePresets.getPreset(id)
        return { label: id === "auto" ? "Wallpaper" : String(preset.name), value: id,
            get palette() {
                if (id === "auto") return { wallpaper: true }
                const c = preset.colors ?? ({})
                const of = (hex, fallback) => hex ? Qt.color(String(hex)) : fallback
                return { dark: Boolean(c.darkmode), bg: of(c.m3background, IrisStyle.bodySurface), fg: of(c.m3onBackground, IrisStyle.text),
                    dots: [c.m3primary, c.m3secondary, c.m3tertiary].map(hex => of(hex, IrisStyle.identity.gray)) }
            },
            get swatch() { return id === "auto" ? IrisStyle.wallpaperLight : preset.colors?.m3primary ? Qt.color(String(preset.colors.m3primary)) : IrisStyle.identity.gray } }
    })
    // The styles the palette can be drawn in, each painted with its own solve of the person's choices (IrisWashi styles).
    readonly property var styleChoices: [
        { id: "iris", label: "iRiS", values: ["iris", null] },
        { id: "washi", label: "Washi", values: ["washi", null] },
        { id: "material:tonalSpot", label: "Material You", values: ["material", "tonalSpot"] },
        { id: "material:vibrant", label: "Vibrant", values: ["material", "vibrant"] },
        { id: "material:expressive", label: "Expressive", values: ["material", "expressive"] },
        { id: "material:fidelity", label: "Fidelity", values: ["material", "fidelity"] },
        { id: "material:monochrome", label: "Monochrome", values: ["material", "monochrome"] }
    ].map(style => ({ label: style.label, value: style.id === "iris" ? "iris" : style.id, values: style.values,
        get palette() {
            const of = (hex, fallback) => hex ? Qt.color(String(hex)) : fallback
            // Night and day side by side: a style is both, whatever mode is on now.
            const side = scheme => {
                const w = IrisWashi.data?.styles?.[style.id]?.[scheme] ?? ({})
                return { bg: of(w.surface, IrisStyle.bodySurface), fg: of(w.text, IrisStyle.text),
                    dots: [w.accent].concat(w.dots ?? []).slice(0, 3).map(hex => of(hex, IrisStyle.identity.gray)) }
            }
            const now = side(IrisStyle.scheme)
            return { dark: !IrisStyle.light, bg: now.bg, fg: now.fg, dots: now.dots, split: [side("dark"), side("light")] }
        },
        get swatch() { return Qt.color(String(IrisWashi.data?.styles?.[style.id]?.[IrisStyle.scheme]?.accent ?? IrisStyle.accent)) } }))
    readonly property var studioRows: [
        { target: "material", group: "Colour theme", label: "Style", description: "iRiS is vivid, Washi is paper and pigment, Material You follows your wallpaper.", kind: "choice", tiles: true, flatTiles: true, fallback: "iris", bundle: ["iris.appearance.language", "iris.appearance.variant"], choices: root.styleChoices,
            keywords: ["style", "palette style", "iris", "washi", "paper", "pigment", "material you", "material", "android", "monet", "dynamic colour", "dynamic color", "tonal spot", "vibrant", "expressive", "fidelity", "monochrome", "preset", "estilo", "paleta"] },
        { target: "material", group: "Colour theme", label: "Colour theme", description: "The palette your shell and apps wear.", path: "appearance.theme", kind: "choice", tiles: true, fallback: "auto", choices: root.colourThemeChoices, note: () => root.themeNote(), keywords: ["palette", "catppuccin", "nord", "gruvbox", "dracula", "rose pine", "tokyo night", "everforest", "kanagawa", "theme", "apps", "terminal", "colours", "colors", "tema", "paleta", "ink"] },
        { target: "material", group: "Colour theme", label: "Match the shell", description: "The shell takes the theme's accent, highlight and material too.", path: "iris.appearance.followTheme", visibleWhen: "!appearance.theme=auto", kind: "switch", fallback: true, keywords: ["sync", "match", "follow", "apps", "shell", "accent", "sincronizar"] },
        { target: "material", group: "Colour theme", label: "Softer colours", description: "Takes the glare off a theme's brightest colours.", path: "appearance.softenColors", visibleWhen: "!appearance.theme=auto", kind: "switch", fallback: true, tune: true, keywords: ["soften", "soft", "muted", "pastel", "glare", "saturation", "suave", "suavizar"] },
        { target: "material", group: "Day and night", label: "A theme for each", tune: true, description: "One theme by day, another at night, switched on the hour you set.", path: "appearance.themeSchedule.enabled", kind: "switch", fallback: false,
            // The tile says the hours it keeps, not the switch's name.
            glance: on => on ? String(Config.options?.appearance?.themeSchedule?.dayStart ?? "06:00") + "–" + String(Config.options?.appearance?.themeSchedule?.nightStart ?? "18:00") : "", keywords: ["schedule", "day", "night", "time", "evening", "morning", "automatic", "horario", "día", "noche"] },
        { target: "material", group: "Day and night", label: "Hours", kind: "list", view: Qt.resolvedUrl("IrisThemeClock.qml"), summary: false, visibleWhen: "appearance.themeSchedule.enabled", keywords: ["hours", "time", "sunrise", "sunset", "clock", "dial", "horas", "reloj"] },
        { target: "material", group: "Scheme", label: "Scheme", description: "Ink sits between dark and light: paper and ink, easier on the eyes.", path: "iris.appearance.scheme", kind: "choice", fallback: "auto", choices: [{label:"Auto",value:"auto",glyph:"auto_awesome"},{label:"Dark mode",value:"dark",glyph:"dark_mode"},{label:"Ink",value:"ink",glyph:"ink_pen"},{label:"Light mode",value:"light",glyph:"light_mode"}], keywords: ["light", "dark", "ink", "sumi", "washi", "paper", "japanese", "day", "night", "mode", "theme", "bright", "white", "black", "claro", "oscuro", "tinta", "modo"] , note: () => root.schemeNote() },
        { target: "material", group: "Scheme", label: "Light or dark from the wallpaper", description: "With Auto, bright wallpapers pick light and dark ones pick dark.", path: "appearance.wallpaperTheming.autoDarkLightMode", visibleWhen: "iris.appearance.scheme=auto", kind: "switch", fallback: false, keywords: ["auto", "brightness", "night", "day", "wallpaper", "luminance", "claro", "oscuro"] },
        { target: "material", group: "Dark look", showIf: () => root.schemeShown("dark"), label: "Paper", tune: true, description: "Night is your style's own.", kind: "choice", tiles: true, flatTiles: true, fallback: "night", bundle: ["iris.appearance.tune.dark.tone", "iris.appearance.tune.dark.warmth", "iris.appearance.darkStyle"], choices: root.paperChoices("dark"), keywords: ["paper", "washi", "ink", "sumi", "night", "eyes", "charcoal", "warm", "papel", "tinta", "noche"] },
        { target: "material", group: "Dark look", showIf: () => root.schemeShown("dark") && String(Config.getNestedValue("iris.appearance.darkStyle", "style")) === "ink", label: "Warmth", summary: false, description: "How much washi fibre the night paper carries.", path: "iris.appearance.tune.dark.warmth", kind: "range", fallback: 20, min: 0, max: 100, step: 5, unit: " %", keywords: ["warmth", "warm", "sepia", "fibre", "fiber", "paper", "eyes", "night", "calidez", "papel"] },
        { target: "material", group: "Dark look", showIf: () => root.schemeShown("dark"), label: "Tone", description: "Lifts or dims this mode's material.", path: "iris.appearance.tune.dark.tone", kind: "range", fallback: 0, min: -30, max: 70, step: 2, unit: " %", keywords: ["brightness", "dim", "darker", "lighter", "grey", "gray", "eyes", "glare", "tone"] },
        { target: "material", group: "Dark look", showIf: () => root.schemeShown("dark"), label: "Colour strength", description: "How strong accents and colours read in this mode.", path: "iris.appearance.tune.dark.colour", kind: "range", fallback: 100, min: 0, max: 100, step: 5, unit: " %", keywords: ["saturation", "vivid", "muted", "pastel", "strong", "blue", "accent", "colour", "color"] },
        { target: "material", group: "Dark look", showIf: () => root.schemeShown("dark"), label: "Widget colour", description: "How colourful desktop widgets look in this mode.", path: "iris.appearance.tune.dark.widgets", kind: "range", fallback: 100, min: 40, max: 160, step: 5, unit: " %", keywords: ["widgets", "desktop", "dull", "faded", "muted", "washed", "vivid", "bright", "colourful", "colorful", "saturation", "colour", "color", "dark"] },
        { target: "material", group: "Ink look", showIf: () => root.schemeShown("ink"), label: "Paper", description: "Washi grades, from bleached to sumi-dyed.", kind: "choice", tiles: true, flatTiles: true, fallback: "kinari", bundle: ["iris.appearance.tune.ink.tone", "iris.appearance.tune.ink.warmth"], choices: root.paperChoices("ink"), keywords: ["paper", "washi", "eyes", "glare", "comfort", "warm", "sepia", "dim", "papel", "ojos", "calido"] },
        { target: "material", group: "Ink look", showIf: () => root.schemeShown("ink"), label: "Warmth", summary: false, description: "How much washi fibre the paper carries.", path: "iris.appearance.tune.ink.warmth", kind: "range", fallback: 50, min: 0, max: 100, step: 5, unit: " %", keywords: ["warmth", "warm", "sepia", "fibre", "fiber", "paper", "eyes", "night", "calidez", "papel"] },
        { target: "material", group: "Ink look", showIf: () => root.schemeShown("ink"), label: "Ink style", description: "Ink wears washi whatever the style above.", path: "iris.appearance.inkStyle", kind: "choice", fallback: "washi", choices: [{label:"Washi",value:"washi"},{label:"Follow the style",value:"style"}], keywords: ["ink", "washi", "style", "sync", "material you", "iris", "tinta", "estilo"] },
        { target: "material", group: "Ink look", showIf: () => root.schemeShown("ink"), label: "Tone", description: "Lifts or dims this mode's material.", path: "iris.appearance.tune.ink.tone", kind: "range", fallback: 0, min: -30, max: 30, step: 2, unit: " %", keywords: ["brightness", "dim", "darker", "lighter", "grey", "gray", "eyes", "glare", "tone"] },
        { target: "material", group: "Ink look", showIf: () => root.schemeShown("ink"), label: "Colour strength", description: "How strong accents and colours read in this mode.", path: "iris.appearance.tune.ink.colour", kind: "range", fallback: 100, min: 0, max: 100, step: 5, unit: " %", keywords: ["saturation", "vivid", "muted", "pastel", "strong", "blue", "accent", "colour", "color"] },
        { target: "material", group: "Ink look", showIf: () => root.schemeShown("ink"), label: "Widget colour", description: "How colourful desktop widgets look in this mode.", path: "iris.appearance.tune.ink.widgets", kind: "range", fallback: 100, min: 40, max: 160, step: 5, unit: " %", keywords: ["widgets", "desktop", "dull", "faded", "muted", "washed", "vivid", "bright", "colourful", "colorful", "saturation", "colour", "color", "ink"] },
        { target: "material", group: "Light look", showIf: () => root.schemeShown("light"), label: "Paper", tune: true, description: "How bright the page is.", kind: "choice", tiles: true, flatTiles: true, fallback: "soft", bundle: ["iris.appearance.tune.light.tone", "iris.appearance.tune.light.warmth"], choices: root.paperChoices("light"), keywords: ["paper", "washi", "eyes", "glare", "comfort", "warm", "sepia", "dim", "papel", "ojos", "calido"] },
        { target: "material", group: "Light look", showIf: () => root.schemeShown("light"), label: "Warmth", summary: false, description: "How much washi fibre the paper carries.", path: "iris.appearance.tune.light.warmth", kind: "range", fallback: 38, min: 0, max: 100, step: 5, unit: " %", keywords: ["warmth", "warm", "sepia", "fibre", "fiber", "paper", "eyes", "night", "calidez", "papel"] },
        { target: "material", group: "Light look", showIf: () => root.schemeShown("light"), label: "Tone", description: "Lifts or dims this mode's material.", path: "iris.appearance.tune.light.tone", kind: "range", fallback: -8, min: -30, max: 30, step: 2, unit: " %", keywords: ["brightness", "dim", "darker", "lighter", "grey", "gray", "eyes", "glare", "tone"] },
        { target: "material", group: "Light look", showIf: () => root.schemeShown("light"), label: "Colour strength", description: "How strong accents and colours read in this mode.", path: "iris.appearance.tune.light.colour", kind: "range", fallback: 85, min: 0, max: 100, step: 5, unit: " %", keywords: ["saturation", "vivid", "muted", "pastel", "strong", "blue", "accent", "colour", "color"] },
        { target: "material", group: "Light look", showIf: () => root.schemeShown("light"), label: "Widget colour", description: "How colourful desktop widgets look in this mode.", path: "iris.appearance.tune.light.widgets", kind: "range", fallback: 110, min: 40, max: 160, step: 5, unit: " %", keywords: ["widgets", "desktop", "dull", "faded", "muted", "washed", "vivid", "bright", "colourful", "colorful", "saturation", "colour", "color", "light"] },
        { target: "material", group: "Material", label: "Material", description: "What every surface is made of.", path: "iris.appearance.theme.surface", kind: "choice", cards: "material", fallback: "black", choices: root.materialChoices, locked: () => IrisStyle.followsTheme, note: () => root.followNote() || (IrisStyle.glassy ? Translation.tr("Glass is on: every surface lays this colour over what is behind it, as the preview above shows.") : "") },
        { target: "material", group: "Adaptive", label: "Adapt to the wallpaper", description: "iRiS takes its shape from the wallpaper: calm images round, busy ones sharpen. 0 is off.", path: "iris.appearance.adaptive", kind: "range", fallback: 0, min: 0, max: 100, step: 5, unit: " %" , note: () => root.adaptiveNote() },
        { target: "material", group: "Material", part: "Depth and detail", label: "Fills", description: "Groups, tracks, hovered and pressed controls.", path: "iris.appearance.theme.fill", kind: "range", fallback: 100, min: 30, max: 200, step: 5, unit: " %" },
        { target: "material", group: "Material", part: "Depth and detail", label: "Lines", description: "Hairlines and borders.", path: "iris.appearance.theme.lines", kind: "range", fallback: 100, min: 0, max: 200, step: 5, unit: " %" },
        { target: "material", group: "Material", part: "Depth and detail", label: "Shadows", description: "Under bodies floating over windows.", path: "iris.appearance.theme.shadow", kind: "range", fallback: 100, min: 0, max: 160, step: 5, unit: " %" },
        { target: "material", group: "Material", part: "Depth and detail", label: "Button rows", description: "Puts rows of round buttons on one plate: Veil, Glass or Solid.", path: "iris.appearance.controlPlate", kind: "choice", tune: true, fallback: "none", choices: [{label:"None",value:"none",glyph:"block"},{label:"Veil",value:"veil",glyph:"gradient"},{label:"Glass",value:"glass",glyph:"blur_on"},{label:"Solid",value:"solid",glyph:"square"}], keywords: ["buttons", "controls", "plate", "capsule", "frame", "glass", "veil", "transport", "navigation", "toolbar", "marco"] },
        { target: "material", group: "Texture", label: "Texture", tune: true, description: "How surfaces are drawn.", path: "iris.appearance.texture", kind: "choice", fallback: "flat", choices: [{label:"Flat",value:"flat",glyph:"check_box_outline_blank"},{label:"Ricelin",value:"solid",glyph:"crop_square"},{label:"Aurora",value:"aurora",glyph:"blur_on"},{label:"Angel",value:"angel",glyph:"auto_awesome"},{label:"Regalia",value:"regalia",glyph:"view_agenda"},{label:"Afterglow",value:"afterglow",glyph:"flare"},{label:"Light leak",value:"leak",glyph:"camera_roll"},{label:"Light streak",value:"streak",glyph:"auto_awesome_motion"}], keywords: ["texture", "afterglow", "retro", "y2k", "2000s", "console", "crt", "bloom", "chrome", "grade", "textura", "consola", "light leak", "film", "analog", "grain", "prism", "faded", "pelicula", "analogico", "grano", "fuga de luz", "streak", "light streak", "aurora", "long exposure", "trail", "estela", "exposicion larga"] },
        { target: "material", group: "Texture", label: "Light", description: "A hot line on every edge that faces the Island, brightest by it.", path: "iris.appearance.streak.light", visibleWhen: "iris.appearance.texture=streak", kind: "range", fallback: 75, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Off", keywords: ["streak", "light", "edge", "specular", "rim", "luz", "borde"] },
        { target: "material", group: "Texture", label: "Aurora", description: "Your colours rising off every lit edge onto what is behind, and glowing a little inside it.", path: "iris.appearance.streak.aurora", visibleWhen: "iris.appearance.texture=streak", kind: "range", fallback: 55, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Off", keywords: ["aurora", "gradient", "colours", "curtain", "cortina", "colores"] },
        { target: "material", group: "Texture", label: "Trails", description: "What a moving body leaves behind it: its lit edge, as a long exposure catches it.", path: "iris.appearance.streak.trails", visibleWhen: "iris.appearance.texture=streak", kind: "range", fallback: 60, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Off", keywords: ["trail", "motion", "long exposure", "blur", "estela", "movimiento"] },
        { target: "material", group: "Texture", label: "Aurora colours", description: "Aurora runs your accent into its two neighbours; Your colours takes accent, wallpaper and highlight as they are.", path: "iris.appearance.streak.colours", visibleWhen: "iris.appearance.texture=streak", kind: "choice", fallback: "aurora", choices: [{label:"Aurora",value:"aurora",get swatch() { return IrisStyle.streakNeighbours(Qt.color(IrisStyle.vivid(IrisStyle.baseAccent, true)))[1] }},{label:"Your colours",value:"colours",get swatch() { return IrisStyle.vivid(IrisStyle.baseSecondaryAccent, true) }},{label:"Wallpaper",value:"wallpaper",get swatch() { return Qt.color(Appearance.wallpaperDominantColor) }}], keywords: ["aurora", "colours", "wallpaper", "accent", "colores", "fondo"] },
        { target: "material", group: "Texture", label: "Grade", description: "The light Afterglow is lit with.", path: "iris.appearance.afterglow.grade", visibleWhen: "iris.appearance.texture=afterglow", kind: "choice", fallback: "dusk",
            choices: [{label:"Dusk",value:"dusk",get swatch() { return Qt.color(IrisStyle.afterglowColours("dusk").light) }},{label:"Cyber",value:"cyber",get swatch() { return Qt.color(IrisStyle.afterglowColours("cyber").light) }},{label:"Fog",value:"fog",get swatch() { return Qt.color(IrisStyle.afterglowColours("fog").light) }},{label:"Acid",value:"acid",get swatch() { return Qt.color(IrisStyle.afterglowColours("acid").bloom) }},{label:"Wallpaper",value:"wallpaper",get swatch() { return Qt.color(IrisStyle.afterglowColours("wallpaper").light) }}],
            keywords: ["grade", "grading", "colour grade", "amber", "teal", "orange", "sunset", "ice", "fog", "haze", "lut", "tinte", "atardecer", "niebla"] },
        { target: "material", group: "Texture", label: "Atmosphere", description: "How strongly the grade tints the blacks and the light.", path: "iris.appearance.afterglow.atmosphere", visibleWhen: "iris.appearance.texture=afterglow", kind: "range", fallback: 45, min: 0, max: 100, step: 5, unit: " %", keywords: ["atmosphere", "grade", "tint", "blacks", "lift", "atmosfera"] },
        { target: "material", group: "Texture", label: "Chrome", description: "The bevel every edge wears: a chrome lip reflecting a lit sky over dark ground.", path: "iris.appearance.afterglow.chrome", visibleWhen: "iris.appearance.texture=afterglow", kind: "range", fallback: 35, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Off", keywords: ["chrome", "bevel", "metal", "edge", "shine", "cromo", "bisel"] },
        { target: "material", group: "Texture", label: "Bloom", description: "Light that spills past the edges and glows on the side facing the light.", path: "iris.appearance.afterglow.bloom", visibleWhen: "iris.appearance.texture=afterglow", kind: "range", fallback: 35, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Off", keywords: ["bloom", "glow", "halo", "overexposure", "resplandor", "brillo"] },
        { target: "material", group: "Texture", label: "Signal", description: "Scanlines and the slight colour fringe of a tube screen.", path: "iris.appearance.afterglow.signal", visibleWhen: "iris.appearance.texture=afterglow", kind: "range", fallback: 0, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Off", keywords: ["signal", "crt", "scanlines", "tube", "tv", "fringe", "ycbcr", "lineas", "television"] },
        { target: "material", group: "Texture", label: "Grade the wallpaper", description: "The wallpaper gets the same light, live ones and the lock included, so the whole screen matches.", path: "iris.appearance.afterglow.wallpaper", visibleWhen: "iris.appearance.texture=afterglow", kind: "switch", fallback: true, keywords: ["wallpaper", "background", "grade", "desktop", "fondo"] },
        { target: "material", group: "Texture", part: "Light", label: "Grade", description: "The film's colours.", path: "iris.appearance.leak.grade", visibleWhen: "iris.appearance.texture=leak", kind: "choice", fallback: "haze",
            choices: [{label:"Haze",value:"haze",get swatch() { return Qt.color(IrisStyle.leakColours("haze").glow) }},{label:"Tide",value:"tide",get swatch() { return Qt.color(IrisStyle.leakColours("tide").glow) }},{label:"Moss",value:"moss",get swatch() { return Qt.color(IrisStyle.leakColours("moss").glow) }},{label:"Prism",value:"prism",get swatch() { return Qt.color(IrisStyle.leakColours("prism").glow) }},{label:"Ember",value:"ember",get swatch() { return Qt.color(IrisStyle.leakColours("ember").glow) }},{label:"Orchid",value:"orchid",get swatch() { return Qt.color(IrisStyle.leakColours("orchid").glow) }},{label:"Polaroid",value:"polaroid",get swatch() { return Qt.color(IrisStyle.leakColours("polaroid").glow) }},{label:"Accent",value:"accent",get swatch() { return Qt.color(IrisStyle.leakColours("accent").glow) }},{label:"Wallpaper",value:"wallpaper",get swatch() { return Qt.color(IrisStyle.leakColours("wallpaper").glow) }}],
            keywords: ["grade", "colour", "film", "prism", "rainbow", "spectrum", "ember", "burn", "orchid", "pink", "polaroid", "haze", "lilac", "tide", "blue", "moss", "green", "grainy gradient", "accent", "theme", "arcoiris", "espectro", "acento", "bruma", "marea", "musgo"] },
        { target: "material", group: "Texture", part: "Light", label: "Shape", description: "The shape the light takes: a haze from one corner over a band of colour, a prismatic eye over a hot horizon, a burnt corner, grain-gradient orbs, or a beam under a stroke of light.", path: "iris.appearance.leak.shape", visibleWhen: "iris.appearance.texture=leak", kind: "choice", fallback: "haze",
            choices: [{label:"Haze",value:"haze",glyph:"blur_on"},{label:"Lens",value:"lens",glyph:"lens_blur"},{label:"Burn",value:"burn",glyph:"local_fire_department"},{label:"Orbs",value:"orbs",glyph:"bubble_chart"},{label:"Beam",value:"beam",glyph:"flashlight_on"}],
            keywords: ["shape", "source", "lens", "eye", "burn", "orbs", "beam", "flare", "horizon", "lente", "quemado", "orbes", "haz"] },
        { target: "material", group: "Texture", part: "Light", label: "Across", description: "Moves the light sideways.", path: "iris.appearance.leak.x", visibleWhen: "iris.appearance.texture=leak", kind: "range", fallback: 0, min: -50, max: 50, step: 5, unit: " %", zeroLabel: "Preset", keywords: ["position", "move", "left", "right", "drag", "where", "posicion", "mover", "izquierda", "derecha"] },
        { target: "material", group: "Texture", part: "Light", label: "Up and down", description: "Moves the light up or down.", path: "iris.appearance.leak.y", visibleWhen: "iris.appearance.texture=leak", kind: "range", fallback: 0, min: -50, max: 50, step: 5, unit: " %", zeroLabel: "Preset", keywords: ["position", "move", "up", "down", "height", "drag", "posicion", "arriba", "abajo", "altura"] },
        { target: "material", group: "Texture", part: "Light", label: "Light", description: "How much light reaches the surfaces: it glows through them as a grain gradient and burns the edge it enters by.", path: "iris.appearance.leak.light", visibleWhen: "iris.appearance.texture=leak", kind: "range", fallback: 60, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Off", keywords: ["light", "exposure", "leak", "glow", "luz", "exposicion"] },
        { target: "material", group: "Texture", part: "Light", label: "Frame", description: "How much light the screen's edge catches.", path: "iris.appearance.leak.frame", visibleWhen: "iris.appearance.texture=leak", showIf: () => IrisFrame.framed, kind: "range", fallback: 100, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Off", keywords: ["frame", "edge", "border", "band", "screen", "marco", "borde"] },
        { target: "material", group: "Texture", part: "Light", label: "Widgets", description: "How much light the desktop widgets catch.", path: "iris.appearance.leak.widgets", visibleWhen: "iris.appearance.texture=leak", kind: "range", fallback: 100, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Off", keywords: ["widgets", "desktop", "cards", "plates", "escritorio", "tarjetas"] },
        { target: "material", group: "Texture", part: "Film", label: "Spill", description: "Light that spills past the edges, red reaching furthest, its tail breaking into grain.", path: "iris.appearance.leak.spill", visibleWhen: "iris.appearance.texture=leak", kind: "range", fallback: 35, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Off", keywords: ["spill", "halo", "halation", "glow", "bloom", "halacion", "resplandor"] },
        { target: "material", group: "Texture", part: "Film", label: "Prism", description: "How far the light splits into its colours.", path: "iris.appearance.leak.prism", visibleWhen: "iris.appearance.texture=leak", kind: "range", fallback: 15, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Off", keywords: ["prism", "dispersion", "chromatic", "aberration", "rainbow", "prisma", "dispersion", "arcoiris"] },
        { target: "material", group: "Texture", part: "Film", label: "Grain", description: "Film grain through the light: the edges of every shape dissolve into it.", path: "iris.appearance.leak.grain", visibleWhen: "iris.appearance.texture=leak", kind: "range", fallback: 55, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Off", keywords: ["grain", "noise", "film", "texture", "grano", "ruido"] },
        { target: "material", group: "Texture", part: "Film", label: "Grain size", description: "Fine like a slow film, coarse like a fast one.", path: "iris.appearance.leak.grainSize", visibleWhen: "iris.appearance.texture=leak", kind: "range", fallback: 1.6, min: 1, max: 4, step: 0.2, unit: " px", keywords: ["grain", "size", "coarse", "fine", "iso", "film", "tamano del grano", "grueso", "fino"] },
        { target: "material", group: "Texture", part: "Film", label: "Streaks", description: "Vertical smears, as light dragged across the film.", path: "iris.appearance.leak.streaks", visibleWhen: "iris.appearance.texture=leak", kind: "range", fallback: 0, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Off", keywords: ["streaks", "smear", "scan", "motion", "vertical", "estrias", "barrido"] },
        { target: "material", group: "Texture", part: "Film", label: "Dust and bokeh", description: "Motes of dust and out-of-focus discs of the grade in the dark of the wallpaper.", path: "iris.appearance.leak.dust", visibleWhen: "iris.appearance.texture=leak", kind: "range", fallback: 0, min: 0, max: 200, step: 10, unit: " %", zeroLabel: "Off", keywords: ["dust", "bokeh", "specks", "discs", "lens", "polvo", "motas", "desenfoque"] },
        { target: "material", group: "Texture", part: "Film", label: "Film edge", description: "The wallpaper's corners fall off as a lens's do; with Light only, the film's edge shows too.", path: "iris.appearance.leak.gate", visibleWhen: "iris.appearance.texture=leak", kind: "switch", fallback: false, keywords: ["vignette", "corners", "gate", "film edge", "border", "vineta", "esquinas", "borde"] },
        { target: "material", group: "Texture", part: "Wallpaper", label: "Backdrop", description: "Under the light: your wallpaper, exposed by it, or the darkroom and the light alone, as the textures it comes from.", path: "iris.appearance.leak.backdrop", visibleWhen: "iris.appearance.texture=leak", kind: "choice", fallback: "picture",
            choices: [{label:"Wallpaper",value:"picture",glyph:"image"},{label:"Light only",value:"light",glyph:"flare"}],
            keywords: ["backdrop", "wallpaper", "background", "darkroom", "texture", "fondo", "luz", "textura"] },
        { target: "material", group: "Texture", part: "Wallpaper", label: "Expose the wallpaper", description: "How far your wallpaper is printed in the light: faded, sunk into the dark away from it, live ones and the lock included. Glass blurs it as printed.", path: "iris.appearance.leak.wallpaper", visibleWhen: "iris.appearance.texture=leak", kind: "range", fallback: 50, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Off", keywords: ["wallpaper", "background", "desktop", "expose", "print", "fondo", "exponer"] },
        { target: "material", group: "Texture", part: "Wallpaper", label: "Develop", description: "A new wallpaper rises out of a milky ground, as a Polaroid does.", path: "iris.appearance.leak.develop", visibleWhen: "iris.appearance.texture=leak", kind: "switch", fallback: true, keywords: ["develop", "polaroid", "fade in", "instant", "animation", "revelar", "animacion"] },
        { target: "material", group: "Glass", label: "Glass", description: "Glass blurs the wallpaper.", path: "iris.appearance.glass.mode", kind: "choice", fallback: "off", choices: [{label:"Off",value:"off",glyph:"crop_square"},{label:"Glass",value:"wallpaper",glyph:"blur_on"},{label:"Blur (beta)",value:"compositor",glyph:"lens_blur"}] },
        { target: "material", group: "Glass", label: "Tint", showIf: () => IrisStyle.glassy, description: "How much material covers the glass.", path: "iris.appearance.glass.tint", kind: "range", fallback: 58, min: 12, max: 96, step: 2, unit: " %" },
        { target: "material", group: "Glass", label: "Frost", description: "How blurred the wallpaper is behind the glass, on iRiS and on glass widgets.", path: "iris.appearance.glass.blur", showIf: () => IrisStyle.glassWallpaper || root.widgetFaces, kind: "range", fallback: 100, min: 20, max: 100, step: 5, unit: " %" },
        { target: "material", group: "Glass", comp: "blur", key: "enabled", label: "Compositor blur", description: "Blur asks the compositor to blur what is behind iRiS.", visibleWhen: "iris.appearance.glass.mode=compositor", showIf: () => IrisCompositorBlur.available, kind: "switch", fallback: true, keywords: ["niri", "blur", "compositor", "desenfoque"] },
        { target: "material", group: "Glass", comp: "blur", key: "strength", label: "Blur strength", visibleWhen: "iris.appearance.glass.mode=compositor", showIf: () => IrisCompositorBlur.usable, kind: "choice", fallback: "balanced", choices: [{label:"Light",value:"light"},{label:"Balanced",value:"balanced"},{label:"Strong",value:"strong"}], keywords: ["niri", "blur", "radius", "passes"] },
        { target: "material", group: "Glass", comp: "blur", key: "saturation", label: "Colour behind", description: "Above 1 makes what is blurred more vivid.", visibleWhen: "iris.appearance.glass.mode=compositor", showIf: () => IrisCompositorBlur.usable, kind: "range", fallback: 1.5, min: 0.5, max: 2.5, step: 0.1, unit: "×", keywords: ["saturation", "vibrancy"] },
        { target: "material", group: "Glass", comp: "blur", key: "noise", label: "Grain", description: "A little noise hides banding in soft gradients.", visibleWhen: "iris.appearance.glass.mode=compositor", showIf: () => IrisCompositorBlur.usable, kind: "range", fallback: 0.02, min: 0, max: 0.1, step: 0.01, scale: 100, unit: " %", keywords: ["noise", "grain", "banding"] },
        { target: "material", group: "Edges", label: "Style", showIf: () => !IrisStyle.afterglow && !IrisStyle.streak, description: "Line is an even hairline.", warns: true, note: () => root.edgeNote(), kind: "choice", bundle: ["iris.appearance.theme.rim", "iris.appearance.theme.edges"], choices: [{label:"None",value:"none",glyph:"crop_free",values:[false,"line"]},{label:"Line",value:"line",glyph:"crop_square",values:[true,"line"]},{label:"Lit",value:"light",glyph:"light_mode",values:[true,"light"]}], keywords: ["edge", "edges", "border", "outline", "rim", "hairline", "light", "glass", "borde", "bordes", "contorno"] },
        { target: "material", group: "Edges", label: "Outline colour", path: "iris.appearance.theme.rimTint", showIf: () => IrisStyle.edgeStyle === "line", kind: "choice", tune: true, fallback: "neutral", choices: [{label:"Neutral",value:"neutral"},{label:"Accent",value:"accent"},{label:"Highlight",value:"highlight"}] },
        { target: "material", group: "Edges", label: "Edge light", description: "How much light the top edge catches.", path: "iris.appearance.glass.edgeLight", showIf: () => (!IrisStyle.afterglow && !IrisStyle.streak && (IrisStyle.edgeStyle === "light" || IrisStyle.glassy)) || root.widgetGlass, kind: "range", fallback: 14, min: 0, max: 100, step: 2, unit: " %", zeroLabel: "Off", keywords: ["edge", "rim", "highlight", "border", "outline", "shine", "borde", "filo", "brillo"] },
        { target: "material", group: "Edges", label: "Edge line", description: "The edge away from the light.", path: "iris.appearance.glass.edgeLine", showIf: () => (!IrisStyle.afterglow && !IrisStyle.streak && (IrisStyle.edgeStyle === "light" || IrisStyle.glassy)) || root.widgetGlass, kind: "range", fallback: 0, min: 0, max: 60, step: 2, unit: " %", zeroLabel: "Off", keywords: ["edge", "border", "outline", "jagged", "aliasing", "borde", "serrucho"] },
        { target: "material", group: "Edges", label: "Edge width", description: "In screen pixels: 1 is the finest line your screen can draw.", path: "iris.appearance.theme.rimWidth", showIf: () => (!IrisStyle.afterglow && IrisStyle.edgeStyle !== "none") || IrisStyle.glassy || root.widgetGlass, kind: "range", fallback: 1, min: 1, max: 3, unit: " px", keywords: ["edge", "border", "thickness", "borde", "grosor"] },
        { target: "material", group: "Edges", label: "Edge colour", description: "Scene takes the wallpaper's light.", path: "iris.appearance.glass.edgeColour", showIf: () => (!IrisStyle.afterglow && !IrisStyle.streak && (IrisStyle.edgeStyle === "light" || IrisStyle.glassy)) || root.widgetGlass, kind: "choice", tune: true, fallback: "scene", choices: [{label:"Scene",value:"scene",glyph:"wallpaper"},{label:"White",value:"white",glyph:"light_mode"},{label:"Accent",value:"accent",glyph:"palette"},{label:"Highlight",value:"highlight",glyph:"auto_awesome"}], keywords: ["edge", "colour", "color", "borde", "color del borde"] },
        { target: "material", group: "Shape", label: "Base corners", description: "Corners of panels, buttons and fields that don't set their own.", path: "iris.appearance.expandedRadius", kind: "range", fallback: 22, min: 16, max: 40, unit: " px", keywords: ["expanded", "radius", "buttons", "fields", "panels", "round"] },
        { target: "material", group: "Shape", label: "Corners", description: "Every radius in the family; nested corners keep stepping down.", path: "iris.appearance.theme.shape", kind: "range", fallback: 100, min: 30, max: 160, step: 5, unit: " %" },
        { target: "material", group: "Shape", label: "One shape for all", mirror: true, description: "The Island, the Dock and the bubbles share the bubbles' shape.", path: "iris.appearance.theme.linkShapes", kind: "switch", fallback: false, keywords: ["same", "match", "link", "linked", "together", "sync", "unify", "everything", "one shape", "mismo", "igual", "todo", "juntos", "vincular"] },
        { target: "material", group: "Shape", label: "All shapes", mirror: true, visibleWhen: "iris.appearance.theme.linkShapes", path: "iris.appearance.theme.pieceShape", kind: "choice", fallback: "circle", choices: [{label:"Circle",value:"circle",glyph:"circle"},{label:"Squircle",value:"squircle",glyph:"rounded_corner"},{label:"Square",value:"square",glyph:"square"}], keywords: ["square", "squared", "boxy", "rectangle", "sharp", "round", "rounded", "circle", "squircle", "corners", "radius", "curves", "cuadrado", "cuadrada", "redondo", "redonda", "esquinas", "curvas", "forma"] },
        { target: "material", group: "Shape", label: "Bubble shape", mirror: true, visibleWhen: "!iris.appearance.theme.linkShapes", path: "iris.appearance.theme.pieceShape", kind: "choice", fallback: "circle", choices: [{label:"Circle",value:"circle",glyph:"circle"},{label:"Squircle",value:"squircle",glyph:"rounded_corner"},{label:"Square",value:"square",glyph:"square"}], keywords: ["square", "squared", "boxy", "rectangle", "sharp", "round", "rounded", "capsule", "pill", "circle", "squircle", "corners", "radius", "curves", "cuadrado", "cuadrada", "redondo", "redonda", "esquinas", "curvas", "forma"] },
        { target: "material", group: "Shape", label: "Island shape", mirror: true, visibleWhen: "!iris.appearance.theme.linkShapes", path: "iris.bar.shape", kind: "choice", fallback: "auto", choices: [{label:"Auto",value:"auto",glyph:"auto_awesome"},{label:"Round",value:"round",glyph:"circle"},{label:"Squircle",value:"squircle",glyph:"rounded_corner"},{label:"Square",value:"square",glyph:"square"}], keywords: ["square", "squared", "boxy", "rectangle", "sharp", "round", "rounded", "capsule", "pill", "circle", "squircle", "corners", "radius", "curves", "cuadrado", "cuadrada", "redondo", "redonda", "esquinas", "curvas", "forma"] },
        { target: "material", group: "Shape", label: "Dock shape", mirror: true, visibleWhen: "!iris.appearance.theme.linkShapes", showIf: () => !IrisFrame.rail, path: "iris.dock.shape", kind: "choice", fallback: "auto", choices: [{label:"Auto",value:"auto",glyph:"auto_awesome"},{label:"Round",value:"round",glyph:"circle"},{label:"Squircle",value:"squircle",glyph:"rounded_corner"},{label:"Square",value:"square",glyph:"square"}], keywords: ["square", "squared", "boxy", "rectangle", "sharp", "round", "rounded", "capsule", "pill", "circle", "squircle", "corners", "radius", "curves", "cuadrado", "cuadrada", "redondo", "redonda", "esquinas", "curvas", "forma"] },
        { target: "material", group: "Shape", label: "Fusion", description: "How deeply shapes melt where they meet.", path: "iris.appearance.theme.melt", kind: "range", fallback: 0, min: 0, max: 200, step: 5, unit: " %" },
        { target: "material", group: "Shape", label: "Spacing", description: "Padding, gaps and control sizes.", path: "iris.appearance.density", kind: "range", fallback: 1, min: 0.8, max: 1.35, step: 0.05, unit: "×" },
        { target: "material", group: "Icons", label: "Icon pack", description: "How iRiS draws its icons.", path: "iris.appearance.icons.style", kind: "choice", fallback: "glyph", choices: [{label:"Glyph",value:"glyph",glyph:"category",detail:"The glyph alone in its colour, as the widgets."},{label:"iRiS",value:"iris",glyph:"apps",detail:"On a plate."},{label:"Tiles",value:"tile",glyph:"gradient",detail:"On an app-icon tile."}], keywords: ["icons", "glyphs", "symbols", "material symbols", "pack", "tile", "tiles", "plate", "gradient", "depth", "app icon", "glyph", "plain", "no plate", "folio", "iconos", "glifos", "paquete", "degradado", "placa", "sin placa"] },
        { target: "material", group: "Icons", label: "Shape", description: "The corners of every icon plate.", path: "iris.appearance.icons.shape", kind: "choice", fallback: "auto", showIf: () => !IrisStyle.plainMarks, choices: [{label:"Auto",value:"auto",glyph:"auto_awesome"},{label:"Round",value:"round",glyph:"circle"},{label:"Square",value:"square",glyph:"square"}], keywords: ["shape", "corners", "round", "circle", "square", "squircle", "icon", "forma", "esquinas", "redondo", "cuadrado"] },
        { target: "material", group: "Icons", label: "Colour", description: "Auto gives each area its colour; a line look (Nothing) draws them in ink.", path: "iris.appearance.icons.colour", kind: "choice", fallback: "auto", choices: [{label:"Auto",value:"auto",glyph:"auto_awesome"},{label:"Areas",value:"area",glyph:"palette"},{label:"Accent",value:"accent",get swatch() { return IrisStyle.accent }},{label:"Mono",value:"mono",get swatch() { return IrisStyle.identity.gray }}], keywords: ["colour", "color", "tint", "mono", "monochrome", "grey", "gray", "accent", "ink", "colorful", "color de iconos", "monocromo", "gris"] },
        { target: "material", group: "Icons", label: "Glyphs", description: "The set every glyph is drawn from.", path: "iris.appearance.icons.glyphs", kind: "choice", fallback: "rounded", choices: [{label:"Rounded",value:"rounded"},{label:"Standard",value:"standard"},{label:"Sharp",value:"sharp"}].filter(choice => !IrisStyle.glyphFonts[choice.value] || Qt.fontFamilies().includes(IrisStyle.glyphFonts[choice.value])), keywords: ["glyphs", "iconography", "icon set", "icon font", "symbols", "sharp", "rounded", "outlined", "iconografía", "símbolos", "redondeados", "rectos"] },
        { target: "material", group: "Icons", label: "Fill", description: "Auto fills them, as the widgets do; a line look outlines them.", path: "iris.appearance.icons.fill", kind: "choice", fallback: "auto", choices: [{label:"Auto",value:"auto"},{label:"Filled",value:"filled"},{label:"Outlined",value:"outlined"}], keywords: ["fill", "filled", "outline", "outlined", "solid", "line", "relleno", "contorno"] },
        { target: "material", group: "Icons", label: "Weight", description: "How heavy every glyph's line is.", path: "iris.appearance.icons.weight", kind: "choice", fallback: "regular", choices: [{label:"Light",value:"light"},{label:"Regular",value:"regular"},{label:"Bold",value:"bold"}], keywords: ["weight", "thin", "light", "bold", "heavy", "stroke", "line", "grosor", "fino", "negrita"] },
        { target: "material", group: "Icons", label: "Plate", description: "The plate behind icons.", path: "iris.appearance.icons.plate", kind: "choice", fallback: "black", visibleWhen: "iris.appearance.icons.style=tile", choices: [{label:"Black",value:"black",get swatch() { return IrisStyle.plateBlackBase }},{label:"White",value:"white",get swatch() { return IrisStyle.plateWhiteBase }},{label:"Tint",value:"tint",get swatch() { return IrisStyle.identity.lavender }},{label:"Surface",value:"surface",get swatch() { return IrisStyle.surfaceHighestOpaque }}], keywords: ["plate", "background", "behind", "black", "white", "light", "dark", "tile", "icon", "placa", "fondo", "negro", "blanco", "claro", "oscuro"] },
        { target: "material", group: "Frame", label: "Close the shell around the screen", description: "A black band around the screen with rounded inner corners.", path: "iris.surround.enable", kind: "switch", fallback: true },
        { target: "material", group: "Frame", label: "Frame width", path: "iris.surround.thickness", visibleWhen: "iris.surround.enable", kind: "range", fallback: 10, min: 4, max: 28, unit: " px" },
        { target: "material", group: "Frame", label: "Screen corners", description: "How round the frame turns inward at the corners of the screen.", path: "iris.surround.radius", visibleWhen: "iris.surround.enable", kind: "range", fallback: 22, min: 0, max: 44, unit: " px" },
        { target: "material", group: "Frame", label: "Rail", showIf: () => Config.options?.iris?.dock?.enable ?? true, description: "The frame grows wide on one side and holds your Dock's apps, like a browser's sidebar.", path: "iris.surround.rail", visibleWhen: "iris.surround.enable", kind: "choice", fallback: "none", choices: [{label:"None",value:"none"},{label:"Left",value:"left",glyph:"left_panel_open"},{label:"Right",value:"right",glyph:"right_panel_open"}], keywords: ["rail", "sidebar", "side bar", "vertical dock", "browser", "zen", "arc", "strip", "barra lateral", "riel", "lateral", "dock vertical"] },
        { target: "material", group: "Frame", label: "Rail width", description: "How wide the rail stands inside the frame; its icons grow with it.", path: "iris.surround.railSize", showIf: () => IrisFrame.rail, kind: "range", fallback: 46, min: 40, max: 72, step: 2, unit: " px", keywords: ["rail", "size", "width", "icons", "slim", "tamaño", "ancho", "riel"] },
        { target: "material", group: "Frame", label: "Rail apps", description: "Top lines them up under the launcher like a browser's tabs; Centre holds them in the middle like a Dock.", path: "iris.surround.railApps", showIf: () => IrisFrame.rail, kind: "choice", fallback: "top", choices: [{label:"Top",value:"top",glyph:"vertical_align_top"},{label:"Centre",value:"centre",glyph:"vertical_align_center"}], keywords: ["rail", "apps", "align", "centre", "center", "top", "alinear", "centro", "arriba"] },
        { target: "material", group: "Frame", label: "Rail buttons", description: "The + that pins apps and the gear that opens Settings.", path: "iris.surround.railButtons", showIf: () => IrisFrame.rail, kind: "switch", fallback: true, keywords: ["rail", "buttons", "plus", "settings", "gear", "botones", "riel"] },
        { target: "material", group: "Frame", label: "Frame light", description: "Holo lights the frame like the back of a CD: a spectral rim with a halo over the screen, on any material.", path: "iris.surround.style", visibleWhen: "iris.surround.enable", kind: "choice", fallback: "plain", choices: [{label:"Plain",value:"plain"},{label:"Holo",value:"holo"}], keywords: ["holo", "holographic", "spectrum", "rainbow", "cd", "eclipse", "holográfico", "marco"] },
        { target: "material", group: "Frame", label: "Holo light", description: "How brightly the spectral rim burns.", path: "iris.surround.holoLight", visibleWhen: "iris.surround.style=holo", showIf: () => Boolean(Config.options?.iris?.surround?.enable), kind: "range", fallback: 45, min: 5, max: 100, step: 5, unit: " %" },
        { target: "material", group: "Frame", label: "Holo halo", description: "How far the light spills over the screen; 0 keeps it on the frame.", path: "iris.surround.holoHalo", visibleWhen: "iris.surround.style=holo", showIf: () => Boolean(Config.options?.iris?.surround?.enable), kind: "range", fallback: 40, min: 0, max: 100, step: 5, unit: " %" },
        { section: "player", group: "Frame music", label: "Music on the edges", description: "Let music animate an Organic Edge wave or swell the iRiS frame itself.", path: "background.edgeWidgets.organic.enable", kind: "switch", fallback: false, keywords: ["music", "frame", "visualizer", "cava"] },
        { section: "player", group: "Frame music", label: "Music drives", path: "iris.surround.music", visibleWhen: "background.edgeWidgets.organic.enable", kind: "choice", fallback: "widget", choices: [{label:"The wave",value:"widget"},{label:"The frame",value:"frame"}] },
        { section: "player", group: "Edge wave", label: "Look", description: "Where the wave sits, what it is made of and how it answers the music, at once.", bundle: root.waveKeys.map(key => OrganicEdgeConfig.path + "." + key), visibleWhen: "iris.surround.music=widget", showIf: () => root.waveShown(), kind: "choice", choices: [root.waveScene("Quiet Horizon", "Horizon", "water"), root.waveScene("Aurora Rails", "Rails", "flare"), root.waveScene("Album Tide", "Tide", "album"), root.waveScene("Pulse Gate", "Pulse", "graphic_eq"), root.waveScene("Contour Frame", "Contour", "select_all")], keywords: ["wave", "organic", "edge", "scene", "preset", "horizon", "rails", "tide", "pulse", "contour", "onda", "borde"] },
        { section: "player", group: "Edge wave", label: "Colours", description: "Adaptive follows the wallpaper and the cover; Theme keeps to your accent.", path: "background.edgeWidgets.organic.palette", visibleWhen: "iris.surround.music=widget", showIf: () => root.waveShown(), tune: true, kind: "choice", fallback: "theme", choices: [{label:"Adaptive",value:"adaptive"},{label:"Theme",value:"theme"},{label:"Wallpaper",value:"wallpaper"},{label:"Album",value:"album"},{label:"Vivid",value:"vivid"},{label:"Iridescent",value:"iridescent"},{label:"Monochrome",value:"mono"},{label:"Cool",value:"cool"},{label:"Warm",value:"warm"},{label:"Your colours",value:"custom"}], keywords: ["colour", "color", "palette", "wave", "paleta", "colores"] },
        { section: "player", group: "Edge wave", label: "Moves with the music", description: "Off, it drifts on its own whatever plays.", path: "background.edgeWidgets.organic.audioReactive", visibleWhen: "iris.surround.music=widget", showIf: () => root.waveShown(), kind: "switch", fallback: true, keywords: ["audio", "music", "react", "cava", "musica"] },
        { section: "player", group: "Edge wave", label: "In silence", path: "background.edgeWidgets.organic.idleMode", visibleWhen: "iris.surround.music=widget", showIf: () => root.waveShown(), tune: true, kind: "choice", fallback: "ambient", choices: [{label:"Drifts",value:"ambient"},{label:"Rests",value:"still"},{label:"Hides",value:"hidden"}], keywords: ["idle", "silence", "quiet", "hidden", "silencio"] },
        { section: "player", group: "Edge wave", label: "Strength", description: "How much of the wave shows over the desktop.", path: "background.edgeWidgets.organic.opacity", visibleWhen: "iris.surround.music=widget", showIf: () => root.waveShown(), kind: "range", fallback: 100, min: 10, max: 100, step: 5, unit: " %", keywords: ["opacity", "strength", "visible", "opacidad"] },
        { section: "player", group: "Frame response", label: "Edges", description: "Which sides of the frame move with the music.", path: "iris.surround.musicEdges", visibleWhen: "iris.surround.music=frame", showIf: () => Boolean(Config.options?.background?.edgeWidgets?.organic?.enable) && Boolean(Config.options?.iris?.surround?.enable), kind: "choice", fallback: "sides", choices: [{label:"Left and right",value:"sides"},{label:"Top and bottom",value:"horizontal"},{label:"All four",value:"all"}] },
        { section: "player", group: "Frame response", label: "Strength", description: "How far the frame swells into the screen.", path: "iris.surround.musicStrength", visibleWhen: "iris.surround.music=frame", showIf: () => Boolean(Config.options?.background?.edgeWidgets?.organic?.enable) && Boolean(Config.options?.iris?.surround?.enable), kind: "range", fallback: 160, min: 50, max: 300, step: 10, unit: " %" },
        { section: "player", group: "Frame response", label: "Sensitivity", description: "How strongly quiet passages move the frame.", path: "iris.surround.musicSensitivity", visibleWhen: "iris.surround.music=frame", showIf: () => Boolean(Config.options?.background?.edgeWidgets?.organic?.enable) && Boolean(Config.options?.iris?.surround?.enable), kind: "range", fallback: 140, min: 50, max: 250, step: 10, unit: " %" },
        { section: "player", group: "Frame response", label: "Travel speed", description: "How quickly the swell flows along the edge.", path: "iris.surround.musicSpeed", visibleWhen: "iris.surround.music=frame", showIf: () => Boolean(Config.options?.background?.edgeWidgets?.organic?.enable) && Boolean(Config.options?.iris?.surround?.enable), kind: "range", fallback: 100, min: 40, max: 200, step: 10, unit: " %" },
        { section: "player", group: "Frame finish", label: "Appearance", description: "Sculpted is pure shape.", path: "iris.surround.musicAppearance", visibleWhen: "iris.surround.music=frame", showIf: () => Boolean(Config.options?.background?.edgeWidgets?.organic?.enable) && Boolean(Config.options?.iris?.surround?.enable), kind: "choice", fallback: "etched", choices: [{label:"Sculpted",value:"sculpted"},{label:"Etched",value:"etched"},{label:"Satin",value:"satin"}] },
        { section: "player", group: "Frame finish", label: "Light colour", description: "Pearl follows iRiS ink; the other choices follow your theme and wallpaper.", path: "iris.surround.musicColour", visibleWhen: "iris.surround.music=frame", showIf: () => Boolean(Config.options?.background?.edgeWidgets?.organic?.enable) && Boolean(Config.options?.iris?.surround?.enable) && String(Config.options?.iris?.surround?.musicAppearance ?? "etched") !== "sculpted", tune: true, kind: "choice", fallback: "pearl", choices: [{label:"Pearl",value:"pearl",get swatch() { return IrisStyle.text }},{label:"Accent",value:"accent",get swatch() { return IrisStyle.accent }},{label:"Highlight",value:"highlight",get swatch() { return IrisStyle.secondaryAccent }},{label:"Wallpaper",value:"wallpaper",get swatch() { return IrisStyle.wallpaperLight }}] },
        { section: "player", group: "Frame finish", label: "Light", description: "How much of the chosen colour rests on the moving frame.", path: "iris.surround.musicLight", visibleWhen: "iris.surround.music=frame", showIf: () => Boolean(Config.options?.background?.edgeWidgets?.organic?.enable) && Boolean(Config.options?.iris?.surround?.enable) && String(Config.options?.iris?.surround?.musicAppearance ?? "etched") !== "sculpted", kind: "range", fallback: 35, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Off" },
        { section: "player", group: "Frame finish", label: "Light width", description: "A hairline for Etched, or a wider falloff for Satin.", path: "iris.surround.musicLightWidth", visibleWhen: "iris.surround.music=frame", showIf: () => Boolean(Config.options?.background?.edgeWidgets?.organic?.enable) && Boolean(Config.options?.iris?.surround?.enable) && String(Config.options?.iris?.surround?.musicAppearance ?? "etched") !== "sculpted", kind: "range", fallback: 5, min: 1, max: 18, unit: " px" },
        { target: "colour", group: "Look", label: "Look", description: "The dialect iRiS speaks: how controls are made, what marks the chosen thing, the voice of labels. Each place below can wear its own.", path: "iris.appearance.look", kind: "choice", fallback: "apple", choices: [{label:"Apple",value:"apple",detail:"Wears your accent."},{label:"Nothing OS",value:"nothing",detail:"Ink and one signal colour."},{label:"Synth",value:"synth",detail:"Hardware keys and faders."},{label:"Gel",value:"gel",detail:"Glossy capsules."},{label:"Prism",value:"prism",detail:"Black and white, light breaking at each level."}], keywords: ["look", "apple", "nothing", "synth", "gel", "prism", "black and white", "blanco y negro", "glossy", "instrument", "accent", "ink", "monochrome", "white", "aspecto", "acento", "blanco"] },
        { target: "colour", group: "Look", part: "Nothing OS", label: "Chosen", description: "What marks the chosen segment, the lit tile, the current row.", path: "iris.appearance.looks.nothing.chosen", showIf: () => IrisStyle.looksWorn.includes("nothing"), kind: "choice", fallback: "ink", choices: [{label:"Ink",value:"ink",detail:"The inverted plate: ink fill, paper word.",get swatch() { return IrisStyle.text }},{label:"Signal",value:"signal",detail:"The signal colour marks it.",get swatch() { return IrisStyle.signal }}], keywords: ["nothing", "chosen", "selected", "inverted", "signal", "ink", "elegido", "tinta"] },
        { target: "colour", group: "Look", part: "Nothing OS", label: "Figures", description: "How large numbers read: the dot matrix of Nothing OS, or Archivo's wide figures.", path: "iris.appearance.looks.nothing.figures", showIf: () => IrisStyle.looksWorn.includes("nothing"), kind: "choice", fallback: "dots", choices: [{label:"Dots",value:"dots",glyph:"grid_on",detail:"Each digit a matrix of round dots."},{label:"Archivo",value:"archivo",glyph:"format_size",detail:"Wide, bold figures."}], keywords: ["nothing", "dots", "dot matrix", "figures", "numbers", "clock", "puntos", "matriz"] },
        { target: "colour", group: "Look", part: "Synth", label: "Keys light in", description: "A key that is on, a chosen key, the one act.", path: "iris.appearance.looks.synth.keys", showIf: () => IrisStyle.looksWorn.includes("synth"), kind: "choice", fallback: "accent", choices: [{label:"Accent",value:"accent",get swatch() { return IrisStyle.lookColour("accent", "#ff5b00") }},{label:"Highlight",value:"highlight",get swatch() { return IrisStyle.lookColour("highlight", "#ff5b00") }},{label:"Signal",value:"signal",get swatch() { return IrisStyle.signal }},{label:"Classic orange",value:"classic",get swatch() { return "#ff5b00" }}], keywords: ["synth", "keys", "led", "orange", "teenage engineering", "on", "teclas", "luz"] }, // iris-literal: stored default of the look, a value people pick
        { target: "colour", group: "Look", part: "Synth", label: "Levels run in", description: "Faders and meters.", path: "iris.appearance.looks.synth.levels", showIf: () => IrisStyle.looksWorn.includes("synth"), kind: "choice", fallback: "highlight", choices: [{label:"Highlight",value:"highlight",get swatch() { return IrisStyle.lookColour("highlight", "#0096ff") }},{label:"Accent",value:"accent",get swatch() { return IrisStyle.lookColour("accent", "#0096ff") }},{label:"Signal",value:"signal",get swatch() { return IrisStyle.signal }},{label:"Classic blue",value:"classic",get swatch() { return "#0096ff" }}], keywords: ["synth", "fader", "level", "meter", "blue", "nivel"] }, // iris-literal: stored default of the look, a value people pick
        { target: "colour", group: "Look", part: "Synth", label: "Key depth", description: "How far keys stand on their edge and sink when pressed.", path: "iris.appearance.looks.synth.depth", showIf: () => IrisStyle.looksWorn.includes("synth"), kind: "range", fallback: 3, min: 0, max: 6, step: 1, unit: " px", zeroLabel: "Flat", keywords: ["synth", "depth", "key", "travel", "edge", "profundidad"] },
        { target: "colour", group: "Look", part: "Synth", label: "Printed labels", description: "Lowercase Geist Mono on keys and titles, as printed on a panel.", path: "iris.appearance.looks.synth.mono", showIf: () => IrisStyle.looksWorn.includes("synth"), kind: "switch", fallback: true, keywords: ["synth", "mono", "lowercase", "labels", "font", "etiquetas"] },
        { target: "colour", group: "Look", part: "Gel", label: "Gel colour", description: "What fills a gel.", path: "iris.appearance.looks.gel.body", showIf: () => IrisStyle.looksWorn.includes("gel"), kind: "choice", fallback: "accent", choices: [{label:"Accent",value:"accent",get swatch() { return IrisStyle.lookColour("accent", IrisStyle.baseAccent) }},{label:"Highlight",value:"highlight",get swatch() { return IrisStyle.lookColour("highlight", IrisStyle.baseAccent) }},{label:"Signal",value:"signal",get swatch() { return IrisStyle.signal }}], keywords: ["gel", "colour", "glossy", "aqua", "color"] },
        { target: "colour", group: "Look", part: "Gel", label: "Gloss", description: "The light cap over a gel: a candy at 0, a mirror at the top.", path: "iris.appearance.looks.gel.gloss", showIf: () => IrisStyle.looksWorn.includes("gel"), kind: "range", fallback: 60, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Matte", keywords: ["gel", "gloss", "shine", "aqua", "brillo"] },
        { target: "colour", group: "Look", part: "Gel", label: "Round type", description: "Titles and figures in Rubik.", path: "iris.appearance.looks.gel.round", showIf: () => IrisStyle.looksWorn.includes("gel"), kind: "switch", fallback: true, keywords: ["gel", "rubik", "round", "font", "redonda"] },
        { target: "colour", group: "Look", part: "Places", label: "Island", path: "iris.appearance.places.island", kind: "choice", tune: true, fallback: "", choices: [{label:"As iRiS",value:""},{label:"Apple",value:"apple"},{label:"Nothing OS",value:"nothing"},{label:"Synth",value:"synth"},{label:"Gel",value:"gel"},{label:"Prism",value:"prism"}], keywords: ["look", "place", "apple", "nothing", "synth", "gel", "prism", "lugar"] },
        { target: "colour", group: "Look", part: "Places", label: "Dock", path: "iris.appearance.places.dock", kind: "choice", tune: true, fallback: "", choices: [{label:"As iRiS",value:""},{label:"Apple",value:"apple"},{label:"Nothing OS",value:"nothing"},{label:"Synth",value:"synth"},{label:"Gel",value:"gel"},{label:"Prism",value:"prism"}], keywords: ["look", "place", "apple", "nothing", "synth", "gel", "prism", "lugar"] },
        { target: "colour", group: "Look", part: "Places", label: "Control Center", path: "iris.appearance.places.control", kind: "choice", tune: true, fallback: "", choices: [{label:"As iRiS",value:""},{label:"Apple",value:"apple"},{label:"Nothing OS",value:"nothing"},{label:"Synth",value:"synth"},{label:"Gel",value:"gel"},{label:"Prism",value:"prism"}], keywords: ["look", "place", "apple", "nothing", "synth", "gel", "prism", "lugar"] },
        { target: "colour", group: "Look", part: "Places", label: "Settings", path: "iris.appearance.places.settings", kind: "choice", tune: true, fallback: "", choices: [{label:"As iRiS",value:""},{label:"Apple",value:"apple"},{label:"Nothing OS",value:"nothing"},{label:"Synth",value:"synth"},{label:"Gel",value:"gel"},{label:"Prism",value:"prism"}], keywords: ["look", "place", "apple", "nothing", "synth", "gel", "prism", "lugar"] },
        { target: "colour", group: "Look", part: "Places", label: "Spotlight", path: "iris.appearance.places.spotlight", kind: "choice", tune: true, fallback: "", choices: [{label:"As iRiS",value:""},{label:"Apple",value:"apple"},{label:"Nothing OS",value:"nothing"},{label:"Synth",value:"synth"},{label:"Gel",value:"gel"},{label:"Prism",value:"prism"}], keywords: ["look", "place", "apple", "nothing", "synth", "gel", "prism", "lugar"] },
        { target: "colour", group: "Look", part: "Places", label: "Orbit", path: "iris.appearance.places.orbit", kind: "choice", tune: true, fallback: "", choices: [{label:"As iRiS",value:""},{label:"Apple",value:"apple"},{label:"Nothing OS",value:"nothing"},{label:"Synth",value:"synth"},{label:"Gel",value:"gel"},{label:"Prism",value:"prism"}], keywords: ["look", "place", "apple", "nothing", "synth", "gel", "prism", "lugar"] },
        { target: "colour", group: "Look", part: "Places", label: "Lock screen", path: "iris.appearance.places.lock", kind: "choice", tune: true, fallback: "", choices: [{label:"As iRiS",value:""},{label:"Apple",value:"apple"},{label:"Nothing OS",value:"nothing"},{label:"Synth",value:"synth"},{label:"Gel",value:"gel"},{label:"Prism",value:"prism"}], keywords: ["look", "place", "apple", "nothing", "synth", "gel", "prism", "lugar"] },
        { target: "colour", group: "Look", part: "Places", label: "Desktop widgets", path: "iris.appearance.places.widgets", kind: "choice", tune: true, fallback: "", choices: [{label:"As iRiS",value:""},{label:"Apple",value:"apple"},{label:"Nothing OS",value:"nothing"},{label:"Synth",value:"synth"},{label:"Gel",value:"gel"},{label:"Prism",value:"prism"}], keywords: ["look", "place", "apple", "nothing", "synth", "gel", "prism", "lugar"] },
        { target: "colour", group: "Look", part: "Places", label: "Notifications", path: "iris.appearance.places.notifications", kind: "choice", tune: true, fallback: "", choices: [{label:"As iRiS",value:""},{label:"Apple",value:"apple"},{label:"Nothing OS",value:"nothing"},{label:"Synth",value:"synth"},{label:"Gel",value:"gel"},{label:"Prism",value:"prism"}], keywords: ["look", "place", "apple", "nothing", "synth", "gel", "prism", "lugar"] },
        { target: "colour", group: "Look", part: "Places", label: "Volume and brightness", path: "iris.appearance.places.osd", kind: "choice", tune: true, fallback: "", choices: [{label:"As iRiS",value:""},{label:"Apple",value:"apple"},{label:"Nothing OS",value:"nothing"},{label:"Synth",value:"synth"},{label:"Gel",value:"gel"},{label:"Prism",value:"prism"}], keywords: ["look", "place", "apple", "nothing", "synth", "gel", "prism", "lugar"] },
        { target: "colour", group: "Signal", label: "Signal", description: "The one colour iRiS uses: something live, something that needs you, an action you can't undo.", path: "iris.appearance.signal", kind: "choice", fallback: "nothing", choices: [{label:"Nothing red",value:"nothing",get swatch() { return IrisStyle.signalRed }},{label:"Ink",value:"ink",get swatch() { return IrisStyle.text }},{label:"From wallpaper",value:"wallpaper",get swatch() { return IrisStyle.vividHighlight(Appearance.wallpaperDominantColor, IrisStyle.signalRed) }},{label:"Orange",get value() { return IrisStyle.signalSwatches.orange },get swatch() { return IrisStyle.signalSwatches.orange }},{label:"Blue",get value() { return IrisStyle.signalSwatches.blue },get swatch() { return IrisStyle.signalSwatches.blue }},{label:"Green",get value() { return IrisStyle.signalSwatches.green },get swatch() { return IrisStyle.signalSwatches.green }},{label:"Pink",get value() { return IrisStyle.signalSwatches.pink },get swatch() { return IrisStyle.signalSwatches.pink }},{label:"Acid",get value() { return IrisStyle.signalSwatches.acid },get swatch() { return IrisStyle.signalSwatches.acid }}], keywords: ["signal", "accent", "red", "ink", "monochrome", "colour", "color", "live", "alert", "nothing", "senal", "rojo", "acento"] },
        { target: "colour", group: "Accent", label: "System accent", description: "What your apps wear, and what iRiS marks as chosen under the Apple look.", path: "iris.appearance.accent", kind: "choice", sources: true, fallback: "blue", get choices() { return root.designChoice("accents").concat([{label:"Blue",value:"blue",get swatch() { return IrisStyle.accents.blue }},{label:"Mint",value:"mint",get swatch() { return IrisStyle.accents.mint }},{label:"Rose",value:"rose",get swatch() { return IrisStyle.accents.rose }},{label:"Lilac",value:"lilac",get swatch() { return IrisStyle.accents.lilac }},{label:"Theme",value:"theme",get swatch() { return IrisStyle.accents.theme }},{label:"Wallpaper",value:"wallpaper",get swatch() { return IrisStyle.accents.wallpaper }},{label:"Custom",value:"custom"}]) }, locked: () => IrisStyle.followsTheme, note: () => root.followNote() },
        { target: "colour", group: "Accent", label: "Accent hue", visibleWhen: "iris.appearance.accent=custom", path: "iris.appearance.theme.accentHue", kind: "hue", fallback: 212, locked: () => IrisStyle.followsTheme, note: () => root.followNote() },
        { target: "colour", group: "Highlight", label: "Highlight", showIf: () => !IrisStyle.mono, description: "The glanced detail: clock separator, day number, timers.", path: "iris.appearance.highlight", kind: "choice", sources: true, fallback: "orange", get choices() { return root.designChoice("highlights").concat([{label:"Orange",value:"orange",get swatch() { return IrisStyle.highlights.orange }},{label:"Yellow",value:"yellow",get swatch() { return IrisStyle.highlights.yellow }},{label:"Red",value:"red",get swatch() { return IrisStyle.highlights.red }},{label:"Pink",value:"pink",get swatch() { return IrisStyle.highlights.pink }},{label:"Green",value:"green",get swatch() { return IrisStyle.highlights.green }},{label:"Accent",value:"accent",get swatch() { return IrisStyle.accent }},{label:"Theme",value:"theme",get swatch() { return IrisStyle.highlights.theme }},{label:"Wallpaper",value:"wallpaper",get swatch() { return IrisStyle.highlights.wallpaper }},{label:"Custom",value:"custom"}]) }, locked: () => IrisStyle.followsTheme, note: () => root.followNote() },
        { target: "colour", group: "Highlight", label: "Highlight hue", visibleWhen: "iris.appearance.highlight=custom", path: "iris.appearance.theme.highlightHue", kind: "hue", fallback: 32, locked: () => IrisStyle.followsTheme, note: () => root.followNote() },
        { target: "colour", group: "Colour layer", section: "anime", label: "Anime colour layer", description: "Anime accents over your colours.", path: "iris.appearance.anime.enabled", kind: "switch", fallback: false, keywords: ["anime", "weeb", "otaku", "japanese", "japones", "palette", "accent", "colour", "color"] },
        { target: "colour", group: "Colour layer", section: "anime", label: "Palette", visibleWhen: "iris.appearance.anime.enabled", path: "iris.appearance.anime.palette", kind: "choice", fallback: "sakura",
            choices: Object.keys(IrisStyle.animePalettes).map(key => ({ label: IrisStyle.animePalettes[key].label, value: key, get swatch() { return IrisStyle.animeAccent(IrisStyle.accents.blue, key, 1) } })),
            keywords: ["anime", "weeb", "otaku", "palette", "colour", "color", "pink", "rose", "cyan", "magenta", "violet", "purple", "green", "gold", "amber"].concat(Object.values(IrisStyle.animePalettes).map(entry => entry.label.toLowerCase())) },
        { target: "colour", group: "Colour layer", section: "anime", label: "Strength", visibleWhen: "iris.appearance.anime.enabled", description: "How far the palette pulls the accents away from your own; 0 keeps them exactly.", path: "iris.appearance.anime.strength", kind: "range", fallback: 60, min: 0, max: 100, step: 5, unit: " %", keywords: ["anime", "weeb", "otaku", "palette", "intensidad", "intensity", "strength", "blend"] },
        { target: "colour", group: "Colour layer", section: "anime", label: "Recolour the highlight", visibleWhen: "iris.appearance.anime.enabled", description: "The highlight takes the anime palette too.", path: "iris.appearance.anime.highlight", kind: "switch", fallback: false, keywords: ["anime", "weeb", "otaku", "palette", "highlight", "colour", "color"] },
        { target: "colour", group: "Airing", section: "anime", label: "Airing bubble", description: "The next episode on the Island; its card lists what's coming.", path: "iris.bubbles.extras.anime.enable", kind: "switch", fallback: false, keywords: ["anime", "weeb", "otaku", "airing", "japanese", "japones", "tracker", "following", "episodes", "episodio", "schedule", "live tv"] },
        { target: "colour", group: "Airing", section: "anime", label: "Episodes in the card", description: "How many upcoming episodes the Airing bubble lists.", path: "iris.anime.shows", kind: "range", fallback: 5, min: 3, max: 8, keywords: ["anime", "weeb", "otaku", "airing", "episodes", "episodio", "following", "shows"] },
        { target: "colour", group: "Badges", label: "Unread counts", tune: true, description: "The family's red, your accent, the highlight, or a quiet neutral.", path: "iris.appearance.theme.badge", kind: "choice", fallback: "alert", choices: [{label:"Alert",value:"alert",get swatch() { return IrisStyle.identity.red }},{label:"Accent",value:"accent"},{label:"Highlight",value:"highlight",get swatch() { return IrisStyle.secondaryAccent }},{label:"Neutral",value:"neutral",get swatch() { return IrisStyle.surfaceHighestOpaque }}] },
        { target: "colour", group: "Light", label: "Light", description: "What lights an open card: its own colour or the wallpaper's.", path: "iris.appearance.aura", kind: "choice", fallback: "subtle", choices: [{label:"Off",value:"off",glyph:"light_off"},{label:"Subtle",value:"subtle",glyph:"light_mode"},{label:"Vivid",value:"vivid",glyph:"wb_sunny"}] },
        { target: "colour", group: "Light", label: "Reach", description: "How far the light goes into a body: just its head, or deeper.", path: "iris.appearance.theme.lightReach", kind: "range", fallback: 100, min: 50, max: 300, step: 5, unit: " %" },
        { target: "colour", group: "Light", label: "Glow", description: "Floating surfaces cast an accent halo instead of a dark shadow.", path: "iris.appearance.theme.glow", kind: "range", fallback: 0, min: 0, max: 100, step: 5, unit: " %" },
        { target: "colour", group: "Wallpaper tint", label: "Wallpaper tint", description: "How much wallpaper colour the black carries.", path: "iris.appearance.tint", kind: "range", fallback: 0, min: 0, max: 100, step: 5, unit: "%" },
        { target: "type", group: "Text", label: "Size", description: "Text across iRiS, on top of the system scale.", path: "iris.appearance.theme.text", kind: "range", fallback: 100, min: 85, max: 125, step: 5, unit: " %", keywords: ["text", "font", "font size", "type", "letters", "readable", "zoom", "texto", "letra", "fuente", "tamaño"] },
        { target: "type", group: "Text", label: "Weight", tune: true, description: "Every weight in iRiS one step lighter or firmer.", path: "iris.appearance.theme.weight", kind: "choice", fallback: "regular", choices: [{label:"Light",value:"light"},{label:"Regular",value:"regular"},{label:"Bold",value:"bold"}], keywords: ["font", "weight", "bold", "thin", "peso", "negrita"] },
        { target: "type", group: "Text", label: "Contrast", description: "Secondary and quiet text.", path: "iris.appearance.theme.contrast", kind: "range", fallback: 100, min: 60, max: 150, step: 5, unit: " %" },
        { target: "type", group: "Faces", label: "Pairing", description: "Sets the three faces below together.", kind: "choice", previewFont: true, bundle: ["iris.appearance.fontFamily", "iris.appearance.titleFontFamily", "iris.appearance.numbersFontFamily"], choices: root.pairings, keywords: ["font", "fonts", "typeface", "typography", "fuente", "tipografia", "letra"] },
        { target: "type", group: "Faces", label: "Text", tune: true, description: "Labels, rows and everything you read.", path: "iris.appearance.fontFamily", kind: "choice", installedFonts: true, previewFont: true, fallback: "", choices: [{label:"Geist",value:""},{label:"Inter",value:"Inter"},{label:"Noto Sans",value:"Noto Sans"},{label:"Montserrat",value:"Montserrat"},{label:"Rubik",value:"Rubik"},{label:"Readex Pro",value:"Readex Pro"},{label:"Roboto Flex",value:"Roboto Flex"},{label:"Gabarito",value:"Gabarito"},{label:"Space Grotesk",value:"Space Grotesk"},{label:"Oxanium",value:"Oxanium"},{label:"JetBrains Mono",value:"JetBrainsMono Nerd Font"}], keywords: ["font", "fonts", "typeface", "typography", "fuente", "tipografia", "letra"] },
        { target: "type", group: "Faces", label: "Titles", tune: true, description: "Page titles and card heads.", path: "iris.appearance.titleFontFamily", kind: "choice", installedFonts: true, previewFont: true, fallback: "", choices: [{label:"Geist",value:""},{label:"Inter Display",value:"Inter Display"},{label:"Noto Sans",value:"Noto Sans"},{label:"Montserrat",value:"Montserrat"},{label:"Rubik",value:"Rubik"},{label:"Readex Pro",value:"Readex Pro"},{label:"Roboto Flex",value:"Roboto Flex"},{label:"Gabarito",value:"Gabarito"},{label:"Space Grotesk",value:"Space Grotesk"},{label:"Oxanium",value:"Oxanium"},{label:"JetBrains Mono",value:"JetBrainsMono Nerd Font"}], keywords: ["font", "fonts", "typeface", "typography", "fuente", "tipografia", "letra"] },
        { target: "type", group: "Faces", label: "Figures", tune: true, description: "Clocks, timers and levels.", path: "iris.appearance.numbersFontFamily", kind: "choice", installedFonts: true, previewFont: true, fallback: "", choices: [{label:"Archivo",value:""},{label:"Rubik",value:"Rubik"},{label:"Inter",value:"Inter"},{label:"Noto Sans",value:"Noto Sans"},{label:"Montserrat",value:"Montserrat"},{label:"Readex Pro",value:"Readex Pro"},{label:"Roboto Flex",value:"Roboto Flex"},{label:"Gabarito",value:"Gabarito"},{label:"Space Grotesk",value:"Space Grotesk"},{label:"Oxanium",value:"Oxanium"},{label:"JetBrains Mono",value:"JetBrainsMono Nerd Font"}], keywords: ["font", "fonts", "typeface", "typography", "fuente", "tipografia", "letra"] },
        { target: "type", group: "Faces", label: "Figure weight", tune: true, path: "iris.appearance.figureWeight", kind: "choice", fallback: "bold", choices: [{label:"Light",value:"light"},{label:"Regular",value:"regular"},{label:"Bold",value:"bold"}] },
        { target: "motion", group: "Motion", label: "Movement", description: "How every shape iRiS grows moves.", path: "iris.appearance.morph", kind: "choice", fallback: "direct", choices: [{label:"Direct",value:"direct",glyph:"north_east"},{label:"Liquid",value:"liquid",glyph:"water_drop"},{label:"Glide",value:"glide",glyph:"swipe_right_alt"},{label:"Snap",value:"snap",glyph:"bolt"},{label:"Elastic",value:"elastic",glyph:"airwave"}] },
        { target: "motion", group: "Curve", label: "Curve", visibleWhen: "iris.appearance.motion", description: "The path a Direct shape follows as it opens or adjusts.", path: "iris.appearance.theme.curve", kind: "choice", fallback: "expressive", choices: [{label:"Expressive",value:"expressive",glyph:"north_east",detail:"Leaves fast and lands softly."},{label:"Standard",value:"standard",glyph:"trending_up",detail:"Even all the way."},{label:"Gentle",value:"gentle",glyph:"moving",detail:"Eases in and out."},{label:"Swift",value:"swift",glyph:"bolt",detail:"Short and sharp."},{label:"Custom",value:"custom",glyph:"draw"}] },
        { target: "motion", group: "Curve", label: "Shape", visibleWhen: "iris.appearance.motion", description: "Drag the two handles.", path: "iris.appearance.theme.curvePoints", kind: "curve", fallback: [0.16, 1, 0.3, 1] },
        { target: "motion", group: "Timing", label: "Open and close", visibleWhen: "iris.appearance.motion", description: "How long a shape takes to grow out of what opened it and fold back.", path: "iris.appearance.theme.openTime", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Timing", label: "Adjusting", visibleWhen: "iris.appearance.motion", description: "How long an open shape takes to change size, like switching pages.", path: "iris.appearance.theme.moveTime", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Timing", label: "Content arrives", visibleWhen: "iris.appearance.motion", description: "Lower shows what is inside while the shape is still growing; higher waits until it has formed.", path: "iris.appearance.theme.contentTiming", kind: "range", fallback: 100, min: 30, max: 170, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Island", visibleWhen: "iris.appearance.motion", description: "Speed of this surface's morph.", path: "iris.appearance.surfaces.island.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Cards", visibleWhen: "iris.appearance.motion", path: "iris.appearance.surfaces.cards.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Control Center", visibleWhen: "iris.appearance.motion", path: "iris.appearance.surfaces.controlCenter.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Side panels", visibleWhen: "iris.appearance.motion", path: "iris.appearance.surfaces.panels.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Spotlight", visibleWhen: "iris.appearance.motion", path: "iris.appearance.surfaces.spotlight.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Orbit", visibleWhen: "iris.appearance.motion", path: "iris.appearance.surfaces.orbit.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Settings", visibleWhen: "iris.appearance.motion", path: "iris.appearance.surfaces.settings.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Menus", visibleWhen: "iris.appearance.motion", path: "iris.appearance.surfaces.menus.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Wallpaper gallery", visibleWhen: "iris.appearance.motion", path: "iris.appearance.surfaces.gallery.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Volume and song pill", visibleWhen: "iris.appearance.motion", path: "iris.appearance.surfaces.osd.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %", keywords: ["osd", "hud", "volume"] },
        { target: "motion", group: "Touch", label: "Press depth", description: "How far buttons, bubbles and the Island dip under a press.", path: "iris.appearance.theme.press", kind: "range", fallback: 100, min: 0, max: 200, step: 10, unit: " %" },
        { target: "motion", group: "Motion", label: "Duration", visibleWhen: "iris.appearance.motion", description: "How long a shape takes to grow out of what opened it.", path: "iris.appearance.motionDuration", kind: "range", fallback:220,min:100,max:400,step:10,unit:" ms" },
        { target: "motion", group: "Motion", label: "Bounce", visibleWhen: "iris.appearance.motion", description: "How far arrivals and moves pass their place before settling, as a share of the style's own. 0 never bounces; leaving never does.", path: "iris.appearance.theme.bounce", kind: "range", fallback: 100, min: 0, max: 200, step: 10, unit: " %" },
        { target: "island", group: "Design and modes", label: "The Design's face", description: "The Design you wear draws the resting Island. Turn it off to choose an Island design of your own.", showIf: () => !root.islandUpright() && IrisDesign.brings("islandFace").length > 0, path: "iris.bar.designFace", kind: "switch", fallback: true, keywords: ["design", "face", "island", "prism", "airisu", "own", "diseño", "isla", "cara"] },
        { target: "island", group: "Design and modes", label: "Island design", description: "How the resting Island shows the time.", showIf: () => !root.islandUpright() && IrisDesign.skin("islandFace").length === 0, path: "iris.bar.design", kind: "choice", cards: "island", fallback: "halo", choices: [{label:"Halo",value:"halo",glyph:"pill",detail:"The time; by day the Island's foot glows where the sun stands."},{label:"Ledger",value:"ledger",glyph:"article",detail:"The time, then what is next on your calendar."},{label:"Tiles",value:"tiles",glyph:"grid_view",detail:"The hour lit on its own tile, the minutes beside it."},{label:"Dial",value:"dial",glyph:"donut_large",detail:"A watch with real hands, the day beside it."},{label:"Marquee",value:"marquee",glyph:"view_stream",detail:"One fact of your day, a new one each minute."},{label:"Duo",value:"duo",glyph:"join_left",detail:"A window on the sky: the sun, the weather, tonight's moon."},{label:"Headline",value:"headline",glyph:"format_size",detail:"The time as a poster, tall and condensed, beside the place and the sky."},{label:"Rings",value:"rings",glyph:"radio_button_checked",detail:"Three rings: the day gone, the battery or the week, the month."},{label:"Aura",value:"aura",glyph:"looks",detail:"The Island ringed in the spectrum, the time inside."},{label:"Status",value:"status",glyph:"signal_cellular_alt",detail:"A status bar: the time, the connection and the battery, or on a desktop the weather."},{label:"Forecast",value:"forecast",glyph:"partly_cloudy_day",detail:"The time, then the next hours: each one's sky and temperature."},{label:"World",value:"world",glyph:"public",detail:"The time here and in another city, on a small watch lit by its daylight."},{label:"Comet",value:"comet",glyph:"motion_blur",detail:"A light runs round the rim; where its head stands counts the hour, the day or the battery."},{label:"Lumen",value:"lumen",glyph:"wb_twilight",detail:"The rim lit from below: the battery's colour and charge, or the hour's sky."},{label:"Glyph",value:"glyph",glyph:"flare",detail:"Lamps in the rim, as on a Nothing Phone: the battery along the foot, notifications and the next event up the sides."},{label:"Tide",value:"tide",glyph:"water",detail:"The Island holds water up to the battery's charge, the hour or the day; it rolls when the charger goes in."}], keywords: ["island", "design", "style", "look", "face", "diseño", "estilo"] },
        { target: "island", group: "Face", label: "Sunlight", description: "By day, the Island's foot glows where the sun stands.", path: "iris.bar.sunLight", kind: "switch", fallback: true, showIf: () => root.islandFace("halo"), keywords: ["sun", "light", "glow", "halo", "sol", "luz"] },
        { target: "island", group: "Face", label: "Looks ahead", description: "How far ahead it looks for the next event.", showIf: () => root.islandFace("ledger"), path: "iris.bar.faces.ledger.ahead", kind: "choice", fallback: 720, choices: [{label:"3 hours",value:180},{label:"12 hours",value:720},{label:"24 hours",value:1440}], keywords: ["agenda", "calendar", "event", "hours", "ledger"] },
        { target: "island", group: "Face", label: "Lit tile", description: "Which half wears the accent.", showIf: () => root.islandFace("tiles"), path: "iris.bar.faces.tiles.lit", kind: "choice", fallback: "hour", choices: [{label:"Hour",value:"hour"},{label:"Minutes",value:"minutes"},{label:"Both",value:"both"}], keywords: ["tiles", "pair", "accent", "hour", "minutes"] },
        { target: "island", group: "Face", label: "The day", description: "The day and its date beside the tiles.", showIf: () => root.islandFace("tiles"), path: "iris.bar.faces.tiles.day", kind: "switch", fallback: true, keywords: ["tiles", "date", "day"] },
        { target: "island", group: "Face", label: "Marks", description: "The ticks round the dial.", showIf: () => root.islandFace("dial"), path: "iris.bar.faces.dial.marks", kind: "choice", fallback: "hours", choices: [{label:"Every hour",value:"hours"},{label:"Quarters",value:"quarters"},{label:"None",value:"none"}], keywords: ["dial", "watch", "ticks", "marks", "hands"] },
        { target: "island", group: "Face", label: "Beside the dial", description: "What sits next to the watch.", showIf: () => root.islandFace("dial"), path: "iris.bar.faces.dial.beside", kind: "choice", fallback: "day", choices: [{label:"The day",value:"day"},{label:"The time",value:"time"},{label:"Nothing",value:"none"}], keywords: ["dial", "watch", "day", "time", "digital"] },
        { target: "island", group: "Face", label: "Next event", description: "What is next on your calendar, within three hours.", showIf: () => root.islandFace("marquee"), path: "iris.bar.faces.marquee.events", kind: "switch", fallback: true, keywords: ["marquee", "bulletin", "calendar", "event"] },
        { target: "island", group: "Face", label: "Weather", description: "The temperature and the sky.", showIf: () => root.islandFace("marquee"), path: "iris.bar.faces.marquee.weather", kind: "switch", fallback: true, keywords: ["marquee", "bulletin", "weather", "temperature"] },
        { target: "island", group: "Face", label: "Sunrise and sunset", description: "When the sun rises or sets next. The date always stays.", showIf: () => root.islandFace("marquee"), path: "iris.bar.faces.marquee.sun", kind: "switch", fallback: true, keywords: ["marquee", "bulletin", "sun", "sunrise", "sunset"] },
        { target: "island", group: "Face", label: "Temperature", description: "The temperature in the window's corner.", showIf: () => root.islandFace("duo"), path: "iris.bar.faces.duo.temperature", kind: "switch", fallback: true, keywords: ["duo", "window", "weather", "temperature"] },
        { target: "island", group: "Face", label: "Beside the time", description: "The place and the sky, or the day and the date.", showIf: () => root.islandFace("headline"), path: "iris.bar.faces.headline.beside", kind: "choice", fallback: "sky", choices: [{label:"The sky",value:"sky"},{label:"The date",value:"date"}], keywords: ["headline", "poster", "weather", "date"] },
        { target: "island", group: "Face", label: "Temperature", description: "The temperature at the end, in the clock's accent.", showIf: () => root.islandFace("headline"), visibleWhen: "!iris.bar.faces.headline.beside=date", path: "iris.bar.faces.headline.temperature", kind: "switch", fallback: true, keywords: ["headline", "poster", "temperature"] },
        { target: "island", group: "Face", label: "Outer ring", description: "The red one, round the outside.", showIf: () => root.islandFace("rings"), path: "iris.bar.faces.rings.outer", kind: "choice", fallback: "day", choices: root.ringCounts, keywords: ["rings", "activity", "day", "week", "month", "year", "battery"] },
        { target: "island", group: "Face", label: "Middle ring", description: "The green one. On a desktop the battery counts the week.", showIf: () => root.islandFace("rings"), path: "iris.bar.faces.rings.middle", kind: "choice", fallback: "battery", choices: root.ringCounts, keywords: ["rings", "activity", "battery", "week"] },
        { target: "island", group: "Face", label: "Inner ring", description: "The blue one, in the middle.", showIf: () => root.islandFace("rings"), path: "iris.bar.faces.rings.inner", kind: "choice", fallback: "month", choices: root.ringCounts, keywords: ["rings", "activity", "month", "year"] },
        { target: "island", group: "Face", label: "Colours", description: "The light round the Island.", showIf: () => root.islandFace("aura"), path: "iris.bar.faces.aura.colours", kind: "choice", fallback: "spectrum", choices: root.islandLights, keywords: ["aura", "ring", "colours", "colors", "gradient", "spectrum"] },
        { target: "island", group: "Face", label: "Turns under the pointer", description: "The colours go once round while the pointer is over the Island.", showIf: () => root.islandFace("aura"), path: "iris.bar.faces.aura.turns", kind: "switch", fallback: true, keywords: ["aura", "turn", "hover", "spin"] },
        { target: "island", group: "Face", label: "Counts", description: "What the comet's head marks, read clockwise from the top: a lap is an hour, a day or a full battery.", showIf: () => root.islandFace("comet"), path: "iris.bar.faces.comet.counts", kind: "choice", fallback: "hour", choices: [{label:"Hour",value:"hour",glyph:"schedule"},{label:"Day",value:"day",glyph:"today"},{label:"Battery",value:"battery",glyph:"battery_horiz_075"}], keywords: ["comet", "counts", "hour", "day", "battery", "progress"] },
        { target: "island", group: "Face", label: "Trail", description: "A tail fading behind the head, or the whole way gone lit from the top.", showIf: () => root.islandFace("comet"), path: "iris.bar.faces.comet.trail", kind: "choice", fallback: "tail", choices: [{label:"Tail",value:"tail",glyph:"motion_blur"},{label:"Track",value:"track",glyph:"line_curve"}], keywords: ["comet", "trail", "tail", "track", "progress"] },
        { target: "island", group: "Face", label: "Colours", description: "The light round the Island.", showIf: () => root.islandFace("comet"), path: "iris.bar.faces.comet.colours", kind: "choice", fallback: "spectrum", choices: root.islandLights, keywords: ["comet", "colours", "colors", "gradient"] },
        { target: "island", group: "Face", label: "Laps under the pointer", description: "The comet runs once round while the pointer is over the Island.", showIf: () => root.islandFace("comet") && Config.options?.iris?.bar?.faces?.comet?.trail !== "track", path: "iris.bar.faces.comet.laps", kind: "switch", fallback: true, keywords: ["comet", "lap", "hover"] },
        { target: "island", group: "Face", label: "Light", description: "What the light under the Island tells: the battery climbs the sides as it charges.", showIf: () => root.islandFace("lumen"), path: "iris.bar.faces.lumen.light", kind: "choice", fallback: "battery", choices: [{label:"Battery",value:"battery",glyph:"battery_charging_full"},{label:"Sky",value:"sky",glyph:"wb_twilight"}].concat(root.islandLights.filter(choice => choice.value !== "day")), keywords: ["lumen", "light", "battery", "sky", "glow"] },
        { target: "island", group: "Face", label: "Foot", description: "What the lamp along the foot counts: the battery's charge, or the hour gone.", showIf: () => root.islandFace("glyph"), path: "iris.bar.faces.glyph.foot", kind: "choice", fallback: "battery", choices: [{label:"Battery",value:"battery",glyph:"battery_5_bar"},{label:"Hour",value:"hour",glyph:"schedule"}], keywords: ["glyph", "foot", "battery", "hour", "lamp"] },
        { target: "island", group: "Face", label: "Notifications lamp", description: "The left side lights a third for each notification waiting, up to three.", showIf: () => root.islandFace("glyph"), path: "iris.bar.faces.glyph.notifications", kind: "switch", fallback: true, keywords: ["glyph", "notifications", "unread", "lamp"] },
        { target: "island", group: "Face", label: "Event lamp", description: "The right side fills over the last hour before an event and stays lit while it runs.", showIf: () => root.islandFace("glyph"), path: "iris.bar.faces.glyph.events", kind: "switch", fallback: true, keywords: ["glyph", "calendar", "event", "lamp"] },
        { target: "island", group: "Face", label: "Charge in figures", description: "While charging, the percentage beside the time.", showIf: () => root.islandFace("glyph"), path: "iris.bar.faces.glyph.figure", kind: "switch", fallback: true, keywords: ["glyph", "charging", "percent", "battery"] },
        { target: "island", group: "Face", label: "Water", description: "What the water stands at: the battery's charge, the hour gone or the day gone.", showIf: () => root.islandFace("tide"), path: "iris.bar.faces.tide.fill", kind: "choice", fallback: "battery", choices: [{label:"Battery",value:"battery",glyph:"battery_5_bar"},{label:"Hour",value:"hour",glyph:"schedule"},{label:"Day",value:"day",glyph:"wb_twilight"}], keywords: ["tide", "water", "battery", "hour", "day", "level", "agua"] },
        { target: "island", group: "Face", label: "Charge in figures", description: "While charging, the percentage beside the time.", showIf: () => root.islandFace("tide"), path: "iris.bar.faces.tide.figure", kind: "switch", fallback: true, keywords: ["tide", "charging", "percent", "battery"] },
        { target: "island", group: "Face", label: "Light at the foot", description: "A little of the light pooled inside the Island, under the time.", showIf: () => root.islandFace("lumen"), path: "iris.bar.faces.lumen.pool", kind: "switch", fallback: true, keywords: ["lumen", "pool", "glow", "foot"] },
        { target: "island", group: "Face", label: "Capsule", description: "What the capsule at the end carries. Auto takes the battery, else a headset's charge, else the weather, else the day.", showIf: () => root.islandFace("status"), path: "iris.bar.faces.status.carry", kind: "choice", fallback: "auto", choices: [{label:"Auto",value:"auto"},{label:"Battery",value:"battery"},{label:"Headset",value:"headset"},{label:"Weather",value:"sky"},{label:"Day",value:"day"}], keywords: ["status", "battery", "headset", "weather", "capsule"] },
        { target: "island", group: "Face", label: "Connection", description: "A cable, Wi-Fi's bars, or none.", showIf: () => root.islandFace("status"), path: "iris.bar.faces.status.connection", kind: "switch", fallback: true, keywords: ["status", "wifi", "network", "ethernet"] },
        { target: "island", group: "Face", label: "Sound off", description: "A red mark while the sound is muted.", showIf: () => root.islandFace("status"), path: "iris.bar.faces.status.sound", kind: "switch", fallback: true, keywords: ["status", "mute", "sound", "volume"] },
        { target: "island", group: "Face", label: "Hours", description: "How many hours the strip shows, now included. A narrow Island shows fewer.", showIf: () => root.islandFace("forecast"), path: "iris.bar.faces.forecast.hours", kind: "choice", fallback: 3, choices: [{label:"2 hours",value:2},{label:"3 hours",value:3},{label:"4 hours",value:4}], keywords: ["forecast", "weather", "hours", "hourly"] },
        { target: "island", group: "Face", label: "Hour names", description: "Each hour's name over its sky.", showIf: () => root.islandFace("forecast"), path: "iris.bar.faces.forecast.labels", kind: "switch", fallback: true, keywords: ["forecast", "weather", "labels", "hours"] },
        { target: "island", group: "Face", label: "Sky in colour", description: "The sun in yellow, rain in blue. Off, every sky is grey.", showIf: () => root.islandFace("forecast"), path: "iris.bar.faces.forecast.colour", kind: "switch", fallback: true, keywords: ["forecast", "weather", "colour", "color", "icons"] },
        { target: "island", group: "Face", label: "City", description: "Whose time sits beside yours.", showIf: () => root.islandFace("world"), path: "iris.bar.faces.world.zone", kind: "choice", fallback: "Asia/Tokyo", choices: IrisFaceData.cities, keywords: ["world", "clock", "city", "timezone", "zone", "ciudad"] },
        { target: "island", group: "Face", label: "Second city", description: "Another city after the first.", showIf: () => root.islandFace("world"), path: "iris.bar.faces.world.second", kind: "choice", fallback: "none", choices: [{label:"None",value:"none"}].concat(IrisFaceData.cities), keywords: ["world", "clock", "city", "timezone", "second"] },
        { target: "island", group: "Face", label: "Time apart", description: "How many hours ahead or behind each city is. Two cities on a slim Island leave it out.", showIf: () => root.islandFace("world"), path: "iris.bar.faces.world.apart", kind: "switch", fallback: true, keywords: ["world", "clock", "offset", "difference", "hours"] },
        { target: "island", group: "Face", label: "Watch", description: "A small watch for each city, lit by day and dim by night.", showIf: () => root.islandFace("world"), path: "iris.bar.faces.world.watch", kind: "switch", fallback: true, keywords: ["world", "clock", "watch", "dial", "analog"] },
        { target: "island", group: "Design and modes", label: "Island layout", description: "Where the Island sits on its edge.", path: "iris.bar.layout", kind: "choice", fallback: "island", choices: [{label:"Island",value:"island",glyph:"pill",detail:"Hugs its content in the middle of the edge."},{label:"Corner left",value:"left",glyph:"north_west",detail:"Docked in the left corner, melted into both walls."},{label:"Corner right",value:"right",glyph:"north_east",detail:"Docked in the right corner, melted into both walls."},{label:"Shelf",value:"full",glyph:"width_full",detail:"A shelf across the whole edge, the Island rising from it."},{label:"Pods",value:"pods",glyph:"more_horiz",detail:"Three bodies on one line that melt where they meet."},{label:"Menu bar",value:"menubar",glyph:"toolbar",detail:"A thin menu bar with the Island hanging from it as a notch."}], keywords: ["menu bar", "notch", "macbook", "mac", "strip", "bar"] },
        { target: "island", group: "Layout", label: "Island rise", visibleWhen: "iris.bar.layout=full", showIf: () => !["left", "right"].includes(String(Config.options?.iris?.bar?.position ?? "top")), description: "How far the Island rises out of the shelf's middle; None keeps one straight edge.", path: "iris.bar.rise", kind: "choice", fallback: "deep", choices: [{label:"None",value:"none",glyph:"horizontal_rule"},{label:"Low",value:"low",glyph:"expand_more"},{label:"Deep",value:"deep",glyph:"keyboard_double_arrow_down"}], keywords: ["rise", "notch", "swell", "shelf", "bar", "heart", "depth"] },
        { target: "island", group: "Layout", label: "Screen edge", path: "iris.bar.position", kind: "choice", fallback: "top", choices: [{label:"Top",value:"top",glyph:"vertical_align_top"},{label:"Bottom",value:"bottom",glyph:"vertical_align_bottom"},{label:"Left",value:"left",glyph:"align_horizontal_left"},{label:"Right",value:"right",glyph:"align_horizontal_right"}] },
        { target: "island", group: "Layout", label: "Size", description: "The Island's height, clock size and breathing room, set together.", kind: "choice",
            bundle: ["iris.bar.height", "iris.bar.clockScale", "iris.bar.padding"],
            choices: [{label:"Compact",value:"compact",glyph:"density_small",values:[34, 90, 80]},{label:"Regular",value:"regular",glyph:"density_medium",values:[42, 100, 100]},{label:"Large",value:"large",glyph:"density_large",values:[50, 115, 120]}],
            keywords: ["size", "small", "big", "large", "compact", "scale", "tamaño", "grande", "chico"] },
        { target: "island", group: "Layout", label: "Height", description: "The resting Island, and how deep its notch melts into the edge.", path: "iris.bar.height", kind: "range", fallback: 42, min: 32, max: 64, unit: " px" },
        { target: "island", group: "Layout", label: "Gap from the edge", visibleWhen: "!iris.bar.notch", path: "iris.bar.margin", kind: "range", fallback:8,min:0,max:24,unit:" px" },
        { target: "island", group: "Layout", label: "Menu bar strip", visibleWhen: "iris.bar.layout=menubar", description: "Transparent leaves your items on the wallpaper, like macOS; Band lays a bar under them.", path: "iris.bar.strip", kind: "choice", fallback: "clear", choices: [{label:"Transparent",value:"clear",glyph:"blur_off"},{label:"Band",value:"band",glyph:"toolbar"}], keywords: ["transparent", "clear", "macos", "tahoe", "menu bar", "strip", "band", "background"] },
        { target: "island", group: "Shape", label: "One shape for all", description: "The Island, the Dock and the bubbles share the bubbles' shape.", path: "iris.appearance.theme.linkShapes", kind: "switch", fallback: false, keywords: ["same", "match", "link", "linked", "together", "sync", "unify", "everything", "one shape", "mismo", "igual", "todo", "juntos", "vincular"] },
        { target: "island", group: "Shape", label: "Island shape", visibleWhen: "!iris.appearance.theme.linkShapes", description: "Auto keeps the iRiS capsule.", path: "iris.bar.shape", kind: "choice", fallback: "auto", choices: [{label:"Auto",value:"auto",glyph:"auto_awesome"},{label:"Round",value:"round",glyph:"circle"},{label:"Squircle",value:"squircle",glyph:"rounded_corner"},{label:"Square",value:"square",glyph:"square"}], keywords: ["square", "squared", "boxy", "rectangle", "sharp", "round", "rounded", "capsule", "pill", "circle", "squircle", "corners", "radius", "curves", "cuadrado", "cuadrada", "redondo", "redonda", "esquinas", "curvas", "forma"] },
        { target: "island", group: "Shape", label: "All shapes", mirror: true, visibleWhen: "iris.appearance.theme.linkShapes", path: "iris.appearance.theme.pieceShape", kind: "choice", fallback: "circle", choices: [{label:"Circle",value:"circle",glyph:"circle"},{label:"Squircle",value:"squircle",glyph:"rounded_corner"},{label:"Square",value:"square",glyph:"square"}], keywords: ["square", "squared", "boxy", "rectangle", "sharp", "round", "rounded", "circle", "squircle", "corners", "radius", "curves", "cuadrado", "cuadrada", "redondo", "redonda", "esquinas", "curvas", "forma"] },
        { target: "island", group: "Notch", label: "Notch", description: "The Island melts into the screen edge, like the notch it grows from.", path: "iris.bar.notch", kind: "switch", fallback: true, keywords: ["notch", "attach", "melt", "edge", "dynamic island", "float", "floating", "muesca"] },
        { target: "island", group: "Shape", label: "Notch curve", visibleWhen: "iris.bar.notch", description: "How wide the shoulders are where the Island turns into its edge.", path: "iris.bar.notchCurve", kind: "range", fallback: 100, min: 20, max: 200, step: 5, unit: " %" },
        { target: "island", group: "Shape", label: "Open corners", description: "Auto follows the Island's shape; a size here overrides it.", path: "iris.appearance.surfaces.island.radius", kind: "range", fallback: 0, min: 0, max: 44, unit: " px", zeroLabel: "Auto", keywords: ["corners", "radius", "round", "expanded", "open"] },
        { target: "island", group: "At rest", label: "Clock", description: "What the resting Island shows beside the time.", showIf: () => root.islandEngineDraws("Face.qml"), path: "iris.bar.clockStyle", kind: "choice", fallback: "dateTime", choices: [{label:"Time",value:"time"},{label:"Date",value:"dateTime"},{label:"Weather",value:"weather"}] },
        { target: "island", group: "At rest", label: "Utility island", tune: true, showIf: () => !root.islandZoned(), description: "Emerges beside the Island; the tray hides when no apps are present.", path: "iris.bar.auxiliary", kind: "choice", fallback: "tray", choices: [{label:"Tray",value:"tray"},{label:"Timers",value:"tools"},{label:"Sound",value:"sound"},{label:"Microphone",value:"mic"},{label:"None",value:"none"}] },
        { target: "island", group: "At rest", label: "Clock size", description: "The time and date on the resting Island.", path: "iris.bar.clockScale", kind: "range", fallback: 100, min: 80, max: 150, step: 5, unit: " %" },
        { target: "island", group: "At rest", label: "Clock accent", description: "The colour of the time's separator and the day number on the resting Island.", path: "iris.bar.clockAccent", kind: "choice", tune: true, fallback: "highlight", choices: [{label:"Highlight",value:"highlight",get swatch() { return IrisStyle.secondaryAccent }},{label:"Accent",value:"accent",get swatch() { return IrisStyle.accent }},{label:"Plain",value:"plain",get swatch() { return IrisStyle.text }}] },
        { target: "island", group: "At rest", label: "Breathing room", description: "Space around what the resting Island shows.", path: "iris.bar.padding", kind: "range", fallback: 100, min: 50, max: 250, step: 10, unit: " %" },
        { target: "island", group: "At rest", label: "Bubble gap", showIf: () => !root.islandZoned(), description: "How far the bubbles beside the Island rest from it.", path: "iris.bar.satelliteGap", kind: "range", fallback: 6, min: 0, max: 24, unit: " px" },
        { target: "island", group: "At rest", label: "Bubble size", showIf: () => !root.islandZoned(), description: "The bubbles beside the Island, as a share of its height.", path: "iris.bar.satelliteScale", kind: "range", fallback: 100, min: 70, max: 100, step: 5, unit: " %" },
        { target: "island", group: "Desktop page", label: "Header", showIf: () => root.islandEngineDraws("Desktop.qml"), tune: true, description: "What sits behind the time when the Island shows your desktop.", path: "iris.bar.desktopBanner", kind: "choice", fallback: "wallpaper", choices: [{label:"Wallpaper",value:"wallpaper"},{label:"None",value:"none"}] },
        { target: "island", group: "Desktop page", label: "Header fade", showIf: () => root.islandEngineDraws("Desktop.qml"), description: "How far the wallpaper melts into the Island under the time.", path: "iris.bar.desktopBannerFade", visibleWhen: "iris.bar.desktopBanner=wallpaper", kind: "range", fallback: 100, min: 0, max: 100, step: 5, unit: " %", keywords: ["header", "banner", "gradient", "fade", "transparency", "wallpaper", "hero", "degradado"] },
        { target: "island", group: "Desktop page", label: "Header top", showIf: () => root.islandEngineDraws("Desktop.qml"), description: "How the wallpaper melts into the Island at the top, under its buttons.", path: "iris.bar.desktopBannerTop", visibleWhen: "iris.bar.desktopBanner=wallpaper", kind: "range", fallback: 100, min: 0, max: 100, step: 5, unit: " %", keywords: ["header", "banner", "top", "gradient", "fade", "transparency", "wallpaper", "hero", "degradado"] },
        { target: "island", group: "Desktop page", label: "Header veil", showIf: () => root.islandEngineDraws("Desktop.qml"), description: "How much the wallpaper is dimmed behind the time.", path: "iris.bar.desktopBannerVeil", visibleWhen: "iris.bar.desktopBanner=wallpaper", kind: "range", fallback: 100, min: 0, max: 100, step: 5, unit: " %", keywords: ["header", "banner", "dim", "dark", "veil", "scrim", "contrast", "wallpaper"] },
        { target: "island", group: "Desktop page", label: "Header blur", showIf: () => root.islandEngineDraws("Desktop.qml"), description: "Softens the wallpaper behind the time.", path: "iris.bar.desktopBannerBlur", visibleWhen: "iris.bar.desktopBanner=wallpaper", kind: "range", fallback: 0, min: 0, max: 100, step: 5, unit: " %", keywords: ["header", "banner", "blur", "soft", "frost", "wallpaper"] },
        { target: "island", group: "Desktop page", label: "Blocks", showIf: () => root.islandEngineDraws("Desktop.qml"), tune: true, description: "What sits under the time, in the order you switch them on. You can also arrange them on the Island itself: open its desktop page and tap the pencil.", path: "iris.bar.desktopBlocks", kind: "pieces", fallback: ["profile", "context", "workspaces", "forecast", "agenda", "modules"], choices: [{label:"Profile",value:"profile"},{label:"Current app",value:"context"},{label:"Workspaces",value:"workspaces"},{label:"Forecast",value:"forecast"},{label:"Up next",value:"agenda"},{label:"Vitals",value:"vitals"},{label:"Modules",value:"modules"}] },
        { target: "island", group: "Desktop page", label: "Your modules", description: "Modules written with the iRiS SDK sit in the page's Modules block.", path: "iris.bar.rightModules", kind: "pieces", fallback: [], choicesFrom: "irisModules", showIf: () => (CustomWidgets.widgets ?? []).some(widget => String(widget.faces?.iris?.path ?? "").length > 0), keywords: ["sdk", "custom", "module", "plugin", "extension", "widget"] },
        { target: "island", group: "Desktop page", label: "Block style", showIf: () => root.islandEngineDraws("Desktop.qml"), description: "How the Island page's blocks sit.", path: "iris.bar.blockStyle", kind: "choice", tune: true, fallback: "plain", choices: [{label:"Plain",value:"plain",glyph:"view_agenda",detail:"Rows on the Island's black, like the rest of the page."},{label:"Grouped",value:"grouped",glyph:"splitscreen",detail:"The forecast and vitals strips on quiet plates."}] },
        { target: "island", group: "Pages", label: "Page width", description: "How wide the open Island is.", path: "iris.bar.pageWidth", kind: "range", fallback: 440, min: 360, max: 600, step: 10, unit: " px" },
        { target: "island", group: "Pages", label: "Navigation", tune: true, description: "What the open Island's navigation row offers, in the order you switch them on. Pages come first; scroll over the row, or swipe sideways anywhere on the open Island, to move between them.", path: "iris.bar.navItems", kind: "pieces", fallback: ["media", "activity", "desktop", "shelf", "weather", "calendar", "vitals", "tray", "tools", "focus", "today", "controls", "settings"], choices: [{label:"Now playing",value:"media"},{label:"Live activities",value:"activity"},{label:"Desktop",value:"desktop"},{label:"Shelf",value:"shelf"},{label:"Weather",value:"weather"},{label:"Calendar",value:"calendar"},{label:"Vitals",value:"vitals"},{label:"Tray",value:"tray"},{label:"Timers",value:"tools"},{label:"Focus panel",value:"focus"},{label:"Today panel",value:"today"},{label:"Quick controls",value:"controls"},{label:"Settings",value:"settings"}] },
        { target: "island", group: "Pages", label: "Page buttons", showIf: () => root.islandEngineDraws("Nav.qml"), description: "What holds the navigation row.", path: "iris.bar.navFrame", kind: "choice", tune: true, fallback: "auto", choices: [{label:"Auto",value:"auto",glyph:"auto_awesome"},{label:"None",value:"none",glyph:"block"},{label:"Veil",value:"veil",glyph:"gradient"},{label:"Glass",value:"glass",glyph:"blur_on"},{label:"Solid",value:"solid",glyph:"square"}], keywords: ["navigation", "buttons", "tabs", "frame", "plate", "capsule", "glass", "blur", "background", "marco"] },
        { target: "island", group: "Shelf", label: "Shelf", description: "A page on the open Island with what you copied, the screenshots you took and the files you dropped on it.", path: "shelf.enable", kind: "switch", fallback: true, keywords: ["clipboard", "history", "screenshots", "drop", "files", "paste", "copied"] },
        { target: "island", group: "Shelf", label: "Items kept", description: "How many it keeps besides the ones you pin.", path: "shelf.length", kind: "range", fallback: 24, min: 6, max: 96, step: 6, unit: "", showIf: () => Config.options?.shelf?.enable ?? true },
        { target: "island", group: "Shelf", label: "Copied pictures", tune: true, description: "Pictures you copy go on the shelf too.", path: "shelf.images", kind: "switch", fallback: true, showIf: () => Config.options?.shelf?.enable ?? true },
        { target: "island", group: "Shelf", label: "Clear on logout", tune: true, description: "What isn't pinned leaves when you log in again.", path: "shelf.clearOnLogout", kind: "switch", fallback: false, showIf: () => Config.options?.shelf?.enable ?? true },
        { target: "island", group: "Player page", label: "Blocks", tune: true, description: "What the player page shows, in the order you switch them on.", path: "iris.bar.mediaBlocks", kind: "pieces", fallback: ["player", "timeline", "transport", "players", "levels"], choices: [{label:"Now playing",value:"player"},{label:"Timeline",value:"timeline"},{label:"Controls",value:"transport"},{label:"Other players",value:"players"},{label:"App volume",value:"levels"}] },
        { target: "pieces", group: "Size", label: "Bubble size", description: "Bubbles off the Island, as a share of the Island's height.", path: "iris.bubbles.scale", kind: "range", fallback: 100, min: 60, max: 140, step: 5, unit: " %" },
        { target: "pieces", group: "Size", label: "One shape for all", mirror: true, description: "The Island, the Dock and the bubbles share the bubbles' shape.", path: "iris.appearance.theme.linkShapes", kind: "switch", fallback: false, keywords: ["same", "match", "link", "linked", "together", "sync", "unify", "everything", "one shape", "mismo", "igual", "todo", "juntos", "vincular"] },
        { target: "pieces", group: "Size", label: "Bubble shape", visibleWhen: "!iris.appearance.theme.linkShapes", description: "The profile of every bubble, bar and satellite.", keywords: ["square", "squared", "boxy", "rectangle", "sharp", "round", "rounded", "pill", "circle", "squircle", "corners", "radius", "curves", "cuadrado", "cuadrada", "redondo", "redonda", "esquinas", "curvas", "forma"], path: "iris.appearance.theme.pieceShape", kind: "choice", fallback: "circle", choices: [{label:"Circle",value:"circle",glyph:"circle"},{label:"Squircle",value:"squircle",glyph:"rounded_corner"},{label:"Square",value:"square",glyph:"square"}] },
        { target: "pieces", group: "Size", label: "All shapes", mirror: true, visibleWhen: "iris.appearance.theme.linkShapes", path: "iris.appearance.theme.pieceShape", kind: "choice", fallback: "circle", choices: [{label:"Circle",value:"circle",glyph:"circle"},{label:"Squircle",value:"squircle",glyph:"rounded_corner"},{label:"Square",value:"square",glyph:"square"}], keywords: ["square", "squared", "boxy", "rectangle", "sharp", "round", "rounded", "circle", "squircle", "corners", "radius", "curves", "cuadrado", "cuadrada", "redondo", "redonda", "esquinas", "curvas", "forma"] },
        { target: "pieces", group: "On the contour", label: "Group into a bar", description: "Bubbles resting in the same place share one plate and read as a small bar; off, each one floats as its own disc.", path: "iris.bubbles.cluster", kind: "switch", fallback: true },
        { target: "pieces", group: "On the contour", label: "Keep them on the frame", tune: true, description: "Bubbles in a corner or on an edge sit on the shell's own edge, where they read as a swelling of it, instead of floating over your windows.", path: "iris.bubbles.attach", kind: "switch", fallback: true },
        { target: "pieces", group: "On the contour", label: "Meet the edge", description: "Notch: they melt into the edge with the Island's curved shoulders.", path: "iris.bubbles.join", visibleWhen: "iris.bubbles.attach", kind: "choice", fallback: "notch", choices: [{label:"Notch",value:"notch"},{label:"Weld",value:"weld"},{label:"Gap",value:"gap"}] },
        { target: "pieces", group: "On the contour", label: "Grow from the corner", tune: true, visibleWhen: "iris.bubbles.attach", description: "Bubbles in a corner run out of the frame's curve as one contour, however far along the edge they reach.", path: "iris.bubbles.fromCorner", kind: "switch", fallback: true, keywords: ["corner", "contour", "curve", "rail", "esquina", "contorno"] },
        { target: "pieces", group: "On the contour", label: "Shoulders", description: "How deep the curve is where a bubble melts into the edge.", path: "iris.bubbles.notchCurve", visibleWhen: "iris.bubbles.join=notch", kind: "range", fallback: 100, min: 30, max: 200, step: 5, unit: " %" },
        { target: "pieces", group: "Opening bodies", label: "Join to opener", description: "When settled, let a card or Control Center become one silhouette with the bubble or Island that opened it.", path: "iris.appearance.surfaces.cards.joinOrigin", kind: "switch", fallback: false },
        { target: "bodies", group: "Cards", label: "Design", description: "A whole look for every card at once.", path: "iris.appearance.surfaces.cards.design", kind: "choice", fallback: "welded", choices: [{label:"Welded",value:"welded",glyph:"join_inner"},{label:"Floating",value:"floating",glyph:"filter_none"},{label:"Plain",value:"plain",glyph:"crop_square"},{label:"Vibrant",value:"vibrant",glyph:"auto_awesome"}] },
        { target: "bodies", group: "Cards", label: "Room around the content", description: "Auto follows the design.", path: "iris.appearance.surfaces.cards.pad", kind: "range", fallback: 0, min: 0, max: 160, step: 5, unit: " %", zeroLabel: "Auto" },
        { target: "bodies", group: "Cards", label: "Handle", tune: true, description: "A small bar on the edge facing its bubble or the Island.", path: "iris.appearance.surfaces.cards.grabber", kind: "choice", fallback: "auto", choices: [{label:"Auto",value:"auto"},{label:"Show",value:"on"},{label:"Hide",value:"off"}] },
        { target: "bodies", group: "Cards", label: "Corners", description: "Auto keeps the family's shape for cards.", path: "iris.appearance.surfaces.cards.radius", kind: "range", fallback: 0, min: 0, max: 44, unit: " px", zeroLabel: "Auto" },
        { target: "bodies", group: "Joining", label: "Opens", description: "Where a card or the Control Center grows from a bubble: away from the edge it sits on, or along it.", path: "iris.appearance.theme.placement", kind: "choice", fallback: "auto", choices: [{label:"Away from the edge",value:"auto",glyph:"open_in_new"},{label:"Along the edge",value:"along",glyph:"swap_vert"}] },
        { target: "bodies", group: "Joining", label: "Air", description: "The space between what opened and the bar or bubble it came from.", path: "iris.appearance.theme.air", kind: "range", fallback: 8, min: 0, max: 40, unit: " px" },
        { target: "bodies", group: "Joining", label: "Fusion", description: "How deeply bodies melt where they touch. 0 keeps joins crisp; the join to a bubble and the notch keep their own shape.", path: "iris.appearance.theme.melt", kind: "range", fallback: 0, min: 0, max: 200, step: 5, unit: " %" },
        { target: "bodies", group: "Cards", label: "Width", description: "Auto keeps the family's width.", path: "iris.appearance.surfaces.cards.width", kind: "range", fallback: 0, min: 0, max: 560, step: 10, unit: " px", zeroLabel: "Auto" },
        { target: "bodies", group: "Cards", label: "Stand off its piece", description: "How far a card rests from the bubble or Island that opened it.", path: "iris.appearance.surfaces.cards.gap", kind: "range", fallback: 0, min: 0, max: 40, unit: " px", zeroLabel: "Welded" },
        { target: "bodies", group: "Cards", label: "Light", tune: true, description: "Its own colour, the wallpaper's, or plain black.", path: "iris.appearance.surfaces.cards.light", kind: "choice", fallback: "inherit", choices: [{label:"Own",value:"inherit",glyph:"auto_awesome"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Off",value:"off",glyph:"light_off"}] },
        { target: "bodies", group: "Card contents", label: "Header", tune: true, description: "The glyph, name and figure at the top of the sound and microphone cards.", path: "iris.appearance.surfaces.cards.header", kind: "switch", fallback: true },
        { target: "bodies", group: "Card contents", label: "Devices", tune: true, description: "Pick the output or input right inside the card.", path: "iris.appearance.surfaces.cards.devices", kind: "switch", fallback: true },
        { target: "bodies", group: "Card contents", label: "App volumes", tune: true, description: "Each app's level under the sound card.", path: "iris.appearance.surfaces.cards.mixer", kind: "switch", fallback: true },
        { target: "bodies", group: "Control Center", label: "Corners", description: "Auto keeps the family's shape for the panel.", path: "iris.appearance.surfaces.controlCenter.radius", kind: "range", fallback: 0, min: 0, max: 44, unit: " px", zeroLabel: "Auto" },
        { target: "bodies", group: "Control Center", label: "Light", tune: true, description: "Its own colour, the wallpaper's, or plain black.", path: "iris.appearance.surfaces.controlCenter.light", kind: "choice", fallback: "inherit", choices: [{label:"Own",value:"inherit",glyph:"auto_awesome"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Off",value:"off",glyph:"light_off"}] },
        { target: "bodies", group: "Control Center", label: "What it carries", description: "Every control the panel holds.", path: "iris.controlCenter.modules", kind: "list", view: Qt.resolvedUrl("IrisOrderedPieces.qml"), current: () => IrisControlOptions.modules, groups: IrisControlOptions.categories, fallback: ["platter", "media", "darkMode", "nightLight", "levels", "idle", "snip", "devices", "record", "notifications"], choices: IrisControlOptions.choicesFor(IrisControlOptions.catalogueIds), summary: () => String(IrisControlOptions.modules.length) },
        { target: "bodies", group: "Control Center", label: "Columns", description: "How many controls fit across.", path: "iris.controlCenter.columns", kind: "range", fallback: 4, min: 3, max: 6, keywords: ["grid", "layout"] },
        { target: "bodies", group: "Control Center", label: "Names under the controls", tune: true, description: "Off shows a name in the header while you point at it.", path: "iris.controlCenter.labels", kind: "switch", fallback: true },
        { target: "bodies", group: "Control Center", label: "Control shape", tune: true, description: "Round draws each switch as a disc with its name under it; Tiles are rounded squares.", path: "iris.controlCenter.controls", kind: "choice", fallback: "tiles", choices: [{label:"Tiles",value:"tiles",glyph:"grid_view"},{label:"Round",value:"round",glyph:"radio_button_checked"}] },
        { target: "bodies", group: "Control Center", label: "Accent", tune: true, description: "What a switch lights up with.", path: "iris.controlCenter.accent", kind: "choice", fallback: "system", choices: [{label:"Accent",value:"system"},{label:"Colourful",value:"colourful"},{label:"Mono",value:"mono"}], keywords: ["colour", "color", "tint", "toggle"] },
        { target: "bodies", group: "Control Center", label: "Slider fill", tune: true, path: "iris.controlCenter.sliders", kind: "choice", fallback: "neutral", choices: [{label:"Neutral",value:"neutral"},{label:"Accent",value:"accent"}], keywords: ["brightness", "volume", "level"] },
        { target: "bodies", group: "Control Center", label: "Connections plate", tune: true, description: "Up to four round switches, in this order.", path: "iris.controlCenter.platter", kind: "list", view: Qt.resolvedUrl("IrisOrderedPieces.qml"), current: () => IrisControlOptions.platterIds, limit: 4, groups: IrisControlOptions.categories, fallback: ["network", "bluetooth", "focus", "gameMode"], choices: IrisControlOptions.choicesFor(["network", "bluetooth", "vpn", "hotspot", "warp", "focus", "gameMode", "profiles", "idle", "darkMode", "nightLight", "audio", "mic"]), summary: () => String(IrisControlOptions.platterIds.length), keywords: ["wifi", "bluetooth", "platter"] },
        { target: "bodies", group: "Control Center", label: "Levels", tune: true, description: "Which sliders stand side by side in Levels.", path: "iris.controlCenter.levels", kind: "list", view: Qt.resolvedUrl("IrisOrderedPieces.qml"), current: () => IrisControlOptions.levelIds, fallback: ["brightness", "volume", "microphone"], choices: IrisControlOptions.choicesFor(IrisControlOptions.levelKinds), summary: () => String(IrisControlOptions.levelIds.length), keywords: ["slider", "brightness", "volume", "mic"] },
        { target: "bodies", group: "Control Center", label: "Opens as", description: "The Island itself becomes the Control Center, or a panel hangs from it.", path: "iris.controlCenter.opens", kind: "choice", fallback: "island", choices: [{label:"The Island",value:"island",glyph:"pill"},{label:"A panel",value:"panel",glyph:"web_asset"}] },
        { target: "bodies", group: "Control Center", label: "Width", path: "iris.controlCenter.width", kind: "range", fallback:360,min:320,max:540,step:10,unit:" px" },
        { target: "bodies", group: "Visualizer", label: "Visualizer", description: "How what plays is drawn on the resting Island, its player page and the Visualizer bubble.", path: "iris.player.visualizer.style", kind: "choice", fallback: "capsules",
            choices: [{label:"Capsules",value:"capsules",glyph:"graphic_eq"},{label:"Equalizer",value:"rise",glyph:"equalizer"},{label:"Dots",value:"dots",glyph:"more_horiz"},{label:"Wave",value:"wave",glyph:"airwave"},{label:"Ring",value:"ring",glyph:"brightness_empty"}],
            keywords: ["visualizer", "visualiser", "cava", "spectrum", "equalizer", "ecualizador", "bars", "barras", "wave", "onda", "dots", "puntos", "ring", "anillo"] },
        { target: "bodies", group: "Visualizer", label: "Bands", description: "How many parts of the sound it follows.", path: "iris.player.visualizer.bars", kind: "range", fallback: 5, min: 3, max: 9, step: 1 },
        { target: "bodies", group: "Visualizer", label: "Visualizer colour", description: "The artwork's own colour, the accent, the highlight or the ink.", path: "iris.player.visualizer.colour", kind: "choice", fallback: "art",
            choices: [{label:"Artwork",value:"art"},{label:"Accent",value:"accent"},{label:"Highlight",value:"highlight"},{label:"Ink",value:"ink"}] },
        { target: "bodies", group: "Player", label: "Round album cover", path: "iris.player.roundCover", kind: "switch", fallback: false },
        { target: "bodies", group: "Player", label: "Blurred album background", description: "Tints the expanded Island and media cards with the cover.", path: "iris.player.artworkBackground", kind: "switch", fallback:true },
        { target: "places", group: "Panel look", label: "Corners", description: "Auto keeps the family's shape for side panels.", path: "iris.appearance.surfaces.panels.radius", kind: "range", fallback: 0, min: 0, max: 44, unit: " px", zeroLabel: "Auto" },
        { target: "places", group: "Panel look", label: "Light", description: "Its own colour, the wallpaper's, or plain black.", path: "iris.appearance.surfaces.panels.light", kind: "choice", fallback: "inherit", choices: [{label:"Own",value:"inherit",glyph:"auto_awesome"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Off",value:"off",glyph:"light_off"}] },
        { target: "places", group: "Spotlight", label: "Corners", description: "Auto keeps the family's shape for Spotlight.", path: "iris.appearance.surfaces.spotlight.radius", kind: "range", fallback: 0, min: 0, max: 44, unit: " px", zeroLabel: "Auto" },
        { target: "places", group: "Orbit", label: "Corners", description: "Auto keeps the family's shape for Orbit.", path: "iris.appearance.surfaces.orbit.radius", kind: "range", fallback: 0, min: 0, max: 44, unit: " px", zeroLabel: "Auto" },
        { target: "places", group: "Spotlight", label: "Light", tune: true, description: "Its own colour, the wallpaper's, or plain black.", path: "iris.appearance.surfaces.spotlight.light", kind: "choice", fallback: "inherit", choices: [{label:"Own",value:"inherit",glyph:"auto_awesome"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Off",value:"off",glyph:"light_off"}] },
        { target: "places", group: "Orbit", label: "Light", description: "Its own colour, the wallpaper's, or plain black.", path: "iris.appearance.surfaces.orbit.light", kind: "choice", fallback: "inherit", choices: [{label:"Own",value:"inherit",glyph:"auto_awesome"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Off",value:"off",glyph:"light_off"}] },
        { target: "places", group: "Spotlight", label: "Opens as", description: "Floating opens a sheet of its own; Island turns the Island into Spotlight.", path: "iris.palette.opens", kind: "choice", fallback: "floating", choices: [{label:"Floating",value:"floating",glyph:"web_asset"},{label:"The Island",value:"island",glyph:"pill"}] },
        { target: "places", group: "Spotlight", label: "Width", path: "iris.palette.width", kind: "range", fallback:640,min:420,max:900,step:10,unit:" px" },
        { target: "places", group: "Wallpaper gallery", showIf: () => root.ownGallery(), label: "Corners", description: "Auto keeps the family's shape for the gallery.", path: "iris.appearance.surfaces.gallery.radius", kind: "range", fallback: 0, min: 0, max: 44, unit: " px", zeroLabel: "Auto" },
        { target: "places", group: "Wallpaper gallery", showIf: () => root.ownGallery(), label: "Light", tune: true, description: "Its own colour, the wallpaper's, or plain black.", path: "iris.appearance.surfaces.gallery.light", kind: "choice", fallback: "inherit", choices: [{label:"Own",value:"inherit",glyph:"auto_awesome"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Off",value:"off",glyph:"light_off"}] },
        { target: "places", group: "Wallpaper gallery", showIf: () => root.ownGallery(), label: "Layout", tune: true, description: "How the picker lays out what you browse.", path: "iris.wallpaper.layout", kind: "choice", fallback: "reel", choices: [{label:"Reel",value:"reel",glyph:"view_carousel",detail:"Flicks through one at a time."},{label:"Mosaic",value:"mosaic",glyph:"dashboard",detail:"Lines the next ones up beside the one in front."},{label:"Browser",value:"browser",glyph:"grid_view",detail:"Folders, a grid and an inspector."}], keywords: ["gallery", "picker", "layout", "carousel", "grid", "bento", "browser", "reel", "mosaic"] },
        { target: "places", group: "Settings", label: "Corners", description: "Auto keeps the family's shape for Settings.", path: "iris.appearance.surfaces.settings.radius", kind: "range", fallback: 0, min: 0, max: 44, unit: " px", zeroLabel: "Auto" },
        { target: "places", group: "Settings", label: "Light", tune: true, description: "Its own colour, the wallpaper's, or plain black.", path: "iris.appearance.surfaces.settings.light", kind: "choice", fallback: "inherit", choices: [{label:"Own",value:"inherit",glyph:"auto_awesome"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Off",value:"off",glyph:"light_off"}] },
        { target: "places", group: "Menus", label: "Size", tune: true, description: "Compact rows fit more in less; Regular keeps them roomy.", path: "iris.appearance.surfaces.menus.density", kind: "choice", fallback: "compact", choices: [{label:"Compact",value:"compact",glyph:"density_small"},{label:"Regular",value:"regular",glyph:"density_medium"}], keywords: ["menu", "context menu", "right click", "tray", "size", "density", "small"] },
        { target: "places", group: "Menus", label: "Corners", description: "Auto keeps the family's shape for menus.", path: "iris.appearance.surfaces.menus.radius", kind: "range", fallback: 0, min: 0, max: 44, unit: " px", zeroLabel: "Auto" },
        { target: "places", group: "Menus", label: "Light", tune: true, description: "Its own colour, the wallpaper's, or plain black.", path: "iris.appearance.surfaces.menus.light", kind: "choice", fallback: "inherit", choices: [{label:"Own",value:"inherit",glyph:"auto_awesome"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Off",value:"off",glyph:"light_off"}] },
        { target: "transients", group: "Banners", label: "Width", path: "iris.notifications.width", visibleWhen: "iris.modules.notificationPopup", kind: "range", fallback: 380, min: 340, max: 560, step: 10, unit: " px" },
        { target: "transients", group: "Feedback", label: "Level style", tune: true, description: "How a level shows in its pill.", path: "iris.osd.style", visibleWhen: "iris.modules.osd", kind: "choice", fallback: "capsule", choices: [{label:"Capsule",value:"capsule",glyph:"toggle_on",detail:"Fills the whole pill like a slider."},{label:"Bar",value:"bar",glyph:"linear_scale",detail:"A slim line."},{label:"Minimal",value:"minimal",glyph:"progress_activity",detail:"A ring around the icon."}], keywords: ["osd", "hud", "volume", "brightness", "slider", "look", "apple"] },
        { target: "transients", group: "Feedback", label: "Show the percentage", tune: true, path: "iris.osd.figure", visibleWhen: "iris.modules.osd", kind: "switch", fallback: true, keywords: ["osd", "number", "value", "percent"] },
        { target: "transients", group: "Feedback", label: "Pill corners", description: "Auto keeps it a capsule.", path: "iris.appearance.surfaces.osd.radius", visibleWhen: "iris.modules.osd", kind: "range", fallback: 0, min: 0, max: 32, unit: " px", zeroLabel: "Auto", keywords: ["osd", "radius", "shape"] },
        { target: "transients", group: "Feedback", label: "Pill light", tune: true, description: "Own lights volume indigo, the mic orange and brightness in the highlight.", path: "iris.appearance.surfaces.osd.light", visibleWhen: "iris.modules.osd", kind: "choice", fallback: "inherit", choices: [{label:"Own",value:"inherit",glyph:"auto_awesome"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Off",value:"off",glyph:"light_off"}], keywords: ["osd", "colour", "color", "glow", "tint"] },
        { target: "transients", group: "Feedback", label: "OSD width", path: "iris.osd.width", visibleWhen: "iris.modules.osd", kind: "range", fallback: 320, min: 260, max: 520, step: 10, unit: " px" },
        { target: "transients", group: "Feedback", label: "OSD position", tune: true, description: "Where the level pill shows when the Island is not there to answer, like over a fullscreen game.", path: "iris.osd.position", visibleWhen: "iris.modules.osd", kind: "choice", fallback: "bottom", choices: [{label:"Bottom",value:"bottom",glyph:"vertical_align_bottom"},{label:"Top",value:"top",glyph:"vertical_align_top"}], keywords: ["osd", "volume", "pill", "edge", "place"] },
        { target: "transients", group: "Feedback", label: "Distance from the edge", path: "iris.osd.offset", visibleWhen: "iris.modules.osd", kind: "range", fallback: 18, min: 0, max: 240, step: 2, unit: " px", keywords: ["osd", "margin", "offset", "gap"] },
        { target: "transients", group: "Feedback", label: "Time on screen", description: "Songs and warnings stay a little longer so they can be read.", path: "iris.osd.duration", visibleWhen: "iris.modules.osd", kind: "range", fallback: 1500, min: 800, max: 5000, step: 100, unit: " ms", keywords: ["osd", "timeout", "duration", "hide"] },
        { target: "dock", group: "Look", label: "Screen edge", description: "Auto keeps the Dock on the edge opposite the Island.", showIf: () => !IrisFrame.rail, path: "iris.dock.position", kind: "choice", fallback: "auto", choices: root.dockEdgeChoices },
        { target: "dock", group: "Look", label: "One shape for all", tune: true, mirror: true, description: "The Island, the Dock and the bubbles share the bubbles' shape.", path: "iris.appearance.theme.linkShapes", kind: "switch", fallback: false, keywords: ["same", "match", "link", "linked", "together", "sync", "unify", "everything", "one shape", "mismo", "igual", "todo", "juntos", "vincular"] },
        { target: "dock", group: "Look", label: "All shapes", mirror: true, visibleWhen: "iris.appearance.theme.linkShapes", path: "iris.appearance.theme.pieceShape", kind: "choice", fallback: "circle", choices: [{label:"Circle",value:"circle",glyph:"circle"},{label:"Squircle",value:"squircle",glyph:"rounded_corner"},{label:"Square",value:"square",glyph:"square"}], keywords: ["square", "squared", "boxy", "rectangle", "sharp", "round", "rounded", "circle", "squircle", "corners", "radius", "curves", "cuadrado", "cuadrada", "redondo", "redonda", "esquinas", "curvas", "forma"] },
        { target: "dock", group: "Look", label: "Dock shape", visibleWhen: "!iris.appearance.theme.linkShapes", description: "Auto keeps the iRiS capsule.", showIf: () => !IrisFrame.rail, path: "iris.dock.shape", kind: "choice", fallback: "auto", choices: [{label:"Auto",value:"auto",glyph:"auto_awesome"},{label:"Round",value:"round",glyph:"circle"},{label:"Squircle",value:"squircle",glyph:"rounded_corner"},{label:"Square",value:"square",glyph:"square"}], keywords: ["square", "squared", "boxy", "rectangle", "sharp", "round", "rounded", "capsule", "pill", "circle", "squircle", "corners", "radius", "curves", "cuadrado", "cuadrada", "redondo", "redonda", "esquinas", "curvas", "forma"] },
        { target: "dock", group: "Look", label: "Dock notch", tune: true, description: "The Dock melts into its screen edge like the Island's notch.", showIf: () => !IrisFrame.rail, path: "iris.dock.notch", kind: "switch", fallback: true, keywords: ["notch", "attach", "melt", "edge", "float", "floating", "muesca"] },
        // A body welded to the frame is the frame's material (IrisField.glassOf): its own material shows while it floats.
        { target: "dock", group: "Look", label: "Material", description: "What this surface is made of.", path: "iris.dock.material", showIf: () => !(IrisFrame.framed && (Config.options?.iris?.dock?.notch ?? false)), kind: "choice", fallback: "inherit", choices: [{label:"iRiS",value:"inherit",detail:"Follows iRiS."},{label:"Solid",value:"solid",detail:"Stays solid."},{label:"Glass",value:"glass",detail:"Glass over the blurred wallpaper."},{label:"Blur (beta)",value:"blur",detail:"Real blur of the windows below (Niri 26.04+)."}] },
        { target: "dock", group: "Icons", label: "Icon size", showIf: () => !IrisFrame.rail, path: "iris.dock.iconSize", kind: "range", fallback:40,min:28,max:64,unit:" px" },
        { target: "dock", group: "Icons", label: "Magnify on hover", showIf: () => !IrisFrame.rail, path: "iris.dock.magnification", kind: "switch", fallback:false },
        { target: "dock", group: "Icons", label: "Magnification", visibleWhen: "iris.dock.magnification", description: "How large the icon under the pointer grows; its neighbours follow.", showIf: () => !IrisFrame.rail, path: "iris.dock.magnifySize", kind: "range", fallback: 150, min: 110, max: 200, step: 5, unit: " %" },
        { target: "dock", group: "Icons", label: "Applications button", tune: true, description: "Opens Spotlight from the start of the Dock.", path: "iris.dock.launcher", kind: "switch", fallback:true },
        { target: "desktop", group: "Widgets", label: "On the desktop", description: "Tap a widget to add it to this screen or take it away.", path: "background.widgets", kind: "widgets", keywords: ["stack", "stacks", "pages", "group", "carousel", "rotate", "smart stack", "layer", "combine"] },
        { target: "desktop", group: "Widgets", label: "Arrange the desktop", shelf: false, description: "Move, size and dress every widget on the desktop itself; the shelf has these same options.", kind: "action", button: "Arrange", run: () => { GlobalStates.settingsOverlayOpen = false; GlobalStates.setWidgetEditMode(true) }, keywords: ["edit", "move", "arrange", "layout", "place", "organize", "editar", "mover", "acomodar"] },
        { target: "desktop", group: "Widgets", label: "Desktops", shelf: false, description: "Ready-made desktops (Glance, Dashboard, Focus, Listening, Bare) and the ones you saved: wear one, Undo takes it back.", kind: "action", button: "Choose", run: () => { GlobalStates.desktopShelfPage = "presets"; GlobalStates.settingsOverlayOpen = false; GlobalStates.setWidgetEditMode(true) }, keywords: ["presets", "layouts", "desktops", "saved", "glance", "dashboard", "focus", "escritorios", "plantillas"] },
        { target: "desktop", group: "Widgets", label: "Design", quickName: "Widget design", description: "One look on every widget.", path: "iris.widgets.design", widgetDesign: true, kind: "choice", fallback: "iris", choices: [{label:"iRiS",value:"iris",glyph:"auto_awesome"},{label:"Prism",value:"prism",glyph:"flare",detail:"Each widget a folder of frosted glass with a lit flap."},{label:"Material",value:"material",glyph:"widgets"},{label:"iNstrument",value:"instrument",glyph:"avg_pace"},{label:"Readout",value:"readout",glyph:"view_agenda"}], keywords: ["global", "instrument", "readout", "prism", "folder", "refraction", "shared", "material", "widgets", "style", "look", "all widgets", "match", "tech", "gauges"] },
        { target: "desktop", group: "Widgets", label: "Widgets with a look of their own", description: "Some widgets were given a different design in their Look controls.", kind: "action", button: "Match", run: () => DesktopWidgetDesign.apply(DesktopWidgetDesign.current), showIf: () => DesktopWidgetDesign.exceptionCount > 0 && !IrisDesign.owns("iris.widgets.design"), keywords: ["match", "same", "coherent", "exceptions", "design"] },
        { target: "desktop", group: "Widgets", label: "Undo the last design change", description: "Brings back the design and each widget's own look from before you started changing it.", kind: "action", button: "Undo", run: () => DesktopWidgetDesign.undo(), showIf: () => DesktopWidgetDesign.canUndo && !IrisDesign.owns("iris.widgets.design"), keywords: ["undo", "revert", "restore", "back", "design"] },
        { target: "desktop", group: "Widgets", label: "Widget corners", description: "Individual widget overrides take priority.", path: "iris.widgets.radius", showIf: () => root.widgetFaces, kind: "range", fallback:22,min:0,max:40,unit:" px" },
        { target: "desktop", group: "Widgets", label: "Accents", tune: true, quickName: "Widget accents", description: "The three colours every widget draws its rings, bars and figures with.", path: "iris.widgets.tint", kind: "choice", fallback: "wallpaper", choices: [{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"iRiS",value:"system",glyph:"auto_awesome"},{label:"Spectrum",value:"spectrum",glyph:"palette"},{label:"Mono",value:"mono",glyph:"contrast"}], keywords: ["colour", "color", "accent", "palette", "tint", "hue", "widgets"] },
        { target: "desktop", group: "Widgets", label: "Accent strength", description: "Low keeps soft pastels; high makes accents saturated and bright.", path: "iris.widgets.vibrance", kind: "range", fallback: 85, min: 0, max: 100, step: 5, unit: " %", keywords: ["vibrance", "saturation", "strong", "vivid", "accent", "colour", "color"] },
        { target: "desktop", group: "Widgets", label: "Material", description: "What sits behind every widget.", path: "iris.widgets.material", set: next => DesktopWidgetLook.look.wearMaterial(String(next)), state: () => DesktopWidgetOptions.everyState("showBackground") === "false" ? "clear" : String(Config.options?.iris?.widgets?.material ?? "glass"), showIf: () => root.widgetFaces, kind: "choice", fallback: "glass", choices: [{label:"Glass",value:"glass",glyph:"blur_on",detail:"Frosts the wallpaper behind each widget."},{label:"Transparent",value:"clear",glyph:"select",detail:"Leaves it bare: nothing drawn behind the widget."},{label:"Solid",value:"solid",glyph:"square",detail:"The Island's material, opaque."},{label:"Tinted",value:"tinted",glyph:"format_color_fill",detail:"The Island's material with a touch of your accent."}] },
        { target: "desktop", group: "Widgets", label: "Glass blur", description: "How much the glass behind every widget frosts the wallpaper: low keeps it clear, high turns it to milk.", path: "iris.widgets.blur", showIf: () => root.widgetFaces && String(Config.options?.iris?.widgets?.material ?? "glass") === "glass", kind: "range", fallback: 100, min: 0, max: 100, step: 5, unit: " %", keywords: ["blur", "frost", "glass", "frosted", "desenfoque", "vidrio"] },
        { target: "desktop", group: "Widgets", label: "Shrink the desktop while editing", description: "Off, widgets are arranged on the full desktop, in place.", path: "background.widgets.editCard", kind: "switch", fallback: false, keywords: ["edit", "card", "arrange", "old"] },
        { target: "desktop", group: "Widgets", label: "Lume on every widget", tune: true, description: "Every widget reads as if the wallpaper under it were bright and busy: a deeper veil on glass and a stronger text shadow on widgets without a background.", path: "iris.widgets.legibleAlways", kind: "switch", fallback: false, keywords: ["lume", "legibility", "readable", "contrast", "veil", "shadow", "always", "force", "text"] },
        { target: "desktop", group: "Widgets", label: "On bright wallpapers", tune: true, description: "Where the wallpaper under a widget is light, it turns to frost with dark ink and deeper accents.", path: "iris.widgets.brightWallpapers", kind: "switch", fallback: false, keywords: ["bright", "white", "light", "legible", "readable", "contrast", "ink", "black", "dark text", "frost", "adaptive"] },
        { target: "desktop", group: "Widgets", label: "Titles and figures", tune: true, path: "iris.widgets.weight", showIf: () => root.widgetFaces, kind: "choice", fallback: "regular", choices: [{label:"Light",value:"light"},{label:"Regular",value:"regular"},{label:"Bold",value:"bold"}] },
        { target: "desktop", group: "Widgets", label: "Surface opacity", path: "iris.widgets.opacity", showIf: () => root.widgetFaces, description: "How much material a widget carries.", kind: "range", fallback:100,min:20,max:100,step:5,unit:" %" },
        { target: "desktop", group: "Widgets", label: "Outline", tune: true, description: "The line around each widget.", path: "iris.widgets.outline", showIf: () => DesktopWidgetDesign.current === "iris", kind: "choice", fallback: "auto", choices: [{label:"Auto",value:"auto",glyph:"auto_awesome"},{label:"Always",value:"always",glyph:"crop_square"},{label:"None",value:"none",glyph:"block"}], keywords: ["outline", "border", "frame", "rim", "hairline", "edge", "line", "stroke", "marco", "borde"] },
        { target: "desktop", group: "Widgets", label: "Widgets with their own material", description: "They chose a material or surface opacity in their Look controls, so the rows above don't reach them.", kind: "action", button: "Match", run: () => DesktopWidgetLook.look.matchSurfaces(), showIf: () => root.widgetFaces && DesktopWidgetLook.look.ownSurfaceCount > 0, keywords: ["match", "same", "material", "glass", "opacity", "own", "reset", "every widget"] },
        { target: "desktop", group: "Desktop menu", label: "Wallpaper at the top", description: "The right-click menu opens on your wallpaper: tap it for the gallery, or the round button for the next one.", path: "iris.desktopMenu.wallpaper", kind: "switch", fallback: true, keywords: ["right click", "context menu", "desktop menu", "wallpaper", "shuffle"] },
        { target: "desktop", group: "Desktop menu", label: "Actions", description: "What the right-click menu offers, in the order you switch them on. They group themselves: the desktop, tools, then the shell.", path: "iris.desktopMenu.items", kind: "pieces", fallback: ["widgets", "customize", "screenshot", "terminal", "settings", "restart"], choices: IrisDesktopActions.catalogue.map(entry => ({ label: entry.label, value: entry.id })), keywords: ["right click", "context menu", "desktop menu", "terminal", "screenshot", "files", "record", "colour picker", "restart"] },
        { target: "motion", group: "Style per surface", label: "Island", tune: true, description: "A surface can move in a style of its own.", path: "iris.appearance.surfaces.island.morph", visibleWhen: "iris.appearance.motion", kind: "choice", fallback: "", choices: [{label:"Family",value:""},{label:"Direct",value:"direct"},{label:"Liquid",value:"liquid"},{label:"Glide",value:"glide"},{label:"Snap",value:"snap"},{label:"Elastic",value:"elastic"},{label:"None",value:"instant"}], keywords: ["morph", "animation", "spring", "bounce", "instant", "no animation", "none"] },
        { target: "motion", group: "Style per surface", label: "Cards", tune: true, path: "iris.appearance.surfaces.cards.morph", visibleWhen: "iris.appearance.motion", kind: "choice", fallback: "", choices: [{label:"Family",value:""},{label:"Direct",value:"direct"},{label:"Liquid",value:"liquid"},{label:"Glide",value:"glide"},{label:"Snap",value:"snap"},{label:"Elastic",value:"elastic"},{label:"None",value:"instant"}], keywords: ["morph", "animation", "spring", "bounce", "instant", "no animation", "none"] },
        { target: "motion", group: "Style per surface", label: "Control Center", tune: true, path: "iris.appearance.surfaces.controlCenter.morph", visibleWhen: "iris.appearance.motion", kind: "choice", fallback: "", choices: [{label:"Family",value:""},{label:"Direct",value:"direct"},{label:"Liquid",value:"liquid"},{label:"Glide",value:"glide"},{label:"Snap",value:"snap"},{label:"Elastic",value:"elastic"},{label:"None",value:"instant"}], keywords: ["morph", "animation", "spring", "bounce", "instant", "no animation", "none"] },
        { target: "motion", group: "Style per surface", label: "Side panels", tune: true, path: "iris.appearance.surfaces.panels.morph", visibleWhen: "iris.appearance.motion", kind: "choice", fallback: "", choices: [{label:"Family",value:""},{label:"Direct",value:"direct"},{label:"Liquid",value:"liquid"},{label:"Glide",value:"glide"},{label:"Snap",value:"snap"},{label:"Elastic",value:"elastic"},{label:"None",value:"instant"}], keywords: ["morph", "animation", "spring", "bounce", "instant", "no animation", "none"] },
        { target: "motion", group: "Style per surface", label: "Spotlight", tune: true, path: "iris.appearance.surfaces.spotlight.morph", visibleWhen: "iris.appearance.motion", kind: "choice", fallback: "", choices: [{label:"Family",value:""},{label:"Direct",value:"direct"},{label:"Liquid",value:"liquid"},{label:"Glide",value:"glide"},{label:"Snap",value:"snap"},{label:"Elastic",value:"elastic"},{label:"None",value:"instant"}], keywords: ["morph", "animation", "spring", "bounce", "instant", "no animation", "none"] },
        { target: "motion", group: "Style per surface", label: "Orbit", tune: true, path: "iris.appearance.surfaces.orbit.morph", visibleWhen: "iris.appearance.motion", kind: "choice", fallback: "", choices: [{label:"Family",value:""},{label:"Direct",value:"direct"},{label:"Liquid",value:"liquid"},{label:"Glide",value:"glide"},{label:"Snap",value:"snap"},{label:"Elastic",value:"elastic"},{label:"None",value:"instant"}], keywords: ["morph", "animation", "spring", "bounce", "instant", "no animation", "none"] },
        { target: "motion", group: "Style per surface", label: "Settings", tune: true, path: "iris.appearance.surfaces.settings.morph", visibleWhen: "iris.appearance.motion", kind: "choice", fallback: "", choices: [{label:"Family",value:""},{label:"Direct",value:"direct"},{label:"Liquid",value:"liquid"},{label:"Glide",value:"glide"},{label:"Snap",value:"snap"},{label:"Elastic",value:"elastic"},{label:"None",value:"instant"}], keywords: ["morph", "animation", "spring", "bounce", "instant", "no animation", "none"] },
        { target: "motion", group: "Style per surface", label: "Menus", tune: true, path: "iris.appearance.surfaces.menus.morph", visibleWhen: "iris.appearance.motion", kind: "choice", fallback: "", choices: [{label:"Family",value:""},{label:"Direct",value:"direct"},{label:"Liquid",value:"liquid"},{label:"Glide",value:"glide"},{label:"Snap",value:"snap"},{label:"Elastic",value:"elastic"},{label:"None",value:"instant"}], keywords: ["morph", "animation", "spring", "bounce", "instant", "no animation", "none"] },
        { target: "motion", group: "Style per surface", label: "Wallpaper gallery", tune: true, path: "iris.appearance.surfaces.gallery.morph", visibleWhen: "iris.appearance.motion", kind: "choice", fallback: "", choices: [{label:"Family",value:""},{label:"Direct",value:"direct"},{label:"Liquid",value:"liquid"},{label:"Glide",value:"glide"},{label:"Snap",value:"snap"},{label:"Elastic",value:"elastic"},{label:"None",value:"instant"}], keywords: ["morph", "animation", "spring", "bounce", "instant", "no animation", "none"] },
        { target: "motion", group: "Style per surface", label: "Volume and song pill", tune: true, path: "iris.appearance.surfaces.osd.morph", visibleWhen: "iris.appearance.motion", kind: "choice", fallback: "", choices: [{label:"Family",value:""},{label:"Direct",value:"direct"},{label:"Liquid",value:"liquid"},{label:"Glide",value:"glide"},{label:"Snap",value:"snap"},{label:"Elastic",value:"elastic"},{label:"None",value:"instant"}], keywords: ["morph", "animation", "spring", "bounce", "instant", "no animation", "none"] },
        { target: "material", group: "Material per surface", label: "Cards", description: "Glass or solid for this surface alone.", path: "iris.appearance.surfaces.cards.material", kind: "choice", tune: true, fallback: "", choices: [{label:"Family",value:""},{label:"Solid",value:"solid",glyph:"crop_square"},{label:"Glass",value:"glass",glyph:"blur_on"}], keywords: ["glass", "solid", "blur", "material", "vidrio"] },
        { target: "material", group: "Material per surface", label: "Control Center", path: "iris.appearance.surfaces.controlCenter.material", visibleWhen: "iris.controlCenter.opens=panel", kind: "choice", tune: true, fallback: "", choices: [{label:"Family",value:""},{label:"Solid",value:"solid",glyph:"crop_square"},{label:"Glass",value:"glass",glyph:"blur_on"}], keywords: ["glass", "solid", "blur", "material", "vidrio"] },
        { target: "material", group: "Material per surface", label: "Side panels", path: "iris.appearance.surfaces.panels.material", showIf: () => !(IrisFrame.framed && (Config.options?.iris?.sidebars?.left?.notch ?? false) && (Config.options?.iris?.sidebars?.right?.notch ?? false)), kind: "choice", tune: true, fallback: "", choices: [{label:"Family",value:""},{label:"Solid",value:"solid",glyph:"crop_square"},{label:"Glass",value:"glass",glyph:"blur_on"}], keywords: ["glass", "solid", "blur", "material", "vidrio"] },
        { target: "material", group: "Material per surface", label: "Spotlight", path: "iris.appearance.surfaces.spotlight.material", kind: "choice", tune: true, fallback: "", choices: [{label:"Family",value:""},{label:"Solid",value:"solid",glyph:"crop_square"},{label:"Glass",value:"glass",glyph:"blur_on"}], keywords: ["glass", "solid", "blur", "material", "vidrio"] },
        { target: "material", group: "Material per surface", label: "Orbit", path: "iris.appearance.surfaces.orbit.material", kind: "choice", tune: true, fallback: "", choices: [{label:"Family",value:""},{label:"Solid",value:"solid",glyph:"crop_square"},{label:"Glass",value:"glass",glyph:"blur_on"}], keywords: ["glass", "solid", "blur", "material", "vidrio"] },
        { target: "material", group: "Material per surface", label: "Settings", path: "iris.appearance.surfaces.settings.material", kind: "choice", tune: true, fallback: "", choices: [{label:"Family",value:""},{label:"Solid",value:"solid",glyph:"crop_square"},{label:"Glass",value:"glass",glyph:"blur_on"}], keywords: ["glass", "solid", "blur", "material", "vidrio"] },
        { target: "material", group: "Material per surface", label: "Menus", path: "iris.appearance.surfaces.menus.material", kind: "choice", tune: true, fallback: "", choices: [{label:"Family",value:""},{label:"Solid",value:"solid",glyph:"crop_square"},{label:"Glass",value:"glass",glyph:"blur_on"}], keywords: ["glass", "solid", "blur", "material", "vidrio"] },
        { target: "material", group: "Material per surface", label: "Wallpaper gallery", path: "iris.appearance.surfaces.gallery.material", kind: "choice", tune: true, fallback: "", choices: [{label:"Family",value:""},{label:"Solid",value:"solid",glyph:"crop_square"},{label:"Glass",value:"glass",glyph:"blur_on"}], keywords: ["glass", "solid", "blur", "material", "vidrio"] },
        { target: "material", group: "Material per surface", label: "Volume and song pill", path: "iris.appearance.surfaces.osd.material", kind: "choice", tune: true, fallback: "", choices: [{label:"Family",value:""},{label:"Solid",value:"solid",glyph:"crop_square"},{label:"Glass",value:"glass",glyph:"blur_on"}], keywords: ["glass", "solid", "blur", "material", "vidrio"] }
    ]
    // Every surface's corners in one place, beside the family's: each row is the surface's own (same path, same range),
    // listed here as well because "how round is it" is asked of the look, not of a surface.
    readonly property var cornerLabels: ({ island: "Island", cards: "Cards", controlCenter: "Control Center", panels: "Side panels", spotlight: "Spotlight", orbit: "Orbit",
        settings: "Settings", gallery: "Wallpaper gallery", menus: "Menus", osd: "Volume and song pill" })
    readonly property var cornerMirrors: {
        const out = []
        for (const spec of root.studioRows) {
            const found = /^iris\.appearance\.surfaces\.(\w+)\.radius$/.exec(String(spec.path ?? ""))
            if (!found || !root.cornerLabels[found[1]]) continue
            const mirror = root.derive(spec, { target: "material", group: "Corners per surface", label: root.cornerLabels[found[1]], mirror: true,
                keywords: ["corners", "radius", "round", "rounded", "square"] })
            delete mirror.description
            out.push(mirror)
        }
        return out
    }
    readonly property var edgeKeys: ["edgeLight", "edgeLine", "rimWidth", "edgeColour"]
    readonly property var edgeMirrors: {
        const out = []
        for (const spec of root.studioRows) {
            const found = /^iris\.appearance\.(?:glass|theme)\.(\w+)$/.exec(String(spec.path ?? ""))
            if (!found || !root.edgeKeys.includes(found[1])) continue
            out.push(root.derive(spec, { target: "desktop", group: "Widgets", mirror: true,
                description: "The edge of glass widgets, the same as the Island's and the Dock's glass.",
                showIf: () => root.widgetGlass && String(Config.options?.iris?.widgets?.outline ?? "auto") !== "none",
                keywords: ["outline", "border", "frame", "edge", "line", "light", "rim", "marco", "borde", "widgets"] }))
        }
        return out
    }
    // A row copied with its getters kept. Object.assign read every getter (a Design's choices, its name) inside the
    // registry's own binding, so the registry rebuilt, and Prism remade each of its rows, whenever one of those values
    // moved: 3 s frozen on a Design switch. The getters now run where the row is drawn.
    function derive(base: var, extra: var): var {
        const out = {}
        for (const source of [base, extra]) {
            for (const key of Object.getOwnPropertyNames(source))
                Object.defineProperty(out, key, Object.assign(Object.getOwnPropertyDescriptor(source, key), { configurable: true, enumerable: true }))
        }
        return out
    }
    readonly property var studio: {
        const rows = root.studioRows.slice()
        const at = rows.map(spec => spec.target === "material" && spec.group === "Shape").lastIndexOf(true)
        rows.splice(at < 0 ? rows.length : at + 1, 0, ...root.cornerMirrors)
        const outline = rows.findIndex(spec => spec.path === "iris.widgets.outline")
        rows.splice(outline < 0 ? rows.length : outline + 1, 0, ...root.edgeMirrors)
        return rows.map((spec, index) => root.derive(spec, { modelKey: "studio:" + index }))
    }

    // Alternatives offered for a piece whose resting face is a glyph. The description
    // names what is drawn on screen, so searching for the glyph finds the control.
    readonly property var pieceIcons: ({
        awake: { description: "The face of the Stay awake bubble; it fills while the screen is kept on.",
            glyphs: ["coffee", "local_cafe", "emoji_food_beverage", "visibility", "light_mode", "bolt"] },
        nightLight: { description: "The face of the Night light bubble; it fills while the screen is warmed.",
            glyphs: ["nightlight", "bedtime", "dark_mode", "wb_twilight", "brightness_4", "local_fire_department"] },
        capture: { description: "The face of the Screenshot bubble.",
            glyphs: ["screenshot_region", "screenshot_monitor", "crop", "photo_camera", "center_focus_strong", "select"] },
        power: { description: "The face of the Power bubble.",
            glyphs: ["power_settings_new", "logout", "lock", "restart_alt", "mode_off_on", "settings_power"] },
        controls: { description: "The face of the bubble that opens the Control Center. It shows a wifi arc while Wi-Fi is on and a slider otherwise; pick a glyph here to keep one of your own instead.",
            glyphs: ["tune", "settings", "wifi", "toggle_on", "dashboard", "apps", "equalizer", "more_horiz"] },
        tools: { description: "The face of the Timers bubble while nothing is counting; a running timer always shows its ring and the minutes left.",
            glyphs: ["timer", "hourglass_empty", "alarm", "schedule", "av_timer", "timelapse"] },
        focus: { description: "The moon on the Do Not Disturb bubble.",
            glyphs: ["bedtime", "dark_mode", "nightlight", "do_not_disturb_on", "notifications_off", "self_improvement"] },
        notifications: { description: "The bell on the notifications bubble.",
            glyphs: ["notifications", "notifications_active", "campaign", "chat_bubble", "mark_email_unread", "inbox"] },
        bluetooth: { description: "The face of the Bluetooth bubble.",
            glyphs: ["bluetooth", "bluetooth_connected", "bluetooth_audio", "headphones", "devices", "cast"] },
        updates: { description: "The face of the Updates bubble while nothing is waiting; pending updates always show their count.",
            glyphs: ["task_alt", "system_update_alt", "deployed_code_update", "download", "package_2", "refresh"] },
        anime: { description: "The mark on the Airing bubble and its card.",
            glyphs: ["live_tv", "smart_display", "subscriptions", "theaters", "animation", "movie"] },
        watching: { description: "The mark on the Continue bubble and its card.",
            glyphs: ["resume", "play_circle", "not_started", "slow_motion_video", "video_library", "history"] }
    })

    readonly property var bubbleRows: {
        const rows = []
        for (const kind of IrisPieces.iconKinds) {
            const icon = root.pieceIcons[kind]
            rows.push({ section: "bubbles", group: "Icons", label: IrisPieces.labelOf(kind) + " icon",
                description: icon.description, piece: kind, glyphs: icon.glyphs,
                path: "iris.pieces.icons", kind: "icon", fallback: "", tune: true })
        }
        for (const piece of IrisPieces.slots)
            rows.push({ section: "bubbles", group: "Placement", label: piece.label, description: piece.description,
                piece: piece.id,
                path: IrisPieces.configPath(piece.id) + ".place", kind: "zone", fallback: "island",
                choices: IrisPieces.zoneChoices(true), tune: true })
        for (const piece of IrisPieces.extras) {
            if (IrisFrame.announcements.includes(piece.id)) continue
            const path = IrisPieces.configPath(piece.id)
            // The two anime pieces live with the rest of anime in Settings; every
            // other bubble stays under Bubbles. One switch, one place.
            const anime = piece.id === "anime" || piece.id === "watching"
            const section = anime ? "anime" : "bubbles"
            const group = anime ? (piece.id === "anime" ? "Airing" : "Continue") : "Extra bubbles"
            const hint = IrisPieces.dependencyHint(piece.id)
            rows.push({ section: section, group: group, label: piece.label,
                description: hint.length > 0 ? hint : piece.description,
                piece: piece.id, keywords: piece.keywords ?? [],
                // Under Bubbles the extras are a long list of switches: they wait behind the area's Fine-tune.
                path: path + ".enable", kind: "switch", fallback: false, tune: !anime })
            rows.push({ section: section, group: group, label: piece.label + " bubble rests",
                piece: piece.id,
                path: path + ".place", visibleWhen: path + ".enable", kind: "zone",
                fallback: IrisPieces.defaultPlace, choices: IrisPieces.zoneChoices(false), tune: !anime })
            if (piece.id === "workspaces") {
                rows.push({ section: "bubbles", group: "Workspaces", label: "Tap opens", description: "Open the Overview, or grow a workspace switcher from this bubble.", piece: piece.id,
                    path: path + ".opens", visibleWhen: path + ".enable", kind: "choice", fallback: "card",
                    choices: [{label:"Overview",value:"overview",glyph:"space_dashboard"},{label:"Workspace card",value:"card",glyph:"view_carousel"}] })
            }
        }
        return rows
    }

    // The glyph wallpaper's rows, drawn from the one list of its options (GlyphArt.js): what it shows, its look
    // (choosing one writes everything a look decides), then each option, the fine ones behind tuning.
    readonly property var glyphRows: {
        const base = "background.effects.glyphs."
        const on = () => Boolean(Config.options?.background?.effects?.glyphs?.enable)
        const row = spec => Object.assign({ section: "desktop", group: "Glyph art", showIf: on, restorable: true }, spec)
        const plain = ["cell", "motion", "intro"]
        return [
            row({ label: "Shows", path: base + "source", kind: "choice", fallback: "wallpaper",
                choices: [{ label: "Your wallpaper", value: "wallpaper", glyph: "image" }]
                    .concat(Glyphs.subjects()).concat([{ label: "A word", value: "word", glyph: "title" }]),
                keywords: ["demo", "iris", "planet", "word", "text"] }),
            row({ label: "Word", description: "A word, | for a new line", path: base + "word", visibleWhen: base + "source=word", kind: "text", fallback: "" }),
            row({ label: "Look", path: base + "look", kind: "choice", fallback: "signal", choices: Glyphs.lookNames(),
                set: look => Config.setNestedValues(Glyphs.lookWrites(base, String(look))),
                keywords: ["ascii", "glyph", "terminal", "matrix", "crt", "halftone", "newsprint", "typewriter", "colour", "color"] })
        ].concat(Glyphs.OPTIONS.map(spec => row({
            tune: plain.indexOf(spec.key) < 0,
            label: spec.label,
            path: base + spec.key,
            kind: spec.kind === "colour" ? "choice" : spec.kind,
            fallback: Glyphs.wallpaperFallback(spec),
            min: spec.min, max: spec.max, step: spec.step,
            unit: spec.unit ? " " + spec.unit : undefined,
            choices: spec.kind === "colour" ? Glyphs.INKS.map(ink => ({ label: ink[1], value: ink[0], colour: ink[0], swatch: ink[0] }))
                : spec.choices ? spec.choices.map(choice => ({ label: choice[1], value: choice[0] })) : undefined,
            visibleWhen: spec.when ? (spec.when[1] === true ? base + spec.when[0] : base + spec.when[0] + "=" + spec.when[1]) : undefined
        })))
    }

    readonly property var behaviour: [
        { section: "appearance", group: "Design", label: "Design", description: "What iRiS is made of: its shapes, type, controls and motion.", path: "iris.appearance.design", kind: "choice", cards: "design", fallback: "iris", get choices() { return IrisDesign.catalogue }, note: () => IrisDesign.refusesGlass ? Translation.tr("%1 is opaque by design: it wears no glass.").arg(IrisDesign.name) : "", keywords: ["design", "style", "airisu", "iris", "jdm", "japanese", "look", "skin", "diseño", "estilo"] },
        { section: "bar", group: "Design and modes", label: "Composition", description: "How the Island holds media and controls.", path: "iris.bar.composition", kind: "choice", fallback: "cluster", choices: [{label:"Unified",value:"unified",glyph:"crop_7_5",detail:"Unified keeps media and controls inside the one Island."},{label:"Cluster",value:"cluster",glyph:"bubble_chart",detail:"Cluster splits media and controls into bubbles beside the clock."}] },
        { section: "bar", group: "Visibility", label: "Automatically hide", description: "The Island tucks into its edge and comes back when you rest the pointer there.", path: "iris.bar.autoHide", kind: "switch", fallback: false },
        { section: "bar", group: "Visibility", label: "Stay visible on empty workspaces", description: "When auto-hide is on, keep the Island visible on workspaces with no windows.", path: "iris.bar.revealOnEmpty", visibleWhen: "iris.bar.autoHide", kind: "switch", fallback: true },
        { section: "bar", group: "Visibility", label: "Reserve space for windows", tune: true, description: "Bubbles on the same edge reserve their own room.", path: "iris.bar.reserveSpace", visibleWhen: "!iris.bar.autoHide", kind: "switch", fallback:true, keywords: ["reserve", "space", "windows", "exclusive", "margin", "espacio", "reservar"] },
        { section: "bar", group: "Live activities", label: "Screen recording", description: "How long it has run, with a red dot.", path: "iris.bar.activities.record", kind: "switch", fallback: true, keywords: ["recording", "record", "screen", "live activity", "dynamic island", "grabación"] },
        { section: "bar", group: "Live activities", label: "Timers", description: "A timer, a stopwatch or a focus session, with its ring.", path: "iris.bar.activities.timer", kind: "switch", fallback: true, keywords: ["timer", "pomodoro", "stopwatch", "focus", "temporizador"] },
        { section: "bar", group: "Live activities", label: "Downloads and tasks", description: "A job's progress as a ring.", path: "iris.bar.activities.task", kind: "switch", fallback: true, keywords: ["download", "task", "progress", "job", "descarga"] },
        { section: "bar", group: "Live activities", label: "Camera", description: "A green camera tile with the app while the camera is on. The privacy dot shows either way.", path: "iris.bar.activities.camera", kind: "switch", fallback: true, keywords: ["camera", "webcam", "privacy", "cámara"] },
        { section: "bar", group: "Live activities", label: "Calls", description: "While an app listens through the microphone: a green handset and how long it has run. The privacy dot shows either way.", path: "iris.bar.activities.call", kind: "switch", fallback: true, keywords: ["call", "microphone", "mic", "meeting", "llamada"] },
        { section: "bar", group: "Live activities", label: "Music", description: "The song takes the Island while it plays, or the bubble beside it.", path: "iris.bar.activities.media", kind: "switch", fallback: true, keywords: ["music", "song", "player", "media", "now playing", "música"] },
        { section: "bar", group: "Live activities", label: "Order", description: "When several run at once, the first takes the Island and the next waits in the bubble beside it.", path: "iris.bar.activities.order", kind: "list", view: Qt.resolvedUrl("IrisOrderedPieces.qml"), fixed: true,
            current: () => IrisStyle.islandActivityOrder(Config.options?.iris?.bar?.activities?.order), off: kind => Config.options?.iris?.bar?.activities?.[kind] === false,
            fallback: IrisStyle.islandActivityKinds, choices: [{label:"Screen recording",value:"record",glyph:"screen_record"},{label:"Timers",value:"timer",glyph:"timer"},{label:"Downloads and tasks",value:"task",glyph:"download"},{label:"Camera",value:"camera",glyph:"videocam"},{label:"Calls",value:"call",glyph:"call"},{label:"Music",value:"media",glyph:"music_note"}],
            summary: () => Translation.tr(({ record: "Screen recording", timer: "Timers", task: "Downloads and tasks", camera: "Camera", call: "Calls", media: "Music" })[IrisStyle.islandActivityOrder(Config.options?.iris?.bar?.activities?.order)[0]]),
            keywords: ["order", "priority", "first", "live activity", "dynamic island", "orden", "prioridad"] },
        { section: "bar", group: "Live activities", label: "Microphone glow", description: "The screen's edges glow for a moment when an app starts listening.", path: "iris.bar.activities.micGlow", kind: "switch", tune: true, fallback: false, keywords: ["glow", "microphone", "edges", "privacy", "brillo"] },
        { section: "bar", group: "Notices", label: "System events", description: "The Island says by itself what just happened, for a moment: a connection, a timer, a screenshot, Do Not Disturb.", path: "iris.bar.events", kind: "switch", fallback: true, keywords: ["events", "notices", "alerts", "toast", "popup", "osd", "dynamic island", "avisos"] },
        { section: "bar", group: "Notices", label: "Size", description: "How a notice shows in the Island.", path: "iris.bar.notices.style", visibleWhen: "iris.bar.events", kind: "choice", fallback: "compact", set: next => root.writeAndShow("iris.bar.notices.style", next, "accessory"),
            choices: [{label:"Compact",value:"compact",glyph:"short_text",detail:"A line in the resting Island."},{label:"Large",value:"large",glyph:"crop_landscape",detail:"The Island grows into a card, as a phone's alerts do. On a side edge it keeps the line."}],
            keywords: ["large", "big", "expanded", "card", "alert", "compact", "size", "grande", "tamaño"] },
        { section: "bar", group: "Notices", label: "Stays for", description: "How long a notice holds the Island.", path: "iris.bar.notices.seconds", visibleWhen: "iris.bar.events", kind: "range", fallback: 2.5, min: 1.5, max: 8, step: 0.5, unit: " s", set: next => root.writeAndShow("iris.bar.notices.seconds", next, "accessory"), keywords: ["duration", "time", "seconds", "long", "duración"] },
        { section: "bar", group: "Notices", label: "See one", description: "The Island shows a notice in the size and for the time chosen here.", kind: "action", button: "Show", visibleWhen: "iris.bar.events", run: () => root.showNextSample(), keywords: ["preview", "sample", "test", "try"] },
        { section: "bar", group: "Notices", label: "Unlocked", description: "A face drawn in green as the screen unlocks.", path: "iris.bar.notices.unlock", visibleWhen: "iris.bar.events", kind: "switch", tune: true, fallback: true, set: next => root.writeAndShow("iris.bar.notices.unlock", next, next ? "unlock" : ""), keywords: ["unlock", "face", "login"] },
        { section: "bar", group: "Notices", label: "Silent", description: "The sound muted from anywhere.", path: "iris.bar.notices.silent", visibleWhen: "iris.bar.events", kind: "switch", tune: true, fallback: true, set: next => root.writeAndShow("iris.bar.notices.silent", next, next ? "silent" : ""), keywords: ["mute", "muted", "silent", "sound"] },
        { section: "bar", group: "Notices", label: "Do not disturb", description: "Turned on or off.", path: "iris.bar.notices.focus", visibleWhen: "iris.bar.events", kind: "switch", tune: true, fallback: true, set: next => root.writeAndShow("iris.bar.notices.focus", next, next ? "focus" : ""), keywords: ["dnd", "do not disturb", "focus", "quiet"] },
        { section: "bar", group: "Notices", label: "Low battery", description: "When it runs low and nothing charges it.", path: "iris.bar.notices.battery", visibleWhen: "iris.bar.events", kind: "switch", tune: true, fallback: true, set: next => root.writeAndShow("iris.bar.notices.battery", next, next ? "battery" : ""), keywords: ["battery", "low", "charge"] },
        { section: "bar", group: "Notices", label: "Screenshots", description: "The picture itself; a tap opens it.", path: "iris.bar.notices.screenshot", visibleWhen: "iris.bar.events", kind: "switch", tune: true, fallback: true, set: next => root.writeAndShow("iris.bar.notices.screenshot", next, next ? "screenshot" : ""), keywords: ["screenshot", "capture", "picture"] },
        { section: "bar", group: "Notices", label: "Recordings", description: "A recording saved, with its length.", path: "iris.bar.notices.recording", visibleWhen: "iris.bar.events", kind: "switch", tune: true, fallback: true, set: next => root.writeAndShow("iris.bar.notices.recording", next, next ? "recording" : ""), keywords: ["recording", "screen record", "video"] },
        { section: "bar", group: "Notices", label: "Upcoming events", description: "A calendar event about to start, with a ring closing on it.", path: "iris.bar.notices.upcoming", visibleWhen: "iris.bar.events", kind: "switch", tune: true, fallback: true, set: next => root.writeAndShow("iris.bar.notices.upcoming", next, next ? "upcoming" : ""), keywords: ["calendar", "event", "meeting", "agenda", "reminder"] },
        { section: "bar", group: "Notices", label: "First said", description: "How long before an event starts the Island first says it.", path: "iris.bar.notices.upcomingLead", visibleWhen: "iris.bar.notices.upcoming", showIf: () => Boolean(Config.options?.iris?.bar?.events ?? true), kind: "choice", tune: true, fallback: 10,
            choices: [{label:"10 min",value:10},{label:"5 min",value:5},{label:"1 min",value:1}], keywords: ["minutes", "before", "reminder", "lead"] },
        { section: "bar", group: "Notices", label: "Rain and snow", description: "Rain or snow on its way in the next hours.", path: "iris.bar.notices.rain", visibleWhen: "iris.bar.events", kind: "switch", tune: true, fallback: true, set: next => root.writeAndShow("iris.bar.notices.rain", next, next ? "rain" : ""), keywords: ["weather", "rain", "snow", "forecast"] },
        { section: "bar", group: "Notices", label: "Timers", description: "A timer that ends, and each focus or break.", path: "iris.bar.notices.timers", visibleWhen: "iris.bar.events", kind: "switch", tune: true, fallback: true, set: next => root.writeAndShow("iris.bar.notices.timers", next, next ? "timers" : ""), keywords: ["timer", "pomodoro", "alarm", "countdown", "focus", "break"] },
        { section: "bar", group: "Notices", label: "Finished jobs", description: "Downloads, copies and updates that end or fail.", path: "iris.bar.notices.jobs", visibleWhen: "iris.bar.events", kind: "switch", tune: true, fallback: true, set: next => root.writeAndShow("iris.bar.notices.jobs", next, next ? "jobs" : ""), keywords: ["download", "copy", "update", "job", "task", "progress", "done"] },
        { section: "bar", group: "Notices", label: "Shelf", description: "Files and text kept on the Shelf.", path: "iris.bar.notices.shelf", visibleWhen: "iris.bar.events", kind: "switch", tune: true, fallback: true, set: next => root.writeAndShow("iris.bar.notices.shelf", next, next ? "shelf" : ""), keywords: ["shelf", "drop", "files"] },
        { section: "bar", group: "Notices", label: "Game mode", description: "Turned on or off.", path: "iris.bar.notices.gameMode", visibleWhen: "iris.bar.events", kind: "switch", tune: true, fallback: true, set: next => root.writeAndShow("iris.bar.notices.gameMode", next, next ? "gameMode" : ""), keywords: ["game", "gaming", "game mode"] },
        { section: "bar", group: "Notices", label: "Compositor config", description: "An error in the compositor's config, and when it is fixed.", showIf: () => CompositorConfig.niri, path: "iris.bar.notices.niri", visibleWhen: "iris.bar.events", kind: "switch", tune: true, fallback: true, set: next => root.writeAndShow("iris.bar.notices.niri", next, next ? "niri" : ""), keywords: ["niri", "config", "error", "kdl"] },
        { section: "bar", group: "Notices", label: "Loud jumps held back", description: "When a sudden jump in volume is stopped.", path: "iris.bar.notices.soundGuard", visibleWhen: "iris.bar.events", kind: "switch", tune: true, fallback: true, set: next => root.writeAndShow("iris.bar.notices.soundGuard", next, next ? "soundGuard" : ""), keywords: ["volume", "loud", "protection", "ears"] },
        { section: "bar", group: "Connections", label: "Connection notices", description: "A moment in the Island when something is plugged in, connected, unplugged or lost.", path: "osd.connections.enable", kind: "switch", fallback: true, keywords: ["connection", "connected", "disconnected", "plug", "unplug", "device", "notice", "toast", "popup", "wifi", "bluetooth", "usb", "charger", "offline"] },
        { section: "bar", group: "Connections", label: "Network", description: "Wi-Fi or a cable connected and dropped.", path: "osd.connections.network", visibleWhen: "osd.connections.enable", kind: "switch", tune: true, fallback: true, keywords: ["wifi", "ethernet", "cable"] },
        { section: "bar", group: "Connections", label: "Internet", description: "Lost and back online.", path: "osd.connections.internet", visibleWhen: "osd.connections.enable", kind: "switch", tune: true, fallback: true, keywords: ["offline", "online", "internet"] },
        { section: "bar", group: "Connections", label: "Bluetooth devices", description: "Headphones, keyboards, controllers.", path: "osd.connections.bluetooth", visibleWhen: "osd.connections.enable", kind: "switch", tune: true, fallback: true, keywords: ["bluetooth", "headphones", "airpods"] },
        { section: "bar", group: "Connections", label: "USB devices", description: "Mice, keyboards, controllers, cameras and phones, by name.", path: "osd.connections.usb", visibleWhen: "osd.connections.enable", kind: "switch", tune: true, fallback: true, keywords: ["usb", "mouse", "keyboard", "controller", "gamepad", "webcam", "camera", "phone"] },
        { section: "bar", group: "Connections", label: "Charger", description: "Plugged in and on battery.", path: "osd.connections.power", visibleWhen: "osd.connections.enable", kind: "switch", tune: true, fallback: true, keywords: ["charger", "charging", "battery", "power"] },
        { section: "bar", group: "Connections", label: "Sound output", description: "Headphones or speakers take over the sound.", path: "osd.connections.audio", visibleWhen: "osd.connections.enable", kind: "switch", tune: true, fallback: true, keywords: ["headphones", "speaker", "output", "sound"] },
        { section: "bar", group: "Connections", label: "Displays", description: "A monitor plugged in or removed.", path: "osd.connections.displays", visibleWhen: "osd.connections.enable", kind: "switch", tune: true, fallback: true, keywords: ["monitor", "display", "screen", "hdmi"] },
        { section: "bar", group: "Connections", label: "Drives and memory cards", description: "Pendrives, external disks and SD cards, with their name and size.", path: "osd.connections.drives", visibleWhen: "osd.connections.enable", kind: "switch", tune: true, fallback: true, keywords: ["usb", "pendrive", "drive", "disk", "sd", "memory card", "external"] },
        { section: "bar", group: "Notices", label: "Caps Lock badge", description: "A small pill drops out of the Island when Caps Lock turns on or off.", path: "keyboardIndicators.popup.caps", visibleWhen: "iris.bar.events", tune: true, kind: "switch", fallback: true },
        { section: "bar", group: "Interaction", label: "Expand on hover", description: "The pointer has to rest on the Island; passing over it does nothing. A full-width Island always opens on a click instead.", path: "iris.bar.hoverExpand", kind: "switch", fallback:true },
        { section: "bar", group: "Interaction", label: "Hover delay", path: "iris.bar.hoverDelay", kind: "range", fallback:300,min:120,max:800,step:20,unit:" ms" },
        { section: "bar", group: "Interaction", label: "Scroll on the Island", description: "On the resting Island: Shift swaps volume and brightness; Ctrl adjusts the microphone.", path: "iris.bar.scrollAction", kind: "choice", tune: true, fallback: "volume", choices: [{label:"Volume",value:"volume"},{label:"Brightness",value:"brightness"},{label:"Off",value:"none"}] },
        { section: "bar", group: "Interaction", label: "Scroll on bubbles", description: "Also adjust over the media, controls and tray bubbles.", path: "iris.bar.scrollBubbles", tune: true, kind: "switch", fallback: true },
        { section: "bar", group: "Resting Island", label: "Trailing bubble", tune: true, description: "The bubble beside a Cluster Island.", visibleWhen: "iris.bar.composition=cluster", path: "iris.bar.trailing", kind: "choice", fallback: "controls", choices: [{label:"Controls",value:"controls"},{label:"Notifications",value:"notifications"},{label:"Weather",value:"weather"},{label:"Sound",value:"sound"},{label:"Microphone",value:"mic"},{label:"None",value:"none"}] },
        { section: "bar", group: "Resting Island", label: "Bubbles in the Island", description: "Small faces the Island carries, in the order you switch them on. One picked here leaves the frame.", path: "iris.bar.pieces", kind: "pieces", fallback: [], choices: IrisPieces.extras.map(piece => ({ label: piece.label, value: piece.id })) },
        { section: "bar", group: "Resting Island", label: "Where they sit", description: "Which end of the Island carries them.", path: "iris.bar.piecesSide", kind: "choice", tune: true, fallback: "end", choices: [{label:"After the clock",value:"end"},{label:"Before the clock",value:"start"}] },
        { section: "bar", group: "Bar", showIf: () => ["full", "menubar", "pods"].includes(String(Config.options?.iris?.bar?.layout ?? "island")), label: "Start", description: "What rests at the start of the full-width Island, in the order you switch it on. The Island itself is the live part: the time, or whatever is happening.", path: "iris.bar.fullStart", kind: "pieces", fallback: ["workspaces", "window"], choices: root.barZoneChoices },
        { section: "bar", group: "Bar", showIf: () => ["full", "menubar", "pods"].includes(String(Config.options?.iris?.bar?.layout ?? "island")), label: "Centre", description: "Kept in the middle of the edge while there is room.", path: "iris.bar.fullCenter", kind: "pieces", fallback: ["island"], choices: root.barZoneChoices },
        { section: "bar", group: "Bar", showIf: () => ["full", "menubar", "pods"].includes(String(Config.options?.iris?.bar?.layout ?? "island")), label: "End", description: "What rests at the far end.", path: "iris.bar.fullEnd", kind: "pieces", fallback: ["tray", "notifications", "sound", "controls"], choices: root.barZoneChoices },
        { section: "player", group: "Bubble", label: "Media bubble opens", description: "A card that floats out of the bubble, or the Island's player page.", path: "iris.player.bubbleOpens", kind: "choice", fallback: "card", choices: [{label:"Card",value:"card",glyph:"web_asset"},{label:"Island",value:"island",glyph:"pill"}] },
        { section: "player", group: "Bubble", label: "Keep the card open", description: "The card stays beside the Island while a player is active.", path: "iris.player.cardPinned", kind: "switch", fallback: false },
    ].concat(root.bubbleRows, [
        { section: "sources", group: "Weather", label: "Weather", description: "The forecast every weather piece and widget shows.", path: "weather.enable", kind: "switch", fallback: true, keywords: ["weather", "forecast", "temperature", "clima", "tiempo"] },
        { section: "sources", group: "Weather", label: "Latitude", description: "With longitude, overrides the place.", path: "weather.manualLat", visibleWhen: "weather.enable", kind: "text", numeric: true, placeholder: "-34.6037", fallback: 0, tune: true, keywords: ["coordinates", "latitude", "location", "coordenadas"] },
        { section: "sources", group: "Weather", label: "Longitude", path: "weather.manualLon", visibleWhen: "weather.enable", kind: "text", numeric: true, placeholder: "-58.3816", fallback: 0, tune: true, keywords: ["coordinates", "longitude", "location", "coordenadas"] },
        { section: "controlCenter", group: "Hotspot", label: "Network name", description: "What other devices see when the hotspot in the Control Center is on.", path: "hotspot.ssid", kind: "text", placeholder: "iNiR Hotspot", fallback: "iNiR Hotspot", keywords: ["hotspot", "ssid", "wifi", "share", "tethering", "compartir"] },
        { section: "controlCenter", group: "Hotspot", label: "Password", path: "hotspot.password", kind: "text", secret: true, placeholder: "At least 8 characters", fallback: "", keywords: ["hotspot", "password", "key", "contraseña"] },
        { tune: true, section: "controlCenter", group: "Hotspot", label: "Band", description: "5 GHz is faster nearby; 2.4 GHz reaches further and works with older devices.", path: "hotspot.band", kind: "choice", fallback: "bg", choices: [{label:"2.4 GHz",value:"bg"},{label:"5 GHz",value:"a"}] },
        { tune: true, section: "sources", group: "Network", label: "Browser identity", description: "The user agent sent to wallpaper, news and image sites that refuse unknown clients.", path: "networking.userAgent", kind: "text", placeholder: "Mozilla/5.0 …", fallback: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36", keywords: ["user agent", "browser", "network", "wallhaven"] },
        { section: "sources", group: "Weather", label: "Fahrenheit", description: "Degrees and distances in US units instead of Celsius and metric.", path: "weather.useUSCS", kind: "switch", fallback: false },
        { section: "sources", group: "Weather", label: "Show my city", description: "Off, no surface prints where you are: the Island, the lock screen, sidebars, widgets. For streams and screen sharing.", path: "weather.hideLocation", invert: true, visibleWhen: "weather.enable", kind: "switch", fallback: false, keywords: ["location", "city", "place", "privacy", "hide", "stream", "screen share", "ubicación", "ciudad", "privacidad", "ocultar"] },
        { section: "sources", group: "Weather", label: "Place", description: "The city the forecast is for. Leave it empty and iRiS works it out from your connection, which is usually close but not always right.", path: "weather.city", kind: "text", placeholder: "Automatic", fallback: "" },
        { tune: true, section: "sources", group: "Weather", label: "Use GPS when there is one", description: "Asks geoclue instead of guessing from your connection.", path: "weather.enableGPS", kind: "switch", fallback: false },
        { section: "sources", group: "Weather", label: "Check every", path: "weather.fetchInterval", kind: "range", fallback: 10, min: 5, max: 60, step: 5, unit: " min" },
        { section: "sources", group: "Calendar", label: "Bring in other calendars", description: "Google and iCal feeds show up beside your own events, in the calendar bubble and in Today.", path: "calendar.externalSync.enable", kind: "switch", fallback: false },
        { section: "sources", group: "Calendar", label: "Calendars", description: "What each feed brings in the next two weeks.", kind: "list", view: Qt.resolvedUrl("IrisCalendarAccounts.qml"), summary: false, visibleWhen: "calendar.externalSync.enable", keywords: ["google calendar", "outlook", "ical", "ics", "caldav", "nextcloud", "accounts", "feed", "events", "calendario", "cuentas"] },
        { section: "sources", group: "Calendar", label: "Refresh every", path: "calendar.externalSync.refreshMinutes", visibleWhen: "calendar.externalSync.enable", kind: "range", fallback: 15, min: 5, max: 120, step: 5, unit: " min" },
        { section: "sources", group: "Updates", label: "Look for updates every", description: "How often the Updates bubble counts what is waiting.", path: "updates.checkInterval", kind: "range", fallback: 120, min: 15, max: 720, step: 15, unit: " min" },
        { section: "controlCenter", group: "VPN", label: "VPN button in quick controls", description: "Adds a VPN switch to the Control Center beside Ethernet and Bluetooth.", path: "vpn.quickToggle", kind: "switch", fallback: false },
        { tune: true, section: "controlCenter", group: "VPN", label: "Connection details", description: "The VPN card shows addresses, the tailnet's devices and live traffic; tap a value to copy it.", path: "vpn.details", kind: "switch", fallback: false, keywords: ["vpn", "tailscale", "wireguard", "ip", "ipv4", "ipv6", "address", "devices", "traffic", "details", "detalles", "dirección"] },
        { section: "sources", group: "New iNiR", label: "Watch for new iNiR versions", description: "A bubble shows up on its own when there is a new iNiR upstream, and goes away once you update.", path: "shellUpdates.enabled", kind: "switch", fallback: true },
        { section: "sources", group: "New iNiR", label: "Where it shows up", description: "The bubble's place while an update waits: a spot on the frame, or the Island.", path: "iris.bubbles.extras.shellUpdate.place", visibleWhen: "shellUpdates.enabled", kind: "zone", fallback: "right", choices: IrisPieces.zoneChoices(true) },
        { section: "sources", group: "New iNiR", label: "Check every", path: "shellUpdates.checkIntervalMinutes", visibleWhen: "shellUpdates.enabled", kind: "range", fallback: 360, min: 60, max: 1440, step: 60, unit: " min" },
        { section: "sources", group: "New iNiR", label: "Say it again after", description: "If you leave an update sitting, iNiR brings it back this often, also after Not now.", path: "shellUpdates.remindDays", visibleWhen: "shellUpdates.enabled", kind: "range", fallback: 3, min: 0, max: 30, zeroLabel: "Only once", unit: " days" },
        { section: "anime", group: "Airing", label: "Episodes in the card", description: "How many upcoming episodes the Airing bubble lists.", path: "iris.anime.shows", kind: "range", fallback: 5, min: 3, max: 8, keywords: ["anime", "weeb", "otaku", "airing", "episodes", "episodio", "following", "shows", "tracker"] },
        { section: "anime", group: "Continue", label: "Audio", description: "Japanese with subtitles, or dubbed where a dub exists.", path: "iris.anime.audio", visibleWhen: "iris.bubbles.extras.watching.enable", kind: "choice", fallback: "sub", choices: [{label:"Subtitled",value:"sub",glyph:"subtitles"},{label:"Dubbed",value:"dub",glyph:"record_voice_over"}], keywords: ["anime", "ani-cli", "dub", "doblaje", "doblado", "sub", "subtitles", "subtitulos", "subtítulos", "language", "idioma", "audio", "japanese", "english"] },
        { section: "anime", group: "Continue", label: "Quality", description: "The stream every episode starts in.", path: "iris.anime.quality", visibleWhen: "iris.bubbles.extras.watching.enable", kind: "choice", fallback: "best", choices: [{label:"Best",value:"best"},{label:"1080p",value:"1080"},{label:"720p",value:"720"},{label:"480p",value:"480"}], keywords: ["anime", "ani-cli", "quality", "calidad", "resolution", "resolución", "1080p", "720p", "480p", "stream", "video"] },
        { section: "anime", group: "Continue", label: "Subtitle size", description: "Every episode starts with subtitles this size.", path: "iris.anime.subtitleScale", visibleWhen: "iris.bubbles.extras.watching.enable", kind: "range", fallback: 100, min: 50, max: 200, step: 10, unit: " %", keywords: ["anime", "subtitles", "subtítulos", "subtitulos", "size", "tamaño", "font", "letra", "mpv"] },
        { section: "anime", group: "Continue", label: "Subtitle height", description: "How high subtitles sit; 100 is the bottom edge.", path: "iris.anime.subtitlePosition", visibleWhen: "iris.bubbles.extras.watching.enable", kind: "range", fallback: 100, min: 50, max: 100, step: 1, unit: " %", keywords: ["anime", "subtitles", "subtítulos", "position", "posición", "height", "altura", "mpv"] },
        { section: "anime", group: "Continue", label: "Skip intros", description: "Jumps over openings where ani-skip knows them.", path: "iris.anime.skipIntro", visibleWhen: "iris.bubbles.extras.watching.enable", kind: "switch", fallback: false, keywords: ["anime", "opening", "intro", "skip", "saltar", "ani-skip", "op", "ed"] },
        { section: "lock", group: "Scene", label: "Behind everything", description: "The desktop wallpaper, a picture of its own, or nothing but the material.", path: "iris.lock.scene.source", kind: "choice", fallback: "desktop", choices: [{label:"Wallpaper",value:"desktop",glyph:"wallpaper"},{label:"Its own",value:"custom",glyph:"image"},{label:"Material",value:"colour",glyph:"square"}] },
        { section: "lock", group: "Scene", label: "Picture", description: "Full path to the image or video the lock screen uses.", path: "iris.lock.scene.path", visibleWhen: "iris.lock.scene.source=custom", kind: "text", fallback: "" },
        { section: "lock", group: "Scene", label: "Blur", description: "0 leaves the picture sharp.", path: "iris.lock.scene.blur", visibleWhen: "!iris.lock.scene.source=colour", kind: "range", fallback: 100, min: 0, max: 100, step: 5, unit: " %", zeroLabel: "Sharp" },
        { section: "lock", group: "Scene", label: "Colour left in the blur", description: "How much of the picture's colour survives.", path: "iris.lock.scene.saturation", visibleWhen: "!iris.lock.scene.source=colour", kind: "range", fallback: 15, min: 0, max: 100, step: 5, unit: " %" },
        { section: "lock", group: "Scene", label: "Dim", path: "iris.lock.scene.dim", kind: "range", fallback: 0, min: 0, max: 80, step: 5, unit: " %", zeroLabel: "None" },
        { tune: true, section: "lock", group: "Scene", label: "Play live wallpapers", description: "Off shows the first frame, which costs nothing while the screen is locked.", path: "lock.enableAnimation", visibleWhen: "!iris.lock.scene.source=colour", kind: "switch", fallback: false, keywords: ["video", "animated", "gif", "motion"] },
        { section: "lock", group: "Scene", label: "Vignette", description: "Darkens the corners so the middle carries the eye.", path: "iris.lock.scene.vignette", visibleWhen: "!iris.lock.scene.source=colour", kind: "range", fallback: 0, min: 0, max: 90, step: 5, unit: " %", zeroLabel: "None" },
        { section: "lock", group: "Scene", label: "Slow drift", description: "The picture creeps and breathes instead of standing still.", path: "iris.lock.scene.motion", visibleWhen: "!iris.lock.scene.source=colour", kind: "choice", tune: true, fallback: "none", choices: [{label:"Still",value:"none",glyph:"pause"},{label:"Drift",value:"drift",glyph:"animation"}] },
        { section: "lock", group: "Scene", label: "One pass takes", path: "iris.lock.scene.driftTime", visibleWhen: "iris.lock.scene.motion=drift", kind: "range", fallback: 40, min: 10, max: 180, step: 5, unit: " s" },
        { section: "lock", group: "Scene", label: "Fit", description: "Cover fills the screen and crops; contain shows the whole picture.", path: "iris.lock.scene.fit", visibleWhen: "!iris.lock.scene.source=colour", kind: "choice", tune: true, fallback: "cover", choices: [{label:"Cover",value:"cover"},{label:"Contain",value:"contain"}] },
        { section: "lock", group: "Scene", label: "Legibility wash", description: "What keeps white text readable over a bright picture.", path: "iris.lock.scene.scrim", kind: "choice", tune: true, fallback: "gradient", choices: [{label:"Top and bottom",value:"gradient"},{label:"Even",value:"flat"},{label:"None",value:"none"}] },
        { section: "lock", group: "Scene", label: "Wash strength", path: "iris.lock.scene.scrimStrength", visibleWhen: "!iris.lock.scene.scrim=none", kind: "range", fallback: 100, min: 0, max: 200, step: 10, unit: " %" },
        { section: "lock", group: "Scene", label: "Plates", description: "What the player, the field and the chips sit on.", path: "iris.lock.material", kind: "choice", tune: true, fallback: "glass", choices: [{label:"Glass",value:"glass"},{label:"Tint",value:"tint"},{label:"Nothing",value:"none"}], keywords: ["blur", "frosted", "background", "card"] },
        { section: "lock", group: "Type", label: "Text size", description: "Everything on the lock screen, together.", path: "iris.lock.type.scale", kind: "range", fallback: 100, min: 60, max: 160, step: 5, unit: " %" },
        { section: "lock", group: "Type", label: "Clock size", path: "iris.lock.type.clockSize", kind: "range", fallback: 112, min: 24, max: 260, step: 4, unit: " px" },
        { section: "lock", group: "Type", label: "Clock face", tune: true, description: "The typeface the hour is set in.", path: "iris.lock.type.clockFont", kind: "choice", fallback: "numbers", choices: [{label:"Numbers",value:"numbers"},{label:"Interface",value:"main"},{label:"Display",value:"title"}] },
        { section: "lock", group: "Type", label: "Clock weight", path: "iris.lock.type.clockWeight", kind: "range", fallback: 700, min: 100, max: 900, step: 100 },
        { section: "lock", group: "Type", label: "Clock tracking", description: "Space between the digits.", path: "iris.lock.type.clockTracking", kind: "range", fallback: -2, min: -12, max: 12, unit: " px" },
        { tune: true, section: "lock", group: "Type", label: "Clock format", path: "iris.lock.type.clockFormat", kind: "choice", fallback: "auto", choices: [{label:"Follow the system",value:"auto"},{label:"24 hour",value:"24h"},{label:"12 hour",value:"12h"}] },
        { section: "lock", group: "Type", label: "Seconds", description: "Ticks every second while the screen is locked.", path: "iris.lock.type.seconds", kind: "switch", tune: true, fallback: false },
        { tune: true, section: "lock", group: "Type", label: "Date", path: "iris.lock.type.dateFormat", kind: "choice", fallback: "long", choices: [{label:"Monday, 5 May",value:"long"},{label:"Mon 5 May",value:"short"},{label:"5/5/26",value:"numeric"},{label:"Monday",value:"weekday"}] },
        { section: "lock", group: "Type", label: "Clock colour", path: "iris.lock.type.accent", kind: "choice", tune: true, fallback: "plain", choices: [{label:"White",value:"plain"},{label:"Accent",value:"accent"},{label:"Highlight",value:"highlight"}] },
        { section: "lock", group: "Clock", label: "Clock", path: "iris.lock.blocks.clock.enable", kind: "switch", fallback: true },
        { section: "lock", group: "Clock", label: "Style", path: "iris.lock.blocks.clock.style", visibleWhen: "iris.lock.blocks.clock.enable", kind: "choice", fallback: "stack", choices: [{label:"Date over time",value:"stack"},{label:"Time alone",value:"inline"},{label:"Small",value:"minimal"}] },
        { section: "lock", group: "Clock", label: "Show the date", tune: true, path: "iris.lock.blocks.clock.date", visibleWhen: "iris.lock.blocks.clock.enable", kind: "switch", fallback: true },
        { section: "lock", group: "Clock", label: "Where it sits", path: "iris.lock.blocks.clock.zone", visibleWhen: "iris.lock.blocks.clock.enable", kind: "choice", tune: true, fallback: "top", choices: [{label:"Top",value:"top"},{label:"Centre",value:"center"},{label:"Bottom",value:"bottom"},{label:"Top left",value:"topLeft"},{label:"Top right",value:"topRight"},{label:"Bottom left",value:"bottomLeft"},{label:"Bottom right",value:"bottomRight"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Where you left it",value:"free"}] },
        { section: "lock", group: "Clock", label: "Size", path: "iris.lock.blocks.clock.scale", visibleWhen: "iris.lock.blocks.clock.enable", kind: "range", fallback: 100, min: 50, max: 200, step: 5, unit: " %" },
        { section: "lock", group: "At a glance", label: "At a glance", description: "Small glass chips under the clock: the weather, what is next and the battery.", path: "iris.lock.blocks.glance.enable", kind: "switch", fallback: true, keywords: ["widgets", "weather", "calendar", "battery"] },
        { section: "lock", group: "At a glance", label: "Weather", tune: true, path: "iris.lock.blocks.glance.weather", visibleWhen: "iris.lock.blocks.glance.enable", kind: "switch", fallback: true },
        { section: "lock", group: "At a glance", label: "Next event", tune: true, path: "iris.lock.blocks.glance.events", visibleWhen: "iris.lock.blocks.glance.enable", kind: "switch", fallback: true },
        { section: "lock", group: "At a glance", label: "Battery", tune: true, path: "iris.lock.blocks.glance.battery", visibleWhen: "iris.lock.blocks.glance.enable", kind: "switch", fallback: true },
        { section: "lock", group: "At a glance", label: "Where it sits", path: "iris.lock.blocks.glance.zone", visibleWhen: "iris.lock.blocks.glance.enable", kind: "choice", tune: true, fallback: "top", choices: [{label:"Top",value:"top"},{label:"Centre",value:"center"},{label:"Bottom",value:"bottom"},{label:"Top left",value:"topLeft"},{label:"Top right",value:"topRight"},{label:"Bottom left",value:"bottomLeft"},{label:"Bottom right",value:"bottomRight"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Where you left it",value:"free"}] },
        { section: "lock", group: "At a glance", label: "Size", path: "iris.lock.blocks.glance.scale", visibleWhen: "iris.lock.blocks.glance.enable", kind: "range", fallback: 100, min: 50, max: 200, step: 5, unit: " %" },
        { section: "lock", group: "Now playing", label: "Now playing", path: "iris.lock.blocks.media.enable", kind: "switch", fallback: true },
        { section: "lock", group: "Now playing", label: "Style", tune: true, path: "iris.lock.blocks.media.style", visibleWhen: "iris.lock.blocks.media.enable", kind: "choice", fallback: "card", choices: [{label:"On a plate",value:"card"},{label:"Bare",value:"bare"}] },
        { section: "lock", group: "Now playing", label: "Where it sits", path: "iris.lock.blocks.media.zone", visibleWhen: "iris.lock.blocks.media.enable", kind: "choice", tune: true, fallback: "bottom", choices: [{label:"Top",value:"top"},{label:"Centre",value:"center"},{label:"Bottom",value:"bottom"},{label:"Top left",value:"topLeft"},{label:"Top right",value:"topRight"},{label:"Bottom left",value:"bottomLeft"},{label:"Bottom right",value:"bottomRight"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Where you left it",value:"free"}] },
        { section: "lock", group: "Now playing", label: "Size", path: "iris.lock.blocks.media.scale", visibleWhen: "iris.lock.blocks.media.enable", kind: "range", fallback: 100, min: 50, max: 200, step: 5, unit: " %" },
        { section: "lock", group: "Activity", label: "Activity", description: "A recording or a running timer, as a plate.", path: "iris.lock.blocks.activity.enable", kind: "switch", fallback: true },
        { section: "lock", group: "Activity", label: "Where it sits", path: "iris.lock.blocks.activity.zone", visibleWhen: "iris.lock.blocks.activity.enable", kind: "choice", tune: true, fallback: "top", choices: [{label:"Top",value:"top"},{label:"Centre",value:"center"},{label:"Bottom",value:"bottom"},{label:"Top left",value:"topLeft"},{label:"Top right",value:"topRight"},{label:"Bottom left",value:"bottomLeft"},{label:"Bottom right",value:"bottomRight"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Where you left it",value:"free"}] },
        { section: "lock", group: "Activity", label: "Size", path: "iris.lock.blocks.activity.scale", visibleWhen: "iris.lock.blocks.activity.enable", kind: "range", fallback: 100, min: 50, max: 200, step: 5, unit: " %" },
        { tune: true, section: "lock", group: "Sign in", label: "Avatar", path: "iris.lock.blocks.session.avatar", kind: "switch", fallback: true },
        { tune: true, section: "lock", group: "Sign in", label: "Your name", path: "iris.lock.blocks.session.name", kind: "switch", fallback: true },
        { section: "lock", group: "Sign in", label: "Hint under the field", description: "Says what went wrong, or that the reader is waiting for a finger.", path: "iris.lock.blocks.session.hint", kind: "switch", tune: true, fallback: true },
        { section: "lock", group: "Sign in", label: "Field width", path: "iris.lock.blocks.session.width", kind: "range", fallback: 248, min: 160, max: 480, step: 8, unit: " px" },
        { section: "lock", group: "Sign in", label: "Where it sits", path: "iris.lock.blocks.session.zone", kind: "choice", tune: true, fallback: "bottom", choices: [{label:"Top",value:"top"},{label:"Centre",value:"center"},{label:"Bottom",value:"bottom"},{label:"Top left",value:"topLeft"},{label:"Top right",value:"topRight"},{label:"Bottom left",value:"bottomLeft"},{label:"Bottom right",value:"bottomRight"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Where you left it",value:"free"}] },
        { section: "lock", group: "Sign in", label: "Size", path: "iris.lock.blocks.session.scale", kind: "range", fallback: 100, min: 50, max: 200, step: 5, unit: " %" },
        { section: "lock", group: "Status", label: "Status", description: "Battery, network and keyboard layout, in small type.", path: "iris.lock.blocks.status.enable", kind: "switch", fallback: false },
        { section: "lock", group: "Status", label: "Battery", path: "iris.lock.blocks.status.battery", visibleWhen: "iris.lock.blocks.status.enable", kind: "switch", fallback: true },
        { section: "lock", group: "Status", label: "Network", path: "iris.lock.blocks.status.network", visibleWhen: "iris.lock.blocks.status.enable", kind: "switch", fallback: true },
        { section: "lock", group: "Status", label: "Keyboard layout", path: "iris.lock.blocks.status.keyboard", visibleWhen: "iris.lock.blocks.status.enable", kind: "switch", fallback: true },
        { section: "lock", group: "Status", label: "Where it sits", path: "iris.lock.blocks.status.zone", visibleWhen: "iris.lock.blocks.status.enable", kind: "choice", tune: true, fallback: "topRight", choices: [{label:"Top",value:"top"},{label:"Centre",value:"center"},{label:"Bottom",value:"bottom"},{label:"Top left",value:"topLeft"},{label:"Top right",value:"topRight"},{label:"Bottom left",value:"bottomLeft"},{label:"Bottom right",value:"bottomRight"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Where you left it",value:"free"}] },
        { section: "lock", group: "Status", label: "Size", path: "iris.lock.blocks.status.scale", visibleWhen: "iris.lock.blocks.status.enable", kind: "range", fallback: 100, min: 50, max: 200, step: 5, unit: " %" },
        { section: "bubbles", group: "Behaviour", label: "Bubble design", description: "How each bubble beside the Island is drawn.", path: "iris.bubbles.design", kind: "choice", fallback: "glass", choices: [{label:"Glass",value:"glass",glyph:"circle",detail:"The body alone."},{label:"Tinted",value:"tint",glyph:"lens",detail:"Each bubble's own colour, with white marks."},{label:"Outline",value:"outline",glyph:"radio_button_unchecked",detail:"Its colour as a ring inside the edge."}], keywords: ["bubble", "design", "style", "colour", "color", "tint", "outline", "ring", "diseño"] },
        { section: "bubbles", group: "Behaviour", label: "Tapping a bubble", description: "What a tap on a bubble does.", path: "iris.bubbles.opens", kind: "choice", fallback: "card", choices: [{label:"Opens its card",value:"card",glyph:"web_asset",detail:"It grows into a card of its own."},{label:"Opens the Island",value:"island",glyph:"pill",detail:"The Island page or panel it stands for (level bubbles then mute)."}] },
        { section: "bubbles", group: "On the contour", label: "Reserve space for windows", tune: true, description: "Windows keep clear of the bubbles resting on an edge.", path: "iris.bubbles.reserve", visibleWhen: "iris.bubbles.attach", kind: "switch", fallback: true, keywords: ["reserve", "space", "windows", "exclusive", "margin", "espacio", "reservar"] },
        { section: "bubbles", group: "Floating", label: "Space from the screen edges", description: "How far floating bubbles rest from the edges when they are not on the frame.", path: "iris.bubbles.edgeGap", visibleWhen: "!iris.bubbles.attach", kind: "range", fallback: 20, min: 0, max: 64, unit: " px" },
        { section: "bubbles", group: "Behaviour", label: "Snap to corners and edges", description: "Dropped near a ring, a bubble joins that corner or edge in the spot you let it go; off, it stays where you let go.", path: "iris.bubbles.snap", kind: "switch", fallback: true },
        { section: "dock", group: "Visibility", label: "Show dock", path: "iris.dock.enable", kind: "switch", fallback:true },
        { section: "dock", group: "Visibility", label: "Automatically hide", description: "Rest the pointer at the screen edge to reveal it.", showIf: () => !IrisFrame.rail, path: "iris.dock.autoHide", kind: "switch", fallback:true },
        { section: "dock", group: "Visibility", label: "Reserve space for windows", description: "Keep tiled windows clear of the visible Dock.", showIf: () => !IrisFrame.rail, path: "iris.dock.reserveSpace", visibleWhen: "!iris.dock.autoHide", kind: "switch", fallback:true, keywords: ["reserve", "space", "windows", "exclusive", "margin", "espacio", "reservar"] },
        { section: "dock", group: "Visibility", label: "Stay visible on empty workspaces", showIf: () => !IrisFrame.rail, path: "iris.dock.revealOnEmpty", tune: true, kind: "switch", fallback:true },
        { section: "dock", group: "Icons", label: "Notification badges", tune: true, path: "iris.dock.badges", kind: "switch", fallback:true },
        { section: "dock", group: "Apps", label: "Pinned apps", description: "Drag one to move it in the Dock.", glance: () => { const count = (Config.options?.apps?.pinned ?? []).length; return count > 0 ? Translation.tr("%1 pinned").arg(count) : "" }, kind: "list", view: Qt.resolvedUrl("IrisDockPinned.qml"), summary: () => String((Config.options?.apps?.pinned ?? []).length), keywords: ["pinned", "pin", "unpin", "favourites", "favorites", "order", "fijadas", "fijar", "favoritos", "orden"] },
        { section: "dock", group: "Apps", label: "Open apps", tune: true, description: "Where open apps sit in the dock.", path: "iris.dock.arrange", kind: "choice", fallback: "pinned", choices: [{label:"Keep pinned place",value:"pinned",glyph:"keep",detail:"Pinned apps keep their place while open."},{label:"In opening order",value:"opened",glyph:"schedule",detail:"Pinned apps join the other open apps, in the order you opened them."}], keywords: ["order", "sort", "arrange", "organize", "group", "opened", "running", "pinned", "first", "orden", "ordenar", "organizar", "abiertas", "fijadas", "apertura"] },
        { section: "dock", group: "Apps", label: "Drag to reorder", description: "Slide an icon along the Dock to move it.", path: "iris.dock.reorder", tune: true, kind: "switch", fallback: true, keywords: ["drag", "drop", "move", "reorder", "rearrange", "position", "arrastrar", "mover", "reordenar", "posición"] },
        { section: "motion", group: "Motion", label: "Reduce motion", description: "Surfaces appear in place.", path: "iris.appearance.motion", invert: true, kind: "switch", fallback: true, keywords: ["animations", "animation", "animate", "still", "accessibility", "vestibular", "animaciones", "movimiento", "reducir"] },
        { section: "desktop", group: "Widgets", label: "Desktop widgets", description: "Turning this off also unloads their data providers.", path: "iris.modules.desktopWidgets", kind: "switch", fallback:true },
        { section: "desktop", group: "Overview backdrop", label: "Wallpaper behind the overview", description: "Shown around workspaces when the overview is open.", path: "background.backdrop.enable", kind: "switch", fallback:true },
        { section: "desktop", group: "Overview backdrop", label: "Same wallpaper as the desktop", tune: true, description: "Off keeps the overview's own wallpaper; choose it in the gallery with Overview as the target.", path: "background.backdrop.useMainWallpaper", kind: "switch", fallback: true },
        { tune: true, section: "desktop", group: "Overview backdrop", showIf: () => Config.options?.background?.backdrop?.enable ?? true, label: "Only the backdrop on the desktop", description: "Hides the desktop wallpaper: the desktop shows the backdrop with its blur and dim, and glass follows it.", path: "background.backdrop.hideWallpaper", kind: "switch", fallback: false, keywords: ["backdrop", "hide", "wallpaper", "blur", "only", "fondo", "ocultar"] },
        { tune: true, section: "desktop", group: "Overview backdrop", label: "Animate in the overview", description: "A live wallpaper moves behind the workspaces, only while the overview is open.", path: "background.backdrop.enableAnimation", kind: "switch", fallback: false },
        { section: "desktop", group: "Overview backdrop", label: "Blur", path: "background.backdrop.blurRadius", kind: "range", fallback:40,min:0,max:100,unit:" px" },
        { section: "desktop", group: "Overview backdrop", label: "Dim", path: "background.backdrop.dim", kind: "range", fallback: 0, min:0,max:100,unit:" %" },
        { tune: true, section: "desktop", group: "Overview backdrop", label: "Vignette", path: "background.backdrop.vignetteEnabled", kind: "switch", fallback:false },
        { section: "appearance", group: "Presets", label: "Pick a look", description: "One tap sets the whole look; Ctrl+Z takes it back. The tiles below fine-tune it.", kind: "themes",
            glance: () => !IrisThemes.find(IrisThemes.activeId) ? Translation.tr("Custom") : String(IrisThemes.find(IrisThemes.activeId).name) + (IrisThemes.modified ? " · " + Translation.tr("Modified") : ""), keywords: ["preset", "presets", "theme", "themes", "look", "style", "redesign", "aesthetic", "estetica", "tema", "temas", "preajuste"] },
        { section: "appearance", group: "Presets", label: "Take only their colours", tune: true, description: "Themes change your colours only, not shapes, layout or motion.", path: "iris.appearance.themeColoursOnly", kind: "switch", fallback: false, keywords: ["theme", "colours", "colors", "palette", "only", "tema", "colores"] },
        { section: "appearance", group: "Customize", label: "Customize opens", description: "On the shell edits in place; Studio is a side panel with search.", path: "iris.appearance.customize", kind: "choice", tune: true, fallback: "shell", choices: [{ label: "On the shell", value: "shell", glyph: "touch_app" }, { label: "Studio", value: "studio", glyph: "view_sidebar" }], keywords: ["studio", "customize", "editor", "panel", "look"] },
        { section: "appearance", group: "Previews", label: "Animated previews", description: "Live scenes in Settings and Customize.", path: "iris.appearance.previews", kind: "switch", tune: true, fallback: true },
        { section: "spotlight", group: "Spotlight", label: "Spotlight", path: "iris.modules.palette", kind: "switch", fallback:true },
        { section: "spotlight", group: "Spotlight", label: "Maximum results", path: "iris.palette.maxResults", kind: "range", fallback:8,min:3,max:14 },
        { section: "spotlight", group: "Clipboard", label: "Entries shown", description: "How many recent copies Spotlight lists first; scroll or keep pressing Down to go through the whole history. Type ; to open it.", path: "iris.palette.clipboardResults", kind: "range", fallback: 8, min: 3, max: 20, keywords: ["clipboard", "history", "copy", "paste", "cliphist", "portapapeles", "entries", "limit"] },
        { section: "spotlight", group: "Spotlight", label: "Search mode shortcuts", tune: true, description: "Clipboard, calculator, actions and more under the suggestions.", path: "iris.palette.showHints", kind: "switch", fallback:true },
        { section: "orbit", group: "Orbit", label: "Orbit", description: "Every workspace with its windows where they are, and a search that finds any of them.", path: "iris.orbit.enable", kind: "switch", fallback: false, keywords: ["workspaces", "windows", "task view", "overview", "switcher", "expose", "mission control"] },
        { section: "orbit", group: "Orbit", label: "Opens as", description: "The Island grows into it, or a sheet opens under the Island.", path: "iris.orbit.opens", kind: "choice", fallback: "island", choices: [{label:"The Island",value:"island",glyph:"pill"},{label:"A sheet",value:"floating",glyph:"web_asset"}], visibleWhen: "iris.orbit.enable" },
        { section: "orbit", group: "Orbit", label: "Window pictures", description: "What each window looks like, from a screenshot of it. Off shows app icons and takes no screenshots.", path: "iris.orbit.previews", kind: "switch", fallback: true, visibleWhen: "iris.orbit.enable", keywords: ["preview", "screenshot", "thumbnail", "capture"] },
        { section: "orbit", group: "Orbit", label: "Picture age", description: "How old the picture of the workspace you are on may be before Orbit takes a new one.", path: "iris.orbit.previewAge", kind: "range", fallback: 10, min: 2, max: 120, step: 1, unit: " s", visibleWhen: "iris.orbit.previews" },
        { section: "orbit", group: "Size", label: "Width", path: "iris.orbit.width", kind: "range", fallback: 1100, min: 640, max: 1600, step: 20, unit: " px", visibleWhen: "iris.orbit.enable" },
        { section: "orbit", group: "Size", label: "Workspace height", description: "The tallest the workspace you are on gets.", path: "iris.orbit.cardHeight", kind: "range", fallback: 440, min: 200, max: 720, step: 10, unit: " px", visibleWhen: "iris.orbit.enable" },
        { section: "orbit", group: "Size", label: "Neighbours", description: "How much of the workspaces above and below shows.", path: "iris.orbit.peek", kind: "range", fallback: 56, min: 0, max: 140, step: 4, unit: " px", zeroLabel: "Hidden", visibleWhen: "iris.orbit.enable" },
        { section: "orbit", group: "Look", label: "Wallpaper on the workspaces", path: "iris.orbit.wallpaper", kind: "switch", fallback: true, visibleWhen: "iris.orbit.enable" },
        { section: "orbit", group: "Look", label: "Window titles", description: "On the window under the cursor, on every window, or never.", path: "iris.orbit.titles", kind: "choice", fallback: "hover", choices: [{label:"Under the cursor",value:"hover",glyph:"ads_click"},{label:"Always",value:"always",glyph:"title"},{label:"Never",value:"off",glyph:"visibility_off"}], visibleWhen: "iris.orbit.enable" },
        { section: "orbit", group: "Look", label: "Workspace names", path: "iris.orbit.labels", tune: true, kind: "choice", fallback: "full", choices: [{label:"Number and name",value:"full",glyph:"label"},{label:"Number only",value:"number",glyph:"pin"}], visibleWhen: "iris.orbit.enable" },
        { section: "orbit", group: "Look", label: "Fade what doesn't match", description: "How far the windows that don't match your search fall back.", path: "iris.orbit.dimMatches", kind: "range", fallback: 78, min: 0, max: 95, step: 1, unit: " %", visibleWhen: "iris.orbit.enable" },
        { section: "orbit", group: "Look", label: "Key hints", description: "A quiet line at the bottom with the keys.", path: "iris.orbit.hints", tune: true, kind: "switch", fallback: true, visibleWhen: "iris.orbit.enable" },
        { section: "orbit", group: "Shelf", label: "Recent windows", description: "The windows you were in before this one.", path: "iris.orbit.showRecent", kind: "switch", fallback: true, visibleWhen: "iris.orbit.enable" },
        { section: "orbit", group: "Shelf", label: "How many", path: "iris.orbit.recentCount", kind: "range", fallback: 5, min: 2, max: 8, step: 1, visibleWhen: "iris.orbit.showRecent" },
        { section: "orbit", group: "Shelf", label: "Set-aside windows", description: "Windows you minimised, ready to bring back.", path: "iris.orbit.showMinimised", kind: "switch", fallback: true, visibleWhen: "iris.orbit.enable", keywords: ["minimised", "minimized", "stash", "pocket"] },
        { section: "orbit", group: "Shelf", label: "Window actions", description: "Go, send to another workspace, set aside, float and close, for the window under the cursor.", path: "iris.orbit.showActions", kind: "switch", fallback: true, visibleWhen: "iris.orbit.enable" },
        { section: "orbit", group: "Shelf", label: "Thumbnail size", path: "iris.orbit.thumbSize", kind: "range", fallback: 88, min: 64, max: 160, step: 4, unit: " px", visibleWhen: "iris.orbit.enable" },
        { section: "orbit", group: "Behaviour", label: "Close after going", description: "Off keeps Orbit open after you pick a window.", path: "iris.orbit.closeOnGo", kind: "switch", fallback: true, visibleWhen: "iris.orbit.enable" },
        { section: "orbit", group: "Behaviour", label: "Scroll changes workspace", path: "iris.orbit.scroll", tune: true, kind: "switch", fallback: true, visibleWhen: "iris.orbit.enable" },
        { section: "orbit", group: "Behaviour", label: "Ask Spotlight when nothing matches", description: "↵ on a search with no window hands it to Spotlight.", path: "iris.orbit.askSpotlight", tune: true, kind: "switch", fallback: true, visibleWhen: "iris.orbit.enable" },
        { section: "orbit", group: "Behaviour", label: "Bring windows back to", description: "Where a set-aside window returns to: the workspace it left, or the one you are on.", path: "iris.orbit.stashRestore", kind: "choice", fallback: "original", choices: [{label:"Where it was",value:"original",glyph:"undo"},{label:"Where I am",value:"current",glyph:"my_location"}], visibleWhen: "iris.orbit.showMinimised" },
        { section: "orbit", group: "Behaviour", label: "Arrow keys", description: "Up and down change workspace, left and right change window.", path: "iris.orbit.keys", tune: true, kind: "choice", fallback: "niri", choices: [{label:"Niri",value:"niri",glyph:"swap_vert"},{label:"Swapped",value:"swapped",glyph:"swap_horiz"}], visibleWhen: "iris.orbit.enable" },
        { section: "orbit", group: "Hot corner", label: "Hot corner", description: "Rest the pointer in a corner of the screen and Orbit opens.", path: "iris.orbit.hotCorner", kind: "switch", fallback: true, visibleWhen: "iris.orbit.enable", keywords: ["corner", "pointer", "mouse", "gesture", "open"] },
        { section: "orbit", group: "Hot corner", label: "Corner", description: "Auto picks a free one: a corner your screen's own hot corners leave free and where none of your pieces sits. Those corners are never taken.", path: "iris.orbit.hotCornerAt", kind: "choice", fallback: "auto", choices: [{label:"Auto",value:"auto",glyph:"auto_awesome"},{label:"Top left",value:"topLeft",glyph:"north_west"},{label:"Top right",value:"topRight",glyph:"north_east"},{label:"Bottom left",value:"bottomLeft",glyph:"south_west"},{label:"Bottom right",value:"bottomRight",glyph:"south_east"}], visibleWhen: "iris.orbit.hotCorner" },
        { section: "orbit", group: "Hot corner", label: "Corner size", path: "iris.orbit.hotCornerSize", kind: "range", fallback: 12, min: 4, max: 40, step: 2, unit: " px", visibleWhen: "iris.orbit.hotCorner" },
        { section: "orbit", group: "Hot corner", label: "Wait before opening", description: "How long the pointer rests in the corner.", path: "iris.orbit.hotCornerDelay", kind: "range", fallback: 150, min: 0, max: 600, step: 10, unit: " ms", zeroLabel: "At once", visibleWhen: "iris.orbit.hotCorner" },
        { section: "controlCenter", group: "Control Center", label: "Control Center", path: "iris.modules.controlCenter", kind: "switch", fallback:true },
        { section: "bubbles", group: "Tray", label: "Bubble shows", description: "Apps turns the bubble into the tray itself: every app is a disc you can click, right-click or scroll.", path: "iris.tray.face", kind: "choice", fallback: "apps", choices: [{label:"Apps",value:"apps",glyph:"apps"},{label:"Count",value:"count",glyph:"tag"}], keywords: ["tray", "icons", "background apps", "bubble", "count", "number", "system tray"] },
        { section: "bubbles", group: "Tray", label: "App names", tune: true, path: "iris.tray.labels", kind: "switch", fallback:true },
        { section: "bubbles", group: "Tray", label: "Hide passive apps", tune: true, path: "iris.tray.hidePassive", kind: "switch", fallback:false },
        { section: "bubbles", group: "Tray", label: "Columns", path: "iris.tray.columns", kind: "range", fallback:4,min:2,max:6 },
        { section: "desktop", group: "Wallpaper shuffle", label: "Shuffle wallpapers", description: "A new wallpaper from your folder every few minutes.", path: "background.autoWallpaper.enable", kind: "switch", fallback: false, keywords: ["shuffle", "random", "slideshow", "rotate", "cycle", "change", "automatic", "timer", "next wallpaper"] },
        { section: "desktop", group: "Wallpaper shuffle", label: "Every", path: "background.autoWallpaper.intervalMinutes", visibleWhen: "background.autoWallpaper.enable", kind: "range", fallback: 30, min: 1, max: 240, step: 1, unit: " min", keywords: ["interval", "minutes", "how often", "slideshow"] },
        { tune: true, section: "desktop", group: "Wallpaper shuffle", label: "Colours follow", description: "Each new wallpaper recolours the shell and your apps. Off keeps the current colours.", path: "background.autoWallpaper.generateColors", visibleWhen: "background.autoWallpaper.enable", kind: "switch", fallback: true, keywords: ["colors", "theme", "recolor", "palette"] },
        { tune: true, section: "desktop", group: "Wallpaper shuffle", label: "From the folder", description: "Where shuffle picks from.", path: "background.autoWallpaper.folder", visibleWhen: "background.autoWallpaper.enable", kind: "text", placeholder: "The current wallpaper's folder", fallback: "", keywords: ["shuffle", "folder", "slideshow"] },
        // Transition and Library run under iRiS too: awww draws every still wallpaper, and the shared desktop (widgets on) runs the shader ones.
        { section: "wallpaper", group: "Transition", label: "Animate the change", master: true, description: "The next wallpaper arrives with a movement instead of a cut.", path: "background.transition.enable", kind: "switch", fallback: true, keywords: ["transition", "animation", "fade", "wipe", "shader", "transición"] },
        { section: "wallpaper", group: "Transition", label: "Style", tune: true, path: "background.transition.type", visibleWhen: "background.transition.enable", kind: "choice", fallback: "random", choices: [
            {label:"None",value:"none",glyph:"block"},
            {label:"Fade",value:"crossfade",glyph:"motion_photos_on"},
            {label:"Simple",value:"simple",glyph:"transition_fade"},
            {label:"From left",value:"left",glyph:"west"},
            {label:"From right",value:"right",glyph:"east"},
            {label:"From top",value:"top",glyph:"north"},
            {label:"From bottom",value:"bottom",glyph:"south"},
            {label:"Wipe",value:"wipe",glyph:"left_panel_open"},
            {label:"Wave",value:"wave",glyph:"water"},
            {label:"Grow",value:"grow",glyph:"filter_center_focus"},
            {label:"Center",value:"center",glyph:"center_focus_strong"},
            {label:"Any",value:"any",glyph:"shuffle"},
            {label:"Outer",value:"outer",glyph:"blur_circular"},
            {label:"Random",value:"random",glyph:"casino"},
            {label:"Circle shader",value:"circleSelect",glyph:"circle"},
            {label:"Circle pit",value:"circlePit",glyph:"blur_circular"},
            {label:"Magic",value:"magic",glyph:"auto_awesome"},
            {label:"Doom",value:"Doom",glyph:"whatshot"},
            {label:"Peel",value:"Peel",glyph:"layers"},
            {label:"Shader fade",value:"transition",glyph:"gradient"},
            {label:"Pixelate",value:"pixelate",glyph:"grain"},
            {label:"Stripes",value:"stripes",glyph:"texture_minus"},
            {label:"CRT",value:"crt",glyph:"tv"},
            {label:"Dissolve",value:"dissolve",glyph:"blur_on"},
            {label:"Glitch",value:"glitch",glyph:"bug_report"},
            {label:"Ripple",value:"ripple",glyph:"water"},
            {label:"Shatter",value:"shatter",glyph:"broken_image"},
            {label:"iNiR Melt",value:"inirMelt",glyph:"waterfall_chart"},
            {label:"Chromatic Veil",value:"inirVeil",glyph:"gradient"},
            {label:"Glass Fracture",value:"inirFracture",glyph:"deployed_code"},
            {label:"Sumi Wash",value:"inirInk",glyph:"ink_highlighter"},
            {label:"Prism Slices",value:"inirPrism",glyph:"view_column_2"},
            {label:"Random shader",value:"shaderRandom",glyph:"shuffle"}], keywords: ["fade", "wipe", "wave", "grow", "shader", "melt", "glitch", "pixelate", "dissolve"] },
        { section: "wallpaper", group: "Transition", label: "From", showIf: () => (Config.options?.background?.transition?.enable ?? true) && ["wipe", "wave"].includes(String(Config.options?.background?.transition?.type ?? "crossfade")), path: "background.transition.direction", kind: "choice", fallback: "right", choices: [{label:"Left",value:"left",glyph:"west"},{label:"Right",value:"right",glyph:"east"},{label:"Top",value:"top",glyph:"north"},{label:"Bottom",value:"bottom",glyph:"south"}] },
        { section: "wallpaper", group: "Transition", label: "Duration", showIf: () => (Config.options?.background?.transition?.enable ?? true) && !["simple", "none"].includes(String(Config.options?.background?.transition?.type ?? "crossfade")), path: "background.transition.duration", kind: "range", fallback: 800, min: 200, max: 3000, step: 100, unit: " ms", tune: true },
        { section: "wallpaper", group: "Transition", label: "Frames per second", description: "How smoothly the movement is drawn.", showIf: () => (Config.options?.background?.transition?.enable ?? true) && (Config.options?.background?.backend?.provider ?? "awww") === "awww" && AwwwBackend.available, path: "background.backend.awww.transitionFps", kind: "range", fallback: 60, min: 10, max: 240, step: 5 },
        { section: "wallpaper", group: "Transition", label: "Dissolve step", description: "Higher finishes Simple sooner, in coarser steps.", showIf: () => (Config.options?.background?.transition?.enable ?? true) && String(Config.options?.background?.transition?.type ?? "") === "simple" && AwwwBackend.available, path: "background.backend.awww.simpleStep", kind: "range", fallback: 5, min: 1, max: 64, step: 1 },
        { section: "wallpaper", group: "Transition", label: "Sweep step", description: "Higher moves wipes, waves and circles in coarser steps.", showIf: () => (Config.options?.background?.transition?.enable ?? true) && !AwwwBackend.isInternalShaderTransitionType(Config.options?.background?.transition?.type ?? "crossfade") && !["simple", "none"].includes(String(Config.options?.background?.transition?.type ?? "crossfade")) && AwwwBackend.available, path: "background.backend.awww.spatialStep", kind: "range", fallback: 30, min: 1, max: 128, step: 1 },
        { section: "wallpaper", group: "Library", label: "Wallpapers folder", description: "Where the gallery and shuffle look first.", path: "wallpapers.directory", kind: "text", placeholder: "~/Pictures/Wallpapers", fallback: "", keywords: ["folder", "directory", "path", "carpeta"] },
        { section: "wallpaper", group: "Library", label: "A wallpaper per screen", description: "Each screen keeps its own; the gallery asks which screen it is for.", path: "background.multiMonitor.enable", kind: "switch", fallback: false, keywords: ["monitor", "screen", "multi", "per output", "pantalla"] },
        { section: "wallpaper", group: "Library", label: "Small wallpaper notice", tune: true, description: "A notification when a wallpaper is smaller than your screen, with a link to upscale it.", path: "background.hideUpscaleNotification", invert: true, summary: false, kind: "switch", fallback: false, keywords: ["upscale", "resolution", "upscayl"] },
        { section: "wallpaper", group: "Library", label: "Renderer", description: "Interactive web plays a page or WebGL scene as the wallpaper.", path: "background.backend.provider", kind: "choice", fallback: "awww", tune: true, choices: [{label:"Standard",value:"awww",glyph:"image"},{label:"Interactive web",value:"web",glyph:"language"}], keywords: ["awww", "web", "html", "webgl", "backend", "renderer"] },
        { section: "wallpaper", group: "Library", label: "Web page", description: "A local HTML file or a web address.", path: "background.backend.web.source", visibleWhen: "background.backend.provider=web", kind: "text", placeholder: "~/index.html  ·  https://…", fallback: "", tune: true },
        { section: "wallpaper", group: "Library", label: "Takes clicks and keys", description: "Games and interactive pages get the pointer; the bar and dock stay above.", path: "background.backend.web.interactive", visibleWhen: "background.backend.provider=web", kind: "switch", fallback: false, tune: true },
        { section: "desktop", group: "Wallpaper gallery", label: "Picker", description: "Which picker opens for wallpapers.", bundle: ["iris.wallpaper.picker", "wallpaperSelector.style"], kind: "choice", fallback: "iris", choices: [{label:"Gallery",value:"iris",glyph:"auto_awesome",values:["iris","grid"],detail:"iRiS's gallery, grown out of the Island."},{label:"Grid",value:"grid",glyph:"grid_view",values:["material","grid"],detail:"Material's grid, opened the same way."},{label:"Coverflow",value:"coverflow",glyph:"view_carousel",values:["material","coverflow"],detail:"Material's coverflow, opened the same way."},{label:"Launcher",value:"launcher",glyph:"view_agenda",values:["material","launcher"],detail:"Material's launcher, opened the same way."}], keywords: ["picker", "selector", "wallpaper", "material", "grid", "coverflow", "launcher", "gallery", "fondo", "selector de fondos"] },
        { section: "desktop", group: "Wallpaper gallery", showIf: () => root.ownGallery(), label: "Preview on the desktop", tune: true, description: "The highlighted wallpaper shows behind the gallery; closing without applying restores yours.", path: "iris.wallpaper.livePreview", kind: "switch", fallback: true },
        { tune: true, section: "desktop", group: "Wallpaper gallery", showIf: () => root.ownGallery(), label: "Play previews", description: "Live wallpapers play a muted preview while chosen or hovered in the gallery.", path: "iris.wallpaper.motion", kind: "switch", fallback: true },
        { tune: true, section: "desktop", group: "Wallpaper gallery", showIf: () => root.ownGallery(), label: "Library order", description: "How your folders line up in the gallery.", path: "iris.wallpaper.sort", kind: "choice", fallback: "newest", choices: [{label:"Newest",value:"newest",glyph:"schedule"},{label:"Oldest",value:"oldest",glyph:"history"},{label:"Name",value:"name",glyph:"sort_by_alpha"}], keywords: ["sort", "order", "date", "recent", "newest", "oldest", "name", "alphabetical"] },
        { tune: true, section: "desktop", group: "Wallpaper gallery", showIf: () => root.ownGallery(), label: "Online order", description: "What the online gallery shows first. Trending, Most viewed and Most liked are Wallhaven's.", path: "iris.wallpaper.onlineSort", kind: "choice", fallback: "top", choices: [{label:"Top rated",value:"top",glyph:"trending_up"},{label:"Trending",value:"hot",glyph:"local_fire_department"},{label:"Newest",value:"newest",glyph:"schedule"},{label:"Most viewed",value:"views",glyph:"visibility"},{label:"Most liked",value:"favorites",glyph:"favorite"},{label:"Random",value:"random",glyph:"shuffle"}], keywords: ["sort", "order", "top", "hot", "popular", "toplist", "newest", "latest", "views", "favourites", "liked", "random", "wallhaven", "konachan", "yande.re"] },
        { tune: true, section: "desktop", group: "Wallpaper gallery", showIf: () => root.ownGallery(), label: "Shape", description: "What the web is asked for.", path: "iris.wallpaper.ratio", kind: "choice", fallback: "screen", choices: [{label:"Your screen",value:"screen",glyph:"desktop_windows",detail:"Wallpapers that fit your screen."},{label:"Wide",value:"wide",glyph:"crop_landscape",detail:"Any wide one."},{label:"Portrait",value:"portrait",glyph:"crop_portrait",detail:"Tall ones, for a vertical screen."},{label:"Any",value:"any",glyph:"aspect_ratio",detail:"Anything."}], keywords: ["ratio", "aspect", "portrait", "landscape", "vertical", "resolution", "fit", "screen"] },
        { tune: true, section: "desktop", group: "Wallpaper gallery", showIf: () => root.ownGallery(), label: "Top of the", description: "How far back Top looks on Wallhaven, Konachan and yande.re.", path: "iris.wallpaper.topRange", visibleWhen: "iris.wallpaper.onlineSort=top", kind: "choice", fallback: "1w", choices: [{label:"Day",value:"1d"},{label:"Week",value:"1w"},{label:"Month",value:"1M"},{label:"Year",value:"1y"}], keywords: ["top", "weekly", "monthly", "daily", "yearly", "day", "week", "month", "year", "period", "range", "toplist"] },
        { section: "desktop", group: "Wallpaper gallery", showIf: () => root.ownGallery(), label: "Online sources", tune: true, description: "Where the gallery looks beyond your folders, in the order you turn them on. Konachan and yande.re lean to fan service even when rated safe.", path: "iris.wallpaper.sources", kind: "pieces", fallback: ["wallhaven", "live"], choices: [{label:"Wallhaven",value:"wallhaven"},{label:"Live",value:"live"},{label:"Konachan",value:"konachan"},{label:"yande.re",value:"yandere"}], keywords: ["source", "provider", "wallhaven", "konachan", "yande.re", "yandere", "motionbgs", "live", "online", "booru", "download"] },
        { tune: true, section: "desktop", group: "Wallpaper gallery", showIf: () => root.ownGallery(), label: "Suggestive art", description: "Off keeps swimsuits, lingerie and fan service out of online results.", path: "iris.wallpaper.suggestive", kind: "switch", fallback: false, keywords: ["nsfw", "sfw", "safe", "ecchi", "fan service", "suggestive", "filter", "family", "work", "adult", "content"] },
        { tune: true, section: "desktop", group: "Wallpaper gallery", showIf: () => root.ownGallery(), label: "Live wallpaper downloads", description: "Which file a live wallpaper downloads.", path: "iris.wallpaper.liveQuality", kind: "choice", fallback: "best", choices: [{label:"Best",value:"best",detail:"The 4K file, played as a copy sized to your screen; the HD files are heavily compressed."},{label:"Light",value:"light",detail:"HD: a fifth of the download, visibly softer."}], keywords: ["4k", "hd", "quality", "resolution", "video", "motionbgs"] },
        { section: "desktop", group: "Live wallpapers", label: "Animate on the desktop", description: "Video and GIF wallpapers move.", path: "background.enableAnimation", kind: "switch", fallback: true },
        { section: "desktop", group: "Live wallpapers", label: "Pause", tune: true, description: "A hidden wallpaper stops decoding and keeps its frame.", path: "background.videoPause", kind: "choice", fallback: "covered", choices: [{label:"Never",value:"never",glyph:"play_arrow"},{label:"Behind fullscreen",value:"fullscreen",glyph:"fullscreen"},{label:"When covered",value:"covered",glyph:"view_column"}] },
        { tune: true, section: "desktop", group: "Live wallpapers", label: "Pause on battery", path: "background.pauseAnimationOnBattery", kind: "switch", fallback: true },
        { tune: true, section: "desktop", group: "Live wallpapers", label: "Animate on the lock screen", description: "Plays on the lock screen too, blurred or not.", path: "lock.enableAnimation", kind: "switch", fallback: false },
        { section: "desktop", group: "Glyph art", label: "Draw the wallpaper as glyphs", description: "Pictures, GIFs and videos are redrawn as glowing characters.", path: "background.effects.glyphs.enable", kind: "switch", fallback: false, keywords: ["ascii", "glyph", "afterglyph", "characters", "text art", "terminal", "retro", "crt", "matrix", "caracteres", "letras"] },
        { section: "notifications", group: "Banners", label: "Notification banners", path: "iris.modules.notificationPopup", kind: "switch", fallback:true },
        { section: "notifications", group: "Banners", label: "Banner duration", description: "How long a notification stays when the app does not choose.", path: "iris.notifications.duration", kind: "range", fallback:4000,min:2000,max:12000,step:500,scale:0.001,unit:" s" },
        { section: "sound", group: "Output", label: "Sound plays on", description: "Pick where the sound goes; the volume is the one in use.", kind: "list", view: Qt.resolvedUrl("IrisSoundDevices.qml"), input: false, summary: () => Audio.defaultSink ? Audio.friendlyDeviceName(Audio.defaultSink) : "", keywords: ["output", "device", "speakers", "headphones", "bluetooth", "volume", "salida", "parlantes", "altavoces", "auriculares"] },
        { section: "sound", group: "Input", label: "Microphone", description: "Pick the microphone apps hear; the level is the one in use.", kind: "list", view: Qt.resolvedUrl("IrisSoundDevices.qml"), input: true, summary: () => Audio.source ? Audio.friendlyDeviceName(Audio.source) : "", keywords: ["input", "microphone", "mic", "device", "entrada", "micrófono"] },
        { section: "sound", group: "Apps playing", label: "Volume per app", description: "Every app making sound now.", kind: "list", view: Qt.resolvedUrl("IrisSoundApps.qml"), summary: () => Audio.outputAppNodes.map(node => Audio.appNodeDisplayName(node)).join(", "), keywords: ["mixer", "apps", "per app", "volume", "app volume", "mezclador", "aplicaciones", "volumen"] },
        { section: "sound", group: "Feedback", label: "On-screen feedback", description: "Volume, brightness, song and keyboard changes show on the Island, or in a small pill when it is hidden.", path: "iris.modules.osd", kind: "switch", fallback:true, keywords: ["osd", "volume", "brightness", "popup", "indicator"] },
        { section: "sound", group: "Feedback", label: "Volume, brightness and mic", description: "When the Island shows a change of volume, brightness or mic.", path: "iris.osd.levels", visibleWhen: "iris.modules.osd", kind: "choice", fallback: "yours", choices: [{label:"Yours",value:"yours",glyph:"touch_app",detail:"What you change with keys, scrolling or sliders."},{label:"Every change",value:"every",glyph:"all_inclusive",detail:"Also apps and devices moving them, like voice chat adjusting the mic."},{label:"Never",value:"off",glyph:"block"}], keywords: ["osd", "volume", "brightness", "microphone", "mic", "level", "automatic"] },
        { section: "sound", group: "Feedback", label: "Song changes", tune: true, description: "When the Island shows the song.", path: "iris.osd.media", visibleWhen: "iris.modules.osd", kind: "choice", fallback: "yours", choices: [{label:"Yours",value:"yours",glyph:"touch_app",detail:"The song when you skip or pause."},{label:"Every change",value:"every",glyph:"all_inclusive",detail:"Also when the next one starts by itself."},{label:"Never",value:"off",glyph:"block"}], keywords: ["osd", "music", "track", "song", "now playing", "media", "next", "skip"] },
        { section: "sound", group: "Feedback", label: "Keyboard layout and locks", tune: true, path: "iris.osd.keyboard", visibleWhen: "iris.modules.osd", kind: "switch", fallback: true, keywords: ["osd", "caps lock", "num lock", "layout", "language", "keyboard"] },
        { section: "gaming", group: "Fullscreen", label: "Notification banners", description: "Over a fullscreen video or game.", path: "iris.notifications.fullscreen", visibleWhen: "iris.modules.notificationPopup", kind: "switch", fallback: true, keywords: ["fullscreen", "video", "movie", "banner", "notification"] },
        { section: "gaming", group: "Fullscreen", label: "Volume and song pill", description: "Quiet keeps volume, brightness and mic and drops songs and keyboard; Hidden shows nothing.", path: "iris.osd.fullscreen", visibleWhen: "iris.modules.osd", kind: "choice", fallback: "show", choices: [{label:"Everything",value:"show",glyph:"visibility"},{label:"Quiet",value:"quiet",glyph:"volume_down"},{label:"Hidden",value:"hide",glyph:"visibility_off"}], keywords: ["osd", "game", "gaming", "gamemode", "fullscreen", "video", "quiet"] },
        { section: "sound", group: "Volume", label: "Ear protection", description: "Holds back sudden jumps and keeps the volume under the limit.", path: "audio.protection.enable", kind: "switch", fallback: true, keywords: ["earbang", "volume", "limit", "loud", "hearing", "safety"] },
        { section: "sound", group: "Volume", label: "Largest jump", tune: true, description: "The most one change can raise the volume.", path: "audio.protection.maxAllowedIncrease", visibleWhen: "audio.protection.enable", kind: "range", fallback: 10, min: 2, max: 50, step: 2, unit: " %", keywords: ["earbang", "volume", "step"] },
        { section: "sound", group: "Volume", label: "Volume limit", tune: true, description: "Above 100 % amplifies the sound and can distort it; 153 % is as far as the system mixer goes.", path: "audio.protection.maxAllowed", visibleWhen: "audio.protection.enable", kind: "range", fallback: 100, min: 50, max: 154, step: 2, unit: " %", keywords: ["earbang", "volume", "limit", "boost", "amplify", "over 100", "150"] },
    ].concat(...["left", "right"].map(side => [
        { section: "sidebars", group: side === "left" ? "Focus" : "Today", label: "Enable panel", path: "iris.sidebars." + side + ".enable", kind: "switch", fallback:true,
            glance: on => {
                const count = (Config.options?.iris?.sidebars?.[side]?.sections ?? []).length
                return !on ? Translation.tr("Off") : count === 1 ? Translation.tr("One section") : Translation.tr("%1 sections").arg(count)
            } },
        { section: "sidebars", group: side === "left" ? "Focus" : "Today", label: "Sections", kind: "list", bare: true, side: side, view: Qt.resolvedUrl("../sidebar/IrisSidebarEditor.qml"),
            visibleWhen: "iris.sidebars." + side + ".enable", summary: false, keywords: ["sections", "cards", "order", "secciones", "tasks", "notes", "calendar", "weather", "mixer"] },
        { section: "sidebars", group: side === "left" ? "Focus" : "Today", label: "Width", path: "iris.sidebars." + side + ".width", kind: "range", fallback:380,min:300,max:600,step:10,unit:" px" },
        { section: "sidebars", group: side === "left" ? "Focus" : "Today", label: "Maximum height", description: "Panels hug their sections and grow up to this.", path: "iris.sidebars." + side + ".height", kind: "range", fallback:88,min:45,max:100,unit:" %" },
        { section: "sidebars", group: side === "left" ? "Focus" : "Today", label: "Alignment", path: "iris.sidebars." + side + ".alignment", kind: "choice", fallback:"center", choices:[{label:"Top",value:"top"},{label:"Center",value:"center"},{label:"Bottom",value:"bottom"}] },
        { section: "sidebars", group: side === "left" ? "Focus" : "Today", label: "Attach to the screen edge", tune: true, description: "Melts the panel into its edge, like a notch.", path: "iris.sidebars." + side + ".notch", kind: "switch", fallback:false, keywords: ["attach", "join", "frame", "edge", "notch", "float", "pegar"] },
        { section: "sidebars", group: side === "left" ? "Focus" : "Today", label: "Reveal on hover", description: side === "left" ? "Rest the pointer at the left edge to peek; click inside to keep it." : "Rest the pointer at the right edge to peek; click inside to keep it.", path: "iris.sidebars." + side + ".hoverReveal", kind: "switch", fallback:false },
        { section: "sidebars", group: side === "left" ? "Focus" : "Today", label: "Keep open", description: "Stay visible while working in other windows.", path: "iris.sidebars." + side + ".pinned", kind: "switch", fallback:false },
        { section: "sidebars", group: side === "left" ? "Focus" : "Today", label: "Reserve space for windows", description: "Keep tiled windows clear while this panel is kept open.", path: "iris.sidebars." + side + ".reserveSpace", visibleWhen: "iris.sidebars." + side + ".pinned", kind: "switch", fallback:true, keywords: ["reserve", "space", "windows", "exclusive", "margin", "espacio", "reservar"] },
        { section: "sidebars", group: side === "left" ? "Focus" : "Today", label: side === "left" ? "Open Focus" : "Open Today", kind: "action", button: "Open", tune: true,
            run: () => { GlobalStates.settingsOverlayOpen = false; if (side === "left") GlobalStates.openSidebarLeft(""); else GlobalStates.openSidebarRight("") } }
    ])))

    readonly property var idleChoices: [
        { label: "Never", value: 0 }, { label: "1 min", value: 60 }, { label: "2 min", value: 120 },
        { label: "5 min", value: 300 }, { label: "10 min", value: 600 }, { label: "15 min", value: 900 },
        { label: "30 min", value: 1800 }, { label: "1 hour", value: 3600 }
    ]
    // Shared iNiR keys an iRiS surface acts on, so they are set where iRiS shows them. Material and
    // Waffle read the same keys; nothing here is copied.
    readonly property var shared: [
        // Ported from More Settings › Services (2026-10-11): what an iRiS surface really reads, said where it shows.
        { section: "battery", group: "Warnings", label: "Charged notice", description: "Says when the battery reaches this level, so you can unplug.", path: "battery.full", kind: "choice", fallback: 101, choices: [{label:"Never",value:101},{label:"80%",value:80},{label:"90%",value:90},{label:"Full",value:100}], keywords: ["full", "charged", "unplug", "battery"] },
        { section: "lock", group: "Security", label: "Lock when the session starts", description: "Locks right after you sign in, for computers that log in on their own.", path: "lock.launchOnStartup", kind: "switch", fallback: false, keywords: ["autologin", "startup", "boot", "lock"] },
        { section: "lock", group: "Security", label: "Lock with Hyprlock", description: "Hyprlock and its own look lock the screen instead of iRiS's lock screen.", path: "lock.useHyprlock", kind: "switch", tune: true, fallback: false, keywords: ["hyprlock", "lock"] },
        { section: "spotlight", group: "Spotlight", label: "Forgive typos", tune: true, description: "Ranks apps by how few letters differ, so “firefx” still finds Firefox.", path: "search.sloppy", kind: "switch", fallback: false, keywords: ["fuzzy", "typo", "levenshtein", "search"] },
        { section: "spotlight", group: "Prefixes", label: "Clipboard", description: "Typed first, searches what you copied.", path: "search.prefix.clipboard", tune: true, kind: "text", short: true, placeholder: ";", fallback: ";", keywords: ["prefix", "clipboard"] },
        { section: "spotlight", group: "Prefixes", label: "Calculator", description: "Typed first, works out the rest.", path: "search.prefix.math", tune: true, kind: "text", short: true, placeholder: "=", fallback: "=", keywords: ["prefix", "math", "calculator"] },
        { section: "spotlight", group: "Prefixes", label: "Actions", description: "Typed first, lists switches, themes and commands.", path: "search.prefix.action", tune: true, kind: "text", short: true, placeholder: "/", fallback: "/", keywords: ["prefix", "actions"] },
        { section: "spotlight", group: "Prefixes", label: "Emoji", description: "Typed first, finds an emoji to copy.", path: "search.prefix.emojis", tune: true, kind: "text", short: true, placeholder: ":", fallback: ":", keywords: ["prefix", "emoji"] },
        { section: "spotlight", group: "Prefixes", label: "Command", description: "Typed first, runs the rest in your terminal.", path: "search.prefix.shellCommand", tune: true, kind: "text", short: true, placeholder: "$", fallback: "$", keywords: ["prefix", "shell", "command"] },
        { section: "spotlight", group: "Prefixes", label: "Web", description: "Typed first, searches the web.", path: "search.prefix.webSearch", tune: true, kind: "text", short: true, placeholder: "?", fallback: "?", keywords: ["prefix", "web"] },
        { section: "spotlight", group: "Prefixes", label: "Apps only", description: "Typed first, leaves out everything but apps.", path: "search.prefix.app", tune: true, kind: "text", short: true, placeholder: ">", fallback: ">", keywords: ["prefix", "apps"] },
        { section: "player", group: "Name song", label: "Listen for up to", description: "How long Name song listens before it gives up.", path: "musicRecognition.timeout", kind: "range", fallback: 16, min: 10, max: 100, step: 2, unit: " s", keywords: ["recognition", "shazam", "song", "identify"] },
        { section: "player", group: "Name song", label: "Ask every", description: "How often it checks what it has heard so far.", path: "musicRecognition.interval", kind: "range", fallback: 4, min: 2, max: 10, unit: " s", keywords: ["recognition", "song"] },
        { tune: true, section: "sources", group: "Updates", label: "Update command", description: "What the Updates bubble runs in your terminal.", path: "apps.update", kind: "text", placeholder: "yay -Syu", fallback: "", keywords: ["update", "upgrade", "command", "packages"] },
        { section: "sources", group: "New iNiR", label: "Update in a terminal", description: "Opens a terminal for the update, so you can watch it run.", path: "shellUpdates.openTerminalOnUpdate", visibleWhen: "shellUpdates.enabled", kind: "switch", fallback: true, keywords: ["update", "terminal"] },
        { section: "sources", group: "System readings", label: "Read every", description: "How often CPU, memory, disk and temperatures refresh wherever iRiS shows them.", path: "resources.updateInterval", kind: "range", fallback: 3000, min: 500, max: 10000, step: 250, unit: " ms", keywords: ["cpu", "memory", "ram", "vitals", "resources", "polling"] },
        { section: "sources", group: "System readings", label: "Read the GPU", description: "Adds the graphics card to what Vitals shows.", path: "resources.monitorGpu", kind: "switch", fallback: true, keywords: ["gpu", "graphics", "vitals"] },
        { section: "general", group: "Language & time", label: "Clock", description: "The Island, the lock screen and every clock in iRiS.", path: "time.format", kind: "choice", fallback: "hh:mm", choices: [{label:"24-hour",value:"hh:mm"},{label:"12-hour",value:"h:mm ap"},{label:"12-hour AM/PM",value:"h:mm AP"}], keywords: ["time", "hour", "24", "12", "am", "pm", "hora"] },
        { section: "general", group: "Language & time", label: "Exact seconds", description: "Clocks that show seconds tick on the second.", path: "time.secondPrecision", kind: "switch", tune: true, fallback: false },
        { section: "general", group: "Language & time", label: "Language", description: "Every label in the shell.", path: "language.ui", kind: "choice", fallback: "auto",
            choices: [{ label: "System", value: "auto" }].concat(Translation.allAvailableLanguages.map(code => ({ label: Translation.languageDisplayName(code), value: code }))),
            keywords: ["language", "idioma", "translation", "locale", "español", "spanish"] },
        { section: "general", group: "Apps & login", label: "Starts with you", description: "Apps and commands your compositor opens when you sign in.", kind: "list", view: Qt.resolvedUrl("IrisAutostartList.qml"), summary: false, keywords: ["autostart", "startup", "login", "boot", "launch", "spawn", "discord", "steam", "telegram", "inicio", "arranque"] },
        { section: "general", group: "Apps & login", label: "Startup file", description: "The compositor's file these lines live in, for the ones written by hand.", kind: "action", button: "Open", run: () => Quickshell.execDetached(["xdg-open", Autostart.startupFilePath]), showIf: () => Autostart.isNiri && Autostart.startupFilePath.length > 0, tune: true, keywords: ["startup", "niri", "config", "kdl", "file"] },
        { section: "general", group: "Apps & login", label: "Terminal", description: "Where Spotlight's commands, package installs and anime playback open.", path: "apps.terminal", kind: "text", placeholder: "kitty", fallback: "kitty", keywords: ["terminal", "kitty", "foot", "alacritty", "ghostty", "wezterm", "default apps"] },
        { section: "general", group: "Settings window", label: "Prism", description: "The Settings iRiS opens by default: every page in one panel, what it holds over a beam of light.", kind: "action", button: "Open Prism", run: () => { Config.setNestedValues({ "iris.appearance.settingsPanel": "prism", "iris.appearance.settingsOriginal": false }) }, keywords: ["prism", "settings", "new", "design", "layout", "back", "nuevo", "diseño", "volver"] },
        { section: "general", group: "Settings window", label: "Side column", description: "Your profile, what you changed and what is playing, beside the page. Automatic shows it on Home and wherever there is room, and gives the page its width everywhere else.", path: "iris.appearance.settingsRail", kind: "choice", tune: true, fallback: "auto", visibleWhen: "iris.appearance.settingsPanel=prism", choices: [{ label: "Automatic", value: "auto", glyph: "auto_awesome" }, { label: "Always", value: "open", glyph: "right_panel_open" }, { label: "Never", value: "closed", glyph: "right_panel_close" }], keywords: ["rail", "sidebar", "right", "column", "changes", "now playing", "hide", "fold", "columna", "derecha", "ocultar"] },
        { section: "general", group: "Settings window", label: "Opens as", description: "Over the desktop previews every change on the screen behind it.", path: "iris.appearance.settingsHost", kind: "choice", tune: true, fallback: "overlay", choices: [{ label: "Over the desktop", value: "overlay", glyph: "layers" }, { label: "Window", value: "window", glyph: "web_asset" }], keywords: ["settings", "window", "overlay", "floating", "tile", "maximize"] },
        { section: "general", group: "Settings window", label: "Layout", description: "How Settings lays out its areas.", path: "iris.appearance.settingsLayout", kind: "choice", tune: true, fallback: "classic", showIf: () => IrisDesign.skin("settingsPage").length === 0, choices: [{ label: "Classic", value: "classic", glyph: "view_sidebar", detail: "A sidebar of areas beside the page." }, { label: "Folio", value: "folio", glyph: "article", detail: "Reads like a page." }], keywords: ["settings", "layout", "classic", "sidebar", "folio", "deck", "console", "pliego", "baraja", "consola", "cards", "tiles"] },
        { section: "general", group: "Settings window", label: "Original design", description: "The Settings of v2.33 over every page and option of today: plated marks, an area's groups in one list, a sidebar without captions.", path: "iris.appearance.settingsOriginal", kind: "switch", tune: true, fallback: false, showIf: () => IrisDesign.skin("settingsPage").length === 0, keywords: ["settings", "design", "original", "old", "classic", "v2.33", "list", "tiles", "plates", "viejo", "anterior", "clásico", "lista", "diseño"] },
        { section: "general", group: "Shell", label: "Family", description: "The whole shell's look.", path: "panelFamily", kind: "choice", fallback: "ii", choices: [{label:"iRiS",value:"iris",glyph:"visibility"},{label:"Material",value:"ii",glyph:"dashboard"},{label:"Windows 11",value:"waffle",glyph:"window"}], keywords: ["family", "material", "waffle", "windows", "ii", "switch", "familia"] },
        { section: "general", group: "Shell", label: "Low power", description: "Turns glass, blur and heavy wallpaper effects off everywhere.", path: "performance.lowPower", kind: "switch", fallback: false, keywords: ["performance", "battery", "effects", "glass", "blur", "rendimiento"] },
        { section: "general", group: "Shell", label: "Switch shortcut goes through", description: "The families the switch keybind steps through, in the order you turn them on.", path: "familyCycle", kind: "pieces", tune: true, fallback: ["ii", "waffle", "iris"], choices: [{label:"iRiS",value:"iris"},{label:"Material",value:"ii"},{label:"Windows 11",value:"waffle"}], keywords: ["family", "cycle", "shortcut", "keybind", "switch"] },
        { section: "general", group: "Shell", label: "Animated switch", description: "A short transition while the families swap, instead of a cut.", path: "familyTransitionAnimation", kind: "switch", tune: true, fallback: true, keywords: ["family", "transition", "animation"] },

        { section: "spotlight", group: "Web search", label: "Search the web with", description: "What ? and Search the web use in Spotlight.", path: "search.engineBaseUrl", kind: "choice", fallback: "https://www.google.com/search?q=",
            choices: [{label:"Google",value:"https://www.google.com/search?q="},{label:"DuckDuckGo",value:"https://duckduckgo.com/?q="},{label:"Brave",value:"https://search.brave.com/search?q="},{label:"Bing",value:"https://www.bing.com/search?q="},{label:"Startpage",value:"https://www.startpage.com/do/search?q="}],
            keywords: ["search engine", "google", "duckduckgo", "brave", "bing", "startpage", "buscador"] },

        { section: "capture", group: "Snip", label: "Save screenshots to", description: "Empty uses Pictures/Screenshots.", path: "regionSelector.savePath", tune: true, kind: "text", placeholder: "~/Pictures/Screenshots", fallback: "", keywords: ["screenshot", "folder", "path"] },
        { section: "capture", group: "Read text", label: "Read text in", description: "The language Copy text recognises.", path: "regionSelector.ocrLanguage", kind: "choice", fallback: "auto",
            choices: [{label:"Auto",value:"auto"},{label:"English",value:"eng"},{label:"Spanish",value:"spa"},{label:"Russian",value:"rus"},{label:"Japanese",value:"jpn"},{label:"Japanese, vertical",value:"jpn_vert"},{label:"Chinese",value:"chi_sim"},{label:"Chinese, traditional",value:"chi_tra"},{label:"English + Spanish",value:"eng+spa"},{label:"Japanese + English",value:"jpn+eng"}],
            keywords: ["ocr", "tesseract", "text", "copy text", "texto"] },
        { section: "capture", group: "Recording", label: "Quality", description: "Small files, a balance, sharper, or near lossless and large.", kind: "choice", keyed: true,
            bundle: ["screenRecord.qualityPreset", "screenRecord.accelerationMode", "screenRecord.videoCodec", "screenRecord.audioCodec", "screenRecord.fps", "screenRecord.videoBitrateKbps", "screenRecord.audioBitrateKbps", "screenRecord.preset", "screenRecord.crf"],
            choices: [{ label: "Compact", value: "compact", values: ["compact", "auto", "libx264", "aac", 30, 6000, 128, "veryfast", 28] },
                { label: "Balanced", value: "balanced", values: ["balanced", "auto", "libx264", "aac", 60, 10000, 160, "veryfast", 23] },
                { label: "High", value: "quality", values: ["quality", "auto", "libx264", "aac", 60, 16000, 192, "medium", 18] },
                { label: "Master", value: "master", values: ["master", "auto", "libx264", "aac", 60, 28000, 256, "slow", 14] }],
            keywords: ["record", "video", "quality", "bitrate", "fps", "calidad"] },


        { section: "notifications", group: "Do Not Disturb", label: "Do Not Disturb", description: "Banners stay away; notifications still collect in Today.", path: "notifications.silent", kind: "switch", fallback: false, keywords: ["dnd", "silent", "focus", "quiet", "mute"] },
        { section: "notifications", group: "Do Not Disturb", label: "Quiet hours", description: "Do Not Disturb turns itself on every day between these times.", path: "notifications.quietHours.enable", kind: "switch", fallback: false, keywords: ["dnd", "night", "schedule"] },
        { section: "notifications", group: "Do Not Disturb", label: "From", path: "notifications.quietHours.start", visibleWhen: "notifications.quietHours.enable", kind: "text", placeholder: "22:00", fallback: "22:00" },
        { section: "notifications", group: "Do Not Disturb", label: "Until", path: "notifications.quietHours.end", visibleWhen: "notifications.quietHours.enable", kind: "text", placeholder: "08:00", fallback: "08:00" },
        { section: "notifications", group: "Banners", label: "Ignore how long apps ask", tune: true, description: "Every banner uses the duration above, even when the app picks its own.", path: "notifications.ignoreAppTimeout", kind: "switch", fallback: false },
        { section: "notifications", group: "Banners", label: "Urgent banners stay", description: "How long a critical notification stays.", path: "notifications.timeoutCritical", kind: "range", fallback: 0, min: 0, max: 60000, step: 5000, scale: 0.001, unit: " s", zeroLabel: "Until dismissed" },
        { section: "notifications", group: "Banners", label: "Longest a banner stays", description: "Even notifications that ask to stay forever leave the screen after this.", path: "notifications.maxPopupLifetime", kind: "range", fallback: 30000, min: 0, max: 120000, step: 5000, scale: 0.001, unit: " s", zeroLabel: "No limit" },
        { section: "notifications", group: "Sound", label: "Play a sound", path: "sounds.notifications", kind: "switch", fallback: true },
        { section: "notifications", group: "Apps", label: "Apps that notify", description: "Every app that sent you something.", kind: "list", view: Qt.resolvedUrl("IrisNotificationApps.qml"), summary: false, keywords: ["apps", "per app", "mute", "block", "quiet", "silence", "aplicaciones", "silenciar", "bloquear"] },

        { section: "sound", group: "Alert sounds", label: "Alert volume", description: "Notifications, timers and battery warnings.", path: "sounds.volume", kind: "range", fallback: 0.5, min: 0, max: 1, step: 0.05, scale: 100, unit: " %" },
        { section: "sound", group: "Alert sounds", label: "Timers", tune: true, path: "sounds.timer", kind: "switch", fallback: false },
        { section: "sound", group: "Alert sounds", label: "Focus sessions", tune: true, path: "sounds.pomodoro", kind: "switch", fallback: false, keywords: ["pomodoro"] },

        { section: "desktop", group: "Behind windows", label: "Blur the wallpaper", description: "While windows are open on the workspace; it comes back sharp when they leave.", path: "background.effects.enableBlur", kind: "switch", fallback: true, keywords: ["blur", "effects", "wallpaper", "desenfoque"] },
        { section: "desktop", group: "Behind windows", label: "Blur", path: "background.effects.blurRadius", visibleWhen: "background.effects.enableBlur", kind: "range", fallback: 22, min: 4, max: 80, step: 2, unit: " px" },
        { tune: true, section: "desktop", group: "Behind windows", label: "Blur live wallpapers too", description: "Video and GIF wallpapers cost more to blur.", path: "background.effects.enableAnimatedBlur", visibleWhen: "background.effects.enableBlur", kind: "switch", fallback: false },
        { section: "desktop", group: "Behind windows", label: "Dim with windows open", path: "background.effects.dynamicDim", kind: "range", fallback: 0, min: 0, max: 60, step: 5, unit: " %", zeroLabel: "Off" },
        { section: "desktop", group: "Behind windows", label: "Always dim", path: "background.effects.dim", kind: "range", fallback: 0, min: 0, max: 60, step: 5, unit: " %", zeroLabel: "Off" },
        { section: "desktop", group: "Scaling", label: "Scaling", description: "Fill crops, Fit shows bars, Span lays one picture across every screen.", path: "background.fillMode", kind: "choice", fallback: "fill", choices: [{label:"Fill",value:"fill",glyph:"crop"},{label:"Fit",value:"fit",glyph:"fit_screen"},{label:"Stretch",value:"stretch",glyph:"open_in_full"},{label:"Tile",value:"tile",glyph:"grid_view"},{label:"Center",value:"center",glyph:"center_focus_strong"},{label:"Span",value:"span",glyph:"panorama_wide_angle"}], keywords: ["fill", "fit", "stretch", "tile", "center", "span", "scale", "scaling", "zoom", "crop", "monitors", "screens", "ajustar", "estirar", "mosaico", "centrar", "extender"] },
        { section: "desktop", group: "Parallax", label: "Parallax", description: "The wallpaper drifts a little as you move between workspaces and columns.", path: "background.parallax.enable", visibleWhen: "background.fillMode=fill", kind: "switch", fallback: false, keywords: ["parallax", "depth", "3d", "wallpaper"] },
        { section: "desktop", group: "Parallax", label: "Direction", visibleWhen: "background.parallax.enable", kind: "choice",
            bundle: ["background.parallax.axis", "background.parallax.vertical", "background.parallax.autoVertical"],
            choices: [{ label: "Horizontal", value: "horizontal", values: ["horizontal", false, false] }, { label: "Vertical", value: "vertical", values: ["vertical", true, false] }, { label: "Auto", value: "auto", values: ["auto", false, true] }] },
        { section: "desktop", group: "Parallax", label: "Depth", visibleWhen: "background.parallax.enable", kind: "choice",
            bundle: ["background.parallax.zoom", "background.parallax.workspaceZoom", "background.parallax.workspaceShift", "background.parallax.panelShift", "background.parallax.widgetDepth", "background.parallax.widgetsFactor"],
            choices: [{ label: "Subtle", value: "subtle", values: [0.95, 0.95, 0.7, 0.08, 0.9, 0.9] }, { label: "Balanced", value: "balanced", values: [1, 1, 1, 0.15, 1.2, 1.2] }, { label: "Immersive", value: "immersive", values: [1.08, 1.08, 1.25, 0.22, 1.38, 1.38] }] },

        { section: "capture", group: "Snip", label: "Snap to windows", description: "The selection jumps to the window under the pointer.", path: "regionSelector.targetRegions.windows", kind: "switch", fallback: true, keywords: ["screenshot", "snip", "capture", "captura"] },
        { section: "capture", group: "Snip", label: "Annotate in Satty", tune: true, description: "Edit opens Satty instead of the built-in editor.", path: "regionSelector.annotation.useSatty", kind: "switch", fallback: false, keywords: ["satty", "annotate", "draw", "edit"] },
        { section: "capture", group: "Japanese lookup", label: "Look up Japanese", description: "Text you capture from a manga, a game or a stream shows readings and meanings.", path: "regionSelector.japaneseLookup.enabled", kind: "switch", fallback: true, keywords: ["japanese", "japones", "manga", "kanji", "dictionary", "ocr", "weeb", "otaku", "furigana"] },
        { section: "capture", group: "Japanese lookup", label: "Send words to Anki", tune: true, description: "Adds the word you pick as a card through AnkiConnect.", path: "regionSelector.japaneseLookup.anki.enabled", visibleWhen: "regionSelector.japaneseLookup.enabled", kind: "switch", fallback: false, keywords: ["anki", "flashcards", "srs", "study"] },
        { section: "capture", group: "Japanese lookup", label: "Deck", path: "regionSelector.japaneseLookup.anki.deck", visibleWhen: "regionSelector.japaneseLookup.anki.enabled", tune: true, kind: "text", placeholder: "Default", fallback: "Default" },
        { section: "capture", group: "Recording", label: "Sound", path: "screenRecord.audioMode", kind: "choice", fallback: "system", choices: [{label:"None",value:"none"},{label:"System",value:"system"},{label:"Microphone",value:"microphone"},{label:"Both",value:"both"}], keywords: ["record", "video", "audio", "grabar"] },
        { tune: true, section: "capture", group: "Recording", label: "Tell me when it is saved", path: "screenRecord.showNotifications", kind: "switch", fallback: true },
        { section: "capture", group: "Recording", label: "Save to", description: "Empty uses your Videos folder.", path: "screenRecord.savePath", tune: true, kind: "text", placeholder: "~/Videos", fallback: "" },
        { section: "capture", group: "Recording", label: "System sound from", showIf: () => ["system", "both"].includes(String(Config.options?.screenRecord?.audioMode ?? "system")), path: "screenRecord.systemAudioSource", kind: "choice", fallback: "", choicesFrom: "monitorSources", tune: true, keywords: ["audio", "source", "monitor", "output"] },
        { section: "capture", group: "Recording", label: "Microphone", showIf: () => ["microphone", "both"].includes(String(Config.options?.screenRecord?.audioMode ?? "system")), path: "screenRecord.microphoneSource", kind: "choice", fallback: "", choicesFrom: "microphones", tune: true, keywords: ["mic", "audio", "input", "micrófono"] },
        { section: "capture", group: "Recording", label: "A copy for Discord", description: "Each recording also gets a smaller .discord.mp4 beside it, under the size Discord takes.", path: "screenRecord.discordCompress.enabled", kind: "switch", fallback: false, tune: true, keywords: ["discord", "compress", "upload", "size", "comprimir"] },
        { section: "capture", group: "Recording", label: "Keep it under", path: "screenRecord.discordCompress.targetSizeMb", visibleWhen: "screenRecord.discordCompress.enabled", kind: "choice", fallback: 10, choices: [{label:"8 MB",value:8},{label:"10 MB",value:10},{label:"25 MB",value:25},{label:"50 MB",value:50}] },
        { section: "capture", group: "Recording", label: "Only when it is too big", path: "screenRecord.discordCompress.onlyIfNeeded", visibleWhen: "screenRecord.discordCompress.enabled", kind: "switch", fallback: true },
        { section: "capture", group: "Recording", label: "Largest side", path: "screenRecord.discordCompress.maxDimension", visibleWhen: "screenRecord.discordCompress.enabled", kind: "choice", fallback: 1280, tune: true, choices: [540, 720, 960, 1280, 1440, 1920].map(size => ({ label: size + " px", value: size })) },
        { section: "capture", group: "Recording", label: "Copy sound", path: "screenRecord.discordCompress.audioBitrateKbps", visibleWhen: "screenRecord.discordCompress.enabled", kind: "choice", fallback: 96, tune: true, choices: [96, 128, 160, 192, 256, 320].map(rate => ({ label: rate + " kbps", value: rate })) },
        { section: "capture", group: "Recording", label: "Copy encoding", description: "Slower makes a better copy at the same size.", path: "screenRecord.discordCompress.preset", visibleWhen: "screenRecord.discordCompress.enabled", kind: "choice", fallback: "slow", tune: true, choices: [{label:"Fast",value:"veryfast"},{label:"Balanced",value:"medium"},{label:"Slow",value:"slow"},{label:"Slowest",value:"veryslow"}] },
        { section: "capture", group: "Recording", label: "Retry in software", description: "If the encoder fails, recording starts again without the GPU.", path: "screenRecord.enableFallback", kind: "switch", fallback: true, tune: true },
        { section: "capture", group: "Recording", label: "Sound system", path: "screenRecord.audioBackend", kind: "choice", fallback: "", tune: true, choices: [{label:"Auto",value:""},{label:"PipeWire",value:"pipewire"},{label:"PulseAudio",value:"pulse"}] },
        { section: "capture", group: "Recording", label: "File name", description: "Date codes such as %Y, %m and %H fill in when it is saved.", path: "screenRecord.recordingNameFormat", kind: "text", placeholder: "recording_%Y-%m-%d_%H.%M.%S", fallback: "recording_%Y-%m-%d_%H.%M.%S", tune: true },
        { section: "capture", group: "Snip", label: "Circle to search", description: "Google Lens takes a circle drawn around anything instead of a rectangle.", path: "search.imageSearch.useCircleSelection", kind: "switch", fallback: false, tune: true, keywords: ["lens", "google", "circle", "search", "círculo"] },
        { tune: true, section: "capture", group: "Snip", label: "Remember the last mode", description: "The next snip opens on the mode you used last.", path: "regionSelector.rememberSnipChoice", kind: "switch", fallback: true },
        { tune: true, section: "capture", group: "Snip", label: "Snap to panels", path: "regionSelector.targetRegions.layers", kind: "switch", fallback: false },
        { tune: true, section: "capture", group: "Snip", label: "Snap to content", description: "Images and blocks of text inside a window.", path: "regionSelector.targetRegions.content", kind: "switch", fallback: true },
        { tune: true, section: "capture", group: "Snip", label: "Aim lines", description: "Guides across the screen while you drag a rectangle.", path: "regionSelector.rect.showAimLines", kind: "switch", fallback: true },
        { section: "capture", group: "Snip", label: "Circle stroke", path: "regionSelector.circle.strokeWidth", visibleWhen: "search.imageSearch.useCircleSelection", kind: "range", fallback: 6, min: 1, max: 20, step: 1, unit: " px" },
        { section: "capture", group: "Snip", label: "Circle padding", path: "regionSelector.circle.padding", visibleWhen: "search.imageSearch.useCircleSelection", kind: "range", fallback: 10, min: 0, max: 100, step: 5, unit: " px" },
        { section: "capture", group: "Snip", label: "File name", description: "Date codes such as %Y, %m and %H fill in when it is saved.", path: "regionSelector.screenshotNameFormat", kind: "text", placeholder: "ss-%Y%m%d-%H%M%S", fallback: "ss-%Y%m%d-%H%M%S", tune: true },
        { section: "capture", group: "Japanese lookup", label: "Dictionary", description: "Jitendex, about 37 MB: readings and meanings for what you capture.", kind: "action", button: "Install", run: () => JapaneseDictionary.installRecommended(), showIf: () => (Config.options?.regionSelector?.japaneseLookup?.enabled ?? true) && !JapaneseDictionary.jitendexInstalled && !JapaneseDictionary.busy, keywords: ["jitendex", "dictionary", "diccionario"] },
        { section: "capture", group: "Japanese lookup", label: "Translate to", tune: true, path: "regionSelector.japaneseLookup.translationTarget", visibleWhen: "regionSelector.japaneseLookup.enabled", kind: "choice", fallback: "auto", choices: [{label:"Auto",value:"auto"},{label:"English",value:"en"},{label:"Spanish",value:"es"}] },
        { section: "capture", group: "Japanese lookup", label: "AnkiConnect address", path: "regionSelector.japaneseLookup.anki.endpoint", visibleWhen: "regionSelector.japaneseLookup.anki.enabled", kind: "text", placeholder: "http://127.0.0.1:8765", fallback: "http://127.0.0.1:8765", tune: true },
        { section: "capture", group: "Japanese lookup", label: "Note type", path: "regionSelector.japaneseLookup.anki.model", visibleWhen: "regionSelector.japaneseLookup.anki.enabled", kind: "text", placeholder: "Basic", fallback: "Basic", tune: true },
        { section: "capture", group: "Japanese lookup", label: "Front field", path: "regionSelector.japaneseLookup.anki.frontField", visibleWhen: "regionSelector.japaneseLookup.anki.enabled", kind: "text", placeholder: "Front", fallback: "Front", tune: true },
        { section: "capture", group: "Japanese lookup", label: "Back field", path: "regionSelector.japaneseLookup.anki.backField", visibleWhen: "regionSelector.japaneseLookup.anki.enabled", kind: "text", placeholder: "Back", fallback: "Back", tune: true },
        { section: "capture", group: "Japanese lookup", label: "Kaishi 1.5k", description: "Japanese to English, beginner vocabulary.", kind: "action", button: "Download", run: () => JapaneseDictionary.downloadStudyDeck("kaishi"), showIf: () => (Config.options?.regionSelector?.japaneseLookup?.anki?.enabled ?? false) && !JapaneseDictionary.deckBusy, tune: true },
        { section: "capture", group: "Japanese lookup", label: "Manabi 2.7k", description: "Japanese to English, words and sentences.", kind: "action", button: "Download", run: () => JapaneseDictionary.downloadStudyDeck("manabi"), showIf: () => (Config.options?.regionSelector?.japaneseLookup?.anki?.enabled ?? false) && !JapaneseDictionary.deckBusy, tune: true },
        { section: "capture", group: "Japanese lookup", label: "Niponismo", description: "Japanese to Spanish, grammar.", kind: "action", button: "Download", run: () => JapaneseDictionary.downloadStudyDeck("niponismo"), showIf: () => (Config.options?.regionSelector?.japaneseLookup?.anki?.enabled ?? false) && !JapaneseDictionary.deckBusy, tune: true },

        { section: "appearance", group: "App colours", part: "What your apps take", label: "The shell's accent", description: "Apps and terminals wear the accent you chose instead of one from the wallpaper.", path: "iris.appearance.accentForApps", showIf: () => !IrisStyle.followsTheme && ThemeService.isAutoTheme && !["theme", "wallpaper"].includes(String(Config.getNestedValue("iris.appearance.accent", "blue"))), kind: "switch", fallback: true, keywords: ["apps", "accent", "gtk", "terminal", "match", "sync", "same colour", "acento", "aplicaciones"] },
        { section: "appearance", group: "App colours", part: "What your apps take", label: "The shell's material", tune: true, description: "Apps and terminals sit on the same paper as the shell.", path: "iris.appearance.materialForApps", visibleWhen: "appearance.theme=auto", kind: "switch", fallback: true, keywords: ["apps", "terminal", "gtk", "sync", "match", "surfaces", "background", "sincronizar", "aplicaciones"] },
        { section: "appearance", group: "App colours", part: "What your apps take", label: "The shell's font", description: "Apps read in the font the shell shows.", path: "appearance.typography.syncWithSystem", kind: "switch", tune: true, fallback: true, keywords: ["apps", "gtk", "qt", "system font", "fuente del sistema", "aplicaciones"] },
        { section: "appearance", group: "App colours", part: "What your apps take", label: "Icons", description: "The icon set apps and the tray draw.", path: "appearance.iconTheme", set: name => IconThemeService.setTheme(name), kind: "choice", tune: true, choicesFrom: "iconThemes", fallback: "", keywords: ["icon theme", "icon pack", "papirus", "adwaita", "whitesur", "tray icons", "app icons", "iconos"] },
        { section: "appearance", group: "App colours", part: "Toolkits and terminals", label: "GTK and KDE apps", description: "They wear the shell's colours, made again for each wallpaper.", path: "appearance.wallpaperTheming.enableAppsAndShell", kind: "switch", fallback: true, keywords: ["matugen", "theme", "gtk", "kde", "colors", "colours", "apps", "wallpaper"] },
        { section: "appearance", group: "App colours", part: "Toolkits and terminals", label: "Qt apps", path: "appearance.wallpaperTheming.enableQtApps", visibleWhen: "appearance.wallpaperTheming.enableAppsAndShell", kind: "switch", tune: true, fallback: true },
        { section: "appearance", group: "App colours", part: "Toolkits and terminals", label: "Terminals", path: "appearance.wallpaperTheming.enableTerminal", kind: "switch", fallback: true, keywords: ["kitty", "foot", "alacritty", "ghostty", "wezterm"] },
        { section: "appearance", group: "App colours", part: "Toolkits and terminals", label: "Terminals always dark", description: "Terminals keep a dark palette in Ink and Light mode too.", path: "appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode", visibleWhen: "appearance.wallpaperTheming.enableTerminal", kind: "switch", tune: true, fallback: false, keywords: ["kitty", "foot", "terminal", "dark", "light", "ink", "scheme", "oscuro", "claro", "tinta"] },
        { section: "appearance", group: "App colours", part: "Toolkits and terminals", label: "Which ones", description: "Terminals and tools that take the colours.", flags: "appearance.wallpaperTheming.terminals", visibleWhen: "appearance.wallpaperTheming.enableTerminal", kind: "pieces", regen: true, tune: true, fallback: [], choices: [{label:"kitty",value:"kitty"},{label:"Alacritty",value:"alacritty"},{label:"foot",value:"foot"},{label:"WezTerm",value:"wezterm"},{label:"Ghostty",value:"ghostty"},{label:"Konsole",value:"konsole"},{label:"Starship",value:"starship"},{label:"Oh My Posh",value:"omp"},{label:"btop",value:"btop"},{label:"lazygit",value:"lazygit"},{label:"yazi",value:"yazi"}], keywords: ["kitty", "alacritty", "foot", "wezterm", "ghostty", "konsole", "starship", "oh my posh", "btop", "lazygit", "yazi", "terminales"] },
        { section: "appearance", group: "App colours", part: "Toolkits and terminals", label: "Terminal colour", description: "How saturated the sixteen colours are.", path: "appearance.wallpaperTheming.terminalColorAdjustments.saturation", visibleWhen: "appearance.wallpaperTheming.enableTerminal", kind: "range", fallback: 0.65, min: 0.1, max: 0.8, step: 0.05, scale: 100, unit: " %", keywords: ["saturation", "terminal", "kitty"] },
        { section: "appearance", group: "App colours", part: "Toolkits and terminals", label: "Terminal brightness", path: "appearance.wallpaperTheming.terminalColorAdjustments.brightness", visibleWhen: "appearance.wallpaperTheming.enableTerminal", kind: "range", fallback: 0.6, min: 0.35, max: 0.75, step: 0.05, scale: 100, unit: " %" },
        { section: "appearance", group: "App colours", part: "Toolkits and terminals", label: "Lean toward the accent", description: "0 keeps each colour's own hue; 100 pulls them all toward your accent.", path: "appearance.wallpaperTheming.terminalColorAdjustments.harmony", visibleWhen: "appearance.wallpaperTheming.enableTerminal", kind: "range", fallback: 0.4, min: 0, max: 1, step: 0.05, scale: 100, unit: " %", keywords: ["harmony", "terminal"] },
        { section: "appearance", group: "App colours", part: "Toolkits and terminals", label: "Hues that lean", description: "How far from the accent a colour can be and still lean toward it.", path: "appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold", visibleWhen: "appearance.wallpaperTheming.enableTerminal", kind: "range", fallback: 100, min: 0, max: 100, step: 10, regen: true },
        { section: "appearance", group: "App colours", part: "Toolkits and terminals", label: "Terminal background", description: "Lower is darker; 50 matches the shell's surfaces.", path: "appearance.wallpaperTheming.terminalColorAdjustments.backgroundBrightness", visibleWhen: "appearance.wallpaperTheming.enableTerminal", kind: "range", fallback: 0.5, min: 0.1, max: 0.9, step: 0.05, scale: 100, unit: " %" },
        { section: "appearance", group: "App colours", part: "Toolkits and terminals", label: "Brighter terminal text", path: "appearance.wallpaperTheming.terminalGenerationProps.termFgBoost", visibleWhen: "appearance.wallpaperTheming.enableTerminal", kind: "range", fallback: 0.35, min: 0, max: 1, step: 0.1, scale: 100, unit: " %", zeroLabel: "Off", regen: true },
        { section: "appearance", group: "App colours", part: "Apps", label: "Discord (Vesktop)", path: "appearance.wallpaperTheming.enableVesktop", kind: "switch", tune: true, fallback: true },
        { section: "appearance", group: "App colours", part: "Apps", label: "Chrome and Chromium", path: "appearance.wallpaperTheming.enableChrome", kind: "switch", tune: true, fallback: true },
        { section: "appearance", group: "App colours", part: "Apps", label: "Firefox", description: "Follows the wallpaper from its next launch; LibreWolf, Floorp, Waterfox and Zen too.", path: "appearance.wallpaperTheming.enableFirefox", kind: "switch", tune: true, fallback: true, keywords: ["firefox", "librewolf", "floorp", "waterfox", "zen", "browser", "navegador"] },
        { section: "appearance", group: "App colours", part: "Apps", label: "VS Code", path: "appearance.wallpaperTheming.enableVSCode", kind: "switch", tune: true, fallback: true },
        { section: "appearance", group: "App colours", part: "Apps", label: "Zed", path: "appearance.wallpaperTheming.enableZed", kind: "switch", tune: true, fallback: true },
        { section: "appearance", group: "App colours", part: "Apps", label: "Spotify (Spicetify)", path: "appearance.wallpaperTheming.enableSpicetify", kind: "switch", tune: true, fallback: true, keywords: ["spotify", "music", "musica"] },
        { section: "appearance", group: "App colours", part: "Apps", label: "Spotify theme", path: "appearance.wallpaperTheming.spicetifyTheme", visibleWhen: "appearance.wallpaperTheming.enableSpicetify", kind: "choice", tune: true, fallback: "Inir", choices: [{label:"iNiR",value:"Inir"},{label:"Text (TUI)",value:"InirTUI"}] },
        { section: "appearance", group: "App colours", part: "Apps", label: "YouTube Music (Pear Desktop)", path: "appearance.wallpaperTheming.enablePearDesktop", kind: "switch", tune: true, fallback: true, keywords: ["youtube", "ytmusic", "pear", "music", "musica"] },
        { section: "appearance", group: "App colours", part: "Apps", label: "LiMusic", description: "Follows the wallpaper, from the next time LiMusic opens.", path: "appearance.wallpaperTheming.enableLimusic", kind: "switch", tune: true, fallback: false, keywords: ["limusic", "youtube", "music", "musica"] },
        { section: "appearance", group: "App colours", part: "Apps", label: "Claude Code", description: "Adds iNiR themes to Claude Code's theme list: two follow the wallpaper, two keep a fixed Monokai palette.", path: "appearance.wallpaperTheming.enableClaudeCode", kind: "switch", tune: true, fallback: false, keywords: ["claude", "claude code", "anthropic", "terminal", "cli", "syntax", "sintaxis", "theme"] },
        { section: "appearance", group: "App colours", part: "Apps", label: "Steam", path: "appearance.wallpaperTheming.enableSteam", kind: "switch", tune: true, fallback: true },
        { section: "appearance", group: "App colours", part: "Apps", label: "Neovim", path: "appearance.wallpaperTheming.enableNeovim", kind: "switch", tune: true, fallback: false },
        { section: "appearance", group: "App colours", part: "Apps", label: "OpenCode", path: "appearance.wallpaperTheming.enableOpenCode", kind: "switch", tune: true, fallback: false, keywords: ["opencode", "terminal", "theme"] },
        { section: "appearance", group: "App colours", part: "Apps", label: "Cava", path: "appearance.wallpaperTheming.enableCava", kind: "switch", tune: true, fallback: true, keywords: ["cava", "visualizer", "terminal"] },
        { section: "appearance", group: "App colours", part: "Apps", label: "Cava colours from", path: "appearance.cava.colorSource", visibleWhen: "appearance.wallpaperTheming.enableCava", regen: true, kind: "choice", fallback: "theme", tune: true, choices: [{label:"Theme",value:"theme"},{label:"Vibrant",value:"vibrant"},{label:"Album cover",value:"cover"}] },
        { section: "appearance", group: "App colours", part: "Apps", label: "Cava gradient", description: "How many colours its bars climb through.", path: "appearance.cava.gradientCount", visibleWhen: "appearance.wallpaperTheming.enableCava", regen: true, kind: "range", fallback: 8, min: 1, max: 8, step: 1 },
        { section: "appearance", group: "App colours", part: "Apps", label: "Cava sensitivity", path: "appearance.cava.sensitivity", visibleWhen: "appearance.wallpaperTheming.enableCava", regen: true, kind: "range", fallback: 100, min: 10, max: 500, step: 10, unit: " %" },
        { section: "appearance", group: "App colours", part: "Apps", label: "Cava bars", path: "appearance.cava.bars", visibleWhen: "appearance.wallpaperTheming.enableCava", regen: true, kind: "range", fallback: 0, min: 0, max: 200, step: 8, zeroLabel: "Auto" },
        { section: "appearance", group: "App colours", part: "Apps", label: "Cava frame rate", path: "appearance.cava.framerate", visibleWhen: "appearance.wallpaperTheming.enableCava", regen: true, kind: "range", fallback: 60, min: 30, max: 165, step: 5, unit: " fps" },
        { section: "appearance", group: "App colours", part: "Apps", label: "Cava in stereo", path: "appearance.cava.stereo", visibleWhen: "appearance.wallpaperTheming.enableCava", regen: true, kind: "switch", fallback: true, tune: true },

        { section: "display", group: "Screens", label: "Island on", description: "None chosen shows it on every screen.", path: "iris.bar.screenList", showIf: () => Quickshell.screens.length > 1, kind: "pieces", fallback: [], choicesFrom: "screens", keywords: ["monitor", "bar", "island", "screen", "pantalla"] },
        { section: "display", group: "Screens", label: "Bubbles on", description: "The bubbles off the Island. None chosen shows them on every screen.", path: "iris.bubbles.screenList", showIf: () => Quickshell.screens.length > 1, kind: "pieces", fallback: [], choicesFrom: "screens", keywords: ["monitor", "bubbles", "burbujas", "screen", "pantalla", "main"] },
        { section: "display", group: "Screens", label: "Widgets on", description: "None chosen shows them on every screen.", path: "background.widgets.screenList", showIf: () => Quickshell.screens.length > 1, kind: "pieces", fallback: [], choicesFrom: "screens", keywords: ["monitor", "widgets", "desktop", "screen", "pantalla"] },
        { section: "display", group: "Screens", label: "Main screen", description: "Where the wallpaper gallery and other one-screen panels open.", path: "display.primaryMonitor", showIf: () => Quickshell.screens.length > 1 && !CompositorConfig.displayHas("main", true), kind: "choice", fallback: "", choicesFrom: "primaryScreens", keywords: ["primary", "main", "monitor", "principal"] },
        { section: "display", group: "Night Light", label: "On a schedule", description: "Warmer colours in the evening, back to normal in the morning.", path: "light.night.automatic", kind: "switch", fallback: false, keywords: ["night", "blue light", "warm", "wlsunset", "noche"] },
        { section: "display", group: "Night Light", label: "From", path: "light.night.from", visibleWhen: "light.night.automatic", kind: "text", placeholder: "19:00", fallback: "19:00" },
        { section: "display", group: "Night Light", label: "Until", path: "light.night.to", visibleWhen: "light.night.automatic", kind: "text", placeholder: "06:30", fallback: "06:30" },
        { section: "display", group: "Night Light", label: "Night Light now", path: "light.night.enabled", visibleWhen: "!light.night.automatic", kind: "switch", fallback: false },
        { section: "display", group: "Night Light", label: "Warmth", description: "Lower is warmer.", path: "light.night.colorTemperature", kind: "range", fallback: 6000, min: 2500, max: 6500, step: 100, unit: " K" },
        { section: "display", group: "Comfort", label: "Soften bright flashes", description: "Dims the screen when a mostly white window suddenly fills it.", path: "light.antiFlashbang.enable", kind: "switch", fallback: false, keywords: ["flashbang", "bright", "white", "eyes"] },

        { section: "battery", group: "Warnings", label: "Low battery", path: "battery.low", kind: "range", fallback: 20, min: 5, max: 50, step: 5, unit: " %" },
        { section: "battery", group: "Warnings", label: "Critical battery", path: "battery.critical", kind: "range", fallback: 5, min: 1, max: 20, unit: " %" },
        { section: "battery", group: "Warnings", label: "Warning sounds", path: "sounds.battery", kind: "switch", fallback: false },
        { section: "battery", group: "Suspend", label: "Suspend when almost empty", path: "battery.automaticSuspend", kind: "switch", fallback: false },
        { section: "battery", group: "Suspend", label: "At", path: "battery.suspend", visibleWhen: "battery.automaticSuspend", kind: "range", fallback: 3, min: 1, max: 10, unit: " %" },
        { section: "battery", group: "Charge limit", label: "Limit charging", description: "Stops charging early so the battery ages slower.", path: "battery.chargeLimit.enable", kind: "switch", fallback: false },
        { section: "battery", group: "Charge limit", label: "Stop at", path: "battery.chargeLimit.threshold", visibleWhen: "battery.chargeLimit.enable", kind: "range", fallback: 80, min: 50, max: 100, step: 5, unit: " %" },

        { section: "gaming", group: "Game mode", label: "Turn on for fullscreen apps", description: "Game mode starts by itself while a window is fullscreen and ends when it leaves.", path: "gameMode.autoDetect", kind: "switch", fallback: true, keywords: ["game", "gaming", "fullscreen", "juego", "performance"] },
        { section: "gaming", group: "Game mode", label: "Stop shell animations", tune: true, description: "iRiS shapes appear in place while you play.", path: "gameMode.disableAnimations", kind: "switch", fallback: false },
        { section: "gaming", group: "Game mode", label: "Stop glass and blur", tune: true, path: "gameMode.disableEffects", kind: "switch", fallback: false },
        { section: "gaming", group: "Game mode", label: "Stop window animations", tune: true, showIf: () => CompositorConfig.niri, path: "gameMode.disableNiriAnimations", kind: "switch", fallback: false },
        { section: "gaming", group: "Game mode", label: "Hold notifications", tune: true, description: "Banners wait until you are done; they still collect in Today.", path: "gameMode.suppressNotifications", kind: "switch", fallback: true },
        { section: "gaming", group: "Game mode", label: "Stop audio visualizers", tune: true, path: "gameMode.disableVisualizers", kind: "switch", fallback: true },
        { section: "gaming", group: "Game mode", label: "Close the Discord overlay", path: "gameMode.disableDiscoverOverlay", kind: "switch", fallback: true, showIf: () => GameMode.discoverOverlayInstalled, keywords: ["discover", "discord", "overlay"] },
        { section: "gaming", group: "Game mode", label: "Hide reload notices", tune: true, description: "The small notice when your config reloads stays away while you play.", path: "gameMode.disableReloadToasts", kind: "switch", fallback: true, keywords: ["toast", "reload"] },
        { section: "gaming", group: "Floating tools", label: "Floating tools", description: "Super+G: recorder, mixer, frame cap, crosshair, notes and more over what you play; pin one to keep it there.", kind: "action", button: "Open", run: () => { GlobalStates.settingsOverlayOpen = false; GlobalStates.overlayOpen = true }, keywords: ["overlay", "super+g", "game", "tools", "recorder", "crosshair", "fps", "mangohud", "herramientas"] },
        { section: "gaming", group: "Floating tools", label: "Dim the screen behind", path: "overlay.darkenScreen", kind: "switch", fallback: true, keywords: ["overlay", "scrim", "dark"] },
        { section: "gaming", group: "Floating tools", label: "Dim", path: "overlay.scrimDim", visibleWhen: "overlay.darkenScreen", kind: "range", fallback: 35, min: 0, max: 100, step: 5, unit: " %", keywords: ["overlay", "scrim", "dark"] },
        { section: "gaming", group: "Floating tools", label: "Tool background", description: "How solid each tool's plate is; a pinned tool can set its own.", path: "overlay.backgroundOpacity", kind: "range", fallback: 0.9, min: 0.2, max: 1, step: 0.05, scale: 100, unit: " %", keywords: ["overlay", "opacity", "transparent"] },
        { section: "gaming", group: "Floating tools", label: "Pinned tools that let clicks through", description: "Their opacity, so the game shows behind them.", path: "overlay.clickthroughOpacity", kind: "range", fallback: 0.8, min: 0.2, max: 1, step: 0.05, scale: 100, unit: " %", keywords: ["overlay", "opacity", "clickthrough", "pinned"] },
        { section: "gaming", group: "Floating tools", label: "Zoom in on open", path: "overlay.openingZoomAnimation", kind: "switch", fallback: true, keywords: ["overlay", "animation", "zoom"] },

        { section: "lock", group: "When idle", label: "Turn the screen off after", path: "idle.screenOffTimeout", kind: "choice", fallback: 300, choices: root.idleChoices, keywords: ["idle", "timeout", "screen off", "sleep"] },
        { section: "lock", group: "When idle", label: "Lock after", path: "idle.lockTimeout", kind: "choice", fallback: 600, choices: root.idleChoices, keywords: ["idle", "timeout", "lock"] },
        { section: "lock", group: "When idle", label: "Suspend after", path: "idle.suspendTimeout", kind: "choice", fallback: 0, choices: root.idleChoices, keywords: ["idle", "timeout", "suspend", "sleep"] },
        { section: "lock", group: "When idle", label: "Lock before sleeping", path: "idle.lockBeforeSleep", kind: "switch", fallback: true },
        { section: "lock", group: "When idle", label: "Shorter times on battery", tune: true, path: "idle.onBattery.enable", kind: "switch", fallback: false },
        { section: "lock", group: "When idle", label: "On battery, screen off after", path: "idle.onBattery.screenOffTimeout", visibleWhen: "idle.onBattery.enable", kind: "choice", fallback: 120, choices: root.idleChoices },
        { section: "lock", group: "When idle", label: "On battery, lock after", path: "idle.onBattery.lockTimeout", visibleWhen: "idle.onBattery.enable", kind: "choice", fallback: 300, choices: root.idleChoices },
        { section: "lock", group: "When idle", label: "On battery, suspend after", path: "idle.onBattery.suspendTimeout", visibleWhen: "idle.onBattery.enable", kind: "choice", fallback: 600, choices: root.idleChoices },
        { section: "lock", group: "Security", label: "Unlock the keyring", tune: true, description: "Your password also opens the login keyring, so apps stop asking for it.", path: "lock.security.unlockKeyring", kind: "switch", fallback: true },
        { section: "login", group: "Login Screen", label: "Login screen", description: "Where you sign in after starting the computer.", path: "lock.loginScreen", locked: () => !MaterialThemeLoader.loginScreenInstalled, warns: true, note: () => root.loginNote(), kind: "choice", fallback: "auto", choices: [{label:"Automatic",value:"auto"},{label:"iRiS",value:"iris"},{label:"Classic",value:"classic"}], keywords: ["login", "sddm", "greeter", "sign in", "boot", "startup", "password", "classic"] },
        { section: "login", group: "Login Screen", label: "Login style", description: "Cover shows your picture sharp, Frame hangs it in a mat, Lens cuts the time out of it.", path: "lock.loginStyle", showIf: () => ["iris", "auto"].indexOf(Config.options?.lock?.loginScreen ?? "auto") >= 0, locked: () => !MaterialThemeLoader.loginScreenInstalled, kind: "choice", fallback: "lens", choices: [{label:"Cover",value:"cover"},{label:"Frame",value:"frame"},{label:"Lens",value:"lens"}], keywords: ["login", "sddm", "greeter", "sign in", "style", "cover", "frame", "lens", "mat", "picture", "clock", "blur", "portada", "marco", "lente"] }
    ]

    // Values read when a row asks, never when the list is built: a colour read here put the whole registry, and the search
    // index built from it, behind every scheme or accent change (10-29: 1.4 s of the shell held on one switch).
    readonly property var swatchChoices: [
        { label: "Accent", get value() { return String(IrisStyle.accent) }, get swatch() { return IrisStyle.accent } },
        { label: "Highlight", get value() { return String(IrisStyle.secondaryAccent) }, get swatch() { return IrisStyle.secondaryAccent } },
        { label: "Blue", get value() { return String(IrisStyle.identity.blue) }, get swatch() { return IrisStyle.identity.blue } },
        { label: "Green", get value() { return String(IrisStyle.identity.green) }, get swatch() { return IrisStyle.identity.green } },
        { label: "Pink", get value() { return String(IrisStyle.identity.pink) }, get swatch() { return IrisStyle.identity.pink } },
        { label: "Gray", get value() { return String(IrisStyle.identity.gray) }, get swatch() { return IrisStyle.identity.gray } }
    ]
    // The compositor's settings, read and written by the base's CompositorConfig: `comp` and `key` are its vocabulary,
    // never a compositor's own option name. A row the compositor in use cannot do is not shown (shown()).
    readonly property var niriRows: [
        { tune: false, section: "windows", group: "Layout", notice: true, label: "Let Settings change the compositor", description: "Its config file does not read what Settings saves yet. This adds the one line it needs; nothing else in it changes.", kind: "action", button: "Allow", run: () => CompositorConfig.link(), showIf: () => !CompositorConfig.linked, keywords: ["compositor", "config", "include", "link", "allow", "not saving", "no guarda"] },
        { tune: false, section: "keyboard", group: "Keyboard", notice: true, label: "Let Settings change the compositor", description: "Its config file does not read what Settings saves yet. This adds the one line it needs; nothing else in it changes.", kind: "action", button: "Allow", run: () => CompositorConfig.link(), showIf: () => !CompositorConfig.linked, keywords: ["compositor", "config", "include", "link", "allow", "not saving", "no guarda"] },
        { tune: false, section: "display", group: "Screen", notice: true, label: "Let Settings change the compositor", description: "Its config file does not read what Settings saves yet. This adds the one line it needs; nothing else in it changes.", kind: "action", button: "Allow", run: () => CompositorConfig.link(), showIf: () => !CompositorConfig.linked, keywords: ["compositor", "config", "include", "link", "allow", "not saving", "no guarda"] },
        { tune: false, section: "windows", group: "Layout", notice: true, label: "The compositor skipped a line", get description() { return CompositorConfig.error }, kind: "action", button: "Show the file", run: () => Qt.openUrlExternally("file://" + CompositorConfig.errorFile), showIf: () => CompositorConfig.error.length > 0 && CompositorConfig.errorFile.length > 0, keywords: ["compositor", "config", "error", "refused", "invalid"] },
        { tune: false, section: "keyboard", group: "Keyboard", notice: true, label: "The compositor skipped a line", get description() { return CompositorConfig.error }, kind: "action", button: "Show the file", run: () => Qt.openUrlExternally("file://" + CompositorConfig.errorFile), showIf: () => CompositorConfig.error.length > 0 && CompositorConfig.errorFile.length > 0, keywords: ["compositor", "config", "error", "refused", "invalid"] },
        { tune: false, section: "display", group: "Screen", notice: true, label: "The compositor skipped a line", get description() { return CompositorConfig.error }, kind: "action", button: "Show the file", run: () => Qt.openUrlExternally("file://" + CompositorConfig.errorFile), showIf: () => CompositorConfig.error.length > 0 && CompositorConfig.errorFile.length > 0, keywords: ["compositor", "config", "error", "refused", "invalid"] },
        { tune: false, section: "windows", group: "Layout", comp: "layout", key: "mode", label: "Arrangement", kind: "list", bare: true, view: Qt.resolvedUrl("IrisLayoutModes.qml"), summary: () => root.layoutMode(), keywords: ["layout", "tiling", "scrolling", "dwindle", "master", "stack", "floating", "stacking", "mosaico", "distribucion", "ventanas"] },
        { tune: false, section: "windows", group: "Layout", comp: "layout", key: "gaps", label: "Gaps", description: "Space around and between windows.", kind: "range", fallback: 16, min: 0, max: 48, unit: " px", keywords: ["niri", "gaps", "spacing", "padding"] },
        { section: "windows", group: "Layout", label: "New windows open", kind: "list", bare: true, view: Qt.resolvedUrl("IrisLayoutWidth.qml"), showIf: () => CompositorConfig.has("layout", "new-width") && root.layoutMode() === "scrolling", keywords: ["column width", "window width", "default width", "ancho", "half", "third"] },
        { section: "windows", group: "Layout", showIf: () => root.layoutMode() === "scrolling", comp: "layout", key: "center-focused-column", read: "center_focused", label: "Centre the focused column", summary: false, kind: "choice", fallback: "never", choices: [{label:"Never",value:"never"},{label:"When it overflows",value:"on-overflow"},{label:"Always",value:"always"}], keywords: ["niri", "center", "centre", "column"] },
        { tune: true, section: "windows", group: "Layout", showIf: () => root.layoutMode() === "scrolling", comp: "layout", key: "always-center-single-column", label: "Centre a column that is alone", kind: "switch", fallback: false },
        { tune: true, section: "windows", group: "Layout", showIf: () => root.layoutMode() === "scrolling", comp: "layout", key: "default-column-display", label: "New columns", kind: "choice", fallback: "normal", choices: [{label:"Side by side",value:"normal"},{label:"Tabbed",value:"tabbed"}], keywords: ["niri", "tabs", "tabbed"] },
        { tune: true, section: "windows", group: "Layout", comp: "layout", key: "empty-workspace-above-first", label: "Empty workspace above the first", kind: "switch", fallback: false },
        { section: "windows", group: "Layout", showIf: () => root.layoutMode() === "master", comp: "layout", key: "master.position", label: "Main window on", summary: false, kind: "choice", fallback: "left", choices: [{label:"Left",value:"left",glyph:"align_horizontal_left"},{label:"Centre",value:"center",glyph:"align_horizontal_center"},{label:"Right",value:"right",glyph:"align_horizontal_right"}], keywords: ["master", "main", "principal"] },
        { section: "windows", group: "Layout", showIf: () => root.layoutMode() === "master", comp: "layout", key: "master.share", label: "Main window takes", kind: "range", fallback: 0.55, min: 0.3, max: 0.8, step: 0.05, scale: 100, unit: " %" },
        { tune: true, section: "windows", group: "Layout", showIf: () => root.layoutMode() === "master", comp: "layout", key: "master.new-is-master", label: "A new window becomes the main one", kind: "switch", fallback: false },
        { section: "windows", group: "Layout", showIf: () => root.layoutMode() === "dwindle", comp: "layout", key: "dwindle.toward-pointer", label: "New windows open toward the pointer", description: "Off opens them on the right or below.", kind: "switch", fallback: false },
        { tune: true, section: "windows", group: "Layout", showIf: () => root.layoutMode() === "dwindle", comp: "layout", key: "dwindle.keep-split", label: "Keep each split's direction", description: "A split stays side by side or stacked when its space changes shape.", kind: "switch", fallback: false },
        { section: "windows", group: "Layout", showIf: () => root.layoutMode() === "stacking", comp: "layout", key: "stacking.drop-zones", label: "Snap to edges and corners", description: "Dragging a window to an edge fills that half; a corner, that quarter.", kind: "switch", fallback: true, keywords: ["snap", "tile", "zones", "halves"] },
        { tune: true, section: "windows", group: "Layout", showIf: () => root.layoutMode() !== "stacking", comp: "layout", key: "maximize", label: "An app's maximize button fills", kind: "choice", fallback: "column", description: "Its own place is its column, or its tile.", choices: [{label:"Its own place",value:"column"},{label:"The screen",value:"edges"}] },

        { section: "windows", group: "Borders", comp: "layout", key: "border.enabled", label: "Border", description: "A solid line around every window.", kind: "switch", fallback: false, keywords: ["niri", "border", "outline"] },
        { section: "windows", group: "Borders", comp: "layout", key: "border.width", label: "Width", showIf: () => CompositorConfig.value({ comp: "layout", key: "border.enabled" }) === true, kind: "range", fallback: 4, min: 1, max: 10, unit: " px" },
        { section: "windows", group: "Borders", comp: "layout", key: "border.active-color", label: "Focused", showIf: () => CompositorConfig.value({ comp: "layout", key: "border.enabled" }) === true, kind: "choice", fallback: "", choices: root.swatchChoices },
        { section: "windows", group: "Borders", comp: "layout", key: "border.inactive-color", label: "Others", showIf: () => CompositorConfig.value({ comp: "layout", key: "border.enabled" }) === true, kind: "choice", fallback: "", choices: root.swatchChoices },
        { tune: true, section: "windows", group: "Borders", comp: "layout", key: "outer-border.width", label: "Outer line", description: "A second, darker line outside the border.", showIf: () => CompositorConfig.value({ comp: "layout", key: "border.enabled" }) === true, kind: "range", fallback: 0, min: 0, max: 8, unit: " px" },
        { section: "windows", group: "Borders", comp: "layout", key: "focus-ring.enabled", label: "Focus ring", description: "A ring outside the focused window only.", kind: "switch", fallback: false, keywords: ["niri", "focus ring", "outline"] },
        { section: "windows", group: "Borders", comp: "layout", key: "focus-ring.width", label: "Ring width", showIf: () => CompositorConfig.value({ comp: "layout", key: "focus-ring.enabled" }) === true, kind: "range", fallback: 4, min: 1, max: 10, unit: " px" },
        { section: "windows", group: "Borders", comp: "layout", key: "focus-ring.active-color", label: "Ring colour", showIf: () => CompositorConfig.value({ comp: "layout", key: "focus-ring.enabled" }) === true, kind: "choice", fallback: "", choices: root.swatchChoices },

        { tune: false, section: "windows", group: "Shape", comp: "window-rules", key: "corner-radius", label: "Window corners", description: "Rounds every window's corners.", kind: "range", fallback: 0, min: 0, max: 24, unit: " px", keywords: ["niri", "radius", "rounded", "corners"] },
        { tune: true, section: "windows", group: "Shape", comp: "window-rules", key: "clip-to-geometry", label: "Clip content to the corners", kind: "switch", fallback: false, write: on => on ? "true" : "false" },
        { section: "windows", group: "Shape", comp: "layout", key: "shadow.enabled", label: "Shadows", kind: "switch", fallback: false, keywords: ["niri", "shadow"] },
        { section: "windows", group: "Shape", comp: "layout", key: "shadow.softness", label: "Softness", showIf: () => CompositorConfig.value({ comp: "layout", key: "shadow.enabled" }) === true, kind: "range", fallback: 30, min: 0, max: 80, unit: " px" },
        { section: "windows", group: "Shape", comp: "layout", key: "shadow.spread", label: "Spread", showIf: () => CompositorConfig.value({ comp: "layout", key: "shadow.enabled" }) === true, kind: "range", fallback: 5, min: 0, max: 40, unit: " px" },
        { tune: true, section: "windows", group: "Shape", comp: "layout", key: "shadow.offset-x", label: "Shadow falls sideways", showIf: () => CompositorConfig.value({ comp: "layout", key: "shadow.enabled" }) === true, kind: "range", fallback: 2, min: -40, max: 40, unit: " px" },
        { tune: true, section: "windows", group: "Shape", comp: "layout", key: "shadow.offset-y", label: "Shadow falls down", showIf: () => CompositorConfig.value({ comp: "layout", key: "shadow.enabled" }) === true, kind: "range", fallback: 2, min: -40, max: 40, unit: " px" },
        { section: "windows", group: "Shape", comp: "layout", key: "drag-opacity", label: "While you drag it", description: "How solid a window stays in your hand.", kind: "range", fallback: 0.75, min: 0.3, max: 1, step: 0.05, scale: 100, unit: " %" },

        { tune: false, section: "windows", group: "Tabs", comp: "tabs", key: "position", label: "Tabs sit", description: "Windows sharing one place show as tabs.", summary: false, kind: "choice", fallback: "top", choices: [{label:"Top",value:"top",glyph:"vertical_align_top"},{label:"Bottom",value:"bottom",glyph:"vertical_align_bottom"},{label:"Left",value:"left",glyph:"align_horizontal_left"},{label:"Right",value:"right",glyph:"align_horizontal_right"}], keywords: ["tabs", "tabbed", "pestañas", "group"] },
        { section: "windows", group: "Tabs", comp: "tabs", key: "style", label: "Tabs show", kind: "choice", fallback: "titles", choices: [{label:"Titles",value:"titles",glyph:"title"},{label:"A thin line",value:"indicator",glyph:"horizontal_rule"}] },
        { section: "windows", group: "Tabs", comp: "tabs", key: "height", label: "Height", showIf: () => CompositorConfig.value({ comp: "tabs", key: "style" }) !== "indicator", kind: "range", fallback: 24, min: 16, max: 48, unit: " px" },
        { section: "windows", group: "Tabs", comp: "tabs", key: "hide-when-single", label: "Hide for a window alone", kind: "switch", fallback: false },
        { tune: true, section: "windows", group: "Tabs", comp: "tabs", key: "new-tab", label: "A new tab opens", kind: "choice", fallback: "end", choices: [{label:"At the end",value:"end"},{label:"After the current one",value:"after_active"}] },
        { tune: true, section: "windows", group: "Tabs", comp: "tabs", key: "scroll-switches", label: "Scroll over the tabs to switch", kind: "switch", fallback: true },
        { tune: true, section: "windows", group: "Tabs", comp: "tabs", key: "middle-click-closes", label: "Middle click closes a tab", kind: "switch", fallback: false },

        { tune: false, section: "windows", group: "Title bars", comp: "titlebar", key: "mode", label: "Title bars", description: "A bar to drag a window by, with its buttons.", summary: false, kind: "choice", fallback: "off", choices: [{label:"None",value:"off",detail:"Windows stay bare."},{label:"When an app asks",value:"on",detail:"Each app decides."},{label:"Only apps that agree",value:"negotiated",detail:"Apps that draw their own keep it."},{label:"Every window",value:"forced",detail:"Always, whatever the app says."}], keywords: ["title bar", "titlebar", "decorations", "csd", "ssd", "buttons", "close", "barra de titulo"] },
        { section: "windows", group: "Title bars", comp: "titlebar", key: "buttons-side", label: "Buttons on the", showIf: () => String(CompositorConfig.value({ comp: "titlebar", key: "mode" }) ?? "off") !== "off", kind: "choice", fallback: "right", choices: [{label:"Left",value:"left"},{label:"Right",value:"right"}] },
        { tune: true, section: "windows", group: "Title bars", comp: "titlebar", key: "height", label: "Height", showIf: () => String(CompositorConfig.value({ comp: "titlebar", key: "mode" }) ?? "off") !== "off", kind: "range", fallback: 28, min: 20, max: 48, unit: " px" },
        { tune: false, section: "windows", group: "Glass behind apps", comp: "glass", key: "enabled", label: "Blur behind see-through windows", description: "What is behind a window or a panel that lets it through is frosted.", kind: "switch", fallback: true, keywords: ["blur", "glass", "frosted", "transparent", "desenfoque", "vidrio"] },
        { section: "windows", group: "Glass behind apps", comp: "glass", key: "radius", label: "Blur strength", showIf: () => CompositorConfig.value({ comp: "glass", key: "enabled" }) === true, kind: "range", fallback: 5, min: 1, max: 20 },
        { tune: true, section: "windows", group: "Glass behind apps", comp: "glass", key: "passes", label: "Smoothness", description: "More passes blur softer and cost more.", showIf: () => CompositorConfig.value({ comp: "glass", key: "enabled" }) === true, kind: "range", fallback: 2, min: 1, max: 6 },
        { section: "windows", group: "Glass behind apps", comp: "glass", key: "saturation", label: "Colour behind", description: "Above 1 makes what is blurred more vivid.", showIf: () => CompositorConfig.value({ comp: "glass", key: "enabled" }) === true, kind: "range", fallback: 1.1, min: 0.5, max: 2, step: 0.05, unit: "×" },
        { tune: true, section: "windows", group: "Glass behind apps", comp: "glass", key: "brightness", label: "Brightness behind", showIf: () => CompositorConfig.value({ comp: "glass", key: "enabled" }) === true, kind: "range", fallback: 0.9, min: 0.4, max: 1.4, step: 0.05, unit: "×" },
        { tune: true, section: "windows", group: "Glass behind apps", comp: "glass", key: "contrast", label: "Contrast behind", showIf: () => CompositorConfig.value({ comp: "glass", key: "enabled" }) === true, kind: "range", fallback: 0.9, min: 0.4, max: 1.4, step: 0.05, unit: "×" },
        { tune: true, section: "windows", group: "Glass behind apps", comp: "glass", key: "noise", label: "Grain", description: "A little noise hides banding in soft gradients.", showIf: () => CompositorConfig.value({ comp: "glass", key: "enabled" }) === true, kind: "range", fallback: 0.02, min: 0, max: 0.1, step: 0.01, scale: 100, unit: " %" },
        { tune: false, section: "windows", group: "Glass behind apps", comp: "window-rules", key: "active-opacity", label: "Window in focus", description: "Blur only shows through a window that is not fully opaque.", kind: "range", fallback: 1, min: 0.5, max: 1, step: 0.05, scale: 100, unit: " %", keywords: ["niri", "opacity", "transparent", "transparency", "focused", "active", "opacidad"] },
        { section: "windows", group: "Glass behind apps", comp: "window-rules", key: "inactive-opacity", label: "Windows out of focus", description: "How opaque the windows you are not using stay.", kind: "range", fallback: 1, min: 0.5, max: 1, step: 0.05, scale: 100, unit: " %", keywords: ["niri", "opacity", "transparent", "inactive", "background", "unfocused", "opacidad"] },
        { section: "windows", group: "Glass behind apps", comp: "window-rules", key: "blur", label: "Blur behind apps", description: "The compositor blurs what is behind every window that lets it through.", showIf: () => IrisCompositorBlur.available, kind: "switch", fallback: false, keywords: ["niri", "blur", "glass", "frosted", "transparent", "apps", "windows", "desenfoque"] },
        { section: "windows", group: "Glass behind apps", comp: "window-rules", key: "xray", label: "Blur shows", description: "What the glass blurs.", showIf: () => CompositorConfig.value({ comp: "window-rules", key: "blur" }) === true, kind: "choice", fallback: true, choices: [{label:"The wallpaper",value:true,glyph:"wallpaper",detail:"Blurred once; costs almost nothing."},{label:"Everything behind",value:false,glyph:"layers",detail:"Follows other windows; costs more."}], keywords: ["niri", "xray", "blur", "windows behind"] },
        { tune: true, section: "windows", group: "Glass behind apps", comp: "window-rules", key: "border-behind", label: "Keep borders out of the glass", description: "Stops the border and focus ring from showing through a see-through window.", showIf: () => CompositorConfig.value({ comp: "window-rules", key: "blur" }) === true || CompositorConfig.value({ comp: "layout", key: "border.enabled" }) === true || Number(CompositorConfig.value({ comp: "window-rules", key: "active-opacity" }) ?? 1) < 1 || Number(CompositorConfig.value({ comp: "window-rules", key: "inactive-opacity" }) ?? 1) < 1, kind: "switch", fallback: false, keywords: ["niri", "border", "focus ring", "draw-border-with-background"] },
        { section: "windows", group: "Glass behind apps", comp: "blur", key: "enabled", label: "Compositor blur", description: "Off turns blur off everywhere, iRiS included.", showIf: () => CompositorConfig.value({ comp: "window-rules", key: "blur" }) === true && IrisCompositorBlur.available, kind: "switch", fallback: true, keywords: ["niri", "blur"] },
        { section: "windows", group: "Glass behind apps", comp: "blur", key: "strength", label: "Blur strength", showIf: () => CompositorConfig.value({ comp: "window-rules", key: "blur" }) === true && IrisCompositorBlur.usable, kind: "choice", fallback: "balanced", choices: [{label:"Light",value:"light"},{label:"Balanced",value:"balanced"},{label:"Strong",value:"strong"}], keywords: ["niri", "blur", "strength", "radius"] },
        { section: "windows", group: "Glass behind apps", comp: "blur", key: "saturation", label: "Colour behind", description: "Above 1 makes what is blurred more vivid.", showIf: () => CompositorConfig.value({ comp: "window-rules", key: "blur" }) === true && IrisCompositorBlur.usable, kind: "range", fallback: 1.5, min: 0.5, max: 2.5, step: 0.1, unit: "×", keywords: ["niri", "saturation", "vibrancy"] },
        { section: "windows", group: "Glass behind apps", comp: "blur", key: "noise", label: "Grain", description: "A little noise hides banding in soft gradients.", showIf: () => CompositorConfig.value({ comp: "window-rules", key: "blur" }) === true && IrisCompositorBlur.usable, kind: "range", fallback: 0.02, min: 0, max: 0.1, step: 0.01, scale: 100, unit: " %", keywords: ["niri", "noise", "grain"] },

        { section: "windows", group: "Movement", comp: "animations", key: "enabled", label: "Animate windows", description: "Windows opening, closing, moving and switching.", kind: "switch", fallback: true, keywords: ["niri", "animations", "motion"] },
        { section: "windows", group: "Movement", label: "Style", description: "How windows open, close and slide between columns.", showIf: () => CompositorConfig.has("animations", "style") && CompositorConfig.value({ comp: "animations", key: "enabled" }) === true, kind: "niriMotion", keywords: ["niri", "animations", "preset", "motion", "bounce", "bouncy", "fast", "snappy", "slow", "smooth", "material", "open", "close", "window", "animaciones"] },
        { section: "windows", group: "Movement", comp: "animations", key: "slowdown", label: "Speed", description: "Above 1 slows every window animation down.", showIf: () => CompositorConfig.value({ comp: "animations", key: "enabled" }) === true, kind: "range", fallback: 1, min: 0.25, max: 3, step: 0.05, unit: "×", keywords: ["niri", "slowdown", "speed"] },
        { section: "windows", group: "Movement", comp: "animations", key: "duration", label: "Speed", description: "How long a window takes to open, close or move.", showIf: () => CompositorConfig.value({ comp: "animations", key: "enabled" }) === true, kind: "choice", fallback: 250, choices: [{label:"Quick",value:150},{label:"Normal",value:250},{label:"Calm",value:400},{label:"Slow",value:650}], keywords: ["animations", "speed", "duration", "velocidad"] },
        { section: "windows", group: "Movement", comp: "layout", key: "overview.zoom", read: "overview_zoom", label: "Overview size", description: "How big workspaces are in the overview.", kind: "range", fallback: 0.5, min: 0.2, max: 0.75, step: 0.05, scale: 100, unit: " %", keywords: ["niri", "overview", "zoom"] },
        { tune: true, section: "windows", group: "Movement", comp: "overview", key: "wallpaper", label: "Wallpaper behind each workspace", description: "In the overview every workspace keeps its wallpaper.", kind: "switch", fallback: true, keywords: ["overview", "wallpaper"] },
        { section: "windows", group: "Movement", comp: "animations", key: "open", label: "Windows open", showIf: () => CompositorConfig.value({ comp: "animations", key: "enabled" }) === true, kind: "choice", choicesFrom: "compositor", fallback: "style:popin", keywords: ["open", "opening", "appear", "animation", "effect", "wipe", "abrir"] },
        { section: "windows", group: "Movement", comp: "animations", key: "close", label: "Windows close", showIf: () => CompositorConfig.value({ comp: "animations", key: "enabled" }) === true, kind: "choice", choicesFrom: "compositor", fallback: "style:popin", keywords: ["close", "closing", "disappear", "animation", "effect", "cerrar"] },
        { tune: true, section: "windows", group: "Movement", comp: "animations", key: "move", label: "Windows move", showIf: () => CompositorConfig.value({ comp: "animations", key: "enabled" }) === true, kind: "choice", choicesFrom: "compositor", fallback: "", keywords: ["move", "squash", "resize", "animation", "effect", "mover"] },
        { tune: true, section: "windows", group: "Movement", comp: "animations", key: "workspaces", label: "Workspaces change", showIf: () => CompositorConfig.value({ comp: "animations", key: "enabled" }) === true, kind: "choice", choicesFrom: "compositor", fallback: "", keywords: ["workspace", "switch", "wipe", "slide", "animation", "effect", "escritorio"] },
        { tune: true, section: "windows", group: "Movement", comp: "glass", key: "overview", label: "Blur behind the overview", kind: "switch", fallback: true, keywords: ["overview", "blur"] },

        { tune: false, section: "windows", group: "Effects", label: "What the compositor draws", kind: "list", bare: true, view: Qt.resolvedUrl("IrisEffects.qml"), showIf: () => ["screen", "window", "border", "cursor"].some(key => CompositorConfig.has("effects", key)), keywords: ["effect", "effects", "shader", "filter", "vignette", "scanlines", "crt", "glow", "trail", "pulse", "border", "cursor", "pointer", "screen", "efecto", "efectos", "filtro", "puntero", "estela", "brillo"] },
        { tune: true, section: "windows", group: "Movement", comp: "input", key: "workspace-auto-back-and-forth", read: "general.workspace_auto_back_and_forth", label: "Jump back to the previous workspace", description: "Picking the workspace you are on takes you to the one before.", kind: "switch", fallback: false },
        { section: "windows", group: "Room for iRiS", label: "The Island", description: "Off lets windows reach the Island's edge; bubbles resting there still keep theirs.", path: "iris.bar.reserveSpace", visibleWhen: "!iris.bar.autoHide", kind: "switch", fallback: true, keywords: ["reserve", "space", "exclusive", "espacio", "reservar"] },
        { tune: true, section: "windows", group: "Room for iRiS", label: "Bubbles on the edges", path: "iris.bubbles.reserve", visibleWhen: "iris.bubbles.attach", kind: "switch", fallback: true, keywords: ["reserve", "space", "exclusive", "espacio", "reservar", "pieces"] },
        { section: "windows", group: "Room for iRiS", label: "The Dock", showIf: () => !IrisFrame.rail, path: "iris.dock.reserveSpace", visibleWhen: "!iris.dock.autoHide", kind: "switch", fallback: true, keywords: ["reserve", "space", "exclusive", "espacio", "reservar"] },
        { tune: true, section: "windows", group: "Room for iRiS", label: "Focus, when kept open", path: "iris.sidebars.left.reserveSpace", kind: "switch", fallback: true, keywords: ["reserve", "space", "sidebar", "panel"] },
        { tune: true, section: "windows", group: "Room for iRiS", label: "Today, when kept open", path: "iris.sidebars.right.reserveSpace", kind: "switch", fallback: true, keywords: ["reserve", "space", "sidebar", "panel"] },
        { section: "windows", group: "Closing", label: "Confirm before closing windows", description: "Asks before the close-window shortcut closes an app.", path: "closeConfirm.enabled", kind: "switch", fallback:false },

        { section: "keyboard", group: "Keyboard", comp: "input", key: "keyboard.layout", label: "Layout", description: "XKB layouts, comma separated: us,es", kind: "text", placeholder: "us", fallback: "", keywords: ["niri", "keyboard", "layout", "xkb", "teclado", "idioma"] },
        { tune: true, section: "keyboard", group: "Keyboard", comp: "input", key: "keyboard.variant", label: "Variant", kind: "text", placeholder: "intl", fallback: "" },
        { tune: true, section: "keyboard", group: "Keyboard", comp: "input", key: "keyboard.options", label: "Options", description: "Such as caps:escape or grp:alt_shift_toggle.", kind: "text", placeholder: "caps:escape", fallback: "" },
        { tune: true, section: "keyboard", group: "Keyboard", comp: "input", key: "keyboard.track-layout", label: "Layout follows", kind: "choice", fallback: "global", choices: [{label:"The session",value:"global"},{label:"Each window",value:"window"}] },
        { section: "keyboard", group: "Keyboard", comp: "input", key: "keyboard.repeat-delay", label: "Repeat after", kind: "range", fallback: 600, min: 150, max: 1000, step: 25, unit: " ms", keywords: ["repeat", "delay"] },
        { section: "keyboard", group: "Keyboard", comp: "input", key: "keyboard.repeat-rate", label: "Repeat speed", kind: "range", fallback: 25, min: 10, max: 80, unit: " /s", keywords: ["repeat", "rate"] },
        { tune: true, section: "keyboard", group: "Keyboard", comp: "input", key: "keyboard.numlock", label: "Num Lock on at login", kind: "switch", fallback: false },
        { section: "keyboard", group: "Keyboard", comp: "input", key: "mod-key", read: "general.mod_key", label: "Shortcut key", description: "What Mod means in your shortcuts.", kind: "choice", fallback: "Super", choices: [{label:"Super",value:"Super"},{label:"Alt",value:"Alt"},{label:"Ctrl",value:"Ctrl"}], keywords: ["mod", "super", "modifier"] },

        { section: "keyboard", group: "Mouse", comp: "input", key: "mouse.accel-speed", label: "Speed", kind: "range", fallback: 0, min: -1, max: 1, step: 0.05, keywords: ["mouse", "sensitivity", "speed", "raton"] },
        { section: "keyboard", group: "Mouse", comp: "input", key: "mouse.accel-profile", label: "Acceleration", tune: true, kind: "choice", fallback: "adaptive", choices: [{label:"Adaptive",value:"adaptive"},{label:"Flat",value:"flat"}] },
        { section: "keyboard", group: "Mouse", comp: "input", key: "mouse.natural-scroll", label: "Natural scrolling", kind: "switch", fallback: false },
        { section: "keyboard", group: "Mouse", comp: "input", key: "mouse.left-handed", label: "Left-handed", tune: true, kind: "switch", fallback: false },
        { tune: true, section: "keyboard", group: "Mouse", comp: "input", key: "mouse.middle-emulation", label: "Middle click with both buttons", kind: "switch", fallback: false },
        { tune: true, section: "keyboard", group: "Mouse", comp: "input", key: "middle-click-paste", label: "Middle click pastes the selection", kind: "switch", fallback: true, keywords: ["primary", "selection", "paste", "pegar"] },

        { section: "keyboard", group: "Trackpad", showIf: () => CompositorConfig.hasTouchpad, comp: "input", key: "touchpad.tap", label: "Tap to click", kind: "switch", fallback: true, keywords: ["touchpad", "trackpad", "tap"] },
        { section: "keyboard", group: "Trackpad", showIf: () => CompositorConfig.hasTouchpad, comp: "input", key: "touchpad.natural-scroll", label: "Natural scrolling", kind: "switch", fallback: true },
        { section: "keyboard", group: "Trackpad", showIf: () => CompositorConfig.hasTouchpad, comp: "input", key: "touchpad.accel-speed", label: "Speed", kind: "range", fallback: 0, min: -1, max: 1, step: 0.05 },
        { section: "keyboard", group: "Trackpad", showIf: () => CompositorConfig.hasTouchpad, comp: "input", key: "touchpad.dwt", label: "Ignore while typing", kind: "switch", fallback: false },
        { section: "keyboard", group: "Trackpad", showIf: () => CompositorConfig.hasTouchpad, comp: "input", key: "touchpad.click-method", label: "Right click", kind: "choice", fallback: "button-areas", choices: [{label:"Bottom corner",value:"button-areas"},{label:"Two fingers",value:"clickfinger"}] },
        { tune: true, section: "keyboard", group: "Trackpad", showIf: () => CompositorConfig.hasTouchpad, comp: "input", key: "touchpad.disabled-on-external-mouse", label: "Off while a mouse is plugged in", kind: "switch", fallback: false },

        { section: "keyboard", group: "Pointer", comp: "input", key: "cursor.xcursor-theme", read: "cursor.theme", label: "Cursor", kind: "choice", choicesFrom: "cursors", fallback: "", keywords: ["cursor", "theme", "pointer"] },
        { section: "keyboard", group: "Pointer", comp: "input", key: "cursor.xcursor-size", read: "cursor.size", label: "Cursor size", kind: "choice", fallback: 24, choices: [{label:"Small",value:16},{label:"Normal",value:24},{label:"Large",value:32},{label:"Larger",value:48}] },
        { tune: true, section: "keyboard", group: "Pointer", comp: "input", key: "cursor.hide-when-typing", label: "Hide while typing", kind: "switch", fallback: false },
        { tune: true, section: "keyboard", group: "Pointer", comp: "input", key: "cursor.hide-after", label: "Hide when still", kind: "choice", fallback: 0, choices: [{label:"Never",value:0},{label:"3 s",value:3000},{label:"10 s",value:10000},{label:"30 s",value:30000}], keywords: ["cursor", "hide", "idle"] },
        { section: "keyboard", group: "Pointer", comp: "input", key: "focus-follows-mouse", read: "general.focus_follows_mouse", label: "Focus follows the pointer", tune: true, description: "The window under the pointer takes the keyboard.", kind: "switch", fallback: false, write: on => on ? 'max-scroll-amount="0%"' : "off" },
        { tune: true, section: "keyboard", group: "Pointer", comp: "input", key: "warp-mouse-to-focus", read: "general.warp_mouse_to_focus", label: "Pointer jumps to the focused window", kind: "switch", fallback: false, write: on => on ? "on" : "off" },
        { tune: true, section: "keyboard", group: "Pointer", comp: "input", key: "focus.hover-raises", label: "Bring it to the front too", description: "Off only gives it the keyboard; a click raises it.", showIf: () => CompositorConfig.value({ comp: "input", key: "focus-follows-mouse" }) === true, kind: "switch", fallback: true },
        { tune: true, section: "keyboard", group: "Pointer", comp: "input", key: "focus-on-activate", label: "Apps may take focus", description: "An app asking for attention comes to the front by itself.", kind: "switch", fallback: false, keywords: ["focus", "steal", "activate", "urgent"] },

        { tune: false, section: "keyboard", group: "Hot corners", label: "What each corner does", kind: "list", bare: true, view: Qt.resolvedUrl("IrisHotCorners.qml"), showIf: () => CompositorConfig.has("corners", "top-left"), keywords: ["hot corner", "corners", "esquinas", "esquinas activas", "overview", "edge"] },
        { section: "keyboard", group: "Hot corners", comp: "corners", key: "delay", label: "Wait before it fires", description: "How long the pointer rests in a corner.", showIf: () => root.cornersUsed(), kind: "choice", fallback: 500, choices: [{label:"At once",value:0},{label:"Short",value:250},{label:"Normal",value:500},{label:"Long",value:1000}] },

        { section: "display", group: "Screen", label: "Screen", kind: "list", bare: true, view: Qt.resolvedUrl("IrisDisplayScreens.qml"), showIf: () => CompositorConfig.outputs.length > 0 && !CompositorConfig.has("display", "arrange"), summary: () => CompositorConfig.screenName(CompositorConfig.output), keywords: ["monitor", "screens", "inches", "model", "pantalla", "monitores", "pulgadas"] },
        { section: "display", group: "Screen", label: "Arrange", kind: "list", bare: true, view: Qt.resolvedUrl("IrisDisplayArrange.qml"), showIf: () => CompositorConfig.has("display", "arrange"), summary: () => CompositorConfig.screenName(CompositorConfig.output), keywords: ["arrange", "layout", "position", "monitors", "left", "right", "above", "below", "posicion", "ordenar", "monitores", "acomodar", "drag"] },
        { section: "display", group: "Screen", comp: "display", key: "on", label: "Turned on", description: "Off leaves it plugged in and dark; its windows move to another screen.", kind: "switch", fallback: true, keywords: ["disable", "enable", "turn off", "apagar", "monitor"] },
        { section: "display", group: "Screen", comp: "display", key: "resolution", label: "Resolution", description: "Applies now; keep it or it goes back in 15 seconds.", kind: "choice", fallback: "", keywords: ["niri", "resolution", "monitor", "resolucion", "mode"] },
        { section: "display", group: "Screen", comp: "display", key: "rate", label: "Refresh rate", kind: "choice", fallback: "", keywords: ["hz", "refresh", "frecuencia"] },
        { section: "display", group: "Screen", label: "Scale", kind: "list", bare: true, view: Qt.resolvedUrl("IrisDisplayScale.qml"), showIf: () => CompositorConfig.output !== null && CompositorConfig.output?.enabled !== false && CompositorConfig.has("display", "scale"), summary: () => `${Math.round(Number(CompositorConfig.displayValue("scale") ?? 1) * 100)} %`, keywords: ["scale", "hidpi", "escala", "zoom", "larger text", "more space"] },
        { section: "display", group: "Screen", comp: "display", key: "transform", label: "Rotation", kind: "choice", fallback: "normal", choices: [], keywords: ["rotate", "rotation", "portrait"] },
        { section: "display", group: "Screen", comp: "display", key: "vrr", label: "Variable refresh", kind: "choice", fallback: "off", keywords: ["vrr", "freesync", "gsync", "adaptive sync"] },
        { tune: true, section: "display", group: "Screen", comp: "display", key: "tearing", label: "Let fullscreen games tear", description: "Frames show the moment they are ready: less delay, a visible seam.", kind: "switch", fallback: false, keywords: ["tearing", "vsync", "latency", "games", "input lag"] },
        { section: "display", group: "Screen", comp: "display", key: "main", label: "Main screen", description: "Where the session starts, new windows open first and one-screen panels appear; games take it as the main one too.", showIf: () => CompositorConfig.outputs.length > 1, kind: "switch", fallback: false, keywords: ["primary", "main", "principal"] },
        { tune: true, section: "display", group: "Screen", comp: "display", key: "direct-scanout", label: "Fullscreen apps draw straight to the screen", description: "Less work and delay in games. Turn it off if a fullscreen app flickers or goes black.", kind: "switch", fallback: true, keywords: ["direct scanout", "fullscreen", "flicker", "black screen", "games", "parpadeo"] },
        { tune: true, section: "display", group: "Screen", comp: "apps", key: "x11-native", label: "Sharp older apps", description: "Games and apps that predate Wayland draw at the screen's real pixels instead of being stretched. From the next login.", showIf: () => CompositorConfig.has("apps", "x11-native") && CompositorConfig.outputs.some(out => Math.abs(Number(out.scale ?? 1) - 1) > 0.01), kind: "switch", fallback: false, keywords: ["xwayland", "x11", "blurry", "steam", "games", "borroso", "native resolution"] },
        { tune: true, section: "windows", group: "Layout", comp: "layout", key: "struts.top", label: "Free space at the top", kind: "range", fallback: 0, min: 0, max: 200, step: 4, unit: " px", showIf: () => CompositorConfig.has("layout", "struts.top") },
        { tune: true, section: "windows", group: "Layout", comp: "layout", key: "struts.bottom", label: "Free space at the bottom", kind: "range", fallback: 0, min: 0, max: 200, step: 4, unit: " px", showIf: () => CompositorConfig.has("layout", "struts.bottom") },
        { tune: true, section: "windows", group: "Layout", comp: "layout", key: "struts.left", label: "Free space on the left", kind: "range", fallback: 0, min: 0, max: 200, step: 4, unit: " px", showIf: () => CompositorConfig.has("layout", "struts.left") },
        { tune: true, section: "windows", group: "Layout", comp: "layout", key: "struts.right", label: "Free space on the right", kind: "range", fallback: 0, min: 0, max: 200, step: 4, unit: " px", showIf: () => CompositorConfig.has("layout", "struts.right") },
        { tune: true, section: "windows", group: "Layout", comp: "windows", key: "dialogs-attached", label: "Dialogs stay with their window", description: "A dialog follows the window it belongs to and holds it until answered.", kind: "switch", fallback: true, showIf: () => CompositorConfig.has("windows", "dialogs-attached") },
        { tune: true, section: "windows", group: "Layout", comp: "windows", key: "restored-maximize", label: "Apps may open maximized", description: "An app that asks to open filling the screen gets it.", kind: "switch", fallback: false, showIf: () => CompositorConfig.has("windows", "restored-maximize") },
        { tune: true, section: "keyboard", group: "Keyboard", comp: "input", key: "cheatsheet", label: "Show the shortcuts at login", kind: "switch", fallback: true, showIf: () => CompositorConfig.has("input", "cheatsheet") },
        { tune: true, section: "keyboard", group: "Tablet", comp: "input", key: "tablet.output", label: "Tablet draws on", kind: "choice", fallback: "", choicesFrom: "compositor", showIf: () => CompositorConfig.has("input", "tablet.output") },
        { tune: true, section: "keyboard", group: "Tablet", comp: "input", key: "tablet.follows-focus", label: "Tablet follows the screen in use", kind: "switch", fallback: false, showIf: () => CompositorConfig.has("input", "tablet.follows-focus") },
        { tune: true, section: "keyboard", group: "Tablet", comp: "input", key: "tablet.left-handed", label: "Turn the tablet around", description: "For the left hand.", kind: "switch", fallback: false, showIf: () => CompositorConfig.has("input", "tablet.left-handed") },
        { tune: true, section: "keyboard", group: "Touch screen", comp: "input", key: "touch.output", label: "Touch belongs to", kind: "choice", fallback: "", choicesFrom: "compositor", showIf: () => CompositorConfig.has("input", "touch.output") },
        { tune: true, section: "display", group: "Screen", comp: "power", key: "lid-screen-off", label: "Closing the lid turns the laptop's screen off", description: "Its windows move to the other screen; opening it brings it back.", kind: "switch", fallback: false, showIf: () => CompositorConfig.has("power", "lid-screen-off") },
        { tune: true, section: "display", group: "Screen", comp: "apps", key: "gpu-sync", label: "Wait for the graphics card", description: "For NVIDIA cards: prevents flicker and stale frames. Off can be smoother where it is not needed.", kind: "switch", fallback: true, showIf: () => CompositorConfig.has("apps", "gpu-sync") },

        { tune: false, section: "display", group: "Workspaces", label: "Workspaces on this screen", kind: "list", bare: true, view: Qt.resolvedUrl("IrisDisplayWorkspaces.qml"), showIf: () => CompositorConfig.output?.enabled !== false && CompositorConfig.has("display", "workspaces"), keywords: ["workspaces", "virtual desktops", "escritorios", "espacios de trabajo", "count", "dynamic", "fixed", "cyclic", "loop", "wrap", "vertical", "horizontal", "axis"] },
        { section: "display", group: "Workspaces", label: "New windows open", kind: "list", bare: true, screen: true, view: Qt.resolvedUrl("IrisLayoutWidth.qml"), showIf: () => CompositorConfig.outputs.length > 1 && CompositorConfig.output?.enabled !== false && CompositorConfig.has("display", "new-width") && root.layoutMode() === "scrolling", keywords: ["column width", "window width", "ultrawide", "ancho", "half", "third"] },

        { tune: false, section: "display", group: "Colour", comp: "display", key: "hdr", label: "HDR", description: "Brighter highlights and deeper colour on a screen that can show them.", kind: "choice", fallback: "off", keywords: ["hdr", "high dynamic range", "hdr10", "brightness", "color"] },
        { section: "display", group: "Colour", comp: "display", key: "sdr-white", label: "Everything else at", description: "How bright ordinary windows are while HDR is on.", showIf: () => String(CompositorConfig.displayValue("hdr")) !== "off", kind: "range", fallback: 203, min: 80, max: 480, step: 10, unit: " nits" },
        { tune: true, section: "display", group: "Colour", comp: "display", key: "sdr-transfer", label: "Ordinary colours follow", description: "The curve for everything that is not HDR. Try the other if windows look washed out or too dark with HDR on.", showIf: () => String(CompositorConfig.displayValue("hdr")) !== "off", kind: "choice", fallback: "gamma22", keywords: ["sdr", "gamma", "srgb", "washed out", "transfer"] },
        { section: "display", group: "Colour", comp: "display", key: "bit-depth", label: "Colour depth", description: "10 bit draws smoother gradients.", kind: "choice", fallback: 8, keywords: ["10 bit", "deep color", "banding", "bits"] },
        { section: "display", group: "Colour", comp: "display", key: "limited-range", label: "Fix a darker picture", description: "On if this screen looks darker at its highest refresh rate than at 60 Hz.", kind: "switch", fallback: false, keywords: ["dark", "black level", "rgb range", "limited", "full", "hdmi", "75 hz", "oscuro", "negro"] }
    ]
    readonly property var dockEdgeChoices: [{ label: "Auto", value: "auto", glyph: "auto_mode" }].concat([
        { label: "Bottom", value: "bottom", glyph: "vertical_align_bottom" }, { label: "Top", value: "top", glyph: "vertical_align_top" },
        { label: "Left", value: "left", glyph: "align_horizontal_left" }, { label: "Right", value: "right", glyph: "align_horizontal_right" }
    ])
    readonly property var barZoneChoices: [
        { label: "Island", value: "island" }, { label: "Workspaces", value: "workspaces" },
        { label: "Current window", value: "window" }, { label: "Time", value: "time" }
    ].concat(IrisPieces.extras.filter(piece => piece.id !== "workspaces").map(piece => ({ label: piece.label, value: piece.id })))
    // Every area, in the order people reach for them: Look, Desktop, Tools, System, More (the clusters). `tip` is the one line a section opens on.
    readonly property var sections: [
        // Home is General (10-25, he: two pages, the useful one not where Settings opens): what he pinned over the shell's own.
        { id: "general", cluster: -1, title: "Home", subtitle: "What you change every day", icon: "home", get tint() { return root.areaTint(this) }, tip: "Settings that shape the whole shell, whichever surface shows them." },
        { id: "appearance", cluster: 0, title: "Style", subtitle: "Presets, colour, material, shape and type", icon: "style", get tint() { return root.areaTint(this) }, tip: "A preset sets the whole look in one tap; every tile under it fine-tunes one part." },
        { id: "wallpaper", cluster: 0, title: "Wallpaper", subtitle: "Shuffle, live wallpapers, the gallery and the overview", icon: "wallpaper", get tint() { return root.areaTint(this) }, tip: "Next wallpaper in the desktop menu changes it once; Shuffle keeps changing it." },
        { id: "motion", cluster: 0, title: "Motion", subtitle: "How every shape grows, moves and settles", icon: "animation", get tint() { return root.areaTint(this) }, tip: "Shorter durations feel snappier; the curve stays the same." },
        { id: "bar", cluster: 1, title: "Island", subtitle: "Composition, size and how the Island responds", icon: "pill", get tint() { return root.areaTint(this) }, tip: "Rest on the Island to peek, click to keep it, scroll for volume." },
        { id: "dock", cluster: 1, title: "Dock", subtitle: "Visibility, material and app icons", icon: "dock_to_bottom", get tint() { return root.areaTint(this) }, tip: "Slide an icon along the Dock to move it. Right-click it for its windows or to float it as a bubble; middle-click opens a new one." },
        { id: "bubbles", cluster: 1, title: "Bubbles & Cards", subtitle: "Pieces you carry and the cards they grow", icon: "bubble_chart", get tint() { return root.areaTint(this) }, tip: "Hold a bubble to carry it; drop it beside the Island to bring it back." },
        { id: "desktop", cluster: 1, title: "Desktop", subtitle: "Widgets and the desktop menu", icon: "widgets", get tint() { return root.areaTint(this) }, tip: "Right-click the desktop to edit widgets." },
        { id: "widgets", cluster: 1, title: "Widgets", subtitle: "Every widget's own options, and how they arrange", icon: "dashboard_customize", get tint() { return root.areaTint(this) }, tip: "Carry a widget near another and it lines up; hold Alt to place it freely." },
        { id: "windows", cluster: 1, title: "Windows", subtitle: "Gaps, borders, corners and how windows move", icon: "select_window", get tint() { return root.areaTint(this) }, tip: "These change right away, for every app." },
        { id: "sidebars", cluster: 1, tilesOnly: true, title: "Side Panels", subtitle: "Focus and Today, arranged around your workflow", icon: "dock_to_right", get tint() { return root.areaTint(this) }, tip: "Ctrl+E customizes a panel; Keep open makes room beside windows." },
        { id: "controlCenter", cluster: 1, title: "Control Center", subtitle: "What it carries and how it looks", icon: "toggle_on", get tint() { return root.areaTint(this) }, tip: "Arrange it in place from the button beside the lock in its header." },
        { id: "spotlight", cluster: 2, title: "Spotlight", subtitle: "Search apps, files, the clipboard and more", icon: "search", get tint() { return root.areaTint(this) }, tip: "Prefixes: ; clipboard, = calculator, / actions." },
        { id: "orbit", cluster: 2, title: "Orbit", subtitle: "Every workspace and window, and the way to any of them", icon: "workspaces", get tint() { return root.areaTint(this) }, tip: "Type to light up where a window is; ↵ takes you to it. Bind inir orbit toggle." },
        { id: "capture", cluster: 2, title: "Screenshots & Recording", subtitle: "Snip, annotate, read Japanese and record", icon: "screenshot_region", get tint() { return root.areaTint(this) }, tip: "Super+Shift+S snips; the toolbar switches to text, search or recording." },
        { id: "player", cluster: 2, title: "Now Playing", subtitle: "Music in the Island, on the lock screen and on the frame", icon: "music_note", get tint() { return root.areaTint(this) }, tip: "Middle-click the Island to play or pause." },
        { id: "anime", cluster: 2, title: "Anime", subtitle: "Airing, Continue and the anime colour layer", icon: "live_tv", get tint() { return root.areaTint(this) }, tip: "Airing tracks what is coming; Continue resumes what you were watching." },
        { id: "notifications", cluster: 3, title: "Notifications", subtitle: "Banners, quiet hours and Do Not Disturb", icon: "notifications", get tint() { return root.areaTint(this) }, tip: "Hover a banner to keep it; swipe it away to dismiss." },
        { id: "sound", cluster: 3, title: "Sound & Feedback", subtitle: "Volume, alert sounds and what the OSD shows", icon: "volume_up", get tint() { return root.areaTint(this) }, tip: "Scroll on the Island for volume; Ctrl for the microphone." },
        { id: "display", cluster: 3, title: "Display", subtitle: "Resolution, scale, night light and bright flashes", icon: "brightness_6", get tint() { return root.areaTint(this) }, tip: "Shift and scroll on the Island for brightness." },
        { id: "keyboard", cluster: 3, title: "Keyboard & Mouse", subtitle: "Layouts, repeat, pointer speed and cursor", icon: "keyboard", get tint() { return root.areaTint(this) }, tip: "Your shortcuts are on Home, Keyboard shortcuts." },
        { id: "battery", cluster: 3, title: "Battery", subtitle: "Warnings, suspend and charge limit", icon: "battery_full", get tint() { return root.areaTint(this) }, tip: "Only matters on a machine with a battery." },
        { id: "gaming", cluster: 3, title: "Gaming & Fullscreen", subtitle: "What iRiS steps back from while you play", icon: "sports_esports", get tint() { return root.areaTint(this) }, tip: "Game mode turns on by itself for fullscreen games." },
        { id: "lock", cluster: 3, title: "Lock Screen", subtitle: "What it shows, when it locks and how it reads", icon: "lock", get tint() { return root.areaTint(this) }, tip: "Rehearse it: the real surface, editable, with nothing to unlock." },
        { id: "login", cluster: 3, title: "Login Screen", subtitle: "Where you sign in after starting the computer", icon: "login", get tint() { return root.areaTint(this) }, tip: "A change shows the next time you sign in." },
        { id: "sources", cluster: 4, title: "Sources", subtitle: "Where the Island gets what it shows", icon: "cloud_sync", get tint() { return root.areaTint(this) }, tip: "A setting belongs here when an iRiS surface puts its data on screen." },
        { id: "system", cluster: 4, title: "Community Hub", subtitle: "Widgets, themes and web apps from other people", icon: "storefront", get tint() { return root.areaTint(this) }, tip: "What people who use iNiR share, reviewed before it is published." }
    ]
    // The sidebar's groups (DI49g, 2026-10-21): each names the areas under it, which the sidebar lists directly; a
    // category's id still opens its first area (`inir iris settings look`).
    readonly property var categories: [
        { id: "look", cluster: 0, title: "Appearance", icon: "style", get tint() { return root.sectionById(this.sections[0]).tint }, sections: ["appearance", "wallpaper", "motion"] },
        { id: "islandDock", cluster: 1, title: "Island & Dock", icon: "pill", get tint() { return root.sectionById(this.sections[0]).tint }, sections: ["bar", "dock", "bubbles"] },
        { id: "desk", cluster: 1, title: "Desktop & Panels", icon: "widgets", get tint() { return root.sectionById(this.sections[0]).tint }, sections: ["desktop", "widgets", "sidebars", "controlCenter"] },
        // One place for what the compositor in use does (his 11-10), under its own name: screens, windows, input.
        { id: "compositor", cluster: 1, get title() { return CompositorConfig.compositorName || "Compositor" }, icon: "select_window", get tint() { return root.sectionById(this.sections[0]).tint }, sections: ["display", "windows", "keyboard"] },
        { id: "tools", cluster: 2, title: "Spotlight & Tools", icon: "search", get tint() { return root.sectionById(this.sections[0]).tint }, sections: ["spotlight", "orbit", "capture"] },
        { id: "media", cluster: 2, title: "Music & Anime", icon: "music_note", get tint() { return root.sectionById(this.sections[0]).tint }, sections: ["player", "anime"] },
        { id: "notifications", cluster: 3, title: "Notifications & Sound", icon: "notifications", get tint() { return root.sectionById(this.sections[0]).tint }, sections: ["notifications", "sound"] },
        { id: "devices", cluster: 3, title: "Battery & Gaming", icon: "battery_full", get tint() { return root.sectionById(this.sections[0]).tint }, sections: ["battery", "gaming"] },
        { id: "lockLogin", cluster: 3, title: "Lock & Login", icon: "lock", get tint() { return root.sectionById(this.sections[0]).tint }, sections: ["lock", "login"] },
        { id: "foot", cluster: 4, title: "", icon: "", get tint() { return root.sectionById(this.sections[0]).tint }, sections: ["sources", "system"], foot: true }
    ]
    function categoryOf(sectionId: string): var {
        return root.categories.find(category => category.sections.includes(sectionId)) ?? root.categories[0]
    }
    // The shared iNiR pages that still act under iRiS, as the Hub entry lists them. Pages for other families stay out.
    readonly property var morePages: [
        { group: "Shell", key: "hub", label: "Community Hub", detail: "Widgets, themes and web apps from other people", icon: "storefront", tintName: "pink", get tint() { return IrisStyle.identity[this.tintName] }, keywords: ["hub", "community", "plugins", "extensions", "widgets", "themes", "store", "download", "install", "comunidad"] },
    ]
    readonly property var sectionOrder: root.sections.map(section => section.id)
    // Customize's areas (Studio's rail, the capsule's sheets): identity, what each is, one line worth knowing.
    readonly property var customizeAreas: [
        { id: "material", label: "Material", glyph: "layers", get tint() { return IrisStyle.identity.purple }, tipOf: "", tip: "Character sets corners, fills and contrast at once; the rows below fine-tune it.",
            about: "What every surface is made of: its character, corners, lines and the frame." },
        { id: "colour", label: "Colour", glyph: "palette", get tint() { return IrisStyle.identity.pink }, tipOf: "", tip: "A wallpaper accent follows every new wallpaper.",
            about: "Accent, highlight, the light bodies carry and how much wallpaper iRiS takes in." },
        { id: "type", label: "Type", glyph: "text_fields", get tint() { return IrisStyle.identity.orange }, tipOf: "", tip: "Figures have their own face: the clock and every level read it.",
            about: "Typefaces, figures and how large text reads." },
        { id: "motion", label: "Motion", glyph: "animation", get tint() { return IrisStyle.identity.indigo }, tipOf: "motion",
            about: "How shapes open, move and settle, everywhere at once or per surface." },
        { id: "island", label: "Island", glyph: "pill", get tint() { return IrisStyle.identity.blue }, tipOf: "bar",
            about: "Its shape on the edge, what it shows at rest, and its pages." },
        { id: "pieces", label: "Pieces", glyph: "bubble_chart", get tint() { return IrisStyle.identity.sky }, tipOf: "bubbles",
            about: "Bubbles off the Island and the bars they form." },
        { id: "bodies", label: "Cards", glyph: "web_asset", get tint() { return IrisStyle.identity.teal }, tipOf: "controlCenter",
            about: "Cards, the Control Center and the player." },
        { id: "places", label: "Panels", glyph: "space_dashboard", get tint() { return IrisStyle.identity.green }, tipOf: "sidebars",
            about: "Side panels, Spotlight, the gallery, Settings and menus." },
        { id: "transients", label: "Feedback", glyph: "notifications", get tint() { return IrisStyle.identity.red }, tipOf: "notifications",
            about: "Notifications and level feedback." },
        { id: "dock", label: "Dock", glyph: "dock_to_bottom", get tint() { return IrisStyle.identity.lavender }, tipOf: "dock",
            about: "The Dock's shape and its icons." },
        { id: "desktop", label: "Desktop", glyph: "widgets", get tint() { return IrisStyle.identity.yellow }, tipOf: "desktop",
            about: "Widgets on the desktop." },
        { id: "themes", label: "Themes", glyph: "style", get tint() { return IrisStyle.identity.gray }, tipOf: "", tip: "A theme is one small file: copy it to share, paste one to try it.",
            about: "Whole redesigns of iRiS, and the ones you save and share." }
    ]
    function customizeArea(id: string): var { return root.customizeAreas.find(area => area.id === id) ?? root.customizeAreas[0] }
    function customizeTip(id: string): string {
        const area = root.customizeArea(id)
        if (area.tip) return Translation.tr(area.tip)
        return area.tipOf.length > 0 ? Translation.tr(root.sectionById(area.tipOf).tip ?? "") : ""
    }
    // Areas folded into another (his 11-02: the whole look in one place): old links, IPC and Customize land there.
    readonly property var retiredAreas: ({ colour: "appearance" })
    function sectionById(id: string): var {
        id = root.retiredAreas[id] ?? id
        return root.sections.find(section => section.id === id) ?? root.sections[0]
    }
    // Groups that are a set of kinds: folded, they say how many are on ("5 of 7"), not the first one's name.
    readonly property var countedGroups: ["Live activities"]
    readonly property var groupGlyphs: ({
        "Shell family": "swap_horiz", "Shell": "swap_horiz", "Language & time": "language", "Apps & login": "rocket_launch", "Notch": "vertical_align_top",
        "Wallpaper shuffle": "shuffle", "Transition": "transition_fade", "Library": "photo_library",
        "Behind windows": "blur_on", "Japanese lookup": "translate", "Parallax": "3d_rotation", "Scaling": "aspect_ratio", "Recording": "screen_record", "Snip": "screenshot_region",
        "Accent": "palette", "Visualizer": "graphic_eq", "Customize": "brush", "Themes": "style", "Presets": "auto_awesome_mosaic", "Settings window": "settings_applications", "Activity": "timer", "Adaptive": "auto_awesome", "App colours": "format_paint", "Airing": "live_tv", "Alert sounds": "music_note",
        "At a glance": "visibility", "At rest": "schedule", "Badges": "notifications_unread", "Banners": "notifications",
        "Bar": "width_full", "Behaviour": "touch_app", "Bubble": "bubble_chart", "Calendar": "calendar_month",
        "Card contents": "view_agenda", "Cards": "web_asset", "Charge limit": "battery_charging_80", "Clipboard": "content_paste", "Connections": "cable", "Notices": "notifications_active", "Live activities": "stream", "Face": "watch", "Clock": "schedule",
        "Colour layer": "palette", "Comfort": "visibility", "Continue": "play_circle", "Control Center": "tune",
        "Curve": "show_chart", "Date & time": "calendar_clock", "Desktop page": "dashboard", "Do Not Disturb": "do_not_disturb_on",
        "Extra bubbles": "add_circle", "Faces": "font_download", "Feedback": "campaign", "Floating": "flight",
        "Focus": "dock_to_left", "Frame": "crop_free", "Frame response": "graphic_eq", "Frame music": "border_outer", "Edge wave": "waves", "Frame finish": "flare", "Prefixes": "keyboard_command_key", "Name song": "music_cast", "System readings": "monitor_heart", "Fullscreen": "fullscreen", "Game mode": "sports_esports",
        "Glass": "blur_on", "Highlight": "highlight", "Icons": "emoji_symbols", "Interaction": "ads_click", "Joining": "join_inner",
        "Language": "language", "Layout": "view_quilt", "Tabs": "tab", "Title bars": "web_asset", "Effects": "auto_fix_high", "Hot corners": "pip_exit", "Colour": "hdr_on", "Workspaces": "view_carousel", "Light": "light_mode", "Live wallpapers": "motion_photos_on", "Glyph art": "grid_on",
        "Desktop menu": "menu_open", "Look": "visibility", "Design": "design_services", "Material": "layers", "Material per surface": "layers", "Corners per surface": "rounded_corner", "Colour theme": "palette", "Signal": "radio_button_checked", "Day and night": "routine", "Scheme": "contrast", "Dark look": "dark_mode", "Ink look": "ink_pen", "Light look": "light_mode", "Menus": "menu", "Motion": "animation", "New iNiR": "rocket_launch",
        "Night Light": "nightlight", "Notifications": "notifications", "Now playing": "music_note", "On the contour": "border_outer",
        "Opening bodies": "open_in_full", "Overview backdrop": "grid_view", "Pages": "view_carousel", "Per surface": "tune",
        "Panel look": "format_paint", "Placement": "location_on", "Player": "music_note", "Player page": "album", "Previews": "preview",
        "Resting Island": "pill", "Scene": "landscape", "Security": "key", "Settings": "settings", "Shape": "rounded_corner",
        "Sign in": "person", "Login screen": "login", "Login Screen": "login", "Wallpaper tint": "format_color_fill", "Size": "straighten", "Sound": "volume_up", "Spotlight": "search",
        "Orbit": "workspaces", "Shelf": "shelves", "Hot corner": "north_east",
        "Status": "signal_cellular_alt", "Style per surface": "motion_mode", "Suspend": "bedtime", "Text": "text_fields", "Timing": "timer", "Today": "dock_to_right",
        "Touch": "touch_app", "Tray": "inventory_2", "Type": "text_fields", "Updates": "system_update_alt", "Visibility": "visibility",
        "Volume": "volume_up", "VPN": "vpn_lock", "Wallpaper": "wallpaper", "Wallpaper gallery": "photo_library",
        "Warnings": "battery_alert", "Weather": "partly_cloudy_day", "When idle": "hourglass_empty", "Widgets": "widgets",
        "Windows": "select_window", "Workspaces": "view_column", "Apps": "apps", "At login": "rocket_launch", "Every day": "bolt", "Performance": "speed", "Web search": "travel_explore",
        "Read text": "document_scanner", "Texture": "texture", "Borders": "border_style", "Edges": "border_style", "Movement": "animation", "Closing": "close",
        "Room for iRiS": "fit_screen", "Keyboard": "keyboard", "Mouse": "mouse", "Trackpad": "touch_app", "Tablet": "stylus_note", "Touch screen": "touch_app", "Pointer": "arrow_selector_tool", "Screen": "monitor",
        "Arranging": "drag_pan", "Power saving": "energy_savings_leaf", "World clock": "public", "Month Calendar": "calendar_month", "Upcoming Events": "event_upcoming", "Date badge": "today", "Day progress": "wb_twilight", "Timers": "timer", "System uptime": "history", "Media Controls": "album", "System Monitor": "monitoring", "Battery": "battery_full", "Controls": "toggle_on", "Screen time": "hourglass_top", "News": "newspaper", "Notes": "sticky_note_2", "Todo": "checklist", "User card": "account_circle", "Custom image": "image", "Image converter": "transform", "Decorative shape": "interests", "Japanese Typography": "translate", "Editorial": "article", "Mascot": "pets", "Hotspot": "wifi_tethering", "Network": "language", "Screens": "desktop_windows"
    })
    // Colour by family (his pick 10-31, "Bands"): each sidebar cluster is a band of neighbouring identity hues, its areas
    // take them in turn and an area's groups go round the band from the area's own, so a hue says which part of the
    // shell a mark belongs to before its glyph is read. Home and More stay grey; the accent keeps chosen and focus.
    readonly property var clusterBands: ({ "-1": ["gray"], "0": ["purple", "pink", "lavender"], "1": ["blue", "indigo", "sky"],
        "2": ["teal", "green"], "3": ["red", "orange", "yellow"], "4": ["gray"] })
    function bandTint(cluster: int, step: int): color {
        const band = root.clusterBands[String(cluster)] ?? ["gray"]
        return IrisStyle.identity[band[((step % band.length) + band.length) % band.length]]
    }
    function areaStep(area: var): int {
        return Math.max(0, root.sections.filter(entry => entry.cluster === area.cluster).findIndex(entry => entry.id === area.id))
    }
    function areaTint(area: var): color { return root.bandTint(area.cluster, root.areaStep(area)) }
    // Each group's own hue as v2.33 named it, for Settings' Original design (IrisStyle.settingsOriginal); a group born
    // since takes its band's hue (groupTint).
    readonly property var originalGroupTints: ({
        get "Shell family"() { return IrisStyle.identity.purple },
        get "Shell"() { return IrisStyle.identity.purple },
        get "Language & time"() { return IrisStyle.identity.teal },
        get "Apps & login"() { return IrisStyle.identity.pink },
        get "Notch"() { return IrisStyle.identity.blue },
        get "About iNiR"() { return IrisStyle.identity.lavender },
        get "Accent"() { return IrisStyle.identity.blue },
        get "Activity"() { return IrisStyle.identity.orange },
        get "Adaptive"() { return IrisStyle.identity.teal },
        get "Airing"() { return IrisStyle.identity.purple },
        get "Alert sounds"() { return IrisStyle.identity.pink },
        get "App colours"() { return IrisStyle.identity.orange },
        get "Apps"() { return IrisStyle.identity.pink },
        get "At a glance"() { return IrisStyle.identity.sky },
        get "At rest"() { return IrisStyle.identity.indigo },
        get "Badges"() { return IrisStyle.identity.red },
        get "Banners"() { return IrisStyle.identity.red },
        get "Bar"() { return IrisStyle.identity.indigo },
        get "Behaviour"() { return IrisStyle.identity.green },
        get "Behind windows"() { return IrisStyle.identity.indigo },
        get "Borders"() { return IrisStyle.identity.orange },
        get "Bubble"() { return IrisStyle.identity.sky },
        get "Calendar"() { return IrisStyle.identity.red },
        get "Card contents"() { return IrisStyle.identity.teal },
        get "Cards"() { return IrisStyle.identity.blue },
        get "Charge limit"() { return IrisStyle.identity.green },
        get "Clipboard"() { return IrisStyle.identity.teal },
        get "Clock"() { return IrisStyle.identity.orange },
        get "Closing"() { return IrisStyle.identity.red },
        get "Room for iRiS"() { return IrisStyle.identity.teal },
        get "Colour layer"() { return IrisStyle.identity.pink },
        get "Comfort"() { return IrisStyle.identity.yellow },
        get "Continue"() { return IrisStyle.identity.green },
        get "Control Center"() { return IrisStyle.identity.gray },
        get "Curve"() { return IrisStyle.identity.teal },
        get "Date & time"() { return IrisStyle.identity.orange },
        get "Desktop page"() { return IrisStyle.identity.teal },
        get "Do Not Disturb"() { return IrisStyle.identity.indigo },
        get "Extra bubbles"() { return IrisStyle.identity.green },
        get "Faces"() { return IrisStyle.identity.gray },
        get "Feedback"() { return IrisStyle.identity.orange },
        get "Floating"() { return IrisStyle.identity.sky },
        get "Focus · left"() { return IrisStyle.identity.green },
        get "Frame"() { return IrisStyle.identity.gray },
        get "Fullscreen"() { return IrisStyle.identity.blue },
        get "Game mode"() { return IrisStyle.identity.purple },
        get "Glass"() { return IrisStyle.identity.sky },
        get "Edges"() { return IrisStyle.identity.sky },
        get "Highlight"() { return IrisStyle.identity.orange },
        get "Icons"() { return IrisStyle.identity.yellow },
        get "Interaction"() { return IrisStyle.identity.green },
        get "Connections"() { return IrisStyle.identity.blue },
        get "Notices"() { return IrisStyle.identity.orange },
        get "Live activities"() { return IrisStyle.identity.green },
        get "Face"() { return IrisStyle.identity.indigo },
        get "Japanese lookup"() { return IrisStyle.identity.purple },
        get "Joining"() { return IrisStyle.identity.teal },
        get "Keyboard"() { return IrisStyle.identity.gray },
        get "Keyboard shortcuts"() { return IrisStyle.identity.indigo },
        get "Language"() { return IrisStyle.identity.teal },
        get "Layout"() { return IrisStyle.identity.blue },
        get "Light"() { return IrisStyle.identity.yellow },
        get "Live wallpapers"() { return IrisStyle.identity.pink },
        get "Glyph art"() { return IrisStyle.identity.pink },
        get "Login screen"() { return IrisStyle.identity.indigo },
        get "Login Screen"() { return IrisStyle.identity.indigo },
        get "Wallpaper tint"() { return IrisStyle.identity.teal },
        get "Look"() { return IrisStyle.identity.purple },
        get "Material"() { return IrisStyle.identity.indigo },
        get "Material per surface"() { return IrisStyle.identity.indigo },
        get "Menus"() { return IrisStyle.identity.gray },
        get "Motion"() { return IrisStyle.identity.indigo },
        get "Mouse"() { return IrisStyle.identity.blue },
        get "Movement"() { return IrisStyle.identity.indigo },
        get "New iNiR"() { return IrisStyle.identity.purple },
        get "Night Light"() { return IrisStyle.identity.orange },
        get "Notifications"() { return IrisStyle.identity.red },
        get "Now playing"() { return IrisStyle.identity.pink },
        get "On the contour"() { return IrisStyle.identity.teal },
        get "Opening bodies"() { return IrisStyle.identity.blue },
        get "Overview backdrop"() { return IrisStyle.identity.indigo },
        get "Pages"() { return IrisStyle.identity.blue },
        get "Panel look"() { return IrisStyle.identity.green },
        get "Parallax"() { return IrisStyle.identity.teal },
        get "Per surface"() { return IrisStyle.identity.orange },
        get "Performance"() { return IrisStyle.identity.green },
        get "Placement"() { return IrisStyle.identity.red },
        get "Player"() { return IrisStyle.identity.pink },
        get "Player page"() { return IrisStyle.identity.pink },
        get "Pointer"() { return IrisStyle.identity.orange },
        get "Previews"() { return IrisStyle.identity.teal },
        get "Read text"() { return IrisStyle.identity.blue },
        get "Recording"() { return IrisStyle.identity.pink },
        get "Resting Island"() { return IrisStyle.identity.blue },
        get "Scene"() { return IrisStyle.identity.teal },
        get "Screen"() { return IrisStyle.identity.blue },
        get "Security"() { return IrisStyle.identity.gray },
        get "Settings"() { return IrisStyle.identity.gray },
        get "Shape"() { return IrisStyle.identity.purple },
        get "Sign in"() { return IrisStyle.identity.blue },
        get "Size"() { return IrisStyle.identity.orange },
        get "Snip"() { return IrisStyle.identity.orange },
        get "Sound"() { return IrisStyle.identity.pink },
        get "Spotlight"() { return IrisStyle.identity.blue },
        get "Orbit"() { return IrisStyle.identity.indigo },
        get "Shelf"() { return IrisStyle.identity.teal },
        get "Hot corner"() { return IrisStyle.identity.orange },
        get "Status"() { return IrisStyle.identity.green },
        get "Style per surface"() { return IrisStyle.identity.purple },
        get "Suspend"() { return IrisStyle.identity.indigo },
        get "Text"() { return IrisStyle.identity.gray },
        get "Texture"() { return IrisStyle.identity.orange },
        get "Timing"() { return IrisStyle.identity.orange },
        get "Today · right"() { return IrisStyle.identity.orange },
        get "Touch"() { return IrisStyle.identity.green },
        get "Trackpad"() { return IrisStyle.identity.teal },
        get "Tray"() { return IrisStyle.identity.teal },
        get "Type"() { return IrisStyle.identity.gray },
        get "Updates"() { return IrisStyle.identity.green },
        get "VPN"() { return IrisStyle.identity.blue },
        get "Visibility"() { return IrisStyle.identity.blue },
        get "Volume"() { return IrisStyle.identity.pink },
        get "Wallpaper"() { return IrisStyle.identity.teal },
        get "Wallpaper gallery"() { return IrisStyle.identity.purple },
        get "Warnings"() { return IrisStyle.identity.red },
        get "Weather"() { return IrisStyle.identity.sky },
        get "Web search"() { return IrisStyle.identity.teal },
        get "When idle"() { return IrisStyle.identity.indigo },
        get "Widgets"() { return IrisStyle.identity.teal },
        get "Windows"() { return IrisStyle.identity.blue },
        get "Workspaces"() { return IrisStyle.identity.indigo }
    })
    function groupTint(section: string, at: int): color {
        const area = root.sectionById(section)
        return root.bandTint(area.cluster, root.areaStep(area) + at)
    }
    // A group's hue in the design Settings wears: Original's named one when v2.33 had the group.
    function groupHue(section: string, at: int, key: string): color {
        return IrisStyle.settingsOriginal ? (root.originalGroupTints[key] ?? root.groupTint(section, at)) : root.groupTint(section, at)
    }
    function sectionOf(spec: var): string {
        const path = String(spec.path ?? "")
        const group = String(spec.group ?? "")
        switch (spec.target) {
        case "island": return "bar"
        case "pieces": return "bubbles"
        case "bodies": return path.startsWith("iris.player.") ? "player" : group === "Control Center" ? "controlCenter" : "bubbles"
        case "places":
            if (path.startsWith("iris.wallpaper.") || path.includes(".gallery.")) return "desktop"
            if (group === "Spotlight") return "spotlight"
            if (group === "Orbit") return "orbit"
            if (group === "Panel look") return "sidebars"
            return "appearance"
        case "transients": return group === "Notifications" || group === "Banners" ? "notifications" : "sound"
        case "motion": return "motion"
        case "dock": return "dock"
        case "desktop": return "desktop"
        default: return "appearance"
        }
    }
    // Spotlight's "/" actions come from the rows themselves, so nothing is listed twice: every switch
    // Settings shows flips in place, the widget design and accents pick a value, and themes apply.
    // What "/" lists first with nothing typed: the switches people flip during a day.
    readonly property var quickFirst: ["iris.bar.notch", "iris.widgets.legibleAlways", "notifications.silent", "light.night.enabled",
        "performance.lowPower", "iris.bar.autoHide", "iris.surround.enable", "iris.appearance.anime.enabled", "iris.appearance.motion"]
    function quickActions(): var {
        const out = []
        for (const spec of root.settings) {
            if (!spec.path || !root.shown(spec)) continue
            const section = root.sectionById(String(spec.section ?? ""))
            const place = Translation.tr(section.title) + (spec.group ? " › " + Translation.tr(String(spec.group)) : "")
            const words = [spec.label, spec.group ?? "", section.title].concat(spec.keywords ?? []).join(" ")
            const icon = root.groupGlyphs[String(spec.group ?? "")] ?? section.icon
            if (spec.kind === "switch") {
                const first = root.quickFirst.indexOf(spec.path)
                out.push({ id: "set:" + spec.path, name: Translation.tr(spec.label), english: spec.label, detail: place, icon: icon, tint: section.tint,
                    area: section.id, areaName: Translation.tr(section.title),
                    words: words, priority: first >= 0 ? first : 100, isOn: () => spec.invert ? !Boolean(root.currentValue(spec)) : Boolean(root.currentValue(spec)),
                    run: () => root.commit(spec, !Boolean(root.currentValue(spec))) })
            } else if (spec.kind === "choice" && (spec.widgetDesign || spec.path === "iris.widgets.tint")) {
                for (const choice of root.choicesOf(spec))
                    out.push({ id: "set:" + spec.path + "=" + choice.value, name: Translation.tr(spec.quickName ?? spec.label) + ": " + Translation.tr(choice.label),
                        english: (spec.quickName ?? spec.label) + " " + choice.label, area: section.id, areaName: Translation.tr(section.title), detail: place, icon: String(choice.glyph ?? icon), tint: section.tint, words: words + " " + choice.label, priority: 50, pick: true,
                        isOn: () => root.currentValue(spec) === choice.value, run: () => root.commit(spec, choice.value) })
            }
        }
        for (const theme of IrisThemes.all)
            out.push({ id: "theme:" + theme.id, name: Translation.tr("Theme: %1").arg(theme.name), english: "Theme " + theme.name, detail: Translation.tr("Theme"), pick: true,
                area: "appearance", areaName: Translation.tr("Appearance"),
                icon: "palette", get tint() { return IrisStyle.identity.purple }, words: ["theme", "look", theme.name].concat(theme.tags ?? []).join(" "), priority: 60,
                isOn: () => IrisThemes.activeId === theme.id && !IrisThemes.modified, run: () => IrisThemes.choose(theme) })
        return out
    }
    // The order a section's groups are listed in: what someone came to change first, the rest as they were declared.
    // Style's tiles in bands under a name (his 11-02: "no se sabe qué se está cambiando"): what the colour is, what the
    // bodies are made of, their shape and type, and what few people touch. A group no band names goes in the last.
    readonly property var groupBands: ({
        appearance: [
            // The three picks that change everything at once, one short row: a preset, the Design, the look's dialect.
            { title: "Whole look", glyph: "auto_awesome_mosaic", groups: ["Presets", "Design", "Look"] },
            { title: "Colour", glyph: "palette", groups: ["Scheme", "Accent", "Highlight", "Signal", "Colour theme", "Day and night", "App colours", "Wallpaper tint", "Dark look", "Ink look", "Light look"] },
            { title: "Material", glyph: "layers", groups: ["Material", "Glass", "Texture", "Light", "Edges"] },
            { title: "Shape and type", glyph: "rounded_corner", groups: ["Shape", "Corners per surface", "Frame", "Text", "Faces", "Icons"] },
            { title: "More", glyph: "tune", groups: [] }
        ]
    })
    readonly property var groupOrder: ({
        controlCenter: ["Control Center", "Hotspot", "VPN"],
        general: ["Every day", "Language & time", "Apps & login", "Shell", "Settings window"],
        appearance: ["Presets", "Scheme", "Accent", "Highlight", "Signal", "Look", "Colour theme", "Day and night", "App colours", "Wallpaper tint",
            "Dark look", "Ink look", "Light look", "Design", "Material", "Glass", "Texture", "Light", "Edges", "Shape", "Corners per surface",
            "Frame", "Text", "Faces", "Icons", "Material per surface", "Menus", "Settings", "Badges", "Customize", "Previews", "Adaptive"],
        bar: ["Design and modes", "Face", "Notch", "Layout", "Shape", "At rest", "Resting Island", "Bar", "Pages", "Desktop page", "Player page", "Interaction", "Visibility", "Live activities", "Notices", "Connections"],
        bubbles: ["Size", "Behaviour", "On the contour", "Floating", "Opening bodies", "Cards", "Card contents", "Joining", "Tray"],
        dock: ["Notch", "Look", "Icons", "Visibility"],
        desktop: ["Widgets", "Desktop menu"],
        // The screen itself comes first: its picture, then what it runs at, then its colour.
        display: ["Screen", "Workspaces", "Colour", "Screens"],
        widgets: DesktopWidgetOptions.order,
        wallpaper: ["Wallpaper shuffle", "Transition", "Live wallpapers", "Glyph art", "Wallpaper gallery", "Library", "Scaling", "Behind windows", "Parallax", "Overview backdrop"],
        lock: ["When idle", "Security", "Scene", "Clock", "At a glance", "Now playing", "Activity", "Status", "Sign in", "Type"],
        player: ["Bubble", "Visualizer", "Player", "Frame music", "Edge wave", "Frame response", "Frame finish"]
    })
    // Home's live switches (not config) and what it holds until it is given its own rows.
    readonly property var homeDefault: ["iris.appearance.scheme", "iris.appearance.accent", "iris.appearance.look", "iris.appearance.glass.mode", "notifications.silent", "nightLight", "gameMode"]
    readonly property var dailySwitches: [
        { id: "nightLight", section: "display", label: "Night Light", kind: "switch", state: () => Hyprsunset.active, set: on => { if (Boolean(on) !== Hyprsunset.active) Hyprsunset.toggle() }, keywords: ["night", "warm", "blue light"] },
        { id: "gameMode", section: "gaming", label: "Game mode", kind: "switch", state: () => GameMode.active, set: on => { if (Boolean(on) !== GameMode.active) GameMode.toggle() } }
    ]
    // The way into the sheet that edits them, last under them.
    property bool homeEditing: false
    readonly property var homeEdit: ({ section: "general", group: "Every day", label: "Customize", kind: "action", button: "Edit", run: () => root.homeEditing = true, keywords: ["home", "pin", "favourites", "shortcuts", "inicio"] })
    // Every row Home can hold, for the sheet: the live switches, then every other area's rows that set a value in
    // place; `daily` ones are offered before anything is typed.
    readonly property var homeSuggested: root.homeDefault.concat(["background.autoWallpaper.enable", "iris.dock.autoHide", "iris.appearance.motion", "light.night.colorTemperature", "audio.protection.enable"])
    readonly property var homeCandidates: {
        const out = []
        const add = (spec, value) => {
            const area = root.sectionById(String(spec.section ?? ""))
            const label = String(spec.label ?? "")
            const group = String(spec.group ?? "")
            out.push({ value: value, label: label, area: String(area?.title ?? ""), group: group !== label ? group : "", icon: String(area?.icon ?? "settings"),
                get tint() { return area?.tint ?? IrisStyle.identity.gray }, daily: root.homeSuggested.includes(value),
                search: [label, Translation.tr(label), group, Translation.tr(group), String(area?.title ?? ""), Translation.tr(String(area?.title ?? ""))].concat(spec.keywords ?? []).join(" ").toLowerCase() })
        }
        root.dailySwitches.forEach(spec => add(spec, spec.id))
        const seen = new Set()
        for (const spec of root.settings) {
            if (!spec.path || spec.mirror || spec.section === "general" || seen.has(spec.path) || !["switch", "choice", "range"].includes(String(spec.kind))) continue
            seen.add(spec.path)
            add(spec, spec.path)
        }
        return out
    }
    readonly property var movedGroups: ({
        desktop: { to: "wallpaper", groups: ["Wallpaper shuffle", "Scaling", "Live wallpapers", "Glyph art", "Wallpaper gallery", "Behind windows", "Parallax", "Overview backdrop"] }
    })
    function placed(spec: var): var {
        const move = root.movedGroups[String(spec.section ?? "")]
        return move && move.groups.indexOf(String(spec.group ?? "")) >= 0 ? root.derive(spec, { section: move.to }) : spec
    }
    readonly property var settings: {
        // A widget goes on or off in Desktop's grid; Widgets holds only what each one on the desktop offers.
        const rows = root.behaviour.concat(root.glyphRows).concat(root.shared).concat(root.niriRows).concat(DesktopWidgetOptions.rows.filter(spec => !spec.widgetEnable)).concat(root.edgeRows).map(spec => root.placed(spec))
        const known = new Set(rows.filter(spec => !spec.mirror).map(spec => spec.path))
        const own = path => rows.find(spec => spec.path === path && !spec.mirror) ?? root.studio.find(spec => spec.path === path && !spec.mirror)
        // Home: the rows it was given (Customize › On Home), each the area's own row said once more.
        for (const id of Array.from(Config.options?.iris?.appearance?.settingsHome ?? root.homeDefault)) {
            const spec = root.dailySwitches.find(entry => entry.id === id) ?? own(id)
            if (spec) rows.push(root.derive(spec, { section: "general", group: "Every day", mirror: true,
                origin: { section: String(spec.section ?? root.placed(root.derive({ section: root.sectionOf(spec) }, spec)).section), group: String(spec.group ?? "") }, tune: false, description: undefined, cards: undefined, tiles: undefined, visibleWhen: undefined, target: undefined }))
        }
        rows.push(root.homeEdit)
        const look = []
        for (const spec of root.studio) {
            if (spec.mirror) { look.push(root.placed(root.derive({ section: root.sectionOf(spec) }, spec))); continue }
            if (spec.path !== undefined && known.has(spec.path)) continue
            if (spec.path !== undefined) known.add(spec.path)
            look.push(root.placed(root.derive({ section: root.sectionOf(spec) }, spec)))
        }
        const out = []
        for (const section of root.sectionOrder) {
            const own = rows.filter(spec => spec.section === section).concat(look.filter(spec => spec.section === section))
            const order = root.groupOrder[section] ?? []
            const rank = spec => { const at = order.indexOf(String(spec.group ?? "")); return at < 0 ? order.length : at }
            const lookRank = spec => spec.trail ? 2 : String(spec.path ?? "").startsWith("iris.appearance.surfaces.") ? 1 : 0
            own.map((spec, at) => ({ spec: spec, at: at })).sort((a, b) => rank(a.spec) - rank(b.spec) || lookRank(a.spec) - lookRank(b.spec) || a.at - b.at).forEach(item => out.push(item.spec))
        }
        // A row's key is what it is, not where it falls: keyed by index, one row more or less above shifted every key
        // and every page rebuilt all its rows on a write (tiles went blank while they came back, 10-25).
        const seen = {}
        return out.map(spec => {
            const what = String(spec.path ?? (spec.comp !== undefined ? spec.comp + ":" + spec.key : spec.label ?? spec.kind))
            const key = "settings:" + spec.section + "/" + String(spec.group ?? "") + "/" + what + (spec.mirror ? ":mirror" : "")
            seen[key] = (seen[key] ?? 0) + 1
            return root.derive(spec, { modelKey: seen[key] > 1 ? key + "#" + seen[key] : key })
        })
    }
}
