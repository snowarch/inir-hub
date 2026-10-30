import QtQuick
import qs.modules.iris.style
import qs.modules.iris.components

// Folio's group head: the group's name in the ink, a step bolder than its rows, over the plate that holds them.
// It was spaced mono capitals a tone down with a hairline to the edge: a label the eye skipped, never a name it read.
Item {
    id: root
    property Item host
    readonly property real d: IrisStyle.settingsDensity
    readonly property bool lone: root.host?.lone ?? false
    readonly property real line: Math.max(Math.round(22 * root.d), root.lone ? Number(root.host?.switchHeight ?? 0) : 0)
    implicitHeight: root.line

    IrisText {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - (root.lone ? Math.round(64 * root.d) : 0)
        elide: Text.ElideRight
        text: String(root.host?.title ?? "")
        color: IrisStyle.text
        font.family: IrisStyle.fontTitle
        // A step up in size and weight from the rows (now Medium): the anchor the eye jumps between (his 10-30).
        font.pixelSize: IrisStyle.typeHeadline
        font.weight: IrisStyle.weight(Font.Bold)
        Accessible.role: Accessible.Heading
    }
}
