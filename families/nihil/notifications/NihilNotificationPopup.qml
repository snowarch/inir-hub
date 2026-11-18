pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// New notifications as NiHiL pieces at the top right: the app's glyph on a round piece, its name in figures, the
// summary and body; the first action as a lit pill. A click opens it, the cross lets it go.
Scope {
    id: root

    Component.onCompleted: Notifications.ensureInitialized()

    LazyLoader {
        active: Notifications.popupList.length > 0
        component: PanelWindow {
            screen: GlobalStates.focusedScreen ?? Quickshell.screens[0]
            visible: !GlobalStates.screenLocked && !(GameMode.active && GameMode.suppressNotifications)
            color: "transparent"
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:nihilNotifications"
            WlrLayershell.layer: WlrLayer.Overlay
            anchors { top: true; right: true }
            margins { top: NihilStyle.edge; right: NihilStyle.edge }
            implicitWidth: NihilStyle.s(380)
            implicitHeight: Math.min(column.implicitHeight, (screen?.height ?? 800) * 0.7)
            mask: Region { item: column }

            Column {
                id: column
                width: parent.width
                spacing: NihilStyle.gap
                Repeater {
                    model: Notifications.popupList.slice(0, 4)
                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        width: column.width
                        height: body.implicitHeight + NihilStyle.s(32)
                        radius: NihilStyle.cardRadius
                        color: NihilStyle.piece

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: Notifications.cancelTimeout(card.modelData.notificationId)
                            onClicked: Notifications.attemptInvokeAction(card.modelData.notificationId, "default")
                        }

                        Row {
                            id: body
                            x: NihilStyle.s(16); y: NihilStyle.s(16)
                            width: parent.width - NihilStyle.s(32)
                            spacing: NihilStyle.s(12)
                            Rectangle {
                                width: NihilStyle.s(40); height: width; radius: width / 2
                                color: NihilStyle.pieceRaised
                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: NihilStyle.s(22)
                                    source: Quickshell.iconPath(card.modelData.appIcon || AppSearch.guessIcon(card.modelData.appName), "dialog-information")
                                }
                            }
                            Column {
                                width: parent.width - NihilStyle.s(52) - close.width
                                spacing: NihilStyle.s(3)
                                NText {
                                    width: parent.width
                                    mono: true
                                    font.pixelSize: NihilStyle.textSmall
                                    font.capitalization: Font.AllUppercase
                                    color: card.modelData.urgency === "critical" ? NihilStyle.accent : NihilStyle.inkSoft
                                    text: card.modelData.appName
                                }
                                NText {
                                    width: parent.width
                                    font.pixelSize: NihilStyle.textLarge
                                    font.weight: Font.Medium
                                    text: card.modelData.summary
                                }
                                NText {
                                    width: parent.width
                                    visible: text.length > 0
                                    color: NihilStyle.inkSoft
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    textFormat: Text.PlainText
                                    text: card.modelData.body
                                }
                                Row {
                                    visible: card.modelData.actions.length > 0
                                    spacing: NihilStyle.s(6)
                                    topPadding: NihilStyle.s(6)
                                    Repeater {
                                        model: card.modelData.actions.slice(0, 3)
                                        delegate: NButton {
                                            id: action
                                            required property var modelData
                                            required property int index
                                            height: NihilStyle.s(32)
                                            width: label.implicitWidth + NihilStyle.s(28)
                                            lit: action.index === 0
                                            tone: NihilStyle.pieceRaised
                                            onClicked: Notifications.attemptInvokeAction(card.modelData.notificationId, action.modelData.identifier)
                                            NText { id: label; anchors.centerIn: parent; color: action.ink; text: action.modelData.text }
                                        }
                                    }
                                }
                            }
                            NButton {
                                id: close
                                width: NihilStyle.s(28); height: width
                                tone: NihilStyle.pieceRaised
                                icon: "close"
                                iconSize: NihilStyle.s(16)
                                onClicked: Notifications.discardNotification(card.modelData.notificationId)
                            }
                        }
                    }
                }
            }
        }
    }
}
