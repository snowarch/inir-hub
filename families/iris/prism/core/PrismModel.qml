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
