pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.sidebar
import qs.modules.iris.settings

// One area's groups and rows, for a page of the AreaPool: its section never changes. Rows are keyed, so a write never
// rebuilds one under the pointer; a page off screen only marks itself stale and catches up when it shows again.
ColumnLayout {
    id: rows
    required property string section
    property Item host
    property string voice: ""
    // The page shows: config writes reach the rows now; off screen they wait.
    property bool live: true
    // Only these groups (keys), or every group but these: a layout that splits an area (Drawer's columns, Pocket's Home).
    property var only: null
    property var skip: []
    // Home's welcome over the first group; a layout that sets it elsewhere turns it off.
    property bool welcome: true
    // The area's own cards and links (Game mode, the side panels' sections, Home's pages): once per area, so a layout
    // that splits it into columns gives them to one.
    property bool extras: rows.only === null
    property color groupFill: IrisStyle.readingCard
    // Home opens on what is changed every day; General's set-once groups wait behind one line that names them.
    property bool foldHome: true
    // The group the page reads now, for the head that marks it.
    property string reading: ""
    // A row asked to be seen (a search landing): the page scrolls it into view.
    signal reveal(Item row)
    // What a tile opened, to be brought whole into view (the page scrolls only as far as it needs).
    signal bring(Item item)

    readonly property real d: IrisStyle.settingsDensity
    spacing: Math.round(6 * rows.d)

    // ── The area's blocks: its groups, a lone row joining the loose block before it.
    property var blocks: []
    property bool stale: true
    function refresh(): void {
        const groups = []
        // Heads are the area's, not the slice's: a column holding one of Dock's groups still names it.
        const keys = new Set()
        for (const spec of IrisOptions.settings) {
            if (spec.section !== rows.section || !IrisOptions.shown(spec)) continue
            const key = String(spec.group ?? "")
            keys.add(key)
            if ((rows.only && !rows.only.includes(key)) || rows.skip.includes(key)) continue
            let group = groups.find(entry => entry.key === key)
            if (!group) { group = { title: Translation.tr(key), key: key, rows: [] }; groups.push(group) }
            group.rows.push(spec)
        }
        const flat = keys.size > 1 && rows.section !== "system"
        // A group of one row reads as that row; where its label repeats across the area (every widget's "On the
        // desktop") it names nothing, so the row takes its group's name.
        const lone = {}
        for (const group of groups) if (group.rows.length === 1) lone[group.rows[0].label] = (lone[group.rows[0].label] ?? 0) + 1
        for (const group of groups) {
            if (group.rows.length === 1 && lone[group.rows[0].label] > 1 && group.key.length > 0)
                group.rows = [Object.assign({}, group.rows[0], { label: group.key })]
        }
        // Every area reads as Home (his 10-30): its lead group open, every other group a tile that says what it holds
        // and opens under the tiles, one at a time. Home leads with Every day, General's other pages are all tiles;
        // the rest lead with their first group; Style leads with none, its Design a card like every other (his 10-31).
        // Nothing waits behind Fine-tune any more but a group's own ranges.
        // A column of Drawer (foldHome off) or an area of two groups keeps them open, its all-fine-tuning groups folded.
        // An area of peers (the side panels) leads with no group either: its tiles are the switch between them, the first open.
        const peers = rows.peers
        // Style leads with no group: people arrive with one thing in mind, so every tile is in sight at once and the
        // presets are one of them, opening under it (his 11-02 13:47).
        const lead = groups.find(group => group.key === "Every day") ?? (peers || ["general", "appearance"].includes(rows.section) ? null : groups[0])
        const others = groups.filter(group => group !== lead && group.rows.length > 0)
        const tiles = flat && rows.foldHome && others.length >= 2
        const home = tiles && rows.section === "general"
        // Every group an island (his 11-04 22:30, Dynamic Island): compact, it says what it holds now; one at a time
        // grows in place into its rows, the rest flow round it. The daily answer leads open; Home's pins are islands too.
        // Original (v2.33) keeps its list; Drawer's columns (foldHome off) keep their groups open.
        if (tiles && !IrisStyle.settingsOriginal) {
            const out = []
            const deckOf = list => list.map(group => ({ key: group.key, title: group.title, rows: group.rows, at: groups.indexOf(group), pin: false }))
            const everyDay = groups.find(group => group.key === "Every day")
            if (everyDay) {
                const pins = everyDay.rows.filter(spec => spec.kind !== "action").map(spec => ({
                    key: "pin:" + String(spec.modelKey ?? spec.path ?? spec.label ?? ""), title: String(spec.label ?? ""),
                    rows: [spec], spec: spec, at: groups.indexOf(everyDay), pin: true }))
                out.push({ title: everyDay.title, caption: everyDay.title, key: everyDay.key, rows: everyDay.rows, flat: true, deck: pins })
            }
            const rest = groups.filter(group => group !== everyDay && group.rows.length > 0)
            const bands = IrisOptions.groupBands[rows.section] ?? []
            const banded = new Set([].concat(...bands.map(band => band.groups)))
            const sets = bands.length === 0 ? [{ title: home ? "General" : "", glyph: "", groups: rest }]
                : bands.map(band => ({ title: band.title, glyph: band.glyph ?? "", groups: band.groups.length > 0
                    ? rest.filter(group => band.groups.includes(group.key)).sort((a, b) => band.groups.indexOf(a.key) - band.groups.indexOf(b.key))
                    : rest.filter(group => !banded.has(group.key)) })).filter(set => set.groups.length > 0)
            for (const set of sets)
                out.push({ title: "​island" + set.title, caption: set.title.length > 0 ? Translation.tr(set.title) : "", glyph: set.glyph,
                    key: "", rows: [], flat: true, deck: deckOf(set.groups) })
            // The lead stands open once per visit; peers always hold one open (they are the switch between panels).
            if (!rows.leadOpened) {
                rows.leadOpened = true
                const leadKey = peers ? String(rest[0]?.key ?? "") : lead && lead !== everyDay ? lead.key : ""
                if (rows.openGroup.length === 0 && leadKey.length > 0) rows.openGroup = leadKey
            }
            rows.islands = true
            rows.groupTiles = true
            rows.blocks = out
            rows.stale = false
            return
        }
        rows.islands = false
        const rest = tiles ? others : groups.filter(group => group.rows.length > 0 && group.rows.every(spec => IrisOptions.foldsAway(spec)))
        const resting = rest.length > 0 && (tiles || rest.length < groups.length)
        const shown = resting ? groups.filter(group => !rest.includes(group)) : groups
        const out = []
        if (!flat) {
            for (const group of shown) out.push({ title: group.title, caption: "", key: group.key, rows: group.rows, flat: false })
        } else {
            let previous = null
            for (const group of shown) {
                const single = group.rows.length === 1 && group.rows[0].kind !== "list"
                if (single && previous?.loose) { previous.rows = previous.rows.concat(group.rows); continue }
                previous = { title: single ? "\u200B" + group.key : group.title, caption: single ? "" : group.title, key: group.key,
                    rows: group.rows.slice(), loose: single, flat: true }
                out.push(previous)
            }
        }
        if (resting) {
            // An area with bands (Style) shows its tiles under the name of what they change, each band opening under itself.
            const bands = tiles ? (IrisOptions.groupBands[rows.section] ?? []) : []
            const banded = new Set([].concat(...bands.map(band => band.groups)))
            const sets = bands.length === 0 ? [{ title: home ? "General" : "", glyph: "", groups: rest }]
                : bands.map(band => ({ title: band.title, glyph: band.glyph ?? "", groups: band.groups.length > 0
                    ? rest.filter(group => band.groups.includes(group.key)).sort((a, b) => band.groups.indexOf(a.key) - band.groups.indexOf(b.key))
                    : rest.filter(group => !banded.has(group.key)) })).filter(set => set.groups.length > 0)
            for (const set of sets) {
                out.push({ title: "\u200bmore" + set.title, caption: set.title.length > 0 ? Translation.tr(set.title) : "", glyph: set.glyph, key: "", rows: [], flat: true, more: true, names: set.groups.map(group => group.title),
                    groups: tiles ? set.groups.map(group => ({ key: group.key, title: group.title, rows: group.rows })) : [] })
                // A group opens under its tile, which already names it.
                for (const group of set.groups) out.push({ title: group.title, caption: tiles ? "" : group.title, key: group.key, rows: group.rows, flat: true, rest: true })
            }
        }
        if (peers && tiles && resting && !rows.peerOpened) {
            rows.peerOpened = true
            rows.openGroup = rest[0].key
        }
        rows.groupTiles = tiles && resting
        rows.blocks = out
        rows.stale = false
    }
    Timer { id: soon; interval: 0; onTriggered: rows.refresh() }
    function touch(): void { if (rows.live) soon.restart(); else rows.stale = true }
    Connections { target: Config; function onRevisionChanged(): void { rows.touch() } }
    Connections { target: IrisNiri; function onRevisionChanged(): void { rows.touch() } }
    onLiveChanged: if (rows.live && rows.stale) rows.refresh()
    Component.onCompleted: rows.refresh()

    // Fine-tune folds opened by hand, by group; "more" is the area's own, over its all-fine-tuning groups.
    property var unfolded: ({})
    readonly property bool moreOpen: (rows.host?.tuneAll ?? false) || (rows.unfolded["more"] ?? false)
    // Groups as tiles (every area but Drawer's columns); one opens under them at a time.
    property bool groupTiles: false
    property string openGroup: ""
    readonly property bool peers: IrisOptions.sectionById(rows.section)?.tilesOnly === true
    property bool peerOpened: false
    // The page's groups are islands (refresh); the lead opens once per visit.
    property bool islands: false
    property bool leadOpened: false
    // An island opened by hand is brought whole into view once it has grown (a lead opened on arrival is not).
    property bool islandsBring: false
    readonly property var islandList: [].concat(...rows.blocks.map(block => block.deck ?? []))
    function islandNamed(wanted: string): var {
        const lower = wanted.toLowerCase()
        return rows.islandList.find(entry => !entry.pin && (entry.key === wanted || entry.key.toLowerCase() === lower
            || Translation.tr(entry.key).toLowerCase() === lower)) ?? null
    }
    function opensRest(key: string): bool {
        return rows.groupTiles ? (rows.host?.tuneAll ?? false) || rows.openGroup === key : rows.moreOpen
    }
    // A link or a search asks for a resting group: its tile opens it, or the area's Fine-tune does. False when the
    // area holds no such group.
    function openRest(wanted: string): bool {
        if (rows.islands) {
            const island = rows.islandNamed(wanted)
            if (!island) return false
            rows.openGroup = island.key
            return true
        }
        const lower = wanted.toLowerCase()
        const block = rows.blocks.find(entry => entry.rest && (entry.key === wanted || entry.key.toLowerCase() === lower
            || Translation.tr(entry.key).toLowerCase() === lower))
        if (!block) return false
        if (rows.groupTiles) rows.openGroup = block.key
        else if (!rows.moreOpen) rows.fold("more")
        return true
    }
    // A search landing on a row there opens it first.
    readonly property bool landsInMore: {
        const landing = String(rows.host?.landingPath ?? "")
        if (landing.length === 0) return false
        if (rows.islands) return rows.islandList.some(entry => !entry.pin && entry.rows.some(spec => String(spec.path ?? "") === landing))
        return rows.blocks.some(block => block.rest && block.rows.some(spec => String(spec.path ?? "") === landing))
    }
    onLandsInMoreChanged: {
        if (!rows.landsInMore) return
        const landing = String(rows.host?.landingPath ?? "")
        if (rows.islands)
            rows.openGroup = String(rows.islandList.find(entry => !entry.pin && entry.rows.some(spec => String(spec.path ?? "") === landing))?.key ?? "")
        else if (rows.groupTiles)
            rows.openGroup = String(rows.blocks.find(block => block.rest && block.rows.some(spec => String(spec.path ?? "") === landing))?.key ?? "")
        else if (!rows.moreOpen)
            rows.fold("more")
    }
    function fold(key: string): void {
        const next = Object.assign({}, rows.unfolded)
        next[key] = !(next[key] ?? false)
        rows.unfolded = next
    }
    // A pending reveal waits a beat, so the row has its height before the page scrolls to it.
    property Item revealing: null
    Timer { id: revealSoon; interval: 120; onTriggered: if (rows.revealing) rows.reveal(rows.revealing) }
    // A tile's options come into view the frame after they are laid out (his 10-30: he had to scroll for them).
    property Item opening: null
    function showOpened(item: Item): void {
        // Peers' tiles are the switch between them: they stay in view.
        if (rows.peers) return
        rows.opening = item
        bringSoon.restart()
    }
    Timer { id: bringSoon; interval: 60; onTriggered: if (rows.opening) rows.bring(rows.opening) }

    // What the page shows, in order, by group key: the page's wheel and its stage read these.
    function targets(): var {
        const out = []
        for (let i = 0; i < blockRepeater.count; i++) {
            const block = blockRepeater.itemAt(i)?.item
            if (!block || !block.visible) continue
            // A deck answers for each of its islands, so a jump lands on (and opens) the group asked for.
            if (block.decked) { for (const island of block.islandItems()) out.push({ key: island.key, item: island }) }
            else out.push({ key: String(block.modelData.key ?? ""), item: block })
        }
        return out
    }

    // The first group comes with the page; the rest build in the frames after it, as Classic's blocks do: a turn
    // waited on the whole area before (up to 0.9 s for widgets in a nest).
    readonly property bool streams: String(rows.host?.landingPath ?? "").length === 0
    // Every block built: the pool turns to the page only then, so it arrives whole instead of filling in on screen.
    // Weighed a beat later, never inside a binding: a block that finishes as the page turns visible fed the binding back.
    property bool whole: false
    function weigh(): void {
        // One more block while what is built stays within reach. Heights are guessed from the rows: a block is laid out
        // only in the frame after it is built (read 0 there). Inline: a queued weigh can land on a page being destroyed.
        if (!rows.streams || rows.reach === Infinity) {
            rows.builtUpTo = Math.max(rows.builtUpTo, rows.blocks.length)
        } else {
            let below = 0
            for (let i = 0; i < Math.min(rows.builtUpTo, rows.blocks.length); i++)
                if (blockRepeater.itemAt(i)?.wanted !== false) below += (48 + 56 * (rows.blocks[i].rows?.length ?? 0)) * rows.d
            // A block nobody asked for (Home's closed groups) builds nothing and weighs nothing: the build steps over it
            // in the same call. Waiting on it for a status that never comes left every block after it unbuilt (Shell
            // family opened on nothing, his 10-30).
            while (rows.builtUpTo < rows.blocks.length && below <= rows.reach) {
                const last = blockRepeater.itemAt(Math.min(rows.builtUpTo, blockRepeater.count) - 1)
                if (!(last?.status === Loader.Ready || last?.status === Loader.Error || last?.wanted === false)) break
                const next = blockRepeater.itemAt(rows.builtUpTo)
                rows.builtUpTo++
                if (next?.wanted !== false) break
            }
        }
        const upTo = Math.min(rows.builtUpTo, blockRepeater.count)
        let built = blockRepeater.count >= rows.blocks.length
        for (let i = 0; built && i < upTo; i++) built = blockRepeater.itemAt(i)?.status === Loader.Ready || blockRepeater.itemAt(i)?.wanted === false
        rows.whole = built
    }
    onBlocksChanged: Qt.callLater(rows.weigh)
    // How far down (in rows' own y) the page builds: a block past it waits until the page scrolls near, one at a time.
    // Folio sets it (a jump built every row of the area, ~1.5x Classic's folded groups); the rest build them all.
    property real reach: Infinity
    property int builtUpTo: 1
    onReachChanged: Qt.callLater(rows.weigh)
    // Home opens on the welcome, as Classic's does.
    Loader {
        active: rows.section === "general" && rows.welcome
        visible: active
        Layout.fillWidth: true
        Layout.leftMargin: Math.round(8 * rows.d)
        Layout.rightMargin: Math.round(8 * rows.d)
        Layout.bottomMargin: Math.round(6 * rows.d)
        sourceComponent: IrisWallpaperCard { screen: rows.QsWindow.window?.screen ?? GlobalStates.focusedScreen }
    }
    // Game mode's state and its switch lead the area that holds what it does.
    Loader {
        active: rows.section === "gaming" && rows.extras
        visible: active
        Layout.fillWidth: true
        Layout.bottomMargin: Math.round(6 * rows.d)
        sourceComponent: IrisGameModeCard {}
    }
    Repeater {
        id: blockRepeater
        onCountChanged: Qt.callLater(rows.weigh)
        model: ScriptModel { objectProp: "title"; values: rows.blocks }
        Loader {
            id: slot
            required property var modelData
            required property int index
            Layout.fillWidth: true
            readonly property bool wanted: !slot.modelData.rest || rows.opensRest(String(slot.modelData.key ?? ""))
            active: slot.index < rows.builtUpTo && slot.wanted
            visible: slot.active
            onWantedChanged: Qt.callLater(rows.weigh)
            asynchronous: slot.index > 0 && rows.streams
            onStatusChanged: if (rows) Qt.callLater(rows.weigh)
            onLoaded: if (slot.modelData.rest && rows.groupTiles && rows.openGroup === String(slot.modelData.key ?? "")) rows.showOpened(slot)
            sourceComponent: ColumnLayout {
                id: block
                readonly property var modelData: slot.modelData
                readonly property int index: slot.index
                spacing: Math.round(6 * rows?.d)

                readonly property string key: String(block.modelData.key ?? "")
                readonly property string caption: String(block.modelData.caption ?? "")
                // A deck of islands (refresh's island path): its head names the band, the islands hold the groups.
                readonly property bool decked: Array.isArray(block.modelData.deck)
                function islandItems(): var {
                    const out = []
                    for (let i = 0; i < islandRepeater.count; i++) { const island = islandRepeater.itemAt(i); if (island && !island.pin) out.push(island) }
                    return out
                }
                readonly property string tuneKey: rows?.section + "/" + block.key
                readonly property var tuned: block.modelData.rows?.filter(spec => IrisOptions.foldsAway(spec))
                // Under the area's Fine-tune a group is already the fine-tuning: its rows stand open.
                readonly property bool tunes: !block.modelData.rest && block.tuned.length >= 2
                readonly property bool tuneOpen: block.tunes && ((rows?.host?.tuneAll ?? false) || (rows?.unfolded[block.tuneKey] ?? false))
                readonly property var shownRows: block.tunes && !block.tuneOpen ? block.modelData.rows?.filter(spec => !block.tuned.includes(spec)) : block.modelData.rows
                readonly property string landing: String(rows?.host?.landingPath ?? "")
                readonly property bool landsInFold: block.landing.length > 0 && block.tuned.some(spec => String(spec.path ?? "") === block.landing)
                onLandsInFoldChanged: if (block.landsInFold && !block.tuneOpen) rows?.fold(block.tuneKey)
                // A group that is only a switch is its head: the name and its switch, no card.
                readonly property bool loneSwitch: {
                    Config.revision
                    return block.modelData.flat && block.caption.length > 0 && !block.tunes
                        && block.shownRows.length === 1 && block.shownRows[0].kind === "switch"
                }
                // A group that opens with its own bare on/off ("Spotlight" under Spotlight, "Enable panel" under Focus)
                // wears it on the head's line: the name once, the rest under it. One with a sentence keeps its row, where
                // the sentence says what it does in the label's place (Orbit, Airing, Do Not Disturb).
                readonly property bool namedSwitch: {
                    const first = block.shownRows?.[0]
                    if (!block.modelData.flat || block.caption.length === 0 || block.tiled || block.loneSwitch
                            || !first || first.kind !== "switch" || block.shownRows.length < 2 || String(first.description ?? "").length > 0)
                        return false
                    const label = String(first.label ?? "")
                    return Translation.tr(label).toLowerCase() === block.caption.toLowerCase() || /^Enable\b/.test(label)
                }
                readonly property var bodyRows: block.namedSwitch ? block.shownRows.slice(1) : block.shownRows
                // Home's pins are tiles: a glance reads each one's state in words, a switch flips on the tile, any other
                // value opens its own row under them. A wall of full rows (scheme, accent cards, look, glass) was no home.
                readonly property bool tiled: rows?.section === "general" && block.key === "Every day"
                function partOf(spec: var): string { return String(spec.part ?? "") }
                readonly property var parts: block.bodyRows.length === 0 ? [""] : [...new Set(block.bodyRows.map(spec => block.partOf(spec)))]

                // The head, in the layout's voice (IrisSkin groupHeader), holding a lone switch on its line.
                Item {
                    id: head
                    readonly property string title: block.caption
                    readonly property bool lone: block.loneSwitch || block.namedSwitch
                    readonly property real switchHeight: headSwitch.implicitHeight
                    readonly property bool reading: rows?.reading === block.key
                    readonly property string glyph: String(block.modelData.glyph ?? "") || (IrisOptions.groupGlyphs[block.key] ?? IrisOptions.sectionById(rows?.section)?.icon ?? "settings")
                    readonly property color tint: IrisOptions.groupHue(String(rows?.section ?? ""), block.index, block.key)
                    visible: block.modelData.flat && head.title.length > 0
                    Layout.fillWidth: true
                    Layout.leftMargin: Math.round(16 * rows?.d)
                    Layout.rightMargin: Math.round(16 * rows?.d)
                    Layout.topMargin: Math.round((block.index > 0 ? 22 : 6) * rows?.d)
                    Layout.bottomMargin: Math.round(2 * rows?.d)
                    implicitHeight: headSkin.active ? (headSkin.item?.implicitHeight ?? 0) : plainHead.implicitHeight
                    IrisSkin { id: headSkin; part: "groupHeader"; host: head; voice: rows?.voice }
                    IrisGroupTitle {
                        id: plainHead
                        visible: !headSkin.active
                        maxWidth: parent.width - (head.lone ? headSwitch.width + Math.round(12 * rows?.d) : headAction.visible ? headAction.width + Math.round(12 * rows?.d) : 0)
                        text: head.title
                        glyph: head.glyph
                        tint: head.tint
                    }
                    // Home's Customize sits on the head's line, quiet, beside the pins it edits.
                    IrisChip {
                        id: headAction
                        readonly property var spec: block.tiled ? (block.shownRows.find(spec => spec.kind === "action") ?? null) : null
                        visible: headAction.spec !== null
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: "edit"
                        label: Translation.tr(String(headAction.spec?.button ?? "Edit"))
                        Accessible.name: Translation.tr(String(headAction.spec?.label ?? ""))
                        onClicked: headAction.spec?.run()
                    }
                    IrisSwitch {
                        id: headSwitch
                        visible: head.lone
                        anchors.right: parent.right
                        anchors.top: parent.top
                        on: head.lone && (block.shownRows[0].invert ? !Boolean(IrisOptions.currentValue(block.shownRows[0])) : Boolean(IrisOptions.currentValue(block.shownRows[0])))
                        name: head.title
                        onToggled: IrisOptions.commit(block.shownRows[0], block.shownRows[0].invert ? on : !on)
                    }
                }

                // The area's other groups, each saying what it holds now; one opens under them. Current draws them as
                // tiles; Original (v2.33) as one grouped list on a single plate, the same Repeater with a second face.
                Item {
                    id: groupDeck
                    visible: (block.modelData.groups ?? []).length > 0
                    Layout.fillWidth: true
                    Layout.topMargin: block.caption.length > 0 ? 0 : Math.round(14 * rows?.d)
                    implicitHeight: groupGrid.implicitHeight
                    IrisPlate {
                        anchors.fill: parent
                        visible: groupGrid.groupList
                        radius: IrisStyle.radiusTile
                        color: rows?.groupFill ?? "transparent"
                    }
                    // The list's hover plate glides to the row under the pointer instead of blinking on each.
                    Rectangle {
                        id: listHover
                        readonly property real inset: Math.round(3 * (rows?.d ?? 1))
                        visible: groupGrid.groupList
                        x: listHover.inset
                        y: (groupGrid.hovered?.y ?? 0) + listHover.inset
                        width: parent.width - 2 * listHover.inset
                        height: groupGrid.listRow - 2 * listHover.inset
                        radius: IrisStyle.concentric(IrisStyle.radiusTile, listHover.inset, IrisStyle.radiusRow)
                        color: groupGrid.hovered?.pressed ? IrisStyle.fillActive : IrisStyle.fillQuiet
                        opacity: groupGrid.hovered !== null ? 1 : 0
                        Behavior on y { enabled: listHover.opacity > 0; SmoothedAnimation { duration: IrisStyle.duration(140); velocity: -1 } }
                        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
                    }
                    GridLayout {
                        id: groupGrid
                        width: parent.width
                        readonly property real gap: Math.round(8 * rows?.d)
                        readonly property bool groupList: IrisStyle.settingsOriginal
                        readonly property int groupCount: (block.modelData.groups ?? []).length
                        readonly property real listRow: Math.round(46 * rows?.d * Math.max(1, IrisStyle.typeScale))
                        // The row under the pointer (Original), for the gliding hover plate.
                        property var hovered: null
                        columns: groupGrid.groupList ? 1 : Math.max(2, Math.floor((width + gap) / (Math.round(232 * rows?.d) * Math.max(1, IrisStyle.typeScale) + gap)))
                        columnSpacing: groupGrid.groupList ? 0 : gap
                        rowSpacing: groupGrid.groupList ? 0 : gap
                        Repeater {
                            model: ScriptModel { objectProp: "key"; values: block.modelData.groups ?? [] }
                            Item {
                                id: group
                                required property var modelData
                                required property int index
                                readonly property string key: String(group.modelData.key ?? "")
                                readonly property bool open: rows?.openGroup === group.key
                                readonly property color tint: IrisOptions.groupHue(String(rows?.section ?? ""), group.index, group.key)
                                readonly property bool listed: groupGrid.groupList
                                readonly property bool pressed: groupArea.pressed
                                readonly property bool modified: {
                                    Config.revision
                                    return group.listed && (group.modelData.rows ?? []).some(spec => IrisOptions.modified(spec))
                                }
                                // What it holds now, in words: its first rows' values, a switch by its name while on ("24-hour", "Low power").
                                readonly property string glance: {
                                    Config.revision
                                    const said = []
                                    for (const spec of group.modelData.rows ?? []) {
                                        if (said.length >= 2) break
                                        const value = IrisOptions.currentValue(spec)
                                        const choice = (spec.choices ?? []).find(entry => String(entry.value) === String(value))
                                        const word = spec.glance ? spec.glance(value)
                                            : spec.kind === "switch" ? ((spec.invert ? !value : Boolean(value)) ? Translation.tr(String(spec.label ?? "")) : "")
                                            : choice ? Translation.tr(String(choice.label ?? ""))
                                            : spec.kind === "range" ? IrisOptions.rangeText(spec, value)
                                            : spec.kind === "text" && String(value ?? "").length > 0 && String(value).length <= 24 ? String(value) : ""
                                        if (word.length > 0) said.push(word)
                                    }
                                    return said.join(" · ")
                                }
                                function act(): void { rows.openGroup = group.open ? "" : group.key }
                                Layout.fillWidth: true
                                Layout.fillHeight: !group.listed
                                Layout.preferredWidth: 1
                                implicitHeight: group.listed ? groupGrid.listRow
                                    : Math.round(13 * rows?.d) + Math.round(18 * rows?.d) + Math.round(6 * rows?.d) + groupWords.implicitHeight + Math.round(14 * rows?.d)
                                activeFocusOnTab: true
                                Accessible.role: Accessible.Button
                                Accessible.name: Translation.tr(String(group.modelData.title ?? ""))
                                Accessible.description: group.glance
                                Keys.onSpacePressed: group.act()
                                Keys.onReturnPressed: group.act()

                                IrisPlate {
                                    id: groupPlate
                                    visible: !group.listed
                                    anchors.fill: parent
                                    radius: IrisStyle.radiusTile
                                    // Open: a wash of its own colour, as the sidebar marks where you are (his 10-30: an
                                    // outline is no way to say it).
                                    color: group.open ? IrisStyle.tintFillHover(group.tint) : (rows?.groupFill ?? "transparent")
                                    scale: groupArea.pressed ? IrisStyle.pressScale(0.97) : 1
                                    Behavior on color { ColorAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
                                    Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        color: groupArea.pressed ? IrisStyle.fillActive : IrisStyle.fillQuiet
                                        opacity: groupArea.containsMouse || groupArea.pressed || group.activeFocus ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
                                    }
                                    // A widget's Small face (his 11-02: the widgets are the look): the group named small in
                                    // its colour beside its glyph, what it holds now big in the ink under it.
                                    readonly property color voice: IrisStyle.iconColour === "mono" ? IrisStyle.textSecondary : IrisStyle.iconHue(group.tint)
                                    Row {
                                        id: groupHead
                                        x: Math.round(14 * rows?.d)
                                        y: Math.round(13 * rows?.d)
                                        width: parent.width - 2 * x
                                        spacing: Math.round(6 * rows?.d)
                                        IrisSquircle {
                                            plain: IrisStyle.settingsPlainMarks
                                            id: groupMark
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: Math.round(18 * rows?.d)
                                            height: width
                                            tint: group.tint
                                            glyph: IrisOptions.groupGlyphs[group.key] ?? "settings"
                                        }
                                        IrisText {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: groupHead.width - groupMark.width - groupHead.spacing
                                            text: Translation.tr(String(group.modelData.title ?? ""))
                                            color: groupPlate.voice
                                            font.pixelSize: IrisStyle.typeMeta
                                            font.weight: IrisStyle.weight(Font.DemiBold)
                                            elide: Text.ElideRight
                                        }
                                    }
                                    Column {
                                        id: groupWords
                                        x: groupHead.x
                                        anchors.top: groupHead.bottom
                                        anchors.topMargin: Math.round(6 * rows?.d)
                                        width: groupHead.width
                                        spacing: Math.round(1 * rows?.d)
                                        readonly property var said: group.glance.split(" · ")
                                        IrisText {
                                            width: parent.width
                                            text: group.glance.length > 0 ? groupWords.said[0] : Translation.tr("Open")
                                            color: group.glance.length > 0 ? IrisStyle.text : IrisStyle.textTertiary
                                            font.family: IrisStyle.fontTitle
                                            font.pixelSize: IrisStyle.typeHeadline
                                            font.weight: IrisStyle.weight(Font.Bold)
                                            elide: Text.ElideRight
                                        }
                                        IrisText {
                                            width: parent.width
                                            visible: groupWords.said.length > 1 && groupWords.width >= Math.round(150 * rows?.d)
                                            text: groupWords.said.slice(1).join(" · ")
                                            color: IrisStyle.textTertiary
                                            font.pixelSize: IrisStyle.typeFootnote
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                                // Original's face: a v2.33 list row. Plated mark, the name, what it holds at the right in muted ink,
                                // a changed dot, a chevron that turns down while its rows stand open under the list.
                                Item {
                                    id: listFace
                                    visible: group.listed
                                    anchors.fill: parent
                                    readonly property real d: rows?.d ?? 1
                                    Rectangle {
                                        visible: group.open
                                        anchors.fill: parent
                                        anchors.margins: listHover.inset
                                        radius: listHover.radius
                                        color: IrisStyle.tintFillHover(group.tint)
                                    }
                                    IrisSquircle {
                                        id: listMark
                                        plain: IrisStyle.settingsPlainMarks
                                        anchors.left: parent.left
                                        anchors.leftMargin: Math.round(14 * listFace.d)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.round(26 * listFace.d)
                                        height: width
                                        tint: group.tint
                                        glyph: IrisOptions.groupGlyphs[group.key] ?? "settings"
                                    }
                                    IrisText {
                                        id: listTitle
                                        anchors.left: listMark.right
                                        anchors.leftMargin: Math.round(12 * listFace.d)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.ceil(Math.min(implicitWidth, parent.width * 0.42))
                                        text: Translation.tr(String(group.modelData.title ?? ""))
                                        font.pixelSize: IrisStyle.typeLabel
                                        font.weight: IrisStyle.weight(group.open ? Font.DemiBold : Font.Medium)
                                        elide: Text.ElideRight
                                    }
                                    IrisText {
                                        anchors.left: listTitle.right
                                        anchors.leftMargin: Math.round(16 * listFace.d)
                                        anchors.right: listDot.left
                                        anchors.rightMargin: Math.round(8 * listFace.d)
                                        anchors.verticalCenter: parent.verticalCenter
                                        horizontalAlignment: Text.AlignRight
                                        text: group.glance
                                        color: IrisStyle.muted
                                        font.pixelSize: IrisStyle.typeLabel
                                        elide: Text.ElideRight
                                    }
                                    Rectangle {
                                        id: listDot
                                        anchors.right: listChevron.left
                                        anchors.rightMargin: group.modified ? Math.round(8 * listFace.d) : 0
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: group.modified ? Math.round(6 * listFace.d) : 0
                                        height: width
                                        radius: width / 2
                                        color: IrisStyle.accent
                                    }
                                    MaterialSymbol {
                                        id: listChevron
                                        anchors.right: parent.right
                                        anchors.rightMargin: Math.round(12 * listFace.d)
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "chevron_right"
                                        iconSize: Math.round(18 * listFace.d)
                                        color: IrisStyle.textTertiary
                                        rotation: group.open ? 90 : 0
                                        Behavior on rotation { RotationAnimator { duration: IrisStyle.duration(180); easing.type: IrisStyle.feedbackEasing } }
                                    }
                                    Rectangle {
                                        visible: group.index < groupGrid.groupCount - 1
                                        anchors.left: listTitle.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 1
                                        color: IrisStyle.hairline
                                    }
                                }
                                MouseArea {
                                    id: groupArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: group.act()
                                    onContainsMouseChanged: {
                                        if (groupArea.containsMouse) groupGrid.hovered = group
                                        else if (groupGrid.hovered === group) groupGrid.hovered = null
                                    }
                                }
                                Component.onDestruction: if (groupGrid.hovered === group) groupGrid.hovered = null
                            }
                        }
                    }
                }
                // The area's Fine-tune: the groups it holds, opening under it.
                IrisPlate {
                    visible: Boolean(block.modelData.more) && !groupGrid.visible
                    Layout.fillWidth: true
                    Layout.topMargin: Math.round(18 * rows?.d)
                    implicitHeight: moreTune.implicitHeight
                    radius: IrisStyle.radiusTile
                    color: rows?.groupFill ?? "transparent"
                    FineTune {
                        id: moreTune
                        width: parent.width
                        open: rows?.moreOpen ?? false
                        title: rows?.section === "general" ? Translation.tr("General") : ""
                        names: (block.modelData.names ?? []).map(name => String(name))
                        // Against what shows, so a click under "open all" (tune:open) still closes it.
                        onClicked: {
                            const next = Object.assign({}, rows.unfolded)
                            next["more"] = !rows.moreOpen
                            rows.unfolded = next
                        }
                    }
                }
                // The groups as islands: compact in columns, saying what each holds; the open one spans the page in its
                // place and the others flow round it, the whole deck moving as one (one curve, one duration).
                Item {
                    id: deck
                    visible: block.decked
                    Layout.fillWidth: true
                    Layout.topMargin: block.caption.length > 0 ? Math.round(2 * rows?.d) : 0
                    implicitHeight: deck.plan.height
                    readonly property real gap: Math.round(8 * rows?.d)
                    readonly property real compact: Math.round(50 * rows?.d * Math.max(1, IrisStyle.typeScale))
                    // Open, an island's corners settle where a card's would (a capsule closed: half its height).
                    readonly property real radius: Math.max(IrisStyle.radiusTile, IrisStyle.corner(26))
                    readonly property int columns: Math.max(1, Math.min(3, Math.floor((deck.width + deck.gap) / (Math.round(340 * rows?.d) * Math.max(1, IrisStyle.typeScale) + deck.gap))))
                    // Geometry eases only while an island opens or closes; a resize or a page build lands at once.
                    property bool morphing: false
                    property bool growing: false
                    function morph(growing: bool): void {
                        if (!IrisStyle.motionEnabled) return
                        deck.growing = growing
                        deck.morphing = true
                        morphClock.restart()
                    }
                    Timer { id: morphClock; interval: Math.max(IrisStyle.emergeDuration, IrisStyle.recedeDuration) + 80; onTriggered: deck.morphing = false }
                    Connections {
                        target: block.decked ? rows : null
                        function onOpenGroupChanged(): void { deck.morph(rows.openGroup.length > 0) }
                    }
                    readonly property int duration: deck.growing ? IrisStyle.emergeDuration : IrisStyle.recedeDuration
                    readonly property var curve: deck.growing ? IrisStyle.emergeCurve : IrisStyle.recedeCurve
                    // Lines of compact islands share the width; an open island takes a line of its own where it stands,
                    // and a line it cut short spreads its islands across the page (no hole beside the open one).
                    // The open island's height, written by the island itself (read from the model, never from the
                    // Repeater's items: an incubating block has them late and the plan never saw them).
                    property real openWanted: deck.compact
                    readonly property var plan: {
                        const entries = block.decked ? block.modelData.deck : []
                        const openKey = String(rows?.openGroup ?? "")
                        const boxes = []
                        let line = []
                        let y = 0
                        const flush = () => {
                            if (line.length === 0) return
                            const w = (deck.width - deck.gap * (line.length - 1)) / line.length
                            line.forEach((at, k) => { boxes[at] = { x: Math.round(k * (w + deck.gap)), y: y, w: Math.round(w), h: deck.compact } })
                            y += deck.compact + deck.gap
                            line = []
                        }
                        for (let i = 0; i < entries.length; i++) {
                            if (String(entries[i].key) === openKey) {
                                flush()
                                boxes[i] = { x: 0, y: y, w: deck.width, h: deck.openWanted }
                                y += deck.openWanted + deck.gap
                            } else {
                                line.push(i)
                                if (line.length >= deck.columns) flush()
                            }
                        }
                        flush()
                        return { boxes: boxes, height: Math.max(0, y - deck.gap) }
                    }
                    Repeater {
                        id: islandRepeater
                        model: ScriptModel { objectProp: "key"; values: block.decked ? block.modelData.deck : [] }
                        Island {
                            deckItem: deck
                            owner: rows
                        }
                    }
                }
                GridLayout {
                    id: tileGrid
                    visible: block.tiled && !block.decked
                    Layout.fillWidth: true
                    readonly property real gap: Math.round(8 * rows?.d)
                    columns: Math.max(2, Math.floor((width + gap) / (Math.round(208 * rows?.d) * Math.max(1, IrisStyle.typeScale) + gap)))
                    columnSpacing: gap
                    rowSpacing: gap
                    property string opened: ""
                    onOpenedChanged: if (tileGrid.opened.length > 0) rows.showOpened(openedTile)
                    readonly property var openedSpec: block.shownRows.find(spec => String(spec.modelKey ?? spec.path ?? "") === tileGrid.opened) ?? null
                    Repeater {
                        model: ScriptModel { objectProp: "modelKey"; values: block.tiled && !block.decked ? block.shownRows.filter(spec => spec.kind !== "action") : [] }
                        Item {
                            id: tile
                            required property var modelData
                            readonly property var spec: tile.modelData
                            readonly property string key: String(tile.spec.modelKey ?? tile.spec.path ?? "")
                            readonly property bool toggles: tile.spec.kind === "switch"
                            readonly property var area: IrisOptions.sectionById(String(tile.spec.origin?.section ?? ""))
                            readonly property var value: { Config.revision; return IrisOptions.currentValue(tile.spec) }
                            readonly property bool on: tile.toggles && (tile.spec.invert ? !Boolean(tile.value) : Boolean(tile.value))
                            readonly property var choice: (tile.spec.choices ?? []).find(entry => String(entry.value) === String(tile.value)) ?? null
                            readonly property bool open: tileGrid.opened === tile.key
                            readonly property string words: tile.toggles ? (tile.on ? Translation.tr("On") : Translation.tr("Off"))
                                : tile.choice ? Translation.tr(String(tile.choice.label ?? ""))
                                : tile.spec.kind === "range" ? IrisOptions.rangeText(tile.spec, tile.value)
                                : String(tile.value ?? "")
                            readonly property string glyph: String(tile.choice?.glyph ?? tile.spec.glyph ?? IrisOptions.groupGlyphs[String(tile.spec.origin?.group ?? "")] ?? tile.area?.icon ?? "settings")
                            readonly property bool accentTile: String(tile.spec.path ?? "") === "iris.appearance.accent"
                            function act(): void {
                                if (tile.toggles) IrisOptions.commit(tile.spec, tile.spec.invert ? tile.on : !tile.on)
                                else tileGrid.opened = tile.open ? "" : tile.key
                            }
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: Math.round(13 * rows?.d) + Math.round(18 * rows?.d) + Math.round(6 * rows?.d) + tileWords.implicitHeight + Math.round(14 * rows?.d)
                            activeFocusOnTab: true
                            Accessible.role: tile.toggles ? Accessible.CheckBox : Accessible.Button
                            Accessible.name: Translation.tr(String(tile.spec.label ?? ""))
                            Accessible.description: tile.words
                            Accessible.checkable: tile.toggles
                            Accessible.checked: tile.on
                            Keys.onSpacePressed: tile.act()
                            Keys.onReturnPressed: tile.act()

                            IrisPlate {
                                id: tilePlate
                                anchors.fill: parent
                                radius: IrisStyle.radiusTile
                                color: tile.on ? IrisStyle.lookPlate
                                    : tile.open ? IrisStyle.tintFillHover(tile.accentTile ? IrisStyle.accent : (tile.area?.tint ?? IrisStyle.identity.gray))
                                    : (rows?.groupFill ?? "transparent")
                                lit: tile.on || tile.open
                                border.width: IrisStyle.plateEdge.a > 0 ? 1 : 0
                                border.color: IrisStyle.plateEdge
                                scale: tileArea.pressed ? IrisStyle.pressScale(0.97) : 1
                                Behavior on color { ColorAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
                                Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: tileArea.pressed ? IrisStyle.fillActive : IrisStyle.fillQuiet
                                    opacity: tileArea.containsMouse || tileArea.pressed || tile.activeFocus ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
                                }
                                // Home's pins wear a Small widget's face as the group tiles do: the name small in its
                                // colour beside its glyph, the state big in the ink; a switch's plate lights when on.
                                readonly property color voice: tile.on ? IrisStyle.inkOnLookPlate
                                    : IrisStyle.iconColour === "mono" ? IrisStyle.textSecondary
                                    : IrisStyle.iconHue(tile.accentTile ? IrisStyle.accent : (tile.area?.tint ?? IrisStyle.identity.gray))
                                Row {
                                    id: tileHead
                                    x: Math.round(14 * rows?.d)
                                    y: Math.round(13 * rows?.d)
                                    width: parent.width - 2 * x - (tileChevron.visible ? tileChevron.width : 0)
                                    spacing: Math.round(6 * rows?.d)
                                    IrisSquircle {
                                        plain: IrisStyle.settingsPlainMarks
                                        id: tileMark
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.round(18 * rows?.d)
                                        height: width
                                        tint: tile.on ? IrisStyle.inkOnLookPlate : tile.accentTile ? IrisStyle.accent : (tile.area?.tint ?? IrisStyle.identity.gray)
                                        glyph: tile.accentTile ? "palette" : tile.glyph
                                    }
                                    IrisText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: tileHead.width - tileMark.width - tileHead.spacing
                                        text: Translation.tr(String(tile.spec.label ?? ""))
                                        color: tilePlate.voice
                                        font.pixelSize: IrisStyle.typeMeta
                                        font.weight: IrisStyle.weight(Font.DemiBold)
                                        elide: Text.ElideRight
                                    }
                                }
                                IrisText {
                                    id: tileWords
                                    x: tileHead.x
                                    anchors.top: tileHead.bottom
                                    anchors.topMargin: Math.round(6 * rows?.d)
                                    width: parent.width - 2 * x
                                    text: tile.words.length > 0 ? tile.words : Translation.tr("Open")
                                    color: tile.on ? IrisStyle.inkOnLookPlate : tile.words.length > 0 ? IrisStyle.text : IrisStyle.textTertiary
                                    font.family: IrisStyle.fontTitle
                                    font.pixelSize: IrisStyle.typeHeadline
                                    font.weight: IrisStyle.weight(Font.Bold)
                                    elide: Text.ElideRight
                                }
                                MaterialSymbol {
                                    id: tileChevron
                                    visible: !tile.toggles
                                    anchors.right: parent.right
                                    anchors.rightMargin: Math.round(10 * rows?.d)
                                    y: Math.round(11 * rows?.d)
                                    text: "expand_more"
                                    iconSize: Math.round(18 * rows?.d)
                                    color: tile.open || tileArea.containsMouse ? IrisStyle.text : IrisStyle.textTertiary
                                    rotation: tile.open ? 180 : 0
                                    Behavior on rotation { NumberAnimation { duration: IrisStyle.duration(180); easing.type: Easing.OutCubic } }
                                }
                            }
                            MouseArea {
                                id: tileArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: tile.act()
                            }
                        }
                    }
                }
                // The value a tile opened, as its own row, under the tiles.
                Loader {
                    id: openedTile
                    active: block.tiled && !block.decked && tileGrid.openedSpec !== null
                    visible: active
                    Layout.fillWidth: true
                    sourceComponent: IrisPlate {
                        implicitHeight: openRow.implicitHeight
                        radius: IrisStyle.radiusTile
                        color: rows?.groupFill ?? "transparent"
                        IrisSetting {
                            id: openRow
                            width: parent.width
                            spec: tileGrid.openedSpec
                            voice: rows?.voice ?? ""
                            last: true
                        }
                    }
                }
                Repeater {
                    model: ScriptModel { values: block.loneSwitch || block.modelData.more || block.tiled || block.decked ? [] : block.parts }
                    ColumnLayout {
                        id: part
                        required property string modelData
                        required property int index
                        readonly property var specs: block.bodyRows.filter(spec => block.partOf(spec) === part.modelData)
                        readonly property bool lastPart: part.index === block.parts.length - 1
                        Layout.fillWidth: true
                        Layout.topMargin: part.index > 0 ? Math.round(12 * rows?.d) : 0
                        spacing: Math.round(6 * rows?.d)
                        IrisText {
                            visible: text.length > 0
                            Layout.leftMargin: Math.round(16 * rows?.d)
                            text: part.modelData.length > 0 ? Translation.tr(part.modelData) : ""
                            color: IrisStyle.subtext
                            font.pixelSize: IrisStyle.typeMeta
                            font.weight: IrisStyle.weight(Font.DemiBold)
                        }
                        IrisPlate {
                            Layout.fillWidth: true
                            implicitHeight: partRows.implicitHeight
                            radius: IrisStyle.radiusTile
                            color: (rows?.groupFill ?? "transparent")
                            ColumnLayout {
                                id: partRows
                                anchors.left: parent.left
                                anchors.right: parent.right
                                spacing: 0
                                Repeater {
                                    model: ScriptModel { objectProp: "modelKey"; values: part.specs }
                                    IrisSetting {
                                        id: row
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        spec: row.modelData
                                        voice: rows?.voice ?? ""
                                        heading: head.visible && part.index === 0 && row.index === 0 ? head.title : ""
                                        last: row.index === part.specs.length - 1 && !(part.lastPart && block.tunes)
                                        landing: block.landing.length > 0 && String(row.modelData.path ?? "") === block.landing
                                        onLandingChanged: if (row.landing) { rows.revealing = row; revealSoon.restart() }
                                        Component.onCompleted: if (row.landing) { rows.revealing = row; revealSoon.restart() }
                                    }
                                }
                                FineTune {
                                    visible: part.lastPart && block.tunes
                                    Layout.fillWidth: true
                                    open: block.tuneOpen
                                    names: block.tuned.map(spec => Translation.tr(String(spec.label ?? "")))
                                    onClicked: rows?.fold(block.tuneKey)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    // After the groups, once they all stand: what the area opens or edits beyond its values.
    ColumnLayout {
        visible: rows.extras && rows.builtUpTo >= rows.blocks.length && extraLinks.links.length > 0
        Layout.fillWidth: true
        Layout.topMargin: Math.round(18 * rows.d)
        spacing: Math.round(18 * rows.d)
        IrisLinkCard {
            id: extraLinks
            readonly property var host: rows.host
            Layout.fillWidth: true
            visible: extraLinks.links.length > 0
            tinted: rows.section === "general"
            links: {
                if (!rows.extras) return []
                if (rows.section === "desktop") return [
                    { label: Translation.tr("Edit desktop widgets"), icon: "edit", tint: IrisStyle.identity.yellow, action: () => { GlobalStates.settingsOverlayOpen = false; GlobalStates.setWidgetEditMode(true) } }
                ]
                if (rows.section === "general" && extraLinks.host) return [
                    { key: "about", label: Translation.tr("About iNiR"), icon: "info", tint: IrisStyle.identity.lavender },
                    { key: "shortcuts", label: Translation.tr("Keyboard shortcuts"), icon: "keyboard", tint: IrisStyle.identity.indigo }
                ].filter(link => extraLinks.host.pages.some(page => page.key === link.key)).map(link => ({
                    label: link.label, icon: link.icon, tint: link.tint,
                    action: () => extraLinks.host.go({ section: "general", group: "", advancedPage: extraLinks.host.pageIndexOf(link.key) })
                }))
                return []
            }
        }
    }

    function revealLater(row: Item): void { rows.revealing = row; revealSoon.restart() }

    // ── An island: a group (or one of Home's pins) as the Dynamic Island draws a Live Activity. Compact it is one line,
    // its mark snug in the capsule's end, the name in the ink and what it holds now bold in its colour (HIG: bold colour
    // on the black, information split leading and trailing); open it grows in place into its rows on the same plate,
    // the line keeping its place (HIG: the expanded presentation is an enlarged compact one), its corners settling
    // from a capsule to a card. A switch group is its switch: a tap flips it, nothing opens.
    component Island: Item {
        id: island
        required property var modelData
        required property int index
        property Item deckItem
        property Item owner
        readonly property real d: island.owner?.d ?? 1
        readonly property string key: String(island.modelData.key ?? "")
        readonly property bool pin: island.modelData.pin === true
        readonly property var specs: island.modelData.rows ?? []
        readonly property var first: island.specs[0] ?? null
        readonly property bool open: String(island.owner?.openGroup ?? "") === island.key
        readonly property string title: Translation.tr(String(island.modelData.title ?? ""))
        // What answers on the island's own line.
        readonly property bool loneSwitch: !island.pin && island.specs.length === 1 && island.first?.kind === "switch"
        readonly property bool namedSwitch: {
            if (island.pin || island.specs.length < 2 || island.first?.kind !== "switch" || String(island.first?.description ?? "").length > 0) return false
            const label = String(island.first?.label ?? "")
            return Translation.tr(label).toLowerCase() === island.title.toLowerCase() || /^Enable\b/.test(label)
        }
        readonly property bool pinSwitch: island.pin && island.first?.kind === "switch"
        readonly property bool toggles: island.loneSwitch || island.pinSwitch
        readonly property var switchSpec: island.loneSwitch || island.namedSwitch || island.pinSwitch ? island.first : null
        // A group's own on/off is a switch on its line; Home's pins say it in a word, as the Island's own Focus does.
        readonly property bool switchShown: island.loneSwitch || island.namedSwitch
        readonly property bool on: {
            Config.revision
            if (!island.switchSpec) return false
            const value = IrisOptions.currentValue(island.switchSpec)
            return island.switchSpec.invert ? !value : Boolean(value)
        }
        readonly property var area: island.pin ? IrisOptions.sectionById(String(island.first?.origin?.section ?? "")) : null
        readonly property bool accentPin: island.pin && String(island.first?.path ?? "") === "iris.appearance.accent"
        readonly property color tint: island.accentPin ? IrisStyle.accent
            : island.pin ? (island.area?.tint ?? IrisStyle.identity.gray)
            : IrisOptions.groupHue(String(island.owner?.section ?? ""), Number(island.modelData.at ?? island.index), island.key)
        readonly property color hue: IrisStyle.iconColour === "mono" ? IrisStyle.text : IrisStyle.iconHue(island.tint)
        readonly property string glyph: {
            if (!island.pin) return IrisOptions.groupGlyphs[island.key] ?? IrisOptions.sectionById(String(island.owner?.section ?? ""))?.icon ?? "settings"
            if (island.accentPin) return "palette"
            const value = IrisOptions.currentValue(island.first)
            const choice = (island.first?.choices ?? []).find(entry => String(entry.value) === String(value))
            return String(choice?.glyph ?? island.first?.glyph ?? IrisOptions.groupGlyphs[String(island.first?.origin?.group ?? "")] ?? island.area?.icon ?? "settings")
        }
        // What it holds now, in words: a pin its value; a group its first two answers, a switch by its name while on.
        function word(spec: var): string {
            const value = IrisOptions.currentValue(spec)
            const choice = (spec.choices ?? []).find(entry => String(entry.value) === String(value))
            return spec.glance ? String(spec.glance(value) ?? "")
                : spec.kind === "switch" ? ((spec.invert ? !value : Boolean(value)) ? Translation.tr(String(spec.label ?? "")) : "")
                : choice ? Translation.tr(String(choice.label ?? ""))
                : spec.kind === "range" ? IrisOptions.rangeText(spec, value)
                : spec.kind === "text" && String(value ?? "").length > 0 && String(value).length <= 24 ? String(value) : ""
        }
        readonly property var said: {
            Config.revision
            if (island.toggles) return [island.on ? Translation.tr("On") : Translation.tr("Off")]
            // A value named like its island says it is on (Glass read "Glass"); the same word twice is said once.
            const say = spec => { const one = island.word(spec); return one.length > 0 && one.toLowerCase() === island.title.toLowerCase() ? Translation.tr("On") : one }
            if (island.pin) { const one = say(island.first); return one.length > 0 ? [one] : [] }
            const out = []
            const specs = island.specs.slice(island.namedSwitch ? 1 : 0)
            // The rows it shows first; when they say nothing (an off switch, a list), a value from its fine-tune ones.
            for (const tuned of [false, true]) {
                for (const spec of specs) {
                    if (out.length >= 2) break
                    if (IrisOptions.foldsAway(spec) !== tuned || (tuned && spec.kind === "switch")) continue
                    const one = say(spec)
                    if (one.length > 0 && !out.includes(one)) out.push(one)
                }
                if (out.length > 0) break
            }
            return out
        }
        readonly property bool modified: { Config.revision; return island.specs.some(spec => IrisOptions.modified(spec)) }
        // The open island's height: its line and its rows.
        readonly property real compact: island.deckItem?.compact ?? 50
        readonly property real inset: Math.round(6 * island.d)
        readonly property real wanted: island.compact + (body.item ? body.item.implicitHeight + Math.round(10 * island.d) : 0)
        Binding { when: island.open; target: island.deckItem; property: "openWanted"; value: island.wanted }
        // Its rows stay while it closes, so they leave with the body instead of before it.
        property bool closing: false
        onOpenChanged: if (!island.open) { island.closing = true; closeClock.restart() } else bringClock.restart()
        Timer { id: closeClock; interval: (island.deckItem?.duration ?? 200) + 40; onTriggered: island.closing = false }
        Timer { id: bringClock; interval: (island.deckItem?.duration ?? 200) + 30; onTriggered: if (island.open && island.owner?.islandsBring) island.owner.bring(island) }
        function act(): void {
            if (island.toggles) { IrisOptions.commit(island.switchSpec, island.switchSpec.invert ? island.on : !island.on); return }
            if (island.owner?.peers && island.open) return
            island.owner.islandsBring = true
            island.owner.openGroup = island.open ? "" : island.key
        }

        readonly property var box: island.deckItem?.plan.boxes[island.index] ?? null
        x: island.box?.x ?? 0
        y: island.box?.y ?? 0
        width: island.box?.w ?? 0
        height: island.box?.h ?? island.compact
        z: island.open || island.closing ? 1 : 0
        Behavior on x { enabled: island.deckItem?.morphing ?? false; NumberAnimation { duration: island.deckItem.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: island.deckItem.curve } }
        Behavior on y { enabled: island.deckItem?.morphing ?? false; NumberAnimation { duration: island.deckItem.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: island.deckItem.curve } }
        Behavior on width { enabled: island.deckItem?.morphing ?? false; NumberAnimation { duration: island.deckItem.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: island.deckItem.curve } }
        Behavior on height { enabled: island.deckItem?.morphing ?? false; NumberAnimation { duration: island.deckItem.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: island.deckItem.curve } }

        activeFocusOnTab: true
        Accessible.role: island.toggles ? Accessible.CheckBox : Accessible.Button
        Accessible.name: island.title
        Accessible.description: island.said.join(", ")
        Accessible.checkable: island.toggles
        Accessible.checked: island.on
        Keys.onSpacePressed: island.act()
        Keys.onReturnPressed: island.act()

        readonly property real radius: Math.min(island.height / 2, island.deckItem?.radius ?? 26)
        IrisBodyShadow {
            visible: IrisStyle.islandShadow.a > 0
            anchors.fill: plate
            radius: plate.radius
            offset.y: Math.round(3 * island.d)
            blur: Math.round(16 * island.d)
            spread: 0
            color: IrisStyle.islandShadow
        }
        IrisPlate {
            id: plate
            anchors.fill: parent
            radius: island.radius
            color: IrisStyle.islandPlate
            lit: island.open
            scale: lineArea.pressed && !island.open ? IrisStyle.pressScale(0.97) : 1
            Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
        }
        // Hover lifts the line under the pointer; open, only its line answers it (the rows have their own).
        Rectangle {
            x: plate.x
            y: plate.y
            width: plate.width
            height: island.open ? island.compact : plate.height
            topLeftRadius: island.radius
            topRightRadius: island.radius
            bottomLeftRadius: island.open ? 0 : island.radius
            bottomRightRadius: island.open ? 0 : island.radius
            scale: plate.scale
            color: lineArea.pressed ? IrisStyle.fillActive : IrisStyle.fillQuiet
            opacity: lineArea.containsMouse || lineArea.pressed || island.activeFocus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
        }
        Item {
            id: line
            // Above the line's area: its switch takes its own click (a click on it opened the island instead, 11-04); the rest falls through.
            z: 1
            width: island.width
            height: island.compact
            scale: plate.scale
            // The mark sits in the capsule's end with even air round it (HIG: concentric, snug).
            readonly property real markSize: Math.round(22 * island.d)
            readonly property real pad: Math.round((island.compact - line.markSize) / 2)
            readonly property real tail: island.switchShown ? lineSwitch.width : island.open ? closeKey.width : glance.width
            IrisSquircle {
                id: mark
                x: line.pad
                anchors.verticalCenter: parent.verticalCenter
                width: line.markSize
                height: width
                plain: IrisStyle.settingsPlainMarks && !(island.pinSwitch && island.on)
                tint: island.tint
                glyph: island.glyph
            }
            IrisText {
                id: name
                anchors.left: mark.right
                anchors.leftMargin: Math.round(10 * island.d)
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, line.width - x - line.pad - line.tail - Math.round(16 * island.d) - (dot.visible ? dot.width + Math.round(8 * island.d) : 0))
                text: island.title
                color: IrisStyle.text
                font.pixelSize: IrisStyle.typeBody
                font.weight: IrisStyle.weight(Font.DemiBold)
                elide: Text.ElideRight
            }
            // Changed from its factory value: the page's one dot.
            Rectangle {
                id: dot
                visible: island.modified
                anchors.left: name.right
                anchors.leftMargin: Math.round(8 * island.d)
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(6 * island.d)
                height: width
                radius: width / 2
                color: IrisStyle.accent
            }
            // What it holds now, trailing and bold in its colour; it gives way to the rows when the island opens. Two
            // answers that do not fit say the first; one that does not fit is left to the open island (never cut).
            IrisText {
                id: glance
                // From the name's natural width, never its laid-out one: that one waits on this text (a binding loop).
                readonly property real room: line.width - name.x - name.implicitWidth - (dot.visible ? dot.width + Math.round(8 * island.d) : 0) - line.pad - Math.round(20 * island.d)
                readonly property string both: island.said.join(" · ")
                visible: !island.switchShown
                anchors.right: parent.right
                anchors.rightMargin: line.pad + Math.round(2 * island.d)
                anchors.verticalCenter: parent.verticalCenter
                // Compact says little (HIG): two answers only while both are short.
                text: glance.both.length <= 24 && glanceMetrics.advanceWidth(glance.both) <= glance.room ? glance.both
                    : island.said.length > 0 && glanceMetrics.advanceWidth(island.said[0]) <= glance.room ? island.said[0] : ""
                color: island.toggles && !island.on ? IrisStyle.textTertiary : island.hue
                font.pixelSize: IrisStyle.typeBody
                font.weight: IrisStyle.weight(Font.Bold)
                opacity: island.open ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(island.open ? 90 : 160); easing.type: IrisStyle.feedbackEasing } }
                FontMetrics { id: glanceMetrics; font: glance.font }
            }
            IrisSwitch {
                id: lineSwitch
                visible: island.switchShown
                anchors.right: parent.right
                anchors.rightMargin: line.pad
                anchors.verticalCenter: parent.verticalCenter
                on: island.on
                name: island.title
                onToggled: IrisOptions.commit(island.switchSpec, island.switchSpec.invert ? on : !on)
            }
            // Open, the line's end closes it again, as the Island's own cancel key: a round key in the plate's quiet fill.
            Rectangle {
                id: closeKey
                visible: !island.switchShown && !island.toggles
                opacity: island.open ? 1 : 0
                anchors.right: parent.right
                anchors.rightMargin: line.pad - Math.round(2 * island.d)
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(26 * island.d)
                height: width
                radius: width / 2
                color: lineArea.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(island.open ? 200 : 90); easing.type: IrisStyle.feedbackEasing } }
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "keyboard_arrow_up"
                    iconSize: Math.round(18 * island.d)
                    color: IrisStyle.textSecondary
                }
            }
        }
        MouseArea {
            id: lineArea
            width: island.width
            height: island.compact
            hoverEnabled: true
            cursorShape: island.owner?.peers && island.open ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: island.act()
        }
        // The rows, laid out once at the page's width (an open island always spans it) and revealed by the body as it
        // grows, a beat after it starts.
        Item {
            anchors.fill: parent
            clip: true
            Loader {
                id: body
                x: island.inset
                y: island.compact - Math.round(4 * island.d)
                width: (island.deckItem?.width ?? island.width) - 2 * island.inset
                active: island.open || island.closing
                opacity: island.open && body.status === Loader.Ready ? 1 : 0
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation { duration: island.open ? Math.round((island.deckItem?.duration ?? 200) * 0.28) : 0 }
                        NumberAnimation { duration: IrisStyle.duration(island.open ? 180 : 90); easing.type: IrisStyle.feedbackEasing }
                    }
                }
                sourceComponent: island.pin ? pinRows : groupRows
            }
        }
        Component {
            id: pinRows
            IrisSetting { spec: island.first; voice: island.owner?.voice ?? ""; last: true }
        }
        Component {
            id: groupRows
            GroupBody { group: island.modelData; owner: island.owner; skipFirst: island.namedSwitch; heading: island.title }
        }
    }

    // ── An open island's rows: its parts (each in an inset container when there are several, HIG), the fine-tuning
    // folded under them when there is enough of it to fold.
    component GroupBody: ColumnLayout {
        id: body
        required property var group
        property Item owner
        property bool skipFirst: false
        property string heading: ""
        readonly property real d: body.owner?.d ?? 1
        spacing: Math.round(8 * body.d)
        readonly property string key: String(body.group?.key ?? "")
        readonly property string tuneKey: String(body.owner?.section ?? "") + "/" + body.key
        readonly property var all: (body.group?.rows ?? []).slice(body.skipFirst ? 1 : 0)
        readonly property var tuned: body.all.filter(spec => IrisOptions.foldsAway(spec))
        // A group that is all fine-tuning is already the fold: its rows stand open.
        readonly property bool tunes: body.tuned.length >= 2 && body.tuned.length < body.all.length
        readonly property bool tuneOpen: body.tunes && ((body.owner?.host?.tuneAll ?? false) || (body.owner?.unfolded[body.tuneKey] ?? false))
        readonly property var shownRows: body.tunes && !body.tuneOpen ? body.all.filter(spec => !body.tuned.includes(spec)) : body.all
        readonly property string landing: String(body.owner?.host?.landingPath ?? "")
        readonly property bool landsInFold: body.landing.length > 0 && body.tuned.some(spec => String(spec.path ?? "") === body.landing)
        onLandsInFoldChanged: if (body.landsInFold && !body.tuneOpen) body.owner?.fold(body.tuneKey)
        Component.onCompleted: if (body.landsInFold && !body.tuneOpen) body.owner?.fold(body.tuneKey)
        readonly property var parts: body.shownRows.length === 0 ? [""] : [...new Set(body.shownRows.map(spec => String(spec.part ?? "")))]
        Repeater {
            model: ScriptModel { values: body.parts }
            ColumnLayout {
                id: part
                required property string modelData
                required property int index
                readonly property var specs: body.shownRows.filter(spec => String(spec.part ?? "") === part.modelData)
                readonly property bool lastPart: part.index === body.parts.length - 1
                readonly property bool boxed: body.parts.length > 1
                Layout.fillWidth: true
                spacing: Math.round(4 * body.d)
                IrisText {
                    visible: text.length > 0
                    Layout.leftMargin: Math.round(12 * body.d)
                    Layout.topMargin: part.index > 0 ? Math.round(4 * body.d) : 0
                    text: part.modelData.length > 0 ? Translation.tr(part.modelData) : ""
                    color: IrisStyle.subtext
                    font.pixelSize: IrisStyle.typeMeta
                    font.weight: IrisStyle.weight(Font.DemiBold)
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: partRows.implicitHeight
                    radius: IrisStyle.radiusTile
                    color: part.boxed ? IrisStyle.fillQuiet : "transparent"
                    ColumnLayout {
                        id: partRows
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 0
                        Repeater {
                            model: ScriptModel { objectProp: "modelKey"; values: part.specs }
                            IrisSetting {
                                id: row
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                spec: row.modelData
                                voice: body.owner?.voice ?? ""
                                heading: part.index === 0 && row.index === 0 ? body.heading : ""
                                last: row.index === part.specs.length - 1 && !(part.lastPart && body.tunes)
                                landing: body.landing.length > 0 && String(row.modelData.path ?? "") === body.landing
                                onLandingChanged: if (row.landing) body.owner?.revealLater(row)
                                Component.onCompleted: if (row.landing) body.owner?.revealLater(row)
                            }
                        }
                        FineTune {
                            visible: part.lastPart && body.tunes
                            Layout.fillWidth: true
                            open: body.tuneOpen
                            names: body.tuned.map(spec => Translation.tr(String(spec.label ?? "")))
                            onClicked: body.owner?.fold(body.tuneKey)
                        }
                    }
                }
            }
        }
    }
}
