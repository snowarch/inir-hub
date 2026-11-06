pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

// One title in full, over the page it was opened from: banner, what it is about, the facts, where it streams
// officially and what to see next. An anime comes from AniList, a film or series from Cinemeta.
MediaPage {
    id: root
    required property var anime
    required property var movies
    readonly property var show: CornerState.show
    // One narrow column: a smaller cover and banner.
    property bool compact: false
    // A link went to the browser.
    signal followed()

    // The page in full (recommendations, relations, cast); the poster's own data meanwhile.
    property var full: null
    readonly property var s: root.full ?? root.show ?? ({})
    readonly property bool isAnime: root.show?.kind === "anime"
    readonly property var streaming: Array.from(root.s.streaming ?? [])
    // The synopsis opens at five lines.
    property bool readMore: false
    // Why the page in full didn't come, in words.
    property string failed: ""
    readonly property bool asking: root.show !== null && root.full === null && root.failed.length === 0

    function load(): void {
        const id = root.show?.id
        if (id === undefined) return
        root.failed = ""
        if (root.isAnime)
            root.anime.detail(Number(id), (result, error) => { if (root.show?.id === id) root.took(result, error, root.anime) })
        else
            root.movies.detail(String(root.show?.kind ?? "movie"), String(id), (result, error) => { if (root.show?.id === id) root.took(result, error, root.movies) })
    }
    function took(result: var, error: string, store: var): void {
        if (!error && result) { root.full = result; root.failed = "" }
        else if (root.full === null) root.failed = error ? store.down : Translation.tr("%1 doesn't know this title").arg(store.sourceName)
    }
    function follow(url: string): void {
        Qt.openUrlExternally(url)
        root.followed()
    }
    onShowChanged: {
        if (root.show === null) return
        root.full = null
        root.readMore = false
        root.contentY = 0
        loadLater.restart()
    }
    Component.onCompleted: loadLater.restart()
    // A kept answer comes back at once: never in the middle of the show changing.
    Timer { id: loadLater; interval: 0; onTriggered: root.load() }
    Connections {
        target: CornerState
        function onAttemptChanged(): void { if (root.failed.length > 0) root.load() }
    }

    function fmtStatus(status: string): string {
        return ({ RELEASING: Translation.tr("Airing"), FINISHED: Translation.tr("Finished"), NOT_YET_RELEASED: Translation.tr("Not yet aired"),
            CANCELLED: Translation.tr("Cancelled"), HIATUS: Translation.tr("On hiatus") })[status] ?? status
    }
    readonly property var facts: (root.isAnime ? [
        { label: Translation.tr("Score"), value: Number(root.s.score ?? 0) > 0 ? "★ " + Number(root.s.score).toFixed(1) : "" },
        { label: Translation.tr("Format"), value: Translation.tr(String(root.s.type ?? "")) },
        { label: Translation.tr("Episodes"), value: String(root.s.episodes ?? "") === "?" ? "" : String(root.s.episodes ?? "") },
        { label: Translation.tr("Next episode"), value: Number(root.s.airingAt ?? 0) > 0 ? Translation.tr("Ep. %1, %2").arg(root.s.nextEpisode).arg(Translation.locale.toString(new Date(root.s.airingAt * 1000), "ddd d MMM, hh:mm")) : "" },
        { label: Translation.tr("Length"), value: Number(root.s.duration ?? 0) > 0 ? Translation.tr("%1 min").arg(root.s.duration) : "" },
        { label: Translation.tr("Status"), value: root.fmtStatus(String(root.s.status ?? "")) },
        { label: Translation.tr("Season"), value: [Translation.tr(root.anime.seasonName(String(root.s.season ?? ""))), root.s.year].filter(x => String(x ?? "").length > 0).join(" ") },
        { label: Translation.tr("Studio"), value: (root.s.studios ?? []).join(", ") }
    ] : [
        { label: Translation.tr("IMDb"), value: Number(root.s.score ?? 0) > 0 ? "★ " + Number(root.s.score).toFixed(1) : "" },
        { label: Translation.tr("Kind"), value: Translation.tr(String(root.s.type ?? "")) },
        { label: Translation.tr("Year"), value: String(root.s.year ?? "") },
        { label: Translation.tr("Length"), value: String(root.s.runtime ?? "") },
        { label: Translation.tr("Seasons"), value: (root.full?.seasons ?? []).length > 0 ? String(root.full.seasons.length) : "" },
        { label: Translation.tr("Country"), value: String(root.s.country ?? "") },
        { label: Translation.tr("Director"), value: (root.s.director ?? []).slice(0, 2).join(", ") },
        { label: Translation.tr("Cast"), value: (root.s.cast ?? []).slice(0, 4).join(", ") }
    ]).filter(fact => String(fact.value).length > 0)

    spacing: Math.round(18 * root.d)

    // Banner, with the cover overlapping its foot and the name beside it. It grows with what the side holds.
    Item {
        id: head
        readonly property int atLeast: Math.round((root.compact ? 280 : 360) * root.d)
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(head.atLeast, banner.height + Math.round(12 * root.d) + side.implicitHeight)

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
            // On a plate, so it reads over any banner; a narrow window has its own ‹ in the head.
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
                    onClicked: CornerState.back()
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
            y: head.atLeast - height
            width: Math.round((root.compact ? 104 : 160) * root.d)
            height: Math.round(width * 1.5)
            radius: IrisStyle.radiusTile
            color: IrisStyle.fillQuiet
            border.width: 1
            border.color: IrisStyle.hairline
            IrisImage { anchors.fill: parent; source: String(root.s.imageLarge || root.s.image || "") }
        }

        ColumnLayout {
            id: side
            anchors { left: cover.right; leftMargin: Math.round(18 * root.d); right: parent.right; top: banner.bottom; topMargin: Math.round(12 * root.d) }
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
                text: [root.s.titleRomaji, root.s.titleJapanese].filter(t => t && t !== root.s.title).join(" · ")
                color: IrisStyle.muted
                font.pixelSize: IrisStyle.typeFootnote
                elide: Text.ElideRight
            }
            // Where it streams officially and where to read more; wraps in a narrow column.
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Math.round(6 * root.d)
                spacing: Math.round(8 * root.d)
                Repeater {
                    model: root.streaming.slice(0, 5)
                    IrisChip {
                        required property var modelData
                        glyph: "play_circle"
                        label: String(modelData.site)
                        Accessible.description: Translation.tr("Watch it on %1").arg(String(modelData.site))
                        onClicked: root.follow(String(modelData.url))
                    }
                }
                IrisChip {
                    visible: !root.isAnime && String(root.s.trailer ?? "").length > 0
                    glyph: "smart_display"
                    label: Translation.tr("Trailer")
                    onClicked: root.follow("https://www.youtube.com/watch?v=" + encodeURIComponent(String(root.s.trailer)))
                }
                IrisChip {
                    glyph: "open_in_new"
                    label: root.isAnime ? "AniList" : "IMDb"
                    enabled: root.isAnime ? String(root.s.url ?? "").startsWith("https://") : /^tt\d+$/.test(String(root.s.id ?? ""))
                    onClicked: root.follow(root.isAnime ? String(root.s.url) : "https://www.imdb.com/title/" + root.s.id + "/")
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.failed.length > 0 || root.asking
        spacing: Math.round(12 * root.d)
        IrisText {
            Layout.fillWidth: true
            text: root.asking ? Translation.tr("Asking %1…").arg(root.isAnime ? root.anime.sourceName : root.movies.sourceName) : root.failed
            color: IrisStyle.muted
            font.pixelSize: IrisStyle.typeLabel
            wrapMode: Text.WordWrap
        }
        IrisButton {
            visible: !root.asking
            quiet: true
            text: Translation.tr("Retry")
            onClicked: root.load()
        }
    }

    // AniList lists where it streams; when it lists nothing, say so. Cinemeta never does, so a film has only IMDb's chip.
    IrisText {
        Layout.fillWidth: true
        visible: root.isAnime && root.full !== null && root.streaming.length === 0
        text: Translation.tr("AniList lists no official streaming service for it")
        color: IrisStyle.muted
        font.pixelSize: IrisStyle.typeFootnote
        wrapMode: Text.WordWrap
    }

    // The facts, in one line each.
    Flow {
        Layout.fillWidth: true
        spacing: Math.round(18 * root.d)
        Repeater {
            model: root.facts
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
                onClicked: CornerState.pick((root.isAnime ? "anime:genre:" : "movie:genre:") + modelData)
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
    IrisButton {
        visible: synopsis.truncated || root.readMore
        quiet: true
        text: root.readMore ? Translation.tr("Show less") : Translation.tr("Read more")
        onClicked: root.readMore = !root.readMore
    }

    MediaRow {
        visible: root.isAnime && items.length > 0
        store: root.anime
        title: Translation.tr("Related")
        note: Translation.tr("Seasons, films and side stories")
        local: root.isAnime ? (root.full?.relations ?? []) : []
    }
    MediaRow {
        visible: root.isAnime && items.length > 0
        store: root.anime
        title: Translation.tr("If you liked it…")
        note: Translation.tr("Recommended on AniList")
        local: root.isAnime ? (root.full?.recommendations ?? []) : []
    }
    MediaRow {
        visible: !root.isAnime && items.length > 0
        store: root.movies
        title: Translation.tr("More like it")
        note: Translation.tr(String((root.s.genres ?? [])[0] ?? ""))
        filter: !root.isAnime && (root.s.genres ?? []).length > 0 ? { kind: root.s.kind, genre: root.s.genres[0] } : null
        local: root.isAnime ? [] : null
        exclude: String(root.s.id ?? "")
    }
}
