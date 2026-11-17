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
    readonly property bool shown: AndroidState.devicesOpen
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
        implicitHeight: col.implicitHeight + Math.round(24 * root.d)
        radius: IrisStyle.radiusCard
        color: IrisStyle.fill
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

                IrisText {
                    Layout.fillWidth: true
                    text: `${Translation.tr("Devices")} (${AndroidState.devices.length})`
                    color: IrisStyle.text
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: IrisStyle.typeLabel
                    font.weight: IrisStyle.weight(Font.Bold)
                }

                IrisButton {
                    text: Translation.tr("Scan network")
                    onClicked: AndroidState.rescanNetwork()
                }

                IrisButton {
                    text: "ADB Wi-Fi"
                    onClicked: {
                        AndroidState.devicesOpen = false
                        AndroidState.wirelessOpen = true
                    }
                }
            }

            IrisText {
                visible: AndroidState.devices.length === 0
                Layout.fillWidth: true
                text: Translation.tr("No devices detected via USB, Wireless ADB, or KDE Connect.")
                color: IrisStyle.subtext
                font.pixelSize: IrisStyle.typeMeta
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: AndroidState.devices

                delegate: IrisPlate {
                    id: devRow
                    required property var modelData
                    readonly property bool isCurrent: devRow.modelData.id === AndroidState.selectedDeviceId
                    Layout.fillWidth: true
                    implicitHeight: Math.round(48 * root.d)
                    radius: IrisStyle.radiusTile
                    lit: devRow.isCurrent
                    color: devRow.isCurrent
                        ? IrisStyle.tintFill(IrisStyle.accent)
                        : (devMouse.containsMouse ? IrisStyle.fillHover : IrisStyle.formPlate)
                    Behavior on color { ColorAnimation { duration: IrisStyle.feedbackDuration } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(12 * root.d)
                        anchors.rightMargin: Math.round(12 * root.d)
                        spacing: Math.round(10 * root.d)

                        IrisSquircle {
                            Layout.preferredWidth: Math.round(30 * root.d)
                            Layout.preferredHeight: Math.round(30 * root.d)
                            glyph: devRow.modelData.online ? "phone_android" : "phonelink_off"
                            tint: devRow.isCurrent ? IrisStyle.accent : (devRow.modelData.online ? IrisStyle.secondaryAccent : IrisStyle.identity.gray)
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: Math.round(1 * root.d)

                            IrisText {
                                width: parent.width
                                elide: Text.ElideRight
                                text: devRow.modelData.name
                                color: IrisStyle.text
                                font.pixelSize: IrisStyle.typeBody
                                font.weight: IrisStyle.weight(devRow.isCurrent ? Font.Bold : Font.Medium)
                            }

                            IrisText {
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
                                color: IrisStyle.subtext
                                font.pixelSize: IrisStyle.typeCaption
                            }
                        }

                        IrisText {
                            visible: (devRow.modelData.batteryLevel ?? -1) >= 0
                            text: `${devRow.modelData.batteryLevel}%`
                            color: IrisStyle.subtext
                            font.family: IrisStyle.fontNumbers
                            font.pixelSize: IrisStyle.typeMeta
                            font.weight: IrisStyle.weight(Font.Bold)
                        }

                        MaterialSymbol {
                            visible: devRow.isCurrent
                            text: "check_circle"
                            iconSize: Math.round(18 * root.d)
                            fill: 1
                            color: IrisStyle.accent
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
