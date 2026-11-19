pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris
import qs
import qs.modules.common
import qs.services
import qs.modules.nihil.style

// Media: what plays, as large as the dashboard allows. The cover stands on a glow of its own colours; beside it the title,
// the timeline, the keys and the players there are to switch between.
FocusScope {
    id: root

    property var screen: null
    property bool open: false

    readonly property var player: MprisController.activePlayer
    readonly property var players: MprisController.displayPlayers.length > 0 ? MprisController.displayPlayers : MprisController.players
    readonly property real length: MprisController.lengthOf(root.player)
    property real position: 0
    readonly property string art: MprisController.artUrlOf(root.player) || (root.player?.trackArtUrl ?? "")
    readonly property real pad: NihilStyle.s(28)


    function clock(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds))
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), r = s % 60
        return (h > 0 ? h + ":" + String(m).padStart(2, "0") : m) + ":" + String(r).padStart(2, "0")
    }
    // The position is read only while the page is open and something plays.
    Timer {
        running: root.open && (root.player?.isPlaying ?? false)
        interval: 500
        repeat: true
        triggeredOnStart: true
        onTriggered: root.position = MprisController.positionOf(root.player)
    }
    onPlayerChanged: root.position = MprisController.positionOf(root.player)

    Keys.onSpacePressed: root.player?.togglePlaying()
    Keys.onLeftPressed: if (root.player?.canSeek) MprisController.seek(root.player, root.position - 5)
    Keys.onRightPressed: if (root.player?.canSeek) MprisController.seek(root.player, root.position + 5)

    // The cover's own colours, blurred far behind everything.
    Item {
        anchors.fill: parent
        clip: true
        visible: root.art.length > 0
        Image {
            id: haze
            anchors.centerIn: parent
            width: parent.width * 1.2
            height: parent.height * 1.2
            source: root.art
            sourceSize: Qt.size(96, 96)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }
        MultiEffect {
            anchors.fill: haze
            source: haze
            blurEnabled: true
            blur: 1
            blurMax: 64
            saturation: 0.2
            opacity: root.open ? (NihilStyle.dark ? 0.32 : 0.4) : 0
            Behavior on opacity { NumberAnimation { duration: NihilStyle.durationLong } }
        }
    }

    // Nothing plays.
    NEmpty {
        anchors.centerIn: parent
        visible: !root.player
        icon: "music"
        title: Translation.tr("Nothing playing")
        note: Translation.tr("Music and videos you play show up here")
    }

    Item {
        anchors.fill: parent
        anchors.margins: root.pad
        visible: !!root.player

        // The cover.
        Rectangle {
            id: cover
            width: Math.min(parent.height, parent.width * 0.44)
            height: width
            anchors.verticalCenter: parent.verticalCenter
            radius: NihilStyle.radiusCard
            color: NihilStyle.fillHover
            clip: true
            NIcon {
                anchors.centerIn: parent
                visible: artImage.status !== Image.Ready
                text: "music"
                size: NihilStyle.s(56)
                color: NihilStyle.textTertiary
            }
            Image {
                id: artImage
                anchors.fill: parent
                source: root.art
                sourceSize: Qt.size(width * 2, height * 2)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: coverMask
                }
            }
            Rectangle {
                id: coverMask
                anchors.fill: parent
                radius: parent.radius
                visible: false
                layer.enabled: true
            }
            // The edge of the glass the cover sits under.
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: Qt.alpha("#FFFFFF", 0.14)
            }
        }

        Column {
            id: about
            anchors.left: cover.right
            anchors.leftMargin: root.pad
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: NihilStyle.s(18)

            Column {
                width: parent.width
                spacing: NihilStyle.s(4)
                NText {
                    width: parent.width
                    text: root.player?.identity ?? ""
                    font.pixelSize: NihilStyle.textCaption
                    font.weight: Font.Medium
                    color: NihilStyle.textTertiary
                }
                NDisplay {
                    width: parent.width
                    text: MprisController.titleOf(root.player) || Translation.tr("Unknown title")
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                }
                NText {
                    width: parent.width
                    text: [MprisController.artistOf(root.player), root.player?.trackAlbum ?? ""].filter(part => String(part).length > 0).join(" · ")
                    font.pixelSize: NihilStyle.textLarge
                    color: NihilStyle.textSecondary
                }
            }

            // The timeline: the hand sets where it plays from.
            Column {
                width: parent.width
                visible: root.length > 0
                spacing: NihilStyle.s(6)
                NSlider {
                    width: parent.width
                    height: NihilStyle.s(10)
                    from: 0
                    to: Math.max(1, root.length)
                    stepSize: 0
                    value: root.position
                    name: Translation.tr("Position")
                    enabled: root.player?.canSeek ?? false
                    onSeekRequested: value => {
                        MprisController.seek(root.player, value)
                        root.position = value
                    }
                }
                Item {
                    width: parent.width
                    height: NihilStyle.s(16)
                    NText { text: root.clock(root.position); figures: true; font.pixelSize: NihilStyle.textCaption; color: NihilStyle.textTertiary }
                    NText {
                        anchors.right: parent.right
                        text: "-" + root.clock(root.length - root.position)
                        figures: true
                        font.pixelSize: NihilStyle.textCaption
                        color: NihilStyle.textTertiary
                    }
                }
            }

            // The keys.
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: NihilStyle.s(14)
                NButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "shuffle"
                    visible: root.player?.shuffleSupported ?? false
                    highlighted: root.player?.shuffle ?? false
                    Accessible.name: Translation.tr("Shuffle")
                    onClicked: root.player.shuffle = !root.player.shuffle
                }
                NButton {
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(48)
                    height: width
                    icon: "previous"
                    iconSize: NihilStyle.s(22)
                    enabled: root.player?.canGoPrevious ?? false
                    Accessible.name: Translation.tr("Previous")
                    onClicked: root.player?.previous()
                }
                NButton {
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(68)
                    height: width
                    highlighted: true
                    icon: root.player?.isPlaying ? "pause" : "play"
                    iconSize: NihilStyle.s(28)
                    Accessible.name: root.player?.isPlaying ? Translation.tr("Pause") : Translation.tr("Play")
                    onClicked: root.player?.togglePlaying()
                }
                NButton {
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(48)
                    height: width
                    icon: "next"
                    iconSize: NihilStyle.s(22)
                    enabled: root.player?.canGoNext ?? false
                    Accessible.name: Translation.tr("Next")
                    onClicked: root.player?.next()
                }
                NButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "restart"
                    visible: root.player?.loopSupported ?? false
                    highlighted: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                    Accessible.name: Translation.tr("Repeat")
                    onClicked: root.player.loopState = root.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                        : root.player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
                }
            }

            // The sound, for the whole machine.
            Row {
                width: parent.width
                spacing: NihilStyle.s(12)
                NIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: (Audio.sink?.audio?.muted ?? false) ? "volume_mute" : "volume_down"
                    size: NihilStyle.s(18)
                    color: NihilStyle.textSecondary
                }
                NSlider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - NihilStyle.s(60)
                    height: NihilStyle.s(10)
                    value: Audio.sink?.audio?.volume ?? 0
                    name: Translation.tr("Volume")
                    onMoved: value => { if (Audio.sink?.audio) Audio.sink.audio.volume = value }
                }
                NIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "volume_up"
                    size: NihilStyle.s(18)
                    color: NihilStyle.textSecondary
                }
            }

            // Every player there is; the one on show is solid.
            Flow {
                width: parent.width
                visible: root.players.length > 1
                spacing: NihilStyle.s(6)
                Repeater {
                    model: root.players
                    NButton {
                        required property var modelData
                        label: modelData?.identity ?? ""
                        icon: modelData?.isPlaying ? "play" : "pause"
                        iconSize: NihilStyle.s(14)
                        highlighted: modelData === root.player
                        onClicked: MprisController.setActivePlayer(modelData)
                    }
                }
            }
        }
    }
}
