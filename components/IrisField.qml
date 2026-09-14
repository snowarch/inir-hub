pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style

MaterialTextField {
    id: root

    enableSettingsSearch: false
    color: IrisStyle.text
    placeholderTextColor: IrisStyle.subtext
    selectionColor: IrisStyle.accentContainer
    selectedTextColor: IrisStyle.onAccentContainer
    font.family: IrisStyle.fontTitle
    font.pixelSize: 15 * IrisStyle.typeScale
    leftPadding: 14 * IrisStyle.density
    rightPadding: 14 * IrisStyle.density

    background: PanelSurface {
        surfaceDialect: "inir"
        elevation: root.activeFocus ? 2 : 1
        opaqueSurface: true
        radiusOverride: IrisStyle.radiusSmall
        cardStyle: false
        outlined: !IrisStyle.island
        borderless: IrisStyle.island
        borderWidthOverride: root.activeFocus ? 1.5 : 1

        Rectangle {
            anchors.fill: parent
            visible: IrisStyle.island
            radius: IrisStyle.radiusSmall
            color: IrisStyle.field
            border.width: root.activeFocus ? 1 : 0
            border.color: IrisStyle.hairlineStrong
        }

        Rectangle {
            visible: !IrisStyle.island
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: IrisStyle.radiusSmall
            anchors.rightMargin: IrisStyle.radiusSmall
            height: root.activeFocus ? 2 : 1
            radius: height / 2
            color: root.activeFocus ? IrisStyle.accent
                : root.hovered ? IrisStyle.hairlineStrong : IrisStyle.hairline
            Behavior on color {
                enabled: IrisStyle.motionEnabled
                ColorAnimation { duration: IrisStyle.duration(160) }
            }
        }
    }
}
