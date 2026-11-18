pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import "../state"

Item {
    id: root
    readonly property real d: ConnectStyle.density
    readonly property bool shown: AndroidState.devicesOpen
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
        implicitHeight: col.implicitHeight + Math.round(24 * root.d)
        radius: ConnectStyle.radiusCard
        color: ConnectStyle.fill
        clip: true

        ColumnLayout {
            id: col
            width: parent.width - Math.round(24 * root.d)
            x: Math.round(12 * root.d)
            y: Math.round(12 * root.d)
            spacing: Math.round(8 * root.d)

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * root.d)

                StyledText {
                    Layout.fillWidth: true
                    text: `${Translation.tr("Devices")} (${AndroidState.devices.length})`
                    color: ConnectStyle.text
                    font.family: ConnectStyle.fontTitle
                    font.pixelSize: ConnectStyle.typeLabel
                    font.weight: ConnectStyle.weight(Font.Bold)
                }

                ConnectButton {
                    text: Translation.tr("Scan network")
                    onClicked: AndroidState.rescanNetwork()
                }

                ConnectButton {
                    text: "ADB Wi-Fi"
                    onClicked: {
                        AndroidState.devicesOpen = false
                        AndroidState.wirelessOpen = true
                    }
                }
            }

            StyledText {
                visible: AndroidState.devices.length === 0
                Layout.fillWidth: true
                text: Translation.tr("No devices detected via USB, Wireless ADB, or KDE Connect.")
                color: ConnectStyle.subtext
                font.family: ConnectStyle.fontMain
                font.pixelSize: ConnectStyle.typeMeta
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: AndroidState.devices

                delegate: ConnectPlate {
                    id: devRow
                    required property var modelData
                    readonly property bool isCurrent: devRow.modelData.id === AndroidState.selectedDeviceId
                    Layout.fillWidth: true
                    implicitHeight: Math.round(48 * root.d)
                    radius: ConnectStyle.radiusTile
                    lit: devRow.isCurrent
                    color: devRow.isCurrent
                        ? ConnectStyle.tintFill(ConnectStyle.accent)
                        : (devMouse.containsMouse ? ConnectStyle.fillHover : ConnectStyle.formPlate)
                    Behavior on color { ColorAnimation { duration: ConnectStyle.feedbackDuration } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(12 * root.d)
                        anchors.rightMargin: Math.round(12 * root.d)
                        spacing: Math.round(10 * root.d)

                        ConnectSquircle {
                            Layout.preferredWidth: Math.round(30 * root.d)
                            Layout.preferredHeight: Math.round(30 * root.d)
                            glyph: devRow.modelData.online ? "phone_android" : "phonelink_off"
                            tint: devRow.isCurrent ? ConnectStyle.accent : (devRow.modelData.online ? ConnectStyle.secondaryAccent : ConnectStyle.gray)
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: Math.round(1 * root.d)

                            StyledText {
                                width: parent.width
                                elide: Text.ElideRight
                                text: devRow.modelData.name
                                color: ConnectStyle.text
                                font.family: ConnectStyle.fontMain
                                font.pixelSize: ConnectStyle.typeBody
                                font.weight: ConnectStyle.weight(devRow.isCurrent ? Font.Bold : Font.Medium)
                            }

                            StyledText {
                                width: parent.width
                                elide: Text.ElideRight
                                text: {
                                    const d = devRow.modelData
                                    const badge = d.serial && d.kdeId ? "ADB + KDE Connect"
                                        : d.serial ? (d.serial.includes(":") ? "ADB Wi-Fi" : "ADB USB")
                                        : (d.online ? "KDE Connect" : "KDE Connect (Sin conexión)")
                                    const addr = d.ip || d.serial || ""
                                    return addr.length > 0 ? `${badge} • ${addr}` : badge
                                }
                                color: ConnectStyle.subtext
                                font.family: ConnectStyle.fontMain
                                font.pixelSize: ConnectStyle.typeCaption
                            }
                        }

                        StyledText {
                            visible: (devRow.modelData.batteryLevel ?? -1) >= 0
                            text: `${devRow.modelData.batteryLevel}%`
                            color: ConnectStyle.subtext
                            font.family: ConnectStyle.fontNumbers
                            font.pixelSize: ConnectStyle.typeMeta
                            font.weight: ConnectStyle.weight(Font.Bold)
                        }

                        MaterialSymbol {
                            visible: devRow.isCurrent
                            text: "check_circle"
                            iconSize: Math.round(18 * root.d)
                            fill: 1
                            color: ConnectStyle.accent
                        }
                    }

                    MouseArea {
                        id: devMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AndroidState.selectDevice(devRow.modelData.id)
                    }
                }
            }
        }
    }
}
