import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// A group on the page (his 11-18): one card, its name said once in its head, what it is for under the name, its rows
// under that. No sheet count, no art behind every group: the page's head wears the art, the groups carry only what
// they hold, so ten groups never read as ten copies of one folder.
Item {
    id: root
    // { title, rows }
    property var entry: ({ title: "", rows: [] })
    property string tint: "grey"
    property int turn: 0
    property string flashPath: ""
    property int number: 0
    property int count: 0
    readonly property string title: String(root.entry?.title ?? "")

    readonly property real r: PrismTheme.dp(22)
    readonly property real padX: PrismTheme.dp(20)
    readonly property real padY: PrismTheme.dp(18)

    implicitHeight: root.padY + head.implicitHeight + (rows.rows.length > 0 ? PrismTheme.dp(8) + rows.implicitHeight : 0) + root.padY

    Rectangle {
        anchors.fill: parent
        radius: root.r
        color: PrismTheme.card
    }
    PrismGroupHead {
        id: head
        x: root.padX
        y: root.padY
        width: root.width - 2 * root.padX
        entry: root.entry
    }
    PrismSection {
        id: rows
        bare: true
        compact: true
        x: root.padX
        y: head.y + head.implicitHeight + PrismTheme.dp(8)
        width: root.width - 2 * root.padX
        title: root.title
        rows: head.on ? head.bodyRows : []
        headlessKey: head.headlessKey
        flashPath: root.flashPath
    }
}
