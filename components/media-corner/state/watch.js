.pragma library

// Pure local watch-list and playback helpers. Persistence and UI stay in their callers.
function parseProgress(text) {
    const data = JSON.parse(text)
    if (!data || typeof data !== "object" || Array.isArray(data)) throw new Error("invalid progress")
    for (const value of Object.values(data)) {
        if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error("invalid progress entry")
        for (const field of ["position", "duration", "at"])
            if (value[field] !== undefined && (typeof value[field] !== "number" || !Number.isFinite(value[field]))) throw new Error("invalid progress number")
    }
    return data
}
function parseWatchlist(text) {
    const data = JSON.parse(text)
    if (!data || typeof data !== "object" || Array.isArray(data)) throw new Error("invalid watchlist")
    for (const value of Object.values(data))
        if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error("invalid watchlist entry")
    return data
}
function isSeen(progress, marks, key) {
    const mark = marks?.[key]
    if (typeof mark === "boolean") return mark
    const kept = progress?.[key]
    return Boolean(kept) && kept.duration > 0 && kept.position / kept.duration >= 0.9
}
// Count only episodes supplied by the catalogue; never assume an unlisted episode exists.
function summarizeEpisodes(episodes, progress, marks, keyFor) {
    const known = episodes ?? []
    let watched = 0, next = null
    for (const episode of known) {
        if (isSeen(progress, marks, keyFor(episode))) watched++
        else if (next === null) next = episode
    }
    return { watched, known: known.length, next }
}
function resetProgress(progress, key) {
    const kept = progress?.[key]
    if (!kept) return progress
    return Object.assign({}, progress, { [key]: Object.assign({}, kept, { position: 0, duration: 0 }) })
}

function toggleWatchlist(watchlist, key, show, addedAt) {
    const next = Object.assign({}, watchlist ?? {})
    if (next[key]) delete next[key]
    else next[key] = { id: show.id, kind: show.kind, title: show.title, type: show.type ?? "", film: Boolean(show.film), addedAt: Number(addedAt) || 0 }
    return next
}

// Old saved entries have no added date; they sort after entries with a known date.
function sortedSavedKeys(watchlist, progress, order) {
    const list = watchlist ?? {}, activity = {}
    for (const entry of Object.values(progress ?? {})) {
        if (!entry?.show) continue
        const id = String(entry.show.kind) + ":" + String(entry.show.id)
        activity[id] = Math.max(activity[id] ?? 0, Number(entry.at) || 0)
    }
    return Object.keys(list).sort((a, b) => {
        const first = list[a], second = list[b]
        const at = show => order === "added" ? Number(show?.addedAt) || 0
            : order === "activity" ? activity[String(show?.kind) + ":" + String(show?.id)] ?? 0 : 0
        return at(second) - at(first) || String(first?.title ?? "").localeCompare(String(second?.title ?? "")) || a.localeCompare(b)
    })
}

// Group every history entry by provider kind and id, without merging unrelated works.
function historyRows(progress) {
    const groups = {}
    for (const [key, entry] of Object.entries(progress ?? {})) {
        if (!entry?.show || entry.show.id === undefined || !entry.show.kind) continue
        const id = String(entry.show.kind) + ":" + String(entry.show.id)
        if (!groups[id]) groups[id] = { show: entry.show, entries: [], at: 0 }
        groups[id].entries.push({ key, entry })
        groups[id].at = Math.max(groups[id].at, Number(entry.at) || 0)
    }
    const rows = []
    for (const group of Object.values(groups).sort((a, b) => b.at - a.at || String(a.show.title ?? "").localeCompare(String(b.show.title ?? "")))) {
        rows.push({ heading: true, title: String(group.show.title ?? "") })
        group.entries.sort((a, b) => (Number(b.entry.at) || 0) - (Number(a.entry.at) || 0) || a.key.localeCompare(b.key))
        for (const item of group.entries) rows.push({ heading: false, key: item.key, episode: item.entry.episode ?? null })
    }
    return rows
}

// Match locally, including the translated kind and format supplied by the caller.
function matchesSaved(show, query, labels) {
    const needle = String(query ?? "").trim().toLocaleLowerCase()
    if (!needle) return true
    if (!show) return false
    return [show.title, show.kind, show.type].concat(labels ?? []).some(value =>
        String(value ?? "").toLocaleLowerCase().includes(needle))
}

// Start at the most recently active episode. Continue to another season only when
// every listed episode is seen and the immediately following season starts at 1.
function nextUnseen(groups, progress, keyFor, isSeen, fallbackGroup) {
    if (!Array.isArray(groups) || groups.length === 0) return null
    let latestGroup = null, latestEpisode = null, latestAt = 0
    for (const group of groups) {
        for (const episode of group.episodes ?? []) {
            const kept = progress?.[keyFor(episode)]
            if (kept && Number(kept.at) > latestAt) {
                latestGroup = group
                latestEpisode = episode
                latestAt = Number(kept.at)
            }
        }
    }
    const episodes = latestGroup?.episodes ?? groups[fallbackGroup]?.episodes ?? groups[0]?.episodes ?? []
    const start = latestEpisode ? episodes.indexOf(latestEpisode) : 0
    const pending = episodes.slice(Math.max(0, start)).find(episode => !isSeen(keyFor(episode)))
    if (pending) return pending
    const earlier = episodes.slice(0, Math.max(0, start)).find(episode => !isSeen(keyFor(episode)))
    if (earlier) return earlier
    if (!episodes.length || !episodes.every(episode => isSeen(keyFor(episode)))) return null
    const season = Number((latestEpisode ?? episodes[episodes.length - 1]).season)
    if (!Number.isFinite(season)) return null
    const next = groups.find(group => Number(group.episodes?.[0]?.season) === season + 1)
    return Number(next?.episodes?.[0]?.episode) === 1 ? next.episodes[0] : null
}

function updateSourceResult(results, index, error, count, retryAfter) {
    return (results ?? []).map((result, item) => item === index
        ? Object.assign({}, result, { state: error === "busy" ? "limited" : error ? "error" : "done", retryAfter: retryAfter || "", count: error ? 0 : Math.max(0, Number(count) || 0) })
        : result)
}

function initialSourceResults(streamPaths, showKind, kitsu, mappingError) {
    if (mappingError) return []
    return (streamPaths ?? []).map(task => ({
        name: String(task.addon.alias || task.addon.name),
        state: task.path ? "waiting" : showKind === "anime" && !kitsu ? "unidentified" : "unsupported",
        count: 0
    }))
}

function insertSourceStreams(existing, found, sourceIndex, sourceName) {
    const result = (existing ?? []).slice()
    const position = result.findIndex(s => s.sourceIndex > sourceIndex)
    result.splice(position < 0 ? result.length : position, 0,
        ...(found ?? []).map(s => Object.assign({}, s, { source: sourceName, sourceIndex })))
    return result
}

function sourceNames(streams) {
    return [...new Set((streams ?? []).map(stream => String(stream.source)))].sort()
}

function displayedStreams(streams, sourceFilter, sortStreams) {
    const result = (streams ?? []).filter(stream => !sourceFilter || String(stream.source) === sourceFilter)
    if (sortStreams) result.sort((a, b) => String(a.source).localeCompare(String(b.source)) || String(a.name).localeCompare(String(b.name)))
    return result
}
