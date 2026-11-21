import QtQuick
import Quickshell
import qs.services
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// A group's rows (the card around them says the group's name, PrismGroup): two fields of one part (text, levels,
// short choices) stand side by side with the name over the control where the card is wide enough, and two switches
// share a line; everything else takes the whole width. A part of the group gets its own caption.
Item {
    id: root
    property string title: ""
    property var rows: []
    property bool showPage: false
    property string flashPath: ""
    // Search and Changes: a press on a row's name opens it where it lives.
    signal reach(var row)
    // The group's master row, whose name the head already says: it shows its control alone.
    property string headlessKey: ""

    readonly property real inner: root.width
    readonly property real gap: PrismTheme.dp(28)
    readonly property bool twoUp: !root.showPage && root.inner >= PrismTheme.dp(640)
    readonly property real half: Math.floor((root.inner - root.gap) / 2)
    readonly property real controlWidth: root.compact ? root.inner : Math.min(PrismTheme.dp(300), root.inner * 0.4)
    // A folder on the shelf: too narrow for a control beside its name.
    property bool compact: false

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

    implicitHeight: body.implicitHeight

    Column {
        id: body
        width: root.width
        spacing: 0

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
                    topPadding: PrismTheme.dp(18)
                    bottomPadding: PrismTheme.dp(2)
                    text: Translation.tr(entry.part)
                    color: PrismTheme.ink2
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
                        headless: String(row.key ?? "") === root.headlessKey && root.headlessKey.length > 0
                        stacked: parent.stackedPair
                        paired: parent.paired && !parent.stackedPair
                        compact: root.compact
                        dense: true
                        showPage: root.showPage
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
                            // The pair's two halves are one line: the same density, names and controls on one level.
                            paired: !second.stackedPair
                            compact: root.compact
                            dense: true
                            controlWidth: second.stackedPair ? root.half : PrismTheme.dp(64)
                            flash: root.flashPath === row.path
                        }
                    }
                }
            }
        }
    }
}
