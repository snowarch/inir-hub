import QtQuick
import Quickshell
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model

// The page's other groups under the page card, as an archive's drawer (B · Carpeta): short groups stand in columns,
// each going to the column that ends highest, so no card is stretched to a neighbour's height and no place stays
// empty; a gallery (faces, palettes, pieces) runs across every column. Each group takes the shape of what it holds
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

    // Run by run: the short groups between two wide ones share the row, each to the column that ends highest; a run of
    // fewer groups than columns splits the width among them, so no group stands narrow beside an empty place. A wide
    // one goes under all of them.
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
            const cols = Math.min(root.columns, j - i)
            const cell = Math.floor((root.width - root.gap * (cols - 1)) / cols)
            const ends = new Array(cols).fill(top)
            for (let k = i; k < j; ++k) {
                let c = 0
                for (let m = 1; m < cols; ++m) if (ends[m] < ends[c] - 1) c = m
                boxes[k].cellWidth = cell
                boxes[k].x = c * (cell + root.gap)
                boxes[k].y = ends[c]
                boxes[k].column = c
                ends[c] += boxes[k].implicitHeight + root.gap
            }
            top = Math.max(...ends)
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
            entry: modelData
            shape: root.shapeOf(folder.modelData)
            width: folder.wideBox ? root.width : folder.cellWidth
            height: implicitHeight
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
