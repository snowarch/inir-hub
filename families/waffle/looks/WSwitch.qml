import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.waffle.looks

Switch {
    id: root
    WFocusVisual { shown: root.visualFocus; radius: root.height / 2 }

    implicitWidth: 40
    implicitHeight: 20
    property real indicatorHeight: 12
    property real indicatorPressedHeight: 14
    property real indicatorPressedWidth: 17
    property color checkedColor: Looks.colors.accent
    property color uncheckedColor: Looks.colors.bg1
    // Off is drawn in the ink at WinUI's alphas (ControlStrongStrokeColorDefault, TextFillColorSecondary): with Material
    // colours the inactive control was the secondary container, pale on a light card, and the switch vanished.
    property color borderColor: Qt.rgba(Looks.colors.fg.r, Looks.colors.fg.g, Looks.colors.fg.b, Looks.dark ? 0.545 : 0.447)
    property color knobOffColor: Qt.rgba(Looks.colors.fg.r, Looks.colors.fg.g, Looks.colors.fg.b, Looks.dark ? 0.77 : 0.62)

    readonly property real indicatorPressedWidthDiff: indicatorPressedWidth - indicatorHeight
    
    background: Rectangle {
        width: parent.width
        height: parent.height
        radius: height / 2
        color: root.checked ? root.checkedColor : root.uncheckedColor
        border.width: 1
        border.color: root.checked ? root.checkedColor : root.borderColor

        Behavior on color {
            ColorAnimation {
                duration: Looks.transition.enabled ? Looks.transition.duration.normal : 0
                easing.type: Easing.OutQuad
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: Looks.transition.enabled ? Looks.transition.duration.normal : 0
                easing.type: Easing.OutQuad
            }
        }
    }

    // Custom thumb styling - Windows 11 style with smooth spring animation
    indicator: Rectangle {
        implicitWidth: (root.pressed || root.down) ? root.indicatorPressedWidth : root.indicatorHeight
        implicitHeight: (root.pressed || root.down) ? root.indicatorPressedHeight : root.indicatorHeight
        radius: Math.min(width, height) / 2
        color: root.checked ? Looks.colors.accentFg : root.knobOffColor
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: {
            if (root.checked) {
                return 24 - (root.pressed || root.down ? root.indicatorPressedWidthDiff : 0);
            } else {
                return (root.pressed || root.down) ? 3 : (Config.options?.waffles?.tweaks?.switchHandlePositionFix ? 4 : 3);
            }
        }

        Behavior on anchors.leftMargin {
            NumberAnimation {
                duration: Looks.transition.enabled ? Looks.transition.duration.panel : 0
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Looks.transition.easing.bezierCurve.spring
            }
        }
        Behavior on implicitWidth {
            NumberAnimation {
                duration: Looks.transition.enabled ? Looks.transition.duration.fast : 0
                easing.type: Easing.OutQuad
            }
        }
        Behavior on implicitHeight {
            NumberAnimation {
                duration: Looks.transition.enabled ? Looks.transition.duration.fast : 0
                easing.type: Easing.OutQuad
            }
        }
        Behavior on color {
            animation: ColorAnimation { duration: Looks.transition.enabled ? 70 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
        }
    }
}
