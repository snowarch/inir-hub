pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common

// The Media Corner's own state, kept while the Corner is closed: where you are, the answers it already has, and the
// person's options. The options live in ~/.config/inir/plugins/media-corner.json, never in config.json, so removing
// it leaves the settings as they were.
Singleton {
    id: root

    property bool open: false
    // A place ("anime:top", "movie:genre:Drama"…), what the search field holds, and the titles opened over the page.
    property string place: "home"
    property string query: ""
    property var trail: []
    readonly property var show: root.trail.length > 0 ? root.trail[root.trail.length - 1] : null
    // Goes up to ask again what failed: back online, on Retry, on opening.
    property int attempt: 0
    property bool sheet: false
    property string migrationError: ""
    property string _pendingKey: ""
    function saveApiKey(value: string): void {
        if (!root.open || keyWriter.running) return
        root._pendingKey = value
        keyWriter.running = true
    }
    signal callersDropped()

    readonly property alias options: adapter
    function set(name: string, value: var): void {
        if (adapter[name] === value) return
        adapter[name] = value
    }

    function pick(wanted: string): void {
        root.sheet = false
        root.place = wanted
        // «See all» of a search opens that search whole: it keeps what was typed.
        if (!wanted.includes(":search")) root.query = ""
        root.trail = []
    }
    function search(text: string): void {
        if (text === root.query) return
        root.query = text
        root.trail = []
        if (root.place.includes(":search")) root.place = "home"
    }
    function openShow(title: var): void {
        if (title) root.trail = root.trail.concat([title])
    }
    // One step back: the title, the search, then from a genre to its list. False when there is nothing left to undo.
    function back(): bool {
        if (root.sheet) root.sheet = false
        else if (root.trail.length > 0) root.trail = root.trail.slice(0, -1)
        else if (root.query.length > 0) root.search("")
        else if (root.place.includes(":genre:")) root.place = root.place.replace(/:genre:.*$/, ":genres")
        else return false
        return true
    }
    // What IPC asks for: a place, "anime:<AniList id>" or "title:<movie|series>:<IMDb id>".
    function go(wanted: string): void {
        const title = wanted.match(/^title:(movie|series):(tt\d+)$/)
        const anime = wanted.match(/^anime:(\d+)$/)
        if (title) root.openShow({ id: title[2], kind: title[1] })
        else if (anime) root.openShow({ id: Number(anime[1]), kind: "anime" })
        else if (/^(home|sources|anime:(popular|airing|trending|top|season|genres|genre:.+)|movie:(movies|series|top|years|genres|genre:.+))$/.test(wanted)) root.pick(wanted)
    }

    // ── Asking the network. An answer is kept ten minutes, one question is out once, and one that never comes back
    // fails after 20 s. A failure is never kept. callback(value, error): error is "" , "busy" (429) or a short reason.
    readonly property int keepMs: 10 * 60 * 1000
    readonly property int waitMs: 20000
    property var _answers: ({})
    property var _out: ({})
    property int _outCount: 0

    function ask(url: string, body: string, shape: var, callback: var, force: bool = false): void {
        if (!root.open) return
        const key = url + body
        const hit = root._answers[key]
        if (!force && hit && Date.now() - hit.at < root.keepMs) { callback(hit.value, ""); return }
        const out = root._out[key]
        if (out) { out.callbacks.push(callback); return }

        const xhr = new XMLHttpRequest()
        const ticket = { key, xhr, at: Date.now(), callbacks: [callback], done: false }
        root._out[key] = ticket
        root._outCount++
        root.scheduleDeadline()
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || ticket.done) return
            let value = null, error = ""
            if (xhr.status === 200) {
                try { value = shape(JSON.parse(xhr.responseText)) } catch (e) { error = "bad reply" }
            } else error = xhr.status === 429 ? "busy" : "HTTP " + xhr.status
            if (!error) root._answers[key] = { at: Date.now(), value }
            root._settle(ticket, value, error)
        }
        xhr.open(body.length > 0 ? "POST" : "GET", url)
        if (body.length > 0) {
            xhr.setRequestHeader("Content-Type", "application/json")
            xhr.setRequestHeader("Accept", "application/json")
        }
        xhr.send(body)
    }
    function _settle(ticket: var, value: var, error: string): void {
        ticket.done = true
        delete root._out[ticket.key]
        root._outCount--
        root.scheduleDeadline()
        for (const callback of ticket.callbacks) callback(value, error)
    }
    // Abort outstanding requests when no page can use their answers.
    function dropCallers(): void {
        for (const key in root._out) {
            const ticket = root._out[key]
            ticket.done = true
            ticket.callbacks = []
            ticket.xhr.abort()
        }
        root._out = ({})
        root._outCount = 0
        deadline.stop()
        root.callersDropped()
    }
    // A single one-shot timer wakes only for the earliest outstanding deadline.
    function scheduleDeadline(): void {
        deadline.stop()
        let next = Infinity
        for (const key in root._out) next = Math.min(next, root._out[key].at + root.waitMs)
        if (next !== Infinity && root.open) {
            deadline.interval = Math.max(1, next - Date.now())
            deadline.start()
        }
    }
    Timer {
        id: deadline
        repeat: false
        onTriggered: {
            for (const key in root._out) {
                const ticket = root._out[key]
                if (Date.now() - ticket.at < root.waitMs) continue
                root._settle(ticket, null, "no answer")
                ticket.xhr.abort()
            }
            root.scheduleDeadline()
        }
    }

    onOpenChanged: {
        if (!root.open) { root.dropCallers(); migration.running = false; keyWriter.running = false; root._pendingKey = ""; return }
        if (String(adapter.sources).trim().startsWith("[")) migration.running = true
        for (const key in root._answers) {
            if (Date.now() - root._answers[key].at >= root.keepMs) delete root._answers[key]
        }
        root.attempt++
    }
    Connections {
        target: Network
        function onOnlineChanged(): void { if (Network.online && root.open) root.attempt++ }
    }

    Process {
        id: keyWriter
        stdinEnabled: true
        command: ["python3", decodeURIComponent(Qt.resolvedUrl("../scripts/save_key.py").toString().replace(/^file:\/\//, ""))]
        onStarted: { keyWriter.write(root._pendingKey + "\n"); keyWriter.stdinEnabled = false }
        onExited: code => {
            root._pendingKey = ""
            keyWriter.stdinEnabled = true
            if (code === 0) { root.migrationError = ""; file.reload() }
            else root.migrationError = Translation.tr("Could not save the API key; try again")
        }
    }
    Process {
        id: migration
        command: ["python3", decodeURIComponent(Qt.resolvedUrl("../scripts/migrate_sources.py").toString().replace(/^file:\/\//, ""))]
        onExited: code => {
            if (code === 0) { root.migrationError = ""; file.reload() }
            else root.migrationError = Translation.tr("Could not migrate sources; original settings were kept")
        }
    }
    FileView {
        id: file
        path: Directories.pluginFile("media-corner")
        watchChanges: true
        atomicWrites: false
        onLoaded: if (root.open && !migration.running && String(adapter.sources).trim().startsWith("[")) migration.running = true
        onFileChanged: file.reload()
        onAdapterUpdated: file.writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) file.writeAdapter() }
        JsonAdapter {
            id: adapter
            // Over the desktop or in a window of its own.
            property bool windowed: false
            property string sources: "[]"
            property string subtitleLanguage: "eng"
            property string subtitleApiKey: ""
        }
    }
}
