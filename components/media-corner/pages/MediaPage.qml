pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.iris.style
import qs.modules.iris.components

// A page that scrolls: its children stack in one column as wide as the page.
Flickable {
    id: root
    default property alias content: column.data
    property alias spacing: column.spacing
    readonly property real d: IrisStyle.density

    contentHeight: column.implicitHeight + Math.round(8 * root.d)
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    IrisScrollFeel {}
    ScrollBar.vertical: IrisScrollBar {}

    ColumnLayout {
        id: column
        width: root.width
        spacing: Math.round(22 * root.d)
    }
}
