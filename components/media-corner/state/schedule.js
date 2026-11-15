.pragma library

function savedIds(watchlist) {
    return Object.values(watchlist ?? {}).filter(show => show?.kind === "anime" && !show.film)
        .map(show => Number(show.id)).filter(id => Number.isInteger(id) && id > 0 && id <= 2147483647)
}

function upcoming(media, now) {
    return (media ?? []).filter(show => show?.format !== "MOVIE" && Number(show?.nextAiringEpisode?.airingAt) > now
        && Number(show?.nextAiringEpisode?.episode) > 0)
        .map(show => ({ id: show.id, title: String(show.title?.english ?? show.title?.romaji ?? ""),
            airingAt: Number(show.nextAiringEpisode.airingAt), episode: Number(show.nextAiringEpisode.episode) }))
        .sort((a, b) => a.airingAt - b.airingAt || a.episode - b.episode || a.title.localeCompare(b.title))
}
