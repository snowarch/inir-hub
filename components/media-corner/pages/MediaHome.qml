pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../state"

// Home, laid out as iRiS's Settings home in the style worn, then shelves of anime, films and series.
// Prism: one show up front, a deck (what you watched last, what plays or a popular film), the places of every day.
// Normal (Folio): the trending shows in one card with their strip, Every day's tiles, Yours, and the Library rows.
MediaPage {
    id: root
    required property var anime
    required property var movies

    property var hero: null
    property var trending: []
    property var featuredAnime: null
    property var featuredFilm: null
    // Settled: the hero's answer came, with a show or without.
    property bool heroSettled: false
    function askHero(): void {
        if (root.hero !== null) return
        root.anime.page({ sort: "TRENDING_DESC" }, 1, (result, error) => {
            if (!root) return
            root.heroSettled = true
            if (!error) { root.hero = result.items[0] ?? null; root.featuredAnime = result.items[1] ?? null; root.trending = result.items.slice(0, 6) }
        })
    }
    function askFilm(): void {
        if (root.featuredFilm !== null) return
        root.movies.page({ kind: "movie" }, 1, (result, error) => {
            if (root && !error) root.featuredFilm = result.items[0] ?? null
        })
    }
    Component.onCompleted: { root.askHero(); root.askFilm() }
    Connections {
        target: CornerState
        enabled: root.visible
        function onAttemptChanged(): void { root.askHero(); root.askFilm() }
    }

    readonly property var shelves: [
        { anime: true, title: Translation.tr("Airing now"), note: Translation.tr("Anime"), filter: { status: "RELEASING", sort: "POPULARITY_DESC" }, place: "anime:airing" },
        { anime: true, title: Translation.tr("Trending anime"), note: Translation.tr("Anime"), filter: { sort: "TRENDING_DESC" }, place: "anime:trending" },
        { anime: true, title: Translation.tr("This season"), note: Translation.tr("Anime"), filter: { season: root.anime.currentSeason(), year: new Date().getFullYear(), sort: "POPULARITY_DESC" }, place: "anime:season" },
        { title: Translation.tr("Popular films"), note: Translation.tr("Films and series"), filter: { kind: "movie" }, place: "movie:movies" },
        { title: Translation.tr("Popular series"), note: Translation.tr("Films and series"), filter: { kind: "series" }, place: "movie:series" },
        { title: Translation.tr("Top rated films"), note: Translation.tr("Films and series"), filter: { kind: "movie", catalog: "imdbRating" }, place: "movie:top" }
    ]
    // Why something is missing: a catalogue down (the other's shelves still show), or still asking.
    readonly property string down: Array.from(new Set([root.anime.down, root.movies.down])).filter(text => text.length > 0).join("  ·  ")
    readonly property string status: root.down.length > 0 ? root.down
        : !root.heroSettled ? Translation.tr("Asking %1…").arg(root.anime.sourceName) : ""
    readonly property var latest: CornerWatch.latest?.entry ?? null

    CornerHeading { page: true; eyebrow: CornerSkin.prism ? Translation.tr("Media Corner") : Translation.tr("What to watch today"); title: Translation.tr("Home") }

    RowLayout {
        Layout.fillWidth: true
        visible: root.down.length > 0
        spacing: Math.round(12 * root.d)
        IrisText {
            Layout.fillWidth: true
            text: root.down
            color: IrisStyle.danger
            wrapMode: Text.WordWrap
        }
        IrisButton {
            quiet: true
            text: Translation.tr("Retry")
            onClicked: CornerState.attempt++
        }
    }

    Loader {
        Layout.fillWidth: true
        active: CornerSkin.prism
        visible: active
        sourceComponent: prismTop
    }
    Loader {
        Layout.fillWidth: true
        active: !CornerSkin.prism
        visible: active
        sourceComponent: folioTop
    }
    Component {
        id: prismTop
        ColumnLayout {
            spacing: root.spacing
            HomeHero {
                Layout.fillWidth: true
                show: root.hero
                status: root.status || Translation.tr("Nothing here yet")
            }

            // The deck: what you watched last (or another trending show) and what plays (or a popular film).
            GridLayout {
                id: deck
                Layout.fillWidth: true
                columns: width >= Math.round(560 * root.d) ? 2 : 1
                columnSpacing: Math.round(14 * root.d)
                rowSpacing: Math.round(14 * root.d)
                HomeCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(196 * root.d)
                    show: root.latest?.show ?? root.featuredAnime
                    eyebrow: root.latest ? Translation.tr("Continue") : Translation.tr("Also trending")
                    glyph: root.latest ? "play_arrow" : "info"
                    action: root.latest ? Translation.tr("Continue") : Translation.tr("Details")
                    onOpened: CornerState.openShow(show)
                    onActed: {
                        CornerState.openShow(show)
                        if (root.latest) CornerWatch.begin(root.latest.show, root.latest.episode ?? null)
                    }
                }
                PlaybackCard {
                    visible: CornerWatch.current !== null
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(196 * root.d)
                    large: false
                    extras: false
                    playingOnly: true
                }
                HomeCard {
                    visible: CornerWatch.current === null
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(196 * root.d)
                    show: root.featuredFilm
                    eyebrow: Translation.tr("Popular films")
                    glyph: "info"
                    action: Translation.tr("Details")
                    onOpened: CornerState.openShow(show)
                    onActed: CornerState.openShow(show)
                }
            }

            HomePlaces { Layout.fillWidth: true }
        }
    }
    Component {
        id: folioTop
        ColumnLayout {
            spacing: root.spacing
            FolioHero {
                Layout.fillWidth: true
                shows: root.trending
                status: root.status || Translation.tr("Nothing here yet")
            }
            FolioTiles { Layout.fillWidth: true; anime: root.anime }
            LibraryList { Layout.fillWidth: true }
            FolioLibrary { Layout.fillWidth: true }
        }
    }

    Repeater {
        model: root.shelves
        MediaRow {
            required property var modelData
            store: modelData.anime ? root.anime : root.movies
            title: modelData.title
            note: modelData.note ?? ""
            filter: modelData.filter
            allPlace: modelData.place
            glyph: modelData.anime ? "animation" : modelData.filter.kind === "series" ? "tv" : "movie"
            tint: modelData.anime ? IrisStyle.identity.purple : modelData.filter.kind === "series" ? IrisStyle.identity.blue : IrisStyle.identity.orange
        }
    }
}
