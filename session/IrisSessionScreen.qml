pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: window
        required property var modelData
        property bool presentationVisible: GlobalStates.sessionOpen
        property bool presentationShown: false
        visible: window.presentationVisible
        screen: modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:iris-session"
        WlrLayershell.keyboardFocus: GlobalStates.sessionOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        function runAction(action: string): void {
            GlobalStates.sessionOpen = false
            switch (action) {
            case "lock": Session.lock(); break
            case "suspend": Session.suspend(); break
            case "logout": Session.logout(); break
            case "reboot": Session.reboot(); break
            case "poweroff": Session.poweroff(); break
            }
        }

        Component.onCompleted: {
            if (GlobalStates.sessionOpen)
                Qt.callLater(() => window.presentationShown = true)
        }

        Connections {
            target: GlobalStates
            function onSessionOpenChanged(): void {
                if (GlobalStates.sessionOpen) {
                    closePresentation.stop()
                    window.presentationVisible = true
                    Qt.callLater(() => window.presentationShown = true)
                } else if (window.presentationVisible) {
                    window.presentationShown = false
                    closePresentation.restart()
                }
            }
        }

        Timer {
            id: closePresentation
            interval: IrisStyle.duration(IrisStyle.island ? 160 : 100)
            onTriggered: window.presentationVisible = false
        }

        Shortcut {
            enabled: GlobalStates.sessionOpen
            sequences: [StandardKey.Cancel]
            onActivated: {
                if ((sessionLoader.item?.pending ?? "").length > 0) sessionLoader.item.pending = ""
                else GlobalStates.sessionOpen = false
            }
        }

        Loader {
            id: sessionLoader
            anchors.fill: parent
            sourceComponent: IrisStyle.island ? islandComponent : classicComponent
        }

        // ── Island: one row of system actions over the dimmed desktop ────
        Component {
            id: islandComponent

            FocusScope {
                id: stage
                readonly property real d: IrisStyle.density
                readonly property var actions: [
                    { id: "suspend", icon: "bedtime", label: Translation.tr("Sleep"), confirm: false },
                    { id: "reboot", icon: "restart_alt", label: Translation.tr("Restart"), confirm: true },
                    { id: "poweroff", icon: "power_settings_new", label: Translation.tr("Shut Down"), confirm: true },
                    { id: "lock", icon: "lock", label: Translation.tr("Lock"), confirm: false },
                    { id: "logout", icon: "logout", label: Translation.tr("Log Out"), confirm: true }
                ]
                property int focusIndex: 0
                property bool keyboardNavigation: false
                // Restart, Shut Down and Log Out ask for a second press on the
                // same action; anything else cancels the request.
                property string pending: ""
                readonly property var pendingAction: stage.actions.find(action => action.id === stage.pending) ?? null

                function trigger(index: int): void {
                    const action = stage.actions[index]
                    stage.focusIndex = index
                    if (action.confirm && stage.pending !== action.id) {
                        stage.pending = action.id
                        pendingExpiry.restart()
                        return
                    }
                    window.runAction(action.id)
                }

                Timer { id: pendingExpiry; interval: 5000; onTriggered: stage.pending = "" }

                focus: true
                Component.onCompleted: Qt.callLater(() => stage.forceActiveFocus())
                Keys.onPressed: event => {
                    const count = stage.actions.length
                    if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                        stage.keyboardNavigation = true
                        stage.pending = ""
                        stage.focusIndex = (stage.focusIndex + 1) % count
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                        stage.keyboardNavigation = true
                        stage.pending = ""
                        stage.focusIndex = (stage.focusIndex + count - 1) % count
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        stage.keyboardNavigation = true
                        stage.trigger(stage.focusIndex)
                    } else {
                        return
                    }
                    event.accepted = true
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: window.presentationShown ? 0.58 : 0
                    Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(160); easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (stage.pending.length > 0) stage.pending = ""
                        else GlobalStates.sessionOpen = false
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    opacity: window.presentationShown ? 1 : 0
                    scale: window.presentationShown ? 1 : 0.96
                    Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(160); easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }

                    IrisText {
                        Layout.alignment: Qt.AlignHCenter
                        text: DateTime.timeDisplay
                        font.family: IrisStyle.fontTitle
                        font.features: ({ "tnum": 1 })
                        font.pixelSize: Math.round(64 * IrisStyle.typeScale)
                        font.weight: Font.DemiBold
                    }
                    IrisText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.locale().toString(DateTime.clock.date, "dddd, d MMMM")
                        color: ColorUtils.applyAlpha(IrisStyle.text, 0.72)
                        font.pixelSize: Math.round(15 * IrisStyle.typeScale)
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 44 * stage.d
                        spacing: 30 * stage.d

                        Repeater {
                            model: stage.actions
                            Item {
                                id: action
                                required property var modelData
                                required property int index
                                readonly property bool armed: stage.pending === action.modelData.id
                                readonly property bool focused: stage.keyboardNavigation && stage.focusIndex === action.index
                                width: Math.round(76 * stage.d)
                                height: disc.height + label.anchors.topMargin + label.height

                                Rectangle {
                                    id: disc
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width
                                    height: width
                                    radius: width / 2
                                    color: action.armed ? IrisStyle.danger
                                        : pointer.containsMouse || action.focused ? ColorUtils.applyAlpha(IrisStyle.text, 0.26)
                                        : ColorUtils.applyAlpha(IrisStyle.text, 0.14)
                                    scale: pointer.pressed ? 0.93 : 1
                                    Behavior on color { ColorAnimation { duration: IrisStyle.duration(120) } }
                                    Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: Easing.OutCubic } }

                                    // Keyboard focus ring, outside the disc.
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width + 8 * stage.d
                                        height: width
                                        radius: width / 2
                                        color: "transparent"
                                        border.width: 2
                                        border.color: ColorUtils.applyAlpha(IrisStyle.text, 0.85)
                                        visible: action.focused
                                    }

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: action.modelData.icon
                                        iconSize: Math.round(30 * stage.d)
                                        fill: 1
                                        color: action.armed ? "#ffffff" : IrisStyle.text
                                    }
                                }
                                IrisText {
                                    id: label
                                    anchors.top: disc.bottom
                                    anchors.topMargin: 10 * stage.d
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: action.armed ? Translation.tr("Confirm") : action.modelData.label
                                    color: action.armed ? IrisStyle.danger : IrisStyle.text
                                    font.pixelSize: Math.round(13 * IrisStyle.typeScale)
                                    font.weight: Font.Medium
                                }
                                MouseArea {
                                    id: pointer
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    Accessible.role: Accessible.Button
                                    Accessible.name: action.modelData.label
                                    onEntered: stage.keyboardNavigation = false
                                    onClicked: stage.trigger(action.index)
                                }
                            }
                        }
                    }

                    // The hint line holds its height so arming never shifts the row.
                    IrisText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 22 * stage.d
                        text: stage.pendingAction
                            ? Translation.tr("Press %1 again to continue").arg(stage.pendingAction.label)
                            : Translation.tr("Up %1").arg(DateTime.uptime)
                        color: stage.pendingAction ? ColorUtils.applyAlpha(IrisStyle.text, 0.85) : ColorUtils.applyAlpha(IrisStyle.text, 0.5)
                        font.pixelSize: Math.round(12.5 * IrisStyle.typeScale)
                    }
                }
            }
        }

        // ── Classic: action list card ─────────────────────────────────────
        Component {
            id: classicComponent

            Item {
                Rectangle {
                    anchors.fill: parent
                    color: IrisStyle.scrim
                    opacity: window.presentationShown ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(90); easing.type: Easing.OutCubic } }
                }

                IrisSurface {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 32, 720 * IrisStyle.density)
                    height: sessionContent.implicitHeight + IrisStyle.panelPadding * 2
                    raised: true
                    opacity: window.presentationShown ? 1 : 0
                    scale: window.presentationShown ? 1 : 0.985
                    Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(90); easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: IrisStyle.duration(100); easing.type: Easing.OutCubic } }

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
                            Layout.preferredWidth: sessionContent.columns > 1
                                ? 0.36 * sessionContent.width : sessionContent.width
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
                            Layout.preferredWidth: sessionContent.columns > 1
                                ? 0.64 * sessionContent.width : sessionContent.width
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
                                    required property var modelData
                                    required property int index
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
                                    trailingText: String(index + 1).padStart(2, "0")
                                    onClicked: window.runAction(modelData.action)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
