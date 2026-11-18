pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// New notifications as tiles packed at the top right: the app's mark, its name in small capitals, the summary in heavy
// type and the body; the first action on paper. A click opens it, the cross lets it go.
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
            implicitWidth: NihilStyle.s(384)
            implicitHeight: Math.min(column.implicitHeight, (screen?.height ?? 800) * 0.7)
            mask: Region { item: column }

            Column {
                id: column
                width: parent.width
                spacing: NihilStyle.seam
                Repeater {
                    model: Notifications.popupList.slice(0, 4)
                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        readonly property bool critical: card.modelData.urgency === "critical"
                        width: column.width
                        height: Math.max(words.implicitHeight + NihilStyle.s(24), NihilStyle.s(68))
                        radius: NihilStyle.tileRadius
                        color: NihilStyle.piece

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: Notifications.cancelTimeout(card.modelData.notificationId)
                            onClicked: Notifications.attemptInvokeAction(card.modelData.notificationId, "default")
                        }

                        Rectangle {
                            id: mark
                            x: NihilStyle.s(10)
                            y: NihilStyle.s(10)
                            width: NihilStyle.s(48); height: width
                            radius: NihilStyle.rowRadius
                            color: card.critical ? NihilStyle.accent : NihilStyle.pieceRaised
                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: NihilStyle.s(26)
                                source: Quickshell.iconPath(card.modelData.appIcon || AppSearch.guessIcon(card.modelData.appName), "dialog-information")
                            }
                        }

                        Column {
                            id: words
                            x: mark.x + mark.width + NihilStyle.s(12)
                            y: NihilStyle.s(11)
                            width: parent.width - x - close.width - NihilStyle.s(14)
                            spacing: NihilStyle.s(2)
                            NCaps {
                                width: parent.width
                                text: card.modelData.appName
                                color: card.critical ? NihilStyle.accent : NihilStyle.inkSoft
                            }
                            NText {
                                width: parent.width
                                text: card.modelData.summary
                                font.pixelSize: NihilStyle.textLarge
                                font.weight: Font.Black
                            }
                            NText {
                                width: parent.width
                                visible: text.length > 0
                                text: card.modelData.body
                                textFormat: Text.PlainText
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                color: NihilStyle.inkSoft
                            }
                            Row {
                                visible: card.modelData.actions.length > 0
                                spacing: NihilStyle.seam
                                topPadding: NihilStyle.s(6)
                                Repeater {
                                    model: card.modelData.actions.slice(0, 3)
                                    delegate: NButton {
                                        id: action
                                        required property var modelData
                                        required property int index
                                        height: NihilStyle.s(34)
                                        width: label.implicitWidth + NihilStyle.s(24)
                                        paper: action.index === 0
                                        tone: NihilStyle.pieceRaised
                                        onClicked: Notifications.attemptInvokeAction(card.modelData.notificationId, action.modelData.identifier)
                                        NText {
                                            id: label
                                            anchors.centerIn: parent
                                            text: action.modelData.text
                                            font.pixelSize: NihilStyle.textSmall
                                            font.weight: Font.Bold
                                            color: action.ink
                                        }
                                    }
                                }
                            }
                        }

                        NButton {
                            id: close
                            anchors.right: parent.right
                            anchors.rightMargin: NihilStyle.s(6)
                            y: NihilStyle.s(6)
                            width: NihilStyle.s(28); height: width
                            tone: NihilStyle.pieceRaised
                            icon: "close"
                            iconSize: NihilStyle.s(15)
                            onClicked: Notifications.discardNotification(card.modelData.notificationId)
                        }
                    }
                }
            }
        }
    }
}
