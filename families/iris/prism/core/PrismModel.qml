pragma Singleton
import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.prism.pages

// Prism's one model: its pages, what each row holds now, how a value is written and said, what changed from the
// factory profile, and the search. Views never touch Config themselves.
Singleton {
    id: root

    readonly property list<PrismPage> catalogue: [
        PageGeneral {}, PageAppearance {}, PageMotion {}, PageWallpaper {},
        PageBar {}, PageDock {}, PageBubbles {}, PageWidgets {}, PageControlCenter {}, PageSpotlight {}, PageOrbit {}, PagePlayer {},
        PageNotifications {}, PageSound {}, PageDisplay {}, PageLock {}, PageBattery {}, PageGaming {}
    ]
    readonly property var groups: ["Shell", "Desktop", "System"]
    readonly property var pages: Array.from(root.catalogue).filter(page => page.needs !== "battery" || Battery.available)
    readonly property var ids: root.pages.map(page => page.pageId)

    // Every row once, with the page and section it lives in.
    readonly property var rows: {
        const out = []
        root.pages.forEach(page => page.sections.forEach(section => section.rows.forEach(row =>
            out.push(Object.assign({}, row, { page: page.pageId, section: section.title })))))
        return out
    }
    readonly property int revision: Config.revision

    function page(id: string): var { return root.pages.find(entry => entry.pageId === id) ?? root.pages[0] }
    function find(path: string): var { return root.rows.find(row => row.path === path) ?? null }
    function index(id: string): int { return Math.max(0, root.ids.indexOf(id)) }
    function inGroup(group: string): var { return root.pages.filter(page => page.group === group) }
    function rowsOf(id: string): var { return root.rows.filter(row => row.page === id && root.shown(row)) }

    // Rows that stand for more than one key, or for a transition: never restored or listed as a change.
    function virtual(row: var): bool { return row.path === "panelFamily" || row.path === "settingsDesign" }
    // Which Settings opens: Prism, a classic layout, or the v2.33 design, as one choice over its three keys.
    function settingsDesign(): string {
        const _ = root.revision
        if (String(Config.getNestedValue("iris.appearance.settingsPanel", "prism")) === "prism") return "prism"
        if (Boolean(Config.getNestedValue("iris.appearance.settingsOriginal", false))) return "original"
        return String(Config.getNestedValue("iris.appearance.settingsLayout", "classic"))
    }

    function raw(row: var): var {
        if (row.path === "settingsDesign") return root.settingsDesign()
        const _ = root.revision
        const value = Config.getNestedValue(row.path, row.def)
        return value === undefined || value === null ? row.def : value
    }
    // What the control shows: an inverted switch reads the other way round.
    function read(row: var): var { return row.invert ? !Boolean(root.raw(row)) : root.raw(row) }

    function shown(row: var): bool {
        const when = String(row.when ?? "")
        if (when.length === 0) return true
        const _ = root.revision
        if (when.includes("!=")) {
            const [path, value] = when.split("!=")
            return String(Config.getNestedValue(path, "")) !== value
        }
        if (when.startsWith("!")) return !Boolean(Config.getNestedValue(when.slice(1), false))
        return Boolean(Config.getNestedValue(when, false))
    }

    function stored(row: var, value: var): var { return row.invert ? !Boolean(value) : value }
    function write(row: var, value: var): void {
        const next = root.stored(row, value)
        // A family switch goes through the shell's own transition, never a bare write.
        if (row.path === "panelFamily") Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "panelFamily", "set", String(next)])
        else if (row.path === "settingsDesign") root.wearSettings(String(next))
        else Config.setNestedValue(row.path, next)
    }
    // Each Settings design drawn small, its panes read off the design itself: sidebar, page, rail, sheet
    // (PrismSketch draws them: Home's cards and the designs island).
    readonly property var drawings: ({
        prism: [
            { x: 0, y: 0, w: 0.22, h: 1, a: 0.16, r: 0.04 },
            { x: 0.26, y: 0.06, w: 0.46, h: 0.3, tone: "spectrum", r: 0.04 },
            { x: 0.26, y: 0.44, w: 0.46, h: 0.08, a: 0.22, r: 0.02 },
            { x: 0.26, y: 0.58, w: 0.46, h: 0.08, a: 0.22, r: 0.02 },
            { x: 0.26, y: 0.72, w: 0.46, h: 0.08, a: 0.22, r: 0.02 },
            { x: 0.76, y: 0, w: 0.24, h: 1, a: 0.1, r: 0.04 },
            { x: 0.8, y: 0.08, w: 0.08, h: 0.12, tone: "accent", r: 0.04 }
        ],
        classic: [
            { x: 0, y: 0, w: 0.28, h: 1, a: 0.14, r: 0.04 },
            { x: 0.05, y: 0.1, w: 0.18, h: 0.06, a: 0.3, r: 0.02 },
            { x: 0.05, y: 0.22, w: 0.14, h: 0.06, tone: "accent", r: 0.02 },
            { x: 0.05, y: 0.34, w: 0.16, h: 0.06, a: 0.3, r: 0.02 },
            { x: 0.34, y: 0.08, w: 0.3, h: 0.1, a: 0.4, r: 0.02 },
            { x: 0.34, y: 0.28, w: 0.62, h: 0.14, a: 0.12, r: 0.03 },
            { x: 0.34, y: 0.48, w: 0.62, h: 0.14, a: 0.12, r: 0.03 },
            { x: 0.34, y: 0.68, w: 0.62, h: 0.14, a: 0.12, r: 0.03 }
        ],
        folio: [
            { x: 0.22, y: 0.08, w: 0.56, h: 0.12, a: 0.4, r: 0.02 },
            { x: 0.22, y: 0.3, w: 0.56, h: 0.05, a: 0.22, r: 0.02 },
            { x: 0.22, y: 0.4, w: 0.5, h: 0.05, a: 0.22, r: 0.02 },
            { x: 0.22, y: 0.5, w: 0.56, h: 0.05, a: 0.22, r: 0.02 },
            { x: 0.22, y: 0.66, w: 0.56, h: 0.05, a: 0.22, r: 0.02 },
            { x: 0.22, y: 0.76, w: 0.38, h: 0.05, tone: "accent", r: 0.02 }
        ],
        pocket: [
            { x: 0.62, y: 0, w: 0.38, h: 1, a: 0.16, r: 0.05 },
            { x: 0.67, y: 0.1, w: 0.28, h: 0.08, a: 0.4, r: 0.02 },
            { x: 0.67, y: 0.28, w: 0.28, h: 0.1, a: 0.16, r: 0.03 },
            { x: 0.67, y: 0.44, w: 0.28, h: 0.1, tone: "accent", r: 0.03 },
            { x: 0.67, y: 0.6, w: 0.28, h: 0.1, a: 0.16, r: 0.03 },
            { x: 0.06, y: 0.1, w: 0.4, h: 0.05, a: 0.08, r: 0.02 }
        ],
        drawer: [
            { x: 0.04, y: 0.34, w: 0.92, h: 0.66, a: 0.16, r: 0.06 },
            { x: 0.44, y: 0.4, w: 0.12, h: 0.03, a: 0.4, r: 0.02 },
            { x: 0.1, y: 0.52, w: 0.24, h: 0.08, tone: "accent", r: 0.02 },
            { x: 0.38, y: 0.52, w: 0.2, h: 0.08, a: 0.3, r: 0.02 },
            { x: 0.62, y: 0.52, w: 0.2, h: 0.08, a: 0.3, r: 0.02 },
            { x: 0.1, y: 0.7, w: 0.8, h: 0.1, a: 0.12, r: 0.03 }
        ],
        original: [
            { x: 0, y: 0, w: 0.2, h: 1, a: 0.14, r: 0.04 },
            { x: 0.05, y: 0.1, w: 0.1, h: 0.14, tone: "accent", r: 0.03 },
            { x: 0.05, y: 0.32, w: 0.1, h: 0.14, a: 0.35, r: 0.03 },
            { x: 0.05, y: 0.54, w: 0.1, h: 0.14, a: 0.35, r: 0.03 },
            { x: 0.26, y: 0.08, w: 0.7, h: 0.84, a: 0.1, r: 0.04 },
            { x: 0.3, y: 0.18, w: 0.5, h: 0.05, a: 0.3, r: 0.02 },
            { x: 0.3, y: 0.34, w: 0.6, h: 0.05, a: 0.22, r: 0.02 },
            { x: 0.3, y: 0.5, w: 0.6, h: 0.05, a: 0.22, r: 0.02 },
            { x: 0.3, y: 0.66, w: 0.6, h: 0.05, a: 0.22, r: 0.02 }
        ]
    })

    readonly property var designs: [
        { value: "prism", label: "Prism" }, { value: "classic", label: "Classic" }, { value: "folio", label: "Folio" },
        { value: "pocket", label: "Pocket" }, { value: "drawer", label: "Drawer" }, { value: "original", label: "v2.33" }
    ]
    function drawing(design: string): var { return root.drawings[design] ?? [] }
    // Another design takes Prism's place at once, open at the page Prism stood on; the designs island at the top of
    // every Settings window leads back here.
    function wearSettings(design: string): void {
        if (design === "prism") {
            Config.setNestedValues({ "iris.appearance.settingsPanel": "prism", "iris.appearance.settingsOriginal": false })
            PrismState.classicVisit = false
            return
        }
        const updates = { "iris.appearance.settingsPanel": "classic", "iris.appearance.settingsOriginal": design === "original" }
        updates["iris.appearance.settingsLayout"] = design === "original" ? "classic" : design
        Config.setNestedValues(updates)
        // The classic Settings opens where Prism stood (Changes, Prism's own, opens on Home).
        const at = root.ids.includes(PrismState.page) && PrismState.page !== "changes" ? PrismState.page : "general"
        Qt.callLater(() => GlobalStates.openSettingsAt("iris", at))
    }
    // A drag shows its value on the desktop without writing it; release writes once.
    function preview(row: var, value: var): void { Config.previewNestedValue(row.path, root.stored(row, value)) }

    function same(a: var, b: var): bool {
        if (typeof a === "number" || typeof b === "number") return Math.abs(Number(a) - Number(b)) < 1e-6
        return JSON.stringify(a) === JSON.stringify(b)
    }
    function changed(row: var): bool { return !root.same(root.raw(row), row.def) }
    function changedOf(id: string): var { return root.rows.filter(row => row.page === id && !root.virtual(row) && root.changed(row)) }
    readonly property var changes: root.rows.filter(row => !root.virtual(row) && root.changed(row))

    // Restore defaults: every changed row of a page at once, kept so one Undo puts them all back.
    property var undo: null
    function restore(id: string): void {
        const steps = root.changedOf(id).map(row => ({ path: row.path, before: root.raw(row), after: row.def }))
        if (steps.length === 0) return
        const updates = {}
        steps.forEach(step => updates[step.path] = step.after)
        Config.setNestedValues(updates)
        root.undo = { page: id, steps: steps }
    }
    function undoRestore(): void {
        if (!root.undo) return
        const updates = {}
        root.undo.steps.forEach(step => updates[step.path] = step.before)
        Config.setNestedValues(updates)
        root.undo = null
    }

    // A value in words, as the row's "Now" column and the Changes list say it.
    function figure(row: var, value: var): string {
        const scaled = Number(value) * Number(row.scale ?? 1)
        const decimals = Number(row.step ?? 1) * Number(row.scale ?? 1) < 1 ? 1 : 0
        const unit = String(row.unit ?? "")
        const text = scaled.toFixed(decimals)
        return unit.trim() === "%" ? text + "%" : text + unit
    }
    function say(row: var, value: var): string {
        if (row.kind === "switch") return Boolean(value) ? Translation.tr("On") : Translation.tr("Off")
        if (row.kind === "range") return root.figure(row, value)
        if (row.kind === "text") return String(value ?? "")
        const choice = (row.choices ?? []).find(entry => root.same(entry.value, value))
        if (choice) return Translation.tr(choice.label)
        return String(value ?? "")
    }
    function sayNow(row: var): string { return root.say(row, root.read(row)) }

    // Search: a row's name, what it does and its page's name, in the person's language and in English.
    function search(query: string): var {
        const words = String(query ?? "").toLowerCase().trim().split(/\s+/).filter(word => word.length > 0)
        if (words.length === 0) return []
        return root.rows.filter(row => root.shown(row)).map(row => {
            const name = (Translation.tr(row.label) + " " + row.label).toLowerCase()
            const rest = (Translation.tr(row.detail ?? "") + " " + (row.detail ?? "") + " " + Translation.tr(root.page(row.page).name)
                + " " + Translation.tr(row.section) + " " + (row.choices ?? []).map(choice => Translation.tr(choice.label)).join(" ")).toLowerCase()
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

    // The hero's action: Settings steps aside first, so the thing it opens is seen.
    function runShow(page: var): void {
        if (!page?.show) return
        GlobalStates.settingsOverlayOpen = false
        Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), String(page.show.target), String(page.show.fn)])
    }
}
