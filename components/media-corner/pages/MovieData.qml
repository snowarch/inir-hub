pragma ComponentBehavior: Bound
import QtQuick
import qs.services

// What the Media Corner asks Cinemeta (Stremio's open catalogue of films and series, by IMDb id): lists, searches and
// one title in full. It lives and dies with the Corner; each answer is kept ten minutes and asked once.
QtObject {
    id: root
    // Which catalogue it is, for the pages that take either.
    readonly property bool anime: false

    readonly property string base: "https://v3-cinemeta.strem.io"
    readonly property int cacheMs: 10 * 60 * 1000
    // Cinemeta's pages are this long; a shorter one is the last.
    readonly property int perPage: 50
    readonly property var genreNames: ["Action", "Adventure", "Animation", "Biography", "Comedy", "Crime", "Documentary", "Drama",
        "Family", "Fantasy", "History", "Horror", "Mystery", "Romance", "Sci-Fi", "Sport", "Thriller", "War", "Western"]

    property var _cache: ({})
    property var _waiting: ({})

    function _get(path: string, shape, callback): void {
        const hit = root._cache[path]
        if (hit && Date.now() - hit.at < root.cacheMs) { callback(hit.value, ""); return }
        // One question out at a time; one that never came back (20 s) is asked again.
        const out = root._waiting[path]
        if (out && Date.now() - out.at < 20000) { out.callbacks.push(callback); return }
        const ticket = { at: Date.now(), callbacks: [callback] }
        root._waiting[path] = ticket
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = () => {
            // The Corner closed while it was out: nothing is left to tell.
            if (xhr.readyState !== XMLHttpRequest.DONE || !root) return
            let value = null, error = ""
            if (xhr.status === 200) {
                try { value = shape(JSON.parse(xhr.responseText)) } catch (e) { error = "bad reply" }
            } else error = "HTTP " + xhr.status
            if (!error) root._cache[path] = { at: Date.now(), value }
            if (root._waiting[path] === ticket) delete root._waiting[path]
            for (const cb of ticket.callbacks) cb(value, error)
        }
        xhr.open("GET", root.base + path)
        xhr.send()
    }

    // Cinemeta's meta in the shape the pages read (the anime's, so posters and shelves are the same).
    function normalize(m: var): var {
        const poster = String(m.poster ?? "")
        const year = String(m.releaseInfo ?? m.year ?? "")
        return {
            id: String(m.imdb_id ?? m.id ?? ""), kind: m.type === "series" ? "series" : "movie",
            title: String(m.name ?? ""), image: poster.replace("/poster/small/", "/poster/medium/"), imageLarge: poster.replace("/poster/small/", "/poster/large/").replace("/poster/medium/", "/poster/large/"),
            banner: String(m.background ?? ""), logo: String(m.logo ?? ""),
            description: String(m.description ?? ""), year: year, score: Number(m.imdbRating ?? 0),
            genres: Array.from(m.genres ?? m.genre ?? []), type: m.type === "series" ? "Series" : "Movie",
            tmdb: Number(m.moviedb_id ?? 0), runtime: String(m.runtime ?? ""), director: Array.from(m.director ?? []),
            cast: Array.from(m.cast ?? []).slice(0, 12), country: String(m.country ?? ""),
            trailer: String((m.trailers ?? []).find(t => t.type === "Trailer")?.source ?? (m.trailers ?? [])[0]?.source ?? "")
        }
    }

    // One page of titles. filter: { kind: movie|series, catalog: top|imdbRating|year, genre, search }.
    // callback({ items, hasNext }, error)
    function page(filter: var, pageNumber: int, callback): void {
        const f = filter ?? {}
        const kind = f.kind === "series" ? "series" : "movie"
        const extra = []
        if (f.search) extra.push("search=" + encodeURIComponent(f.search))
        else {
            if (f.genre) extra.push("genre=" + encodeURIComponent(f.genre))
            if (pageNumber > 1) extra.push("skip=" + (pageNumber - 1) * root.perPage)
        }
        const catalog = f.search ? "top" : (f.catalog || "top")
        const path = `/catalog/${kind}/${catalog}${extra.length > 0 ? "/" + extra.join("&") : ""}.json`
        root._get(path, data => {
            const items = (data?.metas ?? []).filter(m => m && (m.imdb_id || m.id)).map(m => root.normalize(m))
            return { items, hasNext: !f.search && items.length >= root.perPage - 5 }
        }, callback)
    }

    // One title in full; a series with its episodes by season. callback(show, error)
    function detail(kind: string, id: string, callback): void {
        root._get(`/meta/${kind === "series" ? "series" : "movie"}/${encodeURIComponent(id)}.json`, data => {
            const m = data?.meta
            if (!m) return null
            const show = root.normalize(m)
            const episodes = Array.from(m.videos ?? []).filter(v => Number(v.season) > 0).map(v => ({
                season: Number(v.season), episode: Number(v.episode ?? v.number), title: String(v.name ?? v.title ?? ""),
                image: String(v.thumbnail ?? ""), overview: String(v.overview ?? v.description ?? ""), released: String(v.released ?? v.firstAired ?? "")
            })).sort((a, b) => a.season - b.season || a.episode - b.episode)
            show.episodes = episodes
            show.seasons = Array.from(new Set(episodes.map(e => e.season)))
            return show
        }, callback)
    }

    function forget(): void { root._cache = {} }
}
