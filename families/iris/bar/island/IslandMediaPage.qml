pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.services.deferred
import qs.modules.iris.state
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.shared.mediaControls.components
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.frame
import qs.modules.iris.pieces

GridLayout {
    id: page
    required property Item island
    readonly property bool current: page.island.effectivePage === "media"
    columns: 1
    rowSpacing: 14 * IrisStyle.density
    columnSpacing: 0
    readonly property var blocks: {
        const configured = Config.options?.iris?.bar?.mediaBlocks
        return Array.isArray(configured) ? configured : ["player", "timeline", "transport", "players", "levels"]
    }
    function rowOf(kind: string): int { return page.blocks.indexOf(kind) }
    readonly property string firstExtra: page.blocks.find(kind => (kind === "players" && page.otherPlayers.length > 0) || (kind === "levels" && page.streams.length > 0)) ?? ""


    PlayerBase {
        id: media
        player: page.island.player
        positionUpdatesActive: page.current && page.island.visualExpanded
    }

    // A track change publishes an empty length (and often an empty artist) for a moment: rows that depend on them are
    // held through it, or the page shrinks and grows back and the Island jumps between two songs.
    property bool timelineShown: page.timelineWanted
    // A live stream keeps its row: the line runs full to the broadcast's edge and the end says it is live.
    readonly property bool timelineWanted: media.effectiveLength > 0 || media.effectiveIsLive
    onTimelineWantedChanged: {
        if (page.timelineWanted) { timelineHold.stop(); page.timelineShown = true }
        else timelineHold.restart()
    }
    Timer { id: timelineHold; interval: 1500; onTriggered: page.timelineShown = page.timelineWanted }
    readonly property var shownPlayer: page.island.player
    readonly property bool canShuffle: !page.anime && (page.shownPlayer?.shuffleSupported ?? false) && (page.shownPlayer?.canControl ?? false)
    readonly property bool canLoop: !page.anime && (page.shownPlayer?.loopSupported ?? false) && (page.shownPlayer?.canControl ?? false)
    readonly property int loopState: page.shownPlayer?.loopState ?? MprisLoopState.None

    readonly property bool anime: AnimeWatch.ownsPlayer(page.island.player)
    readonly property var cardKinds: IrisPieces.cardIds
    readonly property var players: (MprisController.displayPlayers ?? []).filter(p => p)
    function stepPlayer(step: int): void {
        const at = page.players.indexOf(page.island.player)
        if (page.players.length < 2 || at < 0) return
        MprisController.setActivePlayer(page.players[(at + step + page.players.length) % page.players.length])
    }
    readonly property var otherPlayers: (MprisController.displayPlayers ?? []).filter(p => p && p !== page.island.player)
    readonly property var streams: {
        const groups = []
        for (const node of (Audio.outputAppNodes ?? [])) {
            if (!node?.audio) continue
            const name = Audio.appNodeDisplayName(node)
            const group = groups.find(g => g.name === name)
            if (group) group.nodes.push(node)
            else groups.push({ name: name, nodes: [node] })
        }
        return groups
    }

    // The app playing, by its desktop entry, its name or its bus name: Apple's expanded player wears its mark in the
    // top right corner.
    readonly property string appIcon: {
        const p = page.shownPlayer
        if (!p) return ""
        const bus = String(p.dbusName ?? "").replace("org.mpris.MediaPlayer2.", "").split(".")[0]
        return AppSearch.iconSource([String(p.desktopEntry ?? ""), AppSearch.guessIcon(String(p.identity ?? "")), AppSearch.guessIcon(bus)], "")
    }
    readonly property bool canSeekBy: !page.anime && media.effectiveCanSeek && media.effectiveLength > 0
    function seekBy(seconds: real): void {
        media.seek(Math.max(0, Math.min(media.effectiveLength - 1, media.effectivePosition + seconds)))
    }

    // Apple's expanded player (.claude/ref/iris-island pin-music-expanded, iris-widgets pin-glass-now-playing): a cover
    // near a quarter of the page, the song large over its artist, the app's mark in the corner; the time on one line
    // round a bar with its knob; five controls on soft discs, the pause the largest, the two at the ends the player's
    // shuffle and repeat or, where it has none, ten seconds back and ahead.
    readonly property real coverSide: Math.round(Math.min(page.island.pageWidth * 0.23, 104 * IrisStyle.density))
    RowLayout {
        Layout.row: Math.max(0, page.rowOf("player"))
        Layout.fillWidth: true
        visible: page.rowOf("player") >= 0
        spacing: Math.round(16 * IrisStyle.density)
        IrisArtwork {
            id: pageCover
            opacity: page.island.coverFlightItem.hides(pageCover) ? 0 : 1
            Component.onCompleted: page.island.pageCover = pageCover
            Layout.preferredWidth: page.coverSide
            Layout.preferredHeight: page.coverSide
            Layout.alignment: Qt.AlignVCenter
            source: MediaArtwork.displaySource
            circular: Config.options?.iris?.player?.roundCover ?? false
            radius: circular ? width / 2 : Math.round(width * 0.17)
            // The cover brings its app forward; a swipe across it or the wheel sideways moves to another player.
            TapHandler {
                onTapped: if (page.island.player?.canRaise) page.island.player.raise()
            }
            DragHandler {
                target: null
                yAxis.enabled: false
                onActiveChanged: if (!active && Math.abs(translation.x) > 24 * IrisStyle.density) page.stepPlayer(translation.x < 0 ? 1 : -1)
            }
            WheelHandler {
                orientation: Qt.Horizontal
                onWheel: event => { if (Math.abs(event.angleDelta.x) >= 60) page.stepPlayer(event.angleDelta.x < 0 ? 1 : -1) }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Math.round(3 * IrisStyle.density) // iris-literal: title and artist sit tight, as Apple's player
            IrisMarquee {
                Layout.fillWidth: true
                text: media.effectiveTitle
                pixelSize: IrisStyle.typeTitle
                weight: Font.Bold
                running: page.current && page.island.visualExpanded
            }
            IrisMarquee {
                Layout.fillWidth: true
                text: media.effectiveArtist
                color: IrisStyle.textSecondary
                pixelSize: IrisStyle.typeHeadline
                running: page.current && page.island.visualExpanded
            }
            IrisVisualizer {
                Layout.topMargin: Math.round(6 * IrisStyle.density)
                running: media.effectiveIsPlaying && page.current && page.island.visualExpanded
                tint: IrisStyle.visualizerTint(page.island.artTint)
                barHeight: 13 * IrisStyle.density
            }
        }
        // The app's mark: a tap brings it forward.
        IrisImage {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: Math.round(26 * IrisStyle.density)
            Layout.preferredHeight: Layout.preferredWidth
            visible: page.appIcon.length > 0
            decodeWidth: Math.round(26 * IrisStyle.density)
            decodeHeight: decodeWidth
            source: page.appIcon
            TapHandler {
                cursorShape: Qt.PointingHandCursor
                onTapped: if (page.shownPlayer?.canRaise) page.shownPlayer.raise()
            }
        }
    }

    RowLayout {
        Layout.row: Math.max(0, page.rowOf("timeline"))
        Layout.fillWidth: true
        Layout.topMargin: Math.round(4 * IrisStyle.density)
        visible: page.rowOf("timeline") >= 0 && page.timelineShown
        spacing: Math.round(12 * IrisStyle.density)
        Tabular {
            Layout.minimumWidth: Math.round(34 * IrisStyle.density)
            text: page.island.clockText(media.effectivePosition)
            color: IrisStyle.textSecondary
            font.pixelSize: IrisStyle.typeMeta
            font.weight: IrisStyle.weight(Font.DemiBold)
        }
        IrisScrubber {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            thickness: 6
            engagedThickness: 10
            knob: !media.effectiveIsLive
            seekable: media.effectiveCanSeek
            value: media.effectiveIsLive ? 1 : media.effectiveLength > 0 ? media.effectivePosition / media.effectiveLength : 0
            fillColor: IrisStyle.text
            trackColor: IrisStyle.fillHover
            onSeekRequested: next => media.seek(next * media.effectiveLength)
        }
        Tabular {
            Layout.minimumWidth: Math.round(34 * IrisStyle.density)
            horizontalAlignment: Text.AlignRight
            // A true minus, as Apple sets it; a live stream has no end to count down to.
            text: media.effectiveIsLive ? Translation.tr("Live")
                : "\u2212" + page.island.clockText(Math.max(0, media.effectiveLength - media.effectivePosition))
            color: media.effectiveIsLive ? IrisStyle.accent : IrisStyle.textSecondary
            font.pixelSize: IrisStyle.typeMeta
            font.weight: IrisStyle.weight(Font.DemiBold)
        }
    }

    ColumnLayout {
        Layout.row: Math.max(0, page.rowOf("transport"))
        Layout.fillWidth: true
        visible: page.rowOf("transport") >= 0
        spacing: 10 * IrisStyle.density
        Item {
            Layout.fillWidth: true
            implicitHeight: transport.implicitHeight
            IrisControlPlate {
                id: transport
                anchors.centerIn: parent
                material: page.island.pagePlate
                controlHeight: 54 * IrisStyle.density
                RowLayout {
                    spacing: transport.framed ? 6 * IrisStyle.density : 12 * IrisStyle.density
                    TransportButton {
                        side: true
                        visible: page.canShuffle || page.canSeekBy
                        readonly property bool on: page.canShuffle && (page.shownPlayer?.shuffle ?? false)
                        glyph: page.canShuffle ? "shuffle" : "replay_10"
                        glyphColor: on ? page.island.artTint : IrisStyle.textSecondary
                        Accessible.name: page.canShuffle ? Translation.tr("Shuffle") : Translation.tr("Back 10 seconds")
                        onClicked: page.canShuffle ? page.shownPlayer.shuffle = !on : page.seekBy(-10)
                    }
                    TransportButton {
                        glyph: "skip_previous"
                        enabled: page.anime || media.effectiveCanGoPrevious
                        Accessible.name: page.anime ? Translation.tr("Previous episode") : Translation.tr("Previous track")
                        onClicked: page.anime ? AnimeWatch.skip("previous") : media.previous()
                    }
                    TransportButton {
                        lead: true
                        glyph: media.effectiveIsPlaying ? "pause" : "play_arrow"
                        enabled: page.island.hasMedia
                        Accessible.name: media.effectiveIsPlaying ? Translation.tr("Pause") : Translation.tr("Play")
                        onClicked: media.togglePlaying()
                    }
                    TransportButton {
                        glyph: "skip_next"
                        enabled: page.anime || media.effectiveCanGoNext
                        Accessible.name: page.anime ? Translation.tr("Next episode") : Translation.tr("Next track")
                        onClicked: page.anime ? AnimeWatch.skip("next") : media.next()
                    }
                    TransportButton {
                        side: true
                        visible: page.canLoop || page.canSeekBy
                        readonly property bool on: page.canLoop && page.loopState !== MprisLoopState.None
                        glyph: !page.canLoop ? "forward_10" : page.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                        glyphColor: on ? page.island.artTint : IrisStyle.textSecondary
                        Accessible.name: page.canLoop ? Translation.tr("Repeat") : Translation.tr("Ahead 10 seconds")
                        onClicked: page.canLoop
                            ? page.shownPlayer.loopState = page.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                                : page.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
                            : page.seekBy(10)
                    }
                }
            }
            // Where the sound goes, read from the real output; nothing when there is no output. A tap opens the sound
            // card with its devices.
            GlyphButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: Audio.defaultSink !== null && Audio.defaultSink !== undefined && page.cardKinds.includes("sound")
                // A plain speaker shows Apple's output picker; earbuds, headphones and screens show themselves.
                readonly property string device: IrisStyle.soundDeviceGlyph(Audio.defaultSink, false)
                glyph: device === "speaker" ? "airplay" : device
                glyphSize: 20 * IrisStyle.density
                glyphColor: IrisStyle.textTertiary
                implicitWidth: Math.round(34 * IrisStyle.density)
                Accessible.name: Translation.tr("Sound output")
                // The page folds away first, as Apple's picker takes the Island's place: whoever holds the sound
                // piece (a floating bubble or the Island) then grows its card.
                onClicked: {
                    page.island.expanded = false
                    IrisState.bubbleCardRequest = ""
                    IrisState.bubbleCardRequest = "sound"
                }
            }
        }
        // One dot per player, the one playing here drawn long; a dot, the wheel sideways or a swipe on the cover moves
        // to another.
        Row {
            Layout.alignment: Qt.AlignHCenter
            visible: page.players.length > 1
            spacing: 6 * IrisStyle.density
            Repeater {
                model: page.players
                MouseArea {
                    id: dot
                    required property var modelData
                    readonly property bool here: dot.modelData === page.island.player
                    width: dot.here ? Math.round(18 * IrisStyle.density) : Math.round(7 * IrisStyle.density)
                    height: Math.round(7 * IrisStyle.density)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: String(dot.modelData?.identity ?? "")
                    onClicked: MprisController.setActivePlayer(dot.modelData)
                    Behavior on width { NumberAnimation { duration: IrisStyle.duration(260); easing.type: Easing.OutCubic } }
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: dot.here ? IrisStyle.text : dot.containsMouse ? IrisStyle.textSecondary : IrisStyle.textTertiary
                    }
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            visible: page.anime
            spacing: 8 * IrisStyle.density
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: IrisStyle.hairline
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 5 * IrisStyle.density
                IrisText {
                    text: Translation.tr("Subtitles")
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeMeta
                }
                Item { Layout.fillWidth: true }
                AnimeChip {
                    text: Translation.tr("Off")
                    active: AnimeWatch.subtitleId <= 0
                    onClicked: AnimeWatch.selectSubtitle(0)
                }
                Repeater {
                    model: AnimeWatch.subtitles
                    AnimeChip {
                        required property var modelData
                        required property int index
                        text: AnimeWatch.subtitleLabel(modelData, index)
                        active: AnimeWatch.subtitleId === Number(modelData.id)
                        onClicked: AnimeWatch.selectSubtitle(Number(modelData.id))
                    }
                }
                AnimeChip {
                    glyph: "add"
                    Accessible.name: Translation.tr("Load a subtitle file")
                    onClicked: subtitleDialog.open()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12 * IrisStyle.density
                AnimeStepper {
                    label: Translation.tr("Size")
                    value: AnimeWatch.subtitleScale + "%"
                    onLess: AnimeWatch.setSubtitleScale(AnimeWatch.subtitleScale - 10)
                    onMore: AnimeWatch.setSubtitleScale(AnimeWatch.subtitleScale + 10)
                }
                AnimeStepper {
                    label: Translation.tr("Sync")
                    value: (AnimeWatch.subtitleDelay > 0 ? "+" : "") + AnimeWatch.subtitleDelay.toFixed(1) + " s"
                    onLess: AnimeWatch.nudgeSubtitleDelay(-0.1)
                    onMore: AnimeWatch.nudgeSubtitleDelay(0.1)
                    onReset: AnimeWatch.resetSubtitleDelay()
                }
                Item { Layout.fillWidth: true }
                AnimeChip {
                    glyph: "replay_10"
                    glyphSize: 17
                    Accessible.name: Translation.tr("Back 10 seconds")
                    onClicked: AnimeWatch.seekBy(-10)
                }
                AnimeChip {
                    glyph: "fast_forward"
                    text: Translation.tr("Skip OP")
                    Accessible.name: Translation.tr("Skip 85 seconds")
                    onClicked: AnimeWatch.seekBy(85)
                }
            }
        }
    }

    ColumnLayout {
        Layout.row: Math.max(0, page.rowOf("players"))
        Layout.fillWidth: true
        visible: page.rowOf("players") >= 0 && page.otherPlayers.length > 0
        spacing: 10 * IrisStyle.density
        Rectangle {
            Layout.fillWidth: true
            visible: page.firstExtra === "players"
            implicitHeight: 1
            color: IrisStyle.hairline
        }
        IrisPlayerChips {
            Layout.fillWidth: true
            player: page.island.player
            accent: page.island.artTint
        }
    }

    ColumnLayout {
        Layout.row: Math.max(0, page.rowOf("levels"))
        Layout.fillWidth: true
        visible: page.rowOf("levels") >= 0 && page.streams.length > 0
        spacing: 10 * IrisStyle.density
        Rectangle {
            Layout.fillWidth: true
            visible: page.firstExtra === "levels"
            implicitHeight: 1
            color: IrisStyle.hairline
        }
        Repeater {
            model: page.streams.slice(0, 4)
            RowLayout {
                id: appLevel
                required property var modelData
                readonly property var nodes: Array.from(appLevel.modelData?.nodes ?? [])
                readonly property bool muted: appLevel.nodes.every(node => node?.audio?.muted)
                // Teardown re-evaluates bindings in a dead context; `live` keeps them from applying.
                property bool live: true
                Component.onDestruction: appLevel.live = false
                Layout.fillWidth: true
                spacing: 10 * IrisStyle.density
                IrisImage {
                    Layout.preferredWidth: Math.round(22 * IrisStyle.density)
                    Layout.preferredHeight: Layout.preferredWidth
                    // Decoded at the size it is given, not the size the row lays it at: that read its own decode back.
                    decodeWidth: Math.round(22 * IrisStyle.density)
                    decodeHeight: decodeWidth
                    Binding on source {
                        when: appLevel.live
                        restoreMode: Binding.RestoreNone
                        value: appLevel.nodes.length > 0
                            ? MprisController.streamIconSource(appLevel.nodes[0], "audio-x-generic") : ""
                    }
                    opacity: appLevel.muted ? 0.45 : 1
                }
                IrisText {
                    Layout.preferredWidth: Math.round(110 * IrisStyle.density)
                    text: appLevel.nodes.length > 1 ? appLevel.modelData.name + " · " + appLevel.nodes.length : appLevel.modelData.name
                    color: (appLevel.muted ? IrisStyle.textTertiary : IrisStyle.textStrong)
                    font.pixelSize: IrisStyle.typeMeta
                    font.weight: IrisStyle.weight(Font.Medium)
                    elide: Text.ElideRight
                }
                IrisScrubber {
                    Layout.fillWidth: true
                    fillColor: appLevel.muted ? IrisStyle.muted : IrisStyle.fillStrong
                    Binding on value {
                        when: appLevel.live
                        restoreMode: Binding.RestoreNone
                        value: Math.min(1, Math.max(0, ...appLevel.nodes.map(node => Number(node?.audio?.volume) || 0)))
                    }
                    onMoved: next => appLevel.nodes.forEach(node => { if (node?.audio) node.audio.volume = next })
                }
                GlyphButton {
                    glyph: appLevel.muted ? "volume_off" : "volume_up"
                    glyphSize: 17 * IrisStyle.density
                    implicitWidth: Math.round(30 * IrisStyle.density)
                    glyphColor: appLevel.muted ? IrisStyle.danger : IrisStyle.text
                    Accessible.name: appLevel.muted ? Translation.tr("Unmute") : Translation.tr("Mute")
                    onClicked: {
                        const mute = !appLevel.muted
                        appLevel.nodes.forEach(node => { if (node?.audio) node.audio.muted = mute })
                    }
                }
            }
        }
    }


    FilePickerDialog {
        id: subtitleDialog
        title: Translation.tr("Load subtitles")
        currentFolder: "file://" + Directories.homePath
        nameFilters: [Translation.tr("Subtitles") + " (*.srt *.ass *.ssa *.vtt *.sub)", Translation.tr("All files") + " (*)"]
        onAccepted: AnimeWatch.addSubtitle(String(selectedFile))
    }

    component TransportButton: GlyphButton {
        property bool lead: false
        property bool side: false
        Layout.alignment: Qt.AlignVCenter
        // Every control stands on a soft disc (Apple's expanded player); the pause's is the largest and the most lit,
        // the two at the ends bare until hovered.
        colBackground: side ? "transparent" : lead ? IrisStyle.fillHover : IrisStyle.fillQuiet
        buttonRadius: transport.framed ? (lead ? transport.controlRadius : IrisStyle.pieceRadius(height)) : height / 2
        buttonRadiusPressed: buttonRadius
        glyphSize: (lead ? 30 : side ? 21 : 25) * IrisStyle.density
        implicitWidth: Math.round((lead ? 54 : side ? 38 : 44) * IrisStyle.density)
    }

    component AnimeChip: MouseArea {
        id: chip
        property string text: ""
        property string glyph: ""
        property real glyphSize: 14
        property bool active: false
        implicitWidth: chipRow.implicitWidth + Math.round((chip.text.length > 0 ? 18 : 12) * IrisStyle.density)
        implicitHeight: Math.round(26 * IrisStyle.density)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: chip.text
        Rectangle {
            anchors.fill: parent
            radius: IrisStyle.capsule(height)
            color: chip.active ? IrisStyle.tintFill(page.island.artTint)
                : chip.pressed ? IrisStyle.fillActive : chip.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet
            Behavior on color { ColorAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
        }
        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: Math.round(4 * IrisStyle.density)
            Glyph {
                visible: chip.glyph.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: chip.glyph
                iconSize: chip.glyphSize * IrisStyle.density
                color: chip.active ? page.island.artTint : IrisStyle.text
            }
            IrisText {
                visible: chip.text.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: chip.text
                color: chip.active ? page.island.artTint : IrisStyle.textSecondary
                font.pixelSize: IrisStyle.typeFootnote
                font.weight: IrisStyle.weight(Font.DemiBold)
            }
        }
    }

    component AnimeStepper: RowLayout {
        id: stepper
        property string label: ""
        property string value: ""
        signal less()
        signal more()
        signal reset()
        spacing: Math.round(2 * IrisStyle.density)
        IrisText {
            Layout.alignment: Qt.AlignBaseline
            text: stepper.label
            color: IrisStyle.textSecondary
            font.pixelSize: IrisStyle.typeMeta
            rightPadding: Math.round(4 * IrisStyle.density)
        }
        GlyphButton {
            glyph: "remove"
            glyphSize: 15 * IrisStyle.density
            implicitWidth: Math.round(24 * IrisStyle.density)
            Accessible.name: Translation.tr("Less %1").arg(stepper.label)
            onClicked: stepper.less()
        }
        Tabular {
            Layout.alignment: Qt.AlignBaseline
            text: stepper.value
            font.pixelSize: IrisStyle.typeMeta
            font.weight: IrisStyle.weight(Font.DemiBold)
            horizontalAlignment: Text.AlignHCenter
            Layout.minimumWidth: Math.round(40 * IrisStyle.density)
            TapHandler { onTapped: stepper.reset() }
        }
        GlyphButton {
            glyph: "add"
            glyphSize: 15 * IrisStyle.density
            implicitWidth: Math.round(24 * IrisStyle.density)
            Accessible.name: Translation.tr("More %1").arg(stepper.label)
            onClicked: stepper.more()
        }
    }
}
