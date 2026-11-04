pragma ComponentBehavior: Bound
import QtQuick
import qs.services

// What the Movie Corner asks Cinemeta (Stremio's open catalogue of films and series, by IMDb id): lists, searches and
// one title in full. It lives and dies with the Corner; each answer is kept ten minutes and asked once.
QtObject {
    id: root

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
        if (root._waiting[path]) { root._waiting[path].push(callback); return }
        root._waiting[path] = [callback]
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = () => {
            // The Corner closed while it was out: nothing is left to tell.
            if (xhr.readyState !== XMLHttpRequest.DONE || !root) return
            let value = null, error = ""
            if (xhr.status === 200) {
                try { value = shape(JSON.parse(xhr.responseText)) } catch (e) { error = "bad reply" }
            } else error = "HTTP " + xhr.status
            if (!error) root._cache[path] = { at: Date.now(), value }
            const callbacks = root._waiting[path] ?? []
            delete root._waiting[path]
            for (const cb of callbacks) cb(value, error)
        }
        xhr.open("GET", root.base + path)
        xhr.send()
    }

    // Cinemeta's meta in the shape the pages read (the Anime Corner's, so posters and shelves are the same).
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

    // Where a title streams in a country, from TMDB (data by JustWatch), with the person's own TMDB key: v3 API key
    // or v4 read token. callback({ link, services: [{ name, logo }] } or null). Never asked without a key.
    function whereToWatch(kind: string, tmdb: int, key: string, region: string, callback): void {
        if (!(tmdb > 0) || key.length === 0 || !/^[A-Z]{2}$/.test(region)) { callback(null); return }
        const path = `/3/${kind === "series" ? "tv" : "movie"}/${tmdb}/watch/providers`
        const hit = root._cache["tmdb:" + path + region]
        if (hit && Date.now() - hit.at < root.cacheMs) { callback(hit.value); return }
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = () => {
            // The Corner closed while it was out: nothing is left to tell.
            if (xhr.readyState !== XMLHttpRequest.DONE || !root) return
            let value = null
            if (xhr.status === 200) {
                try {
                    const here = JSON.parse(xhr.responseText)?.results?.[region]
                    const seen = new Set()
                    const services = ["flatrate", "free", "ads", "rent", "buy"].flatMap(kind => Array.from(here?.[kind] ?? []))
                        .filter(p => p && !seen.has(p.provider_id) && seen.add(p.provider_id))
                        .map(p => ({ name: String(p.provider_name ?? ""), logo: /^\/[\w.-]+$/.test(String(p.logo_path ?? "")) ? "https://image.tmdb.org/t/p/w92" + p.logo_path : "" }))
                    const link = String(here?.link ?? "")
                    value = here && /^https:\/\/www\.themoviedb\.org\//.test(link) ? { link, services: services.slice(0, 5) } : null
                } catch (e) { value = null }
                root._cache["tmdb:" + path + region] = { at: Date.now(), value }
            }
            callback(value)
        }
        const v4 = key.length > 40
        xhr.open("GET", "https://api.themoviedb.org" + path + (v4 ? "" : "?api_key=" + encodeURIComponent(key)))
        if (v4) xhr.setRequestHeader("Authorization", "Bearer " + key)
        xhr.send()
    }

    function forget(): void { root._cache = {} }
}
