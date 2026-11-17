pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

Item {
    id: root
    readonly property real d: IrisStyle.density
    readonly property bool shown: AndroidState.notificationsOpen
    Layout.fillWidth: true
    implicitHeight: root.shown ? sheetPlate.implicitHeight : 0
    opacity: root.shown ? 1.0 : 0.0
    visible: implicitHeight > 0
    clip: true

    Behavior on implicitHeight {
        NumberAnimation {
            duration: IrisStyle.morphDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: IrisStyle.morphCurve
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: IrisStyle.revealDuration
            easing.type: Easing.OutCubic
        }
    }

    IrisPlate {
        id: sheetPlate
        width: parent.width
        height: root.implicitHeight
        implicitHeight: col.implicitHeight + Math.round(20 * root.d)
        radius: IrisStyle.radiusCard
        color: IrisStyle.fill
        clip: true

        ColumnLayout {
            id: col
            width: parent.width - Math.round(24 * root.d)
            x: Math.round(12 * root.d)
            y: Math.round(10 * root.d)
            spacing: Math.round(8 * root.d)

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * root.d)

                MaterialSymbol {
                    text: "notifications"
                    iconSize: Math.round(18 * root.d)
                    color: IrisStyle.accent
                }

                IrisText {
                    Layout.fillWidth: true
                    text: AndroidState.phoneNotifications.length > 0
                        ? `${Translation.tr("Phone notifications")} (${AndroidState.phoneNotifications.length})`
                        : Translation.tr("Phone notifications")
                    color: IrisStyle.text
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: IrisStyle.typeBody
                    font.weight: IrisStyle.weight(Font.Bold)
                }

                IrisPlate {
                    implicitWidth: Math.round(28 * root.d)
                    implicitHeight: Math.round(28 * root.d)
                    radius: Math.round(implicitHeight / 2)
                    color: sendPingMouse.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "send_to_mobile"
                        iconSize: Math.round(15 * root.d)
                        color: IrisStyle.subtext
                    }

                    MouseArea {
                        id: sendPingMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.name: Translation.tr("Send test notification")
                        onClicked: AndroidState.pingDevice()
                    }
                }

                IrisPlate {
                    implicitWidth: Math.round(28 * root.d)
                    implicitHeight: Math.round(28 * root.d)
                    radius: Math.round(implicitHeight / 2)
                    color: closeMouse.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: Math.round(16 * root.d)
                        color: IrisStyle.subtext
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AndroidState.notificationsOpen = false
                    }
                }
            }

            // Quick send test notification button
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * root.d)

                IrisField {
                    id: pingField
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Message to send to your phone...")
                    onAccepted: {
                        if (text.trim().length > 0) {
                            AndroidState.pingDevice(text.trim())
                            text = ""
                        }
                    }
                }

                IrisButton {
                    text: Translation.tr("Send")
                    implicitHeight: Math.round(32 * root.d)
                    emphasized: true
                    onClicked: {
                        const msg = pingField.text.trim().length > 0 ? pingField.text.trim() : Translation.tr("Test notification from PC!")
                        AndroidState.pingDevice(msg)
                        pingField.text = ""
                    }
                }
            }

            // Notifications List
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * root.d)
                visible: AndroidState.phoneNotifications.length > 0

                Repeater {
                    model: AndroidState.phoneNotifications

                    delegate: IrisPlate {
                        id: notifItem
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: nRow.implicitHeight + Math.round(12 * root.d)
                        radius: IrisStyle.radiusTile
                        color: IrisStyle.formPlate

                        RowLayout {
                            id: nRow
                            anchors.fill: parent
                            anchors.margins: Math.round(8 * root.d)
                            spacing: Math.round(8 * root.d)

                            MaterialSymbol {
                                text: "chat"
                                iconSize: Math.round(16 * root.d)
                                color: IrisStyle.accent
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: Math.round(1 * root.d)

                                IrisText {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: `${notifItem.modelData.appName || "App"}: ${notifItem.modelData.title || ""}`
                                    color: IrisStyle.text
                                    font.pixelSize: IrisStyle.typeCaption
                                    font.weight: IrisStyle.weight(Font.Bold)
                                }

                                IrisText {
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    text: notifItem.modelData.text || notifItem.modelData.ticker || ""
                                    color: IrisStyle.subtext
                                    font.pixelSize: Math.max(9, Math.round(10 * root.d))
                                    visible: text.length > 0
                                }
                            }

                            IrisPlate {
                                visible: Boolean(notifItem.modelData.dismissable)
                                implicitWidth: Math.round(24 * root.d)
                                implicitHeight: Math.round(24 * root.d)
                                radius: Math.round(implicitHeight / 2)
                                color: dMouse.containsMouse ? IrisStyle.fillHover : "transparent"

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: Math.round(13 * root.d)
                                    color: IrisStyle.subtext
                                }

                                MouseArea {
                                    id: dMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: AndroidState.dismissNotification(notifItem.modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            // Empty state when no notifications
            IrisPlate {
                Layout.fillWidth: true
                implicitHeight: emptyCol.implicitHeight + Math.round(16 * root.d)
                radius: IrisStyle.radiusRow
                color: IrisStyle.fillQuiet
                visible: AndroidState.phoneNotifications.length === 0

                ColumnLayout {
                    id: emptyCol
                    anchors.fill: parent
                    anchors.margins: Math.round(10 * root.d)
                    spacing: Math.round(6 * root.d)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Math.round(6 * root.d)

                        MaterialSymbol {
                            text: "notifications_none"
                            iconSize: Math.round(18 * root.d)
                            color: IrisStyle.subtext
                        }

                        IrisText {
                            Layout.fillWidth: true
                            text: Translation.tr("No active notifications on your phone")
                            color: IrisStyle.text
                            font.pixelSize: IrisStyle.typeCaption
                            font.weight: IrisStyle.weight(Font.Bold)
                        }
                    }

                    IrisText {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: Translation.tr("If your notifications do not show up:\n1. Open KDE Connect on your phone (%1).\n2. Go to Plugin settings and enable 'Notification sync'.\n3. In Android Settings, grant 'Notification access' to KDE Connect.").arg(AndroidState.deviceName)
                        color: IrisStyle.subtext
                        font.pixelSize: Math.max(9, Math.round(10 * root.d))
                    }
                }
            }
        }
    }
}
