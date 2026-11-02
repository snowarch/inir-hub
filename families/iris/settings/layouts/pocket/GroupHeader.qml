import QtQuick
import qs.modules.iris.style
import qs.modules.iris.components

// Pocket's group head: the group's glyph and name in its colour over its card, a widget's head; a lone switch
// keeps its line.
Item {
    id: root
    property Item host
    readonly property real d: IrisStyle.settingsDensity
    readonly property bool lone: root.host?.lone ?? false
    readonly property real line: Math.max(Math.round(20 * root.d), root.lone ? Number(root.host?.switchHeight ?? 0) : 0)
    implicitHeight: root.line

    IrisGroupTitle {
        anchors.verticalCenter: parent.verticalCenter
        maxWidth: parent.width - (root.lone ? Math.round(64 * root.d) : 0)
        size: IrisStyle.typeBody
        text: String(root.host?.title ?? "")
        glyph: String(root.host?.glyph ?? "settings")
        tint: root.host?.tint ?? IrisStyle.identity.gray
    }
}
