.pragma library

// Pure local watch-list and playback helpers. Persistence and UI stay in their callers.
function resetProgress(progress, key) {
    const kept = progress?.[key]
    if (!kept) return progress
    return Object.assign({}, progress, { [key]: Object.assign({}, kept, { position: 0, duration: 0 }) })
}

function toggleWatchlist(watchlist, key, show) {
    const next = Object.assign({}, watchlist ?? {})
    if (next[key]) delete next[key]
    else next[key] = { id: show.id, kind: show.kind, title: show.title, type: show.type ?? "", film: Boolean(show.film) }
    return next
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
    if (!latestEpisode || !episodes.every(episode => isSeen(keyFor(episode)))) return null
    const season = Number(latestEpisode.season)
    if (!Number.isFinite(season)) return null
    const next = groups.find(group => Number(group.episodes?.[0]?.season) === season + 1)
    return Number(next?.episodes?.[0]?.episode) === 1 ? next.episodes[0] : null
}

function updateSourceResult(results, index, error, count) {
    return (results ?? []).map((result, item) => item === index
        ? Object.assign({}, result, { state: error ? "error" : "done", count: error ? 0 : Math.max(0, Number(count) || 0) })
        : result)
}

function initialSourceResults(streamPaths, showKind, kitsu, mappingError) {
    if (mappingError) return []
    return (streamPaths ?? []).map(task => ({
        name: task.addon.name,
        state: task.path ? "waiting" : showKind === "anime" && !kitsu ? "unidentified" : "unsupported",
        count: 0
    }))
}

function sourceNames(streams) {
    return [...new Set((streams ?? []).map(stream => String(stream.source)))].sort()
}

function displayedStreams(streams, sourceFilter, sortStreams) {
    const result = (streams ?? []).filter(stream => !sourceFilter || String(stream.source) === sourceFilter)
    if (sortStreams) result.sort((a, b) => String(a.source).localeCompare(String(b.source)) || String(a.name).localeCompare(String(b.name)))
    return result
}
