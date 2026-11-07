import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls
import qs.modules.iris.prism.fx

// A page's hero: the refraction art with its glass card, what the page holds now in big type on the left, and the two
// pills of the reference: the page's own action (white) and Restore defaults (smoked).
Item {
    id: root
    property var page: null
    property int number: 1
    property int count: 0
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
        // The ruler: a tick per row of the page, the changed ones taller.
        Row {
            id: ruler
            x: PrismTheme.dp(12)
            y: parent.height * 0.5
            spacing: Math.max(2, (parent.width - PrismTheme.dp(24) - root.count) / Math.max(1, root.count - 1))
            Repeater {
                model: root.count
                delegate: Rectangle {
                    required property int index
                    width: 1
                    height: index < root.changed.length ? PrismTheme.dp(9) : PrismTheme.dp(4)
                    anchors.bottom: parent.bottom
                    color: Qt.rgba(0.08, 0.08, 0.1, index < root.changed.length ? 0.9 : 0.45) // iris-literal: Prism's own ink over its art, the same in every scheme
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
                model: [String(root.page?.pageId ?? "").toUpperCase(), "NO." + root.number, Translation.tr("%1 changed").arg(root.changed.length).toUpperCase()]
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

    // What the page holds now: its leading values as the title, their names as the eyebrow.
    Column {
        x: PrismTheme.dp(28)
        y: PrismTheme.dp(26)
        width: art.card.x - x - PrismTheme.dp(24)
        spacing: PrismTheme.dp(4)
        PrismText {
            width: parent.width
            text: root.lead.map(row => Translation.tr(row.label)).join(" · ")
            color: Qt.rgba(1, 1, 1, 0.56) // iris-literal: Prism's own ink over its art, the same in every scheme
            font.pixelSize: PrismTheme.body
        }
        Repeater {
            model: root.lead
            delegate: PrismText {
                required property var modelData
                width: parent.width
                text: PrismModel.sayNow(modelData)
                color: PrismTheme.paper
                font.pixelSize: PrismTheme.display
                font.weight: Font.Bold
                font.letterSpacing: -0.6
            }
        }
    }

    Row {
        x: PrismTheme.dp(28)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PrismTheme.dp(26)
        spacing: PrismTheme.dp(10)
        PrismPill {
            readonly property bool acts: Boolean(root.page?.show)
            tone: "art"
            glyph: acts ? "play_arrow" : "restart_alt"
            text: acts ? Translation.tr(root.page.show.label) : Translation.tr("Restore defaults")
            enabled_: acts || root.changed.length > 0
            onClicked: acts ? PrismModel.runShow(root.page) : root.restore()
        }
        PrismPill {
            visible: Boolean(root.page?.show)
            tone: "dark"
            text: Translation.tr("Restore defaults")
            enabled_: root.changed.length > 0
            onClicked: root.restore()
        }
    }
}
