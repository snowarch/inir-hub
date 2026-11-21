pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.shared.rest

// Material's rest screen: the wallpaper softened behind a slowly turning cookie that holds the time, the date under it
// and, while something plays, what it is.
RestWindow {
    id: rest

    readonly property var player: MprisController.activePlayer
    readonly property bool playing: rest.player?.isPlaying ?? false

    backdrop: Component {
        Item {
            id: back
            property var screen: null

            // Opaque under everything: the blur fades its edges, and the desktop must not show through them.
            Rectangle {
                anchors.fill: parent
                color: Appearance.colors.colLayer0
            }
            Image {
                id: wall
                anchors.fill: parent
                anchors.margins: Appearance.effectsEnabled ? -48 : 0
                source: back.screen ? rest.wallpaperOf(back.screen) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: Math.round(back.width / 2)
                sourceSize.height: Math.round(back.height / 2)
                visible: !Appearance.effectsEnabled
            }
            MultiEffect {
                anchors.fill: wall
                visible: Appearance.effectsEnabled
                source: wall
                blurEnabled: true
                blurMax: 48
                blur: 1
                saturation: 0.15
            }
            Rectangle {
                anchors.fill: parent
                color: Appearance.colors.colLayer0
                opacity: 0.62
            }
        }
    }

    face: Component {
        Item {
            id: face
            readonly property real unit: Math.min(face.width, face.height)
            readonly property real cookie: Math.round(face.unit * 0.42)

            Column {
                anchors.centerIn: parent
                spacing: Math.round(face.unit * 0.035)

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: face.cookie
                    height: face.cookie

                    MaterialShape {
                        id: shape
                        anchors.fill: parent
                        implicitSize: face.cookie
                        shape: MaterialShape.Shape.Cookie12Sided
                        color: Appearance.colors.colPrimaryContainer
                        RotationAnimation on rotation {
                            running: Appearance.animationsEnabled && rest.shown
                            from: 0
                            to: 360
                            duration: 120000
                            loops: Animation.Infinite
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: DateTime.time
                        font.family: Appearance.font.family.numbers
                        font.pixelSize: Math.round(face.cookie * 0.25)
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnPrimaryContainer
                    }
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: DateTime.date
                    font.family: Appearance.font.family.title
                    font.pixelSize: Math.round(face.cookie * 0.08)
                    font.capitalization: Font.Capitalize
                    color: Appearance.colors.colOnLayer0
                }

                // What plays, as a pill; the cover turns like a record while it plays.
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: rest.player !== null && (MprisController.titleOf(rest.player) ?? "").length > 0
                    width: Math.min(face.width * 0.5, nowRow.implicitWidth + 24)
                    height: 56
                    radius: height / 2
                    color: Appearance.colors.colSecondaryContainer

                    Row {
                        id: nowRow
                        anchors.verticalCenter: parent.verticalCenter
                        x: 10
                        width: parent.width - 24
                        spacing: 12

                        Item {
                            width: 36
                            height: 36
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: Appearance.colors.colPrimaryContainer
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "music_note"
                                    iconSize: 20
                                    color: Appearance.colors.colOnPrimaryContainer
                                }
                            }
                            StyledImage {
                                id: art
                                anchors.fill: parent
                                source: MprisController.artUrlOf(rest.player) ?? ""
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(72, 72)
                                visible: false
                            }
                            MultiEffect {
                                anchors.fill: parent
                                source: art
                                visible: art.status === Image.Ready
                                maskEnabled: true
                                maskSource: artMask
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1
                                RotationAnimation on rotation {
                                    running: Appearance.animationsEnabled && rest.shown && rest.playing
                                    from: 0
                                    to: 360
                                    duration: 16000
                                    loops: Animation.Infinite
                                }
                            }
                            Rectangle {
                                id: artMask
                                anchors.fill: parent
                                radius: width / 2
                                visible: false
                                layer.enabled: true
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 48
                            StyledText {
                                width: parent.width
                                text: MprisController.titleOf(rest.player) ?? ""
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            StyledText {
                                width: parent.width
                                visible: text.length > 0
                                text: MprisController.artistOf(rest.player) ?? ""
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: ColorUtils.transparentize(Appearance.colors.colOnSecondaryContainer, 0.3)
                            }
                        }
                    }
                }
            }
        }
    }
}
