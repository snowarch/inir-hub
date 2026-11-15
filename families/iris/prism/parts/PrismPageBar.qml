pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// Where a page's groups carry their own pictures: the page's two pills on its name's line (Restore defaults quiet, the
// page's show solid; `facts: false`), the screen's own facts in a bar under it (Display; `pills: false`). A bar of one
// pill alone under the name left a 44 px band empty. Nothing to say, no bar.
Item {
    id: root
    property var page: null
    property int restorable: 0
    property bool facts_: true
    property bool pills_: true
    signal restore()

    readonly property var facts: root.facts_ ? PrismModel.factsOf(String(root.page?.pageId ?? "")) : []
    readonly property bool says: root.facts.length > 0 || root.pills_ && (root.restorable > 0 || Boolean(root.page?.show))
    implicitHeight: root.says ? PrismTheme.dp(44) : 0
    implicitWidth: root.facts_ ? 0 : pills.width
    visible: root.says

    Row {
        anchors.verticalCenter: parent.verticalCenter
        width: (root.pills_ ? pills.x : parent.width) - PrismTheme.dp(16)
        spacing: PrismTheme.dp(18)
        clip: true
        Repeater {
            model: root.facts
            delegate: Row {
                required property var modelData
                spacing: PrismTheme.dp(6)
                PrismText { id: fact; text: modelData.say; color: PrismTheme.ink; font.pixelSize: PrismTheme.row; font.weight: Font.DemiBold }
                PrismText { anchors.baseline: fact.baseline; text: modelData.label; color: PrismTheme.ink3; font.pixelSize: PrismTheme.small }
            }
        }
    }
    Row {
        id: pills
        visible: root.pills_
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        spacing: PrismTheme.dp(8)
        PrismPill {
            visible: root.restorable > 0
            tone: "quiet"
            glyph: "restart_alt"
            text: Translation.tr("Restore defaults")
            onClicked: root.restore()
        }
        PrismPill {
            visible: Boolean(root.page?.show)
            tone: "solid"
            glyph: "play_arrow"
            text: Translation.tr(String(root.page?.show?.label ?? ""))
            onClicked: PrismModel.runShow(root.page)
        }
    }
}
