pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.services
import "subtitles.js" as Subtitles

// Optional direct OpenSubtitles provider. The key never appears in a URL or error.
Singleton {
    id: root
    property string token: ""
    property string baseUrl: "https://api.opensubtitles.com/api/v1/"
    property string loginError: ""
    property real lastLoginAt: 0
    readonly property bool authenticated: token.length > 0
    property var request: null
    property var callback: null
    property var cache: ({})
    property string cacheKey: ""
    function cancel(): void {
        timeout.stop()
        if (root.request) { const old = root.request; root.request = null; old.abort() }
        root.callback = null
    }
    function call(method: string, path: string, body: string, done: var): void {
        root.cancel()
        if (!CornerState.open || !CornerState.options.subtitleApiKey) { done(null, "unavailable"); return }
        const xhr = new XMLHttpRequest()
        root.request = xhr
        root.callback = done
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || root.request !== xhr) return
            timeout.stop()
            root.request = null
            const cb = root.callback
            root.callback = null
            let data = null, error = ""
            if (xhr.status >= 200 && xhr.status < 300) {
                try { data = JSON.parse(xhr.responseText) } catch (e) { error = "invalid" }
            } else error = Subtitles.statusError(xhr.status)
            cb(data, error)
        }
        try {
            xhr.open(method, root.baseUrl + path)
            xhr.setRequestHeader("Api-Key", CornerState.options.subtitleApiKey)
            if (root.token) xhr.setRequestHeader("Authorization", "Bearer " + root.token)
            xhr.setRequestHeader("User-Agent", "Media Corner v1.1.0")
            xhr.setRequestHeader("Accept", "application/json")
            if (body) xhr.setRequestHeader("Content-Type", "application/json")
            timeout.restart()
            xhr.send(body || null)
        } catch (e) {
            root.cancel()
            done(null, "network")
        }
    }
    function login(username: string, password: string): void {
        if (Date.now() - root.lastLoginAt < 1000) {
            root.loginError = Translation.tr("Wait before trying to sign in again")
            return
        }
        root.lastLoginAt = Date.now()
        root.token = ""
        root.baseUrl = "https://api.opensubtitles.com/api/v1/"
        root.loginError = ""
        root.call("POST", "login", JSON.stringify({username: username, password: password}), (body, error) => {
            const host = String(body?.base_url ?? "api.opensubtitles.com").replace(/^https?:\/\//, "").replace(/\/$/, "")
            if (!error && body?.token && (host === "api.opensubtitles.com" || host === "vip-api.opensubtitles.com")) {
                root.token = String(body.token)
                root.baseUrl = "https://" + host + "/api/v1/"
            } else root.loginError = Translation.tr("Could not sign in to OpenSubtitles")
        })
    }
    function search(imdb: string, language: string, episode: var, done: var): void {
        if (!/^tt\d+$/.test(imdb) || !/^[a-z]{2,3}$/.test(language)) { done([], "unavailable"); return }
        const codes = { eng: "en", spa: "es", por: "pt", fra: "fr", deu: "de", ita: "it", jpn: "ja" }
        language = codes[language] ?? language
        const season = Number(episode?.season ?? 0), number = Number(episode?.episode ?? 0)
        const extra = season > 0 && number > 0 ? "&season_number=" + Math.floor(season) + "&episode_number=" + Math.floor(number) : ""
        const key = imdb + ":" + language + extra
        const hit = root.cache[key]
        if (hit && Date.now() - hit.at < 600000) { done(hit.items, ""); return }
        root.call("GET", "subtitles?imdb_id=" + imdb.slice(2) + "&languages=" + language + extra, "", (body, error) => {
            const items = Subtitles.searchResults(body, language)
            if (!error) root.cache[key] = { at: Date.now(), items: items }
            done(items, error)
        })
    }
    function download(id: int, done: var): void {
        if (!root.authenticated) { done("", "login"); return }
        root.call("POST", "download", JSON.stringify({ file_id: id }), (body, error) => {
            const link = Subtitles.downloadLink(body)
            done(link, error || (link ? "" : "invalid"))
        })
    }
    Timer {
        id: timeout
        interval: 20000
        onTriggered: {
            const cb = root.callback
            root.cancel()
            if (cb) cb(null, "timeout")
        }
    }
    Connections { target: CornerState; function onOpenChanged(): void { if (!CornerState.open) { root.cancel(); root.token = ""; root.loginError = "" } } }
}
