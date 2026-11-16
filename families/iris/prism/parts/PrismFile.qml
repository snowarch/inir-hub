import QtQuick
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// A folder that holds something other than rows (Home's widgets), so Home wears the same object as every group card
// (his 11-16: each part of Home spoke another language): the name on the tab, the art behind the step with its keys
// on it (`tools`), what it holds on the front sheet. Its height is its content's unless the host sets one.
Item {
    id: root
    property string title: ""
    property string tint: "grey"
    property int turn: 0
    property real seed: 0
    // What stands on the art at the right: a smoked key or pill.
    default property alias contents: inside.data
    property alias tools: toolBox.data

    readonly property real rise: PrismTheme.dp(50)
    readonly property real pad: PrismTheme.dp(20)
    readonly property real innerWidth: root.width - root.pad * 2
    readonly property real innerHeight: root.height - inside.y - root.pad
    implicitHeight: inside.y + inside.childrenRect.height + root.pad

    PrismFolder {
        id: folder
        anchors.fill: parent
        rise: root.rise
        tabWidth: Math.min(root.pad + name.implicitWidth + PrismTheme.dp(22), root.width - toolBox.width - PrismTheme.dp(28) - folder.slope)
        tint: root.tint
        turn: root.turn
        seed: root.seed
        sayWidth: toolBox.width > 0 ? toolBox.width + PrismTheme.dp(24) : 0
    }
    PrismText {
        id: name
        x: root.pad
        y: Math.round((root.rise - height) / 2) + PrismTheme.dp(3)
        width: Math.max(0, folder.tab - root.pad - PrismTheme.dp(14))
        text: root.title
        font.pixelSize: PrismTheme.head
        font.weight: Font.Bold
        font.letterSpacing: -0.2
        elide: Text.ElideRight
    }
    Item {
        id: toolBox
        z: 1
        x: root.width - width - PrismTheme.dp(12)
        y: Math.round((root.rise - height) / 2)
        width: childrenRect.width
        height: childrenRect.height
    }
    Item {
        id: inside
        x: root.pad
        y: root.rise + PrismTheme.dp(10)
        width: root.innerWidth
        height: childrenRect.height
    }
}
