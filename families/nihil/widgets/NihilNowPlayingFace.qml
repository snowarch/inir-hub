pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules.nihil.style

// What is playing: the cover, the names, the keys and how far along it is. With nothing playing it offers the last player.
NihilWidgetFace {
    id: root

    readonly property var player: MprisController.activePlayer
    readonly property bool playing: root.player?.isPlaying ?? false
    readonly property real length: root.player?.length ?? 0
    property real position: 0
    readonly property real keySize: root.dp(root.small ? 30 : 34)
    readonly property real coverSize: root.small ? 0 : root.large ? Math.min(root.contentWidth, root.contentHeight - root.dp(112))
        : root.contentHeight

    function readPosition(): void {
        root.position = root.player?.position ?? 0
    }

    onPlayerChanged: root.readPosition()

    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.moving && root.playing
        onTriggered: root.readPosition()
    }

    FaceBlank {
        visible: !root.player
        face: root
        glyph: "music"
        title: Translation.tr("Nothing playing")
        detail: Translation.tr("Music you play shows up here")
    }

    NButton {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        visible: !root.player && !root.small && MprisController.lastPlayedApp() !== null
        icon: "play"
        label: Translation.tr("Resume")
        onClicked: MprisController.resumeLast()
    }

    ClippingRectangle {
        id: cover
        visible: Boolean(root.player) && !root.small
        anchors.horizontalCenter: root.large ? parent.horizontalCenter : undefined
        width: root.coverSize
        height: root.coverSize
        radius: Math.max(root.dp(6), root.radius - root.padding)
        color: NihilStyle.piece

        NIcon {
            anchors.centerIn: parent
            text: "music"
            size: parent.width * 0.4
            color: root.inkFaint
        }
        Image {
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            sourceSize.width: 384
            sourceSize.height: 384
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }

    Column {
        visible: Boolean(root.player)
        x: root.medium ? cover.width + root.dp(14) : 0
        width: parent.width - x
        anchors.bottom: parent.bottom
        spacing: root.dp(4)

        NText {
            color: root.ink
            width: parent.width
            text: root.player?.trackTitle || Translation.tr("Unknown track")
            elide: Text.ElideRight
            font.pixelSize: root.dp(root.small ? 14 : 16)
            font.weight: Font.Medium
        }
        NText {
            width: parent.width
            visible: text.length > 0
            text: root.player?.trackArtist ?? ""
            elide: Text.ElideRight
            font.pixelSize: root.dp(13)
            color: root.inkSoft
        }
        FaceBar {
            ink: root.ink
            width: parent.width
            visible: root.length > 0
            level: root.position / Math.max(1, root.length)
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.dp(4)

            NButton {
                width: root.keySize
                height: root.keySize
                visible: !root.small
                enabled: root.player?.canGoPrevious ?? false
                icon: "previous"
                Accessible.name: Translation.tr("Previous track")
                onClicked: root.player.previous()
            }
            NButton {
                width: root.keySize
                height: root.keySize
                lit: true
                enabled: root.player?.canTogglePlaying ?? false
                icon: root.playing ? "pause" : "play"
                Accessible.name: root.playing ? Translation.tr("Pause") : Translation.tr("Play")
                onClicked: root.player.togglePlaying()
            }
            NButton {
                width: root.keySize
                height: root.keySize
                enabled: root.player?.canGoNext ?? false
                icon: "next"
                Accessible.name: Translation.tr("Next track")
                onClicked: root.player.next()
            }
        }
    }
}
