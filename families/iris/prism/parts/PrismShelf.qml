import QtQuick
import Quickshell
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model

// A page's groups, in their order, as cards on one scroll. A gallery (faces, palettes, pieces) or a long group reads
// across the page; the short ones between two wide ones stand two to a line, each line as tall as its taller card, so
// the eye reads down the page and never zigzags through a ragged wall. Two share a line only when they hold about as
// much: a card of one switch beside one of five was a tall empty folder (his 11-20: "detalles"). Runs of groups that hold one self-named row each
// (a bubble, a sound) read as one card of rows, under their band's name.
Item {
    id: root
    // { title, rows }, in the page's order.
    property var groups: []
    property string page: ""
    property string flashPath: ""

    readonly property real gap: PrismTheme.dp(14)
    // Two to a line wherever a card keeps room for a name over its control: the side column open beside a page leaves
    // about 700 dp, where one column made every page one long list.
    readonly property int columns: root.width >= PrismTheme.dp(640) ? 2 : 1

    function laysOut(row: var): bool {
        const kind = String(row?.kind ?? ""), spec = row?.spec ?? {}
        return kind === "pieces" || Boolean(spec.flags) || kind === "designs" || (kind === "list" && Boolean(spec.view))
            || ["icon", "curve", "niriMotion", "widgets", "themes"].includes(kind) || (kind === "choice" && spec.cards === "island")
            || (kind === "choice" && Boolean(spec.previewFont))
            || (kind === "choice" && spec.tiles === true && PrismModel.choicesOf(row).every(choice => choice.palette))
    }
    function same(a: string, b: string): bool { return String(a ?? "").trim().toLowerCase() === String(b ?? "").trim().toLowerCase() }
    // A group that is only its own row: its name is the row's, nothing laid out under it.
    function single(group: var): bool {
        const rows = Array.from(group?.rows ?? [])
        return rows.length === 1 && root.same(rows[0].label, group.title) && !root.laysOut(rows[0])
    }
    readonly property var bands: IrisOptions.groupBands[root.page] ?? []
    function bandOf(title: string): var {
        return root.bands.find(band => band.groups.includes(title)) ?? null
    }
    // Two or more one-row groups in a row (within one band) become one card; the band names it unless it is "More".
    readonly property var cards: {
        const out = []
        let run = []
        const flush = () => {
            if (run.length >= 2) {
                const band = root.bandOf(run[0].title)
                const named = band && String(band.title) !== "More" && run.every(group => root.bandOf(group.title) === band)
                out.push({ title: named ? String(band.title) : "", titles: run.map(group => String(group.title)),
                    rows: run.map(group => group.rows[0]), merged: true })
            } else out.push(...run)
            run = []
        }
        for (const group of root.groups) {
            if (root.single(group) && (run.length === 0 || root.bandOf(group.title) === root.bandOf(run[0].title))) { run.push(group); continue }
            flush()
            if (root.single(group)) { run.push(group); continue }
            out.push(group)
        }
        flush()
        return out
    }
    // A gallery, or a long group, reads across the page.
    function wide(card: var): bool {
        const rows = Array.from(card?.rows ?? [])
        return root.columns === 1 || rows.length >= 7 || rows.some(row => root.laysOut(row))
    }

    // How much a card holds, counted by rows: its height changes with the width it gets, its rows do not.
    function weight(card: var): int { return Math.max(1, Array.from(card?.rows ?? []).length) }
    function pairs(a: var, b: var): bool {
        const one = root.weight(a.modelData), two = root.weight(b.modelData)
        return Math.min(one, two) / Math.max(one, two) >= 0.5
    }

    function boxOf(title: string): var {
        for (let i = 0; i < cardsRepeater.count; ++i) {
            const box = cardsRepeater.itemAt(i)
            if (box && box.titles.includes(title)) return box
        }
        return null
    }

    // Run by run: the short cards between two wide ones go two to a line, a lone one takes the line; each line as tall
    // as its taller card. A wide card goes under all of them.
    function place(): void {
        const boxes = []
        for (let i = 0; i < cardsRepeater.count; ++i) {
            const box = cardsRepeater.itemAt(i)
            if (box && box.placed) boxes.push(box)
        }
        let top = 0
        let i = 0
        while (i < boxes.length) {
            const box = boxes[i]
            const next = boxes[i + 1]
            if (box.wideBox || !next || next.wideBox || !root.pairs(box, next)) {
                box.cellWidth = root.width
                box.x = 0
                box.y = top
                box.lineHeight = 0
                box.lined = false
                top += box.implicitHeight + root.gap
                i += 1
                continue
            }
            const cell = Math.floor((root.width - root.gap) / 2)
            const tall = Math.max(box.implicitHeight, next.implicitHeight)
            box.cellWidth = cell
            next.cellWidth = root.width - cell - root.gap
            box.x = 0
            next.x = cell + root.gap
            box.y = top
            next.y = top
            box.lineHeight = tall
            next.lineHeight = tall
            box.lined = true
            next.lined = true
            top += tall + root.gap
            i += 2
        }
        root.implicitHeight = Math.max(0, top - root.gap)
    }
    onColumnsChanged: Qt.callLater(root.place)
    onWidthChanged: Qt.callLater(root.place)

    Repeater {
        id: cardsRepeater
        model: ScriptModel { objectProp: "key"; values: root.cards.map(card => Object.assign({ key: (card.titles ?? [card.title]).join("+") }, card)) }
        onCountChanged: Qt.callLater(root.place)
        delegate: PrismGroup {
            id: card
            required property var modelData
            required property int index
            // A card on its way out (its group gone) keeps where it stood and leaves the placing.
            readonly property bool placed: root.cards.some(entry => (entry.titles ?? [entry.title]).join("+") === card.modelData.key)
            readonly property bool wideBox: root.wide(card.modelData)
            property real cellWidth: root.width
            // Its line's height: two cards of one line stand as tall as each other.
            property real lineHeight: 0
            entry: modelData
            tint: String(PrismModel.page(root.page)?.tint ?? "grey")
            turn: card.index + 1
            width: card.cellWidth
            height: Math.max(implicitHeight, card.lineHeight)
            flashPath: root.flashPath
            onImplicitHeightChanged: Qt.callLater(root.place)
            Component.onCompleted: Qt.callLater(root.place)
        }
    }
}
