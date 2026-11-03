pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style
import qs.modules.iris.state
import qs.modules.iris.pieces
import qs.modules.iris.corner

// The Anime Corner: a Place to find any show on AniList, browse it by what is popular, trending, in season or by
// genre, and pick up what the Airing and Continue bubbles know. It has Settings' body, in Settings' layout and host
// (corner/IrisCornerBody); ShellIrisPanelsImpl puts it over the desktop or in a window. Escape steps back, then closes.
IrisCornerBody {
    id: root
    // Where you are: a place, "genre:<name>", or "search" while the field holds something.
    property string place: "home"
    property string query: ""
    readonly property string page: root.query.length > 0 ? "search" : root.place

    open: IrisState.animeCornerOpen
    onCloseRequested: IrisState.animeCornerOpen = false
    section: root.page === "search" ? "search" : root.place
    searchHint: Translation.tr("Search any anime")
    deeper: root.detail !== null
    onStepOut: root.detail = null
    onPicked: id => { root.place = id; root.nav.search.clear() }
    onSearched: text => root.query = text
    places: [
        { id: "home", title: "Home", icon: "home", tint: IrisStyle.identity.pink },
        { id: "continue", title: "Continue watching", icon: "play_circle", tint: IrisStyle.identity.orange },
        { id: "following", title: "Following", icon: "bookmark", tint: IrisStyle.identity.red },
        { id: "popular", title: "Popular", icon: "local_fire_department", tint: IrisStyle.identity.yellow, caption: "Browse" },
        { id: "trending", title: "Trending", icon: "trending_up", tint: IrisStyle.identity.green },
        { id: "top", title: "Top rated", icon: "star", tint: IrisStyle.identity.teal },
        { id: "season", title: "This season", icon: "eco", tint: IrisStyle.identity.sky },
        { id: "calendar", title: "Calendar", icon: "calendar_month", tint: IrisStyle.identity.blue },
        { id: "genres", title: "Genres", icon: "category", tint: IrisStyle.identity.purple }
    ]
    badges: ({ continue: root.watching.length, following: IrisPieces.animeFollowing.length })

    AnimeCornerData { id: cornerData }
    property var genres: []

    // ani-cli's history as posters: its cover, the episode it is on and how far into it.
    readonly property var watching: (AnimeWatch.shows ?? []).map(entry => {
        const state = AnimeWatch.stateOf(entry)
        return { watch: entry, id: 0, title: String(entry.title ?? ""), image: AnimeWatch.coverOf(entry),
            episode: state.episode || String(entry.episode ?? ""), progress: Number(state.progress ?? 0) }
    })
    // A poster opens its show. One from the history opens too (to pick another episode): it is looked up on AniList by
    // its title and keeps its history entry, so Continue and the episodes stay on what ani-cli played.
    function openShow(show): void {
        if (!show) return
        root.detail = show
        if (root.column) root.pushed = true
        if (show.watch === undefined || Number(show.id ?? 0) > 0) return
        const watch = show.watch
        cornerData.page({ search: String(watch.title ?? "") }, 1, (result, error) => {
            const found = error ? null : (result?.items ?? [])[0]
            if (found && root.detail?.watch === watch) root.detail = Object.assign({}, found, { watch: watch })
        })
    }
    function takeQuery(): void {
        const place = IrisState.animeCornerPlace
        if (place.length > 0) {
            IrisState.animeCornerPlace = ""
            if (place.startsWith("anime:")) root.openShow({ id: Number(place.slice(6)) })
            else { root.nav.search.clear(); root.place = place; root.pushed = true }
        }
        if (IrisState.animeCornerQuery.length === 0) return
        root.nav.search.type(IrisState.animeCornerQuery)
        IrisState.animeCornerQuery = ""
    }
    Connections { target: IrisState; function onAnimeCornerQueryChanged(): void { if (root.open) root.takeQuery() }
        function onAnimeCornerPlaceChanged(): void { if (root.open) root.takeQuery() } }
    // The show open in full over the page; null shows the page.
    property var detail: null
    onPlaceChanged: root.detail = null
    onQueryChanged: root.detail = null

    // The season This season shows; ‹ › walk it, the Corner's own (AnimeService's belongs to the Material shell).
    readonly property var seasons: ["WINTER", "SPRING", "SUMMER", "FALL"]
    property string season: AnimeService.getCurrentSeason()
    property int seasonYear: new Date().getFullYear()
    function stepSeason(by: int): void {
        const index = root.seasons.indexOf(root.season) + by
        root.seasonYear += Math.floor(index / 4)
        root.season = root.seasons[((index % 4) + 4) % 4]
    }

    // What each place lists; the grid asks AniList for it.
    readonly property var pageSpec: {
        const p = root.page
        const season = root.season
        const year = root.seasonYear
        if (p === "search") return { title: Translation.tr("Results for “%1”").arg(root.query), filter: { search: root.query }, pickers: false }
        if (p === "popular") return { title: Translation.tr("Popular"), subtitle: Translation.tr("The most watched on AniList, of all time"), filter: {}, sort: "POPULARITY_DESC" }
        if (p === "trending") return { title: Translation.tr("Trending"), subtitle: Translation.tr("What people are watching right now"), filter: {}, sort: "TRENDING_DESC" }
        if (p === "top") return { title: Translation.tr("Top rated"), subtitle: Translation.tr("The best scored on AniList"), filter: {}, sort: "SCORE_DESC" }
        if (p === "season") return { title: Translation.tr("%1 %2").arg(Translation.tr(AnimeService.getSeasonDisplayName(season))).arg(year), subtitle: root.season === AnimeService.getCurrentSeason() && root.seasonYear === new Date().getFullYear() ? Translation.tr("This season's shows") : Translation.tr("Another season"), filter: { season, year }, sort: "POPULARITY_DESC" }
        if (p === "following") return { title: Translation.tr("Following"), subtitle: Translation.tr("The shows you follow, also in the Airing bubble"), filter: { ids: IrisPieces.animeFollowing.length > 0 ? IrisPieces.animeFollowing : [-1] }, pickers: false }
        if (p.startsWith("genre:")) { const g = p.slice(6); return { title: Translation.tr(g), subtitle: Translation.tr("Genre"), filter: { genre: g }, sort: "POPULARITY_DESC" } }
        if (p === "continue") return { title: Translation.tr("Continue watching"), subtitle: Translation.tr("From ani-cli's history: a poster opens the show, its episodes and where you were"), filter: {}, local: root.watching, pickers: false }
        return { title: Translation.tr("Airing now"), subtitle: Translation.tr("What airs this week, the most watched first"), filter: { status: "RELEASING" }, sort: "POPULARITY_DESC" }
    }

    // Built when it first opens (OnDemandPanelLoader): it is already open then, so opening runs on completion too.
    function opened(): void {
        if (!root.column) root.nav.search.focusField()
        AnimeWatch.reload()
        root.takeQuery()
        if (root.genres.length === 0) cornerData.genres((list, error) => { if (!error) root.genres = list })
    }
    onOpenChanged: if (root.open) root.opened()
    Component.onCompleted: if (root.open) Qt.callLater(root.opened)

    readonly property int closeRoom: Math.round(40 * root.d)

    AnimeHome {
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
        visible: root.page === "home" && !root.detail
        store: cornerData
        watching: root.watching
        onOpenShow: show => root.openShow(show)
        onOpenSection: id => root.pick(id)
    }
    AnimeGrid {
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
        visible: !["home", "calendar", "genres"].includes(root.page) && !root.detail
        seasonNav: root.page === "season"
        onStepSeason: by => root.stepSeason(by)
        local: root.pageSpec.local ?? null
        store: cornerData
        title: root.pageSpec.title
        subtitle: root.pageSpec.subtitle ?? ""
        filter: root.pageSpec.filter
        pickers: (root.pageSpec.pickers ?? true) && !root.column
        sort: root.pageSpec.sort ?? "POPULARITY_DESC"
        onOpenShow: show => root.openShow(show)
    }
    IrisCornerTiles {
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
        visible: root.page === "genres" && !root.detail
        title: Translation.tr("Genres")
        subtitle: Translation.tr("Every genre on AniList")
        names: root.genres
        emptyText: Translation.tr("Loading…")
        onPicked: name => root.place = "genre:" + name
    }
    Loader {
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
        active: root.page === "calendar"
        visible: active && !root.detail
        sourceComponent: AnimeCalendar {
            store: cornerData
            onOpenShow: show => root.openShow(show)
        }
    }
    AnimeDetail {
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
        visible: root.detail !== null
        compact: root.column
        store: cornerData
        show: root.detail
        onBack: root.detail = null
        onOpenShow: show => root.openShow(show)
        onOpenSection: id => { root.place = id; root.detail = null; root.nav.search.clear() }
    }
}
