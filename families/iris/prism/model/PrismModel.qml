pragma Singleton
import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.settings
import qs.modules.iris.prism.core

// Prism's one model, drawn from iRiS Settings' one registry (IrisOptions): every area is a page, every row of it a
// line of the chart, read, written, undone and said exactly as Classic and Folio do. What Prism adds is its dress:
// each page's place in the sidebar, its tint, the rows its hero says in big type, and the pages that are a view of
// their own (the Hub, Keyboard shortcuts, About). Views never touch Config themselves.
Singleton {
    id: root

    readonly property int revision: Config.revision

    // The sidebar's captions, in order; a page's group comes from its area's cluster in IrisOptions.
    readonly property var groups: ["Shell", "Desktop", "Tools", "System", "iNiR"]
    readonly property var clusterGroups: ({ "-1": "Shell", "0": "Shell", "1": "Desktop", "2": "Tools", "3": "System", "4": "iNiR" })

    // Prism's dress per area: a shorter name where the sidebar wants one, its mark and tint, and the rows the hero says.
    readonly property var dress: ({
        general: { name: "Home", glyph: "home", tint: "blue", lead: ["panelFamily", "time.format"] },
        appearance: { name: "Style", glyph: "palette", tint: "violet", lead: ["iris.appearance.look", "iris.appearance.scheme"] },
        wallpaper: { glyph: "wallpaper", tint: "teal", lead: ["iris.wallpaper.layout", "iris.wallpaper.sort"] },
        motion: { glyph: "animation", tint: "pink", lead: ["iris.appearance.morph", "iris.appearance.theme.curve"] },
        bar: { name: "Island", glyph: "smart_button", tint: "indigo", lead: ["iris.bar.design", "iris.bar.position"] },
        dock: { glyph: "dock_to_bottom", tint: "blue", lead: ["iris.dock.position", "iris.dock.shape"] },
        bubbles: { name: "Bubbles", glyph: "bubble_chart", tint: "pink", lead: ["iris.bubbles.design", "iris.bubbles.join"] },
        desktop: { glyph: "desktop_windows", tint: "amber", lead: ["iris.widgets.design", "iris.widgets.material"] },
        widgets: { glyph: "widgets", tint: "amber", lead: ["background.widgets.editGrid.snap", "background.widgets.powerSaving.enable"] },
        windows: { glyph: "select_window", tint: "teal", lead: [] },
        sidebars: { name: "Side Panels", glyph: "dock_to_right", tint: "green", lead: ["iris.sidebars.right.enable", "iris.sidebars.left.enable"] },
        controlCenter: { glyph: "toggle_on", tint: "green", lead: ["iris.controlCenter.opens", "iris.controlCenter.controls"] },
        spotlight: { glyph: "search", tint: "orange", lead: ["iris.palette.opens", "iris.palette.maxResults"] },
        orbit: { glyph: "grid_view", tint: "violet", lead: ["iris.orbit.opens", "iris.orbit.titles"] },
        capture: { name: "Screenshots & Recording", glyph: "screenshot_region", tint: "orange", lead: ["screenRecord.audioMode", "regionSelector.annotation.useSatty"] },
        player: { name: "Now Playing", glyph: "music_note", tint: "red", lead: ["iris.player.visualizer.style", "iris.player.bubbleOpens"] },
        anime: { glyph: "live_tv", tint: "pink", lead: ["iris.bubbles.extras.anime.enable", "iris.bubbles.extras.watching.enable"] },
        notifications: { glyph: "notifications", tint: "red", lead: ["iris.osd.style", "iris.notifications.duration"] },
        sound: { name: "Sound", glyph: "volume_up", tint: "orange", lead: ["audio.protection.maxAllowed", "audio.protection.maxAllowedIncrease"] },
        display: { glyph: "desktop_windows", tint: "amber", lead: ["light.night.colorTemperature", "light.night.automatic"] },
        keyboard: { glyph: "keyboard", tint: "indigo", lead: [] },
        shortcuts: { name: "Keyboard shortcuts", glyph: "keyboard_command_key", tint: "indigo", lead: [], view: "IrisShortcutsPage.qml", cluster: 3, after: "keyboard" },
        battery: { glyph: "battery_full", tint: "green", lead: ["battery.low", "battery.critical"], needs: "battery" },
        gaming: { name: "Gaming", glyph: "sports_esports", tint: "teal", lead: ["gameMode.autoDetect", "gameMode.disableAnimations"] },
        lock: { name: "Lock", glyph: "lock", tint: "indigo", lead: ["iris.lock.material", "iris.lock.type.clockFont"] },
        login: { name: "Login", glyph: "login", tint: "violet", lead: ["lock.loginScreen", "lock.loginStyle"] },
        sources: { glyph: "cloud_sync", tint: "blue", lead: ["weather.enable", "calendar.externalSync.enable"] },
        system: { glyph: "storefront", tint: "pink", lead: [], view: "IrisHubPage.qml" },
        about: { name: "About", glyph: "info", tint: "grey", lead: [], view: "IrisAboutPage.qml", cluster: 4, after: "system" }
    })

    // Every page: IrisOptions' areas in their order, each with Prism's dress, and Prism's own views where they belong.
    readonly property var pages: {
        const out = []
        const add = (id, base) => {
            const dress = root.dress[id] ?? {}
            if (dress.needs === "battery" && !Battery.available) return
            const cluster = Number(dress.cluster ?? base?.cluster ?? 4)
            out.push({
                pageId: id,
                name: String(dress.name ?? base?.title ?? id),
                group: root.clusterGroups[String(cluster)] ?? "iNiR",
                glyph: String(dress.glyph ?? base?.icon ?? "circle"),
                tint: String(dress.tint ?? "grey"),
                lead: Array.from(dress.lead ?? []),
                view: dress.view ? Qt.resolvedUrl("../../settings/" + dress.view) : "",
                subtitle: String(base?.subtitle ?? ""),
                show: null
            })
        }
        const extras = Object.keys(root.dress).filter(id => root.dress[id].after)
        for (const section of IrisOptions.sections) {
            add(section.id, section)
            for (const id of extras.filter(id => root.dress[id].after === section.id)) add(id, null)
        }
        return out
    }
    readonly property var ids: root.pages.map(page => page.pageId)

    // ── Rows. Every IrisOptions row once, as a line of the chart: its spec, the page and group it lives in, the key
    // that names it and the cover it wears. Home's "Every day" copies are Prism's tiles, not rows; Settings window's
    // three ways to pick a design are one row of drawn layouts here.
    readonly property var designRow: ({
        path: "settingsDesign", label: "Layout", kind: "designs", glyph: "settings_applications", page: "general",
        section: "Settings window", detail: "How Settings lays out its areas.", virtual: true, spec: null, keywords: ["settings", "layout", "design", "prism", "classic", "folio", "original"],
        choices: [{ label: "Prism", value: "prism" }, { label: "Classic", value: "classic" }, { label: "Folio", value: "folio" }, { label: "v2.33", value: "original" }]
    })
    function designRowOf(spec: var): bool {
        return spec.section === "general" && spec.group === "Settings window"
            && (spec.path === "iris.appearance.settingsLayout" || spec.path === "iris.appearance.settingsOriginal" || (spec.kind === "action" && spec.label === "Prism"))
    }
    function coverOf(spec: var): string {
        const own = PrismCovers.byPath[String(spec.path ?? "")]
        if (own) return own
        if (spec.glyph) return String(spec.glyph)
        return String(IrisOptions.groupGlyphs[String(spec.group ?? "")] ?? root.dress[String(spec.section ?? "")]?.glyph ?? "tune")
    }
    readonly property var rows: {
        const out = []
        let designPlaced = false
        for (const spec of IrisOptions.settings) {
            if (spec.mirror || (spec.section === "general" && spec.group === "Every day")) continue
            if (root.designRowOf(spec)) {
                if (!designPlaced) { out.push(root.designRow); designPlaced = true }
                continue
            }
            out.push({
                spec: spec,
                path: String(spec.path ?? spec.modelKey),
                page: String(spec.section ?? ""),
                section: String(spec.group ?? ""),
                part: String(spec.part ?? ""),
                label: String(spec.label ?? ""),
                detail: String(spec.description ?? ""),
                kind: String(spec.kind ?? ""),
                glyph: root.coverOf(spec),
                choices: spec.choices ?? [],
                keywords: Array.from(spec.keywords ?? [])
            })
        }
        return out
    }

    function page(id: string): var { return root.pages.find(entry => entry.pageId === id) ?? root.pages[0] }
    function find(path: string): var { return root.rows.find(row => row.path === path) ?? null }
    function index(id: string): int { return Math.max(0, root.ids.indexOf(id)) }
    function inGroup(group: string): var { return root.pages.filter(page => page.group === group) }
    function shown(row: var): bool {
        const _ = root.revision
        return row.virtual ? true : IrisOptions.shown(row.spec)
    }
    function rowsOf(id: string): var { return root.rows.filter(row => row.page === id && root.shown(row)) }
    // A page's groups, in IrisOptions' order, each with the rows it shows now.
    function sectionsOf(id: string): var {
        const out = []
        for (const row of root.rowsOf(id)) {
            let group = out.find(entry => entry.title === row.section)
            if (!group) { group = { title: row.section, glyph: String(IrisOptions.groupGlyphs[row.section] ?? root.page(id).glyph), rows: [] }; out.push(group) }
            group.rows.push(row)
        }
        return out
    }
    // A long page is read one group at a time, picked from a strip under the hero; a short one stacks its charts.
    function paged(sections: var): bool {
        return sections.length > 6 || sections.reduce((sum, group) => sum + group.rows.length, 0) > 60
    }

    // ── Values: read, written and said through IrisOptions, so a change takes the same side effects and the same
    // history (Undo, Redo, the settings island) in every Settings.
    function virtual(row: var): bool { return Boolean(row?.virtual) || row?.spec?.path === "panelFamily" }
    function choicesOf(row: var): var {
        const _ = root.revision
        return row.virtual ? row.choices : IrisOptions.choicesOf(row.spec)
    }
    // Which Settings opens: Prism, a classic layout, or the v2.33 design, as one choice over its three keys.
    function settingsDesign(): string {
        const _ = root.revision
        if (String(Config.getNestedValue("iris.appearance.settingsPanel", "prism")) === "prism") return "prism"
        if (Boolean(Config.getNestedValue("iris.appearance.settingsOriginal", false))) return "original"
        return String(Config.getNestedValue("iris.appearance.settingsLayout", "classic"))
    }
    function read(row: var): var {
        const _ = root.revision
        if (row.path === "settingsDesign") return root.settingsDesign()
        const value = IrisOptions.currentValue(row.spec)
        return row.spec.invert && (row.kind === "switch") ? !Boolean(value) : value
    }
    function locked(row: var): bool { const _ = root.revision; return Boolean(row.spec?.locked?.()) }
    function note(row: var): string { const _ = root.revision; return row.spec?.note ? String(row.spec.note() ?? "") : "" }
    function stored(row: var, value: var): var { return row.spec?.invert && row.kind === "switch" ? !Boolean(value) : value }
    function write(row: var, value: var): void {
        if (row.path === "settingsDesign") { root.wearSettings(String(value)); return }
        if (row.kind === "action") { row.spec.run?.(); return }
        IrisOptions.commit(row.spec, root.stored(row, value))
    }
    // A drag shows its value on the desktop without writing it; release writes once, as one change.
    function preview(row: var, value: var): void {
        if (row.virtual || !row.spec.path || row.spec.niri || row.spec.widget || row.spec.bundle) return
        IrisOptions.hold(row.spec)
        Config.previewNestedValue(row.spec.path, root.stored(row, value))
    }
    // Another design takes Prism's place at once, open on Home, where its own Settings window group leads back here.
    function wearSettings(design: string): void {
        if (design === "prism") {
            Config.setNestedValues({ "iris.appearance.settingsPanel": "prism", "iris.appearance.settingsOriginal": false })
            return
        }
        const updates = { "iris.appearance.settingsPanel": "classic", "iris.appearance.settingsOriginal": design === "original" }
        if (design !== "original") updates["iris.appearance.settingsLayout"] = design
        Config.setNestedValues(updates)
        Qt.callLater(() => GlobalStates.openSettingsAt("iris", "general"))
    }

    function same(a: var, b: var): bool { return IrisOptions.same(a, b) }
    // Changed: the row left its factory value. Restorable: Restore defaults may put it back (iRiS's own keys).
    function changed(row: var): bool { const _ = root.revision; return !root.virtual(row) && IrisOptions.changed(row.spec) }
    function restorable(row: var): bool { const _ = root.revision; return !root.virtual(row) && IrisOptions.modified(row.spec) }
    function changedOf(id: string): var { return root.rows.filter(row => row.page === id && root.changed(row)) }
    // What Restore defaults would put back on a page (iRiS's own keys; shared ones stay as the person set them).
    function restorableOf(id: string): int { return root.rows.filter(row => row.page === id && root.restorable(row)).length }
    readonly property var changes: { const _ = root.revision; return root.rows.filter(row => root.changed(row)) }
    function restore(id: string): void { IrisOptions.restore(root.rows.filter(row => row.page === id && !root.virtual(row)).map(row => row.spec)) }
    function restoreRow(row: var): void { IrisOptions.restore([row.spec]) }

    function say(row: var, value: var): string {
        if (row.virtual) return Translation.tr((row.choices.find(choice => choice.value === value) ?? {}).label ?? "")
        if (row.kind === "switch") return Boolean(value) ? Translation.tr("On") : Translation.tr("Off")
        return IrisOptions.say(row.spec, root.stored(row, value))
    }
    function sayNow(row: var): string { return root.say(row, root.read(row)) }
    function figure(row: var, value: var): string { return IrisOptions.rangeText(row.spec, value) }

    // Pins: the rows the person keeps at hand, Home's list in every Settings.
    function pinnable(row: var): bool { return !row.virtual && IrisOptions.pinValue(row.spec).length > 0 }
    function pinned(row: var): bool { const _ = root.revision; return !row.virtual && IrisOptions.onHome(row.spec) }
    function togglePin(row: var): void { if (root.pinnable(row)) IrisOptions.togglePin(row.spec) }
    function pinnedRows(): var {
        const _ = root.revision
        return IrisOptions.homeList().map(id => root.rows.find(row => !row.virtual && IrisOptions.pinValue(row.spec) === id)).filter(Boolean)
    }

    // Search: a row's name, what it does, its words and its page's name, in the person's language and in English.
    function search(query: string): var {
        const words = String(query ?? "").toLowerCase().trim().split(/\s+/).filter(word => word.length > 0)
        if (words.length === 0) return []
        return root.rows.filter(row => root.shown(row)).map(row => {
            const label = String(row.label ?? "")
            const detail = String(row.detail ?? "")
            const name = (Translation.tr(label) + " " + label).toLowerCase()
            const rest = (Translation.tr(detail) + " " + detail + " " + Translation.tr(String(root.page(row.page)?.name ?? "")) + " "
                + Translation.tr(String(row.section ?? "")) + " " + Array.from(row.keywords ?? []).join(" ") + " "
                + Array.from(row.choices ?? []).map(choice => Translation.tr(String(choice.label ?? ""))).join(" ")).toLowerCase()
            let score = 0
            for (const word of words) {
                if (name.startsWith(word)) score += 6
                else if (name.includes(word)) score += 4
                else if (rest.includes(word)) score += 1
                else return { row: row, score: -1 }
            }
            return { row: row, score: score }
        }).filter(hit => hit.score > 0).sort((a, b) => b.score - a.score).slice(0, 40).map(hit => hit.row)
    }

    function runShow(page: var): void {
        if (!page?.show) return
        GlobalStates.settingsOverlayOpen = false
        Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), String(page.show.target), String(page.show.fn)])
    }
}
