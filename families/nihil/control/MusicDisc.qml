pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules.nihil.style

// The quick controls' record: a lit disc with the cover set round in its middle (a tap plays or pauses), the skip
// keys either side, the time played over it and the length under it.
Rectangle {
    id: root

    property bool live: true
    readonly property var player: MprisController.activePlayer
    readonly property bool has: root.player !== null
    property int tick: 0
    readonly property real position: (root.tick, root.has ? MprisController.positionOf(root.player) : 0)
    readonly property real length: root.has ? MprisController.lengthOf(root.player) : 0
    readonly property string art: root.has ? MprisController.artUrlOf(root.player) : ""

    function clock(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    radius: width / 2
    color: root.has ? NihilStyle.accent : NihilStyle.pieceRaised

    Timer {
        running: root.live && MprisController.isPlaying
        interval: 1000
        repeat: true
        onTriggered: root.tick++
    }

    readonly property color ink: root.has ? NihilStyle.onAccent : NihilStyle.inkSoft

    NText {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.09
        mono: true
        text: root.clock(root.position)
        font.pixelSize: NihilStyle.s(10)
        color: root.ink
        visible: root.has
    }
    NText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.09
        mono: true
        text: root.clock(root.length)
        font.pixelSize: NihilStyle.s(10)
        color: root.ink
        visible: root.has
    }

    ClippingRectangle {
        id: hole
        anchors.centerIn: parent
        width: parent.width * 0.48
        height: width
        radius: width / 2
        color: NihilStyle.piece
        Image {
            anchors.fill: parent
            source: root.art
            visible: root.art.length > 0
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 160
        }
        NIcon {
            anchors.centerIn: parent
            visible: root.art.length === 0 || !MprisController.isPlaying
            text: MprisController.isPlaying ? "pause" : "play_arrow"
            size: parent.width * 0.42
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.has ? MprisController.togglePlaying() : MprisController.resumeLast()
        }
    }

    component Skip: NIcon {
        required property bool forward
        anchors.verticalCenter: parent.verticalCenter
        text: forward ? "skip_next" : "skip_previous"
        size: NihilStyle.s(16)
        color: root.ink
        visible: root.has
        MouseArea {
            anchors.fill: parent
            anchors.margins: -NihilStyle.s(6)
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.forward ? MprisController.next() : MprisController.previous()
        }
    }
    Skip { forward: false; x: (hole.x - width) / 2 }
    Skip { forward: true; x: hole.x + hole.width + (root.width - hole.x - hole.width - width) / 2 }
}
