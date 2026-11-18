import QtQuick
import qs.modules.nihil.style

// One page in the rail: a glyph and its name, lit while open. `compact` keeps only the glyph.
NButton {
    id: root

    required property var entry
    property bool chosen: false
    property bool compact: false

    width: root.compact ? NihilStyle.s(46) : parent.width
    height: root.compact ? NihilStyle.s(46) : NihilStyle.s(42)
    x: root.compact ? (parent.width - width) / 2 : 0
    tone: "transparent"
    lit: root.chosen
    activeFocusOnTab: true
    Keys.onSpacePressed: root.clicked()
    Keys.onReturnPressed: root.clicked()
    Accessible.role: Accessible.PageTab
    Accessible.name: root.entry.label
    Accessible.selected: root.chosen

    NIcon {
        x: root.compact ? (root.width - width) / 2 : NihilStyle.s(15)
        anchors.verticalCenter: parent.verticalCenter
        text: root.entry.glyph
        size: NihilStyle.s(20)
        color: root.ink
    }
    NText {
        visible: !root.compact
        x: NihilStyle.s(47)
        width: root.width - x - NihilStyle.s(12)
        anchors.verticalCenter: parent.verticalCenter
        text: root.entry.label
        font.pixelSize: NihilStyle.textBody
        font.weight: root.chosen ? Font.DemiBold : Font.Medium
        color: root.ink
    }
    NFocus { shown: root.activeFocus; gap: NihilStyle.s(1) }
}
