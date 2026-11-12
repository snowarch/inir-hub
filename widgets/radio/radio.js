.pragma library

// Radio Browser (radio-browser.info): a free, open directory of the world's internet stations, run by volunteers on
// a few mirrors. Its terms ask clients to send each station they play to /json/url/<uuid>, which keeps the counts
// that rank stations for everyone.
const MIRRORS = ["https://de1.api.radio-browser.info", "https://fi1.api.radio-browser.info", "https://de2.api.radio-browser.info"]

// Tags that say a station talks rather than plays.
const SPOKEN = ["news", "talk", "sport", "sports", "religio", "christian", "catholic", "church", "bible", "quran",
    "islam", "sermon", "politic", "information", "podcast", "comedy", "traffic", "weather", "spoken", "audiobook",
    "community radio", "university", "public radio", "npr", "bbc radio 4", "scanner", "police", "aviation"]

// For "Anywhere": genres from every part of the world, so a random one is music somewhere, not only the West's charts.
const WORLD = ["jazz", "soul", "funk", "blues", "reggae", "dub", "ska", "afrobeat", "highlife", "soukous", "rai",
    "gnawa", "chanson", "bossa nova", "samba", "mpb", "cumbia", "salsa", "tango", "bolero", "flamenco", "fado",
    "rebetiko", "balkan", "klezmer", "celtic", "folk", "bluegrass", "country", "gospel", "city pop", "j-pop",
    "k-pop", "enka", "mandopop", "bollywood", "qawwali", "carnatic", "gamelan", "kpop", "dangdut", "ambient",
    "classical", "baroque", "opera", "electronic", "house", "techno", "drum and bass", "dubstep", "trip-hop",
    "downtempo", "lounge", "chillout", "disco", "synthwave", "italo disco", "new wave", "post-punk", "shoegaze",
    "dream pop", "indie", "psychedelic", "krautrock", "progressive rock", "metal", "punk", "garage", "surf",
    "rockabilly", "rock", "hip hop", "rnb", "trap", "lo-fi", "vaporwave", "world", "latin", "african", "arabic",
    "turkish", "persian", "greek", "brazilian", "cuban", "mexican", "andean", "hawaiian", "polka", "swing", "big band"]

function tags(station) {
    return String(station?.tags ?? "").toLowerCase().split(",").map(t => t.trim()).filter(t => t.length > 0)
}

function spoken(station) {
    const all = tags(station).join(",") + "," + String(station?.name ?? "").toLowerCase()
    return SPOKEN.some(s => all.indexOf(s) >= 0)
}

// One station as the widget keeps it, from Radio Browser's record. Favourites and recent stations are these same
// objects in the person's config, so they play without asking the directory again.
function station(s, tag) {
    return {
        uuid: String(s.stationuuid ?? ""),
        name: cleanName(s.name),
        url: String(s.url_resolved || s.url || ""),
        home: String(s.homepage ?? ""),
        logo: logo(s.favicon),
        country: country(s.country, s.countrycode),
        code: String(s.countrycode ?? "").toUpperCase(),
        place: String(s.state ?? "").trim(),
        language: String(s.language ?? "").split(",")[0].trim(),
        codec: String(s.codec ?? ""),
        bitrate: Number(s.bitrate ?? 0),
        votes: Number(s.votes ?? 0),
        tags: tags(s).slice(0, 8),
        tag: String(tag ?? "")
    }
}

// Many stations pack their genres into the name ("0R - COFFEE LOUNGE || Jazz, Lounge, Chill…"): the name is what
// comes before.
function cleanName(name) {
    const n = String(name ?? "").trim()
    const cut = n.search(/\s(\|\||\||::)\s/)
    return cut >= 3 ? n.slice(0, cut).trim() : n
}

// A favicon worth loading: an http(s) image address, nothing else (some records hold a data: blob or a page).
function logo(url) {
    const u = String(url ?? "").trim()
    return /^https?:\/\/\S+$/.test(u) && u.length < 400 ? u : ""
}

// Tags that say nothing of the music: codecs, years, the word "radio", a frequency.
const NOISE = /^(aac\+?|mp3|ogg|opus|flac|hls|\d+|\d+[.,]\d+( ?fm)?|fm|am|radio|music|online|internet radio|webradio|stereo|information|live|other|various)$/

// What a row says under the name: the place and the station's own genres, as few words as carry it.
function meta(s) {
    if (!s) return ""
    const parts = []
    const at = where(s)
    if (at.length > 0) parts.push(at)
    const genres = (s.tags ?? []).filter(t => t.length <= 18 && !NOISE.test(t)).slice(0, 2)
    if (genres.length > 0) parts.push(genres.join(", "))
    return parts.join(" · ")
}

// Which logo addresses answered with an image, asked once a session: a logo that fails would otherwise write a
// warning to the person's log for every row that shows it. true, false, or a list of callers waiting.
const logos = {}
function checkLogo(url, done) {
    const known = logos[url]
    if (known === true || known === false) { done(known); return }
    if (Array.isArray(known)) { known.push(done); return }
    logos[url] = [done]
    const xhr = new XMLHttpRequest()
    xhr.onreadystatechange = () => {
        if (xhr.readyState !== XMLHttpRequest.DONE) return
        const ok = xhr.status === 200 && /^image\/(png|jpe?g|gif|webp|svg|x-icon|vnd\.microsoft\.icon|bmp)/i.test(String(xhr.getResponseHeader("Content-Type") ?? ""))
        const waiting = logos[url]
        logos[url] = ok
        if (Array.isArray(waiting)) waiting.forEach(f => f(ok))
    }
    xhr.open("GET", url)
    xhr.send()
}

// The stream's quality as people read it: "MP3 128".
function quality(s) {
    if (!s) return ""
    const c = String(s.codec ?? "").toUpperCase().replace("UNKNOWN", "")
    const b = Number(s.bitrate ?? 0)
    return [c, b > 0 ? String(b) : ""].filter(x => x.length > 0).join(" ")
}

// A name as a title: the directory keeps genres and languages lowercase ("bossa nova", "english").
function title(text) {
    return String(text ?? "").replace(/(^|[\s\-\/])(\p{L})/gu, (m, a, b) => a + b.toUpperCase())
}

// The stations a list keeps once: the same station is often listed twice, under the same name.
function unique(list) {
    const seen = {}
    return list.filter(s => {
        const key = s.name.toLowerCase()
        if (s.url.length === 0 || seen[key] || seen[s.uuid]) return false
        seen[key] = seen[s.uuid] = true
        return true
    })
}

// The directory writes official names ("The United States Of America"); people say the short one.
const SHORT = { "The United States Of America": "United States", "The United Kingdom Of Great Britain And Northern Ireland": "United Kingdom",
    "The Russian Federation": "Russia", "The Republic Of Korea": "South Korea", "The Netherlands": "Netherlands",
    "Iran (Islamic Republic Of)": "Iran", "Bolivia (Plurinational State Of)": "Bolivia", "The Republic Of Moldova": "Moldova",
    "Venezuela (Bolivarian Republic Of)": "Venezuela", "Taiwan, Republic Of China": "Taiwan", "Viet Nam": "Vietnam",
    "The Czech Republic": "Czechia", "The Philippines": "Philippines", "The Dominican Republic": "Dominican Republic" }
function country(name, code) {
    const n = String(name ?? "").trim()
    if (SHORT[n]) return SHORT[n]
    const plain = n.replace(/^The /, "")
    return plain.length > 0 ? plain : String(code ?? "")
}

// The flag of a two-letter country code, as the pair of regional letters every emoji font draws.
function flag(code) {
    const c = String(code ?? "").toUpperCase()
    if (!/^[A-Z]{2}$/.test(c)) return ""
    return String.fromCodePoint(0x1F1E6 + c.charCodeAt(0) - 65, 0x1F1E6 + c.charCodeAt(1) - 65)
}

// A tag drawn by weight among the strongest, never the one just played when another is there.
function pick(weights, last) {
    const all = Object.keys(weights).filter(t => weights[t] > 0).sort((a, b) => weights[b] - weights[a]).slice(0, 10)
    const pool = all.length > 1 ? all.filter(t => t !== last) : all
    const sum = pool.reduce((s, t) => s + weights[t], 0)
    let r = Math.random() * sum
    for (let i = 0; i < pool.length; i++) {
        r -= weights[pool[i]]
        if (r <= 0) return pool[i]
    }
    return pool[0] ?? ""
}

function anywhere(last) {
    let t = last
    while (t === last) t = WORLD[Math.floor(Math.random() * WORLD.length)]
    return t
}

function query(params) {
    return Object.keys(params).map(k => `${encodeURIComponent(k)}=${encodeURIComponent(params[k])}`).join("&")
}

// Stations often send their now-playing line HTML-escaped ("Don&#039;t", "Simon &amp; Garfunkel").
function unescape(text) {
    return String(text ?? "").replace(/&#(\d+);/g, (m, n) => String.fromCodePoint(Number(n)))
        .replace(/&#x([0-9a-f]+);/gi, (m, n) => String.fromCodePoint(parseInt(n, 16)))
        .replace(/&quot;/g, "\"").replace(/&apos;/g, "'").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&")
        .trim()
}

// The genres the person typed in the widget's settings ("city pop, jazz"), lowercase, empty for anywhere.
function genres(text) {
    return String(text ?? "").toLowerCase().split(",").map(t => t.trim()).filter(t => t.length > 0)
}

// The next genre: one of the person's, never the one just played when another is there; anywhere without any.
function nextGenre(list, last) {
    if (list.length === 0) return anywhere(last)
    const pool = list.length > 1 ? list.filter(t => t !== last) : list
    return pool[Math.floor(Math.random() * pool.length)]
}

// Where a station is, as people say it: "Kanagawa, Japan", or the country alone.
function where(s) {
    if (!s) return ""
    const place = String(s.place ?? "")
    return place.length > 0 && place !== s.country ? `${place}, ${s.country}` : String(s.country ?? "")
}
