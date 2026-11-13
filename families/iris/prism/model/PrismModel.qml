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
    // The compositor in use has one group under its own name (his 11-10: "todo bajo una sola categoría del compositor
    // en uso"): screens, layout, windows, glass, movement and input, each a page; nothing of it lives anywhere else.
    readonly property string compositorGroup: CompositorConfig.compositorName.length > 0 ? CompositorConfig.compositorName : "Compositor"
    readonly property var groups: ["Shell", "Desktop", root.compositorGroup, "Tools", "System", "iNiR"]
    readonly property var clusterGroups: ({ "-1": "Shell", "0": "Shell", "1": "Desktop", "2": "Tools", "3": "System", "4": "iNiR", "5": root.compositorGroup })

    // Prism's dress per area: a shorter name where the sidebar wants one, its mark and tint, and the rows the hero says.
    readonly property var dress: ({
        general: { name: "Home", glyph: "home", tint: "blue", lead: ["panelFamily", "time.format"] },
        appearance: { name: "Style", glyph: "style", tint: "violet", lead: ["iris.appearance.look", "iris.appearance.design"] },
        colour: { name: "Colour", glyph: "palette", tint: "pink", lead: ["iris.appearance.scheme", "iris.appearance.accent"] },
        surfaces: { name: "Surfaces", glyph: "layers", tint: "teal", lead: ["iris.appearance.theme.surface", "iris.appearance.glass.mode"] },
        typeIcons: { name: "Type & icons", glyph: "text_fields", tint: "orange", lead: ["iris.appearance.theme.text", "iris.appearance.icons.style"] },
        appColours: { name: "App colours", glyph: "format_paint", tint: "blue", lead: ["iris.appearance.accentForApps", "appearance.wallpaperTheming.enableAppsAndShell"] },
        wallpaper: { glyph: "wallpaper", tint: "teal", lead: ["iris.wallpaper.layout", "iris.wallpaper.sort"] },
        motion: { glyph: "animation", tint: "pink", lead: ["iris.appearance.morph", "iris.appearance.theme.curve"] },
        bar: { name: "Island", glyph: "smart_button", tint: "indigo", lead: ["iris.bar.design", "iris.bar.position"] },
        dock: { glyph: "dock_to_bottom", tint: "blue", lead: ["iris.dock.position", "iris.dock.shape"] },
        bubbles: { name: "Bubbles", glyph: "bubble_chart", tint: "pink", lead: ["iris.bubbles.design", "iris.bubbles.join"] },
        desktop: { glyph: "desktop_windows", tint: "amber", lead: ["iris.widgets.design", "iris.widgets.material"] },
        widgets: { glyph: "widgets", tint: "amber", lead: ["background.widgets.editGrid.snap", "background.widgets.powerSaving.enable"] },
        // The compositor's pages (cluster 5), in the order of `order`. A lead with a colon names a compositor row.
        display: { name: "Displays", glyph: "desktop_windows", tint: "amber", cluster: 5, order: 0, lead: ["light.night.colorTemperature"] },
        layout: { name: "Layout", glyph: "view_column_2", tint: "teal", cluster: 5, order: 1, lead: ["layout:mode", "layout:gaps"] },
        windows: { glyph: "select_window", tint: "blue", cluster: 5, order: 2, lead: ["window-rules:corner-radius", "layout:border.enabled", "titlebar:mode"] },
        glass: { name: "Glass & effects", glyph: "blur_on", tint: "violet", cluster: 5, order: 3, lead: ["glass:enabled", "window-rules:blur", "blur:enabled"] },
        movement: { name: "Movement", glyph: "animation", tint: "pink", cluster: 5, order: 4, lead: ["animations:enabled", "animations:duration", "animations:slowdown"] },
        keyboard: { name: "Keyboard", glyph: "keyboard", tint: "indigo", cluster: 5, order: 5, lead: ["input:keyboard.layout", "input:keyboard.repeat-delay"] },
        pointer: { name: "Mouse & pointer", glyph: "mouse", tint: "orange", cluster: 5, order: 7, lead: ["input:cursor.xcursor-theme", "input:cursor.xcursor-size"] },
        sidebars: { name: "Side Panels", glyph: "dock_to_right", tint: "green", lead: ["iris.sidebars.right.enable", "iris.sidebars.left.enable"] },
        controlCenter: { glyph: "toggle_on", tint: "green", lead: ["iris.controlCenter.opens", "iris.controlCenter.controls"] },
        spotlight: { glyph: "search", tint: "orange", lead: ["iris.palette.opens", "iris.palette.maxResults"] },
        orbit: { glyph: "grid_view", tint: "violet", lead: ["iris.orbit.opens", "iris.orbit.titles"] },
        capture: { name: "Screenshots & Recording", glyph: "screenshot_region", tint: "orange", lead: ["screenRecord.audioMode", "regionSelector.annotation.useSatty"] },
        player: { name: "Now Playing", glyph: "music_note", tint: "red", lead: ["iris.player.visualizer.style", "iris.player.bubbleOpens"] },
        anime: { glyph: "live_tv", tint: "pink", lead: ["iris.bubbles.extras.anime.enable", "iris.bubbles.extras.watching.enable"] },
        notifications: { glyph: "notifications", tint: "red", lead: ["iris.osd.style", "iris.notifications.duration"] },
        sound: { name: "Sound", glyph: "volume_up", tint: "orange", lead: ["audio.protection.maxAllowed", "audio.protection.maxAllowedIncrease"] },
        shortcuts: { name: "Keyboard shortcuts", glyph: "keyboard_command_key", tint: "indigo", lead: [], view: "IrisShortcutsPage.qml", cluster: 5, order: 6, after: "keyboard" },
        battery: { glyph: "battery_full", tint: "green", lead: ["battery.low", "battery.critical"], needs: "battery" },
        gaming: { name: "Gaming", glyph: "sports_esports", tint: "teal", lead: ["gameMode.autoDetect", "gameMode.disableAnimations"] },
        lock: { name: "Lock", glyph: "lock", tint: "indigo", lead: ["iris.lock.material", "iris.lock.type.clockFont"] },
        login: { name: "Login", glyph: "login", tint: "violet", lead: ["lock.loginScreen", "lock.loginStyle"] },
        sources: { glyph: "cloud_sync", tint: "blue", lead: ["weather.enable", "calendar.externalSync.enable"] },
        system: { glyph: "storefront", tint: "pink", lead: [], view: "IrisHubPage.qml" },
        about: { name: "About", glyph: "info", tint: "grey", lead: [], view: "IrisAboutPage.qml", cluster: 4, after: "system" }
    })

    // An area too long for one page is read as several (his 11-07: Style was "un chorizo", 126 rows in 31 groups): each
    // chapter a page of its own, in the sidebar after the area; a group no chapter names stays on the area's first page.
    readonly property var chapters: ({
        appearance: [
            { id: "appearance", groups: [] },
            { id: "colour", groups: ["Scheme", "Accent", "Highlight", "Signal", "Colour theme", "Day and night", "Wallpaper tint", "Adaptive", "Dark look", "Ink look", "Light look"] },
            { id: "surfaces", groups: ["Material", "Glass", "Texture", "Light", "Edges", "Shape", "Frame", "Material per surface", "Menus", "Settings"] },
            { id: "typeIcons", groups: ["Text", "Faces", "Icons", "Badges"] },
            { id: "appColours", groups: ["App colours"] }
        ],
        windows: [
            { id: "windows", groups: [], head: "Borders" },
            { id: "layout", groups: ["Layout", "Room for iRiS"] },
            { id: "glass", groups: ["Glass behind apps", "Effects"] },
            { id: "movement", groups: ["Movement"] }
        ],
        keyboard: [
            { id: "keyboard", groups: [], head: "Keyboard" },
            { id: "pointer", groups: ["Mouse", "Trackpad", "Pointer", "Hot corners"] }
        ]
    })
    // The page a row of IrisOptions' `section`, group `group` lives on.
    function pageOf(section: string, group: string): string {
        const list = root.chapters[section]
        if (!list) return section
        return (list.find(chapter => chapter.groups.includes(group)) ?? list[0]).id
    }

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
                subtitle: String(dress.subtitle ?? base?.subtitle ?? ""),
                order: Number(dress.order ?? 0),
                cluster: cluster,
                show: null
            })
        }
        const extras = Object.keys(root.dress).filter(id => root.dress[id].after)
        for (const section of IrisOptions.sections) {
            for (const chapter of root.chapters[section.id] ?? [{ id: section.id }]) add(chapter.id, section)
            for (const id of extras.filter(id => root.dress[id].after === section.id)) add(id, null)
        }
        // The compositor's pages stand together after the desktop's, in their own order, wherever their areas sit.
        const own = out.filter(page => page.cluster === 5).sort((a, b) => a.order - b.order)
        const rest = out.filter(page => page.cluster !== 5)
        const at = rest.reduce((last, page, i) => page.cluster <= 1 ? i : last, -1) + 1
        return rest.slice(0, at).concat(own, rest.slice(at))
    }
    readonly property var ids: root.pages.map(page => page.pageId)

    // ── Rows. Every IrisOptions row once, as a line of the chart: its spec, the page and group it lives in, the key
    // that names it and the cover it wears. Home's "Every day" copies are Prism's tiles, not rows; Settings window's
    // three ways to pick a design are one row of drawn layouts here.
    readonly property var designRow: ({
        key: "general|Settings window|settingsDesign", path: "settingsDesign", label: "Layout", kind: "designs", glyph: "settings_applications", page: "general",
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
            const path = String(spec.path ?? spec.modelKey)
            // What the compositor's file needs before anything here applies heads every page of its area.
            for (const chapter of spec.notice ? (root.chapters[String(spec.section)] ?? []) : []) {
                const head = String(chapter.head ?? chapter.groups[0])
                if (head === String(spec.group)) continue
                out.push({ key: [spec.section, head, path, spec.label].join("|"), spec: spec, path: path + "@" + chapter.id, page: chapter.id, section: head, part: "",
                    label: String(spec.label ?? ""), get detail() { return String(spec.description ?? "") }, kind: "action", glyph: root.coverOf(spec), choices: [], keywords: [] })
            }
            out.push({
                // Who the row is across rebuilds: the page's delegates keep their row while values change around it.
                key: [spec.section, spec.group, path, spec.label].join("|"),
                spec: spec,
                path: path,
                page: root.pageOf(String(spec.section ?? ""), String(spec.group ?? "")),
                section: String(spec.group ?? ""),
                part: String(spec.part ?? ""),
                label: String(spec.label ?? ""),
                // A row's choices and description may be getters that read live values (a Design's name and
                // colours): read where the row is drawn, never here, or every one of them rebuilt the whole chart.
                get detail() { return String(spec.description ?? "") },
                kind: String(spec.kind ?? ""),
                glyph: root.coverOf(spec),
                get choices() { return spec.choices ?? [] },
                keywords: Array.from(spec.keywords ?? [])
            })
        }
        // One home per option (his 11-10: "cosas que están repetidas por cualquier lado"): where IrisOptions lists
        // the same control twice, Prism keeps the later one, its own place (the compositor's glass under Windows,
        // reserved room under Room for iRiS); a row shown under another condition is another control and stays.
        const homeOf = row => row.virtual ? "" : (row.spec.comp ? [row.spec.comp + ":" + row.spec.key, row.kind] : [row.path, row.kind, String(row.spec.visibleWhen ?? "")]).join("|")
        const homes = out.map(homeOf)
        const last = ({})
        homes.forEach((home, i) => { last[home] = i })
        return out.filter((row, i) => homes[i].length === 0 || row.path === "undefined" || last[homes[i]] === i)
    }

    function page(id: string): var { return root.pages.find(entry => entry.pageId === id) ?? root.pages[0] }
    function find(path: string): var { return root.rows.find(row => row.path === path) ?? null }
    // What a page's hero says: the machine's own facts first (the screen as it runs now), then its leading rows that
    // the compositor in use shows, two lines at most.
    function leadOf(page: var): var {
        const _ = root.revision
        const out = root.factsOf(String(page?.pageId ?? ""))
        for (const id of Array.from(page?.lead ?? [])) {
            if (out.length >= 2) break
            const named = String(id)
            const row = named.includes(":")
                ? root.rows.find(row => !row.virtual && row.spec.comp !== undefined && row.spec.comp + ":" + row.spec.key === named && root.shown(row))
                : root.find(named)
            // A row with nothing to say yet (a list, an unset name) leaves the line to the next.
            if (row && String(root.sayNow(row) ?? "").length > 0) out.push(row)
        }
        return out
    }
    function factsOf(id: string): var {
        if (id !== "display") return []
        const _ = CompositorConfig.revision
        const screen = CompositorConfig.output
        const size = CompositorConfig.resolutionLabel(screen)
        if (!screen || size.length === 0) return []
        const rate = CompositorConfig.rateLabel(screen.current_rate_string)
        const out = [{ fact: true, say: size, label: [CompositorConfig.screenName(screen), rate].filter(part => part.length > 0).join(" · ") }]
        // What this very screen can do beyond the plain picture: its rows are on the page only because it can.
        const can = [screen.hdr_supported === true ? "HDR" : "", screen.vrr_supported === true ? "VRR" : ""].filter(part => part.length > 0)
        if (can.length > 0) out.push({ fact: true, say: can.join(" · "), label: Translation.tr("This screen can") })
        return out
    }
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
    // A page's groups with every row this machine allows, shown now or not: where a long page splits (IrisOptions.fits).
    function layoutOf(id: string): var {
        const _ = root.revision
        const out = []
        for (const row of root.rows) {
            if (row.page !== id || !(row.virtual || IrisOptions.fits(row.spec))) continue
            let group = out.find(entry => entry.title === row.section)
            if (!group) { group = { title: row.section, rows: [] }; out.push(group) }
            group.rows.push(row)
        }
        return out
    }
    // A long page is read one group at a time, picked from a strip under the hero; a short one stacks its charts.
    function paged(sections: var): bool {
        // Past about two screens of rows a page is read in parts; the group count alone never splits it.
        return sections.reduce((sum, group) => sum + group.rows.length, 0) > 44
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
    // Where a level's drag holds: the value the row has with nothing set (NaN: none known).
    function home(row: var): real {
        const _ = root.revision
        const factory = root.virtual(row) ? undefined : IrisOptions.factory(row.spec)
        return factory === undefined || factory === null || !Number.isFinite(Number(factory)) ? NaN : Number(factory)
    }
    function stored(row: var, value: var): var { return row.spec?.invert && row.kind === "switch" ? !Boolean(value) : value }
    function write(row: var, value: var): void {
        if (row.path === "settingsDesign") { root.wearSettings(String(value)); return }
        if (row.kind === "action") { row.spec.run?.(); return }
        IrisOptions.commit(row.spec, root.stored(row, value))
    }
    // A drag shows its value on the desktop without writing it; release writes once, as one change.
    function preview(row: var, value: var): void {
        if (row.virtual || !row.spec.path || row.spec.comp || row.spec.widget || row.spec.bundle) return
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
    // What differs from the factory, for the rail and the Changes page. Reading it walks every row (~12 ms over 1695),
    // so it is read only while Prism is on screen and once a burst of writes settles: as a binding it ran on every write
    // anywhere in the shell, Prism closed or not, and on every wheel notch (11-07).
    property bool watching: false
    property var changes: []
    function refreshChanges(): void { root.changes = root.rows.filter(row => root.changed(row)) }
    // Each visit reads the compositor's own settings again (windows, input, screens): they change outside the shell.
    onWatchingChanged: if (root.watching) { CompositorConfig.ensure(); root.refreshChanges() }
    onRowsChanged: if (root.watching) changesLater.restart()
    Connections {
        target: Config
        function onRevisionChanged() { if (root.watching) changesLater.restart() }
    }
    Timer { id: changesLater; interval: 150; onTriggered: root.refreshChanges() }
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
    // Each row Home can hold, by its pin: built when the rows change, never on a write.
    readonly property var pinIndex: {
        const out = {}
        for (const row of root.rows) {
            const pin = row.virtual ? "" : IrisOptions.pinValue(row.spec)
            if (pin.length > 0 && !(pin in out)) out[pin] = row
        }
        return out
    }
    function pinnedRows(): var {
        const _ = root.revision
        return IrisOptions.homeList().map(id => root.pinIndex[id]).filter(Boolean)
    }

    // Search reads an index made once per set of rows and language: every row's words lowered, in the person's language
    // and in English, and its page's name. Translating 1695 rows five times on every key cost 35-60 ms a key (11-07).
    // The cache is a plain object so a search binding never depends on the cache it fills.
    readonly property var lookup: ({})
    function searchIndex(): var {
        const key = Translation.languageCode
        const catalogue = Translation.translations
        const kept = root.lookup.index
        if (kept && kept.rows === root.rows && kept.pages === root.pages && kept.key === key && kept.catalogue === catalogue) return kept
        const both = text => (Translation.tr(text) + " " + text).toLowerCase()
        const pageNames = {}
        const pages = root.pages.map(page => {
            pageNames[page.pageId] = both(String(page.name ?? ""))
            return { page: page, name: pageNames[page.pageId] }
        })
        const groups = []
        const groupAt = {}
        const entries = root.rows.map((row, order) => {
            const where = row.page + "|" + row.section
            if (row.section.length > 0) {
                if (!(where in groupAt)) { groupAt[where] = groups.length; groups.push({ page: row.page, section: row.section, title: both(row.section), rows: [] }) }
                groups[groupAt[where]].rows.push(row)
            }
            return {
                row: row,
                order: order,
                name: both(String(row.label ?? "")),
                group: both(String(row.section ?? "")),
                known: Array.from(row.keywords ?? []).join(" ").toLowerCase(),
                detail: both(String(row.detail ?? "")),
                page: pageNames[row.page] ?? "",
                offers: Array.from(row.choices ?? []).map(choice => both(String(choice.label ?? ""))).join(" ")
            }
        })
        root.lookup.index = { rows: root.rows, pages: root.pages, key: key, catalogue: catalogue, entries: entries, pageNames: pages, groups: groups }
        return root.lookup.index
    }
    function wordsOf(query: string): var { return String(query ?? "").toLowerCase().trim().split(/\s+/).filter(word => word.length > 0) }

    // Rows by how close the words come to what the row is: its name first, then its group, the words it is known by,
    // what it says it does, its page, and last a choice it offers (a "Glass" choice of a widget's face came before the
    // Glass group's own rows, 11-07). Every word must land somewhere. Only the best hits ask whether they are shown.
    function search(query: string): var {
        const words = root.wordsOf(query)
        if (words.length === 0) return []
        const starts = (text, word) => text.startsWith(word) || text.includes(" " + word)
        const hits = []
        for (const entry of root.searchIndex().entries) {
            let score = 0
            for (const word of words) {
                if (entry.name.startsWith(word)) score += 10
                else if (starts(entry.name, word)) score += 8
                else if (entry.name.includes(word)) score += 5
                else if (starts(entry.group, word)) score += 4
                else if (entry.known.includes(word)) score += 3
                else if (starts(entry.detail, word)) score += 2
                else if (entry.page.includes(word) || entry.group.includes(word) || entry.detail.includes(word)) score += 1
                else if (entry.offers.includes(word)) score += 0.5
                else { score = -1; break }
            }
            if (score > 0) hits.push({ row: entry.row, score: score, order: entry.order })
        }
        hits.sort((a, b) => b.score - a.score || a.order - b.order)
        const out = []
        for (const hit of hits) {
            if (!root.shown(hit.row)) continue
            out.push(hit.row)
            if (out.length >= 40) break
        }
        return out
    }

    // Places a search reaches whole: a page or a group whose name holds every word, the page first. A hit opens it.
    function places(query: string): var {
        const words = root.wordsOf(query)
        if (words.length === 0) return []
        const holds = text => words.every(word => text.includes(word))
        const lookup = root.searchIndex()
        const out = []
        for (const entry of lookup.pageNames) {
            const page = entry.page
            if (holds(entry.name)) out.push({ page: page.pageId, group: "", name: page.name, glyph: page.glyph, tint: page.tint })
        }
        for (const group of lookup.groups) {
            if (out.length >= 8) break
            if (!holds(group.title) || !group.rows.some(row => root.shown(row))) continue
            const page = root.page(group.page)
            out.push({ page: group.page, group: group.section, name: group.section, glyph: String(IrisOptions.groupGlyphs[group.section] ?? page.glyph), tint: page.tint })
        }
        return out.slice(0, 8)
    }

    // The wallpaper as people call it: a name they gave it reads as one; a site's dump (ids, hashes, a row of tags)
    // says its folder instead, else just "Wallpaper".
    function wallpaperName(path: string): string {
        const file = String(path ?? "").split("/").pop() ?? ""
        const words = file.replace(/\.[^.]+$/, "").replace(/^(motionbgs|wallhaven|wallpaperflare|unsplash)[-_]/i, "")
            .split(/[-_\s]+/).filter(word => word.length > 0)
        const machine = words.length === 0 || words.length > 5 || words.some(word => /\d{4,}|^[0-9a-f]{12,}$/i.test(word))
            || (words.length === 1 && /\d/.test(words[0]) && /^[a-z0-9]{4,}$/i.test(words[0]))
        const title = list => list.map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(" ")
        if (!machine) return title(words)
        const parts = String(path ?? "").split("/")
        const folder = parts.length > 1 ? parts[parts.length - 2] : ""
        const generic = ["", "pictures", "wallpapers", "wallpaper", "walls", "downloads", "images", "backgrounds", "imágenes", "descargas"]
        return generic.includes(folder.toLowerCase()) || /\d{4,}/.test(folder) ? Translation.tr("Your wallpaper") : title(folder.split(/[-_\s]+/).filter(word => word.length > 0))
    }
    function wallpaperKind(path: string): string {
        const lower = String(path ?? "").toLowerCase()
        return Wallpapers.isVideoFile(lower) ? Translation.tr("Live") : lower.endsWith(".gif") ? Translation.tr("Animated") : Translation.tr("Picture")
    }
    // The wallpapers to go back to in one press: the last ones set, then the folder's own, never the one worn.
    function wallpaperChoices(most: int): var {
        const worn = String(Wallpapers.effectiveWallpaperPath ?? "")
        const folder = Array.from(Wallpapers.wallpapers ?? []).map(String)
            .filter(path => Wallpapers.extensions.includes(path.split(".").pop().toLowerCase()))
        const out = []
        for (const path of Array.from(Wallpapers.recentWallpapers ?? []).map(String).concat(folder)) {
            if (out.length >= most) break
            if (path.length > 0 && path !== worn && !out.includes(path)) out.push(path)
        }
        return out
    }
    function wearWallpaper(path: string): void {
        Wallpapers.applySelectionTarget(path, "main", Appearance.m3colors.darkmode, "")
    }
    // The gallery is a surface of its own: Settings steps aside for it.
    function openWallpaperGallery(): void {
        GlobalStates.wallpaperSelectorTargetMonitor = NiriService.currentOutput ?? ""
        GlobalStates.settingsOverlayOpen = false
        GlobalStates.wallpaperSelectorOpen = true
    }

    function runShow(page: var): void {
        if (!page?.show) return
        GlobalStates.settingsOverlayOpen = false
        Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), String(page.show.target), String(page.show.fn)])
    }
}
