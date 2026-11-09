pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import "radio.js" as R

// Finding stations in Radio Browser's directory: a tag, music only, working streams, never one heard lately; a
// mirror that fails hands the search to the next.
Scope {
    id: root

    // A server that speaks the same API, for testing; empty is Radio Browser's mirrors.
    property string apiUrl: ""
    property int mirror: 0
    readonly property string base: root.apiUrl.length > 0 ? root.apiUrl.replace(/\/$/, "") : R.MIRRORS[root.mirror % R.MIRRORS.length]

    function get(path: string, done: var, tries: int): void {
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            let data = null
            try { data = JSON.parse(xhr.responseText) } catch (e) { data = null }
            if (xhr.status === 200 && data !== null) {
                done(true, data)
            } else if (root.apiUrl.length === 0 && tries + 1 < R.MIRRORS.length) {
                root.mirror += 1
                root.get(path, done, tries + 1)
            } else done(false, null)
        }
        xhr.open("GET", `${root.base}${path}`)
        xhr.send()
    }

    // Stations that play `tag` now, shuffled by the directory. Fewer than five exact matches widen to the tag
    // anywhere in a station's list. `skip` holds uuids heard lately; `away` a country code to leave for last.
    function search(tag: string, skip: var, away: string, done: var): void {
        const ask = exact => root.get(`/json/stations/search?${R.query({ tag: tag, tagExact: exact, hidebroken: true,
            order: "random", limit: 60, bitrateMin: 48 })}`, (ok, data) => {
            if (!ok) { done(false, []); return }
            const seen = {}
            const found = (data ?? []).filter(s => {
                const url = String(s.url_resolved || s.url || "")
                const key = String(s.name ?? "").trim().toLowerCase()
                if (url.length === 0 || seen[key] || R.spoken(s) || skip.indexOf(String(s.stationuuid)) >= 0) return false
                seen[key] = true
                return true
            }).map(s => R.station(s, tag))
            if (found.length < 5 && exact) { ask(false); return }
            // Somewhere else first, the person's own country after, a station that names no place last: the
            // point is to hear a place.
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
