pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.style
import "corner"
import "pages"
import "state"

// The Movie Corner, worn with iRiS: its window over the desktop or in a window of its own (its Settings › The Corner),
// its IPC, and, when the person turns it on, an entry in the app launcher. Nothing is built while it is closed.
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
        IrisCornerOverlay { namespace: "quickshell:movie-corner"; open: CornerState.open; body: MovieCorner {} }
    }
    LazyLoader {
        active: CornerState.open && root.windowed
        IrisCornerWindow {
            title: "iNiR Movie Corner"
            open: CornerState.open
            onCloseRequested: CornerState.open = false
            body: MovieCorner { windowed: true }
        }
    }

    // The launcher entry (Settings › The Corner › In the app launcher). It asks the shell to open the Corner; once the
    // Corner is removed, the entry deletes itself the next time it is clicked.
    readonly property string entryPath: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/applications/inir-movie-corner.desktop"
    readonly property string home: Quickshell.shellPath("modules/movie-corner")
    readonly property bool safePaths: /^[A-Za-z0-9._\/-]+$/.test(root.entryPath + root.home)
    readonly property string entry: [
        "[Desktop Entry]",
        "Type=Application",
        "Name=Movie Corner",
        "Comment=" + Translation.tr("Films and series in your language, in mpv"),
        "Icon=" + root.home + "/icons/movie-corner.svg",
        "Categories=AudioVideo;Video;",
        "Keywords=movie;film;series;tv;cinema;",
        // Desktop-entry quoting: \\" reaches sh as ", \\$ as $.
        'Exec=sh -c "if [ -d \\\\"\\\\$1\\\\" ]; then exec inir movie-corner toggle; else rm -f -- \\\\"\\\\$2\\\\"; fi" sh ' + root.home + " " + root.entryPath,
        ""
    ].join("\n")
    readonly property bool wantEntry: CornerState.ready && CornerState.options.launcher && root.safePaths
    onWantEntryChanged: root.syncEntry()
    onEntryChanged: if (root.wantEntry) root.syncEntry()
    function syncEntry(): void {
        if (!CornerState.ready) return
        if (root.wantEntry) entryFile.setText(root.entry)
        else ShellExec.execDetachedArgs(["rm", "-f", "--", root.entryPath], "Movie Corner launcher entry")
    }
    FileView {
        id: entryFile
        path: root.entryPath
        blockLoading: false
        printErrors: false
    }

    /// The Movie Corner: find any film or series and watch it in your language.
    ///
    /// ```kdl
    /// Mod+M { spawn "inir" "movie-corner" "toggle"; }
    /// ```
    IpcHandler {
        target: "movie-corner"
        /// Open or close it
        function toggle(): void { CornerState.open = !CornerState.open }
        /// Open it
        function open(): void { CornerState.open = true }
        /// Close it
        function close(): void { CornerState.open = false }
        /// Open it searching for a film or series
        function search(text: string): void { CornerState.query = text; CornerState.open = true }
        /// Open it on a place: home, continue, following, movies, series, top, years, genres, settings, genre:<name> or title:<movie|series>:<IMDb id>
        function go(place: string): void { CornerState.place = place; CornerState.open = true }
        /// Watch a title by its IMDb id: movie:<id>, or series:<id> with an episode as season:episode (empty opens its page)
        function watch(title: string, episode: string): void {
            const m = /^(movie|series):(tt\d{5,10})$/.exec(String(title))
            if (!m) return
            CornerState.open = true
            const at = /^(\d+):(\d+)$/.exec(String(episode))
            if (m[1] === "series" && !at) { CornerState.place = "title:" + title; return }
            ipcData.detail(m[1], m[2], (show, error) => {
                if (!show) return
                CornerWatch.watch(at ? Object.assign({}, show, { season: Number(at[1]), episode: Number(at[2]),
                    episodeTitle: (show.episodes ?? []).find(e => e.season === Number(at[1]) && e.episode === Number(at[2]))?.title ?? "" }) : show)
            })
        }
        /// Play one of the sources Watch is offering, by its place in the list (0 is the first)
        function choose(index: int): void {
            if (CornerWatch.phase === "choosing" && index >= 0 && index < CornerWatch.sources.length) CornerWatch.play(CornerWatch.sources[index])
        }
        /// Stop what is playing
        function stop(): void { CornerWatch.stop() }
    }
    // What watch() asks Cinemeta; the Corner's own pages keep theirs.
    MovieCornerData { id: ipcData }
}
