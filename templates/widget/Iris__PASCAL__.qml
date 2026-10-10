pragma ComponentBehavior: Bound

// The iRiS face: a line on the Island's Desktop page. IrisStyle tokens and the Iris* parts only, so it
// follows the theme, the density and the type ladder like the rest of the Island.

import QtQuick
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components

Item {
    id: root

    // Given by the Island: where the module sits and which screen it is on.
    property string irisSlot: ""
    property var targetScreen

    readonly property string label: String(CustomWidgets.getConfigValue("__ID__", "label", "Now"))

    implicitWidth: row.implicitWidth
    implicitHeight: Math.round(28 * IrisStyle.density)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(6 * IrisStyle.density)

        IrisText {
            anchors.baseline: figure.baseline
            role: IrisText.Meta
            text: root.label
        }
        IrisText {
            id: figure
            anchors.verticalCenter: parent.verticalCenter
            role: IrisText.Metric
            font.pixelSize: IrisStyle.typeLabel
            color: IrisStyle.accent
            text: DateTime.time
        }
    }
}
