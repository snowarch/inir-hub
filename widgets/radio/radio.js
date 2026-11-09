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

// One station as the widget keeps it, from Radio Browser's record.
function station(s, tag) {
    return {
        uuid: String(s.stationuuid ?? ""),
        name: String(s.name ?? "").trim(),
        url: String(s.url_resolved || s.url || ""),
        home: String(s.homepage ?? ""),
        country: country(s.country, s.countrycode),
        code: String(s.countrycode ?? "").toUpperCase(),
        place: String(s.state ?? "").trim(),
        codec: String(s.codec ?? ""),
        bitrate: Number(s.bitrate ?? 0),
        tags: tags(s).slice(0, 8),
        tag: String(tag ?? "")
    }
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

// The line under the station's name, in words for every state.
function status(phase, onAir, tag, problem) {
    switch (phase) {
    case "failed": return problem
    case "searching": return `Looking for ${tag} somewhere…`
    case "tuning": return "Tuning in…"
    case "playing": return onAir.length > 0 ? onAir : tag
    case "stopped": return "Paused · tap to tune back in"
    default: return "Live stations from anywhere in the world"
    }
}
