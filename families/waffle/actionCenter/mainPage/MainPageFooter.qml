pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter
import qs.modules.waffle.actionCenter.screenTime
import qs.modules.waffle.state

// The footer holds what Windows keeps there, the battery and Settings, with Screen Time and Lock beside them.
FooterRectangle {
    id: root

    function closeThen(action: var): void {
        WaffleState.actionCenterOpen = false
        action()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Looks.dp(10)
        anchors.rightMargin: Looks.dp(10)
        spacing: Looks.dp(4)

        WBorderlessButton {
            visible: Battery.available
            Layout.alignment: Qt.AlignVCenter
            contentItem: Row {
                spacing: Looks.dp(4)
                FluentIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: WIcons.batteryLevelIcon ?? "battery-0"
                    FluentIcon {
                        anchors.fill: parent
                        icon: WIcons.batteryIcon ?? "battery-0"
                    }
                }
                WText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${Math.round((Battery?.percentage ?? 0) * 100)}%`
                }
            }
            WToolTip { text: Translation.tr("Battery") }
        }

        WBorderlessButton {
            visible: Config.options?.screenTime?.enable ?? false
            Layout.alignment: Qt.AlignVCenter

            Component {
                id: screenTimePageComp
                ScreenTimePage {}
            }
            onClicked: if (ActionCenterContext.stackView) ActionCenterContext.stackView.push(screenTimePageComp)

            contentItem: Row {
                spacing: Looks.dp(6)
                FluentIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "schedule"
                    implicitSize: Looks.dp(16)
                    color: Looks.colors.accent
                }
                WText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ScreenTime.formatDuration((ScreenTime.todayData?.totalSeconds) || 0)
                }
            }
            WToolTip { text: Translation.tr("Screen Time") }
        }

        Item { Layout.fillWidth: true }

        FooterButton {
            iconName: "lock-closed"
            tip: Translation.tr("Lock")
            onClicked: root.closeThen(() => Session.lock())
        }
        FooterButton {
            iconName: "settings"
            tip: Translation.tr("Settings")
            onClicked: root.closeThen(() => Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "settings"]))
        }
    }

    component FooterButton: WBorderlessButton {
        id: footerButton
        property string iconName
        property string tip
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: Looks.dp(36)
        implicitHeight: Looks.dp(36)
        contentItem: Item {
            FluentIcon {
                anchors.centerIn: parent
                icon: footerButton.iconName
                implicitSize: Looks.dp(17)
            }
        }
        WToolTip { text: footerButton.tip }
    }
}
