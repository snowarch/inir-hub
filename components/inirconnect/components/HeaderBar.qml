pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import "../state"

Item {
    id: root
    readonly property real d: ConnectStyle.density
    readonly property bool compact: root.width > 0 && root.width < Math.round(440 * root.d)
    implicitHeight: mainRow.implicitHeight

    RowLayout {
        id: mainRow
        anchors.fill: parent
        spacing: Math.round((root.compact ? 6 : 10) * root.d)

        ConnectSquircle {
            Layout.preferredWidth: Math.round((root.compact ? 30 : 34) * root.d)
            Layout.preferredHeight: Math.round((root.compact ? 30 : 34) * root.d)
            glyph: AndroidState.connected ? "phone_android" : "smartphone"
            tint: AndroidState.connected ? ConnectStyle.accent : ConnectStyle.gray
        }

        ColumnLayout {
            id: titleCol
            clip: true
            Layout.fillWidth: true
            Layout.minimumWidth: Math.round(140 * root.d)
            spacing: Math.round(1 * root.d)

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * root.d)

                StyledText {
                    Layout.maximumWidth: Math.round((root.compact ? 115 : 190) * root.d)
                    elide: Text.ElideRight
                    text: AndroidState.connected ? AndroidState.deviceName : Translation.tr("No device connected")
                    color: ConnectStyle.text
                    font.family: ConnectStyle.fontTitle
                    font.pixelSize: root.compact ? ConnectStyle.typeBody : ConnectStyle.typeHeadline
                    font.weight: ConnectStyle.weight(Font.Bold)
                }

                ConnectPlate {
                    id: devBadge
                    visible: AndroidState.devices.length > 0
                    Layout.preferredWidth: devBadgeRow.implicitWidth + Math.round(10 * root.d)
                    Layout.preferredHeight: Math.round(18 * root.d)
                    implicitWidth: devBadgeRow.implicitWidth + Math.round(10 * root.d)
                    implicitHeight: Math.round(18 * root.d)
                    radius: Math.round(9 * root.d)
                    lit: AndroidState.devicesOpen
                    color: AndroidState.devicesOpen ? ConnectStyle.accentFill : ConnectStyle.formPlate

                    Row {
                        id: devBadgeRow
                        anchors.centerIn: parent
                        spacing: Math.round(2 * root.d)

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: AndroidState.devices.length > 1
                                ? `${AndroidState.devices.length} disp.`
                                : "Cambiar"
                            color: AndroidState.devicesOpen ? ConnectStyle.inkOnAccentFill : ConnectStyle.subtext
                            font.family: ConnectStyle.fontMain
                            font.pixelSize: Math.max(9, Math.round(10 * root.d))
                            font.weight: ConnectStyle.weight(Font.Bold)
                        }

                        MaterialSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            text: AndroidState.devicesOpen ? "expand_less" : "expand_more"
                            iconSize: Math.round(13 * root.d)
                            color: AndroidState.devicesOpen ? ConnectStyle.inkOnAccentFill : ConnectStyle.subtext
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AndroidState.toggleSheet("devices")
                    }
                }

                Item { Layout.fillWidth: true }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(5 * root.d)

                Rectangle {
                    width: Math.round(6 * root.d)
                    height: width
                    radius: width / 2
                    color: AndroidState.connected ? ConnectStyle.success : ConnectStyle.muted
                    Behavior on color { ColorAnimation { duration: ConnectStyle.revealDuration } }
                }

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: {
                        if (!AndroidState.connected)
                            return Translation.tr("Offline")
                        if (AndroidState.hasAdb && AndroidState.hasKde)
                            return "ADB + KDE Connect"
                        if (AndroidState.connectionType === "wireless")
                            return Translation.tr("Wireless ADB")
                        if (AndroidState.connectionType === "adb")
                            return Translation.tr("ADB connected")
                        return AndroidState.deviceIp.length > 0
                            ? `KDE Connect (${AndroidState.deviceIp})`
                            : "KDE Connect"
                    }
                    color: ConnectStyle.subtext
                    font.family: ConnectStyle.fontMain
                    font.pixelSize: ConnectStyle.typeCaption
                }
            }
        }

        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: Math.round((root.compact ? 2 : 4) * root.d)

            readonly property int btnSize: Math.round((root.compact ? 28 : 32) * root.d)
            readonly property int glyphSize: Math.round((root.compact ? 16 : 17) * root.d)

            ConnectIconButton {
                implicitWidth: parent.btnSize
                implicitHeight: parent.btnSize
                iconSize: parent.glyphSize
                materialIcon: "notifications"
                selected: AndroidState.notificationsOpen
                Accessible.name: "Notificaciones del teléfono"
                onClicked: AndroidState.toggleSheet("notifications")
            }

            ConnectIconButton {
                implicitWidth: parent.btnSize
                implicitHeight: parent.btnSize
                iconSize: parent.glyphSize
                materialIcon: "music_note"
                selected: AndroidState.mediaVisible
                Accessible.name: "Multimedia"
                onClicked: AndroidState.mediaVisible = !AndroidState.mediaVisible
            }

            ConnectIconButton {
                implicitWidth: parent.btnSize
                implicitHeight: parent.btnSize
                iconSize: parent.glyphSize
                materialIcon: "wifi"
                selected: AndroidState.wirelessOpen
                Accessible.name: Translation.tr("Wireless pairing")
                onClicked: AndroidState.toggleSheet("wireless")
            }

            ConnectIconButton {
                implicitWidth: parent.btnSize
                implicitHeight: parent.btnSize
                iconSize: parent.glyphSize
                materialIcon: "lock_open"
                Accessible.name: Translation.tr("Wake and unlock")
                onClicked: AndroidState.wakeAndUnlock()
            }

            ConnectIconButton {
                implicitWidth: parent.btnSize
                implicitHeight: parent.btnSize
                iconSize: parent.glyphSize
                materialIcon: AndroidState.verticalLayout ? "view_column" : "view_agenda"
                selected: AndroidState.verticalLayout
                Accessible.name: AndroidState.verticalLayout ? "Distribución horizontal" : "Distribución vertical"
                onClicked: AndroidState.verticalLayout = !AndroidState.verticalLayout
            }

            ConnectIconButton {
                implicitWidth: parent.btnSize
                implicitHeight: parent.btnSize
                iconSize: parent.glyphSize
                materialIcon: AndroidState.windowed ? "close_fullscreen" : "open_in_new"
                selected: AndroidState.windowed
                Accessible.name: AndroidState.windowed ? Translation.tr("Open over the desktop") : Translation.tr("Open in window")
                onClicked: AndroidState.windowed = !AndroidState.windowed
            }

            ConnectIconButton {
                visible: !AndroidState.windowed
                implicitWidth: parent.btnSize
                implicitHeight: parent.btnSize
                iconSize: parent.glyphSize
                materialIcon: "keep"
                selected: AndroidState.pinned
                Accessible.name: AndroidState.pinned ? Translation.tr("Stop keeping open") : Translation.tr("Keep open")
                onClicked: AndroidState.pinned = !AndroidState.pinned
            }

            ConnectIconButton {
                implicitWidth: parent.btnSize
                implicitHeight: parent.btnSize
                iconSize: parent.glyphSize
                materialIcon: "refresh"
                Accessible.name: Translation.tr("Refresh devices")
                onClicked: AndroidState.refresh()
            }

            ConnectIconButton {
                visible: !AndroidState.windowed
                implicitWidth: parent.btnSize
                implicitHeight: parent.btnSize
                iconSize: parent.glyphSize
                materialIcon: "close"
                Accessible.name: Translation.tr("Close")
                onClicked: AndroidState.open = false
            }
        }
    }
}
