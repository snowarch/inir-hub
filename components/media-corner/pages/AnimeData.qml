pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import "../state"

// What the Media Corner asks AniList: pages of shows, the genres and one show in full. Adult titles stay out.
QtObject {
    id: root
    // Which catalogue it is, for the pages that take either.
    readonly property bool anime: true
    readonly property string sourceName: "AniList"
    // Why its last answer failed, in words; empty while it answers.
    property string down: ""
    readonly property string base: "https://graphql.anilist.co"
    readonly property int perPage: 30

    // What a poster needs.
    readonly property string cardFields: `
        id
        title { romaji english native }
        coverImage { extraLarge large medium }
        averageScore
        format
        seasonYear
    `
    readonly property string mediaFields: `
        ${root.cardFields}
        idMal
        bannerImage
        description(asHtml: false)
        episodes
        duration
        status
        genres
        studios(isMain: true) { nodes { name } }
        season
        nextAiringEpisode { airingAt episode }
        siteUrl
    `

    function currentSeason(): string {
        const month = new Date().getMonth()
        return month < 3 ? "WINTER" : month < 6 ? "SPRING" : month < 9 ? "SUMMER" : "FALL"
    }
    function seasonName(season: string): string {
        return ({ WINTER: "Winter", SPRING: "Spring", SUMMER: "Summer", FALL: "Fall" })[season] ?? season
    }

    function _ask(query: string, variables: var, shape: var, callback: var): void {
        CornerState.ask(root.base, JSON.stringify({ query, variables }), reply => {
            if (reply?.errors) throw new Error(String(reply.errors[0]?.message))
            return shape(reply?.data)
        }, (value, error) => {
            root.down = !error ? "" : error === "busy" ? Translation.tr("AniList is busy, try again in a minute")
                : !Network.online && error === "HTTP 0" ? Network.offlineReason : Translation.tr("%1 didn't answer (´・ω・`)").arg(root.sourceName)
            callback(value, error)
        })
    }

    function normalize(m: var): var {
        const next = m.nextAiringEpisode
        return {
            id: m.id, kind: "anime",
            title: m.title?.english ?? m.title?.romaji ?? "",
            titleRomaji: m.title?.romaji ?? "",
            titleJapanese: m.title?.native ?? "",
            image: m.coverImage?.large ?? m.coverImage?.medium ?? "",
            imageLarge: m.coverImage?.extraLarge ?? m.coverImage?.large ?? "",
            banner: m.bannerImage ?? "",
            // AniList's plain text still carries <br> and <i>: the page shows words only.
            description: String(m.description ?? "").replace(/<br\s*\/?>/gi, "\n").replace(/<[^>]+>/g, "").replace(/\n{3,}/g, "\n\n").trim(),
            score: (m.averageScore ?? 0) / 10,
            episodes: m.episodes ?? "?",
            duration: Number(m.duration ?? 0),
            status: m.status ?? "",
            genres: m.genres ?? [],
            studios: (m.studios?.nodes ?? []).map(s => s.name),
            season: m.season ?? "",
            year: m.seasonYear ?? "",
            airingAt: Number(next?.airingAt ?? 0),
            nextEpisode: Number(next?.episode ?? 0),
            idMal: Number(m.idMal ?? 0),
            url: m.siteUrl ?? ("https://anilist.co/anime/" + m.id),
            // AniList's format in words (the filter keeps the enum).
            type: ({ TV: "TV", TV_SHORT: "TV short", MOVIE: "Movie", SPECIAL: "Special", OVA: "OVA", ONA: "ONA", MUSIC: "Music" })[m.format] ?? String(m.format ?? "")
        }
    }

    // One page of shows. filter: { search, genre, sort, format, season, year, status }. callback({ items, hasNext }, error)
    function page(filter: var, pageNumber: int, callback: var): void {
        const f = filter ?? {}
        const sort = f.sort ? [f.sort] : (f.search ? ["SEARCH_MATCH"] : ["POPULARITY_DESC"])
        // AniList reads a null argument as a filter of its own: only what is set goes in the query.
        const args = { search: "String", genre: "String", format: "MediaFormat", season: "MediaSeason", year: "Int", status: "MediaStatus" }
        const field = { year: "seasonYear" }
        const variables = { page: pageNumber, perPage: root.perPage, sort }
        let declared = "$page: Int, $perPage: Int, $sort: [MediaSort]", passed = "type: ANIME, sort: $sort, isAdult: false"
        for (const name in args) {
            const value = f[name]
            if (value === undefined || value === null || value === "") continue
            variables[name] = value
            declared += `, $${name}: ${args[name]}`
            passed += `, ${field[name] ?? name}: $${name}`
        }
        const query = `query (${declared}) { Page(page: $page, perPage: $perPage) { pageInfo { hasNextPage } media(${passed}) { ${root.mediaFields} } } }`
        root._ask(query, variables, data => ({
            items: (data?.Page?.media ?? []).map(m => root.normalize(m)),
            hasNext: Boolean(data?.Page?.pageInfo?.hasNextPage)
        }), callback)
    }

    // AniList's genres, without the adult one. callback([names], error)
    function genres(callback: var): void {
        root._ask("query { GenreCollection }", {}, data => (data?.GenreCollection ?? []).filter(g => g !== "Hentai"), callback)
    }

    // One show in full, with what AniList recommends next to it. callback(show, error)
    function detail(id: int, callback: var): void {
        const query = `
            query ($id: Int) {
                Media(id: $id, type: ANIME) {
                    ${root.mediaFields}
                    externalLinks { site url type }
                    recommendations(perPage: 12, sort: RATING_DESC) { nodes { mediaRecommendation { isAdult ${root.cardFields} } } }
                    relations { edges { relationType(version: 2) node { type isAdult ${root.cardFields} } } }
                }
            }`
        root._ask(query, { id }, data => {
            const m = data?.Media
            if (!m) return null
            const show = root.normalize(m)
            // Where it streams officially (Crunchyroll, Netflix…): AniList's own links, opened in the browser.
            show.streaming = (m.externalLinks ?? []).filter(l => l?.type === "STREAMING" && /^https:\/\//.test(String(l.url ?? "")))
                .map(l => ({ site: String(l.site ?? ""), url: String(l.url) }))
            show.recommendations = (m.recommendations?.nodes ?? []).map(n => n.mediaRecommendation)
                .filter(r => r && !r.isAdult).map(r => root.normalize(r))
            // Sequels first, then the rest of the family; manga and novels stay on AniList.
            const words = { PREQUEL: "Prequel", SEQUEL: "Sequel", PARENT: "Main story", SIDE_STORY: "Side story", SPIN_OFF: "Spin-off", ALTERNATIVE: "Alternative",
                SUMMARY: "Summary", COMPILATION: "Compilation", CONTAINS: "Contains", CHARACTER: "Same characters" }
            const order = Object.keys(words)
            show.relations = (m.relations?.edges ?? []).filter(e => e?.node?.type === "ANIME" && !e.node.isAdult)
                .sort((a, b) => (order.indexOf(a.relationType) + 99) % 99 - (order.indexOf(b.relationType) + 99) % 99)
                .map(e => Object.assign(root.normalize(e.node), { relation: words[e.relationType] ?? "" }))
            return show
        }, callback)
    }
}
