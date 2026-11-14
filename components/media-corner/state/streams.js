.pragma library

// What the sources say, read and never run: Stremio add-on manifests and streams as JSON, web sources as URL templates.
// Only https streams play: torrents (infoHash) and pages meant for a browser (externalUrl) are left out.

// An add-on's root from its manifest address, or "" when it isn't one. Stremio's own links work too.
function baseOf(url) {
    const text = String(url ?? "").trim().replace(/^stremio:\/\//, "https://")
    return /^https:\/\/[^\s/?#]+(\/[^\s?#]*)?\/manifest\.json$/.test(text) ? text.slice(0, -"/manifest.json".length) : ""
}

// The host alone: an address can carry the person's token, so it is never shown whole.
function hostOf(url) {
    return String(url ?? "").replace(/^https:\/\//, "").split(/[/?#]/)[0].split("@").pop()
}

// { name, types, prefixes } of a manifest that lists streams; null when it lists none.
function manifestInfo(manifest) {
    const resources = Array.isArray(manifest?.resources) ? manifest.resources : []
    const stream = resources.find(r => r === "stream" || r?.name === "stream")
    const subtitle = resources.find(r => r === "subtitles" || r?.name === "subtitles")
    if (stream === undefined && subtitle === undefined) return null
    const resource = stream ?? subtitle
    const types = Array.isArray(resource?.types) ? resource.types : (Array.isArray(manifest?.types) ? manifest.types : [])
    const prefixes = Array.isArray(resource?.idPrefixes) ? resource.idPrefixes : (Array.isArray(manifest?.idPrefixes) ? manifest.idPrefixes : [])
    const resourceTypes = r => (Array.isArray(r?.types) ? r.types : (Array.isArray(manifest?.types) ? manifest.types : [])).map(String)
    const resourcePrefixes = r => (Array.isArray(r?.idPrefixes) ? r.idPrefixes : (Array.isArray(manifest?.idPrefixes) ? manifest.idPrefixes : [])).map(String)
    return { name: String(manifest.name ?? "").slice(0, 40), types: types.map(String), prefixes: prefixes.map(String),
             streamTypes: resourceTypes(stream), streamPrefixes: resourcePrefixes(stream),
             subtitleTypes: resourceTypes(subtitle), subtitlePrefixes: resourcePrefixes(subtitle),
             hasStreams: stream !== undefined, hasSubtitles: subtitle !== undefined }
}

function subtitlesFrom(body) {
    const result = []
    for (const entry of Array.isArray(body?.subtitles) ? body.subtitles : []) {
        const url = String(entry?.url ?? ""), lang = String(entry?.lang ?? "").toLowerCase()
        if (!/^https:\/\/[^\s]+$/.test(url) || !/^[a-z]{2,3}$/.test(lang)) continue
        result.push({ url, lang, name: String(entry.label ?? lang).slice(0, 80) })
    }
    return result
}

// [{ name, url, referer }] an add-on answers for one video.
function streamsFrom(body) {
    const out = []
    for (const item of Array.isArray(body?.streams) ? body.streams : []) {
        const url = String(item?.url ?? "")
        if (!/^https:\/\/\S+$/.test(url)) continue
        const headers = item.behaviorHints?.proxyHeaders?.request ?? {}
        const referer = String(headers.Referer ?? headers.referer ?? "")
        const name = [item.name, item.title ?? item.description].filter(Boolean).map(text => String(text).split("\n")[0]).join(" · ").slice(0, 80)
        out.push({ name: name || "Stream", url, referer: /^https:\/\/\S+$/.test(referer) ? referer : "" })
    }
    return out
}

// The request path for one video on this add-on, or "" when it can't find it by the ids there are.
// show: { kind: anime|movie|series, id, film? }; episode: { season?, episode } or null.
function pathFor(source, show, episode, kitsuId, resource) {
    const resourcePrefixes = resource === "subtitles" ? source.subtitlePrefixes : source.streamPrefixes
    const resourceTypes = resource === "subtitles" ? source.subtitleTypes : source.streamTypes
    const prefixes = Array.isArray(resourcePrefixes) ? resourcePrefixes : (Array.isArray(source.prefixes) ? source.prefixes : [])
    const types = Array.isArray(resourceTypes) ? resourceTypes : (Array.isArray(source.types) ? source.types : [])
    const asks = prefix => prefixes.length === 0 || prefixes.includes(prefix)
    const serves = type => types.length === 0 || types.includes(type)
    if (show.kind === "anime") {
        if (!kitsuId || !asks("kitsu")) return ""
        if (show.film) return serves("movie") ? `movie/kitsu:${kitsuId}` : ""
        const type = types.includes("anime") ? "anime" : "series"
        return serves(type) ? `${type}/kitsu:${kitsuId}:${episode?.episode ?? 1}` : ""
    }
    if (!/^tt\d+$/.test(String(show.id)) || !asks("tt") || !serves(show.kind)) return ""
    return show.kind === "movie" ? `movie/${show.id}` : `series/${show.id}:${episode?.season ?? 1}:${episode?.episode ?? 1}`
}

// Kitsu's id for an AniList show, from its mappings answer; "" when it has none.
function kitsuIdFrom(body) {
    const anime = (Array.isArray(body?.included) ? body.included : []).find(item => item?.type === "anime" && /^\d+$/.test(String(item.id)))
    return anime ? String(anime.id) : ""
}

function validTemplate(template) {
    return /^https:\/\/\S+$/.test(String(template ?? "").trim()) && String(template).includes("%s")
}

function webUrl(template, title) {
    return String(template).replace("%s", () => encodeURIComponent(String(title ?? "")))
}

// What a play's progress is kept under.
function watchKey(show, episode) {
    if (!episode) return String(show.id)
    return episode.season !== undefined ? `${show.id}:${episode.season}:${episode.episode}` : `${show.id}:${episode.episode}`
}

// mpv's status line, as asked for by --term-status-msg: { position, duration, window }, or null before there is a position.
function statusFrom(line) {
    const parts = String(line).split(" ")
    if (parts[0] !== "@@POS" || !/^\d/.test(parts[1] ?? "")) return null
    return { position: Number(parts[1]), duration: Number(parts[2]) || 0, window: parts[3] === "yes" }
}

function clock(seconds) {
    const total = Math.max(0, Math.floor(seconds)), hours = Math.floor(total / 3600), minutes = Math.floor(total / 60) % 60
    const two = n => String(n).padStart(2, "0")
    return (hours > 0 ? hours + ":" + two(minutes) : String(minutes)) + ":" + two(total % 60)
}
