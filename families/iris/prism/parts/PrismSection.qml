import QtQuick
import Quickshell
import qs.services
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// A group of rows as the reference's chart: eyebrow and title, the column heads, hairline rows, every row in sight; a
// part of the group gets its own caption.
Column {
    id: root
    property string eyebrow: ""
    property string title: ""
    property var rows: []
    property bool heads: true
    property bool showPage: false
    property int firstNumber: 1
    property string flashPath: ""
    // A figure at the head's right that is not a link: where this group stands among the page's ("03 / 12").
    property string note: ""
    // Search and Changes: a press on a row's name opens it where it lives.
    signal reach(var row)
    // Every row of the group is on the page: a fold behind "N more" cost a press to reach what was asked for (his 11-07).
    readonly property var shownRows: root.rows
    // The chart's grey column only where the room holds it; otherwise what a row does sits under its name.
    readonly property real aboutWidth: root.width < PrismTheme.dp(980) ? 0 : Math.min(PrismTheme.dp(280), root.width * 0.26)
    readonly property real controlWidth: Math.min(PrismTheme.dp(300), root.width * 0.38)
    spacing: 0

    PrismHeading {
        width: root.width
        eyebrow: root.eyebrow
        title: root.title
        titleSize: PrismTheme.title * 0.86
        note: root.note
    }
    Item { width: 1; height: PrismTheme.dp(14) }

    // Column heads, as the chart's "# Name Song Artist Time".
    Item {
        visible: root.heads
        width: root.width
        height: PrismTheme.dp(30)
        Repeater {
            model: [
                { t: "#", x: 0 },
                { t: Translation.tr("Setting"), x: PrismTheme.dp(30) + PrismTheme.dp(36) + PrismTheme.dp(14) },
                { t: root.aboutWidth > 0 ? Translation.tr("What it does") : "", x: root.width - PrismTheme.dp(56) - PrismTheme.dp(8) - root.controlWidth - PrismTheme.dp(20) - root.aboutWidth },
                { t: Translation.tr("Now"), x: root.width - PrismTheme.dp(64), right: true }
            ]
            delegate: PrismText {
                required property var modelData
                x: modelData.right ? modelData.x - width : modelData.x
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.t
                color: PrismTheme.ink3
                font.pixelSize: PrismTheme.small
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: PrismTheme.line }
    }

    // A write changes Config.revision and with it every row list; the model keys rows by `key` so a value changing
    // keeps every row's delegate (a plain array rebuilt the whole page on each click, and a handler still running in
    // a row that was gone read "root is not defined").
    Repeater {
        model: ScriptModel { objectProp: "key"; values: root.shownRows }
        delegate: Column {
            id: entry
            required property var modelData
            required property int index
            width: root.width
            readonly property string part: String(entry.modelData.spec?.part ?? "")
            // A search's hits come from many groups: a part's caption there would name one group's inside.
            readonly property bool partStarts: !root.showPage && entry.part.length > 0 && (entry.index === 0 || String(root.shownRows[entry.index - 1]?.spec?.part ?? "") !== entry.part)
            PrismText {
                visible: entry.partStarts
                topPadding: entry.index === 0 ? PrismTheme.dp(10) : PrismTheme.dp(18)
                bottomPadding: PrismTheme.dp(4)
                text: Translation.tr(entry.part)
                color: PrismTheme.ink3
                font.pixelSize: PrismTheme.small
                font.weight: Font.DemiBold
            }
            PrismRow {
                width: parent.width
                row: entry.modelData
                number: root.firstNumber + entry.index
                showPage: root.showPage
                aboutWidth: root.aboutWidth
                controlWidth: root.controlWidth
                flash: root.flashPath === entry.modelData.path
                onOpenRequested: root.reach(entry.modelData)
            }
            Rectangle {
                visible: entry.index < root.shownRows.length - 1 && (root.showPage || String(root.shownRows[entry.index + 1]?.spec?.part ?? "") === entry.part)
                width: parent.width
                height: 1
                color: PrismTheme.line
            }
        }
    }
}
