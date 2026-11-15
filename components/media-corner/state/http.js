.pragma library

// Retry-After is either a number of seconds or an HTTP date, never arbitrary server text.
function retryAfter(value) {
    const text = String(value ?? "").trim()
    if (/^\d{1,8}$/.test(text)) return text
    if (text.length <= 40 && /^(Mon|Tue|Wed|Thu|Fri|Sat|Sun), \d{2} (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d{4} \d{2}:\d{2}:\d{2} GMT$/.test(text) && Number.isFinite(Date.parse(text))) return text
    return ""
}
function retryDisplay(value) {
    const text = String(value ?? "")
    return /^\d+$/.test(text) ? text + " s" : text
}
