pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import "streams.js" as Streams
import "watch.js" as Watch
import "subtitles.js" as Subtitles

// Watching a title: it asks the person's add-ons, lets them pick, and plays in mpv while the Corner is open.
// A position alone doesn't count: mpv reports 0 for a stream it then can't read.
// It runs nothing unless someone pressed Watch. idle → finding → choosing → launching → playing → idle.
Singleton {
    id: root

    property string phase: "idle"
    property var show: null
    property var episode: null
    property var streams: []
    property var sourceResults: []
    property bool mappingError: false
    property var subtitles: []
    property var selectedSubtitle: null
    property bool subtitleChoiceMade: false
    property var retryPlayback: null
    property string subtitleError: ""
    // What didn't answer or play, in words.
    property string error: ""
    property bool mpvMissing: false
    // mpv took long to say it is playing; it isn't stopped, only explained.
    property bool slow: false
    property real position: 0
    property real duration: 0
    property bool paused: false
    property real subtitleDelay: 0
    property bool fullscreen: false
    property var playbackTracks: []
    property var audioTrack: "no"
    property var subtitleTrack: "no"
    property bool controlLinked: false
    property int controlAttempts: 0
    readonly property string controlPath: {
        const runtime = String(Quickshell.env("XDG_RUNTIME_DIR") ?? "")
        return runtime.startsWith("/") && runtime.length < 300 ? `${runtime}/media-corner-mpv-${Quickshell.processId}.sock` : ""
    }
    readonly property string title: root.show ? String(root.show.title ?? "") : ""
    readonly property bool busy: root.phase === "launching" || root.phase === "playing"

    property int _ticket: 0
    property int _waiting: 0
    property bool _subtitleSearchFailed: false
    property bool _fallbackSearched: false
    property var _next: null
    property var _current: null
    property real _startedAt: 0
    property bool _stopping: false
    property var _watchCalls: []

    function _cancelWatchCalls(): void {
        const calls = root._watchCalls
        root._watchCalls = []
        for (const callback of calls) CornerState.cancelAsk(callback)
    }
    function _watchAsk(url: string, shape: var, done: var): void {
        const callback = (value, error, retryAfter) => {
            root._watchCalls = root._watchCalls.filter(call => call !== callback)
            done(value, error, retryAfter)
        }
        root._watchCalls = root._watchCalls.concat([callback])
        CornerState.ask(url, "", shape, callback)
    }

    // ── Finding.
    function begin(title: var, chosen: var): void {
        root._ticket++
        root._cancelWatchCalls()
        CornerSubtitles.cancel()
        if (root.phase === "playing") root._keep()
        if (mpv.running) { root._stopping = true; mpv.running = false }
        root._next = null
        root.show = title
        root.episode = chosen
        root.streams = []
        root.sourceResults = []
        root.mappingError = false
        root.subtitles = []
        root.selectedSubtitle = null
        root.subtitleChoiceMade = false
        root.retryPlayback = null
        root.subtitleError = ""
        root._subtitleSearchFailed = false
        root._fallbackSearched = false
        root.error = ""
        root.phase = "finding"
        CornerState.sheet = true
        mpvCheck.running = true
        const addons = CornerSources.addons
        const direct = Boolean(CornerState.options.subtitleApiKey) && /^tt\d+$/.test(String(title?.id ?? ""))
        if (addons.length === 0 && CornerSources.subtitles.length === 0 && !direct) { root.subtitleChoiceMade = true; root.phase = "choosing"; return }
        if (title.kind !== "anime") { root._ask(addons, ""); return }
        // Add-ons know an anime by Kitsu's id: AniList's is mapped to it first.
        const ticket = root._ticket
        const query = `filter[externalSite]=anilist/anime&filter[externalId]=${Number(title.id)}&include=item`
        root._watchAsk("https://kitsu.app/api/edge/mappings?" + query, body => Streams.kitsuIdFrom(body), (kitsu, error) => {
            if (ticket === root._ticket) {
                root.mappingError = Boolean(error)
                root._ask(addons, error ? "" : kitsu, Boolean(error))
            }
        })
    }
    function _ask(addons: var, kitsu: string, mappingError = false): void {
        const ticket = root._ticket
        const streamPaths = addons.map((addon, index) => ({ addon, index, path: Streams.pathFor(addon, root.show, root.episode, kitsu), kind: "stream" }))
        root.sourceResults = Watch.initialSourceResults(streamPaths, root.show?.kind, kitsu, mappingError)
        const subtitlePaths = CornerSources.subtitles.map(addon => ({ addon, path: Streams.pathFor(addon, root.show, root.episode, kitsu, "subtitles"), kind: "subtitles" }))
        const paths = streamPaths.concat(subtitlePaths).filter(p => p.path.length > 0)
        const direct = Boolean(CornerState.options.subtitleApiKey) && /^tt\d+$/.test(String(root.show?.id ?? ""))
        root._waiting = paths.length + (direct ? 1 : 0)
        if (root._waiting === 0) { root._found(); return }
        if (direct) CornerSubtitles.search(String(root.show.id), String(CornerState.options.subtitleLanguage).toLowerCase(), root.episode, (found, error, retryAfter) => {
            if (ticket !== root._ticket) return
            if (!error) root.subtitles = root.subtitles.concat(found)
            else if (error === "busy") root.subtitleError = CornerSubtitles.limitedMessage(retryAfter ?? "")
            else if (error !== "unavailable" && error !== "cancelled") root.subtitleError = Translation.tr("Subtitle service is unavailable")
            if (error) root._subtitleSearchFailed = true
            if (--root._waiting === 0) root._found()
        })
        for (const task of paths) {
            root._watchAsk(`${Streams.baseOf(task.addon.url)}/${task.kind}/${task.path}.json`, body => task.kind === "stream" ? Streams.streamsFrom(body) : Streams.subtitlesFrom(body), (found, error, retryAfter) => {
                if (ticket !== root._ticket) return
                if (task.kind === "stream") root.sourceResults = Watch.updateSourceResult(root.sourceResults, task.index, error, found?.length ?? 0, retryAfter)
                if (error && task.kind === "stream") root.error = Translation.tr("Request failed")
                if (error && task.kind === "subtitles") root._subtitleSearchFailed = true
                if (error === "busy" && task.kind === "subtitles") root.subtitleError = CornerState.limitedText(retryAfter ?? "")
                else if (!error && task.kind === "stream") root.streams = Watch.insertSourceStreams(root.streams, found, task.index, CornerSources.displayName(task.addon))
                else if (!error) root.subtitles = root.subtitles.concat(found.map(s => Object.assign({ source: CornerSources.displayName(task.addon) }, s)))
                if (--root._waiting === 0) root._found()
            })
        }
    }
    function _found(): void {
        const wanted = String(CornerState.options.subtitleLanguage).toLowerCase()
        const fallback = String(CornerState.options.subtitleFallbackLanguage).toLowerCase()
        const primary = Subtitles.findLanguage(root.subtitles, wanted)
        if (!primary && fallback && !root._subtitleSearchFailed && !root._fallbackSearched && CornerState.options.subtitleApiKey && /^tt\d+$/.test(String(root.show?.id ?? ""))) {
            root._fallbackSearched = true
            const ticket = root._ticket
            CornerSubtitles.search(String(root.show.id), fallback, root.episode, (found, error, retryAfter) => {
                if (ticket !== root._ticket) return
                if (!error) root.subtitles = root.subtitles.concat(found)
                else if (error === "busy") root.subtitleError = CornerSubtitles.limitedMessage(retryAfter ?? "")
                else if (error !== "unavailable" && error !== "cancelled") root.subtitleError = Translation.tr("Subtitle service is unavailable")
                root._found()
            })
            return
        }
        root.phase = "choosing"
        root.selectedSubtitle = Subtitles.preferredSelection(root.subtitles, wanted, fallback, root._subtitleSearchFailed, CornerState.options.subtitleAutoSelect)
        root.subtitleChoiceMade = CornerState.options.subtitleAutoSelect || root.subtitles.length === 0
    }
    function chooseSubtitle(subtitle: var): void {
        root.selectedSubtitle = subtitle
        root.subtitleChoiceMade = true
        root.error = ""
    }
    function cancel(): void {
        root._ticket++
        root._cancelWatchCalls()
        root.retryPlayback = null
        CornerSubtitles.cancel()
        // Leaving while it opens: nobody is waiting for it now, and it shouldn't turn up later.
        if (root.phase === "launching" || root._next !== null) root.stop()
        else if (root.phase !== "playing") root.phase = "idle"
    }
    Connections {
        target: CornerState
        function onOpenChanged(): void {
            if (CornerState.open) return
            root._ticket++
            root._cancelWatchCalls()
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
        }
    }

    // ── Playing. The address comes from the network: it is only ever an https address after `--`, in a list of arguments.
    // shortcut: mpv is a child of the shell, so `inir restart` closes it; detach it if that gets in the way.
    function play(stream: var, resume: bool): void {
        if (!Streams.mediaUrl(stream?.url) || !root.subtitleChoiceMade || !root.progressLoaded || root.phase === "launching") return
        root.error = ""
        root.retryPlayback = null
        if (root.selectedSubtitle?.fileId) {
            const ticket = root._ticket
            root.phase = "launching"
            CornerSubtitles.download(Number(root.selectedSubtitle.fileId), (url, error, retryAfter) => {
                if (ticket !== root._ticket) return
                if (error || !url) {
                    root.error = error === "login" ? Translation.tr("Sign in to OpenSubtitles in Sources first") : error === "busy" ? CornerSubtitles.limitedMessage(retryAfter ?? "") : Translation.tr("Could not download subtitles; try again or choose no subtitles")
                    root.retryPlayback = { stream, resume }
                    root.phase = "choosing"
                    return
                }
                root.selectedSubtitle = Object.assign({}, root.selectedSubtitle, { url: url, fileId: 0 })
                root.phase = "choosing"
                root.play(stream, resume)
            })
            return
        }
        if (mpv.running || root._stopping) {
            root._next = { stream, resume }
            root.phase = "launching"
            if (mpv.running) { root._stopping = true; mpv.running = false }
            return
        }
        root._start(stream, resume)
    }
    function stop(): void {
        root._ticket++
        root._cancelWatchCalls()
        CornerSubtitles.cancel()
        root._next = null
        root.retryPlayback = null
        if (root.phase === "playing") root._keep()
        root._stopping = root._stopping || mpv.running
        mpv.running = false
        if (root.phase === "playing" || root.phase === "launching") root.phase = "idle"
    }
    function control(action: string): void {
        if (!root.controlLinked || !controlSocket.item || !CornerState.open || root.phase !== "playing") return
        const commands = { pause: ["cycle", "pause"], back: ["seek", -10, "relative"], forward: ["seek", 10, "relative"],
            subtitleEarlier: ["add", "sub-delay", -0.5], subtitleLater: ["add", "sub-delay", 0.5], fullscreen: ["cycle", "fullscreen"] }
        if (!Object.prototype.hasOwnProperty.call(commands, action)) return
        controlSocket.item.write(JSON.stringify({ command: commands[action] }) + "\n")
        if (action === "pause") controlSocket.item.write(JSON.stringify({ command: ["get_property", "pause"], request_id: 1 }) + "\n")
        controlSocket.item.flush()
    }
    function selectTrack(type: string, id: var): void {
        if (!root.controlLinked || !controlSocket.item || !CornerState.open || root.phase !== "playing") return
        if (type !== "audio" && type !== "sub") return
        if (!(type === "sub" && id === "no") && !root.playbackTracks.some(track => track.type === type && track.id === id)) return
        controlSocket.item.write(JSON.stringify({ command: ["set_property", type === "audio" ? "aid" : "sid", id] }) + "\n")
        controlSocket.item.flush()
    }
    function _start(stream: var, shouldResume: bool): void {
        if (!Streams.mediaUrl(stream?.url)) return
        const key = Streams.watchKey(root.show, root.episode)
        const resume = shouldResume ? root.resumeAt(key) : 0
        // keep-open would keep mpv alive, with no window, on a stream it can't read: it has to end for that to be told.
        const args = ["mpv", "--ytdl=no", "--keep-open=no", "--sub-delay=0", "--terminal", "--no-really-quiet", "--no-input-terminal", "--term-status-msg=@@POS ${=time-pos} ${=duration} ${vo-configured}"]
        if (root.controlPath.length) args.push("--input-ipc-server=" + root.controlPath)
        if (root.selectedSubtitle && Streams.mediaUrl(root.selectedSubtitle.url)) args.push("--sub-file=" + root.selectedSubtitle.url)
        if (!root.selectedSubtitle) args.push("--sid=no")
        if (Streams.mediaUrl(stream.referer)) args.push("--referrer=" + stream.referer)
        if (resume > 0) args.push("--start=" + Math.floor(resume))
        args.push("--", stream.url)
        root._current = { stream, key, title: root.title, show: { id: root.show.id, kind: root.show.kind, title: root.title, type: root.show.type ?? "", film: Boolean(root.show.film) }, episode: root.episode }
        root._startedAt = resume
        root._stopping = false
        root.position = 0
        root.duration = 0
        root.slow = false
        root.paused = false
        root.subtitleDelay = 0
        root.fullscreen = false
        root.playbackTracks = []
        root.audioTrack = "no"
        root.subtitleTrack = "no"
        root.controlAttempts = 0
        root.phase = "launching"
        mpv.command = args
        mpv.running = true
    }
    function _playing(): void {
        root.phase = "playing"
        CornerState.sheet = false
    }
    Loader {
        id: controlSocket
        active: false
        sourceComponent: Socket {
            path: root.controlPath
            connected: true
            onConnectionStateChanged: {
                root.controlLinked = connected
                if (connected) {
                    write(JSON.stringify({ command: ["get_property", "pause"], request_id: 1 }) + "\n")
                    write(JSON.stringify({ command: ["observe_property", 1, "pause"] }) + "\n")
                    write(JSON.stringify({ command: ["observe_property", 2, "sub-delay"] }) + "\n")
                    write(JSON.stringify({ command: ["observe_property", 3, "fullscreen"] }) + "\n")
                    write(JSON.stringify({ command: ["observe_property", 4, "track-list"] }) + "\n")
                    write(JSON.stringify({ command: ["observe_property", 5, "aid"] }) + "\n")
                    write(JSON.stringify({ command: ["observe_property", 6, "sid"] }) + "\n")
                    flush()
                }
            }
            parser: SplitParser {
                onRead: line => {
                    if (line.length > 65536) return
                    try {
                        const reply = JSON.parse(line)
                        if (reply.request_id === 1 && reply.error === "success" && typeof reply.data === "boolean") root.paused = reply.data
                        if (reply.event === "property-change" && reply.name === "pause" && typeof reply.data === "boolean") root.paused = reply.data
                        if (reply.event === "property-change" && reply.name === "sub-delay" && typeof reply.data === "number") root.subtitleDelay = reply.data
                        if (reply.event === "property-change" && reply.name === "fullscreen" && typeof reply.data === "boolean") root.fullscreen = reply.data
                        if (reply.event === "property-change" && reply.name === "track-list") root.playbackTracks = Streams.playbackTracks(reply.data)
                        if (reply.event === "property-change" && reply.name === "aid" && (Number.isSafeInteger(reply.data) || reply.data === false || reply.data === "no")) root.audioTrack = reply.data === false ? "no" : reply.data
                        if (reply.event === "property-change" && reply.name === "sid" && (Number.isSafeInteger(reply.data) || reply.data === false || reply.data === "no")) root.subtitleTrack = reply.data === false ? "no" : reply.data
                    } catch (e) {}
                }
            }
        }
    }
    Timer {
        interval: 250
        repeat: true
        running: CornerState.open && root.phase === "playing" && root.controlPath.length > 0 && !root.controlLinked && root.controlAttempts < 40
        onTriggered: {
            root.controlAttempts++
            controlSocket.active = false
            controlSocket.active = true
        }
    }
    Connections {
        target: CornerState
        function onOpenChanged(): void { if (!CornerState.open) controlSocket.active = false }
    }
    Process {
        id: mpv
        stdout: SplitParser {
            onRead: line => {
                if (root._stopping) return
                const status = Streams.statusFrom(line)
                if (status === null) return
                root.position = status.position
                root.duration = status.duration
                // Sound has no window: for that, the position moving from where it started is the sign.
                if (root.phase === "launching" && (status.window || status.position > root._startedAt + 1)) root._playing()
            }
        }
        onExited: code => {
            controlSocket.active = false
            root.controlLinked = false
            if (root._stopping) {
                root._stopping = false
                const next = root._next
                root._next = null
                if (next !== null && CornerState.open && CornerState.sheet && root.phase === "launching") root._start(next.stream, next.resume)
                return
            }
            const played = root.phase === "playing"
            if (played) root._keep()
            root.phase = "idle"
            // 4 is a signal or a quit: someone stopped it. Any other end before there was anything to see is a failure,
            // unless it was stopped here: mpv cut off while opening exits as if it couldn't open.
            if (code === 4 || root._stopping || (played && code === 0)) return
            root.error = code === 1 ? Translation.tr("mpv could not start. Check its configuration")
                : played ? Translation.tr("mpv stopped with an error. Try another stream")
                : Translation.tr("mpv couldn't play it. Try another stream")
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

    // A separate local list of titles the person wants to watch.
    function matchesSaved(show: var, query: string): bool {
        if (!show) return false
        const kind = show.kind === "anime" ? "Anime" : show.kind === "movie" ? "Movie" : "Series"
        return Watch.matchesSaved(show, query, [Translation.tr(kind), Translation.tr(String(show.type ?? ""))])
    }
    readonly property var sortedSavedKeys: Watch.sortedSavedKeys(root.watchlist, root.progress, CornerState.options.savedOrder)
    property var watchlist: ({})
    property bool watchlistLoaded: false
    property bool watchlistLoadFailed: false
    property var pendingWatchlistToggles: []
    function toggleWatchlist(show: var): void {
        const key = Streams.watchKey(show, null), addedAt = Date.now()
        root.watchlist = Watch.toggleWatchlist(root.watchlist, key, show, addedAt)
        if (root.watchlistLoaded) watchlistFile.setText(JSON.stringify(root.watchlist))
        else root.pendingWatchlistToggles = root.pendingWatchlistToggles.concat([{ show, addedAt }])
    }
    function finishWatchlistLoad(value: var): void {
        let list = value
        for (const pending of root.pendingWatchlistToggles)
            list = Watch.toggleWatchlist(list, Streams.watchKey(pending.show, null), pending.show, pending.addedAt)
        const changed = root.pendingWatchlistToggles.length > 0
        root.pendingWatchlistToggles = []
        root.watchlist = list
        root.watchlistLoaded = true
        root.watchlistLoadFailed = false
        if (changed) watchlistFile.setText(JSON.stringify(list))
    }
    function retryWatchlistLoad(): void {
        root.watchlistLoadFailed = false
        watchlistFile.reload()
    }
    FileView {
        id: watchlistFile
        path: Directories.stateUserPath + "/media-corner-watchlist.json"
        printErrors: false
        onLoaded: {
            try { root.finishWatchlistLoad(Watch.parseWatchlist(watchlistFile.text())) }
            catch (e) { root.watchlistLoaded = false; root.watchlistLoadFailed = true }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) root.finishWatchlistLoad({})
            else { root.watchlistLoaded = false; root.watchlistLoadFailed = true }
        }
    }

    // ── Progress: id or id:season:episode → { position, duration, at }.
    property var progress: ({})
    property bool progressLoaded: false
    property bool progressLoadFailed: false
    property var pendingProgress: ({})
    function retryProgressLoad(): void { root.progressLoadFailed = false; progressFile.reload() }
    function finishProgressLoad(value: var): void {
        const pending = root.pendingProgress
        root.progress = Object.assign({}, value, pending)
        root.pendingProgress = ({})
        root.progressLoaded = true
        root.progressLoadFailed = false
        if (Object.keys(pending).length) progressFile.setText(JSON.stringify(root.progress))
    }
    // Explicit marks are independent of playback positions; false overrides automatic completion.
    property var seenMarks: ({})
    property bool seenMarksLoaded: false
    property bool seenMarksLoadFailed: false
    function retrySeenMarks(): void { root.seenMarksLoadFailed = false; seenFile.reload() }
    function setSeen(key: string, seen: bool): void {
        if (!root.seenMarksLoaded) return
        root.seenMarks = Object.assign({}, root.seenMarks, { [key]: seen })
        seenFile.setText(JSON.stringify(root.seenMarks))
    }
    function _keep(): void {
        if (!root._current || root.position <= 0) return
        const entry = { position: root.position, duration: root.duration, at: Date.now(), show: root._current.show, episode: root._current.episode }
        if (!root.progressLoaded) {
            root.pendingProgress = Object.assign({}, root.pendingProgress, { [root._current.key]: entry })
            return
        }
        root.progress = Object.assign({}, root.progress, { [root._current.key]: entry })
        progressFile.setText(JSON.stringify(root.progress))
    }
    // Where to pick it up: a little before where it stopped, unless it was barely started or is finished.
    function forget(key: string): void {
        if (!root.progressLoaded || (root.busy && root._current?.key === key)) return
        const next = Object.assign({}, root.progress)
        delete next[key]
        root.progress = next
        progressFile.setText(JSON.stringify(next))
    }
    function resetProgress(key: string): void {
        if (!root.progressLoaded) return
        const next = Watch.resetProgress(root.progress, key)
        if (next === root.progress) return
        root.progress = next
        progressFile.setText(JSON.stringify(root.progress))
    }
    function resumeAt(key: string): real {
        const kept = root.progress[key]
        return kept && kept.position > 30 && !(kept.duration > 0 && kept.position / kept.duration >= 0.9) ? kept.position - 5 : 0
    }
    function isSeen(key: string): bool {
        return Watch.isSeen(root.progress, root.seenMarks, key)
    }
    FileView {
        id: seenFile
        path: Directories.stateUserPath + "/media-corner-seen.json"
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(seenFile.text())
                if (!data || typeof data !== "object" || Array.isArray(data)) { root.seenMarksLoadFailed = true; return }
                root.seenMarks = data
                root.seenMarksLoaded = true
                root.seenMarksLoadFailed = false
            } catch (e) { root.seenMarksLoadFailed = true }
        }
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) root.seenMarksLoaded = true; else root.seenMarksLoadFailed = true }
    }
    FileView {
        id: progressFile
        path: Directories.stateUserPath + "/media-corner-progress.json"
        // It doesn't exist until something has been watched.
        printErrors: false
        onLoaded: {
            try { root.finishProgressLoad(Watch.parseProgress(progressFile.text())) }
            catch (e) { root.progressLoaded = false; root.progressLoadFailed = true }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) root.finishProgressLoad({})
            else { root.progressLoaded = false; root.progressLoadFailed = true }
        }
    }
}
