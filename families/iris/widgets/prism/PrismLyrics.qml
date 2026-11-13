pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.widgets
import "root:modules/common/functions/LyricsMath.js" as LyricsMath

// Lyrics in Prism: the song on the tab, where it is on the flap, the line being sung in the pane and the next one
// waiting on the foot. Without a line to sing, the pane says why (nothing playing, looking, none, offline).
PrismFolder {
    id: root

    readonly property var player: MprisController.activePlayer
    readonly property string title: MprisController.titleOf(root.player) ?? ""
    readonly property string artist: MprisController.artistOf(root.player) ?? ""
    readonly property bool hasPlayer: root.player !== null && root.title.length > 0
    readonly property bool wanted: root.live && root.hasPlayer
    onWantedChanged: root.wanted ? LyricsService.subscribe(root) : LyricsService.unsubscribe(root)
    Component.onCompleted: if (root.wanted) LyricsService.subscribe(root)
    Component.onDestruction: LyricsService.unsubscribe(root)

    readonly property string status: LyricsService.status
    readonly property var lines: root.status === "ok" ? LyricsService.lyricsLines : []
    readonly property bool instrumental: root.lines.length > 0 && LyricsMath.isNotice(root.lines)
    readonly property var stageLines: root.instrumental ? [] : LyricsMath.stage(root.lines)
    readonly property string mode: !root.hasPlayer ? "idle" : root.stageLines.length > 0 ? "singing"
        : root.instrumental ? "instrumental" : root.status === "offline" ? "offline"
        : root.status === "loading" || root.status === "idle" || root.status === "ok" ? "loading" : "none"
    readonly property bool singing: root.mode === "singing"

    // The song's time, four times a second while it plays and is seen; held otherwise.
    property real songTime: 0
    function tick(): void { root.songTime = LyricsService.clockAt(Date.now()) }
    readonly property var _clock: [LyricsService.clockPos, LyricsService.clockMs, LyricsService.playing, root.moving, root.singing]
    on_ClockChanged: root.tick()
    Timer {
        interval: 250
        repeat: true
        running: root.singing && root.moving && LyricsService.playing
        onTriggered: root.tick()
    }
    readonly property int at: root.singing ? Math.floor(LyricsMath.cursor(root.stageLines, root.songTime, 0.45)) : -1
    function lineAt(index: int): string {
        const entry = root.stageLines[index]
        return !entry ? "" : entry.gap ? "♪" : String(entry.text ?? "")
    }
    readonly property string now: root.lineAt(Math.max(0, root.at))
    readonly property var coming: [root.lineAt(root.at + 1), root.lineAt(root.at + 2)].filter(line => line.length > 0)

    tabGlyph: "lyrics"
    tabText: root.hasPlayer ? root.title : Translation.tr("Lyrics")
    flapText: root.hasPlayer ? Math.floor(root.songTime / 60) + ":" + String(Math.floor(root.songTime % 60)).padStart(2, "0") : ""
    lightPass: root.singing && LyricsService.playing ? 1 : 0.5

    FaceText {
        face: root
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.paneMiddle - height / 2)
        text: root.singing ? root.now
            : root.mode === "idle" ? Translation.tr("Play something with words")
            : root.mode === "instrumental" ? Translation.tr("Instrumental")
            : root.mode === "offline" ? Translation.tr("Lyrics need an internet connection")
            : root.mode === "loading" ? Translation.tr("Looking for lyrics") : Translation.tr("No lyrics for this song")
        color: root.singing ? root.ink : root.inkSecondary
        size: root.singing ? root.type(16, 20, 26) : root.type(13, 15, 19)
        weight: Font.Bold
        lineHeight: 0.96
        wrapMode: Text.WordWrap
        maximumLineCount: root.large ? 3 : 2
        fontSizeMode: Text.Fit
        minimumPixelSize: root.px(12)
        height: Math.min(implicitHeight, root.paneBottom - root.paneTop - root.dp(12))
    }
    Column {
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.large ? root.footTop + root.dp(22) : root.footTop + (root.footHeight - height) / 2 - root.dp(2))
        spacing: root.dp(8)
        Repeater {
            model: root.singing ? root.coming.slice(0, root.large ? 2 : 1) : [root.artist].filter(name => name.length > 0)
            FaceText {
                required property string modelData
                required property int index
                face: root
                width: root.innerWidth
                text: modelData
                color: index === 0 ? root.inkSecondary : root.inkTertiary
                size: root.type(12.5, 14, 17)
                weight: Font.DemiBold
                wrapMode: Text.WordWrap
                maximumLineCount: root.large ? 2 : 1
                elide: Text.ElideRight
            }
        }
    }
}
