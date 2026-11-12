pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "radio.js" as R

// Radio Browser's directory: finding stations by name, place, genre and language, the lists to browse them by, and
// the random tune of the discovery button. A mirror that fails or stalls hands the request to the next.
Scope {
    id: root

    // A server that speaks the same API, for testing; empty is Radio Browser's mirrors.
    property string apiUrl: ""
    property int mirror: 0
    readonly property string base: root.apiUrl.length > 0 ? root.apiUrl.replace(/\/$/, "") : R.MIRRORS[root.mirror % R.MIRRORS.length]

    function get(path: string, done: var, tries: int): void {
        const xhr = new XMLHttpRequest()
        let settled = false
        const fail = () => {
            if (settled) return
            settled = true
            if (root.apiUrl.length === 0 && tries + 1 < R.MIRRORS.length) {
                root.mirror += 1
                root.get(path, done, tries + 1)
            } else done(false, null)
        }
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || settled) return
            let data = null
            try { data = JSON.parse(xhr.responseText) } catch (e) { data = null }
            if (xhr.status === 200 && data !== null) {
                settled = true
                done(true, data)
            } else fail()
        }
        // A mirror that takes the connection and never answers would hold the person on "Looking…" for minutes.
        stall.createObject(root, { xhr: xhr, give: fail })
        xhr.open("GET", `${root.base}${path}`)
        xhr.send()
    }
    Component {
        id: stall
        Timer {
            property var xhr
            property var give
            interval: 9000
            running: true
            onTriggered: {
                if (xhr.readyState !== XMLHttpRequest.DONE) {
                    xhr.abort()
                    give()
                }
                destroy()
            }
        }
    }

    // Stations of one list the tuner shows. `kind`: search (a name), country (a code), tag, language, popular,
    // trending, top. Every station, talk included: here the person chooses.
    function list(kind: string, value: string, done: var): void {
        const q = { hidebroken: true, limit: 120, order: "votes", reverse: true }
        if (kind === "search") { q.name = value; q.order = "clickcount" }
        else if (kind === "country") q.countrycode = value
        else if (kind === "tag") { q.tag = value; q.tagExact = true }
        else if (kind === "language") { q.language = value; q.languageExact = true }
        else if (kind === "popular") q.order = "clickcount"
        else if (kind === "trending") q.order = "clicktrend"
        root.get(`/json/stations/search?${R.query(q)}`, (ok, data) => {
            done(ok, ok ? R.unique((data ?? []).map(s => R.station(s, kind === "tag" ? value : ""))) : [])
        }, 0)
    }

    // The lists to browse by, read once a session: the directory changes slowly. Each entry: { key, name, count }.
    property var cache: ({})
    function index(kind: string, done: var): void {
        if (root.cache[kind]) { done(true, root.cache[kind]); return }
        const path = kind === "countries" ? "/json/countries?order=stationcount&reverse=true&hidebroken=true"
            : kind === "tags" ? "/json/tags?order=stationcount&reverse=true&hidebroken=true&limit=400"
            : "/json/languages?order=stationcount&reverse=true&hidebroken=true&limit=200"
        root.get(path, (ok, data) => {
            if (!ok) { done(false, []); return }
            const all = (data ?? []).map(e => ({
                key: String(kind === "countries" ? e.iso_3166_1 ?? "" : e.name ?? "").trim(),
                name: kind === "countries" ? R.country(e.name, e.iso_3166_1) : R.title(e.name),
                count: Number(e.stationcount ?? 0)
            })).filter(e => e.key.length > 0 && e.key.length <= 28 && e.count >= (kind === "tags" ? 25 : 3))
            const next = Object.assign({}, root.cache)
            next[kind] = all
            root.cache = next
            done(true, all)
        }, 0)
    }

    // The discovery tune: stations that play `tag` now, shuffled, music only, never one heard lately. Fewer than
    // five exact matches widen to the tag anywhere in a station's list. `away` is a country code left for last.
    function discover(tag: string, skip: var, away: string, done: var): void {
        const ask = exact => root.get(`/json/stations/search?${R.query({ tag: tag, tagExact: exact, hidebroken: true,
            order: "random", limit: 60, bitrateMin: 48 })}`, (ok, data) => {
            if (!ok) { done(false, []); return }
            const found = R.unique((data ?? []).filter(s => !R.spoken(s) && skip.indexOf(String(s.stationuuid)) < 0)
                .map(s => R.station(s, tag)))
            if (found.length < 5 && exact) { ask(false); return }
            // Somewhere else first, the person's own country after, a station that names no place last.
            const rank = s => s.code.length === 0 ? 2 : s.code === away ? 1 : 0
            done(true, found.map((s, i) => ({ s: s, i: i })).sort((a, b) => rank(a.s) - rank(b.s) || a.i - b.i).map(x => x.s).slice(0, 24))
        }, 0)
        ask(true)
    }

    // Radio Browser counts a play when a client asks for the station's address: its ranking depends on it.
    function counted(uuid: string): void {
        if (uuid.length > 0) root.get(`/json/url/${encodeURIComponent(uuid)}`, () => {}, 0)
    }
}
