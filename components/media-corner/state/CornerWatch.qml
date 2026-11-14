pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import "streams.js" as Streams

// Watching a title: it asks the person's add-ons, lets them pick, and plays in mpv while the Corner is open.
// A position alone doesn't count: mpv reports 0 for a stream it then can't read.
// It runs nothing unless someone pressed Watch. idle → finding → choosing → launching → playing → idle.
Singleton {
    id: root

    property string phase: "idle"
    property var show: null
    property var episode: null
    property var streams: []
    property var subtitles: []
    property var selectedSubtitle: null
    property string subtitleError: ""
    // What didn't answer or play, in words.
    property string error: ""
    property bool mpvMissing: false
    // mpv took long to say it is playing; it isn't stopped, only explained.
    property bool slow: false
    property real position: 0
    property real duration: 0
    readonly property string title: root.show ? String(root.show.title ?? "") : ""
    readonly property bool busy: root.phase === "launching" || root.phase === "playing"

    property int _ticket: 0
    property int _waiting: 0
    property var _next: null
    property var _current: null
    property real _startedAt: 0
    property bool _stopping: false

    // ── Finding.
    function begin(title: var, chosen: var): void {
        root._ticket++
        root.show = title
        root.episode = chosen
        root.streams = []
        root.subtitles = []
        root.selectedSubtitle = null
        root.subtitleError = ""
        root.error = ""
        root.phase = "finding"
        CornerState.sheet = true
        mpvCheck.running = true
        const addons = CornerSources.addons
        if (addons.length === 0 && CornerSources.subtitles.length === 0) { root.phase = "choosing"; return }
        if (title.kind !== "anime") { root._ask(addons, ""); return }
        // Add-ons know an anime by Kitsu's id: AniList's is mapped to it first.
        const ticket = root._ticket
        const query = `filter[externalSite]=anilist/anime&filter[externalId]=${Number(title.id)}&include=item`
        CornerState.ask("https://kitsu.app/api/edge/mappings?" + query, "", body => Streams.kitsuIdFrom(body), (kitsu, error) => {
            if (ticket === root._ticket) root._ask(addons, error ? "" : kitsu)
        })
    }
    function _ask(addons: var, kitsu: string): void {
        const ticket = root._ticket
        const streamPaths = addons.map(addon => ({ addon, path: Streams.pathFor(addon, root.show, root.episode, kitsu), kind: "stream" }))
        const subtitlePaths = CornerSources.subtitles.map(addon => ({ addon, path: Streams.pathFor(addon, root.show, root.episode, kitsu), kind: "subtitles" }))
        const paths = streamPaths.concat(subtitlePaths).filter(p => p.path.length > 0)
        const direct = Boolean(CornerState.options.subtitleApiKey) && /^tt\d+$/.test(String(root.show?.id ?? ""))
        root._waiting = paths.length + (direct ? 1 : 0)
        if (root._waiting === 0) { root._found(); return }
        if (direct) CornerSubtitles.search(String(root.show.id), String(CornerState.options.subtitleLanguage).toLowerCase(), root.episode, (found, error) => {
            if (ticket !== root._ticket) return
            if (!error) root.subtitles = root.subtitles.concat(found)
            else if (error === "busy") root.subtitleError = Translation.tr("Subtitle service is busy; try again later")
            else if (error !== "unavailable") root.subtitleError = Translation.tr("Subtitle service is unavailable")
            if (--root._waiting === 0) root._found()
        })
        for (const task of paths) {
            CornerState.ask(`${Streams.baseOf(task.addon.url)}/${task.kind}/${task.path}.json`, "", body => task.kind === "stream" ? Streams.streamsFrom(body) : Streams.subtitlesFrom(body), (found, error) => {
                if (ticket !== root._ticket) return
                if (error && task.kind === "stream") root.error = Translation.tr("%1 didn't answer (´・ω・`)").arg(task.addon.name)
                else if (!error && task.kind === "stream") root.streams = root.streams.concat(found.map(s => Object.assign({ source: task.addon.name }, s)))
                else if (!error) root.subtitles = root.subtitles.concat(found.map(s => Object.assign({ source: task.addon.name }, s)))
                if (--root._waiting === 0) root._found()
            })
        }
    }
    function _found(): void {
        root.phase = "choosing"
        const wanted = String(CornerState.options.subtitleLanguage).toLowerCase()
        const aliases = { eng: "en", spa: "es", por: "pt", fra: "fr", deu: "de", ita: "it", jpn: "ja" }
        root.selectedSubtitle = root.subtitles.find(s => s.lang === wanted || s.lang === aliases[wanted]) ?? null
        root._playTheOnlyOne()
    }
    // Nothing to pick: straight to mpv, once it's known to be there (an answer from the cache can beat the check).
    function _playTheOnlyOne(): void {
        if (root.phase !== "choosing" || mpvCheck.running || root.mpvMissing) return
        if (root.streams.length === 1 && root.subtitles.length === 0 && CornerSources.webs.length === 0 && root.error.length === 0) root.play(root.streams[0])
    }
    function cancel(): void {
        root._ticket++
        CornerSubtitles.cancel()
        // Leaving while it opens: nobody is waiting for it now, and it shouldn't turn up later.
        if (root.phase === "launching") root.stop()
        else if (root.phase !== "playing") root.phase = "idle"
    }
    Connections {
        target: CornerState
        function onOpenChanged(): void {
            if (CornerState.open) return
            if (root.phase === "playing") root._keep()
            root._ticket++
            mpvCheck.running = false
            root.stop()
            root.phase = "idle"
            CornerState.sheet = false
        }
        function onSheetChanged(): void { if (!CornerState.sheet) root.cancel() }
        // The Corner is going: the answers it waited for won't be told to anyone.
        function onCallersDropped(): void {
            if (root.busy) return
            root.cancel()
            CornerState.sheet = false
        }
    }
    Process {
        id: mpvCheck
        command: ["sh", "-c", "command -v mpv"]
        onExited: code => {
            root.mpvMissing = code !== 0
            root._playTheOnlyOne()
        }
    }

    // ── Playing. The address comes from the network: it is only ever an https address after `--`, in a list of arguments.
    // shortcut: mpv is a child of the shell, so `inir restart` closes it; detach it if that gets in the way.
    function play(stream: var): void {
        if (!/^https:\/\//.test(String(stream?.url ?? ""))) return
        root.error = ""
        if (root.selectedSubtitle?.fileId) {
            const ticket = root._ticket
            root.phase = "launching"
            CornerSubtitles.download(Number(root.selectedSubtitle.fileId), (url, error) => {
                if (ticket !== root._ticket) return
                if (error || !url) {
                    root.error = error === "login" ? Translation.tr("Sign in to OpenSubtitles in Sources first") : Translation.tr("Could not download subtitles; try again or choose no subtitles")
                    root.phase = "choosing"
                    return
                }
                root.selectedSubtitle = Object.assign({}, root.selectedSubtitle, { url: url, fileId: 0 })
                root.play(stream)
            })
            return
        }
        if (mpv.running) { root._next = stream; mpv.running = false; return }
        root._start(stream)
    }
    function stop(): void {
        root._next = null
        root._stopping = mpv.running
        mpv.running = false
    }
    function _start(stream: var): void {
        const key = Streams.watchKey(root.show, root.episode)
        const resume = root.resumeAt(key)
        // keep-open would keep mpv alive, with no window, on a stream it can't read: it has to end for that to be told.
        const args = ["mpv", "--ytdl=no", "--keep-open=no", "--terminal", "--no-really-quiet", "--no-input-terminal", "--term-status-msg=@@POS ${=time-pos} ${=duration} ${vo-configured}"]
        if (root.selectedSubtitle) args.push("--sub-file=" + root.selectedSubtitle.url)
        if (stream.referer) args.push("--referrer=" + stream.referer)
        if (resume > 0) args.push("--start=" + Math.floor(resume))
        args.push("--", stream.url)
        root._current = { stream, key, title: root.title }
        root._startedAt = resume
        root._stopping = false
        root.position = 0
        root.duration = 0
        root.slow = false
        root.phase = "launching"
        mpv.command = args
        mpv.running = true
    }
    function _playing(): void {
        root.phase = "playing"
        CornerState.sheet = false
    }
    Process {
        id: mpv
        stdout: SplitParser {
            onRead: line => {
                const status = Streams.statusFrom(line)
                if (status === null) return
                root.position = status.position
                root.duration = status.duration
                // Sound has no window: for that, the position moving from where it started is the sign.
                if (root.phase === "launching" && (status.window || status.position > root._startedAt + 1)) root._playing()
            }
        }
        onExited: code => {
            const played = root.phase === "playing"
            if (played) root._keep()
            if (root._next !== null) {
                const next = root._next
                root._next = null
                root._start(next)
                return
            }
            root.phase = "idle"
            // 4 is a signal or a quit: someone stopped it. Any other end before there was anything to see is a failure,
            // unless it was stopped here: mpv cut off while opening exits as if it couldn't open.
            if (played || code === 4 || root._stopping) return
            root.error = Translation.tr("mpv couldn't play it. Try another stream")
            root.phase = "choosing"
            if (CornerState.open) CornerState.sheet = true
            else Notifications.send(Translation.tr("Media Corner"), root.error, "normal", 6000)
        }
    }
    Timer {
        interval: 30000
        running: root.phase === "launching"
        onTriggered: root.slow = true
    }
    Timer {
        interval: 20000
        repeat: true
        running: root.phase === "playing"
        onTriggered: root._keep()
    }

    // ── Progress: id or id:season:episode → { position, duration, at }.
    property var progress: ({})
    function _keep(): void {
        if (!root._current || root.position <= 0) return
        root.progress = Object.assign({}, root.progress, { [root._current.key]: { position: root.position, duration: root.duration, at: Date.now() } })
        progressFile.setText(JSON.stringify(root.progress))
    }
    // Where to pick it up: a little before where it stopped, unless it was barely started or is finished.
    function resumeAt(key: string): real {
        const kept = root.progress[key]
        return kept && kept.position > 30 && !root.isSeen(key) ? kept.position - 5 : 0
    }
    function isSeen(key: string): bool {
        const kept = root.progress[key]
        return Boolean(kept) && kept.duration > 0 && kept.position / kept.duration >= 0.9
    }
    FileView {
        id: progressFile
        path: Directories.stateUserPath + "/media-corner-progress.json"
        // It doesn't exist until something has been watched.
        printErrors: false
        onLoaded: {
            try { root.progress = JSON.parse(progressFile.text()) ?? {} } catch (e) { root.progress = {} }
        }
    }
}
