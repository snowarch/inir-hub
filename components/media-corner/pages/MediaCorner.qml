pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.services.deferred
import qs.modules.iris.style
import "../corner"
import "../state"

// The Media Corner: a Place to find any anime (AniList), film or series (Cinemeta), browse each by what is popular,
// top rated, in season, by year or by genre, and see where it streams officially. It has Settings' shape
// (corner/IrisCornerBody); Panel.qml puts it over the desktop or in a window. Escape steps back, then closes.
IrisCornerBody {
    id: root
    // Where you are: a place ("anime:popular", "movie:genre:Drama"…), or "search" while the field holds something.
    property string place: "home"
    property string query: ""
    readonly property string page: root.query.length > 0 && !root.place.includes(":search") ? "search" : root.place

    open: CornerState.open
    onCloseRequested: CornerState.open = false
    section: root.page
    searchHint: Translation.tr("Search anime, films and series")
    deeper: root.detail !== null
    onStepOut: root.detail = null
    onPicked: id => { root.place = id; root.nav.search.clear() }
    onSearched: text => { root.query = text; if (root.place.includes(":search")) root.place = "home" }
    places: [
        { id: "home", title: "Home", icon: "home", tint: IrisStyle.identity.pink },
        { id: "anime:airing", title: "Airing now", icon: "live_tv", tint: IrisStyle.identity.orange, caption: "Anime" },
        { id: "anime:trending", title: "Trending", icon: "trending_up", tint: IrisStyle.identity.green },
        { id: "anime:top", title: "Top rated", icon: "star", tint: IrisStyle.identity.teal },
        { id: "anime:season", title: "This season", icon: "eco", tint: IrisStyle.identity.sky },
        { id: "anime:genres", title: "Genres", icon: "category", tint: IrisStyle.identity.purple },
        { id: "movie:movies", title: "Films", icon: "movie", tint: IrisStyle.identity.yellow, caption: "Films and series" },
        { id: "movie:series", title: "Series", icon: "tv", tint: IrisStyle.identity.red },
        { id: "movie:top", title: "Top rated", icon: "star", tint: IrisStyle.identity.teal },
        { id: "movie:years", title: "By year", icon: "calendar_month", tint: IrisStyle.identity.blue },
        { id: "movie:genres", title: "Genres", icon: "category", tint: IrisStyle.identity.indigo }
    ]

    AnimeData { id: animeData }
    MovieData { id: movieData }
    property var animeGenres: []

    function openShow(show): void {
        if (!show) return
        root.detail = show
        if (root.column) root.pushed = true
    }
    // What IPC asked for (CornerState.place / query), taken when it opens.
    function takeQuery(): void {
        const place = CornerState.place
        if (place.length > 0) {
            CornerState.place = ""
            const title = place.match(/^title:(movie|series):(tt\d+)$/)
            const anime = place.match(/^anime:(\d+)$/)
            if (title) root.openShow({ id: title[2], kind: title[1] })
            else if (anime) root.openShow({ id: Number(anime[1]), kind: "anime" })
            else if (root.places.some(p => p.id === place) || /^(anime|movie):genre:/.test(place)) { root.nav.search.clear(); root.place = place; root.pushed = true }
        }
        if (CornerState.query.length === 0) return
        root.nav.search.type(CornerState.query)
        CornerState.query = ""
    }
    Connections {
        target: CornerState
        function onQueryChanged(): void { if (root.open) root.takeQuery() }
        function onPlaceChanged(): void { if (root.open && CornerState.place.length > 0) root.takeQuery() }
    }
    // The title open in full over the page; null shows the page.
    property var detail: null
    onPlaceChanged: root.detail = null
    onQueryChanged: root.detail = null

    // The season This season shows, and the year By year shows; ‹ › walk them.
    readonly property var seasons: ["WINTER", "SPRING", "SUMMER", "FALL"]
    property string season: AnimeService.getCurrentSeason()
    property int seasonYear: new Date().getFullYear()
    property int year: new Date().getFullYear()
    function step(by: int): void {
        if (root.page === "movie:years") { root.year = Math.max(1997, Math.min(new Date().getFullYear(), root.year + by)); return }
        const index = root.seasons.indexOf(root.season) + by
        root.seasonYear += Math.floor(index / 4)
        root.season = root.seasons[((index % 4) + 4) % 4]
    }

    // What each grid place lists, and from which catalogue.
    readonly property var pageSpec: {
        const p = root.page
        const thisSeason = root.season === AnimeService.getCurrentSeason() && root.seasonYear === new Date().getFullYear()
        if (p === "anime:search") return { anime: true, title: Translation.tr("Anime called “%1”").arg(root.query), filter: { search: root.query }, pickers: false }
        if (p === "anime:airing") return { anime: true, title: Translation.tr("Airing now"), subtitle: Translation.tr("What airs this week, the most watched first"), filter: { status: "RELEASING" } }
        if (p === "anime:trending") return { anime: true, title: Translation.tr("Trending"), subtitle: Translation.tr("What people are watching right now"), filter: {}, sort: "TRENDING_DESC" }
        if (p === "anime:top") return { anime: true, title: Translation.tr("Top rated"), subtitle: Translation.tr("The best scored on AniList"), filter: {}, sort: "SCORE_DESC" }
        if (p === "anime:season") return { anime: true, stepper: true, title: Translation.tr("%1 %2").arg(Translation.tr(AnimeService.getSeasonDisplayName(root.season))).arg(root.seasonYear),
            subtitle: thisSeason ? Translation.tr("This season's shows") : Translation.tr("Another season"), filter: { season: root.season, year: root.seasonYear } }
        if (p.startsWith("anime:genre:")) { const g = p.slice(12); return { anime: true, title: Translation.tr(g), subtitle: Translation.tr("Anime genre"), filter: { genre: g } } }
        if (p.startsWith("movie:search:")) { const kind = p.slice(13); return { title: Translation.tr("“%1”").arg(root.query), subtitle: kind === "series" ? Translation.tr("Series") : Translation.tr("Films"), filter: { kind, search: root.query }, pickers: false } }
        if (p === "movie:movies") return { title: Translation.tr("Films"), subtitle: Translation.tr("The most watched right now"), filter: {}, kind: "movie" }
        if (p === "movie:series") return { title: Translation.tr("Series"), subtitle: Translation.tr("The most watched right now"), filter: {}, kind: "series" }
        if (p === "movie:top") return { title: Translation.tr("Top rated"), subtitle: Translation.tr("The best scored on IMDb"), filter: {}, catalog: "imdbRating" }
        if (p === "movie:years") return { stepper: true, title: String(root.year), subtitle: Translation.tr("Released that year"), filter: { catalog: "year", genre: String(root.year) } }
        if (p.startsWith("movie:genre:")) { const g = p.slice(12); return { title: Translation.tr(g), subtitle: Translation.tr("Genre"), filter: { genre: g } } }
        return null
    }

    // Built when it first opens (LazyLoader): it is already open then, so opening runs on completion too.
    function opened(): void {
        if (!root.column) root.nav.search.focusField()
        root.takeQuery()
        if (root.animeGenres.length === 0) animeData.genres((list, error) => { if (!error) root.animeGenres = list })
    }
    onOpenChanged: if (root.open) root.opened()
    Component.onCompleted: if (root.open) Qt.callLater(root.opened)

    readonly property int closeRoom: Math.round(40 * root.d)

    MediaHome {
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
        visible: root.page === "home" && !root.detail
        anime: animeData
        movies: movieData
        onOpenShow: show => root.openShow(show)
        onOpenSection: id => root.pick(id)
    }
    MediaSearch {
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
        visible: root.page === "search" && !root.detail
        anime: animeData
        movies: movieData
        query: root.query
        onOpenShow: show => root.openShow(show)
        onOpenSection: id => root.place = id
    }
    // One grid per catalogue, so each keeps its own pickers.
    Repeater {
        model: [true, false]
        MediaGrid {
            id: grid
            required property bool modelData
            readonly property bool shown: root.pageSpec !== null && Boolean(root.pageSpec.anime) === grid.modelData
            anchors.fill: parent
            anchors.rightMargin: root.closeRoom
            visible: grid.shown && !root.detail
            store: grid.modelData ? animeData : movieData
            title: grid.shown ? root.pageSpec.title : ""
            subtitle: grid.shown ? (root.pageSpec.subtitle ?? "") : ""
            filter: grid.shown ? root.pageSpec.filter : ({})
            pickers: grid.shown && (root.pageSpec.pickers ?? true) && !root.column
            stepper: grid.shown && Boolean(root.pageSpec.stepper)
            kindPicker: !grid.shown || root.pageSpec.kind === undefined
            Binding on sort { when: grid.shown && root.pageSpec.sort !== undefined; value: root.pageSpec?.sort ?? "POPULARITY_DESC" }
            Binding on kind { when: grid.shown && root.pageSpec.kind !== undefined; value: root.pageSpec?.kind ?? "movie" }
            Binding on catalog { when: grid.shown && root.pageSpec.catalog !== undefined; value: root.pageSpec?.catalog ?? "top" }
            onStep: by => root.step(by)
            onOpenShow: show => root.openShow(show)
        }
    }
    IrisCornerTiles {
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
        visible: (root.page === "anime:genres" || root.page === "movie:genres") && !root.detail
        title: Translation.tr("Genres")
        subtitle: root.page === "anime:genres" ? Translation.tr("Every genre on AniList") : Translation.tr("Every genre on Cinemeta")
        names: root.page === "anime:genres" ? root.animeGenres : movieData.genreNames
        emptyText: Translation.tr("Loading…")
        onPicked: name => root.place = root.page.slice(0, 6) + "genre:" + name
    }
    MediaDetail {
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
        visible: root.detail !== null
        compact: root.column
        anime: animeData
        movies: movieData
        show: root.detail
        onBack: root.detail = null
        onOpenShow: show => root.openShow(show)
        onOpenSection: id => { root.place = id; root.detail = null; root.nav.search.clear() }
    }
}
