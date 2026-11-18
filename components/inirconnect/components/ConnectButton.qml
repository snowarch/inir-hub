pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common.functions
import qs.modules.common.widgets
import "../state"

RippleButton {
    id: root

    default property alias contentData: customContent.data
    property bool selected: false
    property bool quiet: false
    property bool emphasized: false
    property color foreground: root.emphasized
        ? ConnectStyle.inkOnAccentFill
        : root.selected
            ? ConnectStyle.accent
            : ConnectStyle.text

    implicitWidth: Math.max(Math.round(34 * ConnectStyle.density),
        root.text.length > 0 ? label.implicitWidth + Math.round(22 * ConnectStyle.density) : Math.round(34 * ConnectStyle.density))
    implicitHeight: Math.max(Math.round(34 * ConnectStyle.density),
        root.text.length > 0 ? label.implicitHeight + Math.round(12 * ConnectStyle.density) : Math.round(34 * ConnectStyle.density))
    Layout.minimumHeight: root.text.length > 0 ? label.implicitHeight + Math.round(10 * ConnectStyle.density) : 0

    toggled: root.selected && !root.emphasized
    buttonRadius: ConnectStyle.radiusButton
    buttonRadiusPressed: Math.max(3, ConnectStyle.radiusButton - 2)
    rippleEnabled: !ConnectStyle.isIris
    stateTransitionsEnabled: ConnectStyle.motionEnabled
    pressScaleEnabled: true
    cookieMorphing: false

    colBackground: root.emphasized
        ? ConnectStyle.accentFill
        : root.quiet
            ? ColorUtils.applyAlpha(ConnectStyle.formPlate, 0)
            : ConnectStyle.formPlate
    colBackgroundHover: root.emphasized ? ConnectStyle.accentHover : ConnectStyle.fillHover
    colBackgroundToggled: ConnectStyle.tintFill(ConnectStyle.accent)
    colBackgroundToggledHover: ConnectStyle.tintFillHover(ConnectStyle.accent)
    colRipple: ConnectStyle.tintFill(ConnectStyle.accent)
    colRippleToggled: ConnectStyle.tintFillHover(ConnectStyle.accent)

    Accessible.name: root.text
    Accessible.role: Accessible.Button
    Accessible.checked: root.selected

    Rectangle {
        anchors.fill: parent
        z: 1
        radius: root.buttonEffectiveRadius
        color: "transparent"
        border.width: root.visualFocus ? 2 : (!ConnectStyle.isIris && !root.quiet && !root.emphasized && !root.toggled ? 1 : 0)
        border.color: root.visualFocus ? ConnectStyle.accent : ConnectStyle.plateEdge
        visible: border.width > 0
    }

    contentItem: Item {
        id: contentHost

        StyledText {
            id: label
            anchors.centerIn: parent
            width: Math.min(implicitWidth, Math.max(0, contentHost.width - Math.round(16 * ConnectStyle.density)))
            elide: Text.ElideRight
            visible: root.text.length > 0
            text: root.text
            color: root.foreground
            font.family: ConnectStyle.fontMain
            font.pixelSize: ConnectStyle.typeLabel
            font.weight: root.emphasized || root.selected
                ? ConnectStyle.weight(Font.DemiBold)
                : ConnectStyle.weight(Font.Medium)
            horizontalAlignment: Text.AlignHCenter
        }

        Item {
            id: customContent
            anchors.fill: parent
        }
    }
}
