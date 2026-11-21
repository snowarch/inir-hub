pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.shared.rest
import qs.modules.iris.style
import qs.modules.iris.components

// iRiS's rest screen, a standby: the wallpaper dimmed, the date and a large clock low on the left in iRiS's own figures
// and, while something plays, its cover and name under them.
RestWindow {
    id: rest

    readonly property var player: MprisController.activePlayer
    readonly property string title: MprisController.titleOf(rest.player) ?? ""

    backdrop: Component {
        Item {
            id: back
            property var screen: null

            IrisWallpaperView {
                anchors.fill: parent
                screen: back.screen
                live: false
            }
            // Dimmed for rest, and darker where the words sit so they read on any wallpaper.
            Rectangle {
                anchors.fill: parent
                color: "#000000" // iris-literal: the dim of a screen at rest
                opacity: 0.32
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#8c000000" } // iris-literal: shade under the words
                    GradientStop { position: 0.65; color: "#00000000" } // iris-literal: shade under the words
                }
            }
        }
    }

    face: Component {
        Item {
            id: face
            readonly property real unit: Math.min(face.width, face.height)

            Column {
                x: Math.round(face.width * 0.08)
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Math.round(face.height * 0.12)
                spacing: Math.round(face.unit * 0.012)

                IrisText {
                    role: IrisText.Eyebrow
                    tone: IrisStyle.onMediaSecondary
                    font.pixelSize: Math.round(IrisStyle.typeTitle * Math.max(1, face.unit / 1080))
                    text: DateTime.date
                }

                IrisClock {
                    pixelSize: Math.round(face.unit * 0.2)
                    color: IrisStyle.onMedia
                    separatorColor: IrisStyle.accent
                }

                Row {
                    visible: rest.title.length > 0
                    topPadding: Math.round(face.unit * 0.02)
                    spacing: 14

                    IrisArtwork {
                        width: Math.round(56 * IrisStyle.density)
                        height: width
                        source: MprisController.artUrlOf(rest.player) ?? ""
                        decodeSize: 112
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        IrisText {
                            width: Math.min(implicitWidth, face.width * 0.36)
                            role: IrisText.Name
                            tone: IrisStyle.onMedia
                            elide: Text.ElideRight
                            text: rest.title
                        }
                        IrisText {
                            width: Math.min(implicitWidth, face.width * 0.36)
                            visible: text.length > 0
                            role: IrisText.Meta
                            tone: IrisStyle.onMediaSecondary
                            elide: Text.ElideRight
                            text: MprisController.artistOf(rest.player) ?? ""
                        }
                    }
                }
            }
        }
    }
}
