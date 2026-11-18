pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.common.widgets
import "../state"

ConnectPlate {
    id: root
    readonly property real d: ConnectStyle.density
    readonly property int coverSize: Math.max(Math.round(38 * root.d), Math.min(Math.round(66 * root.d), root.height - Math.round(14 * root.d)))
    Layout.fillWidth: true
    implicitHeight: Math.round(56 * root.d)
    radius: ConnectStyle.radiusTile
    lit: AndroidState.mediaPlaying
    color: AndroidState.mediaPlaying ? ConnectStyle.tintFill(ConnectStyle.accent) : ConnectStyle.formPlate
    Behavior on color { ColorAnimation { duration: ConnectStyle.feedbackDuration } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Math.round(8 * root.d)
        anchors.rightMargin: Math.round(8 * root.d)
        spacing: Math.round(10 * root.d)

        ClippingRectangle {
            Layout.preferredWidth: root.coverSize
            Layout.preferredHeight: root.coverSize
            Layout.alignment: Qt.AlignVCenter
            radius: Math.round(9 * root.d)
            color: ConnectStyle.fillQuiet

            ConnectSquircle {
                anchors.fill: parent
                visible: coverImg.status !== Image.Ready
                glyph: AndroidState.mediaPlaying ? "equalizer" : "music_note"
                tint: AndroidState.mediaPlaying ? ConnectStyle.accent : ConnectStyle.secondaryAccent
            }

            Image {
                id: coverImg
                anchors.fill: parent
                source: AndroidState.mediaArtUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                mipmap: true
                visible: coverImg.status === Image.Ready
            }
        }

        Column {
            Layout.fillWidth: true
            spacing: Math.round(1 * root.d)

            StyledText {
                width: parent.width
                elide: Text.ElideRight
                text: AndroidState.mediaTitle.length > 0 ? AndroidState.mediaTitle : "Multimedia"
                color: ConnectStyle.text
                font.family: ConnectStyle.fontMain
                font.pixelSize: ConnectStyle.typeCaption
                font.weight: ConnectStyle.weight(Font.Bold)
            }

            StyledText {
                width: parent.width
                elide: Text.ElideRight
                text: AndroidState.mediaArtist.length > 0
                    ? AndroidState.mediaArtist
                    : (AndroidState.mediaPlaying ? "Reproduciendo en teléfono" : "Control de reproducción")
                color: ConnectStyle.subtext
                font.family: ConnectStyle.fontMain
                font.pixelSize: Math.max(9, Math.round(10 * root.d))
            }
        }

        RowLayout {
            spacing: Math.round(4 * root.d)

            Repeater {
                model: [
                    { icon: "volume_down", cmd: "voldown", tip: "Bajar volumen" },
                    { icon: "skip_previous", cmd: "prev", tip: "Anterior" },
                    { icon: AndroidState.mediaPlaying ? "pause" : "play_arrow", cmd: "playpause", tip: "Reproducir / Pausar", primary: true },
                    { icon: "skip_next", cmd: "next", tip: "Siguiente" },
                    { icon: "volume_up", cmd: "volup", tip: "Subir volumen" }
                ]

                delegate: ConnectPlate {
                    id: mBtn
                    required property var modelData
                    readonly property bool isPrimary: Boolean(mBtn.modelData.primary)
                    implicitWidth: Math.round((mBtn.isPrimary ? 30 : 26) * root.d)
                    implicitHeight: Math.round((mBtn.isPrimary ? 30 : 26) * root.d)
                    radius: Math.round(implicitHeight / 2)
                    color: mBtn.isPrimary
                        ? (mMouse.containsMouse ? ConnectStyle.accentHover : ConnectStyle.accentFill)
                        : (mMouse.containsMouse ? ConnectStyle.fillHover : ConnectStyle.fillQuiet)
                    scale: mMouse.pressed ? ConnectStyle.pressScale(0.92) : 1.0
                    Behavior on scale { NumberAnimation { duration: ConnectStyle.feedbackDuration; easing.type: ConnectStyle.feedbackEasing } }
                    Behavior on color { ColorAnimation { duration: ConnectStyle.feedbackDuration } }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: mBtn.modelData.icon
                        iconSize: Math.round((mBtn.isPrimary ? 16 : 14) * root.d)
                        fill: mBtn.isPrimary ? 1 : 0
                        color: mBtn.isPrimary ? ConnectStyle.inkOnAccentFill : ConnectStyle.text
                    }

                    MouseArea {
                        id: mMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AndroidState.mediaAction(mBtn.modelData.cmd)
                    }
                }
            }
        }
    }
}
