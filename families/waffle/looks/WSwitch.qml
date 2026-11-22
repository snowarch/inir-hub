import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.waffle.looks

// Waffle Next toggle: a 44 x 22 pill whose knob grows under the pointer, stretches while pressed and springs across
Switch {
    id: root
    WFocusVisual { shown: root.visualFocus; radius: root.height / 2 }

    implicitWidth: Looks.dp(44)
    implicitHeight: Looks.dp(22)
    property color checkedColor: Looks.colors.accent
    property color uncheckedColor: Looks.colors.bg1
    // Off is drawn in the ink at WinUI's alphas (ControlStrongStrokeColorDefault, TextFillColorSecondary): with Material
    // colours the inactive control was the secondary container, pale on a light card, and the switch vanished.
    property color borderColor: Qt.rgba(Looks.colors.fg.r, Looks.colors.fg.g, Looks.colors.fg.b, Looks.dark ? 0.545 : 0.447)
    property color knobOffColor: Qt.rgba(Looks.colors.fg.r, Looks.colors.fg.g, Looks.colors.fg.b, Looks.dark ? 0.77 : 0.62)

    readonly property bool _held: root.pressed || root.down
    readonly property real _knobH: root._held || root.hovered ? Looks.dp(16) : Looks.dp(14)
    readonly property real _knobW: root._held ? Looks.dp(20) : root._knobH
    // centred on the track; the Waffle Style tweak turned off keeps Windows' knob a pixel off centre when off
    readonly property real _inset: (root.height - root._knobH) / 2
        - (!root.checked && !(Config.options?.waffles?.tweaks?.switchHandlePositionFix ?? true) ? 1 : 0)

    background: Rectangle {
        width: parent.width
        height: parent.height
        radius: height / 2
        color: root.checked ? root.checkedColor
            : root.hovered ? Qt.alpha(Looks.colors.fg, Looks.dark ? 0.08 : 0.05) : root.uncheckedColor
        border.width: 1
        border.color: root.checked ? root.checkedColor : root.borderColor

        // a sheen on the lit track, the light from above every Waffle Next surface has
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            opacity: root.checked ? 1 : 0
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.16) }
                GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
            }
            Behavior on opacity {
                NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.normal : 0 }
            }
        }

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

    indicator: Rectangle {
        implicitWidth: root._knobW
        implicitHeight: root._knobH
        radius: height / 2
        color: root.checked ? Looks.colors.accentFg : root.knobOffColor
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.checked ? root.width - root._knobW - root._inset : root._inset

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
