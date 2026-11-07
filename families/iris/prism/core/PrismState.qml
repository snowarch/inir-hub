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
    // The query the page answers. It trails the typing by a beat, so each key echoes at once and the results are built
    // where the typing rests (a page of rows built on every key cost 40-90 ms a key); a cleared field answers at once.
    property string asked: ""
    onQueryChanged: {
        if (root.query.trim().length === 0) { askLater.stop(); root.asked = "" }
        else askLater.restart()
    }
    Timer { id: askLater; interval: 90; onTriggered: root.asked = root.query }
    // The green light: the panel takes the whole room instead of its resting size.
    property bool wide: false
    // The group a long page shows, by page: a long page is read one group at a time.
    property var groupOf: ({})
    // When the page last scrolled: a wheel that lands on a level after it scrolls the page, not the level.
    property real scrolledAt: 0

    readonly property bool canBack: root.back.length > 0
    readonly property bool canForward: root.forward.length > 0
    readonly property bool searching: root.asked.trim().length > 0

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
        root.groupOf = ({})
    }
    // A group asked for (the sidebar's index, a search place, a request "section/group"): the page brings it to the top.
    property int groupAsk: 0
    function pickGroup(page: string, group: string): void {
        const next = Object.assign({}, root.groupOf)
        next[page] = group
        root.groupOf = next
        root.groupAsk++
    }
}
