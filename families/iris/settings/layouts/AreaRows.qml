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
        // the rest lead with their first group. Nothing waits behind Fine-tune any more but a group's own ranges.
        // A column of Drawer (foldHome off) or an area of two groups keeps them open, its all-fine-tuning groups folded.
        const lead = groups.find(group => group.key === "Every day") ?? (rows.section === "general" ? null : groups[0])
        const others = groups.filter(group => group !== lead && group.rows.length > 0)
        const tiles = flat && rows.foldHome && others.length >= 2
        const home = tiles && rows.section === "general"
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
                previous = { title: single ? "​" + group.key : group.title, caption: single ? "" : group.title, key: group.key,
                    rows: group.rows.slice(), loose: single, flat: true }
                out.push(previous)
            }
        }
        if (resting) {
            out.push({ title: "\u200bmore", caption: home ? Translation.tr("General") : "", key: "", rows: [], flat: true, more: true, names: rest.map(group => group.title),
                groups: tiles ? rest.map(group => ({ key: group.key, title: group.title, rows: group.rows })) : [] })
            // A group opens under its tile, which already names it.
            for (const group of rest) out.push({ title: group.title, caption: tiles ? "" : group.title, key: group.key, rows: group.rows, flat: true, rest: true })
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
    function opensRest(key: string): bool {
        return rows.groupTiles ? (rows.host?.tuneAll ?? false) || rows.openGroup === key : rows.moreOpen
    }
    // A link or a search asks for a resting group: its tile opens it, or the area's Fine-tune does. False when the
    // area holds no such group.
    function openRest(wanted: string): bool {
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
        return landing.length > 0 && rows.blocks.some(block => block.rest && block.rows.some(spec => String(spec.path ?? "") === landing))
    }
    onLandsInMoreChanged: {
        if (!rows.landsInMore) return
        const landing = String(rows.host?.landingPath ?? "")
        if (rows.groupTiles)
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
    function showOpened(item: Item): void { rows.opening = item; bringSoon.restart() }
    Timer { id: bringSoon; interval: 60; onTriggered: if (rows.opening) rows.bring(rows.opening) }

    // What the page shows, in order, by group key: the page's wheel and its stage read these.
    function targets(): var {
        const out = []
        for (let i = 0; i < blockRepeater.count; i++) {
            const block = blockRepeater.itemAt(i)?.item
            if (block && block.visible) out.push({ key: String(block.modelData.key ?? ""), item: block })
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
                    readonly property string glyph: IrisOptions.groupGlyphs[block.key] ?? IrisOptions.sectionById(rows?.section)?.icon ?? "settings"
                    visible: block.modelData.flat && head.title.length > 0
                    Layout.fillWidth: true
                    Layout.leftMargin: Math.round(16 * rows?.d)
                    Layout.rightMargin: Math.round(16 * rows?.d)
                    Layout.topMargin: Math.round((block.index > 0 ? 22 : 6) * rows?.d)
                    Layout.bottomMargin: Math.round(2 * rows?.d)
                    implicitHeight: headSkin.active ? (headSkin.item?.implicitHeight ?? 0) : plainHead.implicitHeight
                    IrisSkin { id: headSkin; part: "groupHeader"; host: head; voice: rows?.voice }
                    IrisText {
                        id: plainHead
                        visible: !headSkin.active
                        width: parent.width - (head.lone ? headSwitch.width + Math.round(12 * rows?.d) : 0)
                        text: head.title
                        color: IrisStyle.text
                        font.family: IrisStyle.fontTitle
                        font.pixelSize: IrisStyle.typeHeadline
                        font.weight: IrisStyle.weight(Font.Bold)
                        elide: Text.ElideRight
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

                // The area's other groups as tiles, each saying what it holds now; one opens under them.
                GridLayout {
                    id: groupGrid
                    visible: (block.modelData.groups ?? []).length > 0
                    Layout.fillWidth: true
                    Layout.topMargin: block.caption.length > 0 ? 0 : Math.round(14 * rows?.d)
                    readonly property real gap: Math.round(8 * rows?.d)
                    columns: Math.max(2, Math.floor((width + gap) / (Math.round(232 * rows?.d) * Math.max(1, IrisStyle.typeScale) + gap)))
                    columnSpacing: gap
                    rowSpacing: gap
                    Repeater {
                        model: ScriptModel { objectProp: "key"; values: block.modelData.groups ?? [] }
                        Item {
                            id: group
                            required property var modelData
                            readonly property string key: String(group.modelData.key ?? "")
                            readonly property bool open: rows?.openGroup === group.key
                            readonly property color tint: IrisOptions.groupTints[group.key] ?? IrisOptions.sectionById(rows?.section)?.tint ?? IrisStyle.identity.gray
                            // What it holds now, in words: its first rows' values, a switch by its name while on ("24-hour", "Low power").
                            readonly property string glance: {
                                Config.revision
                                const said = []
                                for (const spec of group.modelData.rows ?? []) {
                                    if (said.length >= 2) break
                                    const value = IrisOptions.currentValue(spec)
                                    const choice = (spec.choices ?? []).find(entry => String(entry.value) === String(value))
                                    const word = spec.kind === "switch" ? ((spec.invert ? !value : Boolean(value)) ? Translation.tr(String(spec.label ?? "")) : "")
                                        : choice ? Translation.tr(String(choice.label ?? ""))
                                        : spec.kind === "range" ? IrisOptions.rangeText(spec, value)
                                        : spec.kind === "text" && String(value ?? "").length > 0 && String(value).length <= 24 ? String(value) : ""
                                    if (word.length > 0) said.push(word)
                                }
                                return said.join(" · ")
                            }
                            function act(): void { rows.openGroup = group.open ? "" : group.key }
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: Math.max(Math.round(64 * rows?.d), groupWords.implicitHeight + Math.round(24 * rows?.d))
                            activeFocusOnTab: true
                            Accessible.role: Accessible.Button
                            Accessible.name: Translation.tr(String(group.modelData.title ?? ""))
                            Accessible.description: group.glance
                            Keys.onSpacePressed: group.act()
                            Keys.onReturnPressed: group.act()

                            IrisPlate {
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
                                IrisSquircle {
                                    id: groupMark
                                    x: Math.round(12 * rows?.d)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.round(32 * rows?.d)
                                    height: width
                                    tint: group.tint
                                    glyph: IrisOptions.groupGlyphs[group.key] ?? "settings"
                                }
                                Column {
                                    id: groupWords
                                    anchors.left: groupMark.right
                                    anchors.leftMargin: Math.round(10 * rows?.d)
                                    anchors.right: groupChevron.left
                                    anchors.rightMargin: Math.round(6 * rows?.d)
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Math.round(1 * rows?.d)
                                    IrisText {
                                        width: parent.width
                                        text: Translation.tr(String(group.modelData.title ?? ""))
                                        color: IrisStyle.text
                                        font.pixelSize: IrisStyle.typeBody
                                        font.weight: IrisStyle.weight(Font.DemiBold)
                                        elide: Text.ElideRight
                                    }
                                    IrisText {
                                        width: parent.width
                                        visible: group.glance.length > 0
                                        text: group.glance
                                        color: IrisStyle.textSecondary
                                        font.pixelSize: IrisStyle.typeMeta
                                        elide: Text.ElideRight
                                    }
                                }
                                MaterialSymbol {
                                    id: groupChevron
                                    anchors.right: parent.right
                                    anchors.rightMargin: Math.round(12 * rows?.d)
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "expand_more"
                                    iconSize: Math.round(18 * rows?.d)
                                    color: group.open || groupArea.containsMouse ? IrisStyle.text : IrisStyle.textTertiary
                                    rotation: group.open ? 180 : 0
                                    Behavior on rotation { NumberAnimation { duration: IrisStyle.duration(180); easing.type: Easing.OutCubic } }
                                }
                            }
                            MouseArea {
                                id: groupArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: group.act()
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
                    color: IrisStyle.fieldChamfer ? "transparent" : (rows?.groupFill ?? "transparent")
                    IrisCutPlate { anchors.fill: parent; visible: IrisStyle.fieldChamfer && (rows?.groupFill.a ?? 0) > 0; color: rows?.groupFill ?? "transparent" }
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
                GridLayout {
                    id: tileGrid
                    visible: block.tiled
                    Layout.fillWidth: true
                    readonly property real gap: Math.round(8 * rows?.d)
                    columns: Math.max(2, Math.floor((width + gap) / (Math.round(208 * rows?.d) * Math.max(1, IrisStyle.typeScale) + gap)))
                    columnSpacing: gap
                    rowSpacing: gap
                    property string opened: ""
                    onOpenedChanged: if (tileGrid.opened.length > 0) rows.showOpened(openedTile)
                    readonly property var openedSpec: block.shownRows.find(spec => String(spec.modelKey ?? spec.path ?? "") === tileGrid.opened) ?? null
                    Repeater {
                        model: ScriptModel { objectProp: "modelKey"; values: block.tiled ? block.shownRows : [] }
                        Item {
                            id: tile
                            required property var modelData
                            readonly property var spec: tile.modelData
                            readonly property string key: String(tile.spec.modelKey ?? tile.spec.path ?? "")
                            readonly property bool edit: tile.spec.kind === "action"
                            readonly property bool toggles: tile.spec.kind === "switch"
                            readonly property var area: IrisOptions.sectionById(String(tile.spec.origin?.section ?? ""))
                            readonly property var value: { Config.revision; return tile.edit ? null : IrisOptions.currentValue(tile.spec) }
                            readonly property bool on: tile.toggles && (tile.spec.invert ? !Boolean(tile.value) : Boolean(tile.value))
                            readonly property var choice: (tile.spec.choices ?? []).find(entry => String(entry.value) === String(tile.value)) ?? null
                            readonly property bool open: tileGrid.opened === tile.key
                            readonly property string words: tile.edit ? ""
                                : tile.toggles ? (tile.on ? Translation.tr("On") : Translation.tr("Off"))
                                : tile.choice ? Translation.tr(String(tile.choice.label ?? ""))
                                : tile.spec.kind === "range" ? IrisOptions.rangeText(tile.spec, tile.value)
                                : String(tile.value ?? "")
                            readonly property string glyph: tile.edit ? "edit"
                                : String(tile.choice?.glyph ?? tile.spec.glyph ?? IrisOptions.groupGlyphs[String(tile.spec.origin?.group ?? "")] ?? tile.area?.icon ?? "settings")
                            readonly property bool accentTile: String(tile.spec.path ?? "") === "iris.appearance.accent"
                            function act(): void {
                                if (tile.edit) tile.spec.run()
                                else if (tile.toggles) IrisOptions.commit(tile.spec, tile.spec.invert ? tile.on : !tile.on)
                                else tileGrid.opened = tile.open ? "" : tile.key
                            }
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: Math.max(Math.round(60 * rows?.d), tileWords.implicitHeight + Math.round(24 * rows?.d))
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
                                color: tile.on ? IrisStyle.lookPlate : tile.edit ? "transparent"
                                    : tile.open ? IrisStyle.tintFillHover(tile.accentTile ? IrisStyle.accent : (tile.area?.tint ?? IrisStyle.identity.gray))
                                    : (rows?.groupFill ?? "transparent")
                                lit: tile.on || tile.open
                                border.width: tile.edit ? 1 : IrisStyle.plateEdge.a > 0 ? 1 : 0
                                border.color: tile.edit ? IrisStyle.hairlineStrong : IrisStyle.plateEdge
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
                                IrisSquircle {
                                    id: tileMark
                                    x: Math.round(12 * rows?.d)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.round(32 * rows?.d)
                                    height: width
                                    visible: !tile.edit
                                    tint: tile.on ? IrisStyle.inkOnLookPlate : tile.accentTile ? IrisStyle.accent : (tile.area?.tint ?? IrisStyle.identity.gray)
                                    glyph: tile.accentTile ? "palette" : tile.glyph
                                }
                                MaterialSymbol {
                                    visible: tile.edit
                                    anchors.centerIn: tileMark
                                    text: "edit"
                                    iconSize: Math.round(18 * rows?.d)
                                    color: IrisStyle.textSecondary
                                }
                                Column {
                                    id: tileWords
                                    anchors.left: tileMark.right
                                    anchors.leftMargin: Math.round(10 * rows?.d)
                                    anchors.right: tileChevron.visible ? tileChevron.left : parent.right
                                    anchors.rightMargin: Math.round(tileChevron.visible ? 6 : 12) * (rows?.d ?? 1)
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Math.round(1 * rows?.d)
                                    IrisText {
                                        width: parent.width
                                        text: Translation.tr(String(tile.spec.label ?? ""))
                                        color: tile.on ? IrisStyle.inkOnLookPlate : tile.edit ? IrisStyle.textSecondary : IrisStyle.text
                                        font.pixelSize: IrisStyle.typeBody
                                        font.weight: IrisStyle.weight(tile.edit ? Font.Medium : Font.DemiBold)
                                        elide: Text.ElideRight
                                    }
                                    IrisText {
                                        width: parent.width
                                        visible: tile.words.length > 0
                                        text: tile.words
                                        color: tile.on ? IrisStyle.secondaryOf(IrisStyle.inkOnLookPlate) : IrisStyle.textSecondary
                                        font.pixelSize: IrisStyle.typeMeta
                                        elide: Text.ElideRight
                                    }
                                }
                                MaterialSymbol {
                                    id: tileChevron
                                    visible: !tile.edit && !tile.toggles
                                    anchors.right: parent.right
                                    anchors.rightMargin: Math.round(12 * rows?.d)
                                    anchors.verticalCenter: parent.verticalCenter
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
                    active: block.tiled && tileGrid.openedSpec !== null
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
                    model: ScriptModel { values: block.loneSwitch || block.modelData.more || block.tiled ? [] : block.parts }
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
                            color: IrisStyle.fieldChamfer ? "transparent" : (rows?.groupFill ?? "transparent")
                            IrisCutPlate { anchors.fill: parent; visible: IrisStyle.fieldChamfer && (rows?.groupFill.a ?? 0) > 0; color: rows?.groupFill ?? "transparent" }
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
        visible: rows.extras && rows.builtUpTo >= rows.blocks.length && extraLinks.links.length + panelEditors.count > 0
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
                if (rows.section === "sidebars") return [
                    { label: Translation.tr("Open Focus"), icon: "dock_to_left", tint: IrisStyle.identity.green, action: () => { GlobalStates.settingsOverlayOpen = false; GlobalStates.openSidebarLeft("") } },
                    { label: Translation.tr("Open Today"), icon: "dock_to_right", tint: IrisStyle.identity.orange, action: () => { GlobalStates.settingsOverlayOpen = false; GlobalStates.openSidebarRight("") } }
                ]
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
        Repeater {
            id: panelEditors
            model: rows.extras && rows.section === "sidebars" ? ["left", "right"] : []
            ColumnLayout {
                id: panelEditor
                required property string modelData
                Layout.fillWidth: true
                spacing: Math.round(6 * rows.d)
                IrisText {
                    Layout.leftMargin: Math.round(16 * rows.d)
                    text: panelEditor.modelData === "left" ? Translation.tr("Focus sections") : Translation.tr("Today sections")
                    color: IrisStyle.text
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: IrisStyle.typeBody
                    font.weight: IrisStyle.weight(Font.DemiBold)
                }
                IrisSidebarEditor { Layout.fillWidth: true; side: panelEditor.modelData }
            }
        }
    }
}
