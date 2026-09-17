pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

IrisButton {
    id: chip
    property string glyph: ""
    property string label: ""
    implicitHeight: Math.round(30 * IrisStyle.density)
    implicitWidth: chipRow.implicitWidth + Math.round(22 * IrisStyle.density)
    buttonRadius: height / 2
    buttonRadiusPressed: height / 2
    Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: Math.round(5 * IrisStyle.density)
        Glyph { anchors.verticalCenter: parent.verticalCenter; text: chip.glyph; iconSize: 16 * IrisStyle.density; color: chip.foreground }
        IrisText { anchors.verticalCenter: parent.verticalCenter; text: chip.label; color: chip.foreground; font.pixelSize: 12.5 * IrisStyle.typeScale }
    }
}
