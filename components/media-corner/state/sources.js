.pragma library

// Pure source data operations. Persistence and network requests live in the caller.
function httpUrl(value) {
    const text = String(value || "")
    const match = text.match(/^https?:\/\/(?:[^@\s/?#]+@)?(?:[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?|\[[0-9a-f:]+\])(?::([0-9]{1,5}))?(?:[/?#][^\s]*)?$/i)
    return Boolean(match) && (!match[1] || Number(match[1]) <= 65535)
        && !/[\x00-\x20\\]/.test(text) && !/%(?![0-9a-f]{2})/i.test(text)
}

function webUrl(template, title) {
    if (typeof template !== "string" || template.split("%s").length !== 2) return ""
    const authority = template.match(/^https?:\/\/[^/?#]+/i)
    if (!authority || template.indexOf("%s") < authority[0].length) return ""
    let resolved
    try { resolved = template.replace("%s", encodeURIComponent(String(title || ""))) }
    catch (error) { return "" }
    return httpUrl(resolved) ? resolved : ""
}

function validSource(source) {
    if (!source || typeof source !== "object" || typeof source.name !== "string" || !source.name.trim()) return false
    if (source.type === "web") return webUrl(source.template, "test") !== ""
    if (source.type === "stremio") return typeof source.url === "string" && httpUrl(source.url)
        && /^https:\/\//i.test(source.url) && /\/manifest\.json$/.test(source.url)
    return false
}

// Accept v1.1's JSON string/array and versioned records. Return a new value, without mutating the input.
function migrate(input) {
    let value = input
    try { if (typeof value === "string") value = JSON.parse(value) }
    catch (error) { return { schemaVersion: 1, sources: [], invalid: 1, recognized: false } }
    let entries
    if (Array.isArray(value)) entries = value
    else if (value && value.schemaVersion === 1 && Array.isArray(value.sources)) entries = value.sources
    else return { schemaVersion: 1, sources: [], invalid: 1, recognized: false }
    const accepted = []
    let invalid = 0
    for (const source of entries) {
        if (!validSource(source)) { invalid++; continue }
        accepted.push(Object.assign({}, source))
    }
    return { schemaVersion: 1, sources: accepted, invalid: invalid, recognized: true }
}
