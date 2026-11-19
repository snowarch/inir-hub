pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// Home's own part: the settings people touch every day as tiles, in the grammar of the Apple widget set (a black or
// white circle says the state, the name and what it holds now under it). A press acts: a switch flips, a choice steps
// to the next, anything else opens its row. The list is the classic Home's (`iris.appearance.settingsHome`), so both
// Settings show the same; Edit takes tiles off and offers the daily ones to add, in place.
Column {
    id: root
    signal reach(var row)
    property bool editing: false
    spacing: 0

    readonly property var ids: {
        const _ = PrismModel.revision
        return Array.from(Config.options?.iris?.appearance?.settingsHome ?? IrisOptions.homeDefault).map(entry => String(entry))
    }
    // A live switch of the shell (Night Light, Game mode) or a row of Prism's pages; anything else is left out.
    readonly property var glyphs: ({ nightLight: "nightlight", gameMode: "sports_esports" })
    function tileOf(id: string): var {
        const live = IrisOptions.dailySwitches.find(entry => entry.id === id)
        if (live) return { id: id, live: live, label: live.label, glyph: root.glyphs[id] ?? "toggle_on", kind: "switch" }
        const row = PrismModel.find(id)
        return row && !PrismModel.virtual(row) ? { id: id, row: row, label: row.label, glyph: row.glyph ?? "tune", kind: row.kind } : null
    }
    readonly property var tiles: root.ids.map(id => root.tileOf(id)).filter(tile => tile !== null)
    readonly property var offered: IrisOptions.homeSuggested.filter(id => !root.ids.includes(id)).map(id => root.tileOf(id)).filter(tile => tile !== null)

    function isOn(tile: var): bool {
        if (tile.live) return Boolean(tile.live.state())
        return tile.kind === "switch" ? Boolean(PrismModel.read(tile.row)) : false
    }
    function says(tile: var): string {
        if (tile.live) return tile.live.state() ? Translation.tr("On") : Translation.tr("Off")
        return PrismModel.sayNow(tile.row)
    }
    function act(tile: var): void {
        if (tile.live) { tile.live.set(!tile.live.state()); return }
        const row = tile.row
        if (row.kind === "switch") { PrismModel.write(row, !Boolean(PrismModel.read(row))); return }
        const choices = PrismModel.choicesOf(row)
        if ((row.kind === "choice" || row.kind === "swatch") && choices.length > 1) {
            const at = choices.findIndex(entry => PrismModel.same(entry.value, PrismModel.read(row)))
            PrismModel.write(row, choices[(at + 1) % choices.length].value)
            return
        }
        root.reach(row)
    }
    function whereOf(tile: var): string {
        const page = PrismModel.page(tile.row?.page ?? tile.live?.section ?? "")
        return page ? Translation.tr(page.name) : ""
    }
    function setIds(list: var): void { Config.setNestedValue("iris.appearance.settingsHome", list) }

    // The head as the drawing's captions: the name, and Edit at its end.
    Item {
        width: root.width
        height: PrismTheme.dp(28)
        PrismText {
            anchors.verticalCenter: parent.verticalCenter
            text: Translation.tr("Every day")
            font.pixelSize: PrismTheme.head
            font.weight: Font.DemiBold
            font.letterSpacing: -PrismTheme.head * 0.012
        }
        PrismText {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.editing ? Translation.tr("Done") : Translation.tr("Edit")
            color: editArea.containsMouse ? PrismTheme.ink : PrismTheme.accentInk
            font.pixelSize: PrismTheme.small
            font.weight: Font.DemiBold
            MouseArea {
                id: editArea
                anchors.fill: parent
                anchors.margins: -PrismTheme.dp(6)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: root.editing ? Translation.tr("Done") : Translation.tr("Edit")
                onClicked: root.editing = !root.editing
            }
        }
    }
    Item { width: 1; height: PrismTheme.dp(12) }

    Flow {
        id: grid
        width: root.width
        spacing: PrismTheme.dp(8)
        readonly property int columns: Math.max(2, Math.floor((width + spacing) / (PrismTheme.dp(176) + spacing)))
        readonly property real tileWidth: Math.floor((width - (columns - 1) * spacing) / columns)

        Repeater {
            // Keyed by id (an offer apart): a write rebuilds the tile list, the tiles stay.
            model: ScriptModel {
                objectProp: "key"
                values: root.tiles.map(tile => Object.assign({ key: tile.id }, tile)).concat(root.editing ? root.offered.map(tile => Object.assign({ offer: true, key: "+" + tile.id }, tile)) : [])
            }
            delegate: PrismTile {
                id: tile
                required property var modelData
                width: grid.tileWidth
                offer: Boolean(tile.modelData.offer)
                on: !tile.offer && root.isOn(tile.modelData)
                glyph: tile.modelData.glyph
                label: Translation.tr(tile.modelData.label)
                says: String(tile.offer ? root.whereOf(tile.modelData) : root.says(tile.modelData))
                isSwitch: tile.modelData.kind === "switch"
                removable: root.editing && !tile.offer
                onClicked: {
                    if (tile.offer) root.setIds(root.ids.concat([tile.modelData.id]))
                    else if (!root.editing) root.act(tile.modelData)
                }
                onRemoveClicked: root.setIds(root.ids.filter(id => id !== tile.modelData.id))
            }
        }
    }
}
