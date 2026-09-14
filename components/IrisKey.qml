import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style

PanelSurface {
    id: root
    property string key: ""

    implicitWidth: label.implicitWidth + 14 * IrisStyle.density
    implicitHeight: 24 * IrisStyle.density
    surfaceDialect: "inir"
    elevation: 1
    opaqueSurface: true
    radiusOverride: Math.max(5, IrisStyle.radiusSmall - 1)
    cardStyle: false
    outlined: !IrisStyle.island
    borderless: IrisStyle.island
    borderWidthOverride: 1

    IrisText {
        id: label
        anchors.centerIn: parent
        text: root.key
        font.family: IrisStyle.fontNumbers
        font.pixelSize: 10 * IrisStyle.typeScale
        font.weight: Font.Medium
        color: IrisStyle.muted
    }
}
