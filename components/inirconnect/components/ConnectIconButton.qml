pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common.widgets
import "../state"

ConnectButton {
    id: root

    property string materialIcon: "circle"
    property int iconSize: Math.round(18 * ConnectStyle.density)
    implicitWidth: Math.round(34 * ConnectStyle.density)
    implicitHeight: implicitWidth
    quiet: true

    MaterialSymbol {
        anchors.centerIn: parent
        text: root.materialIcon
        iconSize: root.iconSize
        fill: root.selected ? 1 : 0
        animateFill: true
        font.weight: root.selected || root.hovered ? ConnectStyle.weight(Font.DemiBold) : ConnectStyle.weight(Font.Normal)
        color: root.foreground
    }
}
