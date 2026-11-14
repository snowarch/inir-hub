pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import "../corner"
import "../state"

// The Media Corner: a Place to find any anime (AniList), film or series (Cinemeta), browse each by what is popular,
// top rated, in season, by year or by genre, and see where it streams officially. Panel.qml puts it over the desktop or
// in a window. Where you are lives in CornerState, so closing it loses nothing. Escape steps back, then closes.
CornerBody {
    id: root
    // The place, or "search" while the field holds something and no shelf's «See all» is open.
    readonly property string page: CornerState.query.length > 0 && !CornerState.place.includes(":search") ? "search" : CornerState.place

    open: CornerState.open
    onCloseRequested: CornerState.open = false
    section: root.page
    searchHint: Translation.tr("Search anime, films and series")
    places: [
        { id: "home", title: "Home", icon: "home" },
        { id: "anime:popular", title: "Popular anime", icon: "local_fire_department", caption: "Anime" },
        { id: "anime:airing", title: "Airing now", icon: "live_tv" },
        { id: "anime:trending", title: "Trending", icon: "trending_up" },
        { id: "anime:top", title: "Top anime", icon: "star" },
        { id: "anime:season", title: "This season", icon: "eco" },
        { id: "anime:genres", title: "Anime genres", icon: "category" },
        { id: "movie:movies", title: "Films", icon: "movie", caption: "Films and series" },
        { id: "movie:series", title: "Series", icon: "tv" },
        { id: "movie:top", title: "Top films and series", icon: "star" },
        { id: "movie:years", title: "By year", icon: "calendar_month" },
        { id: "movie:genres", title: "Film and series genres", icon: "category" },
        { id: "sources", title: "Sources", icon: "extension", caption: "Watching" }
    ]

    AnimeData { id: animeData }
    MovieData { id: movieData }

    // The season This season shows, and the year By year shows; ‹ › walk them.
    readonly property var seasons: ["WINTER", "SPRING", "SUMMER", "FALL"]
    property string season: animeData.currentSeason()
    property int seasonYear: new Date().getFullYear()
    property int year: new Date().getFullYear()
    function step(by: int): void {
        if (root.page === "movie:years") { root.year = Math.max(movieData.firstYear, Math.min(new Date().getFullYear(), root.year + by)); return }
        const index = root.seasons.indexOf(root.season) + by
        root.seasonYear += Math.floor(index / 4)
        root.season = root.seasons[((index % 4) + 4) % 4]
    }

    // What each grid place lists, from which catalogue, and what it fixes: `sort`, `kind` and `catalog` hide their picker.
    function specOf(p: string): var {
        const query = CornerState.query
        const thisSeason = root.season === animeData.currentSeason() && root.seasonYear === new Date().getFullYear()
        if (p === "anime:search") return { anime: true, title: Translation.tr("Anime called “%1”").arg(query), filter: { search: query }, pickers: false }
        if (p === "anime:popular") return { anime: true, title: Translation.tr("Popular anime"), subtitle: Translation.tr("The most followed on AniList"), filter: {}, sort: "POPULARITY_DESC" }
        if (p === "anime:airing") return { anime: true, title: Translation.tr("Airing now"), subtitle: Translation.tr("What airs this week, the most watched first"), filter: { status: "RELEASING" } }
        if (p === "anime:trending") return { anime: true, title: Translation.tr("Trending"), subtitle: Translation.tr("What people are watching right now"), filter: {}, sort: "TRENDING_DESC" }
        if (p === "anime:top") return { anime: true, title: Translation.tr("Top anime"), subtitle: Translation.tr("The best scored on AniList"), filter: {}, sort: "SCORE_DESC" }
        if (p === "anime:season") return { anime: true, stepper: true, title: Translation.tr("%1 %2").arg(Translation.tr(animeData.seasonName(root.season))).arg(root.seasonYear),
            subtitle: thisSeason ? Translation.tr("This season's shows") : Translation.tr("Another season"), filter: { season: root.season, year: root.seasonYear } }
        if (p.startsWith("anime:genre:")) { const g = p.slice(12); return { anime: true, title: Translation.tr(g), subtitle: Translation.tr("Anime genre"), filter: { genre: g } } }
        if (p.startsWith("movie:search:")) { const kind = p.slice(13); return { title: Translation.tr("“%1”").arg(query), subtitle: kind === "series" ? Translation.tr("Series") : Translation.tr("Films"), filter: { kind, search: query }, pickers: false } }
        if (p === "movie:movies") return { title: Translation.tr("Films"), subtitle: Translation.tr("The most watched right now"), filter: {}, kind: "movie" }
        if (p === "movie:series") return { title: Translation.tr("Series"), subtitle: Translation.tr("The most watched right now"), filter: {}, kind: "series" }
        if (p === "movie:top") return { title: Translation.tr("Top films and series"), subtitle: Translation.tr("The best scored on IMDb"), filter: {}, catalog: "imdbRating" }
        if (p === "movie:years") return { stepper: true, title: String(root.year), subtitle: Translation.tr("Released that year"), filter: { catalog: "year", genre: String(root.year) } }
        if (p.startsWith("movie:genre:")) {
            const g = p.slice(12), spec = { title: Translation.tr(g), subtitle: Translation.tr("Genre"), filter: { genre: g } }
            if (movieData.seriesOnly.includes(g)) spec.kind = "series"
            return spec
        }
        return null
    }
    readonly property var pageSpec: {
        const spec = root.specOf(root.page)
        if (spec) spec.place = root.page
        return spec
    }

    // Built when it first opens (LazyLoader): it is already open then, so opening runs on completion too.
    function opened(): void {
        if (!root.column) root.nav.search.focusField()
    }
    onOpenChanged: if (root.open) root.opened()
    Timer { id: openedLater; interval: 0; onTriggered: root.opened() }
    Component.onCompleted: if (root.open) openedLater.restart()

    // AniList's genres, asked when their page is first opened.
    property var animeGenres: []
    function askGenres(): void {
        if (root.page !== "anime:genres" || root.animeGenres.length > 0) return
        animeData.genres((list, error) => { if (!error) root.animeGenres = list })
    }
    onPageChanged: root.askGenres()
    Connections {
        target: CornerState
        function onAttemptChanged(): void { root.askGenres() }
    }

    readonly property int closeRoom: root.windowed ? 0 : Math.round(40 * root.d)

    // A page is built when first shown and then kept, with its scroll and its pickers.
    component Page: Loader {
        property bool shown: false
        property bool seen: false
        onShownChanged: if (shown) seen = true
        Component.onCompleted: if (shown) seen = true
        active: seen
        visible: shown && CornerState.show === null && !CornerState.sheet
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
    }
    // One grid per catalogue, so each keeps its own list and pickers. A hidden one holds its last place and asks nothing.
    component GridPage: Page {
        id: gridPage
        required property bool anime
        readonly property var here: root.pageSpec !== null && Boolean(root.pageSpec.anime) === gridPage.anime ? root.pageSpec : null
        property var spec: gridPage.here
        onHereChanged: if (gridPage.here) gridPage.spec = gridPage.here
        shown: gridPage.here !== null
        sourceComponent: MediaGrid {
            store: gridPage.anime ? animeData : movieData
            spec: gridPage.spec
            onStep: by => root.step(by)
        }
    }

    Page {
        shown: root.page === "home"
        sourceComponent: MediaHome { anime: animeData; movies: movieData }
    }
    Page {
        shown: root.page === "search"
        sourceComponent: MediaSearch { anime: animeData; movies: movieData; query: CornerState.query }
    }
    GridPage { anime: true }
    GridPage { anime: false }
    Page {
        shown: root.page === "anime:genres" || root.page === "movie:genres"
        sourceComponent: MediaTiles {
            readonly property bool anime: root.page === "anime:genres"
            title: anime ? Translation.tr("Anime genres") : Translation.tr("Film and series genres")
            subtitle: anime ? Translation.tr("Every genre on AniList") : Translation.tr("Every genre on Cinemeta")
            names: anime ? root.animeGenres : movieData.genreNames
            failed: anime ? animeData.down : ""
            emptyText: Translation.tr("Loading…")
            onPicked: name => CornerState.pick(root.page.slice(0, 6) + "genre:" + name)
        }
    }
    Page { shown: root.page === "sources"; sourceComponent: MediaSources {} }
    Loader {
        property bool seen: false
        readonly property bool shown: CornerState.show !== null
        onShownChanged: if (shown) seen = true
        Component.onCompleted: if (shown) seen = true
        active: seen
        visible: shown && !CornerState.sheet
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
        sourceComponent: MediaDetail {
            compact: root.column
            anime: animeData
            movies: movieData
            // A link opens in the browser: the overlay gets out of its way. A window sits beside it.
            onFollowed: if (!root.windowed) CornerState.open = false
        }
    }
    Loader {
        active: CornerState.sheet
        z: 5
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
        sourceComponent: MediaWatchSheet {
            onFollowed: if (!root.windowed) CornerState.open = false
        }
    }
}
