.pragma library

function statusError(status) {
    if (status >= 200 && status < 300) return ""
    return status === 429 ? "busy" : "network"
}
function searchResults(body, language) {
    const items = []
    for (const row of Array.isArray(body?.data) ? body.data : []) {
        const attr = row?.attributes ?? {}, files = Array.isArray(attr.files) ? attr.files : []
        const id = Number(files[0]?.file_id ?? 0)
        if (id > 0 && Number.isInteger(id)) items.push({fileId: id, lang: String(attr.language ?? language), name: String(attr.release ?? language).slice(0, 80), source: "OpenSubtitles"})
    }
    return items
}
function downloadLink(body) {
    const link = String(body?.link ?? "")
    return /^https:\/\/[^\s]+$/.test(link) ? link : ""
}
