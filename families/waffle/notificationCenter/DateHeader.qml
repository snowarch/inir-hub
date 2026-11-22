pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

// Waffle Next: today as a desk calendar shows it, the day on an accent tile and the weekday beside it.
FooterRectangle {
    id: root

    implicitWidth: 0
    implicitHeight: Looks.dp(64)
    property bool collapsed
    color: ColorUtils.transparentize(Looks.colors.bgPanelBody, collapsed ? 0 : 1)
    Behavior on color {
        animation: ColorAnimation { duration: Looks.transition.enabled ? 70 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Looks.dp(16)
            rightMargin: Looks.dp(14)
        }
        spacing: Looks.dp(12)

        Rectangle {
            Layout.preferredWidth: Looks.dp(40)
            Layout.preferredHeight: Looks.dp(40)
            radius: Looks.radius.large
            color: Looks.colors.accent

            WText {
                anchors.centerIn: parent
                text: DateTime.clock.date.getDate()
                color: Looks.colors.accentFg
                font.pixelSize: Looks.font.pixelSize.xlarger
                font.weight: Looks.font.weight.strong
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            WText {
                Layout.fillWidth: true
                text: Translation.locale.toString(DateTime.clock.date, "dddd")
                // Spanish, French and others write the weekday in lower case
                font.capitalization: Font.Capitalize
                font.pixelSize: Looks.font.pixelSize.larger
                font.weight: Looks.font.weight.strong
                elide: Text.ElideRight
            }
            WText {
                Layout.fillWidth: true
                text: Translation.locale.toString(DateTime.clock.date, "d MMMM yyyy")
                color: Looks.colors.subfg
                elide: Text.ElideRight
            }
        }

        WBorderlessButton {
            implicitWidth: Looks.dp(30)
            implicitHeight: Looks.dp(30)
            radius: height / 2
            padding: 0
            colBackground: Qt.alpha(Looks.colors.fg, Looks.dark ? 0.06 : 0.05)
            onClicked: root.collapsed = !root.collapsed
            contentItem: Item {
                FluentIcon {
                    anchors.centerIn: parent
                    implicitSize: Looks.dp(12)
                    icon: "chevron-down"
                    rotation: root.collapsed ? 180 : 0
                    Behavior on rotation {
                        animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.normal : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
                    }
                }
            }
        }
    }
}
