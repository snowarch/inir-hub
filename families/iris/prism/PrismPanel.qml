import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.components
import qs.modules.iris.settings
import qs.modules.iris.style
import qs.modules.iris.state
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls
import qs.modules.iris.prism.parts

// Prism's body: the sidebar, the page beside it (its card, its folders) and the side column. Lays itself out from the room
// it is given; the window around it only places it.
Item {
    id: root
    property bool active: true
    property string flashPath: ""
    // Hosted as a window: square corners (the compositor rounds a window), the lights act on the window, the switch
    // between hosts reads "Over the desktop".
    property bool windowed: false
    signal closeRequested()
    // The yellow light in a window: the window goes to the dock as any app's would.
    signal minimizeRequested()
    // The green light in a window: its column takes the screen.
    signal growRequested()

    // The other host opens on the page this one stands on.
    function switchHost(): void {
        GlobalStates.settingsOverlayRequestedKey = PrismState.page
        Config.setNestedValue("iris.appearance.settingsHost", root.windowed ? "overlay" : "window")
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (PrismState.query.length > 0) PrismState.query = ""
            else root.closeRequested()
            event.accepted = true
        } else if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            root.focusSearch()
            event.accepted = true
        } else if (event.key === Qt.Key_Left && (event.modifiers & Qt.AltModifier)) {
            PrismState.goBack()
            event.accepted = true
        } else if (event.key === Qt.Key_Right && (event.modifiers & Qt.AltModifier)) {
            PrismState.goForward()
            event.accepted = true
        }
    }
    // Every change made here is iRiS Settings' own: the same history, the island under the page tells it and takes it back.
    Shortcut { sequences: ["Ctrl+Z"]; enabled: root.active && IrisOptions.canUndo; onActivated: IrisOptions.undo() }
    Shortcut { sequences: ["Ctrl+Shift+Z", "Ctrl+Y"]; enabled: root.active && IrisOptions.canRedo; onActivated: IrisOptions.redo() }

    readonly property var page: PrismModel.page(PrismState.page)
    readonly property bool changesView: PrismState.page === "changes"
    // A page iRiS draws as a view of its own (Community Hub, Keyboard shortcuts, About) fills the middle below its title.
    readonly property bool home: !PrismState.searching && !root.changesView && root.page.pageId === "general"
    // Home is the person's own (his 11-18): its blocks in their order, its head's look, its greeting.
    readonly property var homeLook: Config.options?.iris?.appearance ?? ({})
    readonly property var homeBlocks: Array.from(root.homeLook.settingsHomeBlocks ?? ["everyday", "deck", "groups", "index"]).map(String)
    readonly property string homeGreeting: String(root.homeLook.settingsHomeGreeting ?? "name")
    property bool homeArranging: false
    readonly property string greeting: {
        if (root.homeGreeting === "hour") return Qt.formatTime(DateTime.clock.date, "hh:mm")
        const hour = DateTime.clock.date.getHours()
        const said = hour >= 5 && hour < 12 ? Translation.tr("Good morning") : hour >= 12 && hour < 19 ? Translation.tr("Good afternoon")
            : hour >= 19 ? Translation.tr("Good evening") : Translation.tr("Good night")
        const name = String(SystemInfo.displayName || SystemInfo.username || "")
        return name.length > 0 && root.homeGreeting === "name" ? said + ", " + name : said
    }
    // A page drawn to its own measure: its head is a drawing of what it sets, and every group stands on the shelf.
    readonly property Component heroNow: PrismState.searching || root.changesView || root.home ? null
        : (({ colour: colourHero, typeIcons: typeHero, lock: lockHero })[String(root.page.pageId)] ?? null)
    readonly property bool shelved: root.home || root.heroNow !== null
    // The page's own keys on its head.
    readonly property var pageActions: root.home
        ? [{ id: "editHome", glyph: root.homeArranging ? "check" : "edit", text: root.homeArranging ? "Done" : "Make it yours", solid: true }]
        : root.page.pageId === "controlCenter" ? [{ id: "arrange", glyph: "dashboard_customize", text: "Arrange it", solid: true }] : []
    function act(id: string): void {
        if (id === "editHome") { root.homeArranging = !root.homeArranging; return }
        if (id === "lockEdit") { root.closeRequested(); IrisState.lockEdit = true; return }
        if (id === "lockNow") { root.closeRequested(); Session.lock(); return }
        if (id === "arrange") {
            root.closeRequested()
            IrisState.morphOwner = ""
            GlobalStates.controlPanelOpen = true
            IrisState.controlEdit = true
        }
    }
    onHomeChanged: if (!root.home) root.homeArranging = false
    readonly property bool hosted: !PrismState.searching && !root.changesView && String(root.page.view ?? "").length > 0
    readonly property var sections: PrismState.searching || root.changesView || root.hosted ? [] : PrismModel.sectionsOf(root.page.pageId)
    // A long page is read in parts of a screenful or two (whole groups, about 24 rows each); a short one stacks every
    // group. Either way the sidebar's index under the page names each group and follows the reading, and a part ends
    // on the next one (his 11-07: never looked for sideways, never one two-row group alone on a screen).
    // Where it splits is read from every row the page may show, so a switch that shows or hides its neighbours
    // never moves a group into another part under the reader (his 11-10: a toggle threw the page elsewhere).
    readonly property var layout: root.sections.length === 0 ? [] : PrismModel.layoutOf(root.page.pageId)
    // Every group on one scroll, each a folder (his 11-17 pick, B · Carpeta): a page is never read in parts.
    readonly property bool paged: false
    readonly property var parts: {
        if (!root.paged) return [root.sections]
        const out = []
        let part = [], rows = 0, band = ""
        for (const section of root.layout) {
            const n = section.rows.length
            // An area in bands turns its parts where its bands turn: a part is one band, or a long band's half.
            const own = root.bandOf(section.title)
            if (part.length > 0 && (rows + n > 28 || (root.bands.length > 0 && own !== band))) { out.push(part); part = []; rows = 0 }
            band = own
            part.push(section)
            rows += n
            if (rows >= 20 && root.bands.length === 0) { out.push(part); part = []; rows = 0 }
        }
        if (part.length > 0) out.push(part)
        // Each part shows its groups as they read now; a group with nothing to show drops out, its neighbours stay.
        return out.map(titles => root.sections.filter(section => titles.some(entry => entry.title === section.title)))
            .filter(shown => shown.length > 0)
    }
    readonly property string group: {
        const chosen = String(PrismState.groupOf[root.page.pageId] ?? "")
        return root.sections.some(section => section.title === chosen) ? chosen : String(root.sections[0]?.title ?? "")
    }
    readonly property int partIndex: Math.max(0, root.parts.findIndex(part => part.some(section => section.title === root.group)))
    readonly property var shownSections: root.parts[root.partIndex] ?? []
    // The index in the sidebar: every group, with a dot where something differs from the factory. An area that names
    // bands (Bubbles' ~38 groups) is indexed by band, as Classic and Folio show it; a band opens at its first group.
    readonly property var bands: PrismModel.chapters[root.page.pageId] ? [] : (IrisOptions.groupBands[root.page.pageId] ?? [])
    function bandOf(title: string): string {
        if (root.bands.length === 0) return title
        const band = root.bands.find(band => band.groups.includes(title)) ?? root.bands.find(band => band.groups.length === 0)
        return band ? String(band.title) : title
    }
    readonly property var groups: {
        const out = []
        for (const section of root.sections) {
            const title = root.bandOf(section.title)
            const changed = section.rows.some(row => PrismModel.changed(row))
            const entry = out.find(entry => entry.title === title)
            if (entry) { entry.changed = entry.changed || changed; entry.rows = entry.rows.concat(section.rows) }
            else out.push({ title: title, changed: changed, first: section.title, rows: Array.from(section.rows) })
        }
        return out
    }
    function firstOf(entry: string): string {
        return String(root.sections.find(section => root.bandOf(section.title) === entry)?.title ?? entry)
    }
    // Where the reader stands: the group whose head has passed a third of the way down the page.
    property string spyGroup: ""
    // The group a press asked for is where the reader stands until the page is scrolled by hand: a short group near
    // the foot never reaches the reading line, and the index named its neighbour instead (his 11-09).
    property string heldGroup: ""
    // True while the page places itself: only a hand's scroll lets go of the group asked for.
    property bool placing: false
    // Until when a change of layout aims again at what was asked for (rows are still being built under it).
    property real aimUntil: 0
    readonly property string currentGroup: root.shownSections.some(section => section.title === root.heldGroup) ? root.heldGroup
        : root.shownSections.some(section => section.title === root.spyGroup) ? root.spyGroup : String(root.shownSections[0]?.title ?? "")
    // Where each group's folder stands on the scroll: the page card holds the first, the shelf the rest.
    function tops(): var {
        if (root.shownSections.length === 0 || !leaf.visible) return []
        const out = root.home ? [] : [{ title: String(root.shownSections[0].title), top: leaf.y + content.y }]
        for (const section of root.shownSections.slice(root.home ? 0 : 1)) {
            const box = shelf.boxOf(String(section.title))
            if (box) out.push({ title: String(section.title), top: shelf.y + box.y + content.y })
        }
        return out.sort((a, b) => a.top - b.top)
    }
    function spy(): void {
        if (glider.running) return
        const list = root.tops()
        if (list.length === 0) return
        const line = centre.contentY + centre.height * 0.3
        let at = list[0].title
        for (const entry of list) if (entry.top <= line) at = entry.title
        root.spyGroup = at
    }
    function boxOf(title: string): var {
        const entry = root.tops().find(entry => entry.title === title)
        return entry ? { y: entry.top - content.y, index: entry.top === leaf.y + content.y ? 0 : 1 } : null
    }
    // A group asked for: on screen it glides to its head; in another part of a long page that part opens first.
    function showGroup(title: string): void {
        root.heldGroup = title
        root.aimUntil = Date.now() + 700
        const box = root.boxOf(title)
        if (box) root.glide(root.headOf(box))
        else if (root.paged) PrismState.pickGroup(root.page.pageId, title)
    }
    // Where a group's head comes to rest: clear of the blurred edge at the top, its eyebrow whole. The page's first
    // group keeps the page's own top over it when both fit.
    function headOf(box: Item): real {
        const y = box.y + content.y - centreEdge.reach - PrismTheme.dp(6)
        return box.index === 0 && root.partIndex === 0 && y < centre.height * 0.55 ? 0 : y
    }
    function glide(y: real): void {
        const to = Math.max(0, Math.min(centre.contentHeight - centre.height, y))
        if (glider.running && Math.abs(glider.to - to) < 2) return
        if (!glider.running && Math.abs(centre.contentY - to) < 2) return
        glider.stop()
        glider.to = to
        glider.start()
    }
    NumberAnimation { id: glider; target: centre; property: "contentY"; duration: PrismTheme.ms(360); easing.type: Easing.OutCubic; onStopped: root.spy() }
    // The page under a group asked for is still growing (rows are built over a few frames): aim again once it rests.
    Timer {
        id: aimLater
        interval: 50
        onTriggered: {
            if (Date.now() > root.aimUntil) return
            if (root.flashPath.length > 0) { root.placeRow(); return }
            const box = root.heldGroup.length > 0 ? root.boxOf(root.heldGroup) : null
            if (box) root.glide(root.headOf(box))
        }
    }
    readonly property real sideWidth: PrismTheme.dp(232)
    // The side column (profile, Changes, Now Playing). Left to itself it stands on Home, which is about the person,
    // and wherever the page keeps a wide measure beside it; every other page gets its room. The control at the page's
    // top is the person's say, remembered: a press that only repeats what the column does by itself gives it back.
    readonly property string railMode: String(Config.options?.iris?.appearance?.settingsRail ?? "auto")
    readonly property bool railFits: root.width >= PrismTheme.dp(1080)
    readonly property bool railAuto: PrismState.page === "general" || root.width - root.sideWidth - PrismTheme.dp(300) >= PrismTheme.dp(900)
    readonly property bool railOpen: root.railFits && (root.railMode === "open" || root.railMode !== "closed" && root.railAuto)
    // By hand the column slides; a page that opens already has it where it belongs.
    property bool railByHand: false
    property real railShown: root.railOpen ? 1 : 0
    Behavior on railShown { enabled: root.railByHand; NumberAnimation { duration: PrismTheme.ms(240); easing.type: Easing.OutCubic } }
    // The page takes the column's room once the column has left, and gives it before the column comes: one layout either way.
    readonly property real railWidth: root.railOpen || root.railShown > 0 ? PrismTheme.dp(300) : 0
    Timer { id: railRest; interval: 400; onTriggered: root.railByHand = false }
    function toggleRail(): void {
        const next = !root.railOpen
        root.railByHand = true
        railRest.restart()
        Config.setNestedValue("iris.appearance.settingsRail", next === root.railAuto ? "auto" : next ? "open" : "closed")
    }

    function focusSearch(): void { sidebar.search.input.forceActiveFocus() }
    // A place a search found: its page, and its group when it names one.
    function openPlace(place: var): void {
        PrismState.query = ""
        PrismState.go(place.page)
        if (String(place.group ?? "").length > 0) PrismState.pickGroup(place.page, place.group)
    }
    // Enter in the search: the first place, else the first row.
    function takeFirstHit(): void {
        if (PrismState.query.trim().length === 0) return
        const places = PrismModel.places(PrismState.query)
        if (places.length > 0) { root.openPlace(places[0]); return }
        const hits = PrismModel.search(PrismState.query)
        if (hits.length > 0) root.reach(hits[0])
    }
    // Reach a row: its page and group, its section unfolded, the row scrolled into view and lit once.
    function reach(row: var): void {
        if (!row) return
        PrismState.query = ""
        PrismState.go(row.page)
        PrismState.pickGroup(row.page, row.section)
        root.heldGroup = String(row.section ?? "")
        root.aimUntil = Date.now() + 700
        root.flashPath = row.path
        reachLater.restart()
    }
    function placeRow(): void {
        const item = root.findRow(content, root.flashPath)
        if (!item) return
        const y = item.mapToItem(content, 0, 0).y
        root.placing = true
        centre.contentY = Math.max(0, Math.min(centre.contentHeight - centre.height, y - centre.height * 0.35))
        root.placing = false
    }
    // The page lays out first; then the row is found where it landed.
    Timer {
        id: reachLater
        interval: 60
        onTriggered: {
            root.placeRow()
            flashOff.restart()
        }
    }
    function findRow(item: Item, path: string): var {
        for (const child of item.children) {
            if (child.row !== undefined && child.row?.path === path && child.number !== undefined) return child
            const found = root.findRow(child, path)
            if (found) return found
        }
        return null
    }
    Timer { id: flashOff; interval: 1400; onTriggered: root.flashPath = "" }

    Connections {
        target: PrismState
        function onPageChanged() { glider.stop(); root.heldGroup = ""; root.toTop(); root.spyGroup = ""; IrisOptions.settle() }
        // A search reads from its top: the best hits and the places they name come first.
        function onQueryChanged() { glider.stop(); root.heldGroup = ""; root.toTop() }
        // A long page brings the head of its new group into sight; a stacked one glides to it once laid out.
        function onGroupAskChanged() { groupLater.restart() }
    }
    function toTop(): void {
        root.placing = true
        centre.contentY = 0
        root.placing = false
    }
    Timer {
        id: groupLater
        interval: 40
        onTriggered: {
            if (root.flashPath.length > 0) return
            root.showGroup(root.group)
        }
    }

    // The body's round corners are drawn by what stands in them (the sidebar's fill, its glow, the edge veils' feet);
    // nothing else reaches them. A mask over the whole body rendered every frame of Prism twice, offscreen and again (11-07).
    readonly property bool watching: root.active && root.visible
    onWatchingChanged: PrismModel.watching = root.watching
    Component.onCompleted: PrismModel.watching = root.watching
    Component.onDestruction: PrismModel.watching = false

    Rectangle {
        id: body
        anchors.fill: parent
        radius: root.windowed ? 0 : PrismTheme.dp(28)
        color: PrismTheme.canvas
        clip: true

        // The window's ground: a fine grid of dots under the sidebar and between the cards (B · Carpeta). Drawn once
        // per size, never per frame.
        Canvas {
            anchors.fill: parent
            renderStrategy: Canvas.Immediate
            readonly property real step: PrismTheme.dp(18)
            readonly property color dot: PrismTheme.light ? Qt.rgba(0, 0, 0, 0.07) : Qt.rgba(1, 1, 1, 0.06) // iris-literal: the ground's dots
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onDotChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                ctx.fillStyle = dot
                for (let y = step / 2; y < height; y += step)
                    for (let x = step / 2; x < width; x += step) ctx.fillRect(x, y, 1.3, 1.3)
            }
        }

        PrismSidebar {
            id: sidebar
            width: root.sideWidth
            height: parent.height
            corner: body.radius
            windowed: root.windowed
            onCloseRequested: root.closeRequested()
            onMinimizeRequested: root.minimizeRequested()
            onGrowRequested: root.growRequested()
            onSwitchHost: root.switchHost()
            onReach: row => root.reach(row)
            onSearchEntered: root.takeFirstHit()
        }

        Flickable {
            id: centre
            visible: !root.hosted
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.rightMargin: root.railWidth
            height: parent.height
            contentHeight: content.y + content.implicitHeight + PrismTheme.dp(40)
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            onContentYChanged: {
                // A hand on the page: the reading line names the group again.
                if (!glider.running && !root.placing) { root.heldGroup = ""; root.aimUntil = 0 }
                root.spy()
            }
            onContentHeightChanged: {
                if (Date.now() < root.aimUntil) aimLater.restart()
                root.spy()
            }

            Column {
                id: content
                // The page's cards run from the sidebar's edge to a step short of the window's (B · Carpeta: 4 and 16).
                x: PrismState.searching || root.changesView ? PrismTheme.dp(32) : PrismTheme.dp(4)
                y: PrismState.searching || root.changesView ? 0 : PrismTheme.dp(16)
                width: centre.width - x - (PrismState.searching || root.changesView ? PrismTheme.dp(32) : PrismTheme.dp(16))
                spacing: 0

                // Search and Changes keep their plain head; a page wears its card.
                PageTop { visible: PrismState.searching || root.changesView; width: content.width }

                // The page card: the art, the page's name, its first group on the sheet's tab (B · Carpeta).
                PrismLeaf {
                    id: leaf
                    visible: !PrismState.searching && !root.changesView
                    width: content.width
                    page: root.page
                    // Home's card is the person's own: a greeting, the everyday tiles and the desktop drawn; its groups
                    // all stand on the shelf.
                    lead: root.shelved ? null : root.shownSections[0] ?? null
                    // Home's tab greets, a page drawn to its measure names what its drawing shows; the poster names the
                    // page, or on Home the day.
                    tabTitle: root.home ? root.greeting : Translation.tr(({ colour: "Your colours", typeIcons: "Your type", lock: "Your lock screen" })[String(root.page.pageId)] ?? "")
                    tabLine: root.home ? (Weather.enabled && Weather.hasData ? String(Weather.data?.temp ?? "") + "  ·  " + Translation.tr("Settings, made yours") : Translation.tr("Settings, made yours"))
                        : Translation.tr(({ colour: "The three colours iRiS wears, and where they come from", typeIcons: "The faces iRiS reads in, their size and weight" })[String(root.page.pageId)] ?? "")
                    posterTitle: root.home ? Translation.locale.toString(DateTime.clock.date, "dddd d") : ""
                    posterLine: root.home ? Translation.locale.toString(DateTime.clock.date, "MMMM") : ""
                    side: root.home && root.homeBlocks[0] === "everyday" ? homeSide : null
                    hero: root.heroNow
                    actions: root.pageActions
                    artKind: root.home ? String(root.homeLook.settingsHomeArt ?? "flow") : "flow"
                    onAction: id => root.act(id)
                    flashPath: root.flashPath
                    restorable: PrismModel.restorableOf(root.page.pageId)
                    extra: root.page.pageId === "general" ? homeExtra : root.page.pageId === "wallpaper" ? wallpaperExtra : null
                    onRestore: PrismModel.restore(root.page.pageId)
                    railFits: root.railFits
                    railOpen: root.railOpen
                    onToggleRail: root.toggleRail()
                }
                Item { visible: shelf.visible; width: 1; height: PrismTheme.dp(14) }
                // Every other group, a folder each.
                PrismShelf {
                    id: shelf
                    // Home's groups stand among its blocks, where the person put them.
                    visible: leaf.visible && !root.home && shelf.groups.length > 0
                    width: content.width
                    groups: root.shelved ? root.shownSections : root.shownSections.slice(1)
                    tint: root.page.tint
                    flashPath: root.flashPath
                }

                // A search, or every change: the places it names (a page, a group) first, then one chart of rows that
                // say where they live; a press on a place or a row's name goes there.
                Loader {
                    active: PrismState.searching || root.changesView
                    visible: active
                    width: content.width
                    sourceComponent: Column {
                        width: content.width
                        id: found
                        readonly property var hits: PrismState.searching ? PrismModel.search(PrismState.asked) : PrismModel.changes
                        readonly property var places: PrismState.searching ? PrismModel.places(PrismState.asked) : []
                        // The rows that fill the screen come in the first frame, the rest a few a frame after it: forty
                        // rows with their controls in one frame cost ~70 ms.
                        // A new query starts over; a write in Changes keeps every row it had.
                        property int built: 12
                        readonly property string answering: PrismState.asked
                        onAnsweringChanged: { found.built = 12; grow.restart() }
                        onHitsChanged: if (found.built < found.hits.length) grow.restart()
                        Component.onCompleted: if (found.built < found.hits.length) grow.restart()
                        Timer {
                            id: grow
                            interval: 16
                            repeat: true
                            onTriggered: { found.built += 8; if (found.built >= found.hits.length) grow.stop() }
                        }
                        PrismPlaces {
                            visible: parent.places.length > 0
                            width: parent.width
                            places: parent.places
                            onOpen: place => root.openPlace(place)
                        }
                        Item { visible: parent.places.length > 0; width: 1; height: PrismTheme.dp(30) }
                        PrismText {
                            visible: parent.hits.length === 0 && parent.places.length === 0
                            topPadding: PrismTheme.dp(12)
                            text: PrismState.searching ? Translation.tr("No setting matches that.") : Translation.tr("Everything is as it came.")
                            color: PrismTheme.ink2
                            font.pixelSize: PrismTheme.row
                        }
                        PrismSection {
                            visible: parent.hits.length > 0
                            width: parent.width
                            line: PrismState.searching ? Translation.tr("Settings") : Translation.tr("From the factory profile")
                            title: Translation.tr("%1 found").arg(parent.hits.length)
                            glyph: PrismState.searching ? "search" : "history"
                            rows: found.hits.slice(0, found.built)
                            showPage: true
                            onReach: row => root.reach(row)
                        }
                    }
                }

            }
        }

        // A page iRiS draws itself: Prism gives it the title and the room; the view scrolls on its own.
        Item {
            id: hostedBox
            visible: root.hosted
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.rightMargin: root.railWidth
            height: parent.height
            PrismBand {
                id: hostedTop
                x: PrismTheme.dp(4)
                y: PrismTheme.dp(16)
                width: parent.width - PrismTheme.dp(20)
                page: root.page
            }
            Loader {
                anchors.top: hostedTop.bottom
                anchors.topMargin: PrismTheme.dp(8)
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                active: root.hosted
                source: root.hosted ? root.page.view : ""
                // Prism's marks are ink alone (only the chosen wears colour): the page's own tinted marks give way.
                onLoaded: {
                    if (item && item.markDelegate !== undefined) item.markDelegate = hostedMark
                    if (item && item.plainMarks !== undefined) item.plainMarks = true
                }
            }
            Component {
                id: hostedMark
                PrismGlyph {
                    text: parent ? String(parent.glyph ?? "") : ""
                    iconSize: PrismTheme.dp(18)
                    color: PrismTheme.ink2
                }
            }
        }

        // Rows leaving the top soften into a blur and fade into the page, and so does the foot while rows wait past it.
        IrisScrollEdge {
            id: centreEdge
            visible: centre.visible
            flick: centre
            anchors.fill: centre
            reach: PrismTheme.dp(36)
            veil: PrismTheme.canvas
            // The veil alone: the blurred band read the page into a texture and blurred it on every scrolled frame,
            // which is what a weak GPU felt as a page scrolling at few frames (11-11).
            blurs: false
            // Its ends meet the body's round corners unless the rail stands there.
            topRightRadius: root.railWidth > 0 ? 0 : body.radius
            bottomRightRadius: root.railWidth > 0 ? 0 : body.radius
        }

        PrismRail {
            id: rail
            x: Math.round(body.width - rail.width * root.railShown)
            width: PrismTheme.dp(300)
            visible: root.railShown > 0
            opacity: root.railShown
            height: parent.height
            active: root.active && rail.visible
            pageId: root.hosted || PrismState.searching || root.changesView ? "" : String(root.page.pageId ?? "")
            pageName: String(root.page.name ?? "")
            groups: root.groups
            current: root.bandOf(root.currentGroup)
            onPickGroup: title => root.showGroup(title)
            onSeeAllChanges: PrismState.go("changes")
            onReach: row => root.reach(row)
        }

        // The side column's own key, at the page's top corner where the column begins: it folds it away and brings it
        // back, and stays in reach however far the page is read.
        PrismRound {
            visible: root.railFits && !leaf.visible
            x: Math.round(body.width - root.railWidth - width - PrismTheme.dp(32))
            y: PrismTheme.dp(18)
            z: 5
            glyph: root.railOpen ? "right_panel_close" : "right_panel_open"
            Accessible.role: Accessible.Button
            Accessible.name: root.railOpen ? Translation.tr("Hide the side column") : Translation.tr("Show the side column")
            onClicked: root.toggleRail()
        }

        IrisSettingsIsland {
            d: IrisStyle.settingsDensity
            room: centre.width
            allowed: root.active && !IrisOptions.homeEditing
            x: Math.round(centre.x + (centre.width - width) / 2)
            y: Math.round(body.height - height - PrismTheme.dp(22))
            z: 20
        }
    }
    // Home: the tiles touched every day by the drawing; under both the wallpaper with sound and light, then every
    // page of Settings as an index. Wallpaper's sheet holds the wallpapers to go back to.
    Component {
        id: homeSide
        PrismHome { editing: root.homeArranging; onReach: row => root.reach(row) }
    }
    Component {
        id: homeExtra
        Column {
            id: blocks
            spacing: PrismTheme.dp(30)
            Loader {
                active: root.homeArranging
                visible: active
                width: blocks.width
                sourceComponent: PrismHomeArrange { onDone: root.homeArranging = false }
            }
            Repeater {
                model: root.homeBlocks.filter(id => !(id === "everyday" && leaf.siding))
                delegate: Loader {
                    required property string modelData
                    width: blocks.width
                    sourceComponent: ({ everyday: homeEveryday, deck: homeDeck, groups: homeGroups, index: homeIndex })[modelData] ?? null
                }
            }
        }
    }
    Component { id: homeEveryday; PrismHome { editing: root.homeArranging; onReach: row => root.reach(row) } }
    Component { id: homeDeck; PrismHomeDeck {} }
    Component { id: homeIndex; PrismIndex {} }
    Component { id: homeGroups; PrismShelf { groups: root.shownSections; tint: root.page.tint; flashPath: root.flashPath } }
    // The pages drawn to their measure.
    Component { id: colourHero; PrismColourHero { onPickGroup: title => root.showGroup(title) } }
    Component { id: typeHero; PrismTypeHero { onPickGroup: title => root.showGroup(title) } }
    Component { id: lockHero; PrismLockHero { onAction: id => root.act(id); onPickGroup: title => root.showGroup(title) } }
    Component {
        id: wallpaperExtra
        PrismWallpaperHero {
            restorable: 0
        }
    }
    // The page's top: back and forward, then where it stands and its name.
    component PageTop: Column {
        spacing: 0
        Row {
            topPadding: PrismTheme.dp(18)
            spacing: PrismTheme.dp(8)
            PrismRound { glyph: "chevron_left"; enabled_: PrismState.canBack; onClicked: PrismState.goBack() }
            PrismRound { glyph: "chevron_right"; enabled_: PrismState.canForward; onClicked: PrismState.goForward() }
        }
        Item { width: 1; height: PrismTheme.dp(18) }
        PrismHeading {
            width: parent.width
            eyebrow: PrismState.searching ? Translation.tr("Search")
                : root.changesView ? Translation.tr("Yours") : Translation.tr(root.page.group)
            title: PrismState.searching ? "“" + PrismState.asked.trim() + "”"
                : root.changesView ? Translation.tr("Changes") : Translation.tr(root.page.name)
        }
        Item { width: 1; height: PrismTheme.dp(18) }
    }
}
