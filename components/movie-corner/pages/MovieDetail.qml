pragma ComponentBehavior: Bound
import QtQuick
import qs
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
import "../state"

// One title in full, over the page it was opened from: its backdrop, what it is about, where to watch it, a series'
// episodes by season and more like it.
Flickable {
    id: root
    required property MovieCornerData store
    property var show: null
    // One narrow column (Pocket): a smaller cover and banner.
    property bool compact: false
    signal back()
    signal openShow(var show)
    signal openSection(string id)

    readonly property real d: IrisStyle.density
    // Cinemeta's page in full (episodes, cast); the poster's own data meanwhile.
    property var full: null
    readonly property var s: root.full ?? root.show ?? ({})
    readonly property bool series: root.s.kind === "series"
    readonly property bool followed: CornerState.follows(String(root.s.id ?? ""))
    // Where Continue is in this title, or null.
    readonly property var next: CornerWatch.nextOf(root.s)
    // The synopsis opens at five lines.
    property bool readMore: false

    // Where it streams officially, with the person's TMDB key; null without one or when TMDB doesn't know.
    property var where: null
    function _askWhere(): void {
        const id = String(root.s.id ?? "")
        const region = String(Qt.locale().name.split("_")[1] ?? "").toUpperCase()
        root.store.whereToWatch(String(root.s.kind ?? "movie"), Number(root.s.tmdb ?? 0), CornerWatch.secretOf("tmdb"), region,
            value => { if (String(root.s.id ?? "") === id) root.where = value })
    }
    onFullChanged: if (root.full) root._askWhere()
    Connections { target: CornerWatch; function onKeysReadyChanged(): void { if (root.full) root._askWhere() } }
    onShowChanged: {
        root.where = null
        CornerWatch.loadKeys()
        root.full = null
        root.readMore = false
        root.contentY = 0
        const id = String(root.show?.id ?? "")
        const kind = String(root.show?.kind ?? "movie")
        if (id.length > 0) root.store.detail(kind, id, (result, error) => { if (!error && result && String(root.show?.id ?? "") === id) root.full = result })
    }
    function watchNow(): void {
        if (root.series) {
            const first = (root.full?.episodes ?? [])[0]
            const at = root.next ?? (first ? { season: first.season, episode: first.episode } : { season: 1, episode: 1 })
            const episode = (root.full?.episodes ?? []).find(e => e.season === at.season && e.episode === at.episode)
            CornerWatch.watch(Object.assign({}, root.s, { season: at.season, episode: at.episode, episodeTitle: episode?.title ?? "" }))
        } else CornerWatch.watch(root.s)
    }

    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    IrisScrollFeel {}
    ScrollBar.vertical: IrisScrollBar {}

    ColumnLayout {
        id: column
        width: root.width
        spacing: Math.round(18 * root.d)

        // Banner, with the cover overlapping its foot and the name beside it.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round((root.compact ? 280 : 360) * root.d)

            ClippingRectangle {
                id: banner
                width: parent.width
                height: Math.round((root.compact ? 170 : 240) * root.d)
                radius: IrisStyle.radiusTile
                color: IrisStyle.fillQuiet
                IrisImage {
                    anchors.fill: parent
                    source: String(root.s.banner || root.s.imageLarge || "")
                    fillMode: Image.PreserveAspectCrop
                }
                Rectangle {
                    anchors.fill: parent
                    // The banner melts into the sheet, so the name under it reads on one ground.
                    gradient: Gradient {
                        GradientStop { position: 0.3; color: "transparent" }
                        GradientStop { position: 1; color: IrisStyle.surfaceOpaque }
                    }
                }
                // On a plate, so it reads over any banner; Pocket has its own ‹ in the head.
                Rectangle {
                    visible: !root.compact
                    anchors { left: parent.left; top: parent.top; margins: Math.round(10 * root.d) }
                    width: backButton.width + Math.round(4 * root.d)
                    height: width
                    radius: width / 2
                    color: IrisStyle.artVeilHeavy
                    IrisIconButton {
                        id: backButton
                        anchors.centerIn: parent
                        materialIcon: "arrow_back"
                        Accessible.name: Translation.tr("Back")
                        onClicked: root.back()
                    }
                }
            }

            IrisBodyShadow {
                x: cover.x
                y: cover.y + Math.round(8 * root.d)
                width: cover.width
                height: cover.height
                radius: cover.radius
                blur: 24 * root.d
                spread: -4 * root.d
                color: IrisStyle.shadow
            }
            ClippingRectangle {
                id: cover
                x: Math.round(22 * root.d)
                anchors.bottom: parent.bottom
                width: Math.round((root.compact ? 104 : 160) * root.d)
                height: Math.round(width * 1.5)
                radius: IrisStyle.radiusTile
                color: IrisStyle.fillQuiet
                border.width: 1
                border.color: IrisStyle.hairline
                IrisImage { anchors.fill: parent; source: String(root.s.imageLarge || root.s.image || "") }
            }

            ColumnLayout {
                anchors { left: cover.right; leftMargin: Math.round(18 * root.d); right: parent.right; top: banner.bottom; topMargin: Math.round(12 * root.d); bottom: parent.bottom }
                spacing: Math.round(4 * root.d)
                IrisText {
                    Layout.fillWidth: true
                    text: String(root.s.title ?? "")
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: IrisStyle.typeTitleLarge
                    font.weight: IrisStyle.weight(Font.Bold)
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                IrisText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: (root.s.director ?? []).length > 0 ? Translation.tr("Directed by %1").arg(root.s.director.join(", ")) : ""
                    color: IrisStyle.muted
                    font.pixelSize: IrisStyle.typeFootnote
                    elide: Text.ElideRight
                }
                Item { Layout.fillHeight: true }
                // Wraps in a narrow column (Pocket) instead of cutting its last button.
                Flow {
                    Layout.fillWidth: true
                    spacing: Math.round(8 * root.d)
                    // Where you were, when you have been here; else the start.
                    IrisButton {
                        emphasized: true
                        visible: CornerWatch.hasSources || !CornerWatch.sourcesKnown
                        enabled: CornerWatch.canStart && String(root.s.id ?? "").length > 0
                        text: root.next ? (root.series ? Translation.tr("Continue · S%1 E%2").arg(root.next.season).arg(root.next.episode) : Translation.tr("Continue"))
                            : Translation.tr("Watch")
                        onClicked: root.watchNow()
                    }
                    IrisChip {
                        glyph: "translate"
                        label: CornerWatch.watchLine
                        Accessible.description: Translation.tr("Change it in the Corner's Settings")
                        onClicked: CornerState.place = "settings"
                    }
                    IrisChip {
                        glyph: "bookmark"
                        label: root.followed ? Translation.tr("Following") : Translation.tr("Follow")
                        selected: root.followed
                        enabled: String(root.s.id ?? "").length > 0
                        onClicked: CornerState.toggleFollow(root.s)
                    }
                    // Where it streams officially (TMDB, data by JustWatch): each opens TMDB's page with the links.
                    Repeater {
                        model: Array.from(root.where?.services ?? [])
                        IrisChip {
                            required property var modelData
                            glyph: "play_circle"
                            label: String(modelData.name)
                            Accessible.description: Translation.tr("Watch it on %1").arg(String(modelData.name))
                            onClicked: Qt.openUrlExternally(String(root.where.link))
                        }
                    }
                    IrisChip {
                        glyph: "movie"
                        label: Translation.tr("Trailer")
                        visible: /^[A-Za-z0-9_-]{6,20}$/.test(String(root.s.trailer ?? ""))
                        onClicked: Qt.openUrlExternally("https://www.youtube.com/watch?v=" + root.s.trailer)
                    }
                    IrisChip {
                        glyph: "open_in_new"
                        label: "IMDb"
                        enabled: /^tt\d+$/.test(String(root.s.id ?? ""))
                        onClicked: Qt.openUrlExternally("https://www.imdb.com/title/" + root.s.id + "/")
                    }
                }
            }
        }

        IrisText {
            Layout.fillWidth: true
            visible: text.length > 0
            text: Array.from(root.where?.services ?? []).length > 0 ? Translation.tr("Where to watch: data by JustWatch, through TMDB")
                : CornerWatch.sourcesKnown && !CornerWatch.hasSources
                    ? (CornerWatch.secretOf("tmdb").length > 0 ? Translation.tr("No sources yet: add one in the Corner's Settings › Sources")
                        : Translation.tr("No sources yet: add one in the Corner's Settings › Sources, or your TMDB key there to see where it streams"))
                : ""
            color: IrisStyle.muted
            font.pixelSize: IrisStyle.typeFootnote
            wrapMode: Text.WordWrap
        }

        // The facts, in one line each.
        Flow {
            Layout.fillWidth: true
            spacing: Math.round(18 * root.d)
            Repeater {
                model: [
                    { label: Translation.tr("IMDb"), value: Number(root.s.score ?? 0) > 0 ? "★ " + Number(root.s.score).toFixed(1) : "" },
                    { label: Translation.tr("Kind"), value: Translation.tr(String(root.s.type ?? "")) },
                    { label: Translation.tr("Year"), value: String(root.s.year ?? "") },
                    { label: Translation.tr("Length"), value: String(root.s.runtime ?? "") },
                    { label: Translation.tr("Seasons"), value: root.series && (root.full?.seasons ?? []).length > 0 ? String(root.full.seasons.length) : "" },
                    { label: Translation.tr("Country"), value: String(root.s.country ?? "") }
                ].filter(fact => String(fact.value).length > 0)
                delegate: ColumnLayout {
                    required property var modelData
                    spacing: 0
                    IrisText { text: modelData.label; color: IrisStyle.muted; font.pixelSize: IrisStyle.typeFootnote }
                    IrisText { text: modelData.value; font.pixelSize: IrisStyle.typeLabel; font.weight: IrisStyle.weight(Font.DemiBold) }
                }
            }
        }

        // Each genre opens its own list.
        Flow {
            Layout.fillWidth: true
            spacing: Math.round(6 * root.d)
            Repeater {
                model: root.s.genres ?? []
                delegate: IrisChip {
                    required property string modelData
                    label: Translation.tr(modelData)
                    onClicked: root.openSection("genre:" + modelData)
                }
            }
        }

        IrisText {
            id: synopsis
            Layout.fillWidth: true
            visible: text.length > 0
            text: String(root.s.description ?? "")
            color: IrisStyle.textSecondary
            font.pixelSize: IrisStyle.typeBody
            wrapMode: Text.WordWrap
            lineHeight: 1.15
            maximumLineCount: root.readMore ? 400 : 5
            elide: Text.ElideRight
        }
        IrisText {
            visible: synopsis.truncated || root.readMore
            text: root.readMore ? Translation.tr("Show less") : Translation.tr("Read more")
            color: IrisStyle.accent
            font.pixelSize: IrisStyle.typeLabel
            font.weight: IrisStyle.weight(Font.DemiBold)
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.readMore = !root.readMore }
        }

        // A series' episodes, a season at a time.
        MovieEpisodes {
            Layout.fillWidth: true
            Layout.topMargin: Math.round(6 * root.d)
            visible: root.series
            show: root.s
            episodes: root.full?.episodes ?? []
            seasons: root.full?.seasons ?? []
        }

        // Who is in it.
        ColumnLayout {
            Layout.fillWidth: true
            visible: (root.s.cast ?? []).length > 0
            spacing: Math.round(8 * root.d)
            IrisText {
                text: Translation.tr("Cast")
                font.pixelSize: IrisStyle.typeHeadline
                font.weight: IrisStyle.weight(Font.Bold)
            }
            IrisText {
                Layout.fillWidth: true
                text: (root.s.cast ?? []).join(" · ")
                textFormat: Text.PlainText
                color: IrisStyle.textSecondary
                font.pixelSize: IrisStyle.typeLabel
                wrapMode: Text.WordWrap
            }
        }

        MovieRow {
            Layout.fillWidth: true
            store: root.store
            title: Translation.tr("More like it")
            note: (root.s.genres ?? []).length > 0 ? Translation.tr(root.s.genres[0]) : ""
            seeAll: false
            filter: (root.s.genres ?? []).length > 0 ? { kind: root.s.kind, genre: root.s.genres[0] } : null
            exclude: String(root.s.id ?? "")
            onOpenShow: show => root.openShow(show)
        }
        Item { Layout.preferredHeight: Math.round(8 * root.d) }
    }
}
