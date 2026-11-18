import QtQuick
import Quickshell
import qs.services
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// A group of rows as one card (Raell Tech's keyboard and mouse page, his 11-14: `.claude/ref/iris-prism/raell-keyboard-mouse.png`):
// its mark, its name and a line under it, a chip at the right that says what it holds now, and its rows inside. Where
// the card is wide enough, two fields in a row (text, levels, short choices) stand side by side with the name over the
// control, and two switches share a line; everything else takes the card's whole width. A part of the group gets its
// own caption.
Item {
    id: root
    property string title: ""
    // Under the title: what the card holds (search: where the rows come from).
    property string line: ""
    property string glyph: "tune"
    property string tint: "grey"
    property var rows: []
    property bool showPage: false
    property string flashPath: ""
    // A figure at the chip's place when no row names one: where this group stands among the page's ("03 / 12").
    property string note: ""
    // Search and Changes: a press on a row's name opens it where it lives.
    signal reach(var row)
    // Only the rows: the folder around them draws the sheet and says the name (the page card, a folder on the shelf).
    property bool bare: false

    readonly property real pad: root.bare ? 0 : PrismTheme.dp(24)
    readonly property real inner: root.width - root.pad * 2
    readonly property real gap: PrismTheme.dp(28)
    readonly property bool twoUp: !root.showPage && root.inner >= PrismTheme.dp(640)
    readonly property real half: Math.floor((root.inner - root.gap) / 2)
    // The chart's grey column only where the room holds it; otherwise what a row does sits under its name.
    readonly property real aboutWidth: root.inner < PrismTheme.dp(900) ? 0 : Math.min(PrismTheme.dp(260), root.inner * 0.28)
    readonly property real controlWidth: root.compact ? root.inner : Math.min(PrismTheme.dp(300), root.inner * 0.4)
    // A folder on the shelf: too narrow for a control beside its name.
    property bool compact: false

    // What the chip says: the first row that names its group's state now (the keyboard's layout), else the note.
    readonly property var chipRow: root.rows.find(row => typeof row.spec?.chip === "function") ?? null
    readonly property string chip: {
        const _ = PrismModel.revision
        return root.chipRow ? String(root.chipRow.spec.chip() ?? "") : ""
    }

    // Two fields of one part side by side, two switches on one line; the rest alone. A field is what draws its control
    // under its name well: text, a level, a hue, a choice of a few short names.
    function shapeOf(row: var): string {
        const kind = String(row.kind ?? "")
        if (kind === "switch") return "switch"
        if (kind === "range" || kind === "hue" || kind === "text") return "field"
        if (kind === "choice" && !row.spec?.cards && !row.spec?.flags) {
            const choices = PrismModel.choicesOf(row)
            if (choices.length >= 2 && choices.length <= 4 && !choices.some(choice => choice.swatch !== undefined && choice.swatch !== null)) return "field"
        }
        return ""
    }
    readonly property var lines: {
        const out = []
        const list = root.rows
        for (let i = 0; i < list.length; i++) {
            const row = list[i]
            const next = list[i + 1]
            const shape = root.twoUp ? root.shapeOf(row) : ""
            if (shape.length > 0 && next && root.shapeOf(next) === shape && String(next.spec?.part ?? "") === String(row.spec?.part ?? "")) {
                out.push({ key: row.key + "+" + next.key, rows: [row, next], shape: shape, first: i })
                i++
            } else out.push({ key: row.key, rows: [row], shape: "", first: i })
        }
        return out
    }

    implicitHeight: root.bare ? body.implicitHeight : card.height

    Rectangle {
        id: card
        visible: !root.bare
        width: root.width
        height: body.implicitHeight + root.pad * 2 - PrismTheme.dp(8)
        radius: PrismTheme.dp(24)
        color: PrismTheme.card
    }

    Column {
        id: body
        x: root.pad
        y: root.pad
        width: root.inner
        spacing: 0

        // The head: a mark in the page's tint, the name and its line, the chip.
        Item {
            visible: !root.bare
            width: parent.width
            height: visible ? Math.max(mark.height, titles.implicitHeight) : 0
            PrismThumb {
                id: mark
                size: PrismTheme.dp(40)
                glyph: root.glyph
                tint: root.tint
                anchors.verticalCenter: parent.verticalCenter
            }
            Column {
                id: titles
                anchors.left: mark.right
                anchors.leftMargin: PrismTheme.dp(14)
                anchors.right: chipBox.visible ? chipBox.left : parent.right
                anchors.rightMargin: PrismTheme.dp(12)
                anchors.verticalCenter: parent.verticalCenter
                spacing: PrismTheme.dp(2)
                PrismText {
                    width: parent.width
                    text: root.title
                    font.pixelSize: PrismTheme.head
                    font.weight: Font.Bold
                    font.letterSpacing: -0.2
                    wrapMode: Text.WordWrap
                }
                PrismText {
                    width: parent.width
                    visible: root.line.length > 0
                    text: root.line
                    color: PrismTheme.ink2
                    font.pixelSize: PrismTheme.small
                    wrapMode: Text.WordWrap
                }
            }
            Rectangle {
                id: chipBox
                readonly property string say: root.chip.length > 0 ? root.chip : root.note
                visible: say.length > 0
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                // Laid out by hand from the text's own width: a Row here fed its width back through the box (polish loop).
                readonly property bool marked: root.chip.length > 0 && String(root.chipRow?.spec?.chipGlyph ?? "").length > 0
                readonly property real lead: chipBox.marked ? PrismTheme.dp(15) + PrismTheme.dp(6) : 0
                width: Math.min(chipBox.lead + chipText.implicitWidth + PrismTheme.dp(24), root.inner * 0.45)
                height: PrismTheme.dp(30)
                radius: height / 2
                color: root.chip.length > 0 ? PrismTheme.fill : "transparent"
                PrismGlyph {
                    visible: chipBox.marked
                    x: PrismTheme.dp(12)
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(root.chipRow?.spec?.chipGlyph ?? "")
                    iconSize: PrismTheme.dp(15)
                    color: PrismTheme.ink2
                }
                PrismText {
                    id: chipText
                    x: PrismTheme.dp(12) + chipBox.lead
                    width: chipBox.width - x - PrismTheme.dp(12)
                    anchors.verticalCenter: parent.verticalCenter
                    text: chipBox.say
                    figures: root.chip.length === 0
                    color: root.chip.length > 0 ? PrismTheme.ink : PrismTheme.ink3
                    font.pixelSize: PrismTheme.small
                    font.weight: root.chip.length > 0 ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }
            }
        }
        Item { width: 1; height: root.bare ? 0 : PrismTheme.dp(10) }

        // A write changes Config.revision and with it every row list; the model keys lines by their rows' `key` so a
        // value changing keeps every row's delegate (a plain array rebuilt the whole page on each click, and a handler
        // still running in a row that was gone read "root is not defined").
        Repeater {
            model: ScriptModel { objectProp: "key"; values: root.lines }
            delegate: Column {
                id: entry
                required property var modelData
                required property int index
                width: body.width
                readonly property string part: String(entry.modelData.rows[0].spec?.part ?? "")
                // A search's hits come from many groups: a part's caption there would name one group's inside.
                // A part named as its folder already is says nothing twice.
                readonly property bool partStarts: !root.showPage && entry.part.length > 0 && entry.part !== root.title
                    && (entry.modelData.first === 0 || String(root.rows[entry.modelData.first - 1]?.spec?.part ?? "") !== entry.part)
                PrismText {
                    visible: entry.partStarts
                    topPadding: PrismTheme.dp(14)
                    bottomPadding: PrismTheme.dp(2)
                    text: Translation.tr(entry.part)
                    color: PrismTheme.ink3
                    font.pixelSize: PrismTheme.small
                    font.weight: Font.DemiBold
                }
                // Two rows of a line are two fixed places, never a Repeater over the line's list: the list is new on
                // every write, and a Repeater would rebuild a level under the pointer mid-drag.
                Row {
                    readonly property bool paired: entry.modelData.rows.length > 1
                    readonly property bool stackedPair: paired && entry.modelData.shape === "field"
                    spacing: root.gap
                    PrismRow {
                        width: parent.paired ? root.half : body.width
                        row: entry.modelData.rows[0]
                        stacked: parent.stackedPair
                        compact: root.compact
                        dense: root.bare
                        showPage: root.showPage
                        aboutWidth: parent.paired ? 0 : root.aboutWidth
                        controlWidth: parent.stackedPair ? root.half : parent.paired ? PrismTheme.dp(64) : root.controlWidth
                        flash: root.flashPath === row.path
                        onOpenRequested: root.reach(row)
                    }
                    Loader {
                        id: second
                        active: parent.paired
                        visible: active
                        readonly property bool stackedPair: parent.stackedPair
                        sourceComponent: PrismRow {
                            width: root.half
                            row: entry.modelData.rows[1]
                            stacked: second.stackedPair
                            aboutWidth: 0
                            controlWidth: second.stackedPair ? root.half : PrismTheme.dp(64)
                            flash: root.flashPath === row.path
                        }
                    }
                }
            }
        }
    }
}
