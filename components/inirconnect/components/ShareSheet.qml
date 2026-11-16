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
    readonly property bool shown: AndroidState.shareOpen
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
                    text: AndroidState.connected
                        ? `Enviar a ${AndroidState.deviceName}`
                        : "Enviar archivo o texto"
                    color: IrisStyle.text
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: IrisStyle.typeLabel
                    font.weight: IrisStyle.weight(Font.Bold)
                }

                IrisButton {
                    emphasized: true
                    text: "Elegir archivo..."
                    onClicked: AndroidState.shareFileDialog()
                }

                IrisButton {
                    text: "Abrir carpetas"
                    onClicked: AndroidState.browseFiles()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * root.d)

                IrisPlate {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(34 * root.d)
                    radius: IrisStyle.radiusRow
                    color: IrisStyle.fillQuiet

                    TextInput {
                        id: shareInput
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(10 * root.d)
                        anchors.rightMargin: Math.round(10 * root.d)
                        verticalAlignment: TextInput.AlignVCenter
                        color: IrisStyle.text
                        font.pixelSize: IrisStyle.typeMeta
                        clip: true
                        text: ""
                        onAccepted: {
                            if (shareInput.text.trim().length > 0) {
                                AndroidState.sendTextOrPath(shareInput.text.trim())
                                shareInput.text = ""
                            }
                        }

                        IrisText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: shareInput.text.length === 0 && !shareInput.activeFocus
                            text: "Pega una ruta (/ruta/archivo), enlace URL o texto..."
                            color: IrisStyle.muted
                            font.pixelSize: IrisStyle.typeMeta
                        }
                    }
                }

                IrisButton {
                    enabled: shareInput.text.trim().length > 0
                    text: "Enviar"
                    onClicked: {
                        AndroidState.sendTextOrPath(shareInput.text.trim())
                        shareInput.text = ""
                    }
                }
            }

            IrisText {
                visible: AndroidState.recentFiles.length > 0
                text: "ARCHIVOS RECIENTES (CLIC PARA ENVIAR)"
                color: IrisStyle.subtext
                font.family: IrisStyle.fontLabel
                font.pixelSize: IrisStyle.typeCaption
                font.weight: IrisStyle.weight(Font.Bold)
                font.letterSpacing: 0.6
            }

            GridLayout {
                visible: AndroidState.recentFiles.length > 0
                Layout.fillWidth: true
                columns: 2
                rowSpacing: Math.round(6 * root.d)
                columnSpacing: Math.round(6 * root.d)

                Repeater {
                    model: AndroidState.recentFiles

                    delegate: IrisPlate {
                        id: fileChip
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: Math.round(34 * root.d)
                        radius: IrisStyle.radiusRow
                        color: fileMouse.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet
                        Behavior on color { ColorAnimation { duration: IrisStyle.feedbackDuration } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(10 * root.d)
                            anchors.rightMargin: Math.round(10 * root.d)
                            spacing: Math.round(6 * root.d)

                            MaterialSymbol {
                                text: "description"
                                iconSize: Math.round(16 * root.d)
                                color: IrisStyle.accent
                            }

                            IrisText {
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                                text: fileChip.modelData.name
                                color: IrisStyle.text
                                font.pixelSize: IrisStyle.typeCaption
                                font.weight: IrisStyle.weight(Font.Medium)
                            }

                            MaterialSymbol {
                                text: "send"
                                iconSize: Math.round(14 * root.d)
                                color: IrisStyle.subtext
                            }
                        }

                        MouseArea {
                            id: fileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AndroidState.sendFilePath(fileChip.modelData.path)
                        }
                    }
                }
            }
        }
    }
}
