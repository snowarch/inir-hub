import QtQuick
import qs.modules.iris.style
import qs.modules.iris.components

// Drawer's group head: its glyph and name in its colour, a hairline running to the column's edge; a lone switch keeps its line.
Item {
    id: root
    property Item host
    readonly property real d: IrisStyle.settingsDensity
    readonly property bool lone: root.host?.lone ?? false
    readonly property real line: Math.max(Math.round(24 * root.d), root.lone ? Number(root.host?.switchHeight ?? 0) : 0)
    implicitHeight: root.line

    IrisGroupTitle {
        id: name
        anchors.verticalCenter: parent.verticalCenter
        maxWidth: parent.width - (root.lone ? Math.round(64 * root.d) : 0)
        size: IrisStyle.typeBody
        text: String(root.host?.title ?? "")
        glyph: String(root.host?.glyph ?? "settings")
        tint: root.host?.tint ?? IrisStyle.identity.gray
        opacity: root.lone || (root.host?.reading ?? false) ? 1 : 0.72
        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
    }
    Rectangle {
        visible: !root.lone
        anchors.verticalCenter: parent.verticalCenter
        x: name.x + name.width + Math.round(12 * root.d)
        width: Math.max(0, parent.width - x)
        height: 1
        color: IrisStyle.hairline
    }
}
