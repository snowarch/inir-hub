import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.iris.style
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls
import qs.modules.iris.prism.fx

// A group of rows as one card (Raell Tech's keyboard and mouse page, his 11-14: `.claude/ref/iris-prism/raell-keyboard-mouse.png`):
// its mark, its name and a line under it, a chip at the right that says what it holds now, and its rows inside. Where
// the card is wide enough, two fields in a row (text, levels, short choices) stand side by side with the name over the
// control, and two switches share a line; everything else takes the card's whole width. A part of the group gets its
// own caption.
// The drawn keyboard heads its card whole; no group wears a live scene (the page's drawn object stands on its art).
Item {
    id: root
    property string title: ""
    // { keys, row } for the drawn keyboard, or null (PrismModel.figureOf).
    property var figure: null
    // The page's groups, and this card's entry among them (a band's title on banded pages): its turn of the art.
    property var groups: []
    property string entry: ""
    readonly property int number: root.groups.findIndex(group => String(group.title) === root.entry) + 1
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
    // The form a group wears on the page's grid (his 11-17: not every group the same folder card). "folder": the tab and
    // its art, for a group with a picture; "card": a sheet lit from its top edge with its value set big (card-taskello);
    // "sheet": a plain smoked sheet for a long list; "slip": a slim sheet for one or two rows.
    // "module": the Board's instrument (design D3), its name in mono caps, its value large, its switch at the corner.
    property string form: "folder"
    readonly property bool foldered: !root.bare && root.form === "folder"
    readonly property bool moduled: !root.bare && root.form === "module"
    // A group whose first row is a switch named as the group (Do Not Disturb, Night light) wears that switch at its
    // head's corner, its description under the name: the row itself never stood as a nameless line (his 11-17).
    readonly property var master: !root.bare && !root.foldered && !root.showPage && root.rows.length >= 2
        && root.rows[0].kind === "switch" && String(root.rows[0].label) === String(root.rows[0].section ?? "") ? root.rows[0] : null
    readonly property var listed: root.master ? root.rows.slice(1) : root.rows
    // What a card sets big: the group's value now, and the level it comes from, whose own figure it takes (said once);
    // while that level is dragged, the figure follows the hand.
    property string figureSay: ""
    property var figureRow: null
    property string liveSay: ""
    function said(row: var): bool { return root.figureRow !== null && String(row?.key ?? "") === String(root.figureRow.key) }
    // A part of the group (its spec's), or the group a row was folded in from on the Board (PrismPanel.boardModules).
    function partOf(row: var): string { return String(row?.part ?? row?.spec?.part ?? "") }
    // A module named as its page (Keyboard on Keyboard) under the page's own name: its credit would say it twice.
    property bool echoed: false
    readonly property real naturalHeight: body.implicitHeight + root.pad - PrismTheme.dp(8)
    readonly property real pad: root.bare ? 0 : PrismTheme.dp(24)
    readonly property real inner: root.width - root.pad * 2

    readonly property bool keys: Boolean(root.figure?.keys)
    readonly property real rowsWidth: root.inner

    readonly property real gap: PrismTheme.dp(28)
    readonly property bool twoUp: !root.showPage && root.rowsWidth >= PrismTheme.dp(640)
    readonly property real half: Math.floor((root.rowsWidth - root.gap) / 2)
    readonly property real controlWidth: Math.min(PrismTheme.dp(300), root.rowsWidth * 0.4)
    readonly property real halfControl: Math.min(PrismTheme.dp(260), root.half * 0.45)
    // A module one column wide sets its levels and fields under their names, as wide as the module (design D3).
    readonly property bool narrow: root.moduled && root.rowsWidth < PrismTheme.dp(440)
    function stackOf(row: var): bool { return root.narrow && ["range", "text", "hue"].includes(String(row?.kind ?? "")) }
    // A module the shelf's whole width sets its one-line rows (a switch, a plain choice) two to a line, each with its
    // control at its half's end, as D3's Apps: a row across the window leaves its name and control far apart.
    readonly property bool wide: root.moduled && root.rowsWidth >= PrismTheme.dp(860)
    function lineOf(row: var): bool {
        const kind = String(row?.kind ?? "")
        if (kind === "switch") return true
        return kind === "choice" && row.spec?.cards !== "island" && !row.spec?.flags
            && !PrismModel.choicesOf(row).some(choice => choice.swatch !== undefined && choice.swatch !== null)
    }

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
        const list = root.listed
        for (let i = 0; i < list.length; i++) {
            const row = list[i]
            const next = list[i + 1]
            const shape = root.twoUp ? root.shapeOf(row) : ""
            const together = next && root.partOf(next) === root.partOf(row)
            if (shape.length > 0 && together && root.shapeOf(next) === shape) {
                out.push({ key: row.key + "+" + next.key, rows: [row, next], shape: shape, first: i })
                i++
            } else if (root.wide && together && root.lineOf(row) && root.lineOf(next)) {
                out.push({ key: row.key + "+" + next.key, rows: [row, next], shape: "line", first: i })
                i++
            } else out.push({ key: row.key, rows: [row], shape: "", first: i })
        }
        return out
    }

    implicitHeight: root.bare ? body.implicitHeight : root.boxHeight

    // The tab holds the number and the name on one line, with air; the art takes the rest of the top.
    readonly property real rise: root.form === "folder" ? PrismTheme.dp(50) : root.form === "card" ? PrismTheme.dp(46)
        : root.form === "sheet" ? PrismTheme.dp(56) : root.moduled ? (root.echoed && !root.master ? PrismTheme.dp(14) : PrismTheme.dp(46)) : PrismTheme.dp(40)
    readonly property real slope: Math.round(root.rise * 1.25)
    readonly property real cardRadius: root.form === "slip" || root.moduled ? PrismTheme.dp(22) : PrismTheme.dp(24)
    readonly property real tab: Math.max(root.cardRadius * 2, Math.min(Math.min(root.tabNeed, root.tabRoom), root.width - root.slope - root.cardRadius * 2))
    readonly property real tabNeed: root.pad + titleSaid.implicitWidth + PrismTheme.dp(22)
    // What stands on the art (the chip, the group's own restore) keeps its room; the tab never squeezes the art under a sliver.
    readonly property real artSays: (chipBox.visible ? chipBox.width : 0) + (masterBox.visible ? masterBox.width : 0)
        + (resetBox.visible ? resetBox.width + (chipBox.visible || masterBox.visible ? PrismTheme.dp(8) : 0) : 0)
    readonly property real tabRoom: root.width - (root.artSays > 0 ? root.artSays + PrismTheme.dp(28) : PrismTheme.dp(96)) - root.slope
    // The rows of this group left iNiR's values that Restore may put back: said on the art, put back from there.
    readonly property var restorables: {
        const _ = PrismModel.revision
        return root.showPage ? [] : root.rows.filter(row => PrismModel.restorable(row))
    }
    readonly property real seedOf: root.number * 2.3 + Array.from(root.title).reduce((n, letter) => (n * 31 + letter.charCodeAt(0)) % 9973, 7) * 0.013
    readonly property real boxHeight: Math.max(root.naturalHeight, root.floor)
    Loader {
        id: folderBox
        active: root.foldered
        visible: active
        sourceComponent: PrismFolder {
            width: root.width
            height: root.boxHeight
            rise: root.rise
            tabWidth: Math.min(root.tabNeed, root.tabRoom)
            tint: root.tint
            turn: root.number - 1
            // Its own art: the group's name and place drawn into the seed, so no two folders anywhere share a ribbon.
            seed: root.seedOf
            sayWidth: root.artSays > 0 ? root.artSays + PrismTheme.dp(24) : 0
        }
    }
    // Card, sheet and slip: one smoked sheet, no tab; a card's art is light coming in at its top edge, fading before
    // its rows, the value printed on it big.
    Loader {
        active: !root.bare && !root.foldered
        visible: active
        sourceComponent: ClippingRectangle {
            width: root.width
            height: root.boxHeight
            radius: root.cardRadius
            color: PrismTheme.card
            // A slip's art is its spine (Délavé's dividers): a band of the page's colours down its left edge.
            PrismFlow {
                visible: root.form === "slip"
                width: PrismTheme.dp(7)
                height: parent.height
                tint: root.tint
                turn: root.number
                seed: root.seedOf
                centre: Qt.point(0.5, 0.35)
                thickness: 0.9
            }
            PrismFlow {
                visible: root.form === "card"
                width: parent.width
                height: Math.min(parent.height, root.rise + PrismTheme.dp(64))
                tint: root.tint
                turn: root.number
                seed: root.seedOf
                centre: Qt.point(0.7, 0.05)
                thickness: 0.55
                fade: 0.18
                bare: true
                mute: 0.12
                opacity: PrismTheme.light ? 0.4 : 0.62
            }
        }
    }

    // What the group holds now, printed on its art in a smoked glass pill (the Pink Sky card's tags).
    Rectangle {
        id: chipBox
        readonly property string say: root.chip
        visible: say.length > 0 && !root.bare && root.form !== "card" && !root.moduled && root.master === null
        x: root.width - width - PrismTheme.dp(12)
        y: root.form === "slip" ? PrismTheme.dp(8) : Math.round((root.rise - height) / 2)
        color: root.foldered ? PrismTheme.spot : PrismTheme.fill
        z: 1
        // Laid out by hand from the text's own width: a Row here fed its width back through the box (polish loop).
        readonly property bool marked: root.chip.length > 0 && String(root.chipRow?.spec?.chipGlyph ?? "").length > 0
        readonly property real lead: chipBox.marked ? PrismTheme.dp(15) + PrismTheme.dp(6) : 0
        width: Math.min(chipBox.lead + chipText.implicitWidth + PrismTheme.dp(26), root.width * 0.42)
        height: PrismTheme.dp(30)
        radius: height / 2
        PrismGlyph {
            visible: chipBox.marked
            x: PrismTheme.dp(13)
            anchors.verticalCenter: parent.verticalCenter
            text: String(root.chipRow?.spec?.chipGlyph ?? "")
            iconSize: PrismTheme.dp(15)
            color: root.foldered ? PrismTheme.spotInk2 : PrismTheme.ink2
        }
        PrismText {
            id: chipText
            x: PrismTheme.dp(13) + chipBox.lead
            width: chipBox.width - x - PrismTheme.dp(13)
            anchors.verticalCenter: parent.verticalCenter
            text: chipBox.say
            color: root.foldered ? PrismTheme.paper : PrismTheme.ink
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
        x: (chipBox.visible ? chipBox.x - PrismTheme.dp(8) : masterBox.visible ? masterBox.x - PrismTheme.dp(10) : root.width - PrismTheme.dp(12)) - width
        y: root.form === "slip" ? PrismTheme.dp(8) : root.moduled ? PrismTheme.dp(12) : Math.round((root.rise - height) / 2)
        implicitHeight: PrismTheme.dp(30)
        tone: "dark"
        glyph: "restart_alt"
        text: Translation.tr("%1 changed").arg(root.restorables.length)
        Accessible.name: Translation.tr("Restore defaults")
        onClicked: IrisOptions.restore(root.restorables.map(row => row.spec))
    }

    // The group's own switch at its head's corner.
    PrismSwitch {
        id: masterBox
        visible: root.master !== null
        z: 1
        // In line with the rows' own switches.
        x: root.width - root.pad - width
        y: root.form === "slip" ? PrismTheme.dp(11) : root.moduled ? PrismTheme.dp(13) : Math.round((root.rise - height) / 2) + PrismTheme.dp(2)
        checked: root.master ? Boolean(PrismModel.read(root.master)) : false
        Accessible.name: root.title
        onToggled: value => PrismModel.write(root.master, value)
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
            height: root.bare ? 0 : lineSaid.y + (lineSaid.visible ? lineSaid.implicitHeight + PrismTheme.dp(2) : 0)
            // Folder and sheet: the name, bold; in a folder it stands in the tab.
            PrismText {
                id: titleSaid
                visible: root.form === "folder" || root.form === "sheet"
                y: Math.round((root.rise - height) / 2) + (root.foldered ? PrismTheme.dp(3) : PrismTheme.dp(2))
                width: root.foldered ? Math.max(0, root.tab - root.pad - x - PrismTheme.dp(14))
                    : Math.max(0, parent.width - root.artSays - PrismTheme.dp(16))
                text: root.title
                font.pixelSize: root.form === "sheet" ? PrismTheme.head + PrismTheme.dp(2) : PrismTheme.head
                font.weight: Font.Bold
                font.letterSpacing: root.form === "sheet" ? -0.4 : -0.2
                elide: Text.ElideRight
            }
            // Card and slip: the name printed small in mono caps, as a specimen sheet credits its plate.
            PrismText {
                id: creditSaid
                visible: root.form === "card" || root.form === "slip" || (root.moduled && !(root.echoed && !root.master))
                y: root.form === "card" ? PrismTheme.dp(20) : root.moduled ? PrismTheme.dp(19) : PrismTheme.dp(16)
                width: Math.max(0, parent.width - root.artSays - PrismTheme.dp(16))
                text: root.title.toUpperCase()
                mono: true
                color: root.form === "card" && !PrismTheme.light ? PrismTheme.paper : PrismTheme.ink
                font.pixelSize: PrismTheme.caption
                font.weight: Font.DemiBold
                font.letterSpacing: 0.9
                elide: Text.ElideRight
            }
            // A card's value, big, on its light.
            PrismText {
                id: figureSaid
                visible: (root.form === "card" || root.moduled) && root.figureSay.length > 0
                y: root.rise - PrismTheme.dp(4)
                width: Math.min(implicitWidth, parent.width)
                text: root.liveSay.length > 0 ? root.liveSay : root.figureSay
                figures: true
                color: root.form === "card" && !PrismTheme.light ? PrismTheme.paper : PrismTheme.ink
                font.pixelSize: root.moduled ? PrismTheme.display + PrismTheme.dp(10) : PrismTheme.display + PrismTheme.dp(6)
                font.weight: Font.Bold
                font.letterSpacing: root.moduled ? -1.6 : -1.2
                elide: Text.ElideRight
            }
            PrismText {
                id: lineSaid
                readonly property string about: root.master ? String(root.master.spec?.description ?? root.master.detail ?? "") : ""
                y: root.rise + (figureSaid.visible ? figureSaid.height + PrismTheme.dp(2) : root.master && root.form !== "sheet" ? PrismTheme.dp(-6) : 0)
                width: parent.width - (root.master && !figureSaid.visible ? root.artSays + PrismTheme.dp(12) : 0)
                visible: text.length > 0
                maximumLineCount: 3
                text: root.line.length > 0 ? root.line : Translation.tr(lineSaid.about)
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.small
                wrapMode: Text.WordWrap
            }
        }
        Item { width: 1; height: root.bare || root.form === "slip" ? 0 : root.keys ? PrismTheme.dp(18) : root.moduled ? PrismTheme.dp(4) : PrismTheme.dp(10) }

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

        // The rows.
        Item {
            id: stage
            width: body.width
            height: list.implicitHeight

            Column {
                id: list
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
                        readonly property string part: root.partOf(entry.modelData.rows[0])
                        // A search's hits come from many groups: a part's caption there would name one group's inside.
                        readonly property bool partStarts: !root.showPage && entry.part.length > 0
                            && (entry.modelData.first === 0 || root.partOf(root.listed[entry.modelData.first - 1]) !== entry.part)
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
                            readonly property bool lined: paired && entry.modelData.shape === "line"
                            spacing: root.gap
                            PrismRow {
                                width: parent.paired ? root.half : list.width
                                row: entry.modelData.rows[0]
                                stacked: parent.stackedPair || root.stackOf(row)
                                beside: parent.paired
                                showPage: root.showPage
                                controlWidth: parent.stackedPair ? root.half : parent.lined ? root.halfControl : parent.paired ? PrismTheme.dp(64) : root.stackOf(row) ? list.width : root.controlWidth
                                flash: root.flashPath === row.path
                                said: root.said(row)
                                onLive: say => root.liveSay = say
                                onOpenRequested: root.reach(row)
                            }
                            Loader {
                                id: second
                                active: parent.paired
                                visible: active
                                readonly property bool stackedPair: parent.stackedPair
                                readonly property bool lined: parent.lined
                                sourceComponent: PrismRow {
                                    width: root.half
                                    row: entry.modelData.rows[1]
                                    stacked: second.stackedPair
                                    beside: true
                                    controlWidth: second.stackedPair ? root.half : second.lined ? root.halfControl : PrismTheme.dp(64)
                                    flash: root.flashPath === row.path
                                    said: root.said(row)
                                    onLive: say => root.liveSay = say
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
