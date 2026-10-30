pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.modules.iris.style

// The area a layout shows, one page at a time like Classic: the next page incubates in slices the runtime spreads
// across frames, the one on screen stays until it is Ready, then the two swap in one frame (his 10-30: a page turn
// that slid the whole page was unwanted) and the old one goes.
// Keeping every area seen (and prewarming the neighbours) held 3-6x Classic's objects, and each of them re-read the
// config on every write: the three layouts felt slow next to Classic (2026-10-24).
Item {
    id: pool

    // The area asked for, and the page file for an id (the layout's own page).
    property string current: ""
    property var urlFor: id => ""
    // What a page gets at creation, besides its `area`.
    property var propsFor: id => ({})
    // Pages kept built besides the one on screen.
    property int keep: 0
    // Pages are hidden while a search or a shared page fills the layout.
    property bool hidden: false
    // Settings stands (its open has finished): a page asked for now builds in the click's frame, as Classic's first
    // block does; built in slices it showed 0.2-0.7 s later in a nest. During the open it builds in slices, and one
    // still building when the open ends keeps building so.
    property bool settled: true
    // On screen: the last area whose page stood ready.
    property string shown: ""
    readonly property Item shownItem: pool.itemFor(pool.shown)
    property var resident: []
    property var used: ({})
    property int clock: 0
    signal arrived(string id)

    function slot(id: string): Loader {
        for (let i = 0; i < pages.count; i++) {
            const loader = pages.itemAt(i)
            if (loader && loader.area === id) return loader
        }
        return null
    }
    function itemFor(id: string): Item {
        const loader = pool.slot(id)
        return loader && loader.status === Loader.Ready ? loader.item : null
    }
    // A page is ready once it is whole (every group built), or after a beat at most: a turn to a page still filling in
    // showed it streaming its groups in on screen.
    function ready(id: string): bool {
        const item = pool.itemFor(id)
        return item !== null && (item.whole !== false || pool.forced === id)
    }
    property string forced: ""
    Timer { id: wholeLimit; interval: 450; onTriggered: { pool.forced = pool.current; pool.settle() } }
    function hold(id: string): void {
        if (id.length === 0 || String(pool.urlFor(id)).length === 0) return
        const next = Object.assign({}, pool.used)
        next[id] = ++pool.clock
        pool.used = next
        if (!pool.resident.includes(id)) pool.resident = pool.resident.concat([id])
    }
    function trim(): void {
        const extra = pool.resident.length - (pool.keep + 1)
        if (extra <= 0) return
        const spare = pool.resident.filter(id => id !== pool.shown && id !== pool.current)
            .sort((a, b) => (pool.used[a] ?? 0) - (pool.used[b] ?? 0)).slice(0, extra)
        if (spare.length > 0) pool.resident = pool.resident.filter(id => !spare.includes(id))
    }
    function settle(): void {
        if (pool.current.length === 0 || pool.current === pool.shown || !pool.ready(pool.current)) return
        pool.shown = pool.current
        pool.arrived(pool.shown)
        // Never in this frame: settle runs inside a delegate's creation, and trimming there rewrote the model the
        // Repeater was building (a binding loop on `values`).
        Qt.callLater(pool.trim)
    }
    onCurrentChanged: {
        pool.forced = ""
        wholeLimit.restart()
        pool.hold(pool.current)
        pool.settle()
    }

    Repeater {
        id: pages
        // Keyed by id: a page joining or leaving the pool never touches the others.
        model: ScriptModel { values: pool.resident }
        Loader {
            id: page
            required property string modelData
            readonly property string area: page.modelData
            readonly property bool onScreen: !pool.hidden && page.area === pool.shown
            anchors.fill: parent
            // Never switched while it loads: going sync before the component is Ready makes Qt reload it without the props
            // (no `area`), and Ready lands from the loader thread later than any progress or event-loop turn shows.
            visible: page.onScreen && page.status === Loader.Ready
            enabled: page.area === pool.shown
            Component.onCompleted: {
                page.asynchronous = !pool.settled
                page.setSource(pool.urlFor(page.area), Object.assign({ area: page.area }, pool.propsFor(page.area)))
            }
            onStatusChanged: if (page.status === Loader.Ready && page.area === pool.current) pool.settle()
            Connections {
                target: page.item
                ignoreUnknownSignals: true
                function onWholeChanged(): void { if (page.area === pool.current) pool.settle() }
            }
        }
    }
}
