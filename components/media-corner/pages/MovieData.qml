pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import "../state"

// What the Media Corner asks Cinemeta (Stremio's open catalogue of films and series, by IMDb id): lists, searches and
// one title in full.
QtObject {
    id: root
    // Which catalogue it is, for the pages that take either.
    readonly property bool anime: false
    readonly property string sourceName: "Cinemeta"
    // Why its last answer failed, in words; empty while it answers.
    property string down: ""
    readonly property string base: "https://v3-cinemeta.strem.io"
    // Cinemeta's pages are this long; a shorter one is the last.
    readonly property int perPage: 50
    // The manifest's years end here.
    readonly property int firstYear: 1987
    readonly property var seriesOnly: ["Game-Show", "Reality-TV", "Talk-Show"]
    readonly property var genreNames: ["Action", "Adventure", "Animation", "Biography", "Comedy", "Crime", "Documentary", "Drama",
        "Family", "Fantasy", "History", "Horror", "Mystery", "Romance", "Sci-Fi", "Sport", "Thriller", "War", "Western"].concat(root.seriesOnly)

    function _get(path: string, shape: var, callback: var): void {
        CornerState.ask(root.base + path, "", shape, (value, error) => {
            root.down = !error ? "" : !Network.online && error === "HTTP 0" ? Network.offlineReason : Translation.tr("%1 didn't answer (´・ω・`)").arg(root.sourceName)
            callback(value, error)
        })
    }

    // Cinemeta's meta in the shape the pages read (the anime's, so posters and shelves are the same).
    function normalize(m: var): var {
        const poster = String(m.poster ?? "")
        return {
            id: String(m.imdb_id ?? m.id ?? ""), kind: m.type === "series" ? "series" : "movie",
            title: String(m.name ?? ""),
            image: poster.replace("/poster/small/", "/poster/medium/"),
            imageLarge: poster.replace("/poster/small/", "/poster/large/").replace("/poster/medium/", "/poster/large/"),
            banner: String(m.background ?? ""),
            description: String(m.description ?? ""), year: String(m.releaseInfo ?? m.year ?? ""), score: Number(m.imdbRating ?? 0),
            genres: Array.from(m.genres ?? m.genre ?? []), type: m.type === "series" ? "Series" : "Movie",
            runtime: String(m.runtime ?? ""), director: Array.from(m.director ?? []),
            cast: Array.from(m.cast ?? []).slice(0, 12), country: String(m.country ?? ""),
            trailer: String((m.trailers ?? []).find(t => t.type === "Trailer")?.source ?? (m.trailers ?? [])[0]?.source ?? "")
        }
    }

    // One page of titles. filter: { kind: movie|series, catalog: top|imdbRating|year, genre, search }.
    // callback({ items, hasNext }, error)
    function page(filter: var, pageNumber: int, callback: var): void {
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
    function detail(kind: string, id: string, callback: var): void {
        root._get(`/meta/${kind === "series" ? "series" : "movie"}/${encodeURIComponent(id)}.json`, data => {
            const m = data?.meta
            if (!m) return null
            const show = root.normalize(m)
            const episodes = Array.from(m.videos ?? []).filter(v => Number(v.season) > 0).map(v => ({
                season: Number(v.season), episode: Number(v.episode ?? v.number), title: String(v.name ?? v.title ?? ""),
                image: String(v.thumbnail ?? ""), released: String(v.released ?? v.firstAired ?? "")
            })).sort((a, b) => a.season - b.season || a.episode - b.episode)
            show.episodes = episodes
            show.seasons = Array.from(new Set(episodes.map(e => e.season)))
            return show
        }, callback)
    }
}
