import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// A group of rows as the reference's chart: eyebrow and title, the column heads, hairline rows; past `fold` rows the
// rest wait behind "See all".
Column {
    id: root
    property string eyebrow: ""
    property string title: ""
    property var rows: []
    property bool heads: true
    property bool showPage: false
    property int fold: 6
    property int firstNumber: 1
    property string flashPath: ""
    property bool all: false

    readonly property bool folds: root.rows.length > root.fold + 1
    readonly property var shownRows: root.folds && !root.all ? root.rows.slice(0, root.fold) : root.rows
    // The chart's grey column only where the room holds it; otherwise what a row does sits under its name.
    readonly property real aboutWidth: root.width < PrismTheme.dp(980) ? 0 : Math.min(PrismTheme.dp(280), root.width * 0.26)
    readonly property real controlWidth: Math.min(PrismTheme.dp(300), root.width * 0.38)
    spacing: 0

    PrismHeading {
        width: root.width
        eyebrow: root.eyebrow
        title: root.title
        titleSize: PrismTheme.title * 0.86
        link: root.folds ? (root.all ? Translation.tr("Show less") : Translation.tr("See all")) : ""
        onLinkClicked: root.all = !root.all
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

    Repeater {
        model: root.shownRows
        delegate: Column {
            id: entry
            required property var modelData
            required property int index
            width: root.width
            PrismRow {
                width: parent.width
                row: entry.modelData
                number: root.firstNumber + entry.index
                showPage: root.showPage
                aboutWidth: root.aboutWidth
                controlWidth: root.controlWidth
                flash: root.flashPath === entry.modelData.path
            }
            Rectangle {
                visible: entry.index < root.shownRows.length - 1
                width: parent.width
                height: 1
                color: PrismTheme.line
            }
        }
    }
}
