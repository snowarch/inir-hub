.pragma library

function languageCode(value) {
    const code = String(value ?? "").trim().toLowerCase()
    const aliases = { en: "eng", es: "spa", pt: "por", fr: "fra", fre: "fra", de: "deu", ger: "deu", it: "ita", ja: "jpn", ko: "kor", zh: "zho", chi: "zho", ar: "ara", ru: "rus", uk: "ukr", hi: "hin", id: "ind", tr: "tur" }
    return aliases[code] ?? code
}
function languageLabel(value) {
    const code = String(value ?? "").trim().toLowerCase()
    const names = { eng: "English", spa: "Español", por: "Português", fra: "Français", deu: "Deutsch", ita: "Italiano", jpn: "日本語", kor: "한국어", zho: "中文", ara: "العربية", rus: "Русский", ukr: "Українська", hin: "हिन्दी", ind: "Bahasa Indonesia", tur: "Türkçe" }
    const name = names[languageCode(code)]
    return name ? `${name} (${code})` : code
}
function findLanguage(items, language) {
    const wanted = languageCode(language)
    return wanted ? items.find(item => languageCode(item.lang) === wanted) ?? null : null
}
function preferredSelection(items, primary, fallback, failed, automatic) {
    if (!automatic) return null
    return findLanguage(items, primary) ?? (!failed ? findLanguage(items, fallback) : null)
}

function statusError(status) {
    if (status >= 200 && status < 300) return ""
    return status === 429 ? "busy" : "network"
}
function searchResults(body, language) {
    const items = []
    for (const row of Array.isArray(body?.data) ? body.data : []) {
        const attr = row?.attributes ?? {}, files = Array.isArray(attr.files) ? attr.files : []
        const id = Number(files[0]?.file_id ?? 0)
        if (id > 0 && Number.isInteger(id)) items.push({fileId: id, lang: String(attr.language ?? language).slice(0, 16), name: String(attr.release ?? language).slice(0, 80), hearingImpaired: attr.hearing_impaired === true, source: "OpenSubtitles"})
    }
    return items
}
function downloadLink(body) {
    const link = String(body?.link ?? "")
    return /^https:\/\/[^\s]+$/.test(link) ? link : ""
}
