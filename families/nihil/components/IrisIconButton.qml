import QtQuick
import qs.modules.common.widgets
import qs.modules.nihil.style
import qs.modules.nihil.components

IrisButton {
    id: root
    property string materialIcon: "circle"
    property int iconSize: Math.round(18 * IrisStyle.density)
    implicitWidth: Math.round(34 * IrisStyle.density)
    implicitHeight: implicitWidth
    quiet: true

    MaterialSymbol {
        anchors.centerIn: parent
        text: root.materialIcon
        iconSize: root.iconSize
        fill: root.selected ? 1 : 0
        animateFill: true
        font.weight: root.selected || root.hovered ? IrisStyle.weight(Font.DemiBold) : IrisStyle.weight(Font.Normal)
        color: root.foreground
    }
}
