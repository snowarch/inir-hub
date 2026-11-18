pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import "../state"

Item {
    id: root
    readonly property real d: ConnectStyle.density
    readonly property bool shown: AndroidState.shareOpen
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
                    text: AndroidState.connected
                        ? `${Translation.tr("Send to")} ${AndroidState.deviceName}`
                        : Translation.tr("Send file or text")
                    color: ConnectStyle.text
                    font.family: ConnectStyle.fontTitle
                    font.pixelSize: ConnectStyle.typeLabel
                    font.weight: ConnectStyle.weight(Font.Bold)
                }

                ConnectButton {
                    emphasized: true
                    text: Translation.tr("Choose file...")
                    onClicked: AndroidState.shareFileDialog()
                }

                ConnectButton {
                    text: Translation.tr("Browse folders")
                    onClicked: AndroidState.browseFiles()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * root.d)

                ConnectPlate {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(34 * root.d)
                    radius: ConnectStyle.radiusRow
                    color: ConnectStyle.fillQuiet

                    TextInput {
                        id: shareInput
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
                            if (shareInput.text.trim().length > 0) {
                                AndroidState.sendTextOrPath(shareInput.text.trim())
                                shareInput.text = ""
                            }
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: shareInput.text.length === 0 && !shareInput.activeFocus
                            text: Translation.tr("Paste a path (/path/file), URL link, or text...")
                            color: ConnectStyle.muted
                            font.family: ConnectStyle.fontMain
                            font.pixelSize: ConnectStyle.typeMeta
                        }
                    }
                }

                ConnectButton {
                    enabled: shareInput.text.trim().length > 0
                    text: Translation.tr("Send")
                    onClicked: {
                        AndroidState.sendTextOrPath(shareInput.text.trim())
                        shareInput.text = ""
                    }
                }
            }

            StyledText {
                visible: AndroidState.recentFiles.length > 0
                text: Translation.tr("RECENT FILES (CLICK TO SEND)")
                color: ConnectStyle.subtext
                font.family: ConnectStyle.fontLabel
                font.pixelSize: ConnectStyle.typeCaption
                font.weight: ConnectStyle.weight(Font.Bold)
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

                    delegate: ConnectPlate {
                        id: fileChip
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: Math.round(34 * root.d)
                        radius: ConnectStyle.radiusTile
                        color: fileMouse.containsMouse ? ConnectStyle.fillHover : ConnectStyle.formPlate
                        Behavior on color { ColorAnimation { duration: ConnectStyle.feedbackDuration } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(10 * root.d)
                            anchors.rightMargin: Math.round(10 * root.d)
                            spacing: Math.round(6 * root.d)

                            MaterialSymbol {
                                text: "description"
                                iconSize: Math.round(16 * root.d)
                                color: ConnectStyle.accent
                            }

                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                                text: fileChip.modelData.name
                                color: ConnectStyle.text
                                font.family: ConnectStyle.fontMain
                                font.pixelSize: ConnectStyle.typeCaption
                                font.weight: ConnectStyle.weight(Font.Medium)
                            }

                            MaterialSymbol {
                                text: "send"
                                iconSize: Math.round(14 * root.d)
                                color: ConnectStyle.subtext
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
