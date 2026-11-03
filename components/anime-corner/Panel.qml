pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.iris.pieces
import "corner"
import "pages"
import "state"

// The Anime Corner, worn with iRiS: its window over the desktop or in a window of its own (its Settings › Window),
// its IPC, and the new-episode alerts when the person turns them on. Nothing is built while it is closed.
Scope {
    id: root

    readonly property bool windowed: CornerState.options.windowed
    // Built when it opens; kept until its closing motion ends.
    property bool resident: CornerState.open
    Timer {
        id: grace
        interval: IrisStyle.settleDuration + 120
        onTriggered: root.resident = CornerState.open
    }
    Connections {
        target: CornerState
        function onOpenChanged(): void {
            if (CornerState.open) { grace.stop(); root.resident = true }
            else grace.restart()
        }
    }

    LazyLoader {
        active: root.resident && !root.windowed
        IrisCornerOverlay { namespace: "quickshell:anime-corner"; open: CornerState.open; body: AnimeCorner {} }
    }
    LazyLoader {
        active: CornerState.open && root.windowed
        IrisCornerWindow {
            title: "iNiR Anime Corner"
            open: CornerState.open
            onCloseRequested: CornerState.open = false
            body: AnimeCorner { windowed: true }
        }
    }

    // The launcher entry (Settings › The Corner › In the app launcher). It asks the shell to open the Corner; once the
    // Corner is removed, the entry deletes itself the next time it is clicked.
    readonly property string entryPath: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/applications/inir-anime-corner.desktop"
    readonly property string home: Quickshell.shellPath("modules/anime-corner")
    readonly property bool safePaths: /^[A-Za-z0-9._\/-]+$/.test(root.entryPath + root.home)
    readonly property string entry: [
        "[Desktop Entry]",
        "Type=Application",
        "Name=Anime Corner",
        "Comment=" + Translation.tr("Anime in your language, in mpv"),
        "Icon=video-x-generic",
        "Categories=AudioVideo;Video;",
        "Keywords=anime;anilist;myanimelist;episode;series;",
        // Desktop-entry quoting: \\" reaches sh as ", \\$ as $.
        'Exec=sh -c "if [ -d \\\\"\\\\$1\\\\" ]; then exec qs -c inir ipc call anime-corner toggle; else rm -f -- \\\\"\\\\$2\\\\"; fi" sh ' + root.home + " " + root.entryPath,
        ""
    ].join("\n")
    readonly property bool wantEntry: CornerState.ready && CornerState.options.launcher && root.safePaths
    onWantEntryChanged: root.syncEntry()
    onEntryChanged: if (root.wantEntry) root.syncEntry()
    function syncEntry(): void {
        if (!CornerState.ready) return
        if (root.wantEntry) entryFile.setText(root.entry)
        else ShellExec.execDetachedArgs(["rm", "-f", "--", root.entryPath], "Anime Corner launcher entry")
    }
    FileView {
        id: entryFile
        path: root.entryPath
        blockLoading: false
        printErrors: false
    }

    // New-episode alerts, only when turned on: every half hour, what aired among the shows you follow and the ones
    // you are watching on your list. Its Watch button opens the show.
    property real _checkedAt: Date.now() / 1000 - 3600
    property int _alertShow: 0
    Timer {
        running: CornerState.ready && CornerState.options.notify
        interval: 30 * 60 * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root._check()
    }
    function _check(): void {
        if (CornerAccounts.hasList) CornerAccounts.loadList(false)
        const watching = CornerAccounts.shows.filter(show => show.listStatus === "CURRENT" || show.listStatus === "REPEATING").map(show => show.id)
        const ids = IrisPieces.animeFollowing.concat(watching).filter((id, at, all) => id > 0 && all.indexOf(id) === at)
        if (ids.length === 0 || !Network.online) return
        const from = Math.floor(root._checkedAt)
        const to = Math.floor(Date.now() / 1000)
        AnimeService._graphql("query ($ids: [Int], $from: Int, $to: Int) { Page(perPage: 50) { airingSchedules(mediaId_in: $ids, airingAt_greater: $from, airingAt_lesser: $to, sort: TIME) { episode media { id title { romaji english } } } } }",
            { ids, from, to }, (data, error) => {
                if (error) return
                root._checkedAt = to
                const aired = (data?.Page?.airingSchedules ?? []).filter(entry => entry?.media)
                if (aired.length === 0 || alert.running) return
                const name = entry => String(entry.media.title?.english || entry.media.title?.romaji || "")
                // A notification's body may be read as markup (its summary never is): titles there are text, never tags.
                const escaped = text => text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
                const last = aired[aired.length - 1]
                root._alertShow = Number(last.media.id)
                alert.command = ["notify-send", "-a", "iNiR", "-i", "live_tv", "-A", "watch=" + Translation.tr("Watch"), "--",
                    aired.length === 1 ? Translation.tr("%1: episode %2 is out").arg(name(last)).arg(last.episode)
                        : Translation.tr("%1 new episodes are out").arg(aired.length),
                    aired.map(entry => Translation.tr("%1 · episode %2").arg(escaped(name(entry))).arg(entry.episode)).join("\n")]
                alert.running = true
            })
    }
    Process {
        id: alert
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() === "watch" && root._alertShow > 0) {
                CornerState.place = "anime:" + root._alertShow
                CornerState.open = true
            }
        }
    }

    /// The Anime Corner: find any show on AniList and watch it in your language.
    ///
    /// ```kdl
    /// Mod+A { spawn "inir" "anime-corner" "toggle"; }
    /// ```
    IpcHandler {
        target: "anime-corner"
        /// Open or close it
        function toggle(): void { CornerState.open = !CornerState.open }
        /// Open it
        function open(): void { CornerState.open = true }
        /// Close it
        function close(): void { CornerState.open = false }
        /// Open it searching for a show
        function search(text: string): void { CornerState.query = text; CornerState.open = true }
        /// Open it on a place: home, continue, mylist, following, popular, trending, top, season, calendar, genres, settings, genre:<name> or anime:<AniList id>
        function go(place: string): void { CornerState.place = place; CornerState.open = true }
        /// Watch a show by its title: an episode number plays it, an empty one asks which
        function watch(title: string, episode: string): void {
            CornerState.open = true
            CornerWatch.lookFor({ title: title })
            if (String(episode).length > 0) CornerWatch.play(null, title, episode)
            else CornerWatch.search(title)
        }
        /// Answer the question the watch run is asking, by the option's value
        function choose(value: string): void { if (CornerWatch.choosing) CornerWatch.choose(value) }
    }
}
