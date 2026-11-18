import QtQuick
import Quickshell
import qs.modules.iris.prism.core

// The page's other groups, each a folder, side by side under the page card (the B · Carpeta study): three to a row
// where the page is wide, two where it is not, never an empty place.
Item {
    id: root
    // Every group but the page card's: { title, rows }.
    property var groups: []
    property string tint: "grey"
    property string flashPath: ""

    readonly property real gap: PrismTheme.dp(14)
    // Never an empty column: two groups share the row in halves.
    readonly property int columns: Math.max(1, Math.min(root.width >= PrismTheme.dp(900) ? 3 : 2, root.groups.length))
    readonly property real cell: Math.floor((root.width - root.gap * (root.columns - 1)) / root.columns)

    // A group's folder, for the page to glide to it.
    function boxOf(title: string): var {
        for (let i = 0; i < folders.count; ++i) {
            const box = folders.itemAt(i)
            if (box && box.title === title) return box
        }
        return null
    }

    // Row by row, every folder of a row as tall as its tallest (the study's shelf): their feet line up.
    function place(): void {
        let y = 0
        for (let first = 0; first < folders.count; first += root.columns) {
            let tall = 0
            const row = []
            for (let i = first; i < Math.min(folders.count, first + root.columns); ++i) {
                const box = folders.itemAt(i)
                if (!box) continue
                row.push(box)
                tall = Math.max(tall, box.implicitHeight)
            }
            row.forEach((box, c) => {
                box.x = c * (root.cell + root.gap)
                box.y = y
                box.height = tall
            })
            y += tall + root.gap
        }
        root.implicitHeight = Math.max(0, y - root.gap)
    }
    onColumnsChanged: Qt.callLater(root.place)
    onCellChanged: Qt.callLater(root.place)

    Repeater {
        id: folders
        model: ScriptModel { objectProp: "title"; values: root.groups }
        onCountChanged: Qt.callLater(root.place)
        delegate: PrismFolder {
            required property var modelData
            required property int index
            width: root.cell
            entry: modelData
            tint: root.tint
            turn: index + 1
            flashPath: root.flashPath
            onImplicitHeightChanged: Qt.callLater(root.place)
            Component.onCompleted: Qt.callLater(root.place)
        }
    }
}
