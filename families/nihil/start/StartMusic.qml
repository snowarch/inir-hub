pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules.nihil.style

// Start's small player: the cover on top, the title in mono caps under it, the skip keys beside a lit play key.
Rectangle {
    id: root

    property bool live: true
    readonly property var player: MprisController.activePlayer
    readonly property bool has: root.player !== null
    readonly property string art: root.has ? MprisController.artUrlOf(root.player) : ""

    radius: NihilStyle.s(20)
    color: NihilStyle.pieceRaised

    ClippingRectangle {
        id: cover
        x: NihilStyle.s(6); y: NihilStyle.s(6)
        width: parent.width - NihilStyle.s(12)
        height: parent.height * 0.42
        radius: NihilStyle.s(14)
        color: NihilStyle.piece
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
            color: NihilStyle.inkSoft
        }
    }
    NText {
        anchors.top: cover.bottom
        anchors.topMargin: NihilStyle.s(6)
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - NihilStyle.s(16)
        horizontalAlignment: Text.AlignHCenter
        mono: true
        font.bold: true
        font.pixelSize: NihilStyle.s(10)
        text: (root.has ? MprisController.titleOf(root.player) : Translation.tr("Nothing playing")).toUpperCase()
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: NihilStyle.s(8)
        spacing: NihilStyle.s(10)
        NButton {
            width: NihilStyle.s(26); height: width
            tone: NihilStyle.piece
            icon: "skip_previous"
            onClicked: MprisController.previous()
        }
        NButton {
            width: NihilStyle.s(26); height: width
            lit: true
            icon: MprisController.isPlaying ? "pause" : "play_arrow"
            onClicked: root.has ? MprisController.togglePlaying() : MprisController.resumeLast()
        }
        NButton {
            width: NihilStyle.s(26); height: width
            tone: NihilStyle.piece
            icon: "skip_next"
            onClicked: MprisController.next()
        }
    }
}
