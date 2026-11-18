import QtQuick
import Quickshell
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model

// The page's other groups under the page card, as an archive's drawer (B · Carpeta): short groups stand in even rows,
// every row as wide as the page and its folders as tall as each other, so the drawer reads in order; a gallery
// (faces, palettes, pieces) runs across the whole width. Each group takes the shape of what it holds
// (PrismFolder), its art one of the desktop's colours.
Item {
    id: root
    // Every group but the page card's: { title, rows }.
    property var groups: []
    property string tint: "grey"
    property string flashPath: ""

    readonly property real gap: PrismTheme.dp(14)
    readonly property int columns: root.width >= PrismTheme.dp(900) ? 3 : root.width >= PrismTheme.dp(520) ? 2 : 1
    readonly property real cell: Math.floor((root.width - root.gap * (root.columns - 1)) / root.columns)

    function laysOut(row: var): bool {
        const kind = String(row?.kind ?? ""), spec = row?.spec ?? {}
        return kind === "pieces" || Boolean(spec.flags) || kind === "designs" || (kind === "list" && Boolean(spec.view))
            || ["icon", "curve", "niriMotion", "widgets", "themes"].includes(kind) || (kind === "choice" && spec.cards === "island")
            || (kind === "choice" && Boolean(spec.previewFont))
            || (kind === "choice" && spec.tiles === true && PrismModel.choicesOf(row).every(choice => choice.palette))
    }
    // A gallery, or a long group, reads across the page.
    function wide(group: var): bool {
        const rows = Array.from(group?.rows ?? [])
        return root.columns > 1 && (rows.length >= 10 || rows.some(row => root.laysOut(row)))
    }
    // A group of a row or two that lays nothing out is a slip, not a folder.
    function shapeOf(group: var): string {
        const rows = Array.from(group?.rows ?? [])
        if (root.wide(group)) return "band"
        return rows.length <= 2 && !rows.some(row => root.laysOut(row)) ? "slip" : "folder"
    }

    function boxOf(title: string): var {
        for (let i = 0; i < folders.count; ++i) {
            const box = folders.itemAt(i)
            if (box && box.title === title) return box
        }
        return null
    }

    // Run by run: the short groups between two wide ones are dealt into rows as even as they go (four in two rows of
    // two, five in three and two), each row splitting the page's width and standing as tall as its tallest folder, so
    // no folder stands narrow beside an empty place and no row is ragged. A wide one goes under all of them.
    function place(): void {
        const boxes = []
        for (let i = 0; i < folders.count; ++i) {
            const box = folders.itemAt(i)
            if (box && box.placed) boxes.push(box)
        }
        let top = 0
        let i = 0
        while (i < boxes.length) {
            if (boxes[i].wideBox) {
                boxes[i].x = 0
                boxes[i].y = top
                top += boxes[i].implicitHeight + root.gap
                i += 1
                continue
            }
            let j = i
            while (j < boxes.length && !boxes[j].wideBox) j += 1
            const n = j - i
            const lines = Math.ceil(n / root.columns)
            const base = Math.floor(n / lines)
            const extra = n % lines
            let k = i
            for (let line = 0; line < lines; ++line) {
                const count = base + (line < extra ? 1 : 0)
                const cell = Math.floor((root.width - root.gap * (count - 1)) / count)
                let tall = 0
                for (let m = 0; m < count; ++m) tall = Math.max(tall, boxes[k + m].implicitHeight)
                for (let m = 0; m < count; ++m) {
                    const box = boxes[k + m]
                    box.cellWidth = m === count - 1 ? root.width - m * (cell + root.gap) : cell
                    box.x = m * (cell + root.gap)
                    box.y = top
                    box.column = m
                    box.rowHeight = tall
                }
                top += tall + root.gap
                k += count
            }
            i = j
        }
        root.implicitHeight = Math.max(0, top - root.gap)
    }
    onColumnsChanged: Qt.callLater(root.place)
    onWidthChanged: Qt.callLater(root.place)

    Repeater {
        id: folders
        model: ScriptModel { objectProp: "title"; values: root.groups }
        onCountChanged: Qt.callLater(root.place)
        delegate: PrismFolder {
            id: folder
            required property var modelData
            required property int index
            // A folder on its way out (its group gone) keeps where it stood and leaves the placing.
            readonly property bool placed: root.groups.some(group => String(group?.title ?? "") === folder.title)
            readonly property bool wideBox: root.wide(folder.modelData)
            property int column: 0
            property real cellWidth: root.cell
            // Its row's height: the folders of one row stand as tall as each other.
            property real rowHeight: 0
            entry: modelData
            shape: root.shapeOf(folder.modelData)
            width: folder.wideBox ? root.width : folder.cellWidth
            height: folder.wideBox ? implicitHeight : Math.max(implicitHeight, folder.rowHeight)
            // Every front tab at the left, the back's at the right (the study).
            tabLeft: true
            tint: root.tint
            turn: index + 1
            flashPath: root.flashPath
            onImplicitHeightChanged: Qt.callLater(root.place)
            Component.onCompleted: Qt.callLater(root.place)
        }
    }
}
