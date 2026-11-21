import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.settings
import qs.modules.iris.style
import qs.modules.iris.state
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls
import qs.modules.iris.prism.parts

// Prism's body: the sidebar and the page beside it. A page is its name, then (only where a picture decides: Home,
// Wallpaper, Colour, Type, Lock, the keyboard) the person's own thing drawn as it is now, then its groups as cards.
// Lays itself out from the room it is given; the window around it only places it.
Item {
    id: root
    property bool active: true
    property string flashPath: ""
    // Hosted as a window: square corners (the compositor rounds a window), the keys act on the window.
    property bool windowed: false
    // Under Glass the overlay lends the blurred wallpaper and where the panel lies on it.
    property Item backdrop: null
    property point screenAt: Qt.point(0, 0)
    signal closeRequested()
    // In a window: the window goes to the dock as any app's would.
    signal minimizeRequested()
    // In a window: its column takes the screen.
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
    readonly property string pageId: String(root.page.pageId ?? "")
    readonly property bool home: !PrismState.searching && root.pageId === "general"
    // A page iRiS draws as a view of its own (Community Hub, Keyboard shortcuts, About) fills the room under its head.
    readonly property bool hosted: !PrismState.searching && String(root.page.view ?? "").length > 0
    // The page's lead (PrismLead) says some rows itself: they leave the groups, and a group it stands for whole goes.
    readonly property var lead: PrismModel.leads[root.pageId] ?? null
    readonly property var sections: {
        if (PrismState.searching || root.hosted) return []
        const all = PrismModel.sectionsOf(root.pageId)
        if (!root.lead) return all
        const owned = Array.from(root.lead.tiles ?? []).map(tile => tile[0])
        const gone = Array.from(root.lead.groups ?? [])
        return all.filter(group => !gone.includes(group.title)).map(group => {
            const kept = group.rows.filter(row => !owned.includes(row.path))
            if (kept.length === group.rows.length) return group
            const first = group.rows[0]
            // The group's own master (named as it) went to the lead: the group still dims by it.
            const named = String(first.label ?? "").trim().toLowerCase() === String(group.title ?? "").trim().toLowerCase()
            const master = named && owned.includes(first.path) && String(first.kind) === "switch" ? first : null
            return { title: group.title, glyph: group.glyph, rows: kept, lead: master }
        }).filter(group => group.rows.length > 0)
    }
    // The keyboard page draws the keyboard itself, live, where the compositor says which one it is.
    readonly property bool keyboardShown: root.pageId === "keyboard" && CompositorConfig.has("input", "keyboard.layout")
    // Displays draws the screen it changes, wherever the compositor names one.
    readonly property bool displayShown: root.pageId === "display" && CompositorConfig.output !== null
    readonly property bool deskShown: ["layout", "windows", "glass"].includes(root.pageId) && CompositorConfig.available && CompositorConfig.output !== null
    // What a page shows before its groups: the person's own thing, as it is now.
    readonly property Component hero: PrismState.searching ? null
        : (({ general: homeHero, wallpaper: wallpaperHero, colour: colourHero, typeIcons: typeHero, lock: lockHero })[root.pageId]
            ?? (root.keyboardShown ? keyboardHero : root.displayShown ? displayHero : root.deskShown ? deskHero : root.lead ? leadHero : null))
    // What acts on the page's own thing, at the head: arrange the Control Center, send a notice, take the screen.
    readonly property var pageActions: ({
        controlCenter: [{ id: "arrange", glyph: "dashboard_customize", text: "Arrange it" }],
        notifications: [{ id: "test", glyph: "notifications_active", text: "Send a test" }],
        capture: [{ id: "shot", glyph: "screenshot_region", text: "Screenshot" }, { id: "ocr", glyph: "document_scanner", text: "Read text" },
            { id: "record", glyph: "screen_record", text: "Record" }]
    })[root.pageId] ?? []
    // Home is the person's: their name, and the machine they sit at (never a greeting).
    readonly property string person: String(SystemInfo.displayName || SystemInfo.username || "")
    readonly property string machine: [String(SystemInfo.username ?? ""), String(SystemInfo.hostname ?? "")].filter(part => part.length > 0).join("@")
        + (["", "Unknown"].includes(String(SystemInfo.distroName ?? "")) ? "" : "  ·  " + SystemInfo.distroName)
    readonly property var fact: { const facts = PrismModel.leadOf(root.page); return facts.length > 0 ? facts[0] : null }
    // The screen tools start once Settings has left the screen, so it is never in the picture.
    Timer { id: afterClose; property var run: null; interval: 320; onTriggered: if (afterClose.run) afterClose.run() }
    function act(id: string): void {
        if (id === "test") { Notifications.sendTestNotifications(); return }
        if (id === "shot" || id === "ocr" || id === "record") {
            root.closeRequested()
            afterClose.run = id === "shot" ? () => GlobalStates.openRegionScreenshot() : () => ShellExec.execDetachedArgs(["inir", "region", id])
            afterClose.restart()
            return
        }
        if (id === "lockEdit") { root.closeRequested(); IrisState.lockEdit = true; return }
        if (id === "lockNow") { root.closeRequested(); Session.lock(); return }
        if (id === "arrange") {
            root.closeRequested()
            IrisState.morphOwner = ""
            GlobalStates.controlPanelOpen = true
            IrisState.controlEdit = true
        }
    }

    // The group a page last showed, or the one a request named.
    readonly property string group: {
        const chosen = String(PrismState.groupOf[root.pageId] ?? "")
        return root.sections.some(section => section.title === chosen) ? chosen : ""
    }
    // Until when a change of layout aims again at what was asked for (rows are still being built under it).
    property real aimUntil: 0
    property string aimed: ""
    // A group asked for glides to its card's top, clear of the blurred edge.
    // A group asked for by name (the sidebar, a search's place): it is marked as read, glides into view and its folder
    // warms with the accent a moment, so the eye lands on it.
    function markGroup(title: string): void {
        root.held = title
        root.showGroup(title)
        shelf.boxOf(title)?.flash()
        readLater.restart()
    }
    function showGroup(title: string): void {
        root.aimed = title
        root.aimUntil = Date.now() + 700
        const box = shelf.boxOf(title)
        if (box) root.glide(shelf.y + box.y + content.y - centreEdge.reach - PrismTheme.dp(8))
    }
    function glide(y: real): void {
        const to = Math.max(0, Math.min(centre.contentHeight - centre.height, y))
        root.heldY = to
        if (glider.running && Math.abs(glider.to - to) < 2) return
        if (!glider.running && Math.abs(centre.contentY - to) < 2) return
        glider.stop()
        glider.to = to
        glider.start()
    }
    NumberAnimation { id: glider; target: centre; property: "contentY"; duration: PrismTheme.ms(360); easing.type: Easing.OutCubic }
    // The page under a group asked for is still growing (cards are placed over a few frames): aim again once it rests.
    Timer {
        id: aimLater
        interval: 50
        onTriggered: {
            if (Date.now() > root.aimUntil) return
            if (root.flashPath.length > 0) { root.placeRow(); return }
            if (root.aimed.length > 0) root.showGroup(root.aimed)
        }
    }

    // A new picture for the person (the side column's or Home's own face): the shell's picker, then the account's.
    function chooseAvatar(): void { avatarPicker.open() }
    FilePickerDialog {
        id: avatarPicker
        title: Translation.tr("Profile picture")
        nameFilters: [Translation.tr("Images") + " (*.png *.jpg *.jpeg *.webp *.bmp *.avif)"]
        onAccepted: {
            setAvatar.command = [Quickshell.shellPath("scripts/accounts/set-avatar.sh"), FileUtils.trimFileProtocol(String(avatarPicker.selectedFile))]
            setAvatar.running = true
        }
    }
    Process {
        id: setAvatar
        onExited: exitCode => { if (exitCode === 0) Directories.userAvatarRevision++ }
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
    // Reach a row: its page, the row scrolled into view and lit once.
    function reach(row: var): void {
        if (!row) return
        PrismState.query = ""
        PrismState.go(row.page)
        root.aimUntil = Date.now() + 700
        root.flashPath = row.path
        reachLater.restart()
    }
    function placeRow(): void {
        const item = root.findRow(content, root.flashPath)
        if (!item) return
        const y = item.mapToItem(content, 0, 0).y
        centre.contentY = Math.max(0, Math.min(centre.contentHeight - centre.height, y + content.y - centre.height * 0.35))
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
            if (child.row !== undefined && child.row?.path === path && child.flash !== undefined) return child
            const found = root.findRow(child, path)
            if (found) return found
        }
        return null
    }
    Timer { id: flashOff; interval: 1400; onTriggered: root.flashPath = "" }

    Connections {
        target: PrismState
        function onPageChanged() { glider.stop(); root.aimed = ""; root.held = ""; centre.contentY = 0; IrisOptions.settle() }
        // A search reads from its top: the best hits and the places they name come first.
        function onQueryChanged() { glider.stop(); root.aimed = ""; centre.contentY = 0 }
        // A group asked for (a search place, a request "section/group") comes into sight once the page is laid out.
        function onGroupAskChanged() { groupLater.restart() }
    }
    Timer {
        id: groupLater
        interval: 40
        onTriggered: if (root.flashPath.length === 0 && root.group.length > 0) root.markGroup(root.group)
    }

    readonly property bool watching: root.active && root.visible
    onWatchingChanged: PrismModel.watching = root.watching
    Component.onCompleted: PrismModel.watching = root.watching
    Component.onDestruction: PrismModel.watching = false

    readonly property real sideWidth: PrismTheme.dp(244)
    // The page's measure: its cards run between two even margins, never wider than a comfortable read.
    readonly property real measure: Math.min(centre.width - 2 * PrismTheme.dp(32), PrismTheme.dp(1040))

    // The right column (PrismAside): open where the page keeps a comfortable measure beside it; the person may open or
    // close it (iris.appearance.settingsRail: auto | open | closed). A page iRiS draws itself takes the whole room.
    readonly property string asideMode: String(Config.options?.iris?.appearance?.settingsRail ?? "auto")
    readonly property real asideBase: PrismTheme.dp(276)
    readonly property real asideRoom: root.width - root.sideWidth - root.asideBase
    readonly property bool asideFits: !root.hosted && root.asideRoom >= PrismTheme.dp(620)
    readonly property bool asideAuto: root.asideRoom >= PrismTheme.dp(760)
    readonly property bool asideOpen: root.asideFits && (root.asideMode === "open" || root.asideMode !== "closed" && root.asideAuto)
    readonly property real asideWidth: root.asideOpen ? root.asideBase : 0
    function toggleAside(): void {
        const next = !root.asideOpen
        Config.setNestedValue("iris.appearance.settingsRail", next === root.asideAuto ? "auto" : next ? "open" : "closed")
    }

    // The open page's parts for the sidebar, and those on screen now (a line of cards holds one or two).
    readonly property var subsections: root.home || PrismState.searching || root.hosted ? [] : root.sections.map(section => String(section.title))
    property var reading: []
    // A group pressed in the sidebar is the one read while the page rests where it glided to; a scroll away lets the
    // page say again what is on screen (a short card used to hand the mark to its neighbour under the reading line).
    property string held: ""
    property real heldY: -1
    function readNow(): void {
        if (root.subsections.length < 2 || !shelf.visible) { if (root.reading.length > 0) root.reading = []; return }
        if (root.held.length > 0) {
            if (glider.running || Math.abs(centre.contentY - root.heldY) < PrismTheme.dp(24)) {
                if (root.reading.join("|") !== root.held) root.reading = [root.held]
                return
            }
            root.held = ""
        }
        const top = centre.contentY + centre.height * 0.32
        const atEnd = centre.contentY >= centre.contentHeight - centre.height - 2
        let best = null
        let last = null
        for (const title of root.subsections) {
            const box = shelf.boxOf(title)
            if (!box || box === last) continue
            last = box
            if (best === null || content.y + shelf.y + box.y <= top) best = box
        }
        if (atEnd && last) best = last
        const next = best ? Array.from(best.titles ?? []).map(String) : []
        if (next.join("|") !== root.reading.join("|")) root.reading = next
    }
    Timer { id: readLater; interval: 60; onTriggered: root.readNow() }
    onSubsectionsChanged: readLater.restart()

    // The panel wears the shell's glass (his 11-20: "tiene que respetar la shell"): under Glass the wallpaper, blurred,
    // where the panel lies on it, cut by the body's own round (a fill: a clip is square); under Blur nothing, the
    // compositor blurs behind. Over either, the body is the canvas at the veil's share.
    Loader {
        anchors.fill: parent
        active: PrismTheme.glassWallpaper && root.backdrop !== null
        sourceComponent: Item {
            id: glass
            // The cut fills only once the picture's layer stands (a fill that is no texture yet warns, draws nothing).
            property bool built: false
            Component.onCompleted: glass.built = true
            // The screen's blurred wallpaper, moved so the panel's part of it lies under the panel: a texture of the
            // panel's own size, redrawn only when the picture changes.
            Item {
                id: picture
                width: glass.width
                height: glass.height
                visible: false
                clip: true
                layer.enabled: true
                ShaderEffect {
                    x: -root.screenAt.x
                    y: -root.screenAt.y
                    width: root.backdrop?.width ?? 0
                    height: root.backdrop?.height ?? 0
                    property variant source: root.backdrop
                }
            }
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillItem: glass.built ? picture : null
                    strokeColor: "transparent"
                    strokeWidth: -1
                    PathRectangle { width: glass.width; height: glass.height; radius: body.radius }
                }
            }
        }
    }
    Rectangle {
        id: body
        anchors.fill: parent
        radius: root.windowed ? 0 : PrismTheme.corner
        color: PrismTheme.glass ? ColorUtils.applyAlpha(PrismTheme.canvas, PrismTheme.veil) : PrismTheme.canvas
        clip: true

        PrismSidebar {
            id: sidebar
            width: root.sideWidth
            height: parent.height
            corner: body.radius
            subsections: root.subsections
            reading: root.reading
            onReach: row => root.reach(row)
            onSearchEntered: root.takeFirstHit()
            onPickGroup: title => root.markGroup(title)
        }

        PrismAside {
            id: aside
            x: body.width - root.asideBase
            width: root.asideBase
            height: parent.height
            visible: opacity > 0
            opacity: root.asideOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
            active: root.active && root.asideOpen
            pageId: root.pageId
            everywhere: root.home || PrismState.searching
            onReach: row => root.reach(row)
            onPictureAsked: root.chooseAvatar()
        }

        Flickable {
            id: centre
            visible: !root.hosted
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.rightMargin: root.asideWidth
            height: parent.height
            contentHeight: content.y + content.implicitHeight + PrismTheme.dp(96)
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            onContentHeightChanged: { if (Date.now() < root.aimUntil) aimLater.restart(); readLater.restart() }
            onContentYChanged: readLater.restart()

            Column {
                id: content
                x: Math.round((centre.width - width) / 2)
                y: PrismTheme.dp(24)
                width: root.measure
                spacing: 0

                PrismPageHead {
                    width: content.width
                    plain: PrismState.searching
                    person: root.home
                    eyebrow: root.home ? root.machine : Translation.tr(String(root.page.group ?? ""))
                    tint: String(root.page.tint ?? "grey")
                    turn: PrismModel.index(root.pageId)
                    // Battery's lead says the charge itself: the head does not say it again.
                    fact: root.home || root.pageId === "battery" ? null : root.fact
                    title: PrismState.searching ? "“" + PrismState.asked.trim() + "”"
                        : root.home && root.person.length > 0 ? root.person : Translation.tr(root.page.name)
                    line: PrismState.searching ? Translation.tr("Pages and settings that match")
                        : Translation.tr(String(root.page.subtitle ?? ""))
                    actions: PrismState.searching ? [] : root.pageActions
                    // The page's way back to iNiR's stands here alone: the side column says only what this visit changed.
                    restorable: !PrismState.searching && PrismModel.restorableOf(root.pageId) > 0
                    onAction: id => root.act(id)
                    onRestore: PrismModel.restore(root.pageId)
                    onPictureAsked: root.chooseAvatar()
                }
                Item { width: 1; height: PrismTheme.dp(20) }
                Loader {
                    id: heroBox
                    active: root.hero !== null
                    visible: active
                    width: content.width
                    sourceComponent: root.hero
                }
                Item { visible: heroBox.active && shelf.visible; width: 1; height: PrismTheme.dp(14) }
                PrismShelf {
                    id: shelf
                    visible: !PrismState.searching && shelf.groups.length > 0
                    width: content.width
                    page: root.pageId
                    groups: root.sections
                    flashPath: root.flashPath
                }

                // A search: the places it names (a page, a group) first, then the rows that match, each saying where
                // it lives; a press on a place or a row's name goes there.
                Loader {
                    active: PrismState.searching
                    visible: active
                    width: content.width
                    sourceComponent: Column {
                        id: found
                        width: content.width
                        spacing: PrismTheme.dp(14)
                        readonly property var hits: PrismModel.search(PrismState.asked)
                        readonly property var places: PrismModel.places(PrismState.asked)
                        // The rows that fill the screen come in the first frame, the rest a few a frame after it: forty
                        // rows with their controls in one frame cost ~70 ms.
                        property int built: 12
                        readonly property string answering: PrismState.asked
                        onAnsweringChanged: { found.built = 12; grow.restart() }
                        Component.onCompleted: if (found.built < found.hits.length) grow.restart()
                        Timer {
                            id: grow
                            interval: 16
                            repeat: true
                            onTriggered: { found.built += 8; if (found.built >= found.hits.length) grow.stop() }
                        }
                        PrismPlaces {
                            visible: found.places.length > 0
                            width: found.width
                            places: found.places
                            onOpen: place => root.openPlace(place)
                        }
                        PrismText {
                            visible: found.hits.length === 0 && found.places.length === 0
                            width: found.width
                            topPadding: PrismTheme.dp(40)
                            horizontalAlignment: Text.AlignHCenter
                            text: Voice.miss(Translation.tr("No setting matches that."), PrismState.asked)
                            color: PrismTheme.ink2
                            font.pixelSize: PrismTheme.row
                        }
                        Rectangle {
                            visible: found.hits.length > 0
                            width: found.width
                            height: hitRows.implicitHeight + PrismTheme.dp(16)
                            radius: PrismTheme.cardRadius
                            color: PrismTheme.card
                            PrismSection {
                                id: hitRows
                                x: PrismTheme.dp(20)
                                y: PrismTheme.dp(8)
                                width: parent.width - PrismTheme.dp(40)
                                rows: found.hits.slice(0, found.built)
                                showPage: true
                                onReach: row => root.reach(row)
                            }
                        }
                    }
                }
            }
        }

        // A page iRiS draws itself: Prism gives it its head and the room; the view scrolls on its own.
        Item {
            id: hostedBox
            visible: root.hosted
            anchors.left: sidebar.right
            anchors.right: parent.right
            height: parent.height
            PrismPageHead {
                id: hostedHead
                x: Math.round((hostedBox.width - root.measure) / 2)
                y: PrismTheme.dp(24)
                width: root.measure
                eyebrow: Translation.tr(String(root.page.group ?? ""))
                tint: String(root.page.tint ?? "grey")
                turn: PrismModel.index(root.pageId)
                title: Translation.tr(root.page.name)
                line: Translation.tr(String(root.page.subtitle ?? ""))
            }
            Loader {
                anchors.top: hostedHead.bottom
                anchors.topMargin: PrismTheme.dp(12)
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                active: root.hosted
                source: root.hosted ? root.page.view : ""
                // Prism's marks are ink alone (only the chosen wears colour): the page's own tinted marks give way.
                onLoaded: {
                    if (item && item.markDelegate !== undefined) item.markDelegate = hostedMark
                    if (item && item.plainMarks !== undefined) item.plainMarks = true
                    if (item && item.measure !== undefined) item.measure = Qt.binding(() => root.measure)
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

        // Rows leaving the top fade into the page, and so does the foot while rows wait past it.
        // Over glass a band drawn again would darken the glass: rows end at the column's edge, as any glass window's.
        IrisScrollEdge {
            id: centreEdge
            visible: centre.visible && !PrismTheme.glass
            flick: centre
            anchors.fill: centre
            reach: PrismTheme.dp(36)
            veil: PrismTheme.canvas
            // The veil alone: a blurred band read the page into a texture on every scrolled frame (11-11).
            blurs: false
            topRightRadius: root.asideOpen ? 0 : body.radius
            bottomRightRadius: root.asideOpen ? 0 : body.radius
        }

        // The window's own keys, where every window keeps them: as a window or over the desktop, the whole room, close.
        // With the side column open they head it, plain on its ground, so a scrolled card never runs under them; without
        // it they stand inside the page art's top corner, smoked, so they never hang half off its edge.
        Row {
            id: chrome
            readonly property bool plain: PrismState.searching || root.asideOpen
            anchors.right: parent.right
            anchors.rightMargin: chrome.plain ? PrismTheme.dp(14)
                : Math.round((centre.width - root.measure) / 2) + PrismTheme.dp(14)
            y: chrome.plain ? PrismTheme.dp(14) : PrismTheme.dp(24) + PrismTheme.dp(14)
            z: 5
            spacing: PrismTheme.dp(2)
            PrismRound {
                visible: root.asideFits
                ghost: chrome.plain
                overArt: !chrome.plain
                smoked: !chrome.plain
                glyph: root.asideOpen ? "right_panel_close" : "right_panel_open"
                glyphSize: PrismTheme.dp(17)
                Accessible.role: Accessible.Button
                Accessible.name: root.asideOpen ? Translation.tr("Hide the side column") : Translation.tr("Show the side column")
                onClicked: root.toggleAside()
            }
            PrismRound {
                ghost: chrome.plain
                overArt: !chrome.plain
                smoked: !chrome.plain
                glyph: root.windowed ? "picture_in_picture_center" : "open_in_new"
                glyphSize: PrismTheme.dp(17)
                Accessible.role: Accessible.Button
                Accessible.name: root.windowed ? Translation.tr("Over the desktop") : Translation.tr("As a window")
                onClicked: root.switchHost()
            }
            PrismRound {
                visible: root.windowed
                ghost: chrome.plain
                overArt: !chrome.plain
                smoked: !chrome.plain
                glyph: "remove"
                glyphSize: PrismTheme.dp(17)
                Accessible.role: Accessible.Button
                Accessible.name: Translation.tr("Minimize")
                onClicked: root.minimizeRequested()
            }
            PrismRound {
                ghost: chrome.plain
                overArt: !chrome.plain
                smoked: !chrome.plain
                glyph: root.windowed || !PrismState.wide ? "open_in_full" : "close_fullscreen"
                glyphSize: PrismTheme.dp(16)
                Accessible.role: Accessible.Button
                Accessible.name: Translation.tr("Use the whole screen")
                onClicked: root.windowed ? root.growRequested() : (PrismState.wide = !PrismState.wide)
            }
            PrismRound {
                ghost: chrome.plain
                overArt: !chrome.plain
                smoked: !chrome.plain
                glyph: "close"
                glyphSize: PrismTheme.dp(18)
                Accessible.role: Accessible.Button
                Accessible.name: Translation.tr("Close")
                onClicked: root.closeRequested()
            }
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

    Component { id: homeHero; PrismHomeHero { onReach: row => root.reach(row) } }
    Component { id: wallpaperHero; PrismWallpaperHero {} }
    Component { id: colourHero; PrismColourHero { onPickGroup: title => root.showGroup(title) } }
    Component { id: typeHero; PrismTypeHero { onPickGroup: title => root.showGroup(title) } }
    Component { id: leadHero; PrismLead { page: root.pageId } }
    Component { id: lockHero; PrismLockHero { onAction: id => root.act(id); onPickGroup: title => root.showGroup(title) } }
    // Displays: the screen itself, live, then the page's own switches.
    Component {
        id: displayHero
        Column {
            spacing: PrismTheme.dp(14)
            PrismDisplayHero { width: parent.width }
            PrismLead { width: parent.width; page: root.pageId }
        }
    }
    // Layout, Windows and Glass: the windows themselves, live, then the page's own switches where it has them.
    Component {
        id: deskHero
        Column {
            spacing: PrismTheme.dp(14)
            PrismDeskHero { width: parent.width; page: root.pageId }
            PrismLead { width: parent.width; page: root.pageId; visible: root.lead !== null }
        }
    }
    // Keyboard: the keyboard itself, live; Super, Ctrl, Alt or Shift held shows what each key does.
    Component {
        id: keyboardHero
        Rectangle {
            implicitHeight: map.implicitHeight + 2 * PrismTheme.dp(20)
            radius: PrismTheme.cardRadius
            color: PrismTheme.card
            IrisKeyboardMap {
                id: map
                x: PrismTheme.dp(20)
                y: PrismTheme.dp(20)
                width: parent.width - 2 * PrismTheme.dp(20)
            }
        }
    }
}
