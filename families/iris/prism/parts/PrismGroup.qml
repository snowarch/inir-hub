import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// A group of a page: one smoked card, no outline, its name said once at its top (what it is for under it, its master
// switch at the end), its rows inside. Off, the group still shows what it holds, dimmed and still, so turning it on
// moves nothing. A card made of several one-row groups (PrismShelf.merge) lists them as rows under its band's name.
Item {
    id: root
    // { title, rows, titles }
    property var entry: ({ title: "", rows: [] })
    property string flashPath: ""
    readonly property string title: String(root.entry?.title ?? "")
    // Every group this card holds: a search for one of them lands here.
    readonly property var titles: Array.from(root.entry?.titles ?? [root.title])

    readonly property real pad: PrismTheme.dp(20)
    readonly property bool headed: root.title.length > 0
    readonly property real rowsY: root.headed ? root.pad + head.implicitHeight + PrismTheme.dp(8) : PrismTheme.dp(6)
    readonly property var bodyRows: root.headed ? head.bodyRows : Array.from(root.entry?.rows ?? [])
    implicitHeight: root.rowsY + (root.bodyRows.length > 0 ? rows.implicitHeight + PrismTheme.dp(8) : PrismTheme.dp(12))

    Rectangle {
        anchors.fill: parent
        radius: PrismTheme.cardRadius
        color: PrismTheme.card
    }
    PrismGroupHead {
        id: head
        visible: root.headed
        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad
        entry: root.entry
    }
    PrismSection {
        id: rows
        // Narrow, a field's control goes under its name.
        compact: root.width < PrismTheme.dp(520)
        x: root.pad
        y: root.rowsY
        width: root.width - 2 * root.pad
        title: root.title
        rows: root.bodyRows
        headlessKey: root.headed ? head.headlessKey : ""
        enabled: head.on
        opacity: head.on ? 1 : 0.38
        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
        flashPath: root.flashPath
    }
}
