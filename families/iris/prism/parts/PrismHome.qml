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

// Home's own part: the settings people touch every day as keys (`.claude/ref/language`, keycaps-collage): each a cap
// with its glyph printed at the corner, its name and what it holds at the foot. A switch that is on wears its page's
// first colour, so a row of keys reads like the collage, loud and held together by shape and type; off, the quiet cap.
// A press sinks the key and acts: a switch flips, a choice steps to the next, anything else opens its row. The list is
// the classic Home's (`iris.appearance.settingsHome`), so both Settings show the same; Edit takes keys off and offers
// the daily ones to add, in place. Over the keys, the two levels reached for most (the output's volume, the screen's
// brightness) as faders that move the real thing; a machine with neither shows none. One folder holds it all (his
// 11-16: Home spoke many languages); Edit stands on its art.
PrismFile {
    id: root
    signal reach(var row)
    property bool editing: false
    title: Translation.tr("Every day")
    // The screen Settings stands on, or the first one: its brightness is the one people mean.
    readonly property var monitor: Brightness.monitors.find(entry => entry.screen?.name === NiriService.currentOutput) ?? Brightness.monitors[0] ?? null
    // A screen that answers with a level (a nested or virtual output reads "ready" with none).
    readonly property bool dims: Boolean(root.monitor?.ready) && Number.isFinite(Number(root.monitor?.brightness))
    turn: 2
    seed: 8.1

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
    function pageOf(tile: var): var { return PrismModel.page(tile.row?.page ?? tile.live?.section ?? "") }
    function whereOf(tile: var): string {
        const page = root.pageOf(tile)
        return page ? Translation.tr(page.name) : ""
    }
    function setIds(list: var): void { Config.setNestedValue("iris.appearance.settingsHome", list) }

    tools: PrismPill {
        tone: "dark"
        text: root.editing ? Translation.tr("Done") : Translation.tr("Edit")
        onClicked: root.editing = !root.editing
    }

    Column {
        width: root.innerWidth
        spacing: PrismTheme.dp(14)

        Row {
            visible: Audio.ready
            width: parent.width
            spacing: PrismTheme.dp(10)
            // Mute answers in place: the key goes white while the sound is off.
            PrismRound {
                y: volume.middle - height / 2
                glyph: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                lit: Boolean(Audio.sink?.audio?.muted)
                implicitWidth: PrismTheme.dp(32)
                glyphSize: PrismTheme.dp(17)
                Accessible.name: Translation.tr("Mute")
                onClicked: Audio.toggleMute()
            }
            PrismSlider {
                id: volume
                width: parent.width - PrismTheme.dp(42)
                label: Math.round(volume.live) + "%"
                Accessible.name: Translation.tr("Volume")
                from: 0
                to: 100
                value: Math.round(Audio.value * 100)
                onMoved: value => { Audio.lastUserChange = Date.now(); if (Audio.sink?.audio) Audio.sink.audio.volume = value / 100 }
                onCommitted: value => { Audio.lastUserChange = Date.now(); if (Audio.sink?.audio) Audio.sink.audio.volume = value / 100 }
            }
        }
        // The screen's level, its grooves in line with the volume's.
        Row {
            visible: root.dims
            width: parent.width
            spacing: PrismTheme.dp(10)
            Item {
                width: PrismTheme.dp(32)
                height: light.height
                PrismGlyph {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: light.middle - height / 2
                    text: "light_mode"
                    filled: true
                    iconSize: PrismTheme.dp(17)
                    color: PrismTheme.ink2
                }
            }
            PrismSlider {
                id: light
                width: parent.width - PrismTheme.dp(42)
                label: Math.round(light.live) + "%"
                Accessible.name: Translation.tr("Brightness")
                from: 1
                to: 100
                value: Math.round(Number(root.monitor?.brightness ?? 0) * 100)
                onMoved: value => root.monitor?.setBrightness(value / 100)
                onCommitted: value => root.monitor?.setBrightness(value / 100)
            }
        }

        Flow {
            id: grid
            width: parent.width
            spacing: PrismTheme.dp(8)
            // As many keys a line as fit, then evened out: eight keys are one line or two of four, never six and two.
            readonly property int count: root.tiles.length + (root.editing ? root.offered.length : 0)
            readonly property int fits: Math.max(2, Math.floor((width + spacing) / (PrismTheme.dp(128) + spacing)))
            readonly property int columns: Math.max(2, Math.ceil(grid.count / Math.max(1, Math.ceil(grid.count / grid.fits))))
            readonly property real tileWidth: Math.floor((width - (columns - 1) * spacing) / columns)

            Repeater {
                // Keyed by id (an offer apart): a write rebuilds the tile list, the tiles stay.
                model: ScriptModel {
                    objectProp: "key"
                    values: root.tiles.map(tile => Object.assign({ key: tile.id }, tile)).concat(root.editing ? root.offered.map(tile => Object.assign({ offer: true, key: "+" + tile.id }, tile)) : [])
                }
                delegate: Item {
                    id: tile
                    required property var modelData
                    readonly property bool offer: Boolean(tile.modelData.offer)
                    readonly property bool on: !tile.offer && root.isOn(tile.modelData)
                    readonly property color lit: PrismTheme.palette(String(root.pageOf(tile.modelData)?.tint ?? "grey"))[0]
                    // The legend printed on the cap: dark on a bright cap, white on a deep one, the page's ink when off.
                    readonly property color legend: !tile.on ? PrismTheme.ink : PrismTheme.lum(tile.lit) > 0.55 ? PrismTheme.night : PrismTheme.paper
                    width: grid.tileWidth
                    height: PrismTheme.dp(84)
                    opacity: tile.offer ? (press.containsMouse ? 0.9 : 0.55) : 1
                    Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }

                    PrismKey {
                        anchors.fill: parent
                        radius: PrismTheme.dp(16)
                        face: tile.on ? tile.lit : PrismTheme.keyQuiet
                        hovered: press.containsMouse
                        down: press.pressed
                        PrismGlyph {
                            x: PrismTheme.dp(14)
                            y: PrismTheme.dp(12)
                            text: tile.offer ? "add" : tile.modelData.glyph
                            filled: tile.on
                            iconSize: PrismTheme.dp(20)
                            color: tile.legend
                        }
                        Column {
                            x: PrismTheme.dp(14)
                            width: parent.width - PrismTheme.dp(28)
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: PrismTheme.dp(11)
                            spacing: 0
                            PrismText {
                                width: parent.width
                                text: Translation.tr(tile.modelData.label)
                                elide: Text.ElideRight
                                color: tile.legend
                                font.pixelSize: PrismTheme.small
                                font.weight: Font.Bold
                            }
                            // What it holds now; a key on offer says where it lives instead.
                            PrismText {
                                width: parent.width
                                text: tile.offer ? root.whereOf(tile.modelData) : root.says(tile.modelData)
                                elide: Text.ElideRight
                                // On a lit cap the legend's own ink at caption size; on a quiet one the page's second ink.
                                color: tile.on ? tile.legend : PrismTheme.ink2
                                font.pixelSize: PrismTheme.caption
                            }
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
                        anchors.rightMargin: PrismTheme.dp(8)
                        y: PrismTheme.dp(8)
                        implicitWidth: PrismTheme.dp(24)
                        glyphSize: PrismTheme.dp(15)
                        glyph: "remove"
                        onClicked: root.setIds(root.ids.filter(id => id !== tile.modelData.id))
                    }
                }
            }
        }
    }
}
