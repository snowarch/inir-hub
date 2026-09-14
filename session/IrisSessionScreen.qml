pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: window
        required property var modelData
        visible: GlobalStates.sessionOpen
        screen: modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:iris-session"
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        Shortcut {
            sequences: [StandardKey.Cancel]
            onActivated: GlobalStates.sessionOpen = false
        }

        Rectangle { anchors.fill: parent; color: IrisStyle.scrim }

        IrisSurface {
            anchors.centerIn: parent
            width: Math.min(parent.width - 32, 720 * IrisStyle.density)
            height: sessionContent.implicitHeight + IrisStyle.panelPadding * 2
            raised: true

            GridLayout {
                id: sessionContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: IrisStyle.panelPadding
                anchors.rightMargin: IrisStyle.panelPadding
                columns: width >= 620 * IrisStyle.density ? 2 : 1
                columnSpacing: 28 * IrisStyle.density
                rowSpacing: 18 * IrisStyle.density

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: 0.42 * parent.width
                    spacing: 8 * IrisStyle.density

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8 * IrisStyle.density
                        IrisMark { implicitSize: 28 * IrisStyle.density }
                        IrisText { text: "IRIS / SESSION"; role: IrisText.Eyebrow }
                    }

                    IrisText {
                        text: DateTime.timeDisplay
                        role: IrisText.Display
                        font.family: IrisStyle.fontNumbers
                        font.pixelSize: 44 * IrisStyle.typeScale
                    }
                    IrisText {
                        text: DateTime.date
                        role: IrisText.Meta
                        font.pixelSize: 13 * IrisStyle.typeScale
                    }

                    Rectangle {
                        Layout.topMargin: 6 * IrisStyle.density
                        Layout.preferredWidth: IrisStyle.accentRuleWidth * 1.8
                        Layout.preferredHeight: IrisStyle.accentRuleHeight
                        radius: height / 2
                        color: IrisStyle.secondaryAccent
                    }

                    IrisText {
                        Layout.fillWidth: true
                        Layout.topMargin: 4 * IrisStyle.density
                        text: Translation.tr("Choose what the system should do. Escape returns to the desktop.")
                        role: IrisText.Meta
                        wrapMode: Text.WordWrap
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 4 * IrisStyle.density

                    IrisText {
                        text: Translation.tr("Actions").toUpperCase()
                        role: IrisText.Eyebrow
                        Layout.bottomMargin: 3 * IrisStyle.density
                    }

                    Repeater {
                        model: [
                            { icon: "lock", label: Translation.tr("Lock"), action: "lock" },
                            { icon: "bedtime", label: Translation.tr("Suspend"), action: "suspend" },
                            { icon: "logout", label: Translation.tr("Log out"), action: "logout" },
                            { icon: "restart_alt", label: Translation.tr("Restart"), action: "reboot" },
                            { icon: "power_settings_new", label: Translation.tr("Power off"), action: "poweroff" }
                        ]
                        IrisActionTile {
                            id: actionButton
                            required property var modelData
                            Layout.fillWidth: true
                            compact: true
                            materialIcon: modelData.icon
                            title: modelData.label
                            subtitle: modelData.action === "lock" ? Translation.tr("Keep the session running")
                                : modelData.action === "suspend" ? Translation.tr("Sleep and resume later")
                                : modelData.action === "logout" ? Translation.tr("End this user session")
                                : modelData.action === "reboot" ? Translation.tr("Restart the computer")
                                : Translation.tr("Shut down the computer")
                            danger: modelData.action === "reboot" || modelData.action === "poweroff"
                            trailingText: modelData.action === "lock" ? "01"
                                : modelData.action === "suspend" ? "02"
                                : modelData.action === "logout" ? "03"
                                : modelData.action === "reboot" ? "04" : "05"
                            onClicked: {
                                GlobalStates.sessionOpen = false
                                switch (modelData.action) {
                                case "lock": Session.lock(); break
                                case "suspend": Session.suspend(); break
                                case "logout": Session.logout(); break
                                case "reboot": Session.reboot(); break
                                case "poweroff": Session.poweroff(); break
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
