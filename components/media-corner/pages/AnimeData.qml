pragma ComponentBehavior: Bound
import QtQuick
import qs.services.deferred

// What the Media Corner asks AniList: pages of shows, the genres and one show in full. It lives and dies with the
// Corner; each answer is kept ten minutes and asked once. The network goes through AnimeService._graphql, which already waits out AniList's 429s.
QtObject {
    id: root
    // Which catalogue it is, for the pages that take either.
    readonly property bool anime: true

    // AniList's isAdult filter: adult titles stay out (null would ask for everything).
    readonly property var adult: false
    readonly property int cacheMs: 10 * 60 * 1000
    readonly property int perPage: 30

    readonly property string mediaFields: `
        id
        idMal
        title { romaji english native }
        coverImage { extraLarge large medium color }
        bannerImage
        description(asHtml: false)
        averageScore
        popularity
        episodes
        duration
        status
        genres
        studios(isMain: true) { nodes { name } }
        source
        format
        season
        seasonYear
        nextAiringEpisode { airingAt episode }
        siteUrl
        isAdult
    `

    // key -> { at, value }; key -> [callbacks] while a request is out, so one question is asked once.
    property var _cache: ({})
    property var _waiting: ({})

    function _ask(key, query, variables, shape, callback): void {
        const hit = root._cache[key]
        if (hit && Date.now() - hit.at < root.cacheMs) { callback(hit.value, ""); return }
        // One question out at a time; one that never came back (20 s) is asked again.
        const out = root._waiting[key]
        if (out && Date.now() - out.at < 20000) { out.callbacks.push(callback); return }
        const ticket = { at: Date.now(), callbacks: [callback] }
        root._waiting[key] = ticket
        AnimeService._graphql(query, variables, (data, error) => {
            let value = null, failed = error ? String(error) : ""
            if (!failed) {
                try { value = shape(data) } catch (e) { failed = "bad reply" }
            }
            if (!failed) root._cache[key] = { at: Date.now(), value }
            if (root._waiting[key] === ticket) delete root._waiting[key]
            for (const cb of ticket.callbacks) cb(value, failed)
        })
    }

    function normalize(m): var {
        const show = AnimeService._normalizeAnime(m)
        show.kind = "anime"
        show.imageLarge = m.coverImage?.extraLarge ?? show.image
        show.colour = m.coverImage?.color ?? ""
        show.banner = m.bannerImage ?? ""
        // AniList's plain text still carries <br> and <i>: the page shows words only.
        show.description = String(m.description ?? "").replace(/<br\s*\/?>/gi, "\n").replace(/<[^>]+>/g, "")
            .replace(/\n{3,}/g, "\n\n").trim()
        show.idMal = Number(m.idMal ?? 0)
        show.popularity = Number(m.popularity ?? 0)
        show.duration = Number(m.duration ?? 0)
        // AniList's format in words (the filter keeps the enum).
        show.type = ({ TV: "TV", TV_SHORT: "TV short", MOVIE: "Movie", SPECIAL: "Special", OVA: "OVA", ONA: "ONA", MUSIC: "Music" })[m.format] ?? String(m.format ?? "")
        return show
    }

    // One page of shows. `filter` = { search, genre, sort, format, season, year, status, ids }; null fields are unset.
    // callback({ items, hasNext }, error)
    function page(filter, pageNumber, callback): void {
        const f = filter ?? {}
        const sort = f.sort ? [f.sort] : (f.search ? ["SEARCH_MATCH"] : ["POPULARITY_DESC"])
        // AniList reads a null argument as a filter of its own (or fails on id_in): only what is set goes in the query.
        const args = { search: "String", genre: "String", format: "MediaFormat", season: "MediaSeason", year: "Int", status: "MediaStatus", ids: "[Int]", malIds: "[Int]" }
        const field = { year: "seasonYear", ids: "id_in", malIds: "idMal_in" }
        const variables = { page: pageNumber, perPage: root.perPage, sort }
        let declared = "$page: Int, $perPage: Int, $sort: [MediaSort]", passed = "type: ANIME, sort: $sort"
        if (root.adult !== null) { variables.isAdult = root.adult; declared += ", $isAdult: Boolean"; passed += ", isAdult: $isAdult" }
        for (const name in args) {
            const value = f[name]
            if (value === undefined || value === null || value === "" || (Array.isArray(value) && value.length === 0)) continue
            variables[name] = value
            declared += `, $${name}: ${args[name]}`
            passed += `, ${field[name] ?? name}: $${name}`
        }
        const query = `
            query (${declared}) {
                Page(page: $page, perPage: $perPage) {
                    pageInfo { hasNextPage }
                    media(${passed}) { ${root.mediaFields} }
                }
            }`
        root._ask("page:" + JSON.stringify(variables), query, variables, data => ({
            items: (data?.Page?.media ?? []).map(m => root.normalize(m)),
            hasNext: Boolean(data?.Page?.pageInfo?.hasNextPage)
        }), callback)
    }

    // AniList's genres, minus the adult one unless asked for. callback([names], error)
    function genres(callback): void {
        root._ask("genres", "query { GenreCollection }", {}, data => (data?.GenreCollection ?? [])
            .filter(g => root.adult === null || g !== "Hentai"), callback)
    }

    // One show in full, with what AniList recommends next to it. callback(show, error)
    function detail(id, callback): void {
        const query = `
            query ($id: Int) {
                Media(id: $id, type: ANIME) {
                    ${root.mediaFields}
                    externalLinks { site url type }
                    recommendations(perPage: 12, sort: RATING_DESC) { nodes { mediaRecommendation { ${root.mediaFields} } } }
                    relations { edges { relationType(version: 2) node { type ${root.mediaFields} } } }
                }
            }`
        root._ask("detail:" + id, query, { id: Number(id) }, data => {
            const m = data?.Media
            if (!m) return null
            const show = root.normalize(m)
            // Where it streams officially (Crunchyroll, Netflix…): AniList's own links, opened in the browser.
            show.streaming = (m.externalLinks ?? []).filter(l => l?.type === "STREAMING" && /^https:\/\//.test(String(l.url ?? "")))
                .map(l => ({ site: String(l.site ?? ""), url: String(l.url) }))
            show.recommendations = (m.recommendations?.nodes ?? []).map(n => n.mediaRecommendation)
                .filter(r => r && (root.adult === null || !r.isAdult)).map(r => root.normalize(r))
            // Sequels first, then the rest of the family; manga and novels stay on AniList.
            const order = ["PREQUEL", "SEQUEL", "PARENT", "SIDE_STORY", "SPIN_OFF", "ALTERNATIVE", "SUMMARY", "COMPILATION", "CONTAINS", "CHARACTER", "OTHER"]
            show.relations = (m.relations?.edges ?? []).filter(e => e?.node?.type === "ANIME" && (root.adult === null || !e.node.isAdult))
                .sort((a, b) => (order.indexOf(a.relationType) + 99) % 99 - (order.indexOf(b.relationType) + 99) % 99)
                .map(e => Object.assign(root.normalize(e.node), { relation: String(e.relationType ?? "OTHER") }))
            return show
        }, callback)
    }

    function forget(): void { root._cache = {} }
}
