pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.nihil.components
import qs.modules.nihil.style

Rectangle {
    id: root

    property var links: []
    // Every link opens on its identity mark, as every group row does: one grammar on the page.
    property bool tinted: true

    Layout.fillWidth: true
    implicitHeight: linkColumn.implicitHeight
    radius: 0
    color: IrisStyle.readingCard

    Column {
        id: linkColumn
        width: parent.width
        Repeater {
            model: root.links
            IrisLinkRow {
                required property var modelData
                required property int index
                entry: modelData
                tinted: root.tinted
                last: index === root.links.length - 1
            }
        }
    }
}
