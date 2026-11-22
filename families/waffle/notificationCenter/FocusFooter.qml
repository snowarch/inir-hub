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
import qs.modules.waffle.state

// Waffle Next focus: the length on a stepper pill, Focus on an accent pill; a session shows the time it has left.
FooterRectangle {
    Layout.fillWidth: true
    implicitWidth: 0
    implicitHeight: Looks.dp(56)
    color: Looks.colors.bgPanelBody

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Looks.dp(14)
            rightMargin: Looks.dp(14)
        }
        spacing: Looks.dp(8)

        Rectangle {
            visible: !TimerService.pomodoroRunning
            implicitWidth: stepRow.implicitWidth + Looks.dp(6)
            implicitHeight: Looks.dp(32)
            radius: height / 2
            color: Qt.alpha(Looks.colors.fg, Looks.dark ? 0.07 : 0.05)

            RowLayout {
                id: stepRow
                anchors.centerIn: parent
                spacing: 0

                StepButton {
                    iconName: "subtract"
                    enabled: TimerService.focusTime > 300 // 5 minutes at least
                    onClicked: Config.setNestedValue("time.pomodoro.focus", TimerService.focusTime - 300)
                }
                WText {
                    Layout.preferredWidth: Looks.dp(68)
                    horizontalAlignment: Text.AlignHCenter
                    text: Translation.tr("%1 mins").arg(TimerService.focusTime / 60)
                }
                StepButton {
                    iconName: "add"
                    enabled: TimerService.focusTime < 7200 // 2 hours at most
                    onClicked: Config.setNestedValue("time.pomodoro.focus", TimerService.focusTime + 300)
                }
            }
        }

        RowLayout {
            visible: TimerService.pomodoroRunning
            spacing: Looks.dp(8)

            WText {
                font.pixelSize: Looks.font.pixelSize.large
                text: Translation.tr("Focusing")
            }
            WText {
                readonly property int secondsLeft: Math.max(0, TimerService.pomodoroSecondsLeft)
                text: `${Math.floor(secondsLeft / 60)}:${String(secondsLeft % 60).padStart(2, "0")}`
                color: Looks.colors.subfg
                font.family: Looks.font.family.monospace
            }
        }

        Item {
            Layout.fillWidth: true
        }

        WButton {
            id: focusButton
            checked: true
            implicitHeight: Looks.dp(32)
            implicitWidth: focusRow.implicitWidth + Looks.dp(28)
            radius: height / 2
            padding: 0

            onClicked: {
                if (TimerService.pomodoroRunning) {
                    TimerService.togglePomodoro();
                    TimerService.resetPomodoro();
                } else {
                    TimerService.togglePomodoro();
                    WaffleState.notificationCenterOpen = false;
                }
            }

            contentItem: Item {
                Row {
                    id: focusRow
                    anchors.centerIn: parent
                    spacing: Looks.dp(6)
                    FluentIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: TimerService.pomodoroRunning ? "stop" : "play"
                        filled: true
                        implicitSize: Looks.dp(14)
                        color: Looks.colors.accentFg
                    }
                    WText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: TimerService.pomodoroRunning ? Translation.tr("End session") : Translation.tr("Focus")
                        color: Looks.colors.accentFg
                        font.weight: Looks.font.weight.strong
                    }
                }
            }
        }
    }

    component StepButton: WBorderlessButton {
        id: step
        property string iconName
        implicitWidth: Looks.dp(28)
        implicitHeight: Looks.dp(28)
        radius: height / 2
        padding: 0
        opacity: enabled ? 1 : 0.4
        contentItem: Item {
            FluentIcon {
                anchors.centerIn: parent
                implicitSize: Looks.dp(12)
                icon: step.iconName
            }
        }
    }
}
