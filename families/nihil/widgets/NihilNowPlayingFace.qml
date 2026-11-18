pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.nihil.style

// What plays. Medium and large: a dark piece with the cover fading in from its right, a note glyph, the title in
// figures and the artist in the serif, the time as a bar (played in the signal colour), the play key a lit pill
// beside small skip keys. Small: a round play key over the title.
NihilFace {
    id: root

    readonly property var player: MprisController.activePlayer
    readonly property bool has: root.player !== null
    readonly property bool playing: MprisController.isPlaying
    readonly property string title: root.has ? MprisController.titleOf(root.player) : Translation.tr("Nothing playing")
    readonly property string artist: root.has ? MprisController.artistOf(root.player) : ""
    readonly property string art: root.has ? MprisController.artUrlOf(root.player) : ""
    property int tick: 0
    readonly property real length: root.has ? MprisController.lengthOf(root.player) : 0
    readonly property real position: (root.tick, root.has ? MprisController.positionOf(root.player) : 0)
    readonly property real progress: root.length > 0 ? Math.max(0, Math.min(1, root.position / root.length)) : 0

    Timer {
        running: root.live && root.widget.motionActive && root.playing && !root.small
        interval: 1000
        repeat: true
        onTriggered: root.tick++
    }

    // Medium and large.
    Rectangle {
        id: card
        visible: !root.small
        anchors.fill: parent
        radius: root.radius
        color: NihilStyle.piece

        ClippingRectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.large ? parent.width : parent.width * 0.6
            height: root.large ? parent.height * 0.62 : parent.height
            radius: root.radius
            color: "transparent"
            visible: root.art.length > 0
            Image {
                id: cover
                anchors.fill: parent
                source: root.art
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 512
                visible: false
            }
            MultiEffect {
                anchors.fill: cover
                source: cover
                maskEnabled: true
                maskSource: fade
            }
            Item {
                id: fade
                anchors.fill: parent
                visible: false
                layer.enabled: true
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: root.large ? Gradient.Vertical : Gradient.Horizontal
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 0.55; color: NihilStyle.ink }
                    }
                }
            }
        }

        NButton {
            x: root.dp(14); y: root.dp(14)
            width: root.dp(42); height: width
            tone: NihilStyle.pieceRaised
            icon: "music_note"
            iconSize: root.dp(22)
            onClicked: if (!root.has) MprisController.resumeLast()
        }

        Column {
            anchors { left: parent.left; right: parent.right; bottom: controls.top; margins: root.dp(16); bottomMargin: root.dp(8) }
            spacing: root.dp(2)
            NText {
                width: parent.width * (root.large ? 0.9 : 0.55)
                mono: true
                font.bold: true
                font.pixelSize: root.dp(15)
                font.capitalization: Font.AllUppercase
                text: root.title
            }
            NText {
                width: parent.width * 0.55
                serif: true
                font.pixelSize: root.dp(13)
                color: NihilStyle.inkSoft
                text: root.artist
                visible: text.length > 0
            }
        }

        Row {
            id: controls
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: root.dp(14) }
            height: root.dp(30)
            spacing: root.dp(8)
            Item {
                width: parent.width - play.width - prev.width - next.width - parent.spacing * 3
                height: parent.height
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: root.dp(5)
                    radius: height / 2
                    color: NihilStyle.ink
                    Rectangle {
                        width: parent.width * root.progress
                        height: parent.height
                        radius: parent.radius
                        color: NihilStyle.accent
                    }
                }
            }
            NButton {
                id: play
                width: root.dp(54); height: parent.height
                lit: true
                icon: root.playing ? "pause" : "play_arrow"
                iconSize: root.dp(20)
                onClicked: root.has ? MprisController.togglePlaying() : MprisController.resumeLast()
            }
            NButton {
                id: prev
                width: parent.height; height: width
                tone: NihilStyle.pieceRaised
                icon: "skip_previous"
                iconSize: root.dp(16)
                onClicked: MprisController.previous()
            }
            NButton {
                id: next
                width: parent.height; height: width
                tone: NihilStyle.pieceRaised
                icon: "skip_next"
                iconSize: root.dp(16)
                onClicked: MprisController.next()
            }
        }
    }

    // Small: the play key, lit, on a round piece; the title under it.
    Rectangle {
        visible: root.small
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        radius: width / 2
        color: NihilStyle.piece
        Column {
            anchors.centerIn: parent
            spacing: root.dp(10)
            NButton {
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.dp(64); height: width
                lit: true
                icon: root.playing ? "pause" : "play_arrow"
                iconSize: root.dp(30)
                onClicked: root.has ? MprisController.togglePlaying() : MprisController.resumeLast()
            }
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(implicitWidth, root.width * 0.7)
                horizontalAlignment: Text.AlignHCenter
                mono: true
                font.pixelSize: root.dp(12)
                font.capitalization: Font.AllUppercase
                text: root.title
            }
        }
    }
}
