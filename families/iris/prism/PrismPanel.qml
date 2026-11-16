import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.components
import qs.modules.iris.settings
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.fx
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls
import qs.modules.iris.prism.parts

// Prism's body: sidebar, the page in the middle and the rail, laid out from the room it is given; its host places it.
Item {
    id: root
    property bool active: true
    property string flashPath: ""
    // Hosted as a window: square corners (the compositor rounds it), the lights act on the window.
    property bool windowed: false
    // Under Glass the overlay lends the blurred wallpaper and where the panel lies on the screen.
    property Item backdrop: null
    property point screenAt: Qt.point(0, 0)
    property size screenSize: Qt.size(1, 1)
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
    readonly property bool hosted: !PrismState.searching && !root.changesView && String(root.page.view ?? "").length > 0
    readonly property var sections: PrismState.searching || root.changesView || root.hosted ? [] : PrismModel.sectionsOf(root.page.pageId)
    // A long page is read in parts of a screenful or two (whole groups, about 24 rows each); a short one stacks every
    // group. Either way the sidebar's index under the page names each group and follows the reading, and a part ends
    // on the next one (his 11-07: never looked for sideways, never one two-row group alone on a screen).
    // Where it splits is read from every row the page may show, so a switch that shows or hides its neighbours
    // never moves a group into another part under the reader (his 11-10: a toggle threw the page elsewhere).
    readonly property var layout: root.sections.length === 0 ? [] : PrismModel.layoutOf(root.page.pageId)
    readonly property bool paged: PrismModel.paged(root.layout)
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
    // A page drawn as cards with pictures (not Home, Wallpaper, a search or Changes): which card wears which.
    readonly property bool staged: !PrismState.searching && !root.changesView && root.page.pageId !== "wallpaper" && root.page.pageId !== "general"
    readonly property var figures: {
        return root.staged ? PrismModel.figuresOf(root.page.pageId, root.sections.map(section => section.title)) : ({})
    }
    // The words on the page's top: where it stands and its name, or what was asked and Changes.
    readonly property string topEyebrow: PrismState.searching ? Translation.tr("Search") : root.changesView ? Translation.tr("Yours") : Translation.tr(root.page.group)
    readonly property string topTitle: PrismState.searching ? "“" + PrismState.asked.trim() + "”" : root.changesView ? Translation.tr("Changes") : Translation.tr(root.page.name)
    // Where a card's picture keeps to while the page is read: under the strip once it shows, else under the top edge.
    readonly property real stickTop: stripBar.shown ? stripBar.y + stripBar.height + PrismTheme.dp(14) : PrismTheme.dp(20)
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
    function spy(): void {
        if (sectionsRepeater.count === 0 || glider.running) return
        const line = centre.contentY + centre.height * 0.3
        let at = String(sectionsRepeater.itemAt(0)?.modelData?.title ?? "")
        for (let i = 0; i < sectionsRepeater.count; ++i) {
            const box = sectionsRepeater.itemAt(i)
            if (box && box.visible && box.y + content.y <= line) at = String(box.modelData.title)
        }
        // The page's foot: the last group is where the reader stands, short as it may be.
        if (centre.contentY >= centre.contentHeight - centre.height - 2)
            at = String(sectionsRepeater.itemAt(sectionsRepeater.count - 1)?.modelData?.title ?? at)
        root.spyGroup = at
    }
    function boxOf(title: string): var {
        for (let i = 0; i < sectionsRepeater.count; ++i) {
            const box = sectionsRepeater.itemAt(i)
            if (box?.modelData?.title === title) return box
        }
        return null
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
        // Past the stage its strip stands over the page's top: the head rests under it.
        const clear = stripBar.wanted ? stripBar.y + stripBar.height + PrismTheme.dp(12) : PrismTheme.dp(42)
        const y = box.y + content.y - clear
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

    // The body's round corners are drawn by what stands in them: a mask over the body rendered Prism twice a frame (11-07).
    readonly property bool watching: root.active && root.visible
    onWatchingChanged: PrismModel.watching = root.watching
    Component.onCompleted: PrismModel.watching = root.watching
    Component.onDestruction: PrismModel.watching = false

    Rectangle {
        id: body
        anchors.fill: parent
        radius: root.windowed ? 0 : PrismTheme.dp(28)
        color: PrismTheme.glass ? "transparent" : PrismTheme.canvas
        clip: true

        // The page's colour in the air of the whole panel, under every column (his 11-15).
        PrismAura { id: air; anchors.fill: parent; key: String(root.page?.pageId ?? ""); tint: String(root.page?.tint ?? "grey"); radius: body.radius
            backdrop: root.backdrop; screenAt: root.screenAt; screenSize: root.screenSize }

        PrismSidebar {
            id: sidebar
            width: root.sideWidth
            height: parent.height
            corner: body.radius
            windowed: root.windowed
            groups: root.sections.length > 1 ? root.groups : []
            currentGroup: root.bandOf(root.currentGroup)
            onCloseRequested: root.closeRequested()
            onMinimizeRequested: root.minimizeRequested()
            onGrowRequested: root.growRequested()
            onSwitchHost: root.switchHost()
            onReach: row => root.reach(row)
            onPickGroup: title => root.showGroup(root.firstOf(title))
            onSearchEntered: root.takeFirstHit()
        }

        Flickable {
            id: centre
            visible: !root.hosted
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.rightMargin: root.railWidth
            height: parent.height
            contentHeight: content.implicitHeight + PrismTheme.dp(40)
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
                x: PrismTheme.dp(32)
                width: centre.width - PrismTheme.dp(64)
                spacing: 0

                // The page opens on its poster: the page's art, where it stands and its size printed small, its name
                // big, what it holds now as figures. A search, Changes, Home and Wallpaper keep the words without art.
                // The poster stands off the window's top edge as the folders under it do.
                Item { width: 1; height: root.staged ? PrismTheme.dp(14) : 0 }
                PrismPoster {
                    width: content.width
                    art: root.staged
                    page: root.page
                    eyebrow: root.topEyebrow
                    title: root.topTitle
                    number: !PrismState.searching && !root.changesView ? PrismModel.index(root.page.pageId) + 1 : 0
                    total: PrismModel.ids.length
                    settings: root.staged ? root.sections.reduce((n, section) => n + section.rows.length, 0) : 0
                    changed: root.staged ? PrismModel.changedOf(root.page.pageId).length : 0
                    restorable: root.staged ? PrismModel.restorableOf(root.page.pageId) : 0
                    pills: root.staged
                    lead: root.staged ? PrismModel.leadOf(root.page) : []
                    keyRoom: railKey.visible ? PrismTheme.dp(44) : 0
                    onRestore: PrismModel.restore(root.page.pageId)
                }
                // Wallpaper opens on the wallpaper itself: what is worn and the ones to go back to.
                Loader {
                    active: !PrismState.searching && !root.changesView && root.page.pageId === "wallpaper"
                    visible: active
                    width: content.width
                    sourceComponent: PrismWallpaperHero {
                        width: content.width
                        restorable: PrismModel.restorableOf(root.page.pageId)
                        onRestore: PrismModel.restore(root.page.pageId)
                    }
                }
                Item { visible: !PrismState.searching && !root.changesView; width: 1; height: root.staged ? PrismTheme.dp(26) : PrismTheme.dp(12) }

                // Home: the settings touched every day, as tiles that act.
                Loader {
                    active: !PrismState.searching && !root.changesView && root.page.pageId === "general"
                    visible: active
                    width: content.width
                    sourceComponent: Column {
                        width: content.width
                        PrismHomeDeck { width: parent.width }
                        Item { width: 1; height: PrismTheme.dp(34) }
                        PrismHome { width: parent.width; onReach: row => root.reach(row) }
                        Item { width: 1; height: PrismTheme.dp(40) }
                    }
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

                // Where the groups begin, a pixel tall: a Column leaves an item of no height at y 0.
                Item { id: groupsAt; width: 1; height: 1 }

                // Groups keyed by title: a write rebuilds the list, never the groups on screen.
                Repeater {
                    id: sectionsRepeater
                    model: ScriptModel { objectProp: "title"; values: root.shownSections }
                    delegate: Column {
                        id: sectionBox
                        required property var modelData
                        required property int index
                        visible: sectionBox.modelData.rows.length > 0 || Boolean(root.figures[sectionBox.modelData.title]?.keys)
                        width: content.width
                        PrismSection {
                            width: parent.width
                            figure: root.figures[sectionBox.modelData.title] ?? null
                            groups: root.groups
                            entry: root.bandOf(sectionBox.modelData.title)
                            viewTop: centre.contentY + root.stickTop - content.y - sectionBox.y
                            viewHeight: centre.height - root.stickTop
                            active: root.active
                            onGoGroup: title => root.showGroup(root.firstOf(title))
                            title: Translation.tr(sectionBox.modelData.title)
                            glyph: String(sectionBox.modelData.glyph ?? root.page.glyph)
                            tint: root.page.tint
                            rows: sectionBox.modelData.rows
                            flashPath: root.flashPath
                            note: ""
                        }
                        Item { width: 1; height: PrismTheme.dp(18) }
                    }
                }

                // A long page's part ends on where to go next: the next part's first group large, the part before quiet.
                PrismNextGroup {
                    visible: root.paged && !PrismState.searching && !root.changesView && root.parts.length > 1
                    width: content.width
                    previous: root.partIndex > 0 ? String(root.parts[root.partIndex - 1][0].title) : ""
                    next: root.partIndex < root.parts.length - 1 ? String(root.parts[root.partIndex + 1][0].title) : ""
                    first: String(root.sections[0]?.title ?? "")
                    then: root.partIndex < root.parts.length - 1 ? root.parts[root.partIndex + 1].slice(1).map(section => Translation.tr(section.title)) : []
                    position: root.partIndex + 1
                    count: root.parts.length
                    onPick: title => root.showGroup(title)
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
            PrismPoster {
                id: hostedTop
                x: PrismTheme.dp(32)
                width: parent.width - PrismTheme.dp(64)
                art: false
                pills: false
                page: root.page
                eyebrow: root.topEyebrow
                title: root.topTitle
                keyRoom: railKey.visible ? PrismTheme.dp(44) : 0
            }
            // iRiS's own pages keep 16 dp of air each side: given 16 more, their column stands on Prism's.
            Loader {
                readonly property real air: String(root.page.view ?? "").includes("/prism/parts/") ? 0 : PrismTheme.dp(16)
                anchors { top: hostedTop.bottom; bottom: parent.bottom; left: parent.left; right: parent.right
                    leftMargin: air; rightMargin: air }
                active: root.hosted
                source: root.hosted ? root.page.view : ""
            }
        }

        // Rows leaving the top or past the foot melt into the air drawn again over each edge (nothing offscreen, 11-11).
        // Over the compositor's blur nothing can be drawn again: rows end at the panel's edge, as any glass window's.
        Repeater {
            model: [1, -1]
            delegate: PrismAura {
                required property int modelData
                x: centre.x; y: modelData > 0 ? 0 : body.height - height; width: centre.width; height: PrismTheme.dp(36)
                visible: centre.visible && !PrismTheme.glassBlur && (modelData > 0 ? centre.contentY > 1 : centre.contentY + centre.height < centre.contentHeight - 1)
                fadeDir: modelData; frameSize: Qt.size(body.width, body.height); origin: Qt.point(x, y)
                key: air.key; tint: air.tint; radius: body.radius; backdrop: air.backdrop; screenAt: air.screenAt; screenSize: air.screenSize
            }
        }

        // Scrolled past the page's top, the page keeps its groups as a strip: every group one press away, the open one lit.
        PrismStrip {
            id: stripBar
            readonly property bool wanted: root.staged && root.groups.length > 1
            x: centre.x + content.x
            y: PrismTheme.dp(12)
            // It ends before the side column's key, which comes down into its line while it shows.
            width: (railKey.visible ? railKey.x - PrismTheme.dp(10) : centre.x + content.x + content.width) - x
            shown: stripBar.wanted && centre.visible && centre.contentY > groupsAt.y - PrismTheme.dp(24)
            page: root.page
            groups: root.groups
            currentGroup: root.bandOf(root.currentGroup)
            restorable: PrismModel.restorableOf(root.page.pageId)
            onPickGroup: title => root.showGroup(root.firstOf(title))
            onRestore: PrismModel.restore(root.page.pageId)
        }

        PrismRail {
            id: rail
            x: Math.round(body.width - rail.width * root.railShown)
            width: PrismTheme.dp(300)
            visible: root.railShown > 0
            opacity: root.railShown
            height: parent.height
            active: root.active && rail.visible
            onSeeAllChanges: PrismState.go("changes")
            onReach: row => root.reach(row)
        }

        // The side column's own key, at the page's top corner: it folds the column away and back, in reach at any depth.
        PrismRound {
            id: railKey
            visible: root.railFits
            x: Math.round(body.width - root.railWidth - width - PrismTheme.dp(32) - (root.staged && !root.hosted ? PrismTheme.dp(22) : 0))
            y: stripBar.shown ? Math.round(stripBar.y + (stripBar.height - height) / 2) : PrismTheme.dp(root.staged && !root.hosted ? 32 : 18)
            Behavior on y { NumberAnimation { duration: PrismTheme.ms(240); easing.type: IrisStyle.feedbackEasing } }
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

    // The window's glass edge, over its columns; a window of its own has its frame from the compositor.
    PrismRim {
        anchors.fill: body
        visible: !root.windowed
        radius: body.radius
        tint: String(root.page?.tint ?? "grey")
    }
}
