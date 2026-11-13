import QtQuick
import Quickshell
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls
import qs.modules.iris.prism.fx

// A page's hero: the refraction art with its glass card, what the page holds now in big type on the left, and the two
// pills of the reference: the page's own action (white) and Restore defaults (smoked).
Item {
    id: root
    property var page: null
    property int number: 1
    property int count: 0
    // Rows Restore defaults would put back: none, and the pill is not drawn.
    property int restorable: 0
    property var changed: []
    property var lead: []          // rows whose values make the title
    signal restore()

    implicitHeight: PrismTheme.dp(232)
    readonly property real cardSide: root.height * 0.74

    PrismRefraction {
        id: art
        anchors.fill: parent
        cornerRadius: PrismTheme.dp(24)
        cardRadius: PrismTheme.dp(16)
        // The card stands left of the right edge so the spectrum has room to leave it, as in the reference.
        card: Qt.rect(root.width * 0.7 - root.cardSide / 2, (root.height - root.cardSide) / 2 + PrismTheme.dp(10), root.cardSide, root.cardSide)
        source: Qt.point(0.18, 1.12)
        prismAt: Qt.point((card.x + card.width * 0.3) / Math.max(1, width), (card.y + card.height * 0.7) / Math.max(1, height))
    }

    // The card's print: mono labels and a ruler, like the reference's specimen card.
    Item {
        x: art.card.x
        y: art.card.y
        width: art.card.width
        height: art.card.height
        readonly property color printInk: Qt.rgba(0.08, 0.08, 0.1, 0.78) // iris-literal: Prism's own ink over its art, the same in every scheme
        PrismText {
            x: PrismTheme.dp(12); y: PrismTheme.dp(10)
            mono: true
            text: "IRIS.SETTINGS"
            color: parent.printInk
            font.pixelSize: PrismTheme.dp(8)
        }
        PrismText {
            anchors.right: parent.right; anchors.rightMargin: PrismTheme.dp(12); y: PrismTheme.dp(10)
            mono: true
            text: Translation.tr(root.page?.group ?? "").toUpperCase()
            color: PrismTheme.accent
            font.pixelSize: PrismTheme.dp(8)
            font.weight: Font.Bold
        }
        // The ruler: a tick per row of the page (a long page: one per few rows, as many as the cover holds with air
        // between them), the share changed taller.
        Row {
            id: ruler
            readonly property int ticks: Math.max(1, Math.min(root.count, Math.floor((parent.width - PrismTheme.dp(24)) / 4)))
            readonly property int tall: root.count > 0 ? Math.ceil(root.changed.length * ruler.ticks / root.count) : 0
            x: PrismTheme.dp(12)
            y: parent.height * 0.5
            spacing: Math.max(2, (parent.width - PrismTheme.dp(24) - ruler.ticks) / Math.max(1, ruler.ticks - 1))
            Repeater {
                model: ruler.ticks
                delegate: Rectangle {
                    required property int index
                    width: 1
                    height: index < ruler.tall ? PrismTheme.dp(9) : PrismTheme.dp(4)
                    anchors.bottom: parent.bottom
                    color: Qt.rgba(0.08, 0.08, 0.1, index < ruler.tall ? 0.9 : 0.45) // iris-literal: Prism's own ink over its art, the same in every scheme
                }
            }
        }
        PrismText {
            x: PrismTheme.dp(12); y: ruler.y + PrismTheme.dp(14)
            mono: true
            text: String(root.count).padStart(2, "0") + "." + String(root.changed.length).padStart(3, "0")
            color: parent.printInk
            font.pixelSize: PrismTheme.dp(8)
        }
        Column {
            x: PrismTheme.dp(12)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PrismTheme.dp(12)
            Repeater {
                model: ScriptModel { values: [String(root.page?.pageId ?? "").toUpperCase(), "NO." + root.number, Translation.tr("%1 changed").arg(root.changed.length).toUpperCase()] }
                delegate: PrismText {
                    required property string modelData
                    mono: true
                    text: modelData
                    color: Qt.rgba(0.08, 0.08, 0.1, 0.62) // iris-literal: Prism's own ink over its art, the same in every scheme
                    font.pixelSize: PrismTheme.dp(7)
                }
            }
        }
        PrismText {
            anchors.right: parent.right
            anchors.rightMargin: PrismTheme.dp(10)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PrismTheme.dp(2)
            text: Translation.tr(root.page?.name ?? "").charAt(0).toUpperCase() + root.number
            color: Qt.rgba(0.07, 0.07, 0.09, 0.86) // iris-literal: Prism's own ink over its art, the same in every scheme
            font.family: PrismTheme.fontMain
            font.pixelSize: root.cardSide * 0.34
            font.weight: Font.Black
            font.letterSpacing: -2
        }
    }

    // What the page holds now: each leading value with its name beside it ("Auto Auto" said nothing, his 11-10).
    Column {
        x: PrismTheme.dp(28)
        y: PrismTheme.dp(26)
        width: art.card.x - x - PrismTheme.dp(24)
        spacing: PrismTheme.dp(6)
        Repeater {
            model: root.lead
            delegate: Row {
                id: line
                required property var modelData
                width: parent.width
                spacing: PrismTheme.dp(12)
                PrismText {
                    id: said
                    width: Math.min(implicitWidth, line.width * 0.62)
                    elide: Text.ElideRight
                    text: line.modelData.fact ? line.modelData.say : PrismModel.sayNow(line.modelData)
                    color: PrismTheme.paper
                    font.pixelSize: PrismTheme.display
                    font.weight: Font.Bold
                    font.letterSpacing: -0.6
                }
                PrismText {
                    anchors.baseline: said.baseline
                    width: line.width - said.width - line.spacing
                    elide: Text.ElideRight
                    text: line.modelData.fact ? line.modelData.label : Translation.tr(line.modelData.label)
                    color: Qt.rgba(1, 1, 1, 0.56) // iris-literal: Prism's own ink over its art, the same in every scheme
                    font.pixelSize: PrismTheme.body
                }
            }
        }
    }

    // The pills keep clear of the card: when both words don't fit beside it (a long language), Restore defaults
    // becomes its round glyph.
    Row {
        id: pills
        x: PrismTheme.dp(28)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PrismTheme.dp(26)
        spacing: PrismTheme.dp(10)
        readonly property bool roomy: action.implicitWidth + pills.spacing + restoreWords.implicitWidth <= art.card.x - pills.x - PrismTheme.dp(18)
        PrismPill {
            id: action
            readonly property bool acts: Boolean(root.page?.show)
            tone: "art"
            glyph: acts ? "play_arrow" : "restart_alt"
            text: acts ? Translation.tr(root.page.show.label) : Translation.tr("Restore defaults")
            visible: acts || root.restorable > 0
            onClicked: acts ? PrismModel.runShow(root.page) : root.restore()
        }
        PrismPill {
            id: restoreWords
            visible: Boolean(root.page?.show) && pills.roomy && root.restorable > 0
            tone: "dark"
            text: Translation.tr("Restore defaults")
            onClicked: root.restore()
        }
        PrismRound {
            anchors.verticalCenter: parent.verticalCenter
            visible: Boolean(root.page?.show) && !pills.roomy && root.restorable > 0
            overArt: true
            smoked: true
            implicitWidth: PrismTheme.dp(34)
            glyph: "restart_alt"
            onClicked: root.restore()
        }
    }
}
