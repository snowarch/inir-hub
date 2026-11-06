pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

// Home: one show up front (what is trending on AniList) and shelves of anime, films and series under it.
MediaPage {
    id: root
    required property var anime
    required property var movies

    property var hero: null
    function askHero(): void {
        if (root.hero !== null) return
        root.anime.page({ sort: "TRENDING_DESC" }, 1, (result, error) => { if (!error) root.hero = result.items[0] ?? null })
    }
    Component.onCompleted: root.askHero()
    Connections {
        target: CornerState
        function onAttemptChanged(): void { root.askHero() }
    }

    readonly property var shelves: [
        { anime: true, title: Translation.tr("Airing now"), note: Translation.tr("Anime"), filter: { status: "RELEASING", sort: "POPULARITY_DESC" }, place: "anime:airing" },
        { anime: true, title: Translation.tr("Trending anime"), filter: { sort: "TRENDING_DESC" }, place: "anime:trending" },
        { anime: true, title: Translation.tr("This season"), filter: { season: root.anime.currentSeason(), year: new Date().getFullYear(), sort: "POPULARITY_DESC" }, place: "anime:season" },
        { title: Translation.tr("Popular films"), note: Translation.tr("Films and series"), filter: { kind: "movie" }, place: "movie:movies" },
        { title: Translation.tr("Popular series"), filter: { kind: "series" }, place: "movie:series" },
        { title: Translation.tr("Top rated films"), filter: { kind: "movie", catalog: "imdbRating" }, place: "movie:top" }
    ]
    // Why something is missing: a catalogue down (the other's shelves still show), or still asking.
    readonly property string down: Array.from(new Set([root.anime.down, root.movies.down])).filter(text => text.length > 0).join("  ·  ")
    readonly property string status: root.down.length > 0 ? root.down
        : root.hero === null ? Translation.tr("Asking %1…").arg("AniList") : ""

    RowLayout {
        Layout.fillWidth: true
        visible: root.status.length > 0
        spacing: Math.round(12 * root.d)
        IrisText {
            Layout.fillWidth: true
            text: root.status
            color: IrisStyle.muted
            wrapMode: Text.WordWrap
        }
        IrisButton {
            visible: root.down.length > 0
            quiet: true
            text: Translation.tr("Retry")
            onClicked: CornerState.attempt++
        }
    }

    // The hero: the show's banner behind its cover, its name, what it is about, and what to do with it.
    ClippingRectangle {
        id: hero
        readonly property var show: root.hero
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(250 * root.d)
        visible: hero.show !== null
        radius: IrisStyle.radiusTile
        color: IrisStyle.fillQuiet

        IrisImage {
            anchors.fill: parent
            source: String(hero.show?.banner || hero.show?.imageLarge || "")
            fillMode: Image.PreserveAspectCrop
        }
        // The words sit on the left: the banner fades into the surface under them.
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: IrisStyle.artVeilHeavy }
                GradientStop { position: 0.55; color: IrisStyle.artVeil }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Math.round(18 * root.d)
            spacing: Math.round(18 * root.d)

            ClippingRectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: Math.round(height / 1.5)
                radius: IrisStyle.tileRadius(width * 0.5)
                color: IrisStyle.fillQuiet
                IrisImage { anchors.fill: parent; source: String(hero.show?.imageLarge ?? "") }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: CornerState.openShow(hero.show) }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Math.round(6 * root.d)
                IrisText {
                    text: Translation.tr("Trending now")
                    color: IrisStyle.identity.green
                    font.pixelSize: IrisStyle.typeFootnote
                    font.weight: IrisStyle.weight(Font.Bold)
                }
                IrisText {
                    Layout.fillWidth: true
                    text: String(hero.show?.title ?? "")
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: IrisStyle.typeTitleLarge
                    font.weight: IrisStyle.weight(Font.Bold)
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                }
                IrisText {
                    Layout.fillWidth: true
                    text: [hero.show?.year, Translation.tr(String(hero.show?.type ?? "")), (hero.show?.genres ?? []).slice(0, 3).map(g => Translation.tr(g)).join(" · "),
                           Number(hero.show?.score ?? 0) > 0 ? "★ " + Number(hero.show.score).toFixed(1) : ""].filter(x => String(x ?? "").length > 0).join("  ·  ")
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeFootnote
                    elide: Text.ElideRight
                }
                IrisText {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: String(hero.show?.description ?? "")
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeLabel
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 3
                }
                IrisButton {
                    emphasized: true
                    text: Translation.tr("Details")
                    onClicked: CornerState.openShow(hero.show)
                }
            }
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
        }
    }
}
