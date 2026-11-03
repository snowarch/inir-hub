pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions
import qs.services
import qs.services.deferred

/**
 * CornerWatch — the Movie Corner's player. The engine (modules/movie-corner/scripts/inir-movie.py) asks every site of
 * the chosen language at once and prints one line per source that plays; the person picks one (or the best plays
 * when asked to), and mpv opens it here with its IPC socket in a run folder of its own under $XDG_RUNTIME_DIR, so
 * MpvIpc follows the position. Progress is kept per film and per episode, so each resumes where it stopped.
 */
Singleton {
    id: root

    readonly property double finishedRatio: 0.9
    readonly property string engine: Quickshell.shellPath("modules/movie-corner/scripts/inir-movie.py")
    readonly property string agent: "Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0"

    readonly property var audioLanguages: ["original", "es-419", "es-ES"]
    readonly property string audio: {
        const saved = String(CornerState.options.audio ?? "original")
        return root.audioLanguages.includes(saved) ? saved : "original"
    }
    // With the original audio, the subtitles' language: "auto" follows the shell's language.
    readonly property var subLanguages: ["en", "es", "pt-BR", "fr", "de", "it", "ar", "ru", "tr", "ja", "ko", "zh", "hi", "id", "vi", "pl", "uk", "he", "nl"]
    readonly property string subs: {
        if (root.audio !== "original") return ""
        const saved = String(CornerState.options.subs ?? "auto")
        if (saved === "none") return ""
        if (root.subLanguages.includes(saved)) return saved
        const shell = String(Translation.loadedLanguageCode || "en_US")
        const wanted = shell === "pt_BR" ? "pt-BR" : shell.split("_")[0]
        return root.subLanguages.includes(wanted) ? wanted : "en"
    }
    readonly property string source: String(CornerState.options.source || "ask")

    function languageName(code: string): string {
        return ({ original: Translation.tr("Original audio"), "es-419": Translation.tr("Latin American Spanish"), "es-ES": Translation.tr("Spain Spanish"),
            en: Translation.tr("English"), es: Translation.tr("Spanish"), "pt-BR": Translation.tr("Brazilian Portuguese"), fr: Translation.tr("French"),
            de: Translation.tr("German"), it: Translation.tr("Italian"), ar: Translation.tr("Arabic"), ru: Translation.tr("Russian"), tr: Translation.tr("Turkish"),
            ja: Translation.tr("Japanese"), ko: Translation.tr("Korean"), zh: Translation.tr("Chinese"), hi: Translation.tr("Hindi"), id: Translation.tr("Indonesian"),
            vi: Translation.tr("Vietnamese"), pl: Translation.tr("Polish"), uk: Translation.tr("Ukrainian"), he: Translation.tr("Hebrew"), nl: Translation.tr("Dutch") })[code] ?? code
    }
    // What Watch will play, in words: "Original audio · Spanish subtitles".
    readonly property string watchLine: [root.languageName(root.audio),
        root.subs.length > 0 ? Translation.tr("%1 subtitles").arg(root.languageName(root.subs)) : ""].filter(x => x.length > 0).join(" · ")

    // idle → finding (the engine asks the sites) → choosing (the person picks) → launching → playing → idle.
    property string phase: "idle"
    readonly property bool busy: root.phase !== "idle"
    readonly property bool canStart: root.phase === "idle" || root.phase === "choosing" || root.phase === "playing"
    property string error: ""
    // The sheet stays open while a failure is read.
    property bool holdError: false
    // What is being watched: { id, kind, title, year, tmdb, image, season, episode, episodeTitle }.
    property var item: null
    property var sources: []
    property string fallbackFrom: ""
    property var _retry: null

    function keyOf(entry: var): string {
        return entry.kind === "series" ? entry.id + ":" + entry.season + ":" + entry.episode : String(entry.id)
    }
    function labelOf(entry: var): string {
        return entry.kind === "series" ? Translation.tr("%1 · S%2 E%3").arg(entry.title).arg(entry.season).arg(entry.episode) : String(entry.title)
    }
    function siteName(id: string): string { return ({ vidsrc: "vidsrc.buzz", magistv: "MagisTV24" })[id] ?? id }

    // Watch a film, or an episode of a series ({ season, episode } in `entry`).
    function watch(entry: var): void {
        if (!entry || String(entry.id ?? "").length === 0) return
        root.cancel()
        root.error = ""
        root.sources = []
        root.fallbackFrom = ""
        root.item = Object.assign({ kind: "movie", season: 0, episode: 0 }, entry)
        root._retry = () => root.watch(entry)
        const args = ["python3", root.engine, "sources", "--kind", root.item.kind, "--title", String(root.item.title ?? ""),
            "--audio=" + root.audio, "--subs=" + root.subs, "--source=" + root.source]
        if (String(root.item.year ?? "").length > 0) args.push("--year=" + String(root.item.year).slice(0, 4))
        if (/^tt\d+$/.test(String(root.item.id))) args.push("--imdb=" + root.item.id)
        if (Number(root.item.tmdb ?? 0) > 0) args.push("--tmdb=" + Number(root.item.tmdb))
        if (root.item.kind === "series") args.push("-s", String(Number(root.item.season)), "-e", String(Number(root.item.episode)))
        finder.command = args
        root.phase = "finding"
        finder.running = true
    }
    function retry(): void { if (root._retry && root.phase === "idle") { root.error = ""; root._retry() } }
    function cancel(): void {
        if (finder.running) finder.running = false
        if (root.phase === "finding" || root.phase === "choosing") root.phase = "idle"
    }
    function _found(): void {
        if (root.phase !== "finding") return
        if (root.sources.length === 0) {
            root.phase = "idle"
            root.error = Network.online ? Translation.tr("No site has this in %1 right now").arg(root.languageName(root.audio)) : Network.offlineReason
            return
        }
        if (root.source !== "ask" || root.sources.length === 1) root.play(root.sources[0])
        else root.phase = "choosing"
    }
    Process {
        id: finder
        stdout: SplitParser {
            onRead: line => {
                let row = null
                try { row = JSON.parse(line) } catch (e) { return }
                if (row.done) { Qt.callLater(root._found); return }
                if (row.note === "fallback") { root.fallbackFrom = String(row.site ?? ""); return }
                if (String(row.url ?? "").startsWith("https://")) root.sources = root.sources.concat([row])
            }
        }
        onExited: (code, status) => {
            if (root.phase !== "finding") return
            if (code !== 0) { root.phase = "idle"; root.error = Translation.tr("The sites did not answer") }
            else Qt.callLater(root._found)
        }
    }

    // ── The player ───────────────────────────────────────────────────────────────────────────────────────────
    readonly property string runsHome: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/inir-movie-corner"
    property string runDir: ""
    property var session: null
    readonly property string playingTitle: root.phase === "playing" ? mpv.mediaTitle : ""

    function play(source: var): void {
        if (!root.item || !source) return
        const entry = root.item
        const started = root.startOf(entry)
        if (mpv.running) mpv.quit()
        root.runDir = root.runsHome + "/" + Date.now()
        root.session = Object.assign({}, entry, { key: root.keyOf(entry) })
        const flags = ["--input-ipc-server=" + root.runDir + "/mpv.sock", "--force-media-title=" + root.labelOf(entry),
            "--user-agent=" + root.agent, "--referrer=" + String(source.referer ?? ""),
            // A sound server with no output must not freeze the picture at 0:00.
            "--audio-fallback-to-null=yes"]
        // Only the options the engine is known to send; a site never adds its own.
        for (const flag of Array.from(source.flags ?? [])) if (flag === "--demuxer-lavf-o=extension_picky=0") flags.push(flag)
        if (started > 0) flags.push("--start=" + Math.floor(started))
        for (const track of Array.from(source.subtitles ?? []))
            if (String(track.url ?? "").startsWith("https://")) flags.push("--sub-file=" + track.url)
        root.phase = "launching"
        ShellExec.execDetachedArgs(["/bin/sh", "-c", 'mkdir -p -m 700 -- "$1" && shift && exec "$@"', "sh", root.runDir,
            "mpv", ...flags, "--", String(source.url)], "Movie: " + root.labelOf(entry))
        mpv.begin(root.runDir + "/mpv.sock", root.runDir + "/reject")
    }
    function stop(): void { if (mpv.running) mpv.quit() }

    MpvIpc {
        id: mpv
        onStarted: {
            if (root.phase === "launching") root.phase = "playing"
            claimTimer.tries = 0
            claimTimer.restart()
        }
        onClosed: root._closed()
    }
    function _closed(): void {
        root._record()
        const run = root.runDir
        const watched = root.session
        root.session = null
        root.runDir = ""
        if (root.phase === "launching" && watched) root.error = Translation.tr("The player could not open this source; try another")
        if (root.phase === "launching" || root.phase === "playing") root.phase = root.error.length > 0 && root.sources.length > 1 ? "choosing" : "idle"
        if (run.indexOf(root.runsHome + "/") === 0) ShellExec.execDetachedArgs(["rm", "-rf", "--", run], "Clean movie run")
    }

    // Starting is asking to watch: the player becomes the one the Island follows, once MPRIS has it.
    Timer {
        id: claimTimer
        property int tries: 0
        interval: 500
        repeat: true
        onTriggered: {
            const title = mpv.mediaTitle
            const player = title.length > 0 ? Array.from(MprisController.players ?? []).find(candidate => String(MprisController.titleOf(candidate) ?? "") === title) : null
            if (player) MprisController.setActivePlayer(player)
            if (player || ++claimTimer.tries >= 12 || root.phase !== "playing") claimTimer.stop()
        }
    }
    Timer {
        running: root.phase === "playing"
        interval: 20000
        repeat: true
        onTriggered: root._record()
    }
    Timer {
        running: root.error.length > 0 && !root.busy && !root.holdError
        interval: 30000
        onTriggered: root.error = ""
    }

    // ── Progress: key (IMDb id, or id:season:episode) → { seconds, duration, at, and what it was } ──────────────
    property var progress: ({})
    readonly property string progressPath: Directories.stateUserPath + "/movie-corner-progress.json"
    function _record(): void {
        const entry = root.session
        if (!entry) return
        const position = Math.max(0, Number(mpv.position) || 0)
        const duration = Math.max(0, Number(mpv.duration) || 0)
        if (position <= 0 || duration <= 0) return
        const all = Object.assign({}, root.progress)
        all[entry.key] = { id: entry.id, kind: entry.kind, title: entry.title, year: entry.year ?? "", tmdb: entry.tmdb ?? 0,
            image: entry.image ?? "", season: entry.season ?? 0, episode: entry.episode ?? 0, episodeTitle: entry.episodeTitle ?? "",
            seconds: position, duration: duration, at: Date.now() }
        root.progress = all
        progressFile.setText(JSON.stringify(all))
    }
    function stateOf(entry: var): var {
        const saved = root.progress[root.keyOf(entry)]
        const duration = Number(saved?.duration) || 0
        const seconds = Number(saved?.seconds) || 0
        return { seconds, duration, progress: duration > 0 ? Math.min(1, seconds / duration) : 0, finished: duration > 0 && seconds / duration > root.finishedRatio }
    }
    function startOf(entry: var): double {
        const state = root.stateOf(entry)
        return state.finished ? 0 : Math.max(0, state.seconds - 5)
    }
    function forget(key: string): void {
        const all = Object.assign({}, root.progress)
        delete all[key]
        root.progress = all
        progressFile.setText(JSON.stringify(all))
    }
    // Continue watching: one entry per title, the latest first. A finished episode offers the next one; a finished
    // film leaves the list.
    readonly property var watching: {
        const latest = ({})
        for (const key in root.progress) {
            const entry = root.progress[key]
            if (!entry?.id) continue
            if (!latest[entry.id] || Number(entry.at) > Number(latest[entry.id].at)) latest[entry.id] = entry
        }
        return Object.values(latest).sort((a, b) => Number(b.at) - Number(a.at)).map(entry => {
            const done = Number(entry.duration) > 0 && Number(entry.seconds) / Number(entry.duration) > root.finishedRatio
            if (done && entry.kind !== "series") return null
            const next = done ? { season: Number(entry.season), episode: Number(entry.episode) + 1 } : { season: Number(entry.season), episode: Number(entry.episode) }
            return Object.assign({}, entry, next, { progress: done ? 0 : Number(entry.seconds) / Math.max(1, Number(entry.duration)), watch: true })
        }).filter(entry => entry !== null)
    }
    // The next thing to play of a title: where Continue is, else the start.
    function nextOf(show: var): var {
        const found = root.watching.find(entry => entry.id === show?.id)
        return found ? { season: found.season, episode: found.episode, progress: found.progress } : null
    }

    // Settings › Check the sources: every site tried live on one film, the verdict as a notification.
    property bool checking: false
    function checkSources(): void {
        if (root.checking) return
        root.checking = true
        Notifications.send(Translation.tr("Checking film sources"), Translation.tr("Every site is tried on one film; this takes about half a minute."), "low", 6000)
        doctor.running = true
    }
    Process {
        id: doctor
        command: ["python3", root.engine, "doctor"]
        stdout: StdioCollector {
            id: doctorOut
            onStreamFinished: {
                const rows = doctorOut.text.trim().split("\n").map(line => { try { return JSON.parse(line) } catch (e) { return null } }).filter(row => row !== null)
                const ok = rows.filter(row => row.ok).length
                Notifications.send(Translation.tr("Film sources: %1 of %2 play").arg(ok).arg(rows.length),
                    rows.map(row => "%1 · %2: %3".arg(row.name).arg(root.languageName(row.audio)).arg(row.ok ? (row.height > 0 ? row.height + "p" : "OK") : Translation.tr("not playing"))).join("\n"),
                    ok === rows.length ? "low" : "normal", 20000)
            }
        }
        onExited: root.checking = false
    }

    FileView {
        id: progressFile
        path: root.progressPath
        // No file yet is the first run, not an error.
        printErrors: false
        onLoaded: {
            try { root.progress = JSON.parse(progressFile.text()) ?? {} } catch (e) { root.progress = {} }
        }
    }
}
