pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"
import "../state/streams.js" as Streams

// What mpv plays, as Settings shows a song: its picture, its name, a timeline to seek and round keys, play in the
// middle. With nothing playing it offers to pick up the latest episode. The rail, a title's page and the mini player
// all show this one card, in both styles.
Rectangle {
    id: root
    // The picture on top; off where room is short.
    property bool large: true
    // Subtitle delay, tracks, fullscreen and stop under the keys.
    property bool extras: true
    // Only while something plays (the mini player); otherwise it also offers to continue.
    property bool playingOnly: false
    readonly property real d: IrisStyle.density
    readonly property var current: CornerWatch.current
    readonly property var latest: CornerWatch.latest
    readonly property bool playing: root.current !== null
    readonly property var show: root.playing ? root.current.show : root.latest?.entry?.show ?? null
    readonly property var episode: root.playing ? root.current.episode : root.latest?.entry?.episode ?? null
    readonly property bool hasContent: root.show !== null
    readonly property real position: root.playing ? CornerWatch.position : Number(root.latest?.entry?.position ?? 0)
    readonly property real length: root.playing ? CornerWatch.duration : Number(root.latest?.entry?.duration ?? 0)

    function episodeText(episode: var): string {
        if (!episode) return ""
        return (episode.season ? Translation.tr("Season %1").arg(episode.season) + " · " : "") + Translation.tr("Episode %1").arg(episode.episode)
    }
    function pickUp(): void {
        if (!root.latest?.entry?.show) return
        CornerState.openShow(root.latest.entry.show)
        CornerWatch.begin(root.latest.entry.show, root.latest.entry.episode ?? null)
    }

    visible: root.hasContent && (root.playing || !root.playingOnly)
    implicitHeight: body.implicitHeight + 2 * Math.round(14 * root.d)
    radius: IrisStyle.radiusCard
    color: CornerSkin.card
    border.width: CornerSkin.edgeWidth
    border.color: CornerSkin.edge

    ColumnLayout {
        id: body
        anchors.fill: parent
        anchors.margins: Math.round(14 * root.d)
        spacing: Math.round(10 * root.d)

        ClippingRectangle {
            visible: root.large
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(width * 0.62)
            radius: IrisStyle.radiusTile
            color: CornerSkin.plate
            IrisImage {
                anchors.fill: parent
                source: String(root.show?.banner || root.show?.image || "")
                fillMode: Image.PreserveAspectCrop
            }
            MaterialSymbol {
                anchors.centerIn: parent
                visible: !root.show?.banner && !root.show?.image
                text: root.show?.kind === "anime" ? "animation" : "movie"
                fill: 1
                iconSize: Math.round(40 * root.d)
                color: IrisStyle.textTertiary
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(2 * root.d)
            IrisText {
                Layout.fillWidth: true
                text: !root.playing ? Translation.tr("Continue") : CornerWatch.phase !== "playing" ? Translation.tr("Opening mpv…")
                    : CornerWatch.paused ? Translation.tr("Paused") : Translation.tr("Now playing")
                color: IrisStyle.textSecondary
                font.pixelSize: IrisStyle.typeMeta
                horizontalAlignment: root.large ? Text.AlignHCenter : Text.AlignLeft
            }
            IrisText {
                Layout.fillWidth: true
                text: String(root.show?.title ?? "")
                textFormat: Text.PlainText
                font.pixelSize: IrisStyle.typeHeadline
                font.weight: IrisStyle.weight(Font.Bold)
                elide: Text.ElideRight
                horizontalAlignment: root.large ? Text.AlignHCenter : Text.AlignLeft
            }
            IrisText {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.episodeText(root.episode)
                color: IrisStyle.textSecondary
                font.pixelSize: IrisStyle.typeMeta
                elide: Text.ElideRight
                horizontalAlignment: root.large ? Text.AlignHCenter : Text.AlignLeft
            }
        }
        RowLayout {
            Layout.fillWidth: true
            visible: root.length > 0
            spacing: Math.round(8 * root.d)
            IrisText { text: Streams.clock(root.position); color: IrisStyle.textSecondary; font.pixelSize: IrisStyle.typeFootnote }
            IrisScrubber {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                value: root.length > 0 ? Math.max(0, Math.min(1, root.position / root.length)) : 0
                seekable: CornerWatch.controllable
                knob: CornerWatch.controllable
                thickness: 5
                engagedThickness: 9
                onSeekRequested: value => CornerWatch.seek(value * CornerWatch.duration)
            }
            IrisText { text: Streams.clock(root.length); color: IrisStyle.textSecondary; font.pixelSize: IrisStyle.typeFootnote }
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.round(14 * root.d)
            CornerRound {
                visible: root.playing
                glyph: "replay_10"
                enabled: CornerWatch.controllable
                Accessible.name: Translation.tr("Seek backward")
                onClicked: CornerWatch.control("back")
            }
            CornerRound {
                solid: true
                size: Math.round(46 * root.d)
                glyph: root.playing && !CornerWatch.paused ? "pause" : "play_arrow"
                enabled: !root.playing || CornerWatch.controllable
                Accessible.name: !root.playing ? Translation.tr("Continue") : CornerWatch.paused ? Translation.tr("Resume") : Translation.tr("Pause")
                onClicked: root.playing ? CornerWatch.control("pause") : root.pickUp()
            }
            CornerRound {
                visible: root.playing
                glyph: "forward_10"
                enabled: CornerWatch.controllable
                Accessible.name: Translation.tr("Seek forward")
                onClicked: CornerWatch.control("forward")
            }
        }
        RowLayout {
            visible: root.extras && root.playing
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.round(2 * root.d)
            CornerRound {
                glyph: "remove"
                size: Math.round(30 * root.d)
                enabled: CornerWatch.controllable
                Accessible.name: Translation.tr("Show subtitles earlier")
                onClicked: CornerWatch.control("subtitleEarlier")
            }
            IrisText {
                text: Translation.tr("Subtitle delay: %1 s").arg(CornerWatch.subtitleDelay.toFixed(1))
                color: IrisStyle.textSecondary
                font.pixelSize: IrisStyle.typeFootnote
            }
            CornerRound {
                glyph: "add"
                size: Math.round(30 * root.d)
                enabled: CornerWatch.controllable
                Accessible.name: Translation.tr("Show subtitles later")
                onClicked: CornerWatch.control("subtitleLater")
            }
            CornerRound {
                glyph: CornerWatch.fullscreen ? "fullscreen_exit" : "fullscreen"
                size: Math.round(30 * root.d)
                enabled: CornerWatch.controllable
                Accessible.name: CornerWatch.fullscreen ? Translation.tr("Exit fullscreen") : Translation.tr("Fullscreen")
                onClicked: CornerWatch.control("fullscreen")
            }
            CornerRound {
                glyph: "stop"
                size: Math.round(30 * root.d)
                Accessible.name: Translation.tr("Stop")
                onClicked: CornerWatch.stop()
            }
        }
        PlaybackTracks { Layout.fillWidth: true; visible: root.extras && root.playing && CornerWatch.controllable }
    }
}
