import QtQuick
import Quickshell
import qs.services
import qs.modules.iris.style
import qs.modules.iris.preview
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// A group of rows as one card (Raell Tech's keyboard and mouse page, his 11-14: `.claude/ref/iris-prism/raell-keyboard-mouse.png`):
// its mark, its name and a line under it, a chip at the right that says what it holds now, and its rows inside. Where
// the card is wide enough, two fields in a row (text, levels, short choices) stand side by side with the name over the
// control, and two switches share a line; everything else takes the card's whole width. A part of the group gets its
// own caption.
// A group with a picture wears it in its card (his 11-15, Raell's keyboard and mouse in their own cards): the scene
// beside the rows, its part lit and numbered like the page's strip, following the rows down while the card is read so
// what a control changes stays in sight; narrow, it stands over the rows. The drawn keyboard heads its card whole.
Item {
    id: root
    property string title: ""
    // The picture: { section, group } of a scene, { keys, row } for the drawn keyboard, or null (PrismModel.figureOf).
    property var figure: null
    // The page's groups as the strip numbers them, and this card's entry among them (a band's title on banded pages).
    property var groups: []
    property string entry: ""
    readonly property int number: root.groups.findIndex(group => String(group.title) === root.entry) + 1
    // Where the page's visible top stands in this card's frame, and how tall the page is: the picture keeps in sight.
    property real viewTop: 0
    property real viewHeight: 0
    property bool active: true
    signal goGroup(string title)
    // Under the title: what the card holds (search: where the rows come from).
    property string line: ""
    property string glyph: "tune"
    property string tint: "grey"
    property var rows: []
    property bool showPage: false
    property string flashPath: ""
    // Search and Changes: a press on a row's name opens it where it lives.
    signal reach(var row)

    // Bare: only the rows (and the drawn keyboard), with no folder or head; the page's lead folder draws those.
    property bool bare: false
    // The least height of the folder: folders side by side in a row of the grid end on one line.
    property real floor: 0
    readonly property real naturalHeight: body.implicitHeight + root.pad - PrismTheme.dp(8)
    readonly property real pad: root.bare ? 0 : PrismTheme.dp(24)
    readonly property real inner: root.width - root.pad * 2

    // ── The picture's place: beside the rows where both fit, else over them.
    readonly property bool keys: Boolean(root.figure?.keys)
    readonly property bool scened: !root.showPage && !root.keys && root.figure !== null && root.figure !== undefined
    readonly property bool beside: root.scened && root.inner >= PrismTheme.dp(720)
    readonly property real figureWidth: root.beside ? Math.round(Math.max(PrismTheme.dp(300), Math.min(PrismTheme.dp(420), root.inner * 0.4))) : root.inner
    readonly property real figureHeight: root.beside ? Math.round(root.figureWidth * 0.66)
        : Math.round(Math.max(PrismTheme.dp(180), Math.min(PrismTheme.dp(260), root.inner * 0.42)))
    readonly property real rowsWidth: root.beside ? root.inner - root.figureWidth - PrismTheme.dp(28) : root.inner
    readonly property bool seen: root.viewTop < root.height && root.viewTop + root.viewHeight > 0

    readonly property real gap: PrismTheme.dp(28)
    readonly property bool twoUp: !root.showPage && root.rowsWidth >= PrismTheme.dp(640)
    readonly property real half: Math.floor((root.rowsWidth - root.gap) / 2)
    readonly property real controlWidth: Math.min(PrismTheme.dp(300), root.rowsWidth * 0.4)

    // What the chip says: the first row that names its group's state now (the keyboard's layout).
    readonly property var chipRow: root.rows.find(row => typeof row.spec?.chip === "function")
        ?? (root.keys && typeof root.figure.row?.spec?.chip === "function" ? root.figure.row : null)
    readonly property string chip: {
        const _ = PrismModel.revision
        return root.chipRow ? String(root.chipRow.spec.chip() ?? "") : ""
    }

    // Two fields of one part side by side, two switches on one line; the rest alone. A field is what draws its control
    // under its name well: text, a level, a hue, a choice of a few short names.
    function shapeOf(row: var): string { return PrismModel.shapeOf(row) }
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

    // The tab holds the number and the name on one line, with air; the art takes the rest of the top.
    readonly property real rise: PrismTheme.dp(50)
    readonly property real tabNeed: root.pad + titleSaid.implicitWidth + PrismTheme.dp(22)
    // What stands on the art (the chip, the group's own restore) keeps its room; the tab never squeezes the art under a sliver.
    readonly property real artSays: (chipBox.visible ? chipBox.width : 0) + (resetBox.visible ? resetBox.width + (chipBox.visible ? PrismTheme.dp(8) : 0) : 0)
    readonly property real tabRoom: root.width - (root.artSays > 0 ? root.artSays + PrismTheme.dp(28) : PrismTheme.dp(96)) - card.slope
    // The rows of this group left iNiR's values that Restore may put back: said on the art, put back from there.
    readonly property var restorables: {
        const _ = PrismModel.revision
        return root.showPage ? [] : root.rows.filter(row => PrismModel.restorable(row))
    }
    PrismFolder {
        id: card
        visible: !root.bare
        width: root.width
        height: Math.max(root.naturalHeight, root.floor)
        rise: root.rise
        tabWidth: Math.min(root.tabNeed, root.tabRoom)
        tint: root.tint
        turn: root.number - 1
        // Its own art: the group's name and place drawn into the seed, so no two folders anywhere share a ribbon.
        seed: root.number * 2.3 + Array.from(root.title).reduce((n, letter) => (n * 31 + letter.charCodeAt(0)) % 9973, 7) * 0.013
        sayWidth: root.artSays > 0 ? root.artSays + PrismTheme.dp(24) : 0
    }

    // What the group holds now, printed on its art in a smoked glass pill (the Pink Sky card's tags).
    Rectangle {
        id: chipBox
        readonly property string say: root.chip
        visible: say.length > 0 && !root.bare
        x: root.width - width - PrismTheme.dp(12)
        y: Math.round((root.rise - height) / 2)
        z: 1
        // Laid out by hand from the text's own width: a Row here fed its width back through the box (polish loop).
        readonly property bool marked: root.chip.length > 0 && String(root.chipRow?.spec?.chipGlyph ?? "").length > 0
        readonly property real lead: chipBox.marked ? PrismTheme.dp(15) + PrismTheme.dp(6) : 0
        width: Math.min(chipBox.lead + chipText.implicitWidth + PrismTheme.dp(26), root.width * 0.42)
        height: PrismTheme.dp(30)
        radius: height / 2
        color: PrismTheme.spot
        PrismGlyph {
            visible: chipBox.marked
            x: PrismTheme.dp(13)
            anchors.verticalCenter: parent.verticalCenter
            text: String(root.chipRow?.spec?.chipGlyph ?? "")
            iconSize: PrismTheme.dp(15)
            color: PrismTheme.spotInk2
        }
        PrismText {
            id: chipText
            x: PrismTheme.dp(13) + chipBox.lead
            width: chipBox.width - x - PrismTheme.dp(13)
            anchors.verticalCenter: parent.verticalCenter
            text: chipBox.say
            color: PrismTheme.paper
            font.pixelSize: PrismTheme.small
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }

    // What this group changed, put back from its own folder: the count on the art, a press restores only these rows.
    PrismPill {
        id: resetBox
        visible: root.restorables.length > 0 && !root.bare
        z: 1
        x: (chipBox.visible ? chipBox.x - PrismTheme.dp(8) : root.width - PrismTheme.dp(12)) - width
        y: Math.round((root.rise - height) / 2)
        implicitHeight: PrismTheme.dp(30)
        tone: "dark"
        glyph: "restart_alt"
        text: Translation.tr("%1 changed").arg(root.restorables.length)
        Accessible.name: Translation.tr("Restore defaults")
        onClicked: IrisOptions.restore(root.restorables.map(row => row.spec))
    }

    Column {
        id: body
        x: root.pad
        width: root.inner
        spacing: 0

        // The head: the number and the name inside the tab, the line under it on the front sheet.
        Item {
            visible: !root.bare
            width: parent.width
            height: root.bare ? 0 : root.rise + (lineSaid.visible ? lineSaid.implicitHeight + PrismTheme.dp(2) : 0)
            PrismText {
                id: titleSaid
                y: Math.round((root.rise - height) / 2) + PrismTheme.dp(3)
                width: Math.max(0, card.tab - root.pad - x - PrismTheme.dp(14))
                text: root.title
                font.pixelSize: PrismTheme.head
                font.weight: Font.Bold
                font.letterSpacing: -0.2
                elide: Text.ElideRight
            }
            PrismText {
                id: lineSaid
                y: root.rise
                width: parent.width
                visible: root.line.length > 0
                text: root.line
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.small
                wrapMode: Text.WordWrap
            }
        }
        Item { width: 1; height: root.bare ? 0 : root.scened || root.keys ? PrismTheme.dp(18) : PrismTheme.dp(10) }

        // The drawn keyboard heads its card whole; the keys left iNiR's go back at once from under it.
        Loader {
            active: root.keys
            visible: active
            width: body.width
            sourceComponent: Column {
                width: body.width
                spacing: PrismTheme.dp(10)
                IrisKeyboardMap {
                    id: keyMap
                    width: parent.width
                }
                Item {
                    visible: keyMap.changedCount > 0
                    width: parent.width
                    height: visible ? PrismTheme.dp(36) : 0
                    PrismPill {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        tone: "quiet"
                        glyph: "keyboard"
                        text: keyMap.changedCount === 1 ? Translation.tr("Restore 1 key") : Translation.tr("Restore %1 keys").arg(keyMap.changedCount)
                        onClicked: keyMap.restoreKeys()
                    }
                }
                Item { width: 1; height: PrismTheme.dp(8) }
            }
        }

        // The rows, and the picture beside them (or over them).
        Item {
            id: stage
            width: body.width
            readonly property real pictureHeight: !root.scened ? 0 : pictureBox.item ? pictureBox.item.implicitHeight : root.figureHeight
            height: root.beside ? Math.max(list.implicitHeight, stage.pictureHeight)
                : root.scened ? stage.pictureHeight + PrismTheme.dp(14) + list.implicitHeight : list.implicitHeight

            Loader {
                id: pictureBox
                active: root.scened
                visible: active
                x: root.beside ? body.width - root.figureWidth : 0
                // Beside the rows it keeps to the page's visible top while the card is read, never past its rows' end.
                y: !root.beside ? 0 : Math.round(Math.max(0, Math.min(stage.height - stage.pictureHeight,
                    root.viewTop - body.y - stage.y)))
                sourceComponent: Item {
                    width: root.figureWidth
                    implicitHeight: scene.height + (caption.visible ? PrismTheme.dp(8) + caption.implicitHeight : 0)
                    IrisGroupPreview {
                        id: scene
                        width: root.figureWidth
                        height: scene.cardHeight > 0 ? Math.min(root.figureHeight, Math.max(PrismTheme.dp(120), scene.cardHeight)) : root.figureHeight
                        radius: PrismTheme.dp(16)
                        framed: false
                        captionOutside: true
                        // Prism draws it with the animated previews off too, held still: a picture at rest costs nothing.
                        holdsStill: true
                        playing: root.active && root.seen
                        section: String(root.figure?.section ?? "")
                        group: String(root.figure?.group ?? "")
                        niriValue: (section, key) => CompositorConfig.value(IrisOptions.settings.find(spec => spec.comp === section && spec.key === key) ?? { comp: section, key: key })
                        niriRevision: CompositorConfig.revision
                    }
                    // Its part lit, the others numbered quietly: pointing at one names it, a press goes to its card.
                    PrismSpots {
                        id: marks
                        property string hovering: ""
                        width: scene.width
                        height: scene.height
                        radius: scene.radius
                        spots: scene.spots
                        groups: root.groups
                        pointed: marks.hovering
                        picked: root.entry
                        sayOf: title => PrismModel.glanceOf(root.groups.find(group => String(group.title) === title)).say
                        onPoint: title => marks.hovering = title
                        onPick: title => { if (title.length > 0 && title !== root.entry) root.goGroup(title) }
                    }
                    PrismText {
                        id: caption
                        y: scene.height + PrismTheme.dp(8)
                        width: parent.width
                        text: scene.caption
                        visible: text.length > 0
                        color: PrismTheme.ink2
                        font.pixelSize: PrismTheme.small
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideNone
                    }
                }
            }

            Column {
                id: list
                y: root.beside || !root.scened ? 0 : stage.pictureHeight + PrismTheme.dp(14)
                width: root.rowsWidth
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
                        width: list.width
                        readonly property string part: String(entry.modelData.rows[0].spec?.part ?? "")
                        // A search's hits come from many groups: a part's caption there would name one group's inside.
                        readonly property bool partStarts: !root.showPage && entry.part.length > 0
                            && (entry.modelData.first === 0 || String(root.rows[entry.modelData.first - 1]?.spec?.part ?? "") !== entry.part)
                        // A part's head as the specimen sheets print theirs (`.claude/ref/language`, micrographics): its
                        // name in small mono caps and a hairline running to the card's edge.
                        Item {
                            visible: entry.partStarts
                            width: list.width
                            height: partName.height + PrismTheme.dp(20)
                            PrismText {
                                id: partName
                                y: PrismTheme.dp(16)
                                width: Math.min(implicitWidth, parent.width * 0.7)
                                text: Translation.tr(entry.part).toUpperCase()
                                mono: true
                                color: PrismTheme.ink3
                                font.pixelSize: PrismTheme.caption - 1
                                font.letterSpacing: 0.8
                            }
                            Rectangle {
                                x: partName.width + PrismTheme.dp(12)
                                width: parent.width - x
                                height: 1
                                y: partName.y + Math.round(partName.height / 2)
                                color: PrismTheme.line
                            }
                        }
                        // Two rows of a line are two fixed places, never a Repeater over the line's list: the list is new on
                        // every write, and a Repeater would rebuild a level under the pointer mid-drag.
                        Row {
                            readonly property bool paired: entry.modelData.rows.length > 1
                            readonly property bool stackedPair: paired && entry.modelData.shape === "field"
                            spacing: root.gap
                            PrismRow {
                                width: parent.paired ? root.half : list.width
                                row: entry.modelData.rows[0]
                                stacked: parent.stackedPair
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
                                    controlWidth: second.stackedPair ? root.half : PrismTheme.dp(64)
                                    flash: root.flashPath === row.path
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
