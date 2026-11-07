pragma Singleton
import QtQuick
import Quickshell
import qs
import qs.modules.common

// Where the person is in Prism: the page on screen, the way back and forward, the search and the wide room. Lives as
// long as the shell; reset when Settings closes, so every visit starts on the page it was asked for.
Singleton {
    id: root

    property string page: "general"
    property var back: []
    property var forward: []
    property string query: ""
    // The green light: the panel takes the whole room instead of its resting size.
    property bool wide: false
    // A request Prism has no page for opens the classic Settings once; cleared when Settings closes.
    property bool classicVisit: false
    // When the page last scrolled: a wheel that lands on a level after it scrolls the page, not the level.
    property real scrolledAt: 0

    readonly property bool canBack: root.back.length > 0
    readonly property bool canForward: root.forward.length > 0
    readonly property bool searching: root.query.trim().length > 0

    function go(id: string): void {
        const next = String(id ?? "")
        if (next.length === 0 || next === root.page) { root.query = ""; return }
        root.back = root.back.concat([root.page]).slice(-30)
        root.forward = []
        root.page = next
        root.query = ""
    }
    function goBack(): void {
        if (!root.canBack) return
        root.forward = [root.page].concat(root.forward)
        root.page = root.back[root.back.length - 1]
        root.back = root.back.slice(0, -1)
    }
    function goForward(): void {
        if (!root.canForward) return
        root.back = root.back.concat([root.page])
        root.page = root.forward[0]
        root.forward = root.forward.slice(1)
    }
    function reset(): void {
        root.back = []
        root.forward = []
        root.query = ""
        root.classicVisit = false
    }

    // Pins: the rows the person keeps at hand, stored as the paths iRiS Settings already keeps for Home.
    readonly property var pins: {
        const _ = Config.revision
        return Array.from(Config.getNestedValue("iris.appearance.settingsHome", []) ?? []).map(entry => String(entry))
    }
    function pinned(path: string): bool { return root.pins.includes(String(path)) }
    function togglePin(path: string): void {
        const key = String(path)
        const next = root.pinned(key) ? root.pins.filter(entry => entry !== key) : root.pins.concat([key])
        Config.setNestedValue("iris.appearance.settingsHome", next)
    }
}
