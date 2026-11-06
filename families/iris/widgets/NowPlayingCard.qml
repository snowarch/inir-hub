pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Card (his 11-06 player reference): the player's name heads the face and the hour sits in a capsule of the song's
// colour; a raised card holds the cover beside the synced lines (the one being sung in that colour), or the song's
// bars when it has no lyrics; under it the title, the artist, the timeline with its knob and the keys, play on the
// song's colour. Medium sets the card on the left and the rest beside it.
Item {
    id: view
    required property var face
    required property var media

    readonly property bool wide: view.face.medium
    readonly property bool label: view.face.nothing ?? false
    readonly property color songLight: view.label ? view.face.signal : view.face.artLight
    readonly property string stateWord: view.face.playing ? Translation.tr("Now playing") : Translation.tr("Paused")

    component Head: RowLayout {
        spacing: view.face.dp(6)
        MaterialSymbol {
            visible: !view.label
            text: "graphic_eq"
            fill: 1
            iconSize: view.face.px(17)
            color: view.songLight
        }
        FaceText {
            face: view.face
            Layout.fillWidth: true
            text: view.label ? view.face.source.toUpperCase() : view.face.source
            size: view.label ? 11 : 14
            weight: Font.DemiBold
            font.family: view.label ? view.face.fontLabel : view.face.fontMain
            font.letterSpacing: view.label ? view.face.px(11) * 0.1 : 0
        }
        Rectangle {
            Layout.preferredHeight: view.face.dp(24)
            Layout.preferredWidth: hourText.implicitWidth + view.face.dp(18)
            radius: IrisStyle.capsule(height)
            color: view.songLight
            FaceText {
                id: hourText
                face: view.face
                anchors.centerIn: parent
                text: DateTime.time
                color: view.face.onFill(view.songLight)
                size: 12.5
                weight: Font.Bold
                font.family: view.face.fontNumbers
            }
        }
    }

    component Card: Rectangle {
        id: card
        radius: view.face.innerRadius
        color: view.face.fill
        RowLayout {
            anchors.fill: parent
            anchors.margins: view.face.dp(10)
            spacing: view.face.dp(12)
            IrisArtwork {
                Layout.preferredHeight: card.height - view.face.dp(20)
                Layout.preferredWidth: Layout.preferredHeight
                source: view.face.art
                circular: false
                radius: Math.max(view.face.dp(6), Math.round(width * 0.12))
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: view.face.dp(2)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    spacing: view.face.dp(5)
                    Rectangle {
                        Layout.preferredWidth: view.face.dp(6)
                        Layout.preferredHeight: view.face.dp(6)
                        radius: width / 2
                        color: view.face.playing ? view.songLight : view.face.inkTertiary
                    }
                    FaceText {
                        face: view.face
                        Layout.fillWidth: true
                        text: view.stateWord.toUpperCase()
                        color: view.face.ink
                        size: 10.5
                        weight: Font.Bold
                        font.family: view.label ? view.face.fontLabel : view.face.fontMain
                        font.letterSpacing: view.face.px(10.5) * 0.06
                    }
                }
                Item { Layout.fillHeight: true }
                FaceText {
                    face: view.face
                    Layout.fillWidth: true
                    visible: view.face.lyricsReady && text.length > 0
                    text: LyricsService.slots[2] ?? ""
                    color: view.face.inkTertiary
                    size: 11.5
                }
                FaceText {
                    face: view.face
                    Layout.fillWidth: true
                    visible: view.face.lyricsReady
                    text: LyricsService.slots[3] || "♪"
                    color: view.songLight
                    size: 13.5
                    weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }
                FaceText {
                    face: view.face
                    Layout.fillWidth: true
                    visible: view.face.lyricsReady && text.length > 0
                    text: LyricsService.slots[4] ?? ""
                    color: view.face.inkTertiary
                    size: 11.5
                }
                IrisVisualizer {
                    visible: !view.face.lyricsReady
                    Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                    running: visible && view.face.playing && view.face.moving
                    tint: view.songLight
                    barHeight: view.face.dp(22)
                }
                Item { Layout.fillHeight: true }
            }
        }
    }

    component Timeline: ColumnLayout {
        spacing: view.face.dp(3)
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: view.face.dp(10)
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: view.face.dp(4)
                radius: IrisStyle.capsule(height)
                color: view.face.fillQuiet
                Rectangle {
                    width: parent.width * view.face.progress
                    height: parent.height
                    radius: parent.radius
                    color: view.songLight
                }
            }
            Rectangle {
                x: Math.round(parent.width * view.face.progress - width / 2)
                anchors.verticalCenter: parent.verticalCenter
                width: view.face.dp(10)
                height: width
                radius: width / 2
                color: view.songLight
            }
        }
        RowLayout {
            Layout.fillWidth: true
            FaceText {
                face: view.face
                text: StringUtils.friendlyTimeForSeconds(view.media.effectivePosition)
                color: view.face.inkTertiary
                size: 11
                font.family: view.face.fontNumbers
                font.features: ({ "tnum": 1 })
            }
            Item { Layout.fillWidth: true }
            FaceText {
                face: view.face
                text: StringUtils.friendlyTimeForSeconds(view.media.effectiveLength)
                color: view.face.inkTertiary
                size: 11
                font.family: view.face.fontNumbers
                font.features: ({ "tnum": 1 })
            }
        }
    }

    component Keys: RowLayout {
        spacing: view.face.dp(18)
        FaceAction {
            face: view.face
            implicitWidth: view.face.dp(34)
            color: "transparent"
            glyph: "skip_previous"
            name: Translation.tr("Previous")
            enabled: view.media.effectiveCanGoPrevious
            opacity: enabled ? 1 : 0.4
            onActivated: view.media.previous()
        }
        FaceAction {
            face: view.face
            implicitWidth: view.face.dp(42)
            glyph: view.face.playing ? "pause" : "play_arrow"
            name: view.face.playing ? Translation.tr("Pause") : Translation.tr("Play")
            tint: view.face.onFill(view.songLight)
            color: view.songLight
            onActivated: view.media.togglePlaying()
        }
        FaceAction {
            face: view.face
            implicitWidth: view.face.dp(34)
            color: "transparent"
            glyph: "skip_next"
            name: Translation.tr("Next")
            enabled: view.media.effectiveCanGoNext
            opacity: enabled ? 1 : 0.4
            onActivated: view.media.next()
        }
    }

    GridLayout {
        anchors.fill: parent
        columns: view.wide ? 2 : 1
        columnSpacing: view.face.dp(16)
        rowSpacing: view.face.dp(10)
        Head {
            visible: !view.wide
            Layout.fillWidth: true
            Layout.fillHeight: false
        }
        Card {
            Layout.fillWidth: !view.wide
            Layout.fillHeight: view.wide
            Layout.preferredWidth: view.wide ? view.face.contentWidth * 0.5 : -1
            Layout.preferredHeight: view.wide ? -1 : view.face.dp(112)
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: view.face.dp(2)
            Head {
                visible: view.wide
                Layout.fillWidth: true
                Layout.fillHeight: false
            }
            Item { Layout.fillHeight: true }
            FaceText {
                face: view.face
                Layout.fillWidth: true
                horizontalAlignment: view.wide ? Text.AlignLeft : Text.AlignHCenter
                text: view.media.effectiveTitle || view.face.source
                size: view.wide ? 14.5 : 17
                weight: Font.DemiBold
            }
            FaceText {
                face: view.face
                Layout.fillWidth: true
                horizontalAlignment: view.wide ? Text.AlignLeft : Text.AlignHCenter
                visible: text.length > 0
                text: view.media.effectiveArtist
                color: view.face.inkSecondary
                size: view.wide ? 12.5 : 13.5
            }
            Timeline {
                Layout.fillWidth: true
                Layout.topMargin: view.face.dp(view.wide ? 6 : 12)
                visible: view.media.effectiveLength > 0
            }
            Keys {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: view.face.dp(view.wide ? 6 : 2)
            }
            Item { Layout.fillHeight: true; visible: !view.wide }
        }
    }
}
