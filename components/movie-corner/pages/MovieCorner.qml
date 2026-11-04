pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style
import "../corner"
import "../state"

// The Movie Corner: a Place to find any film or series on Cinemeta, browse what is popular, top rated, new or by genre,
// and pick up where you were. It has Settings' body, in Settings' layout and host (corner/IrisCornerBody); Panel.qml
// puts it over the desktop or in a window. Escape steps back, then closes.
IrisCornerBody {
    id: root
    // Where you are: a place, "genre:<name>", or "search" while the field holds something.
    property string place: "home"
    property string query: ""
    readonly property string page: root.query.length > 0 ? "search" : root.place

    open: CornerState.open
    onCloseRequested: CornerState.open = false
    section: root.page === "search" ? "search" : root.place
    searchHint: Translation.tr("Search any film or series")
    deeper: root.detail !== null || root.watchOpen
    onStepOut: { if (root.watchOpen) root.closeWatch(); else root.detail = null }
    // Watching runs on a sheet of its own over the page: it opens with the search for sources, stays on a failure so it
    // can be read, and closes by itself once the film is playing.
    property bool watchOpen: false
    function closeWatch(): void {
        if (CornerWatch.phase === "finding" || CornerWatch.phase === "choosing") CornerWatch.cancel()
        if (!CornerWatch.busy) CornerWatch.error = ""
        root.watchOpen = false
    }
    Connections {
        target: CornerWatch
        function onPhaseChanged(): void {
            if (["finding", "choosing", "launching"].includes(CornerWatch.phase) && CornerState.open) root.watchOpen = true
            else if (CornerWatch.phase === "playing" || CornerWatch.error.length === 0) root.watchOpen = false
        }
        function onErrorChanged(): void {
            if (CornerWatch.error.length > 0 && CornerState.open) root.watchOpen = true
        }
    }
    onWatchOpenChanged: CornerWatch.holdError = root.watchOpen
    onPicked: id => {
        // The Anime Corner is its own component: asked to open over this one.
        if (id === "anime") { CornerState.open = false; Quickshell.execDetached(["inir", "anime-corner", "open"]); return }
        root.place = id
        root.nav.search.clear()
    }
    onSearched: text => root.query = text
    readonly property bool hasAnime: Plugins.has("anime-corner")
    places: [
        { id: "home", title: "Home", icon: "home", tint: IrisStyle.identity.pink },
        { id: "continue", title: "Continue watching", icon: "play_circle", tint: IrisStyle.identity.orange },
        { id: "following", title: "Following", icon: "bookmark", tint: IrisStyle.identity.red },
        { id: "movies", title: "Films", icon: "movie", tint: IrisStyle.identity.yellow, caption: "Browse" },
        { id: "series", title: "Series", icon: "tv", tint: IrisStyle.identity.green },
        { id: "top", title: "Top rated", icon: "star", tint: IrisStyle.identity.teal },
        { id: "years", title: "By year", icon: "calendar_month", tint: IrisStyle.identity.blue },
        { id: "genres", title: "Genres", icon: "category", tint: IrisStyle.identity.purple },
        { id: "settings", title: "Settings", icon: "settings", tint: IrisStyle.identity.gray, caption: "Corner" }
    ].concat(root.hasAnime ? [{ id: "anime", title: "Anime Corner", icon: "live_tv", tint: IrisStyle.identity.indigo }] : [])
    badges: ({ continue: CornerWatch.watching.length, following: CornerState.following.length })

    MovieCornerData { id: cornerData }

    function openShow(show): void {
        if (!show) return
        root.detail = show
        if (root.column) root.pushed = true
    }
    function takeQuery(): void {
        const place = CornerState.place
        if (place.length > 0) {
            CornerState.place = ""
            const title = place.match(/^title:(movie|series):(tt\d+)$/)
            if (title) root.openShow({ id: title[2], kind: title[1] })
            else { root.nav.search.clear(); root.place = place; root.pushed = true }
        }
        if (CornerState.query.length === 0) return
        root.nav.search.type(CornerState.query)
        CornerState.query = ""
    }
    Connections { target: CornerState; function onQueryChanged(): void { if (root.open) root.takeQuery() }
        function onPlaceChanged(): void { if (root.open && CornerState.place.length > 0) { root.closeWatch(); root.takeQuery() } } }
    // The title open in full over the page; null shows the page.
    property var detail: null
    onPlaceChanged: root.detail = null
    onQueryChanged: root.detail = null

    // The year By year shows; ‹ › walk it, within what Cinemeta lists.
    property int year: new Date().getFullYear()
    function stepYear(by: int): void { root.year = Math.max(1997, Math.min(new Date().getFullYear(), root.year + by)) }

    // What each place lists; the grid asks Cinemeta for it.
    readonly property var pageSpec: {
        const p = root.page
        if (p === "search") return { title: Translation.tr("Results for “%1”").arg(root.query), filter: { search: root.query } }
        if (p === "movies") return { title: Translation.tr("Films"), subtitle: Translation.tr("The most watched right now"), filter: {}, kind: "movie" }
        if (p === "series") return { title: Translation.tr("Series"), subtitle: Translation.tr("The most watched right now"), filter: {}, kind: "series" }
        if (p === "top") return { title: Translation.tr("Top rated"), subtitle: Translation.tr("The best scored on IMDb"), filter: {}, catalog: "imdbRating" }
        if (p === "years") return { title: String(root.year), subtitle: Translation.tr("Released that year"), filter: { catalog: "year", genre: String(root.year) } }
        if (p.startsWith("genre:")) { const g = p.slice(6); return { title: Translation.tr(g), subtitle: Translation.tr("Genre"), filter: { genre: g } } }
        if (p === "following") return { title: Translation.tr("Following"), subtitle: Translation.tr("The films and series you follow"), filter: {}, local: CornerState.following, pickers: false,
            empty: Translation.tr("Nothing followed yet: the bookmark on a poster follows it") }
        if (p === "continue") return { title: Translation.tr("Continue watching"), subtitle: Translation.tr("Where you were in each film and series"), filter: {}, local: CornerWatch.watching, pickers: false,
            empty: Translation.tr("Nothing watched here yet") }
        return { title: Translation.tr("Films"), filter: {} }
    }

    // Built when it first opens (OnDemandPanelLoader): it is already open then, so opening runs on completion too.
    function opened(): void {
        if (!root.column) root.nav.search.focusField()
        root.takeQuery()
    }
    onOpenChanged: {
        if (root.open) root.opened()
        else if (!CornerWatch.busy && root.watchOpen) root.closeWatch()
    }
    Component.onCompleted: if (root.open) Qt.callLater(root.opened)

    readonly property int closeRoom: Math.round(40 * root.d)

    MovieHome {
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
        visible: root.page === "home" && !root.detail
        store: cornerData
        watching: CornerWatch.watching
        onOpenShow: show => root.openShow(show)
        onOpenSection: id => root.pick(id)
    }
    MovieGrid {
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
        visible: !["home", "genres", "settings"].includes(root.page) && !root.detail
        seasonNav: root.page === "years"
        onStepSeason: by => root.stepYear(by)
        local: root.pageSpec.local ?? null
        store: cornerData
        title: root.pageSpec.title
        subtitle: root.pageSpec.subtitle ?? ""
        filter: root.pageSpec.filter
        pickers: root.pageSpec.pickers ?? true
        kind: root.pageSpec.kind ?? "movie"
        catalog: root.pageSpec.catalog ?? "top"
        emptyText: root.pageSpec.empty ?? ""
        onOpenShow: show => root.openShow(show)
    }
    Loader {
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
        active: root.page === "settings"
        visible: active && !root.detail
        sourceComponent: MovieSettings {}
    }
    IrisCornerTiles {
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
        visible: root.page === "genres" && !root.detail
        title: Translation.tr("Genres")
        subtitle: Translation.tr("Every genre on Cinemeta")
        names: cornerData.genreNames
        onPicked: name => root.place = "genre:" + name
    }
    MovieDetail {
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
    MovieWatchSheet {
        anchors.fill: parent
        anchors.rightMargin: root.closeRoom
        visible: root.watchOpen
        z: 10
        onDismissed: root.closeWatch()
    }
}
