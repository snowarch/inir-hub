pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

IrisPlate {
    id: root
    readonly property real d: IrisStyle.density
    readonly property int coverSize: Math.max(Math.round(38 * root.d), Math.min(Math.round(66 * root.d), root.height - Math.round(14 * root.d)))
    Layout.fillWidth: true
    implicitHeight: Math.round(56 * root.d)
    radius: IrisStyle.radiusTile
    lit: AndroidState.mediaPlaying
    color: AndroidState.mediaPlaying ? IrisStyle.tintFill(IrisStyle.accent) : IrisStyle.formPlate
    Behavior on color { ColorAnimation { duration: IrisStyle.feedbackDuration } }

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
            color: IrisStyle.fillQuiet

            IrisSquircle {
                anchors.fill: parent
                visible: coverImg.status !== Image.Ready
                glyph: AndroidState.mediaPlaying ? "equalizer" : "music_note"
                tint: AndroidState.mediaPlaying ? IrisStyle.accent : IrisStyle.secondaryAccent
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

            IrisText {
                width: parent.width
                elide: Text.ElideRight
                text: AndroidState.mediaTitle.length > 0 ? AndroidState.mediaTitle : "Multimedia"
                color: IrisStyle.text
                font.pixelSize: IrisStyle.typeCaption
                font.weight: IrisStyle.weight(Font.Bold)
            }

            IrisText {
                width: parent.width
                elide: Text.ElideRight
                text: AndroidState.mediaArtist.length > 0
                    ? AndroidState.mediaArtist
                    : (AndroidState.mediaPlaying ? "Reproduciendo en teléfono" : "Control de reproducción")
                color: IrisStyle.subtext
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

                delegate: IrisPlate {
                    id: mBtn
                    required property var modelData
                    readonly property bool isPrimary: Boolean(mBtn.modelData.primary)
                    implicitWidth: Math.round((mBtn.isPrimary ? 30 : 26) * root.d)
                    implicitHeight: Math.round((mBtn.isPrimary ? 30 : 26) * root.d)
                    radius: Math.round(implicitHeight / 2)
                    color: mBtn.isPrimary
                        ? (mMouse.containsMouse ? IrisStyle.accent : IrisStyle.accentFill)
                        : (mMouse.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet)
                    scale: mMouse.pressed ? IrisStyle.pressScale(0.92) : 1.0
                    Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
                    Behavior on color { ColorAnimation { duration: IrisStyle.feedbackDuration } }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: mBtn.modelData.icon
                        iconSize: Math.round((mBtn.isPrimary ? 16 : 14) * root.d)
                        fill: mBtn.isPrimary ? 1 : 0
                        color: mBtn.isPrimary ? IrisStyle.inkOnAccentFill : IrisStyle.text
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
