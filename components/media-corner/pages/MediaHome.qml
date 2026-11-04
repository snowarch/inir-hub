pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Home: one show up front (what is trending on AniList) and shelves of anime, films and series under it.
Flickable {
    id: root
    required property var anime
    required property var movies
    signal openShow(var show)
    signal openSection(string id)

    readonly property real d: IrisStyle.density
    property var hero: null
    Component.onCompleted: root.anime.page({ sort: "TRENDING_DESC" }, 1, (result, error) => { if (!error) root.hero = result.items[0] ?? null })

    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    IrisScrollFeel {}
    ScrollBar.vertical: IrisScrollBar {}

    ColumnLayout {
        id: column
        width: root.width
        spacing: Math.round(22 * root.d)

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
                opacity: 0.55
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
                    radius: Math.max(4, IrisStyle.radiusTile - Math.round(18 * root.d))
                    color: IrisStyle.fillQuiet
                    IrisImage { anchors.fill: parent; source: String(hero.show?.imageLarge ?? "") }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.openShow(hero.show) }
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
                    RowLayout {
                        spacing: Math.round(8 * root.d)
                        IrisButton {
                            emphasized: true
                            text: Translation.tr("Details")
                            onClicked: root.openShow(hero.show)
                        }
                    }
                }
            }
        }

        MediaRow {
            Layout.fillWidth: true
            store: root.anime
            title: Translation.tr("Airing now")
            note: Translation.tr("Anime")
            filter: ({ status: "RELEASING", sort: "POPULARITY_DESC" })
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("anime:airing")
        }
        MediaRow {
            Layout.fillWidth: true
            store: root.anime
            title: Translation.tr("Trending anime")
            filter: ({ sort: "TRENDING_DESC" })
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("anime:trending")
        }
        MediaRow {
            Layout.fillWidth: true
            store: root.anime
            title: Translation.tr("This season")
            filter: ({ season: AnimeService.getCurrentSeason(), year: new Date().getFullYear(), sort: "POPULARITY_DESC" })
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("anime:season")
        }
        MediaRow {
            Layout.fillWidth: true
            store: root.movies
            title: Translation.tr("Popular films")
            note: Translation.tr("Films and series")
            filter: ({ kind: "movie" })
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("movie:movies")
        }
        MediaRow {
            Layout.fillWidth: true
            store: root.movies
            title: Translation.tr("Popular series")
            filter: ({ kind: "series" })
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("movie:series")
        }
        MediaRow {
            Layout.fillWidth: true
            store: root.movies
            title: Translation.tr("Top rated films")
            filter: ({ kind: "movie", catalog: "imdbRating" })
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("movie:top")
        }
        Item { Layout.preferredHeight: Math.round(8 * root.d) }
    }
}
