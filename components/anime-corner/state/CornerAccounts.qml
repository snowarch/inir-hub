pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.services

/**
 * CornerAccounts — AniList and MyAnimeList: your list in the Anime Corner, and the episode you finish marked there.
 *
 * Each person registers their own app (AniList and MAL both hand out a client id in a minute, no secret) and pastes
 * its id in the Corner's Settings; the ids are public and live in the Corner's options file. Tokens are secrets: they live in the
 * keyring next to the subtitle keys (CornerWatch.keyOf), reach the engine only through its environment and never
 * come back out, except MAL's, which the engine prints when a login or a refresh made new ones.
 * Without an account, a public list can be read by user name.
 */
Singleton {
    id: root

    readonly property string anilistClient: String(CornerState.options.anilistClientId ?? "").trim()
    readonly property string malClient: String(CornerState.options.malClientId ?? "").trim()
    readonly property string anilistUser: String(CornerState.options.anilistUser ?? "").trim()
    readonly property string malUser: String(CornerState.options.malUser ?? "").trim()
    readonly property bool syncProgress: CornerState.options.syncProgress
    readonly property bool anilist: CornerWatch.hasKey("anilist")
    readonly property bool mal: CornerWatch.hasKey("mal")
    // Where "My list" comes from, the first that is set: your AniList, your MAL, then a public one by name.
    readonly property string listSource: root.anilist ? "anilist" : root.mal ? "mal"
        : root.anilistUser.length > 0 ? "anilist-user" : root.malUser.length > 0 ? "mal-user" : ""
    readonly property bool hasList: root.listSource.length > 0

    // Who AniList says the token belongs to; asked once per connection, shown in Settings.
    property string anilistName: ""
    property string note: ""
    property bool working: false

    function _env(): var {
        return ({ INIR_ANILIST_TOKEN: CornerWatch.keyOf("anilist"), INIR_ANILIST_CLIENT: root.anilistClient,
            INIR_MAL_TOKEN: CornerWatch.keyOf("mal"), INIR_MAL_CLIENT: root.malClient })
    }
    // One line of the engine's JSON; null when it is not JSON (nothing it prints is ever run or shown as markup).
    function _line(text: string): var {
        try { const value = JSON.parse(String(text ?? "")); return value && typeof value === "object" ? value : null }
        catch (e) { return null }
    }
    // MAL hands out a new pair on every login and refresh: the old refresh token stops working, so it is kept at once.
    function _keepMal(tokens: var): void {
        if (tokens && typeof tokens.access === "string" && tokens.access.length > 0)
            CornerWatch.setKey("mal", JSON.stringify({ access: tokens.access, refresh: String(tokens.refresh ?? ""),
                expires: Number(tokens.expires ?? 0) }))
    }

    // AniList: the authorize page shows the token once the person allows iNiR; they paste it in Settings.
    function connectAnilist(): void {
        if (!/^\d+$/.test(root.anilistClient)) { root.note = Translation.tr("Paste your AniList client ID first"); return }
        Qt.openUrlExternally("https://anilist.co/api/v2/oauth/authorize?client_id=" + root.anilistClient + "&response_type=token")
    }
    // The pasted token is tried before it is kept: a wrong paste never lands in the keyring.
    function useAnilistToken(token: string): void {
        const clean = String(token ?? "").trim()
        if (clean.length < 20 || root.working) return
        CornerWatch.loadKeys()
        root.working = true
        root.note = Translation.tr("Checking the token…")
        viewer.pending = clean
        viewer.environment = ({ INIR_ANILIST_TOKEN: clean })
        viewer.running = true
    }
    function whoIsAnilist(): void {
        if (!root.anilist || viewer.running || root.anilistName.length > 0) return
        viewer.pending = ""
        viewer.environment = ({ INIR_ANILIST_TOKEN: CornerWatch.keyOf("anilist") })
        viewer.running = true
    }
    Process {
        id: viewer
        property string pending: ""
        command: ["python3", CornerWatch.engine, "account", "anilist-viewer"]
        stdout: StdioCollector {
            id: viewerOut
            onStreamFinished: {
                const reply = root._line(viewerOut.text.trim())
                if (reply && String(reply.name ?? "").length > 0) {
                    root.anilistName = String(reply.name)
                    if (viewer.pending.length > 0) {
                        CornerWatch.setKey("anilist", viewer.pending)
                        root.note = Translation.tr("Connected to AniList as %1").arg(root.anilistName)
                    }
                } else if (viewer.pending.length > 0) {
                    root.note = /HTTP 40[01]|[Ii]nvalid token|Unauthorized/.test(String(reply?.error ?? ""))
                        ? Translation.tr("AniList refused that token; copy it again from the page it showed")
                        : Translation.tr("Couldn't reach AniList; try again")
                } else if (/HTTP 40[01]|[Ii]nvalid token|Unauthorized/.test(String(reply?.error ?? ""))) {
                    root.note = Translation.tr("AniList refused the saved token; connect again")
                }
                viewer.pending = ""
            }
        }
        onExited: root.working = false
    }

    // MAL: the engine listens on 127.0.0.1 for the browser to come back; it prints the page to open first.
    function connectMal(): void {
        if (root.malClient.length < 8) { root.note = Translation.tr("Paste your MyAnimeList client ID first"); return }
        if (malLogin.running) return
        CornerWatch.loadKeys()
        root.working = true
        root.note = Translation.tr("Allow iNiR in the browser; this waits five minutes")
        malLogin.environment = ({ INIR_MAL_CLIENT: root.malClient })
        malLogin.running = true
    }
    function cancelMal(): void { malLogin.running = false }
    Process {
        id: malLogin
        command: ["python3", CornerWatch.engine, "account", "mal-login"]
        stdout: SplitParser {
            onRead: data => {
                const reply = root._line(data)
                if (!reply) return
                // Only MAL's own authorize page is opened, whatever the line says.
                if (typeof reply.open === "string" && reply.open.startsWith("https://myanimelist.net/v1/oauth2/authorize?"))
                    Qt.openUrlExternally(reply.open)
                else if (reply.tokens) {
                    root._keepMal(reply.tokens)
                    root.note = Translation.tr("Connected to MyAnimeList")
                } else if (reply.error)
                    root.note = /timed out/.test(reply.error) ? Translation.tr("The MyAnimeList login timed out")
                        : /Address already in use/.test(reply.error) ? Translation.tr("Another MyAnimeList login is still waiting")
                        : Translation.tr("MyAnimeList refused the login: %1").arg(String(reply.error))
            }
        }
        onExited: root.working = false
    }

    function disconnect(service: string): void {
        if (service !== "anilist" && service !== "mal") return
        CornerWatch.setKey(service, "")
        if (service === "anilist") root.anilistName = ""
        root.shows = []
        root.note = service === "anilist" ? Translation.tr("AniList disconnected") : Translation.tr("MyAnimeList disconnected")
    }

    // My list: every show on it, in the Corner's shape, the ones being watched first.
    property var shows: []
    property bool listLoading: false
    property string listError: ""
    property double _listAt: 0
    readonly property var statusOrder: ["CURRENT", "REPEATING", "PAUSED", "PLANNING", "COMPLETED", "DROPPED"]
    function loadList(force: bool): void {
        if (!root.hasList || listProcess.running) return
        if (!force && root.shows.length > 0 && Date.now() - root._listAt < 10 * 60 * 1000) return
        if ((root.listSource === "anilist" || root.listSource === "mal") && !CornerWatch.keysReady) {
            root._listWanted = true
            CornerWatch.loadKeys()
            return
        }
        const service = root.listSource.startsWith("mal") ? "mal" : "anilist"
        const user = root.listSource === "anilist-user" ? root.anilistUser : root.listSource === "mal-user" ? root.malUser : ""
        root.listLoading = true
        root.listError = ""
        listProcess.environment = root._env()
        listProcess.command = ["python3", CornerWatch.engine, "account", "list", service, ...(user.length > 0 ? [user] : [])]
        listProcess.running = true
    }
    property bool _listWanted: false
    Connections {
        target: CornerWatch
        function onKeysReadyChanged(): void { if (CornerWatch.keysReady && root._listWanted) { root._listWanted = false; root.loadList(true) } }
    }
    onListSourceChanged: { root.shows = []; root._listAt = 0 }
    Process {
        id: listProcess
        stdout: SplitParser {
            onRead: data => {
                const reply = root._line(data)
                if (!reply) return
                if (reply.tokens) root._keepMal(reply.tokens)
                else if (reply.error) root.listError = String(reply.error)
                else if (Array.isArray(reply.shows)) {
                    root.shows = reply.shows.filter(s => s && typeof s === "object").map(s => ({
                        id: Number(s.id ?? 0) || 0, idMal: Number(s.idMal ?? 0) || 0,
                        title: String(s.title ?? ""), titleRomaji: String(s.titleRomaji ?? ""), titleEnglish: String(s.titleEnglish ?? ""),
                        image: /^https:\/\//.test(String(s.image ?? "")) ? String(s.image) : "",
                        episodes: s.episodes, listStatus: String(s.listStatus ?? ""), seen: Number(s.progress ?? 0) || 0
                    })).sort((a, b) => root._rank(a.listStatus) - root._rank(b.listStatus))
                    root._listAt = Date.now()
                }
            }
        }
        onExited: root.listLoading = false
    }
    function _rank(status: string): int { const at = root.statusOrder.indexOf(status); return at < 0 ? 99 : at }
    function statusName(status: string): string {
        return ({ CURRENT: Translation.tr("Watching"), REPEATING: Translation.tr("Rewatching"), PAUSED: Translation.tr("Paused"),
            PLANNING: Translation.tr("Plan to watch"), COMPLETED: Translation.tr("Completed"), DROPPED: Translation.tr("Dropped") })[status] ?? ""
    }
    function listErrorText(): string {
        const error = root.listError
        if (/private|no such/.test(error)) return Translation.tr("That list is private, or the user doesn't exist")
        if (/ran out|not connected|refused/.test(error)) return Translation.tr("Your login ran out; connect again in the Corner's Settings")
        return Translation.tr("Couldn't read your list")
    }

    // An episode was watched to the end (CornerWatch): the list says so too. Only with a login, only forward, once.
    property var _sent: ({})
    property var _queue: []
    function episodeDone(ids: var, episode: string): void {
        const number = Number(episode)
        if (!root.syncProgress || !ids || !Number.isInteger(number) || number < 1) return
        const jobs = []
        if (root.anilist && Number(ids.anilistId) > 0) jobs.push(["anilist", String(ids.anilistId)])
        if (root.mal && Number(ids.malId) > 0) jobs.push(["mal", String(ids.malId)])
        for (const job of jobs) {
            const key = job.join(":") + ":" + number
            if (root._sent[key]) continue
            root._sent[key] = true
            // A show already further along on the list stays where it is.
            const listed = root.shows.find(s => (job[0] === "anilist" ? s.id : s.idMal) === Number(job[1]))
            if (listed && listed.seen >= number) continue
            root._queue = root._queue.concat([[...job, String(number)]])
        }
        root._next()
    }
    function _next(): void {
        if (progressProcess.running || root._queue.length === 0 || !CornerWatch.keysReady) return
        const job = root._queue[0]
        root._queue = root._queue.slice(1)
        progressProcess.job = job
        progressProcess.environment = root._env()
        progressProcess.command = ["python3", CornerWatch.engine, "account", "progress", ...job]
        progressProcess.running = true
    }
    Process {
        id: progressProcess
        property var job: []
        stdout: SplitParser {
            onRead: data => {
                const reply = root._line(data)
                if (reply?.tokens) root._keepMal(reply.tokens)
                else if (reply?.saved) {
                    const shown = root.shows.map(s => (progressProcess.job[0] === "anilist" ? s.id : s.idMal) === Number(progressProcess.job[1])
                        ? Object.assign({}, s, { seen: Number(progressProcess.job[2]), listStatus: s.listStatus === "PLANNING" ? "CURRENT" : s.listStatus }) : s)
                    root.shows = shown
                } else if (reply?.error)
                    Notifications.send(Translation.tr("Your anime list wasn't updated"),
                        progressProcess.job[0] === "anilist" ? "AniList: " + String(reply.error) : "MyAnimeList: " + String(reply.error), "low", 8000)
            }
        }
        onExited: Qt.callLater(root._next)
    }
}
