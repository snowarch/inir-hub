pragma ComponentBehavior: Bound
import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.shared.rest
import qs.modules.waffle.looks

// Waffle's rest screen, a lock screen with nothing to unlock: the wallpaper as it is, the time and the date high in the
// middle and, while something plays, a small card of it at the foot.
RestWindow {
    id: rest

    readonly property var player: MprisController.activePlayer
    readonly property string title: MprisController.titleOf(rest.player) ?? ""
    readonly property bool shadows: Looks.effectsEnabled

    backdrop: Component {
        Item {
            id: back
            property var screen: null

            Image {
                anchors.fill: parent
                source: back.screen ? rest.wallpaperOf(back.screen) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: back.width
                sourceSize.height: back.height
            }
            // A smoke that keeps the time readable on any wallpaper, heavier at the top where it sits.
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: ColorUtils.transparentize(Looks.colors.bg0Opaque, 0.45) }
                    GradientStop { position: 0.55; color: ColorUtils.transparentize(Looks.colors.bg0Opaque, 0.7) }
                    GradientStop { position: 1; color: ColorUtils.transparentize(Looks.colors.bg0Opaque, 0.5) }
                }
            }
        }
    }

    face: Component {
        Item {
            id: face

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.round(face.height * 0.12)
                spacing: Looks.dp(2)

                WText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: DateTime.time
                    font.pixelSize: Math.round(112 * Looks.fontScale)
                    font.weight: Looks.font.weight.thin
                    layer.enabled: rest.shadows
                    layer.effect: DropShadow { verticalOffset: 1; radius: 8; samples: 17; color: Looks.colors.shadow }
                }
                WText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Translation.locale.toString(DateTime.clock.date, "dddd, MMMM d")
                    font.pixelSize: Math.round(22 * Looks.fontScale)
                    layer.enabled: rest.shadows
                    layer.effect: DropShadow { verticalOffset: 1; radius: 4; samples: 9; color: Looks.colors.shadow }
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Math.round(face.height * 0.08)
                visible: rest.title.length > 0
                width: Math.min(Looks.dp(360), face.width - Looks.dp(48))
                height: Looks.dp(72)
                radius: Looks.radius.xLarge
                color: ColorUtils.transparentize(Looks.colors.bg1Base, 0.15)
                border.width: 1
                border.color: ColorUtils.transparentize(Looks.colors.bg1Border, 0.5)

                Row {
                    anchors.fill: parent
                    anchors.margins: Looks.dp(12)
                    spacing: Looks.dp(12)

                    Rectangle {
                        width: parent.height
                        height: width
                        radius: Looks.radius.medium
                        color: Looks.colors.bg2Base
                        clip: true
                        FluentIcon {
                            anchors.centerIn: parent
                            icon: "music-note-2"
                            implicitSize: Looks.dp(20)
                        }
                        Image {
                            anchors.fill: parent
                            source: MprisController.artUrlOf(rest.player) ?? ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize: Qt.size(96, 96)
                            visible: status === Image.Ready
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - parent.height - parent.spacing
                        WText {
                            width: parent.width
                            text: rest.title
                            elide: Text.ElideRight
                            font.pixelSize: Looks.font.pixelSize.larger
                            font.weight: Looks.font.weight.regular
                        }
                        WText {
                            width: parent.width
                            visible: text.length > 0
                            text: MprisController.artistOf(rest.player) ?? ""
                            elide: Text.ElideRight
                            color: Looks.colors.subfg
                        }
                    }
                }
            }
        }
    }
}
