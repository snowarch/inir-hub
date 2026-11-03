pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

// Home: one title up front (what you were watching, or what is popular) and shelves under it.
Flickable {
    id: root
    required property MovieCornerData store
    // Continue watching as posters (CornerWatch.watching).
    property var watching: []
    signal openShow(var show)
    signal openSection(string id)

    readonly property real d: IrisStyle.density
    readonly property var resuming: root.watching.length > 0 ? root.watching[0] : null
    // The hero: the title being resumed, in full, or the most popular film.
    property var hero: null
    property string _heroFor: ""

    function findHero(): void {
        const key = root.resuming ? root.resuming.kind + ":" + root.resuming.id : "popular"
        if (key === root._heroFor) return
        root._heroFor = key
        if (root.resuming) root.store.detail(root.resuming.kind, root.resuming.id, (show, error) => { if (!error && show && key === root._heroFor) root.hero = show })
        else root.store.page({ kind: "movie" }, 1, (result, error) => { if (!error && key === root._heroFor) root.hero = result.items[0] ?? null })
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
                        text: root.resuming ? Translation.tr("Continue watching") : Translation.tr("Popular now")
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
                        text: [String(hero.show?.year ?? ""), Translation.tr(String(hero.show?.type ?? "")), (hero.show?.genres ?? []).slice(0, 3).map(g => Translation.tr(g)).join(" · "),
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
                            enabled: CornerWatch.canStart && hero.show !== null
                            text: !root.resuming ? Translation.tr("Watch")
                                : root.resuming.kind === "series" ? Translation.tr("Continue · S%1 E%2").arg(root.resuming.season).arg(root.resuming.episode)
                                : Translation.tr("Continue")
                            onClicked: {
                                if (root.resuming) CornerWatch.watch(Object.assign({}, hero.show, { season: root.resuming.season, episode: root.resuming.episode }))
                                else if (hero.show.kind === "series") root.openShow(hero.show)
                                else CornerWatch.watch(hero.show)
                            }
                        }
                        IrisChip {
                            readonly property bool followed: CornerState.follows(String(hero.show?.id ?? ""))
                            glyph: "bookmark"
                            label: followed ? Translation.tr("Following") : Translation.tr("Follow")
                            selected: followed
                            onClicked: CornerState.toggleFollow(hero.show)
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

        MovieRow {
            Layout.fillWidth: true
            store: root.store
            title: Translation.tr("Continue watching")
            local: root.watching
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("continue")
        }
        MovieRow {
            Layout.fillWidth: true
            store: root.store
            title: Translation.tr("Following")
            local: CornerState.following
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("following")
        }
        MovieRow {
            Layout.fillWidth: true
            store: root.store
            title: Translation.tr("Popular films")
            filter: ({ kind: "movie" })
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("movies")
        }
        MovieRow {
            Layout.fillWidth: true
            store: root.store
            title: Translation.tr("Popular series")
            filter: ({ kind: "series" })
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("series")
        }
        MovieRow {
            Layout.fillWidth: true
            store: root.store
            title: Translation.tr("New this year")
            filter: ({ kind: "movie", catalog: "year", genre: String(new Date().getFullYear()) })
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("years")
        }
        MovieRow {
            Layout.fillWidth: true
            store: root.store
            title: Translation.tr("Top rated")
            note: Translation.tr("On IMDb")
            filter: ({ kind: "movie", catalog: "imdbRating" })
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("top")
        }
        Item { Layout.preferredHeight: Math.round(8 * root.d) }
    }
}
