pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import "radio.js" as R

// The tuner's foot: what plays (logo, station, place, the song it announces, with copy and look-up), its star, play
// and next, and the volume.
Item {
    id: root

    property var look
    readonly property real d: root.look?.d ?? 1
    readonly property var station: Radio.current
    readonly property bool song: Radio.playing && Radio.onAir.length > 0

    implicitHeight: Math.round(84 * root.d)
    height: implicitHeight

    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 1
        color: root.look.line
    }

    RadioLogo {
        id: logo
        x: Math.round(18 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        look: root.look
        station: root.station
        size: Math.round(52 * root.d)
        visible: root.station !== null
    }
    Column {
        anchors.left: root.station ? logo.right : parent.left
        anchors.leftMargin: Math.round((root.station ? 14 : 22) * root.d)
        anchors.right: actions.left
        anchors.rightMargin: Math.round(16 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Math.round(2 * root.d)

        Text {
            width: parent.width
            text: root.station?.name ?? Translation.tr("Nothing plays yet")
            elide: Text.ElideRight
            font.family: root.look.font
            font.pixelSize: root.look.title
            font.weight: Font.Bold
            color: root.look.ink
        }
        Row {
            width: parent.width
            spacing: Math.round(4 * root.d)
            Text {
                id: songLine
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, parent.width - (root.song ? copy.width + find.width + parent.spacing * 2 : 0))
                text: Radio.skipped.length > 0 && !root.song ? Translation.tr("%1 didn't answer, moved on").arg(Radio.skipped) : Radio.line
                elide: Text.ElideRight
                font.family: root.look.font
                font.pixelSize: root.look.body
                color: Radio.phase === "failed" ? root.look.danger : root.song ? root.look.ink : root.look.muted
            }
            RadioButton {
                id: copy
                anchors.verticalCenter: parent.verticalCenter
                visible: root.song
                look: root.look
                glyph: copied.running ? "check" : "content_copy"
                size: Math.round(26 * root.d)
                label: Translation.tr("Copy the song")
                onClicked: {
                    Quickshell.clipboardText = Radio.onAir
                    copied.restart()
                }
                Timer { id: copied; interval: 1400 }
            }
            RadioButton {
                id: find
                anchors.verticalCenter: parent.verticalCenter
                visible: root.song
                look: root.look
                glyph: "travel_explore"
                size: Math.round(26 * root.d)
                label: Translation.tr("Look the song up")
                onClicked: Qt.openUrlExternally(`https://duckduckgo.com/?q=${encodeURIComponent(Radio.onAir)}`)
            }
        }
        Text {
            width: parent.width
            visible: root.station !== null
            text: [`${Radio.flag} ${Radio.place}`.trim(), R.quality(root.station)].filter(x => x.length > 0).join(" · ")
            elide: Text.ElideRight
            font.family: root.look.font
            font.pixelSize: root.look.small
            color: root.look.faint
        }
    }

    Row {
        id: actions
        anchors.right: volume.left
        anchors.rightMargin: Math.round(20 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Math.round(6 * root.d)
        RadioButton {
            anchors.verticalCenter: parent.verticalCenter
            look: root.look
            glyph: "star"
            on: Radio.kept
            enabled: root.station !== null
            label: Radio.kept ? Translation.tr("Remove from favourites") : Translation.tr("Add to favourites")
            onClicked: Radio.toggleFavourite(root.station)
        }
        RadioButton {
            anchors.verticalCenter: parent.verticalCenter
            look: root.look
            accent: true
            glyph: Radio.playing || Radio.waiting ? "stop" : "play_arrow"
            size: Math.round(46 * root.d)
            label: Radio.playing ? Translation.tr("Stop") : Translation.tr("Play")
            onClicked: Radio.playPause()
        }
        RadioButton {
            anchors.verticalCenter: parent.verticalCenter
            look: root.look
            glyph: "skip_next"
            enabled: Radio.phase !== "searching"
            label: Translation.tr("Next station")
            onClicked: Radio.next()
        }
    }
    RadioVolume {
        id: volume
        anchors.right: parent.right
        anchors.rightMargin: Math.round(20 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        look: root.look
    }
}
