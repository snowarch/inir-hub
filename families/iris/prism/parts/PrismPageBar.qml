pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// Under a page's name, where its groups carry their own pictures: the screen's own facts at the left (Display), the
// page's two pills at the right (Restore defaults quiet, the page's show solid). Nothing to say, no bar.
Item {
    id: root
    property var page: null
    property int restorable: 0
    signal restore()

    readonly property var facts: PrismModel.factsOf(String(root.page?.pageId ?? ""))
    readonly property bool says: root.facts.length > 0 || root.restorable > 0 || Boolean(root.page?.show)
    implicitHeight: root.says ? PrismTheme.dp(44) : 0
    visible: root.says

    Row {
        anchors.verticalCenter: parent.verticalCenter
        width: pills.x - PrismTheme.dp(16)
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
