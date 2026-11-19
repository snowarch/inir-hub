pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.fx
import qs.modules.iris.prism.controls

// A page's head (B · Carpeta's page card): the page's art across the top in the desktop's colours, turned per page so
// neighbours never lead with one colour; on its calm floor the page's name, large, and at the right the machine's own
// fact when the page has one (the charge, what the screen can). Under the art what the page is for, and only what acts
// on the whole page (Restore defaults while something differs from iNiR's, the page's own key). A long name in a long
// language shrinks to the art's width; it is never cut. A search has no art: its words alone.
Item {
    id: root
    property string title: ""
    property string line: ""
    // Where the page lives: its caption in the sidebar.
    property string eyebrow: ""
    property string tint: "grey"
    property int turn: 0
    // The machine's own fact: { say, label }, or null.
    property var fact: null
    // Home: the person stands before their name.
    property bool person: false
    // A search: words alone, no art.
    property bool plain: false
    // [{ id, glyph, text }]: the page's own keys, white.
    property var actions: []
    property bool restorable: false
    signal action(string id)
    signal restore()

    readonly property real pad: PrismTheme.dp(24)
    readonly property real artHeight: root.plain ? 0 : Math.max(PrismTheme.dp(196), words.implicitHeight + PrismTheme.dp(76))
    readonly property bool told: root.fact !== null && String(root.fact?.say ?? "").length > 0
    implicitHeight: root.plain ? plainWords.implicitHeight : root.artHeight

    PrismFlow {
        id: art
        visible: !root.plain
        width: root.width
        height: root.artHeight
        radius: PrismTheme.cardRadius
        tint: root.tint
        turn: root.turn
        seed: 0.11 + root.turn * 0.37
        // The light gathers high at the right and dies before the words at the foot.
        centre: Qt.point(0.74, 0.2)
        thickness: 0.5
        fade: 0.5
        // The left third stays calm: where the page lives and its name read on the plain ground.
        side: 0.38
        strength: PrismTheme.light ? 0.8 : 1
    }
    PrismText {
        visible: !root.plain && root.eyebrow.length > 0
        x: root.pad
        y: PrismTheme.dp(20)
        width: root.width * 0.5
        text: root.eyebrow
        color: PrismTheme.ink2
        font.pixelSize: PrismTheme.small
        font.weight: Font.DemiBold
        font.letterSpacing: PrismTheme.small * 0.04
    }
    // On the art's calm floor: the name, large, and what the page is for under it.
    Column {
        id: words
        visible: !root.plain
        x: root.pad
        anchors.bottom: art.bottom
        anchors.bottomMargin: PrismTheme.dp(20)
        width: root.width - 2 * root.pad - (side.width > 0 ? side.width + PrismTheme.dp(24) : 0)
        spacing: PrismTheme.dp(4)
        Row {
            width: parent.width
            spacing: PrismTheme.dp(14)
            PrismAvatar {
                id: avatar
                visible: root.person
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: PrismTheme.dp(52)
            }
            PrismText {
                width: parent.width - (avatar.visible ? avatar.width + parent.spacing : 0)
                height: Math.round(PrismTheme.display * 1.2)
                anchors.verticalCenter: parent.verticalCenter
                text: root.title
                font.pixelSize: PrismTheme.display
                font.weight: Font.Bold
                font.letterSpacing: -PrismTheme.display * 0.02
                // A long word in a long language takes a smaller size, never an ellipsis.
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: Math.round(PrismTheme.display * 0.55)
                elide: Text.ElideNone
            }
        }
        PrismText {
            visible: root.line.length > 0
            width: parent.width
            text: root.line
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.body
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            lineHeight: 1.1
        }
    }
    // At the right of the floor: the machine's own fact, then what acts on the whole page.
    Column {
        id: side
        visible: !root.plain && (root.told || keys.width > 0)
        anchors.right: art.right
        anchors.rightMargin: root.pad
        anchors.bottom: art.bottom
        anchors.bottomMargin: PrismTheme.dp(20)
        width: visible ? Math.min(root.width * 0.4, Math.max(keys.width, root.told ? Math.max(factSay.implicitWidth, factLabel.implicitWidth) : 0)) : 0
        spacing: PrismTheme.dp(12)
        Column {
            visible: root.told
            width: parent.width
            spacing: PrismTheme.dp(2)
            PrismText {
                id: factLabel
                width: parent.width
                horizontalAlignment: Text.AlignRight
                text: String(root.fact?.label ?? "")
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.small
            }
            PrismText {
                id: factSay
                width: parent.width
                horizontalAlignment: Text.AlignRight
                text: String(root.fact?.say ?? "")
                figures: true
                font.pixelSize: PrismTheme.dp(26)
                font.weight: Font.Bold
            }
        }
        Row {
            id: keys
            anchors.right: parent.right
            spacing: PrismTheme.dp(8)
            PrismPill {
                visible: root.restorable
                tone: "quiet"
                glyph: "restart_alt"
                text: Translation.tr("Restore defaults")
                onClicked: root.restore()
            }
            Repeater {
                model: root.actions
                delegate: PrismPill {
                    required property var modelData
                    tone: "art"
                    glyph: String(modelData.glyph ?? "")
                    text: Translation.tr(String(modelData.text ?? ""))
                    onClicked: root.action(String(modelData.id))
                }
            }
        }
    }

    // A search: what was asked, and what answers it.
    Column {
        id: plainWords
        visible: root.plain
        width: root.width
        spacing: PrismTheme.dp(4)
        PrismText {
            width: parent.width
            text: root.title
            font.pixelSize: PrismTheme.title
            font.weight: Font.Bold
            font.letterSpacing: -PrismTheme.title * 0.025
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }
        PrismText {
            width: parent.width
            visible: root.line.length > 0
            text: root.line
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.body
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }
    }
}
