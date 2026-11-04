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
 * CornerWatch — the Anime Corner's player runs, in the language the person picks. iRiS's own AnimeWatch keeps
 * playing ani-cli for the Continue bubble; this one runs the Corner's engine beside it, in a runs folder of its own,
 * and shares ani-cli's history with it so Continue lists both.
 *
 * The engine (modules/anime-corner/scripts/inir-anime.py) plays every language from many sites and hands English to
 * ani-cli when asked; it speaks ani-cli's conversation, so scripts/inir-ani runs it (linked as the run's ani-cli)
 * with iNiR as its menu (scripts/inir-ani-menu) and its player (scripts/inir-mpv): every question comes here,
 * and mpv hands its IPC socket to MpvIpc. Each
 * run owns a directory under $XDG_RUNTIME_DIR; its `exit` file says when ani-cli
 * is gone and why. Progress is kept here per show and episode, so an episode
 * resumes where it stopped. jerry and curd only get their history listed and
 * their own continue command in a terminal.
 */
Singleton {
    id: root

    readonly property int maxShows: 6
    // Nothing starts a process until the Corner has been opened; then it stays on for the session, so closing the
    // Corner never cuts a run short.
    readonly property bool enabled: CornerState.used
    onEnabledChanged: if (root.enabled && !root.detected) root.refresh()
    readonly property double finishedRatio: 0.9
    // The spoken language: "ja" (the original), or a dub.
    readonly property var audioLanguages: ["ja", "en", "es-419", "pt-BR", "fr", "de", "it", "ru", "hi", "ta", "te"]
    readonly property string audio: {
        const saved = String(CornerState.options.audio ?? "ja")
        return root.audioLanguages.includes(saved) ? saved : "ja"
    }
    // With Japanese audio, the language of the subtitles burned into the picture. "auto" follows the shell's
    // language where some site has it, else English.
    readonly property var subLanguages: ["en", "es", "pt-BR", "fr", "de", "it", "ar"]
    readonly property string subs: {
        if (root.audio !== "ja") return ""
        const saved = String(CornerState.options.subs ?? "auto")
        if (root.subLanguages.includes(saved)) return saved
        const shell = String(Translation.loadedLanguageCode || "en_US")
        const wanted = shell === "pt_BR" ? "pt-BR" : shell.split("_")[0]
        return root.subLanguages.includes(wanted) ? wanted : "en"
    }
    // ask: every source of the episode is offered with its quality and subtitles; auto: the best that answers;
    // or a site's id, tried first.
    readonly property string source: String(CornerState.options.source || "ask")
    // Run in ani-cli's place: inir-ani puts the run's bin first in PATH, so a link named ani-cli there wins.
    readonly property string engine: Quickshell.shellPath("modules/anime-corner/scripts/inir-anime.py")
    // AniList's names and id for the next run, from the Anime Corner: the engine finds the show by them on every site.
    property var _nextMeta: null
    property var _runIds: null
    // The show a run started from the Corner is for (its cover, banner and names), for the watch sheet.
    property var watchShow: null
    // The Corner's watch sheet keeps a failure on screen until it is closed there.
    property bool holdError: false
    // What the last Watch asked, so a failed start can be tried again as it was.
    property var _retry: null
    // After the player closes, the run only waits to be told what next: a new Watch ends it and starts over.
    readonly property bool canStart: !root.busy || root.phase === "between"
    property var _queued: null
    function _takeOver(start: var): bool {
        if (!root.busy) return false
        if (root.phase === "between" && root.running) { root._queued = start; root.cancel() }
        return true
    }
    function retry(): void { if (root._retry && !root.busy) { root.error = ""; root._retry() } }
    function lookFor(show: var): void {
        root.watchShow = show ?? null
        root._nextMeta = show ? { anilistId: Number(show.id ?? 0) || 0, malId: Number(show.idMal ?? 0) || 0,
            titles: [show.titleRomaji, show.titleEnglish, show.title].filter(t => String(t ?? "").length > 0) } : null
    }
    // Quality, subtitle look and intro skipping are iRiS's own Anime settings, read as they are.
    readonly property string quality: String(Config.options?.iris?.anime?.quality ?? "best")
    readonly property int subtitleScale: Math.max(50, Math.min(200, Number(Config.options?.iris?.anime?.subtitleScale ?? 100)))
    readonly property int subtitlePosition: Math.max(50, Math.min(100, Number(Config.options?.iris?.anime?.subtitlePosition ?? 100)))
    readonly property bool skipIntro: Config.options?.iris?.anime?.skipIntro ?? false
    property bool hasAniSkip: false

    property string cli: ""
    property var shows: []
    property bool detected: false
    property var progress: ({})
    property var session: null
    // Why the last run ended without playing, in words for the card.
    property string error: ""
    readonly property bool available: root.enabled && root.cli.length > 0
    // "ani-cli" is the engine's conversation, also when only python3 is there to run it.
    readonly property bool canTarget: root.available && root.cli === "ani-cli"
    readonly property var current: root.shows.length > 0 ? root.shows[0] : null

    readonly property string _dataHome: {
        const value = Quickshell.env("XDG_DATA_HOME")
        return value && value.length > 0 ? value : Directories.homePath + "/.local/share"
    }

    readonly property string _stateHome: {
        const value = Quickshell.env("XDG_STATE_HOME")
        return value && value.length > 0 ? value : Directories.homePath + "/.local/state"
    }

    readonly property string _runsHome: {
        const value = Quickshell.env("XDG_RUNTIME_DIR")
        return (value && value.length > 0 ? value : "/tmp") + "/inir-anime-corner"
    }

    readonly property string progressPath: Directories.stateUserPath + "/anime-corner-progress.json"
    readonly property string coversPath: Directories.stateUserPath + "/anime-corner-covers.json"
    // AniList cover art by show key. ani-cli's history names a show but carries no
    // art, and mpv playing a stream publishes none, so the title is looked up once.
    property var covers: ({})
    property var _coverAsked: ({})
    readonly property string playingCover: root.session ? root.coverOf(root.session) : ""
    readonly property string launcher: Directories.scriptPath + "/inir-ani"

    property string runDir: ""
    readonly property bool running: root.runDir.length > 0
    property int _pid: 0
    property bool _cancelled: false
    // An answer decided before ani-cli asks: skipping from the Island quits the
    // player, and the question that follows is answered with where to go.
    property string _autoAnswer: ""
    // This run was started with its episode (play()), so ani-cli never asks for one.
    property bool _episodeGiven: false

    // idle -> searching (ani-cli is asking which show or episode) -> launching (an
    // episode is resolving, no player yet) -> playing -> between (the player closed,
    // ani-cli is asking what next) -> ... -> idle once ani-cli exits. Nothing starts
    // a second run before the first ends: two players would share one show's
    // progress and fight over its position.
    property string phase: "idle"
    readonly property bool busy: root.running || root.phase !== "idle"
    readonly property string busyKey: root.session ? String(root.session.key) : ""
    readonly property string busyEpisode: root.session ? String(root.session.episode) : ""
    readonly property string playingTitle: root.phase === "playing" ? mpv.mediaTitle : ""

    function coverOf(entry: var): string {
        return String(root.covers[root.progressKey(entry)] ?? "")
    }

    function _wantCover(title: string): void {
        const key = root.progressKey({ title: title })
        if (!root.enabled || key.length === 0 || root.covers[key] || root._coverAsked[key]) return
        root._coverAsked[key] = true
        AnimeService.findCover(title, url => {
            if (url.length === 0) return
            const all = Object.assign({}, root.covers)
            all[key] = url
            root.covers = all
            coversFile.setText(JSON.stringify(all))
        })
    }

    onShowsChanged: {
        if (coversFile.loaded) for (const show of root.shows) root._wantCover(String(show.title))
    }
    onSessionChanged: {
        // Subtitles found belong to the episode they were found for.
        root.subtitleResults = []
        root.subtitleNotes = []
        if (root.session && coversFile.loaded) root._wantCover(String(root.session.title))
    }

    function isBusyFor(entry: var): bool {
        return root.busy && root.busyKey.length > 0 && root.busyKey === root.progressKey(entry)
    }

    // The Island's player is this run's mpv when MPRIS reports the title the wrapper set.
    function ownsPlayer(player: var): bool {
        return root.playingTitle.length > 0 && String(MprisController.titleOf(player) ?? "") === root.playingTitle
    }

    property var pick: null
    readonly property bool choosing: root.pick !== null
    readonly property string pickPrompt: root.pick ? String(root.pick.prompt ?? "") : ""
    readonly property var pickItems: root.pick ? (root.pick.items ?? []) : []
    readonly property bool betweenEpisodes: root.pickPrompt.indexOf("Playing episode") === 0
    readonly property bool pickingQuality: root.pickPrompt.indexOf("Select Quality") === 0
    readonly property bool pickingShow: root.pickPrompt.indexOf("Select anime") === 0
    readonly property bool pickingEpisode: root.pickPrompt.indexOf("Select episode") === 0
    readonly property bool pickingSource: root.pickPrompt.indexOf("Select source") === 0

    // A source line is "<n> <json>": the site, its server, the audio, subtitles (burned in or not) and the height.
    function sourceOf(item: string): var {
        const text = String(item ?? "")
        const cut = text.indexOf(" ")
        try {
            const found = JSON.parse(text.slice(cut + 1))
            return found && typeof found === "object" ? found : ({})
        } catch (e) {
            return ({})
        }
    }

    // What a Watch button plays in, short enough for a chip: "Latin American Spanish", "Japanese · Spanish subtitles",
    // and the site when one is fixed in Settings.
    readonly property string watchLine: [root.audio === "ja" && root.subs.length > 0
            ? Translation.tr("Japanese · %1 subtitles").arg(root.languageName(root.subs)) : root.languageName(root.audio),
        ...(["ask", "auto"].includes(root.source) ? [] : [root.source === "anicli" ? "ani-cli" : root.source])].join(" · ")
    function languageName(code: string): string {
        switch (String(code)) {
        case "ja": return Translation.tr("Japanese")
        case "en": return Translation.tr("English")
        case "es-419": return Translation.tr("Latin American Spanish")
        case "es": return Translation.tr("Spanish")
        case "pt-BR": return Translation.tr("Brazilian Portuguese")
        case "fr": return Translation.tr("French")
        case "de": return Translation.tr("German")
        case "it": return Translation.tr("Italian")
        case "ru": return Translation.tr("Russian")
        case "hi": return Translation.tr("Hindi")
        case "ta": return Translation.tr("Tamil")
        case "te": return Translation.tr("Telugu")
        case "ar": return Translation.tr("Arabic")
        }
        return String(code)
    }
    property string query: ""
    // The episode asked for before the run knows the show (busyEpisode needs a session).
    property string wantedEpisode: ""

    function actionLabel(id: string): string {
        switch (String(id)) {
        case "next": return Translation.tr("Next episode")
        case "replay": return Translation.tr("Play again")
        case "previous": return Translation.tr("Previous")
        case "select": return Translation.tr("Another episode")
        case "change_quality": return Translation.tr("Source")
        case "quit": return Translation.tr("Done")
        }
        return String(id)
    }

    // ani-cli numbers what it offers and expects that number back; the label is what
    // follows it. Quality lines are "<quality> ><url>" and answer with the quality.
    function pickLabel(item: string): string {
        const text = String(item ?? "")
        if (root.pickingSource) {
            const s = root.sourceOf(text)
            return [s.provider, s.height > 0 ? s.height + "p" : "", s.server].filter(x => String(x ?? "").length > 0).join(" · ")
        }
        if (root.pickingQuality) return text.split(">")[0].trim()
        const cut = text.indexOf(" ")
        return cut < 0 ? text : text.slice(cut + 1)
    }

    function pickValue(item: string): string {
        const text = String(item ?? "")
        if (root.pickingQuality) return text.split(">")[0].trim()
        const cut = text.indexOf(" ")
        return cut < 0 ? text : text.slice(0, cut)
    }

    readonly property var subtitles: root.phase === "playing" ? (mpv.subTracks ?? []) : []
    readonly property int subtitleId: mpv.subId
    readonly property double subtitleDelay: mpv.subDelay
    readonly property var audios: root.phase === "playing" ? (mpv.audioTracks ?? []) : []
    readonly property int audioId: mpv.audioId

    function selectAudio(id: int): void { mpv.apply("aid", id) }
    function nudgeSubtitleDelay(seconds: real): void { mpv.apply("sub-delay", Math.round((mpv.subDelay + seconds) * 10) / 10) }
    function resetSubtitleDelay(): void { mpv.apply("sub-delay", 0) }
    function seekBy(seconds: real): void { mpv.seekBy(seconds) }
    function addSubtitle(path: string): void { mpv.addSub(String(path ?? "").replace(/^file:\/\//, "")) }
    function _applySubtitleLook(): void {
        mpv.apply("sub-scale", root.subtitleScale / 100)
        mpv.apply("sub-pos", root.subtitlePosition)
    }
    onSubtitleScaleChanged: root._applySubtitleLook()
    onSubtitlePositionChanged: root._applySubtitleLook()

    // An external track's title is the provider's file name, never a label a person
    // can read, so only the language names a track.
    // ani-cli's provider publishes one track, labelled English, as a remote file named by a hash; a
    // file the person loaded is named after itself.
    function subtitleLabel(track: var, index: int): string {
        const lang = String(track?.lang ?? "").trim()
        if (lang.length > 0) return lang.toUpperCase()
        const file = String(track?.["external-filename"] ?? "")
        if (track?.external === true && file.length > 0 && !/^[a-z]+:\/\//i.test(file))
            return file.split("/").pop().replace(/\.[^.]+$/, "")
        if (track?.external === true) return Translation.tr("English")
        const title = String(track?.title ?? "").trim()
        return title.length > 0 ? title : String(index + 1)
    }

    function selectSubtitle(id: int): void {
        mpv.selectSub(id)
    }

    function historyPath(id: string): string {
        if (id === "jerry") return root._dataHome + "/jerry/jerry_history.txt"
        if (id === "curd") return root._dataHome + "/curd/curd_history.txt"
        if (id === "ani-cli") {
            const custom = Quickshell.env("ANI_CLI_HIST_DIR")
            const dir = custom && custom.length > 0 ? custom : root._stateHome + "/ani-cli"
            return dir + "/ani-hsts"
        }
        return ""
    }

    function reload(): void {
        if (!root.enabled) {
            root.shows = []
            return
        }
        if (root.cli.length === 0) return
        historyFile.reload()
        progressFile.reload()
    }

    function refresh(): void {
        if (!root.enabled) {
            root.cli = ""
            root.shows = []
            root.detected = false
            root.progress = ({})
            root.error = ""
            return
        }
        root.detected = false
        detectProcess.running = false
        detectProcess.running = true
    }

    function resume(entry: var): void {
        if (root.cli.length === 0 || root._takeOver(() => root.resume(entry))) return
        const target = entry ?? root.current
        if (!target) return
        if (root.cli !== "ani-cli") {
            root._resumeCli(root.cli)
            return
        }
        const episode = root.stateOf(target).episode
        if (episode.length === 0) return
        const meta = root._nextMeta
        root._retry = () => { root._nextMeta = meta; root.resume(target) }
        root.session = { key: root.progressKey(target), title: String(target.title ?? ""), episode: episode }
        root._start(["-e", episode, String(target.title)], String(target.title))
        root.phase = "launching"
        mpv.begin(root.runDir + "/mpv.sock", root.runDir + "/reject")
    }

    function search(text: string): void {
        const wanted = String(text ?? "").trim()
        if (wanted.length === 0 || root.cli !== "ani-cli") return
        const meta0 = root._nextMeta, show0 = root.watchShow
        if (root._takeOver(() => { root._nextMeta = meta0; root.watchShow = show0; root.search(text) })) return
        const meta = root._nextMeta
        root._retry = () => { root._nextMeta = meta; root.search(wanted) }
        root.query = wanted
        root.wantedEpisode = ""
        root.session = null
        root._start([wanted], "")
        root.phase = "searching"
    }

    function choose(value: string): void {
        if (!root.pick || !root.running) return
        const action = root.betweenEpisodes ? String(value) : ""
        // With the episode given (-e), picking the show is what plays it; a source is always the last question.
        const plays = root.pickingEpisode || root.pickingQuality || root.pickingSource || (root.pickingShow && root._episodeGiven)
            || action === "next" || action === "replay" || action === "previous"
        root.pick = null
        ShellExec.writeFileViaShell(root.runDir + "/response", String(value) + "\n")
        if (plays) {
            root.phase = "launching"
            // A wait already on this run's socket keeps going: restarting it in the same tick kills it for good.
            if (!mpv.running || mpv.path !== root.runDir + "/mpv.sock") mpv.begin(root.runDir + "/mpv.sock", root.runDir + "/reject")
        }
    }

    // From the Island while an episode plays: close it (its place is saved) and
    // answer ani-cli's next question with the direction, keeping the series resolved.
    function skip(action: string): void {
        if (action !== "next" && action !== "previous") return
        if (root.betweenEpisodes) {
            root.choose(action)
            return
        }
        if (root.phase !== "playing" || !mpv.connected) return
        root._autoAnswer = action
        mpv.quit()
    }

    function cancel(): void {
        if (!root.running) return
        root._cancelled = true
        if (root.choosing) {
            root.pick = null
            ShellExec.writeFileViaShell(root.runDir + "/response", "")
        } else if (root._pid > 0) {
            ShellExec.execDetachedArgs(["kill", String(root._pid)], "Stop anime run")
        }
    }

    // Everything a row or the bubble needs about one show, resolved once: the episode
    // that would actually play, where it would start, and how far in that leaves it.
    function stateOf(entry: var): var {
        const empty = { episode: "", start: 0, progress: 0 }
        const episode = String(entry?.episode ?? "").trim()
        if (episode.length === 0) return empty
        const series = root.progress?.[root.progressKey(entry)] ?? ({})
        let target = episode
        let saved = series[episode]
        if (saved && root._finished(saved)) {
            const value = Number(episode)
            if (isFinite(value)) {
                target = String(value + 1)
                saved = series[target]
            }
        }
        const seconds = saved && !root._finished(saved) ? (Number(saved.seconds) || 0) : 0
        const duration = saved ? (Number(saved.duration) || 0) : 0
        return {
            episode: target,
            start: seconds,
            progress: duration > 0 ? Math.max(0, Math.min(1, seconds / duration)) : 0
        }
    }

    // The history entry of a show known by these titles (AniList's romaji, English, native), or null.
    function entryFor(titles: var): var {
        const keys = (titles ?? []).map(title => root.progressKey({ title: title })).filter(key => key.length > 0)
        return keys.length > 0 ? (root.shows.find(entry => keys.includes(root.progressKey(entry))) ?? null) : null
    }

    // One episode of a show as the Anime Corner's grid shows it: seen, how far in, never started.
    function episodeState(entry: var, episode: string): var {
        const saved = entry ? (root.progress?.[root.progressKey(entry)]?.[String(episode)] ?? null) : null
        const duration = Number(saved?.duration) || 0
        return { seen: saved !== null && root._finished(saved),
            progress: saved && duration > 0 ? Math.max(0, Math.min(1, (Number(saved.seconds) || 0) / duration)) : 0 }
    }

    // A chosen episode, from the Anime Corner. A show in the history is played under its history title, checked like
    // a resume; any other goes through ani-cli's own search (its menu here picks the show), so nothing is expected.
    function play(entry: var, title: string, episode: string): void {
        const name = String(entry?.title ?? title ?? "").trim()
        const wanted = String(episode ?? "").trim()
        if (!root.canTarget || name.length === 0 || wanted.length === 0) return
        const meta0 = root._nextMeta, show0 = root.watchShow
        if (root._takeOver(() => { root._nextMeta = meta0; root.watchShow = show0; root.play(entry, title, episode) })) return
        const meta = root._nextMeta
        root._retry = () => { root._nextMeta = meta; root.play(entry, title, episode) }
        root.query = name
        root.wantedEpisode = wanted
        root.session = entry ? { key: root.progressKey(entry), title: name, episode: wanted } : null
        root._start(["-e", wanted, name], entry ? name : "")
        root._episodeGiven = true
        root.phase = entry ? "launching" : "searching"
        // A search with one result plays at once, unasked: listen from the start (choose() listens again after a pick).
        mpv.begin(root.runDir + "/mpv.sock", root.runDir + "/reject")
    }

    function targetEpisodeOf(entry: var): string {
        return root.stateOf(entry).episode
    }

    function targetStartOf(entry: var): double {
        return root.stateOf(entry).start
    }

    function _finished(saved: var): bool {
        const duration = Number(saved?.duration) || 0
        return duration > 0 && (Number(saved?.seconds) || 0) / duration > root.finishedRatio
    }

    function _start(args: var, expect: string): void {
        const token = String(Date.now())
        root.runDir = root._runsHome + "/" + token
        root.error = ""
        root.pick = null
        root._pid = 0
        root._cancelled = false
        root._autoAnswer = ""
        root._episodeGiven = false
        // One argument each, "=" joined: an empty value (a dub has no subtitles) must not vanish on the way.
        const flags = ["--audio=" + root.audio, "--subs=" + root.subs, "--source=" + root.source]
        if (root.skipIntro && root.hasAniSkip) flags.push("--skip")
        if (root.quality !== "best") flags.push("-q", root.quality)
        const meta = root._nextMeta ? JSON.stringify(root._nextMeta) : ""
        // The run plays one show: its AniList and MAL ids mark the list when an episode of it ends.
        root._runIds = root._nextMeta ? { anilistId: root._nextMeta.anilistId, malId: root._nextMeta.malId } : null
        root._nextMeta = null
        // Link the engine as the run's ani-cli before inir-ani starts, then run inir-ani unchanged.
        ShellExec.execDetachedArgs([
            "/usr/bin/env",
            "INIR_ANI_EXPECT=" + expect,
            "INIR_ANI_PROGRESS=" + root.progressPath,
            "INIR_ANI_FINISHED=" + String(root.finishedRatio),
            "INIR_ANIME_META=" + meta,
            "/bin/sh", "-c", 'mkdir -p -- "$3/bin" && ln -sf -- "$1" "$3/bin/ani-cli" && shift && exec "$@"',
            "sh", root.engine,
            root.launcher, root.runDir,
            ...flags, ...args
        ], "Anime: " + args.join(" "))
    }

    function _resumeCli(id: string): void {
        const command = ["/usr/bin/bash", "-lc", id + " -c"]
        const terminal = root._terminal()
        if (terminal === "wezterm")
            ShellExec.execDetachedArgs([terminal, "start", "--always-new-process", "--", ...command], "Resume anime")
        else
            ShellExec.execDetachedArgs([terminal, "-e", ...command], "Resume anime")
    }

    // ani-cli exited: the run is over whatever phase it was in. Its last complaint is
    // the reason, unless the person cancelled or it simply finished.
    function _ended(text: string): void {
        if (!root.running) return
        const lines = String(text ?? "").split("\n")
        const status = Number(lines[0])
        const said = String(lines[1] ?? "").trim()
        const finished = root.session
        const run = root.runDir
        const asked = root.query
        root.runDir = ""
        root.pick = null
        root.query = ""
        // A player can outlive a launcher that was killed; it keeps being observed
        // and saves its place when it closes.
        if (root.phase !== "playing") {
            mpv.stop()
            root.session = null
            root.phase = "idle"
        }
        root._pid = 0
        if (status !== 0 && !root._cancelled && root.error.length === 0)
            root.error = root._explain(said, finished, asked)
        root._cancelled = false
        root._autoAnswer = ""
        if (run.indexOf(root._runsHome + "/") === 0)
            ShellExec.execDetachedArgs(["rm", "-rf", "--", run], "Clean anime run")
        const next = root._queued
        root._queued = null
        if (next) Qt.callLater(next)
    }

    function _explain(said: string, session: var, asked: string): string {
        const episode = session ? String(session.episode) : ""
        if (said.indexOf("No sources yet") >= 0) return Translation.tr("No sources yet: add one in the Corner's Settings › Sources")
        if (said.indexOf("No results found") >= 0) return Translation.tr("Nothing found for “%1”").arg(asked)
        if (said.indexOf("Invalid anime selection") >= 0 && session)
            return Translation.tr("Could not find %1 again").arg(session.title)
        if (said.indexOf("Invalid episode") >= 0 || said.indexOf("not released") >= 0)
            return episode.length > 0 ? Translation.tr("Episode %1 is not out yet").arg(episode) : Translation.tr("That episode is not out yet")
        if (said.indexOf("Out of range") >= 0) return Translation.tr("No more episodes")
        if (said.indexOf("No sources found for dub") >= 0) return Translation.tr("No dub for this one; try subtitles")
        if (said.indexOf("No sources found") >= 0 || said.indexOf("no valid sources") >= 0) return Translation.tr("No stream found for this episode")
        if (said.indexOf("cloudflare") >= 0) return Translation.tr("The anime site is blocking requests right now")
        if (said.indexOf("Request failed") >= 0 || said.indexOf("Could not resolve") >= 0) return Translation.tr("The anime site did not answer")
        return said.length > 0 ? said : Translation.tr("ani-cli stopped")
    }

    function _persist(): void {
        const finished = root.session
        root.session = null
        root.phase = root.running ? "between" : "idle"
        root._record(finished)
    }

    // The position is written while the episode runs, not only when it ends: a
    // shell reload or a killed player would otherwise lose the whole point.
    function _record(entry: var): void {
        if (!entry) return
        const position = Math.max(0, Number(mpv.position) || 0)
        const duration = Math.max(0, Number(mpv.duration) || 0)
        if (position <= 0 && duration <= 0) return
        const all = Object.assign({}, root.progress ?? ({}))
        const series = Object.assign({}, all[entry.key] ?? ({}))
        const done = root._finished(series[entry.episode])
        series[entry.episode] = { episode: entry.episode, seconds: position, duration: duration, at: Date.now() }
        if (!done && root._finished(series[entry.episode]) && root._runIds) CornerAccounts.episodeDone(root._runIds, String(entry.episode))
        all[entry.key] = series
        root.progress = all
        progressFile.setText(JSON.stringify(all))
    }

    function _reject(found: string): void {
        root.session = null
        root.phase = root.running ? "between" : "idle"
        root._autoAnswer = "quit"
        const resolved = String(found ?? "").trim()
        root.error = Translation.tr("Refused · %1").arg(resolved.length > 0 ? resolved : "?")
    }

    function clock(seconds: real): string {
        const total = Math.max(0, Math.floor(Number(seconds) || 0))
        const hours = Math.floor(total / 3600)
        const minutes = Math.floor((total % 3600) / 60)
        const rest = total % 60
        if (hours > 0)
            return hours + ":" + String(minutes).padStart(2, "0") + ":" + String(rest).padStart(2, "0")
        return minutes + ":" + String(rest).padStart(2, "0")
    }

    function _terminal(): string {
        const configured = String(Config.options?.apps?.terminal ?? "kitty").trim()
        if (configured.length === 0) return "kitty"
        if (!/^[A-Za-z0-9._+-]+$/.test(configured)) return "kitty"
        return configured
    }

    function _parseProgress(text: string): void {
        let data = null
        try {
            data = JSON.parse(String(text ?? ""))
        } catch (error) {
            data = null
        }
        root.progress = (data && typeof data === "object") ? data : ({})
    }

    MpvIpc {
        id: mpv
        onStarted: {
            if (root.phase !== "idle") root.phase = "playing"
            root._applySubtitleLook()
            claimTimer.tries = 0
            claimTimer.restart()
        }
        onMediaTitleChanged: if (!root.session) root._adopt()
        onClosed: root._persist()
        onRejected: (expected, found) => root._reject(found)
    }

    // A player that outlived a shell reload, or the next episode of a search run,
    // says which show it is through the title the wrapper set: "<show> Episode <n>".
    function _adopt(): void {
        const title = String(mpv.mediaTitle ?? "").trim()
        const match = title.match(/^(.*?)\s+Episode\s+([0-9.]+)\s*$/i)
        if (!match) return
        root.session = { key: root.progressKey({ title: match[1] }), title: match[1], episode: match[2] }
    }

    // A run still going after the shell reloaded: its directory has no `exit` and its
    // launcher is alive. Dead runs are swept. Prints "<dir>\t<1 if mpv listens>".
    Process {
        id: findRunProcess
        running: false
        command: ["/usr/bin/python3", "-c",
            "import os, shutil, socket, sys\n"
            + "base = sys.argv[1]\n"
            + "found = ''\n"
            + "for name in sorted(os.listdir(base) if os.path.isdir(base) else [], reverse=True):\n"
            + "    run = os.path.join(base, name)\n"
            + "    try:\n"
            + "        alive = not os.path.exists(os.path.join(run, 'exit')) and os.path.exists('/proc/' + open(os.path.join(run, 'pid')).read().strip())\n"
            + "    except OSError:\n"
            + "        alive = False\n"
            + "    if alive and not found:\n"
            + "        found = run\n"
            + "    elif not alive:\n"
            + "        shutil.rmtree(run, ignore_errors=True)\n"
            + "if found:\n"
            + "    listening = '0'\n"
            + "    try:\n"
            + "        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)\n"
            + "        client.settimeout(1)\n"
            + "        client.connect(os.path.join(found, 'mpv.sock'))\n"
            + "        client.close()\n"
            + "        listening = '1'\n"
            + "    except OSError:\n"
            + "        pass\n"
            + "    sys.stdout.write(found + '\\t' + listening)\n",
            root._runsHome]
        stdout: StdioCollector {
            id: findRunCollector
            onStreamFinished: {
                const fields = findRunCollector.text.trim().split("\t")
                if (fields[0].length === 0 || root.busy) return
                root.runDir = fields[0]
                if (fields[1] === "1") {
                    root.phase = "launching"
                    mpv.begin(root.runDir + "/mpv.sock", root.runDir + "/reject")
                } else {
                    root.phase = "between"
                }
            }
        }
    }

    // Starting an episode is asking to watch it: its player becomes the one the
    // Island and the media card follow, once MPRIS has registered it.
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
        running: root.error.length > 0 && !root.busy && !root.holdError
        interval: 30000
        onTriggered: root.error = ""
    }

    Timer {
        running: root.phase === "playing" && root.session !== null
        interval: 20000
        repeat: true
        onTriggered: root._record(root.session)
    }

    // Keys and accounts live in the system keyring through the shell's KeyringStorage (where the AI keys live),
    // never in config.json, never on a command line. Nothing is written before the keyring has been read: a write
    // replaces the whole entry, and a write before the read would drop every other key in it.
    readonly property bool keysReady: KeyringStorage.loaded
    readonly property var _keys: KeyringStorage.keyringData?.animeCorner ?? ({})
    readonly property var keyNames: ["opensubtitles", "subdl", "anilist", "mal"]
    property var _pendingKeys: ({})
    function loadKeys(): void { if (!KeyringStorage.loaded) KeyringStorage.fetchKeyringData() }
    function keyOf(service: string): string { return String(root._keys?.[service] ?? "") }
    function hasKey(service: string): bool { return root.keyOf(service).length > 0 }
    function setKey(service: string, value: string): void {
        if (!root.keyNames.includes(service)) return
        const clean = String(value ?? "").trim()
        if (!KeyringStorage.loaded) {
            const pending = Object.assign({}, root._pendingKeys)
            pending[service] = clean
            root._pendingKeys = pending
            KeyringStorage.fetchKeyringData()
            return
        }
        if (root.keyOf(service) !== clean) KeyringStorage.setNestedField(["animeCorner", service], clean)
    }
    Connections {
        target: KeyringStorage
        function onLoadedChanged(): void {
            if (!KeyringStorage.loaded) return
            const pending = root._pendingKeys
            root._pendingKeys = ({})
            for (const service of Object.keys(pending)) root.setKey(service, pending[service])
        }
    }

    // Subtitles for the episode that is playing, from OpenSubtitles and SubDL, in the person's languages.
    property var subtitleResults: []
    property var subtitleNotes: []
    property bool subtitleSearching: false
    property string subtitleFetching: ""
    readonly property var subtitleLanguages: {
        const shell = String(Translation.loadedLanguageCode || "en_US")
        const own = shell === "pt_BR" ? "pt-BR" : shell.split("_")[0]
        return [root.subs, own, "en"].filter((code, at, all) => code.length > 0 && all.indexOf(code) === at)
    }
    function findSubtitles(): void {
        if (!root.session || root.subtitleSearching) return
        root.loadKeys()
        root.subtitleResults = []
        root.subtitleNotes = []
        root.subtitleSearching = true
        subsSearch.environment = ({ INIR_OPENSUBTITLES_KEY: root.keyOf("opensubtitles"), INIR_SUBDL_KEY: root.keyOf("subdl") })
        subsSearch.command = ["python3", root.engine, "subs", "search", String(root.session.title), "0",
            String(root.session.episode), root.subtitleLanguages.join(",")]
        subsSearch.running = true
    }
    function fetchSubtitle(item: var): void {
        if (!root.running || root.subtitleFetching.length > 0 || !item) return
        root.subtitleFetching = String(item.id)
        subsGet.environment = ({ INIR_OPENSUBTITLES_KEY: root.keyOf("opensubtitles"), INIR_SUBDL_KEY: root.keyOf("subdl") })
        subsGet.command = ["python3", root.engine, "subs", "get", String(item.service), String(item.id), root.runDir + "/subs"]
        subsGet.running = true
    }
    readonly property var _services: ({ opensubtitles: "OpenSubtitles", subdl: "SubDL" })
    // The engine's notes are English and short; these are the ones a person reads.
    function subtitleNote(note: string): string {
        const text = String(note ?? "")
        let found = text.match(/^no key for (\w+)$/)
        if (found) return Translation.tr("Add your %1 key in the Corner's Settings to search it too").arg(root._services[found[1]] ?? found[1])
        found = text.match(/^(\w+) refused the key$/)
        if (found) return Translation.tr("%1 refused the key: check it in the Corner's Settings").arg(root._services[found[1]] ?? found[1])
        found = text.match(/^(\w+) did not answer$/)
        if (found) return Translation.tr("%1 did not answer").arg(root._services[found[1]] ?? found[1])
        if (/no download left today/.test(text)) return Translation.tr("No downloads left today on OpenSubtitles")
        return text
    }

    Process {
        id: subsSearch
        stdout: StdioCollector {
            id: subsSearchOut
            onStreamFinished: {
                try {
                    const found = JSON.parse(subsSearchOut.text)
                    root.subtitleResults = Array.from(found.results ?? []).filter(r => r && typeof r === "object")
                    root.subtitleNotes = Array.from(found.notes ?? []).map(n => String(n))
                } catch (e) {
                    root.subtitleNotes = [Translation.tr("The subtitle search failed")]
                }
            }
        }
        onExited: root.subtitleSearching = false
    }

    Process {
        id: subsGet
        stdout: StdioCollector {
            id: subsGetOut
            onStreamFinished: {
                const path = subsGetOut.text.trim()
                if (path.startsWith(root.runDir + "/subs/")) root.addSubtitle(path)
            }
        }
        stderr: StdioCollector {
            id: subsGetErr
            onStreamFinished: if (subsGetErr.text.trim().length > 0) root.subtitleNotes = [subsGetErr.text.trim()]
        }
        onExited: root.subtitleFetching = ""
    }

    // The Corner's Settings › Check the sources: every site tried live, the verdict as a notification.
    property bool checkingSources: false
    function checkSources(): void {
        if (root.checkingSources) return
        root.checkingSources = true
        Notifications.send(Translation.tr("Checking anime sources"), Translation.tr("Every site is tried on one show; this takes about half a minute."), "low", 6000)
        doctorProcess.running = true
    }

    Process {
        id: doctorProcess
        command: ["python3", root.engine, "doctor"]
        stdout: StdioCollector {
            id: doctorCollector
            onStreamFinished: {
                const rows = doctorCollector.text.trim().split("\n").filter(line => line.trim().length > 0)
                if (rows.length === 1 && rows[0].indexOf("No sources yet") === 0) {
                    Notifications.send(Translation.tr("No anime sources yet"), Translation.tr("Add a source file or a Stremio add-on in the Corner's Settings › Sources."), "normal", 10000)
                    return
                }
                const ok = rows.filter(line => / OK /.test(line)).length
                Notifications.send(Translation.tr("Anime sources: %1 of %2 play").arg(ok).arg(rows.length),
                    rows.map(line => line.replace(/\s+[\d.]+s\s+/, "  ")).join("\n"), ok === rows.length ? "low" : "normal", 20000)
            }
        }
        onExited: root.checkingSources = false
    }

    // The person's sources, as the engine loads them: files in the sources folder and the Stremio add-ons saved here.
    // The Corner ships none; until one is added, only the official links in a show's page play anything.
    property var sources: []
    property var sourceErrors: []
    property string sourcesFolder: ""
    property bool sourcesKnown: false
    readonly property bool hasSources: root.sources.length > 0
    function loadSources(): void {
        if (sourcesProcess.running) root._reloadSources = true
        else sourcesProcess.running = true
    }
    property bool _reloadSources: false
    Connections {
        target: CornerState
        function onOpenChanged(): void { if (CornerState.open) root.loadSources() }
    }
    Process {
        id: sourcesProcess
        command: ["python3", root.engine, "sources"]
        stdout: StdioCollector {
            id: sourcesOut
            onStreamFinished: {
                try {
                    const found = JSON.parse(sourcesOut.text)
                    root.sources = Array.from(found.sources ?? []).filter(s => s && typeof s.id === "string")
                    root.sourceErrors = Array.from(found.files ?? []).filter(f => f && String(f.error ?? "").length > 0)
                    root.sourcesFolder = String(found.folder ?? "")
                } catch (e) {
                    root.sources = []
                }
                root.sourcesKnown = true
            }
        }
        onExited: if (root._reloadSources) { root._reloadSources = false; sourcesProcess.running = true }
    }
    function openSourcesFolder(): void {
        if (root.sourcesFolder.length === 0) return
        ShellExec.execDetachedArgs(["sh", "-c", 'mkdir -p -- "$1" && exec xdg-open "$1"', "sh", root.sourcesFolder], "Open anime sources folder")
    }

    // Stremio add-ons: the engine reads the manifest first, then the Corner keeps it in its file. An add-on plays in
    // the Watch language set when it was added.
    readonly property var addons: {
        try {
            const listed = JSON.parse(String(CornerState.options.addons || "[]"))
            return Array.isArray(listed) ? listed.filter(a => a && typeof a.url === "string") : []
        } catch (e) {
            return []
        }
    }
    property string addonNote: ""
    readonly property bool addonChecking: addonProcess.running
    function addAddon(url: string): void {
        const address = String(url ?? "").trim()
        if (address.length === 0 || addonProcess.running) return
        root.addonNote = ""
        addonProcess.command = ["python3", root.engine, "addon", address]
        addonProcess.running = true
    }
    function _addonError(said: string): string {
        if (said.indexOf("Not an add-on address") === 0) return Translation.tr("That is not an add-on address: it starts with https:// and ends in /manifest.json")
        if (said.indexOf("It doesn't answer") === 0) return Translation.tr("The add-on does not answer")
        if (said.indexOf("It sends no add-on manifest") === 0) return Translation.tr("That address is not a Stremio add-on")
        if (said.indexOf("It lists no streams") === 0) return Translation.tr("That add-on has no streams")
        if (said.indexOf("It doesn't find anime") === 0) return Translation.tr("That add-on does not find anime (it needs Kitsu ids)")
        return Translation.tr("The add-on could not be checked")
    }
    function removeAddon(url: string): void {
        CornerState.set("addons", JSON.stringify(root.addons.filter(a => a.url !== url)))
        root.loadSources()
    }
    Process {
        id: addonProcess
        stdout: StdioCollector {
            id: addonOut
            onStreamFinished: {
                let reply = null
                try { reply = JSON.parse(addonOut.text) } catch (e) { reply = null }
                if (!reply || !reply.ok) {
                    root.addonNote = root._addonError(String(reply?.error ?? ""))
                    return
                }
                if (root.addons.some(a => a.url === reply.url)) {
                    root.addonNote = Translation.tr("%1 is already added").arg(reply.name || reply.url)
                    return
                }
                CornerState.set("addons", JSON.stringify(root.addons.concat([{ url: String(reply.url), name: String(reply.name ?? ""),
                    types: Array.from(reply.types ?? []), audio: root.audio, subs: root.subs }])))
                root.addonNote = Translation.tr("Added %1").arg(reply.name || reply.url)
                root.loadSources()
            }
        }
    }

    Process {
        id: detectProcess
        command: ["/usr/bin/bash", "-c",
            'command -v ani-skip >/dev/null 2>&1 && printf "skip "; command -v python3 >/dev/null 2>&1 && { printf ani-cli; exit 0; }; for c in ani-cli jerry curd; do command -v "$c" >/dev/null 2>&1 && { printf %s "$c"; exit 0; }; done']
        stdout: StdioCollector {
            id: detectCollector
            onStreamFinished: {
                const found = detectCollector.text.trim().split(" ")
                root.hasAniSkip = found[0] === "skip"
                root.cli = found[found.length - 1] === "skip" ? "" : found[found.length - 1]
                root.detected = true
                root.reload()
                if (root.cli === "ani-cli" && !root.busy) findRunProcess.running = true
            }
        }
    }

    FileView {
        id: historyFile
        path: root.enabled && root.cli.length > 0 ? Qt.resolvedUrl(root.historyPath(root.cli)) : ""
        watchChanges: true
        printErrors: false
        onFileChanged: historyDebounce.restart()
        onLoaded: root._parse(historyFile.text())
        onLoadFailed: root.shows = []
    }

    // An episode ending rewrites the history and the position together.
    Timer {
        id: historyDebounce
        interval: 400
        repeat: false
        onTriggered: root.reload()
    }

    // The run's files are replaced, not rewritten, and appear after the watch would
    // start, so they are polled, and only while a run is alive.
    Timer {
        running: root.running
        interval: 400
        repeat: true
        onTriggered: {
            if (!root.choosing) requestFile.reload()
            exitFile.reload()
            if (root._pid === 0) pidFile.reload()
        }
    }

    // A launcher killed outright writes no `exit`; its process going away is the end.
    Timer {
        running: root.running && root._pid > 0
        interval: 2000
        repeat: true
        onTriggered: processFile.reload()
    }

    FileView {
        id: requestFile
        path: root.running ? Qt.resolvedUrl(root.runDir + "/request.json") : ""
        printErrors: false
        onLoaded: {
            let data = null
            try {
                data = JSON.parse(requestFile.text())
            } catch (error) {
                data = null
            }
            const asked = (data && Array.isArray(data.items) && data.items.length > 0) ? data : null
            if (!asked) return
            root.pick = asked
            if (root.betweenEpisodes && root.phase !== "between") root.phase = "between"
            if (root.betweenEpisodes && root._autoAnswer.length > 0) {
                const answer = root._autoAnswer
                root._autoAnswer = ""
                root.choose(answer)
            }
        }
        onLoadFailed: root.pick = null
    }

    FileView {
        id: exitFile
        path: root.running ? Qt.resolvedUrl(root.runDir + "/exit") : ""
        printErrors: false
        onLoaded: root._ended(exitFile.text())
    }

    FileView {
        id: pidFile
        path: root.running ? Qt.resolvedUrl(root.runDir + "/pid") : ""
        printErrors: false
        onLoaded: root._pid = Number(pidFile.text().trim()) || 0
    }

    FileView {
        id: processFile
        path: root._pid > 0 ? "/proc/" + root._pid + "/stat" : ""
        printErrors: false
        onLoadFailed: if (root.running) root._ended("137\n")
    }

    FileView {
        id: coversFile
        property bool loaded: false
        path: root.enabled ? Qt.resolvedUrl(root.coversPath) : ""
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(coversFile.text())
                root.covers = (data && typeof data === "object") ? data : ({})
            } catch (error) {
                root.covers = ({})
            }
            coversFile.loaded = true
            root.showsChanged()
        }
        onLoadFailed: {
            coversFile.loaded = true
            root.showsChanged()
        }
    }

    FileView {
        id: progressFile
        path: root.enabled ? Qt.resolvedUrl(root.progressPath) : ""
        watchChanges: true
        printErrors: false
        onLoaded: root._parseProgress(progressFile.text())
        onLoadFailed: root.progress = ({})
    }

    Connections {
        target: Config
        function onRevisionChanged(): void {
            if (root.enabled && !root.detected) root.refresh()
        }
    }

    Component.onCompleted: {
        if (root.enabled) root.refresh()
    }

    // The provider slug is not stable: searching the same show can resolve it to a
    // different id, which would orphan its saved position. The title is what both
    // the history and the player agree on. scripts/inir-mpv derives the same key.
    function progressKey(entry: var): string {
        return String(entry?.title ?? "").toLowerCase().replace(/[^a-z0-9]+/g, " ").trim()
    }

    function _parse(text: string): void {
        const entries = []
        for (const raw of String(text ?? "").split("\n")) {
            const line = raw.replace(/\r$/, "")
            if (line.length === 0) continue
            const entry = root.cli === "ani-cli" ? root._parseAniCli(line)
                : root.cli === "jerry" ? root._parseJerry(line)
                : root.cli === "curd" ? root._parseCurd(line) : null
            if (!entry || entry.title.length === 0) continue
            entries.push(entry)
        }
        entries.reverse()
        const seen = ({})
        const unique = []
        for (const entry of entries) {
            const key = root.progressKey(entry)
            if (key.length === 0 || seen[key]) continue
            seen[key] = true
            unique.push(entry)
        }
        root.shows = unique.slice(0, root.maxShows)
    }

    // ani-cli ~/.local/state/ani-cli/ani-hsts: episode<TAB>provider_id<TAB>title.
    function _parseAniCli(line: string): var {
        const fields = line.split("\t")
        if (fields.length < 3) return null
        return {
            id: fields[1].trim(), anilistId: 0,
            title: fields[2].trim(), episode: fields[0].trim(), total: ""
        }
    }

    // jerry ~/.local/share/jerry/jerry_history.txt: anilist_id<TAB>ep/total<TAB>stopped<TAB>title.
    function _parseJerry(line: string): var {
        const fields = line.split("\t")
        if (fields.length < 4) return null
        const progress = String(fields[1]).split("/")
        return {
            id: fields[0].trim(), anilistId: Number(fields[0]) || 0,
            title: fields[3].trim(), episode: String(progress[0] ?? "").trim(),
            total: String(progress[1] ?? "").trim()
        }
    }

    // curd ~/.local/share/curd/curd_history.txt, CSV written by Go's encoding/csv:
    // anilist_id,provider_id,episode,playback_time,duration,provider,title. Older
    // rows end at provider_id or drop provider, so the title is the last field.
    function _parseCurd(line: string): var {
        const fields = root._csv(line)
        if (fields.length < 5) return null
        let title = ""
        if (fields.length >= 7) title = fields[6]
        else if (fields.length === 6) title = fields[5]
        else if (isNaN(Number(fields[4]))) title = fields[4]
        return {
            id: String(fields[1] ?? ""), anilistId: Number(fields[0]) || 0,
            title: String(title).trim(), episode: String(fields[2]).trim(), total: ""
        }
    }

    function _csv(line: string): var {
        const fields = []
        let value = ""
        let quoted = false
        for (let i = 0; i < line.length; i++) {
            const ch = line[i]
            if (quoted) {
                if (ch === '"') {
                    if (line[i + 1] === '"') { value += '"'; i++ }
                    else quoted = false
                } else value += ch
            } else if (ch === '"') quoted = true
            else if (ch === ",") { fields.push(value); value = "" }
            else value += ch
        }
        fields.push(value)
        return fields
    }
}
