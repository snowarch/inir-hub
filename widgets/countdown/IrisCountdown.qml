pragma ComponentBehavior: Bound

// The iRiS face: a compact line on the Island's Desktop page. iRiS modules use IrisStyle tokens and
// the Iris* components, so they follow the theme, the density and the type ladder like the rest of
// the Island. Settings are the same keys the desktop face reads.

import QtQuick
import Quickshell
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "countdown.js" as Countdown

Item {
    id: root

    // Given by the Island: where the module sits and which screen it is on.
    property string irisSlot: ""
    property var targetScreen

    readonly property string label: String(CustomWidgets.getConfigValue("countdown", "label", "New year"))
    readonly property var target: Countdown.parse(CustomWidgets.getConfigValue("countdown", "date", ""))

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: root.visible
    }
    readonly property var reading: Countdown.describe(root.target, clock.date)

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
            color: root.reading.past ? IrisStyle.textSecondary : IrisStyle.accent
            text: root.reading.valid ? root.reading.figure : "—"
        }
        IrisText {
            anchors.baseline: figure.baseline
            visible: root.reading.valid && root.reading.unit.length > 0
            role: IrisText.Meta
            text: root.reading.unit
        }
    }
}
