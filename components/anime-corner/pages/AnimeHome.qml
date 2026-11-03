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
import qs.modules.iris.pieces
import qs.modules.iris.state
import "../state"

// Home: one show up front (what you were watching, or what is trending) and shelves under it.
Flickable {
    id: root
    required property AnimeCornerData store
    // ani-cli's history as posters (IrisAnimeCorner.watching).
    property var watching: []
    signal openShow(var show)
    signal openSection(string id)

    readonly property real d: IrisStyle.density
    readonly property var resuming: root.watching.length > 0 ? root.watching[0] : null
    // The hero's AniList side: the show being resumed, found by its title, or the first trending one.
    property var hero: null
    property string _heroFor: ""

    function findHero(): void {
        const key = root.resuming ? "watch:" + root.resuming.title : "trending"
        if (key === root._heroFor) return
        root._heroFor = key
        const filter = root.resuming ? { search: String(root.resuming.title) } : { sort: "TRENDING_DESC" }
        root.store.page(filter, 1, (result, error) => {
            if (error || key !== root._heroFor) return
            root.hero = result.items.length > 0 ? result.items[0] : null
            // ani-cli names a show its own way: without a match, the hero falls back to what is trending.
            if (!root.hero && root.resuming) { root._heroFor = "trending"; root.store.page({ sort: "TRENDING_DESC" }, 1, (r, e) => { if (!e) root.hero = r.items[0] ?? null }) }
        })
    }
    onResumingChanged: Qt.callLater(root.findHero)
    Component.onCompleted: Qt.callLater(root.findHero)

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
                        text: root.resuming ? Translation.tr("Continue watching") : Translation.tr("Trending now")
                        color: root.resuming ? IrisStyle.identity.orange : IrisStyle.identity.green
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
                            enabled: CornerWatch.canTarget && CornerWatch.canStart
                            text: root.resuming ? Translation.tr("Continue · Ep %1").arg(root.resuming.episode) : Translation.tr("Watch")
                            onClicked: {
                                CornerWatch.lookFor(hero.show)
                                root.resuming ? CornerWatch.resume(root.resuming.watch) : CornerWatch.search(String(hero.show?.titleRomaji || hero.show?.title || ""))
                            }
                        }
                        IrisChip {
                            readonly property bool followed: IrisPieces.animeFollows(Number(hero.show?.id ?? 0))
                            glyph: "bookmark"
                            label: followed ? Translation.tr("Following") : Translation.tr("Follow")
                            selected: followed
                            onClicked: IrisPieces.animeToggleFollow(Number(hero.show?.id ?? 0))
                        }
                        IrisChip {
                            glyph: "info"
                            label: Translation.tr("Details")
                            onClicked: root.openShow(hero.show)
                        }
                    }
                }
            }
        }

        AnimeRow {
            Layout.fillWidth: true
            store: root.store
            title: Translation.tr("Continue watching")
            note: Translation.tr("From ani-cli")
            local: root.watching
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("continue")
        }
        AnimeRow {
            Layout.fillWidth: true
            store: root.store
            title: Translation.tr("Following")
            filter: IrisPieces.animeFollowing.length > 0 ? { ids: IrisPieces.animeFollowing, sort: "POPULARITY_DESC" } : null
            local: IrisPieces.animeFollowing.length > 0 ? null : []
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("following")
        }
        AnimeRow {
            Layout.fillWidth: true
            store: root.store
            title: Translation.tr("Airing now")
            filter: ({ status: "RELEASING", sort: "POPULARITY_DESC" })
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("airing")
        }
        AnimeRow {
            Layout.fillWidth: true
            store: root.store
            title: Translation.tr("Trending")
            filter: ({ sort: "TRENDING_DESC" })
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("trending")
        }
        AnimeRow {
            Layout.fillWidth: true
            store: root.store
            title: Translation.tr("This season")
            filter: ({ season: AnimeService.getCurrentSeason(), year: new Date().getFullYear(), sort: "POPULARITY_DESC" })
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("season")
        }
        AnimeRow {
            Layout.fillWidth: true
            store: root.store
            title: Translation.tr("Popular")
            note: Translation.tr("Of all time")
            filter: ({ sort: "POPULARITY_DESC" })
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("popular")
        }
        Item { Layout.preferredHeight: Math.round(8 * root.d) }
    }
}
