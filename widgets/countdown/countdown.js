.pragma library

// The logic all three faces share. A face only decides how it looks; what it says comes from here,
// so Material, iRiS and Waffle never disagree about how long is left.

// "2026-12-24" or "2026-12-24T18:30", read in local time. Anything else is null.
function parse(text) {
    const match = /^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2}))?$/.exec(String(text || "").trim())
    if (!match)
        return null
    const date = new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]), Number(match[4] || 0), Number(match[5] || 0))
    return isNaN(date.getTime()) || date.getDate() !== Number(match[3]) ? null : date
}

function hasTime(text) {
    return /[T ]\d{2}:\d{2}$/.test(String(text || "").trim())
}

// The date under the figure. The words on this card are English, so the date is too: one card never
// mixes two languages, whatever the system locale says.
function dateLine(target, text) {
    if (!target)
        return ""
    return Qt.locale("en_US").toString(target, hasTime(text) ? "ddd d MMM yyyy · HH:mm" : "dddd d MMMM yyyy")
}

// Calendar days between two moments, so 23:00 today to 09:00 tomorrow is one day, not zero.
function calendarDays(from, to) {
    const day = d => new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()
    return Math.round((day(to) - day(from)) / 86400000)
}

// What to show: a figure, its unit, and whether the moment has passed.
//   { valid, past, figure, unit }
function describe(target, now) {
    if (!target)
        return { valid: false, past: false, figure: "", unit: "" }
    const ms = target.getTime() - now.getTime()
    const days = calendarDays(now, target)
    if (days === 0 && ms > 0) {
        // Later today: hours and minutes are what matter.
        const minutes = Math.ceil(ms / 60000)
        const h = Math.floor(minutes / 60)
        return { valid: true, past: false, figure: h > 0 ? `${h}h ${minutes % 60}m` : `${minutes}m`, unit: "left" }
    }
    if (days === 0)
        return { valid: true, past: true, figure: "Today", unit: "" }
    const n = Math.abs(days)
    return { valid: true, past: days < 0, figure: String(n), unit: (n === 1 ? "day" : "days") + (days < 0 ? " ago" : "") }
}
