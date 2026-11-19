pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// A page's head: its name large, what it is for under it, and at its right only what acts on the whole page (Restore
// defaults while something differs from iNiR's, the page's own key). Nothing else: the sidebar already says where
// the page lives.
Item {
    id: root
    property string title: ""
    property string line: ""
    // [{ id, glyph, text }]: the page's own keys, white.
    property var actions: []
    property bool restorable: false
    signal action(string id)
    signal restore()

    implicitHeight: Math.max(words.implicitHeight, keys.height)

    Column {
        id: words
        width: root.width - (keys.width > 0 ? keys.width + PrismTheme.dp(20) : 0)
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
    Row {
        id: keys
        anchors.right: parent.right
        anchors.bottom: words.bottom
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
                tone: "solid"
                glyph: String(modelData.glyph ?? "")
                text: Translation.tr(String(modelData.text ?? ""))
                onClicked: root.action(String(modelData.id))
            }
        }
    }
}
