import QtQuick
import qs.modules.iris.style
import qs.modules.iris.components

// Folio's group head: the group's glyph and name in its colour, a step bolder than its rows, over the plate that holds them.
// It was spaced mono capitals a tone down with a hairline to the edge: a label the eye skipped, never a name it read.
Item {
    id: root
    property Item host
    readonly property real d: IrisStyle.settingsDensity
    readonly property bool lone: root.host?.lone ?? false
    readonly property real line: Math.max(Math.round(22 * root.d), root.lone ? Number(root.host?.switchHeight ?? 0) : 0)
    implicitHeight: root.line

    // A step up in size and weight from the rows: the anchor the eye jumps between (his 10-30), in a widget's head voice.
    IrisGroupTitle {
        anchors.verticalCenter: parent.verticalCenter
        maxWidth: parent.width - (root.lone ? Math.round(64 * root.d) : 0)
        text: String(root.host?.title ?? "")
        glyph: String(root.host?.glyph ?? "settings")
        tint: root.host?.tint ?? IrisStyle.identity.gray
    }
}
