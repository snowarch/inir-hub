.pragma library

// Everything the four faces say comes from here: which account is shown, how many days fit in the
// grid, how busy each one was and what the numbers under it are. Faces only decide how it looks, so
// Material, its sidebars, the Island and Waffle never disagree.

const PROVIDERS = ["github", "gitlab", "forgejo"]
const DAY = 86400000

// ── The account ─────────────────────────────────────────────────────────────

// "github.com/you", "forgejo:codeberg.org/you", "gitlab:gitlab.example.com/you". A provider in front
// is needed only where the host does not say which platform it is.
function parseAccount(text) {
    let line = String(text || "").trim()
    if (line.length === 0)
        return null
    let provider = ""
    const colon = line.indexOf(":")
    if (colon > 0 && line.slice(0, colon).indexOf("/") < 0) {
        provider = line.slice(0, colon).toLowerCase()
        line = line.slice(colon + 1)
    }
    line = line.replace(/^\/+/, "").replace(/^https?:\/\//, "").replace(/\/+$/, "")
    const slash = line.indexOf("/")
    if (slash <= 0 || slash === line.length - 1)
        return null
    const host = line.slice(0, slash).trim()
    const user = line.slice(slash + 1).trim().replace(/^@/, "")
    if (!/^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?(:[0-9]{1,5})?$/.test(host))
        return null
    if (!/^[A-Za-z0-9_][A-Za-z0-9_.@-]*$/.test(user) || user.length > 64)
        return null
    if (provider === "gitea")
        provider = "forgejo"
    if (PROVIDERS.indexOf(provider) < 0)
        provider = host === "github.com" ? "github" : host === "gitlab.com" ? "gitlab" : "forgejo"
    return { provider: provider, host: host, user: user }
}

function key(account) {
    return account ? [account.provider, account.host, account.user].join(" ") : ""
}

// What the person typed wins; with nothing typed, the first account their own CLIs are logged in to.
function account(text, discovered) {
    const typed = parseAccount(text)
    if (typed)
        return typed
    const first = Array.isArray(discovered) ? discovered.find(one => one && one.provider && one.host && one.user) : null
    return first ? { provider: first.provider, host: first.host, user: first.user } : null
}

function isGithub(account) {
    return !!account && account.provider === "github"
}

// The glyph each platform is known by in the shell's icon set.
function platformGlyph(account) {
    if (!account)
        return "code"
    if (account.provider === "github")
        return "code"
    if (account.provider === "gitlab")
        return "merge"
    return "account_tree"
}

// What to call the platform on a card: a proper name, never translated.
function platformName(account) {
    if (!account)
        return ""
    if (account.provider === "github")
        return account.host === "github.com" ? "GitHub" : "GitHub " + account.host
    if (account.provider === "gitlab")
        return "GitLab"
    return account.host === "codeberg.org" ? "Codeberg" : "Forgejo"
}

// ── Days ────────────────────────────────────────────────────────────────────

function startOfDay(value) {
    const date = value instanceof Date ? value : new Date(value)
    return new Date(date.getFullYear(), date.getMonth(), date.getDate())
}

function addDays(date, days) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate() + days)
}

function iso(date) {
    const two = number => (number < 10 ? "0" : "") + number
    return date.getFullYear() + "-" + two(date.getMonth() + 1) + "-" + two(date.getDate())
}

// How much of the busiest day one day is, in the five steps a grid reads as.
function level(count, max) {
    if (!(count > 0))
        return 0
    if (!(max > 1))
        return 4
    const share = count / max
    return share >= 0.75 ? 4 : share >= 0.5 ? 3 : share >= 0.25 ? 2 : 1
}

// The grid: one column per week, Sunday on top, the last column the week today is in. Days after
// today are marked `future` and drawn as nothing.
function grid(days, weeks, today) {
    const counts = days && typeof days === "object" ? days : {}
    const end = startOfDay(today || new Date())
    const span = Math.max(4, Math.min(53, Math.floor(Number(weeks) || 26)))
    const first = addDays(end, -end.getDay() - (span - 1) * 7)
    const columns = []
    let max = 0
    for (let week = 0; week < span; week++) {
        const column = []
        for (let day = 0; day < 7; day++) {
            const date = addDays(first, week * 7 + day)
            const key = iso(date)
            const raw = Number(counts[key] || 0)
            const count = isFinite(raw) && raw > 0 ? Math.floor(raw) : 0
            if (count > max)
                max = count
            column.push({ key: key, count: count, level: 0, future: date.getTime() > end.getTime() })
        }
        columns.push(column)
    }
    for (let week = 0; week < columns.length; week++) {
        for (let day = 0; day < columns[week].length; day++)
            columns[week][day].level = level(columns[week][day].count, max)
    }
    return { columns: columns, max: max, weeks: span }
}

// The grid, and the numbers under it: the sum, how many days were worked, the streak that is still
// going, the longest one, and the busiest day.
function summary(days, weeks, today) {
    const drawn = grid(days, weeks, today)
    const flat = []
    let total = 0
    let active = 0
    let longest = 0
    let run = 0
    let busiest = null
    for (let week = 0; week < drawn.columns.length; week++) {
        for (let day = 0; day < drawn.columns[week].length; day++) {
            const cell = drawn.columns[week][day]
            flat.push(cell)
            if (cell.future)
                continue
            total += cell.count
            if (cell.count > 0) {
                active += 1
                run += 1
                if (run > longest)
                    longest = run
                if (!busiest || cell.count > busiest.count)
                    busiest = { key: cell.key, count: cell.count }
            } else {
                run = 0
            }
        }
    }
    // A streak that is still going runs back from today; a quiet today does not end the one that
    // ended yesterday, so it is skipped rather than counted as a break.
    let current = 0
    const todayKey = iso(startOfDay(today || new Date()))
    for (let index = flat.length - 1; index >= 0; index--) {
        const cell = flat[index]
        if (cell.future)
            continue
        if (cell.count > 0) {
            current += 1
            continue
        }
        if (cell.key === todayKey)
            continue
        break
    }
    return {
        grid: drawn,
        max: drawn.max,
        total: total,
        active: active,
        current: current,
        longest: longest,
        busiest: busiest
    }
}

// The day under a point of the drawn grid, for the line that reads out what is hovered.
function cellAt(drawn, x, y, size, gap) {
    if (!drawn || !drawn.columns || drawn.columns.length === 0)
        return null
    const step = size + gap
    if (!(step > 0))
        return null
    const week = Math.floor(x / step)
    const day = Math.floor(y / step)
    if (week < 0 || week >= drawn.columns.length || day < 0 || day >= 7)
        return null
    return drawn.columns[week][day]
}

// ── Weeks, the month and today ──────────────────────────────────────────────

// Weekly totals, oldest first, the last one the week today is in: the bars of the Weeks look.
function weeks(days, count, today) {
    const map = days && typeof days === "object" ? days : {}
    const end = startOfDay(today || new Date())
    const span = Math.max(2, Math.min(53, Math.floor(Number(count) || 12)))
    const first = addDays(end, -end.getDay() - (span - 1) * 7)
    const out = []
    let max = 0
    for (let week = 0; week < span; week++) {
        const start = addDays(first, week * 7)
        let total = 0
        for (let day = 0; day < 7; day++) {
            const date = addDays(start, day)
            if (date.getTime() > end.getTime())
                continue
            const raw = Number(map[iso(date)] || 0)
            total += isFinite(raw) && raw > 0 ? Math.floor(raw) : 0
        }
        if (total > max)
            max = total
        out.push({ key: iso(start), count: total, current: week === span - 1 })
    }
    for (let index = 0; index < out.length; index++)
        out[index].level = level(out[index].count, max)
    return { weeks: out, max: max }
}

// This calendar month as a sheet of weeks, Sunday first: the days of the month filled in, the days
// before it and after it left empty.
function month(days, today) {
    const map = days && typeof days === "object" ? days : {}
    const now = startOfDay(today || new Date())
    const first = new Date(now.getFullYear(), now.getMonth(), 1)
    const length = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
    const cells = []
    let max = 0
    let total = 0
    let active = 0
    for (let lead = 0; lead < first.getDay(); lead++)
        cells.push(null)
    for (let day = 1; day <= length; day++) {
        const date = new Date(now.getFullYear(), now.getMonth(), day)
        const raw = Number(map[iso(date)] || 0)
        const count = isFinite(raw) && raw > 0 ? Math.floor(raw) : 0
        const future = date.getTime() > now.getTime()
        if (count > max)
            max = count
        if (!future) {
            total += count
            if (count > 0)
                active += 1
        }
        cells.push({ key: iso(date), day: day, count: count, level: 0, today: day === now.getDate(), future: future })
    }
    while (cells.length % 7 !== 0)
        cells.push(null)
    for (let index = 0; index < cells.length; index++) {
        if (cells[index])
            cells[index].level = level(cells[index].count, max)
    }
    return { cells: cells, rows: cells.length / 7, total: total, active: active, max: max,
        name: Qt.locale().toString(first, "MMMM"), year: first.getFullYear(), weekday: (day) => Qt.locale().dayName((day + 1) % 7, Qt.locale().ShortFormat) }
}

// Today's count and the week so far: what the Today look puts in its shape.
function todayReading(days, today) {
    const map = days && typeof days === "object" ? days : {}
    const now = startOfDay(today || new Date())
    const count = counted(map, iso(now))
    const start = addDays(now, -now.getDay())
    let week = 0
    let worked = 0
    for (let day = 0; day <= now.getDay(); day++) {
        const value = counted(map, iso(addDays(start, day)))
        week += value
        if (value > 0)
            worked += 1
    }
    return { key: iso(now), count: count, week: week, worked: worked, day: Qt.locale().toString(now, "dddd d MMM") }
}

function counted(map, key) {
    const raw = Number(map[key] || 0)
    return isFinite(raw) && raw > 0 ? Math.floor(raw) : 0
}

// ── Words ───────────────────────────────────────────────────────────────────

// Thousands, without a locale that would put the separators somewhere else than the rest reads.
function number(value) {
    const amount = Math.round(Number(value) || 0)
    const text = String(Math.abs(amount))
    let out = ""
    for (let index = 0; index < text.length; index++) {
        if (index > 0 && (text.length - index) % 3 === 0)
            out += ","
        out += text[index]
    }
    return (amount < 0 ? "-" : "") + out
}

function dayWords(key) {
    const parts = String(key || "").split("-")
    if (parts.length !== 3)
        return ""
    const date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]))
    if (isNaN(date.getTime()))
        return ""
    return Qt.locale().toString(date, "ddd d MMM")
}

// What the helper said, in words a person can act on.
function errorWord(code) {
    switch (String(code || "").trim()) {
    case "no-jq":
        return "Dev Stats needs jq to read the numbers, and it is not installed"
    case "no-cli":
        return "This platform's command line tool is not installed"
    case "request-failed":
        return "The platform did not answer"
    case "bad-account":
        return "Write the account as host/user, like github.com/you"
    case "no-helper":
        return "Dev Stats' helper script is missing"
    case "bad-command":
        return "Dev Stats' helper was called with something it does not do"
    default:
        return "Dev Stats could not read the numbers"
    }
}
