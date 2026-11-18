pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules.common

// What plays, on one tile: the cover at its end, the title in heavy type, the three keys and the time at its foot.
NTile {
    id: root

    property bool live: true
    readonly property var player: MprisController.activePlayer
    readonly property bool has: root.player !== null
    readonly property string art: root.has ? MprisController.artUrlOf(root.player) : ""
    property int tick: 0
    readonly property real position: (root.tick, root.has ? MprisController.positionOf(root.player) : 0)
    readonly property real length: root.has ? MprisController.lengthOf(root.player) : 0

    function clock(seconds: real): string {
        const whole = Math.max(0, Math.floor(seconds))
        return Math.floor(whole / 60) + ":" + String(whole % 60).padStart(2, "0")
    }

    Timer {
        running: root.live && root.visible && MprisController.isPlaying
        interval: 1000
        repeat: true
        onTriggered: root.tick++
    }

    ClippingRectangle {
        id: cover
        x: NihilStyle.s(6)
        y: NihilStyle.s(6)
        width: root.height - NihilStyle.s(12)
        height: width
        radius: NihilStyle.rowRadius
        color: NihilStyle.pieceRaised
        Image {
            anchors.fill: parent
            source: root.art
            visible: root.art.length > 0
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 256
        }
        NIcon {
            anchors.centerIn: parent
            visible: root.art.length === 0
            text: "music_note"
            size: NihilStyle.s(34)
            color: NihilStyle.inkSoft
        }
    }

    Column {
        anchors.left: cover.right
        anchors.leftMargin: NihilStyle.s(12)
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        y: NihilStyle.s(10)
        spacing: NihilStyle.s(1)
        NCaps {
            width: parent.width
            text: root.has ? MprisController.artistOf(root.player) : Translation.tr("Silence")
            color: root.inkSoft
        }
        NText {
            width: parent.width
            text: root.has ? MprisController.titleOf(root.player) : Translation.tr("Nothing playing")
            font.pixelSize: NihilStyle.textLarge
            font.weight: Font.Black
        }
    }

    Row {
        id: keys
        anchors.left: cover.right
        anchors.leftMargin: NihilStyle.s(12)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: NihilStyle.s(6)
        spacing: NihilStyle.seam
        NButton {
            width: NihilStyle.s(40); height: width
            tone: NihilStyle.pieceRaised
            icon: "skip_previous"
            onClicked: MprisController.previous()
        }
        NButton {
            width: NihilStyle.s(56); height: NihilStyle.s(40)
            paper: true
            icon: MprisController.isPlaying ? "pause" : "play_arrow"
            onClicked: root.has ? MprisController.togglePlaying() : MprisController.resumeLast()
        }
        NButton {
            width: NihilStyle.s(40); height: width
            tone: NihilStyle.pieceRaised
            icon: "skip_next"
            onClicked: MprisController.next()
        }
    }

    NCaps {
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        anchors.verticalCenter: keys.verticalCenter
        visible: root.has && root.length > 0 && root.width > NihilStyle.s(320)
        text: root.clock(root.position) + " / " + root.clock(root.length)
        color: root.inkSoft
    }
}
