pragma ComponentBehavior: Bound
import QtQuick
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

    PrismHeading {
        width: root.width
        eyebrow: Translation.tr("Home")
        title: Translation.tr("Every day")
        titleSize: PrismTheme.head
        link: root.editing ? Translation.tr("Done") : Translation.tr("Edit")
        onLinkClicked: root.editing = !root.editing
    }
    Item { width: 1; height: PrismTheme.dp(12) }

    Flow {
        id: grid
        width: root.width
        spacing: PrismTheme.dp(8)
        readonly property int columns: Math.max(2, Math.floor((width + spacing) / (PrismTheme.dp(176) + spacing)))
        readonly property real tileWidth: Math.floor((width - (columns - 1) * spacing) / columns)

        Repeater {
            model: root.tiles.concat(root.editing ? root.offered.map(tile => Object.assign({ offer: true }, tile)) : [])
            delegate: Item {
                id: tile
                required property var modelData
                readonly property bool offer: Boolean(tile.modelData.offer)
                readonly property bool on: !tile.offer && root.isOn(tile.modelData)
                width: grid.tileWidth
                height: PrismTheme.dp(52)
                opacity: tile.offer ? (press.containsMouse ? 0.9 : 0.55) : 1
                Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    // On, the capsule lifts a little under its white circle; a hairline of light keeps it on the page.
                    color: press.pressed ? PrismTheme.fillPress : press.containsMouse || tile.on ? PrismTheme.fillHover : PrismTheme.fill
                    border.width: 1
                    border.color: tile.on ? Qt.alpha(PrismTheme.ink, 0.1) : "transparent"
                    scale: press.pressed ? 0.97 : 1
                    Behavior on color { ColorAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
                }
                // The state as a circle: white when on, the page's dark when off; a swatch wears its colour.
                Rectangle {
                    id: mark
                    x: PrismTheme.dp(8)
                    anchors.verticalCenter: parent.verticalCenter
                    width: PrismTheme.dp(36); height: width; radius: width / 2
                    color: tile.on ? PrismTheme.solid : PrismTheme.sunk
                    Behavior on color { ColorAnimation { duration: PrismTheme.ms(180); easing.type: Easing.OutCubic } }
                    PrismGlyph {
                        anchors.centerIn: parent
                        text: tile.offer ? "add" : tile.modelData.glyph
                        filled: tile.on
                        iconSize: PrismTheme.dp(18)
                        color: tile.on ? PrismTheme.inkSolid : PrismTheme.ink
                    }
                }
                Column {
                    anchors.left: mark.right
                    anchors.leftMargin: PrismTheme.dp(10)
                    anchors.right: parent.right
                    anchors.rightMargin: root.editing && !tile.offer ? PrismTheme.dp(40) : PrismTheme.dp(16)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    PrismText {
                        width: parent.width
                        text: Translation.tr(tile.modelData.label)
                        elide: Text.ElideRight
                        font.pixelSize: PrismTheme.small
                        font.weight: Font.DemiBold
                    }
                    // What it holds now; a tile on offer says where it lives instead.
                    PrismText {
                        width: parent.width
                        text: tile.offer ? root.whereOf(tile.modelData) : root.says(tile.modelData)
                        elide: Text.ElideRight
                        color: PrismTheme.ink2
                        font.pixelSize: PrismTheme.caption
                    }
                }
                MouseArea {
                    id: press
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: tile.modelData.kind === "switch" ? Accessible.CheckBox : Accessible.Button
                    Accessible.name: Translation.tr(tile.modelData.label)
                    Accessible.checked: tile.on
                    onClicked: {
                        if (tile.offer) root.setIds(root.ids.concat([tile.modelData.id]))
                        else if (!root.editing) root.act(tile.modelData)
                    }
                }
                // Editing: a tile on Home comes off from its corner.
                PrismRound {
                    visible: root.editing && !tile.offer
                    anchors.right: parent.right
                    anchors.rightMargin: PrismTheme.dp(10)
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: PrismTheme.dp(24)
                    glyphSize: PrismTheme.dp(15)
                    glyph: "remove"
                    onClicked: root.setIds(root.ids.filter(id => id !== tile.modelData.id))
                }
            }
        }
    }
}
