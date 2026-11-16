pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import "schedule.js" as Schedule

// What airs next for the saved anime: asked of AniList only while the page shows it, 50 titles a request, never
// polled. `active` is the page being on screen; leaving it drops the request in flight.
Singleton {
    id: root
    property bool active: false
    property bool loading: false
    property string failure: ""
    property var entries: []
    property int checkedAt: 0

    property var _ids: []
    property var _collected: []
    property int _offset: 0
    property var _waiting: null

    function cancel(): void {
        if (root._waiting) { CornerState.cancelAsk(root._waiting); root._waiting = null }
        root.loading = false
    }
    function refresh(): void {
        if (!root.active) return
        root.cancel()
        root.entries = []
        root.failure = ""
        root.checkedAt = 0
        if (!CornerWatch.watchlistLoaded) {
            root.failure = CornerWatch.watchlistLoadFailed ? Translation.tr("Could not load saved titles") : ""
            root.loading = !CornerWatch.watchlistLoadFailed
            return
        }
        root._ids = Schedule.savedIds(CornerWatch.watchlist)
        root._collected = []
        root._offset = 0
        if (!root._ids.length) return
        root.loading = true
        root._askBatch()
    }
    function _askBatch(): void {
        if (!root.active || !root.loading) return
        const batch = root._ids.slice(root._offset, root._offset + 50)
        if (!batch.length) {
            root.entries = Schedule.upcoming(root._collected, Math.floor(Date.now() / 1000))
            root.checkedAt = Math.floor(Date.now() / 1000)
            root.loading = false
            return
        }
        const query = "query ($ids: [Int]) { Page(page: 1, perPage: 50) { media(id_in: $ids, type: ANIME, isAdult: false) { id format title { english romaji } nextAiringEpisode { airingAt episode } } } }"
        const callback = (media, error, retryAfter) => {
            if (root._waiting !== callback) return
            root._waiting = null
            if (!root.active) return
            if (error) {
                root.failure = error === "busy" ? CornerState.limitedText(retryAfter ?? "") : Translation.tr("Could not load the schedule")
                root.loading = false
                return
            }
            root._collected = root._collected.concat(media)
            root._offset += batch.length
            root._askBatch()
        }
        root._waiting = callback
        // A refresh is asked for: it always goes to AniList, never to an answer kept from before.
        CornerState.ask("https://graphql.anilist.co", JSON.stringify({ query, variables: { ids: batch } }), reply => {
            if (reply?.errors || !Array.isArray(reply?.data?.Page?.media)) throw new Error("invalid response")
            return reply.data.Page.media
        }, callback, true)
    }
    onActiveChanged: if (root.active) root.refresh(); else root.cancel()
    Connections {
        target: CornerWatch
        function onWatchlistLoadedChanged(): void { if (root.active && CornerWatch.watchlistLoaded) root.refresh() }
        function onWatchlistLoadFailedChanged(): void { if (root.active && CornerWatch.watchlistLoadFailed) root.refresh() }
    }
    Connections {
        target: CornerState
        function onOpenChanged(): void { if (!CornerState.open) root.active = false }
    }
}
