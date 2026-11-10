import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.components
import qs.modules.iris.settings
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls
import qs.modules.iris.prism.parts

// Prism's body: sidebar, the page in the middle (heading, hero, sections) and the rail. Lays itself out from the room
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
    readonly property bool hosted: !PrismState.searching && !root.changesView && String(root.page.view ?? "").length > 0
    readonly property var sections: PrismState.searching || root.changesView || root.hosted ? [] : PrismModel.sectionsOf(root.page.pageId)
    // A long page is read in parts of a screenful or two (whole groups, about 24 rows each); a short one stacks every
    // group. Either way the sidebar's index under the page names each group and follows the reading, and a part ends
    // on the next one (his 11-07: never looked for sideways, never one two-row group alone on a screen).
    readonly property bool paged: PrismModel.paged(root.sections)
    readonly property var parts: {
        if (!root.paged) return [root.sections]
        const out = []
        let part = [], rows = 0
        for (const section of root.sections) {
            const n = section.rows.length
            if (part.length > 0 && rows + n > 28) { out.push(part); part = []; rows = 0 }
            part.push(section)
            rows += n
            if (rows >= 20) { out.push(part); part = []; rows = 0 }
        }
        if (part.length > 0) out.push(part)
        return out
    }
    readonly property string group: {
        const chosen = String(PrismState.groupOf[root.page.pageId] ?? "")
        return root.sections.some(section => section.title === chosen) ? chosen : String(root.sections[0]?.title ?? "")
    }
    readonly property int partIndex: Math.max(0, root.parts.findIndex(part => part.some(section => section.title === root.group)))
    readonly property var shownSections: root.parts[root.partIndex] ?? []
    // The index in the sidebar: every group, with a dot where something differs from the factory.
    readonly property var groups: root.sections.map(section => ({ title: section.title, changed: section.rows.some(row => PrismModel.changed(row)) }))
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

        PrismSidebar {
            id: sidebar
            width: root.sideWidth
            height: parent.height
            corner: body.radius
            windowed: root.windowed
            groups: root.sections.length > 1 ? root.groups : []
            currentGroup: root.currentGroup
            onCloseRequested: root.closeRequested()
            onMinimizeRequested: root.minimizeRequested()
            onGrowRequested: root.growRequested()
            onSwitchHost: root.switchHost()
            onReach: row => root.reach(row)
            onPickGroup: title => root.showGroup(title)
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

                PageTop { width: content.width }

                PrismHero {
                    visible: !PrismState.searching && !root.changesView && root.page.pageId !== "wallpaper"
                    width: content.width
                    page: root.page
                    number: PrismModel.index(root.page.pageId) + 1
                    count: root.sections.reduce((n, section) => n + section.rows.length, 0)
                    changed: PrismModel.changedOf(root.page.pageId)
                    restorable: PrismModel.restorableOf(root.page.pageId)
                    lead: root.page.lead.map(path => PrismModel.find(path)).filter(row => row !== null)
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
                Item { visible: !PrismState.searching && !root.changesView; width: 1; height: PrismTheme.dp(34) }

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
                            eyebrow: PrismState.searching ? Translation.tr("Settings") : Translation.tr("From the factory profile")
                            title: Translation.tr("%1 found").arg(parent.hits.length)
                            rows: found.hits.slice(0, found.built)
                            showPage: true
                            onReach: row => root.reach(row)
                        }
                    }
                }

                Item { id: groupsAt; width: 1; height: 0 }

                // Groups keyed by title: a write rebuilds the list, never the groups on screen.
                Repeater {
                    id: sectionsRepeater
                    model: ScriptModel { objectProp: "title"; values: root.shownSections }
                    delegate: Column {
                        id: sectionBox
                        required property var modelData
                        required property int index
                        visible: sectionBox.modelData.rows.length > 0
                        width: content.width
                        PrismSection {
                            width: parent.width
                            eyebrow: Translation.tr(root.page.name)
                            title: Translation.tr(sectionBox.modelData.title)
                            rows: sectionBox.modelData.rows
                            heads: sectionBox.index === 0
                            firstNumber: 1
                            flashPath: root.flashPath
                            note: root.paged ? String(root.sections.findIndex(section => section.title === sectionBox.modelData.title) + 1).padStart(2, "0") + " / " + String(root.sections.length).padStart(2, "0") : ""
                        }
                        Item { width: 1; height: PrismTheme.dp(36) }
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
            PageTop {
                id: hostedTop
                x: PrismTheme.dp(32)
                width: parent.width - PrismTheme.dp(64)
            }
            Loader {
                anchors.top: hostedTop.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                active: root.hosted
                source: root.hosted ? root.page.view : ""
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
            // Its foot meets the body's round corner unless the rail stands there.
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
            onSeeAllChanges: PrismState.go("changes")
            onReach: row => root.reach(row)
        }

        // The side column's own key, at the page's top corner where the column begins: it folds it away and brings it
        // back, and stays in reach however far the page is read.
        PrismRound {
            visible: root.railFits
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
