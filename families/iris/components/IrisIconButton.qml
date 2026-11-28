import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

IrisButton {
    id: root
    property string materialIcon: "circle"
    property int iconSize: Math.round(18 * IrisStyle.density)
    // A glyph alone names nothing: its name shows on hover. Built only when given. A StyledToolTip placed inside an
    // IrisButton lands in its content item, which has no hover state, and would never hide.
    property string tooltip: ""
    property string tooltipPosition: "bottom"
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

    Loader {
        anchors.fill: parent
        active: root.tooltip.length > 0
        sourceComponent: StyledToolTip {
            text: root.tooltip
            position: root.tooltipPosition
            extraVisibleCondition: root.buttonHovered
        }
    }
}
