pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import "../state"

Item {
    id: root
    readonly property real d: ConnectStyle.density
    readonly property bool shown: AndroidState.notificationsOpen
    Layout.fillWidth: true
    implicitHeight: root.shown ? sheetPlate.implicitHeight : 0
    opacity: root.shown ? 1.0 : 0.0
    visible: implicitHeight > 0
    clip: true

    Behavior on implicitHeight {
        NumberAnimation {
            duration: ConnectStyle.morphDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: ConnectStyle.morphCurve
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: ConnectStyle.revealDuration
            easing.type: Easing.OutCubic
        }
    }

    ConnectPlate {
        id: sheetPlate
        width: parent.width
        height: root.implicitHeight
        implicitHeight: col.implicitHeight + Math.round(20 * root.d)
        radius: ConnectStyle.radiusCard
        color: ConnectStyle.fill
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
                    color: ConnectStyle.accent
                }

                StyledText {
                    Layout.fillWidth: true
                    text: AndroidState.phoneNotifications.length > 0
                        ? `${Translation.tr("Phone notifications")} (${AndroidState.phoneNotifications.length})`
                        : Translation.tr("Phone notifications")
                    color: ConnectStyle.text
                    font.family: ConnectStyle.fontTitle
                    font.pixelSize: ConnectStyle.typeBody
                    font.weight: ConnectStyle.weight(Font.Bold)
                }

                ConnectPlate {
                    implicitWidth: Math.round(28 * root.d)
                    implicitHeight: Math.round(28 * root.d)
                    radius: Math.round(implicitHeight / 2)
                    color: sendPingMouse.containsMouse ? ConnectStyle.fillHover : ConnectStyle.fillQuiet

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "send_to_mobile"
                        iconSize: Math.round(15 * root.d)
                        color: ConnectStyle.subtext
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

                ConnectPlate {
                    implicitWidth: Math.round(28 * root.d)
                    implicitHeight: Math.round(28 * root.d)
                    radius: Math.round(implicitHeight / 2)
                    color: closeMouse.containsMouse ? ConnectStyle.fillHover : ConnectStyle.fillQuiet

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: Math.round(16 * root.d)
                        color: ConnectStyle.subtext
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

                ConnectPlate {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(32 * root.d)
                    radius: ConnectStyle.radiusRow
                    color: ConnectStyle.fillQuiet

                    TextInput {
                        id: pingField
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(10 * root.d)
                        anchors.rightMargin: Math.round(10 * root.d)
                        verticalAlignment: TextInput.AlignVCenter
                        color: ConnectStyle.text
                        font.family: ConnectStyle.fontMain
                        font.pixelSize: ConnectStyle.typeMeta
                        clip: true
                        text: ""
                        onAccepted: {
                            if (pingField.text.trim().length > 0) {
                                AndroidState.pingDevice(pingField.text.trim())
                                pingField.text = ""
                            }
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: pingField.text.length === 0 && !pingField.activeFocus
                            text: Translation.tr("Message to send to your phone...")
                            color: ConnectStyle.muted
                            font.family: ConnectStyle.fontMain
                            font.pixelSize: ConnectStyle.typeMeta
                        }
                    }
                }

                ConnectButton {
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

                    delegate: ConnectPlate {
                        id: notifItem
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: nRow.implicitHeight + Math.round(12 * root.d)
                        radius: ConnectStyle.radiusTile
                        color: ConnectStyle.formPlate

                        RowLayout {
                            id: nRow
                            anchors.fill: parent
                            anchors.margins: Math.round(8 * root.d)
                            spacing: Math.round(8 * root.d)

                            MaterialSymbol {
                                text: "chat"
                                iconSize: Math.round(16 * root.d)
                                color: ConnectStyle.accent
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: Math.round(1 * root.d)

                                StyledText {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: `${notifItem.modelData.appName || "App"}: ${notifItem.modelData.title || ""}`
                                    color: ConnectStyle.text
                                    font.family: ConnectStyle.fontMain
                                    font.pixelSize: ConnectStyle.typeCaption
                                    font.weight: ConnectStyle.weight(Font.Bold)
                                }

                                StyledText {
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    text: notifItem.modelData.text || notifItem.modelData.ticker || ""
                                    color: ConnectStyle.subtext
                                    font.family: ConnectStyle.fontMain
                                    font.pixelSize: Math.max(9, Math.round(10 * root.d))
                                    visible: text.length > 0
                                }
                            }

                            ConnectPlate {
                                visible: Boolean(notifItem.modelData.dismissable)
                                implicitWidth: Math.round(24 * root.d)
                                implicitHeight: Math.round(24 * root.d)
                                radius: Math.round(implicitHeight / 2)
                                color: dMouse.containsMouse ? ConnectStyle.fillHover : "transparent"

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: Math.round(13 * root.d)
                                    color: ConnectStyle.subtext
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
            ConnectPlate {
                Layout.fillWidth: true
                implicitHeight: emptyCol.implicitHeight + Math.round(16 * root.d)
                radius: ConnectStyle.radiusRow
                color: ConnectStyle.fillQuiet
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
                            color: ConnectStyle.subtext
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("No active notifications on your phone")
                            color: ConnectStyle.text
                            font.family: ConnectStyle.fontMain
                            font.pixelSize: ConnectStyle.typeCaption
                            font.weight: ConnectStyle.weight(Font.Bold)
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: Translation.tr("If your notifications do not show up:\n1. Open KDE Connect on your phone (%1).\n2. Go to Plugin settings and enable 'Notification sync'.\n3. In Android Settings, grant 'Notification access' to KDE Connect.").arg(AndroidState.deviceName)
                        color: ConnectStyle.subtext
                        font.family: ConnectStyle.fontMain
                        font.pixelSize: Math.max(9, Math.round(10 * root.d))
                    }
                }
            }
        }
    }
}
