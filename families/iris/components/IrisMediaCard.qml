pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.shared.mediaControls.components
import qs.modules.iris.pieces
import qs.modules.iris.style

Item {
    id: root
    property var player: MprisController.activePlayer
    property bool compact: false
    property bool active: visible
    property bool showBackground: true
    property real headerReserve: 0
    // The plate's corner; a side panel sets it concentric with its own.
    property real plateRadius: IrisStyle.radiusSmall
    property bool showPlayers: true
    // On a veil over imagery (the lock), which stays dark in every scheme: media ink instead of the scheme's.
    property bool overMedia: false
    readonly property color ink: root.overMedia ? IrisStyle.onMedia : IrisStyle.text
    readonly property color inkMeta: root.overMedia ? IrisStyle.onMediaSecondary : IrisStyle.subtext
    readonly property color inkSecondary: root.overMedia ? IrisStyle.onMediaSecondary : IrisStyle.textSecondary
    readonly property color inkTertiary: root.overMedia ? IrisStyle.onMediaTertiary : IrisStyle.textTertiary
    property color tint: root.ink
    readonly property bool hasPlayer: root.player !== null && root.player !== undefined
    // A stream is live when it has no length, cannot seek while playing, or its end keeps running
    // away from a playhead that sits at it. Every sign is re-read, never latched: a browser that
    // sends a track's title before its length, or a seek that republishes metadata, must not leave
    // a normal video reading "Live" for the rest of the track.
    readonly property string trackKey: (root.player?.dbusName ?? "") + "\n" + media.effectiveTitle
    property real seenLength: 0
    property int grewSamples: 0
    property int atEndSamples: 0
    onTrackKeyChanged: { root.seenLength = 0; root.grewSamples = 0; root.atEndSamples = 0 }
    Timer {
        interval: 2000
        repeat: true
        running: root.active && root.hasPlayer && media.effectiveIsPlaying
        onTriggered: {
            const len = media.effectiveLength
            const pos = media.effectivePosition
            const atEdge = len > 0 && pos >= len - 1
            root.atEndSamples = atEdge ? root.atEndSamples + 1 : 0
            const grew = root.seenLength > 0 && len > root.seenLength + 1 && pos >= root.seenLength - 3
            root.grewSamples = grew ? root.grewSamples + 1 : 0
            if (len > 0) root.seenLength = len
        }
    }
    // A track change publishes an empty length for a moment: held through it, or the card drops its timeline, shows
    // "Live", shrinks and grows back between two songs.
    property bool lengthKnown: media.effectiveLength > 0
    readonly property bool lengthNow: media.effectiveLength > 0
    onLengthNowChanged: {
        if (root.lengthNow) { lengthHold.stop(); root.lengthKnown = true }
        else lengthHold.restart()
    }
    Timer { id: lengthHold; interval: 1500; onTriggered: root.lengthKnown = root.lengthNow }
    readonly property bool canShuffle: root.hasPlayer && (root.player?.shuffleSupported ?? false) && (root.player?.canControl ?? false)
    readonly property bool canLoop: root.hasPlayer && (root.player?.loopSupported ?? false) && (root.player?.canControl ?? false)
    readonly property int loopState: root.player?.loopState ?? MprisLoopState.None
    readonly property bool liveStream: root.hasPlayer
        && (!root.lengthKnown
            || (media.effectiveIsPlaying && !media.effectiveCanSeek)
            || root.grewSamples >= 2
            || root.atEndSamples >= 2)
    readonly property bool hasTimeline: root.hasPlayer && !root.liveStream
    // Nothing playing: the card offers the music app you use most and opens it. Not on the lock, where nothing opens.
    property bool offersOpen: true
    readonly property bool offersMusic: root.offersOpen && !root.hasPlayer && IrisPieces.musicAppName.length > 0
    readonly property string emptyDetail: root.offersOpen ? IrisPieces.musicDetail : Translation.tr("Your music appears here")
    readonly property string emptyIcon: root.offersMusic ? IrisPieces.musicAppIcon : ""
    MouseArea {
        anchors.fill: parent
        visible: root.offersMusic
        cursorShape: IrisPieces.musicLaunch === "opening" ? Qt.BusyCursor : Qt.PointingHandCursor
        onClicked: IrisPieces.openMusic()
    }
    // A Design draws the player its own way on this card's model (DESIGNS.md › skins): the playback, its states, the
    // empty card's offer and the actions stay here.
    readonly property var playback: media
    readonly property bool skinned: cardSkin.active
    implicitHeight: root.skinned ? (cardSkin.item?.implicitHeight ?? 0)
        : (root.compact ? compactBody.implicitHeight : body.implicitHeight) + 28 * IrisStyle.density
    implicitWidth: 360 * IrisStyle.density
    PlayerBase { id: media; player: root.player; positionUpdatesActive: root.active }

    Item {
        anchors.fill: parent
        visible: root.showBackground
        Rectangle { anchors.fill: parent; visible: !root.skinned; radius: root.plateRadius; color: IrisStyle.surfaceHigh }
        Loader {
            anchors.fill: parent
            active: root.active && root.showBackground && (Config.options?.iris?.player?.artworkBackground ?? true)
                && media.displayedArtFilePath.length > 0
            sourceComponent: IrisMediaBackdrop { source: media.displayedArtFilePath; radius: root.plateRadius; strength: 0.5 }
        }
    }
    ColumnLayout {
        id: body
        visible: !root.compact && !root.skinned
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14 * IrisStyle.density
        spacing: 12 * IrisStyle.density
        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: root.headerReserve
            spacing: 14 * IrisStyle.density
            IrisArtwork {
                source: media.displayedArtFilePath
                appIcon: root.emptyIcon
                circular: Config.options?.iris?.player?.roundCover ?? false
                Layout.preferredWidth: 68 * IrisStyle.density
                Layout.preferredHeight: 68 * IrisStyle.density
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(4 * IrisStyle.density)
                IrisText { Layout.fillWidth: true; text: root.hasPlayer ? media.effectiveTitle : Translation.tr("Nothing playing"); color: root.ink; font.weight: IrisStyle.weight(Font.DemiBold); elide: Text.ElideRight }
                IrisText { Layout.fillWidth: true; text: root.hasPlayer ? media.effectiveArtist : root.emptyDetail; role: IrisText.Meta; color: !root.hasPlayer && IrisPieces.musicLaunch === "failed" && root.offersOpen ? (root.overMedia ? IrisStyle.dangerOnMedia : IrisStyle.danger) : root.inkMeta; elide: Text.ElideRight }
            }
        }
        // The time on one line, the bar between its two figures (Apple's expanded player).
        RowLayout {
            Layout.fillWidth: true
            visible: root.hasTimeline
            spacing: Math.round(10 * IrisStyle.density)
            CardTime { text: StringUtils.friendlyTimeForSeconds(media.effectivePosition) }
            IrisScrubber {
                id: timeline
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                thickness: 5
                engagedThickness: 9
                seekable: media.effectiveCanSeek
                fillColor: root.ink
                trackColor: root.overMedia ? IrisStyle.onMediaFill : IrisStyle.fillHover
                value: media.effectiveLength > 0 ? Math.min(1, media.effectivePosition / media.effectiveLength) : 0
                onSeekRequested: next => media.seek(next * media.effectiveLength)
            }
            CardTime {
                horizontalAlignment: Text.AlignRight
                text: "\u2212" + StringUtils.friendlyTimeForSeconds(Math.max(0, media.effectiveLength - media.effectivePosition))
            }
        }
        RowLayout {
            Layout.fillWidth: true
            visible: root.hasPlayer && root.liveStream
            spacing: 6 * IrisStyle.density
            Rectangle {
                implicitWidth: Math.round(7 * IrisStyle.density)
                implicitHeight: implicitWidth
                radius: IrisStyle.capsule(width)
                color: root.overMedia ? IrisStyle.dangerOnMedia : IrisStyle.danger
                // Still: a pulse held its whole window at the display rate for as long as a stream played.
                opacity: media.effectiveIsPlaying ? 1 : 0.5
            }
            IrisText {
                text: Translation.tr("Live")
                color: root.inkSecondary
                font.pixelSize: IrisStyle.typeMeta
                font.weight: IrisStyle.weight(Font.DemiBold)
            }
            Item { Layout.fillWidth: true }
            IrisText {
                visible: media.effectivePosition > 0
                text: StringUtils.friendlyTimeForSeconds(media.effectivePosition)
                color: root.inkTertiary
                font.pixelSize: IrisStyle.typeFootnote
                font.family: IrisStyle.fontNumbers
                font.features: ({ "tnum": 1 })
            }
        }
        // Three glyphs, the pause on a soft disc; shuffle and repeat at the edges, lit in the card's tint when on.
        Item {
            Layout.fillWidth: true
            implicitHeight: transport.implicitHeight
            visible: root.hasPlayer
            CardToggle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: root.canShuffle
                on: root.player?.shuffle ?? false
                materialIcon: "shuffle"
                Accessible.name: Translation.tr("Shuffle")
                onClicked: root.player.shuffle = !on
            }
            IrisControlPlate {
                id: transport
                anchors.centerIn: parent
                controlHeight: Math.round(40 * IrisStyle.density)
                RowLayout {
                    spacing: Math.round((transport.framed ? 4 : 12) * IrisStyle.density)
                    // On the plate each takes its concentric radius, bare a full round.
                    Repeater {
                        model: ["previous", "toggle", "next"]
                        IrisIconButton {
                            required property string modelData
                            readonly property bool toggle: modelData === "toggle"
                            implicitWidth: Math.round((toggle ? 40 : 36) * IrisStyle.density)
                            implicitHeight: implicitWidth
                            buttonRadius: transport.framed ? transport.controlRadius : height / 2
                            buttonRadiusPressed: buttonRadius
                            colBackground: toggle ? (root.overMedia ? IrisStyle.onMediaFill : IrisStyle.fill) : "transparent"
                            foreground: root.ink
                            materialIcon: toggle ? (media.effectiveIsPlaying ? "pause" : "play_arrow") : modelData === "previous" ? "skip_previous" : "skip_next"
                            iconSize: toggle ? Math.round(24 * IrisStyle.density) : Math.round(21 * IrisStyle.density)
                            Accessible.name: toggle ? (media.effectiveIsPlaying ? Translation.tr("Pause") : Translation.tr("Play"))
                                : modelData === "previous" ? Translation.tr("Previous track") : Translation.tr("Next track")
                            enabled: toggle ? root.hasPlayer : modelData === "previous" ? media.effectiveCanGoPrevious : media.effectiveCanGoNext
                            onClicked: toggle ? media.togglePlaying() : modelData === "previous" ? media.previous() : media.next()
                        }
                    }
                }
            }
            CardToggle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.canLoop
                on: root.loopState !== MprisLoopState.None
                materialIcon: root.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                Accessible.name: Translation.tr("Repeat")
                onClicked: root.player.loopState = root.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                    : root.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
            }
        }
        IrisPlayerChips {
            id: playerChips
            Layout.fillWidth: true
            visible: root.showPlayers && playerChips.players.length > 0
            player: root.player
            accent: root.tint
            overMedia: root.overMedia
        }
    }

    RowLayout {
        id: compactBody
        visible: root.compact && !root.skinned
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 14 * IrisStyle.density
        spacing: 12 * IrisStyle.density
        IrisArtwork {
            source: media.displayedArtFilePath
            appIcon: root.emptyIcon
            circular: Config.options?.iris?.player?.roundCover ?? false
            Layout.preferredWidth: 46 * IrisStyle.density
            Layout.preferredHeight: 46 * IrisStyle.density
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(2 * IrisStyle.density)
            IrisText { Layout.fillWidth: true; text: root.hasPlayer ? media.effectiveTitle : Translation.tr("Nothing playing"); color: root.ink; font.weight: IrisStyle.weight(Font.DemiBold); elide: Text.ElideRight }
            IrisText { Layout.fillWidth: true; text: root.hasPlayer ? media.effectiveArtist : root.emptyDetail; role: IrisText.Meta; color: !root.hasPlayer && IrisPieces.musicLaunch === "failed" && root.offersOpen ? (root.overMedia ? IrisStyle.dangerOnMedia : IrisStyle.danger) : root.inkMeta; elide: Text.ElideRight }
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 5 * IrisStyle.density
                visible: root.hasTimeline
                implicitHeight: Math.max(2, Math.round(3 * IrisStyle.density))
                radius: IrisStyle.capsule(height)
                color: root.overMedia ? IrisStyle.onMediaFill : IrisStyle.fill
                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    color: root.tint
                    width: parent.width * (media.effectiveLength > 0 ? Math.min(1, media.effectivePosition / media.effectiveLength) : 0)
                }
            }
        }
        // With no player the row is its empty state: three dead buttons only cut its words short.
        IrisIconButton { visible: root.hasPlayer; foreground: root.ink; materialIcon: "skip_previous"; Accessible.name: Translation.tr("Previous track"); enabled: media.effectiveCanGoPrevious; onClicked: media.previous() }
        IrisIconButton { visible: root.hasPlayer; foreground: root.ink; materialIcon: media.effectiveIsPlaying ? "pause" : "play_arrow"; Accessible.name: media.effectiveIsPlaying ? Translation.tr("Pause") : Translation.tr("Play"); onClicked: media.togglePlaying(); iconSize: Math.round(24 * IrisStyle.density) }
        IrisIconButton { visible: root.hasPlayer; foreground: root.ink; materialIcon: "skip_next"; Accessible.name: Translation.tr("Next track"); enabled: media.effectiveCanGoNext; onClicked: media.next() }
    }

    IrisSkin { id: cardSkin; part: "mediaCard"; host: root }

    component CardTime: IrisText {
        Layout.minimumWidth: Math.round(30 * IrisStyle.density)
        color: root.inkTertiary
        font.pixelSize: IrisStyle.typeFootnote
        font.family: IrisStyle.fontNumbers
        font.features: ({ "tnum": 1 })
    }
    component CardToggle: IrisIconButton {
        property bool on: false
        implicitWidth: Math.round(32 * IrisStyle.density)
        implicitHeight: implicitWidth
        buttonRadius: height / 2
        buttonRadiusPressed: buttonRadius
        iconSize: Math.round(17 * IrisStyle.density)
        foreground: on ? root.tint : root.inkTertiary
    }
}
