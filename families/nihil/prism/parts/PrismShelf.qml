import QtQuick
import Quickshell
import qs.modules.nihil.prism.core

// The page's other groups, each a folder, side by side under the page card (the B · Carpeta study): three to a row
// where the page is wide, two where it is not, never an empty place.
Item {
    id: root
    // Every group but the page card's: { title, rows }.
    property var groups: []
    property string tint: "grey"
    property string flashPath: ""
    // The first folder's number: the page card holds group 01, except on Home.
    property int first: 2

    readonly property real gap: PrismTheme.dp(14)
    // At most three short groups to a row where the page is wide, two where it is not.
    readonly property int columns: root.width >= PrismTheme.dp(900) ? 3 : root.width >= PrismTheme.dp(520) ? 2 : 1
    // A group whose rows lay things out under their line (lists, pieces, designs, a long group) takes a row of its own;
    // short ones share a row, in halves or thirds, never leaving an empty place.
    function wide(group: var): bool {
        const rows = Array.from(group?.rows ?? [])
        return rows.length >= 9 || rows.some(row => {
            const kind = String(row?.kind ?? ""), spec = row?.spec ?? {}
            return kind === "pieces" || Boolean(spec.flags) || kind === "designs" || (kind === "list" && Boolean(spec.view))
                || ["icon", "curve", "niriMotion", "widgets", "themes"].includes(kind) || (kind === "choice" && spec.cards === "island")
        })
    }
    // [[index, …], …]: each row of the shelf. Short groups fill their rows in the page's order and a wide one keeps
    // its place among them, so no short group stands alone across the page while another waits further down.
    function linesOf(groups: var): var {
        const out = []
        let line = []
        Array.from(groups ?? []).forEach((group, i) => {
            if (root.wide(group)) { out.push([i]); return }
            if (line.length === 0) out.push(line)
            line.push(i)
            if (line.length === root.columns) line = []
        })
        return out.filter(entry => entry.length > 0)
    }
    readonly property var lines: root.linesOf(root.groups)

    // A folder's place across its row and its number as read, row by row (a short group pulled up keeps the count in
    // order), found by its group's name in the groups themselves: a page's folders are made as soon as its groups
    // arrive, before the shelf's own properties catch up, and the leaving page's folders live a moment past them. A
    // folder at a width it never has lays out its rows (a colour pick's discs) for it; null for a folder on its way out.
    function cellOf(title: string): var {
        const index = root.groups.findIndex(group => String(group?.title ?? "") === title)
        if (index < 0) return null
        let at = 0
        for (const line of root.linesOf(root.groups)) {
            const c = line.indexOf(index)
            if (c < 0) { at += line.length; continue }
            const cell = Math.floor((root.width - root.gap * (line.length - 1)) / line.length)
            return { x: c * (cell + root.gap), width: cell, number: at + c }
        }
        return null
    }

    // A group's folder, for the page to glide to it.
    function boxOf(title: string): var {
        for (let i = 0; i < folders.count; ++i) {
            const box = folders.itemAt(i)
            if (box && box.title === title) return box
        }
        return null
    }

    // Row by row, every folder as tall as its row's tallest: their feet line up.
    function place(): void {
        let y = 0
        for (const line of root.lines) {
            const row = line.map(i => folders.itemAt(i)).filter(box => box !== null)
            const tall = Math.max(0, ...row.map(box => box.implicitHeight))
            row.forEach(box => { box.y = y; box.height = tall })
            y += tall + root.gap
        }
        root.implicitHeight = Math.max(0, y - root.gap)
    }
    onLinesChanged: Qt.callLater(root.place)

    Repeater {
        id: folders
        model: ScriptModel { objectProp: "title"; values: root.groups }
        onCountChanged: Qt.callLater(root.place)
        delegate: PrismFolder {
            id: folder
            required property var modelData
            required property int index
            entry: modelData
            readonly property var cell: root.cellOf(String(folder.modelData?.title ?? ""))
            // On its way out it keeps where it stood.
            Binding on x { when: folder.cell !== null; value: folder.cell?.x ?? 0; restoreMode: Binding.RestoreNone }
            Binding on width { when: folder.cell !== null; value: folder.cell?.width ?? 0; restoreMode: Binding.RestoreNone }
            Binding on number { when: folder.cell !== null; value: (folder.cell?.number ?? 0) + root.first; restoreMode: Binding.RestoreNone }
            count: root.groups.length + root.first - 1
            tint: root.tint
            turn: index + 1
            flashPath: root.flashPath
            onImplicitHeightChanged: Qt.callLater(root.place)
            Component.onCompleted: Qt.callLater(root.place)
        }
    }
}
