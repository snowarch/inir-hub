pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// One page for every list: a search, Popular, Top rated, a genre, a season or a year. Posters in a grid; the next page
// is asked for as the end comes into view. `store` is AnimeData (AniList) or MovieData (Cinemeta).
Item {
    id: root
    required property var store
    readonly property bool anime: Boolean(root.store.anime)
    readonly property string sourceName: root.anime ? "AniList" : "Cinemeta"
    // AniList: { search, genre, sort, format, season, year, status }; Cinemeta: { kind, catalog, genre, search }.
    property var filter: ({})
    property string title: ""
    property string subtitle: ""
    // The pickers beside the title; a search hides them. Films and Series already say which kind they list.
    property bool pickers: true
    property bool kindPicker: true
    // AniList's sort and format, Cinemeta's kind and catalog.
    property string sort: "POPULARITY_DESC"
    property string format: ""
    property string kind: "movie"
    property string catalog: "top"
    // ‹ › beside the title, to walk the seasons or the years.
    property bool stepper: false
    signal openShow(var show)
    signal step(int by)

    readonly property real d: IrisStyle.density
    property var items: []
    property int pageNumber: 0
    property bool hasNext: true
    property bool loading: false
    property string error: ""
    property int _ticket: 0

    readonly property bool byYear: root.filter.catalog === "year"
    readonly property var asked: Object.assign({}, root.filter, !root.pickers ? {}
        : root.anime ? { sort: root.sort, format: root.format }
        : { kind: root.kind, catalog: root.byYear ? "year" : root.catalog })
    onAskedChanged: reloadLater.restart()
    Component.onCompleted: reloadLater.restart()
    // The filter arrives a property at a time: ask once they have all landed.
    Timer { id: reloadLater; interval: 0; onTriggered: root.reload() }

    // A hidden grid asks nothing: it asks when it comes into view.
    property bool stale: false
    onVisibleChanged: if (root.visible && root.stale) root.reload()
    function reload(): void {
        root.stale = !root.visible
        if (root.stale) return
        root._ticket++
        root.items = []
        root.pageNumber = 0
        root.hasNext = true
        root.error = ""
        root.loading = false
        grid.contentY = 0
        root.more()
    }
    function more(): void {
        if (root.loading || !root.hasNext || !Network.online) return
        const ticket = root._ticket
        root.loading = true
        root.store.page(root.asked, root.pageNumber + 1, (result, error) => {
            if (ticket !== root._ticket) return
            root.loading = false
            if (error) { root.error = error; return }
            root.pageNumber++
            // A title can come back on the next page when the order shifts mid-scroll.
            const seen = new Set(root.items.map(s => s.id))
            root.items = root.items.concat(result.items.filter(s => !seen.has(s.id)))
            root.hasNext = result.hasNext
        })
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Math.round(12 * root.d)

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(12 * root.d)
            IrisIconButton {
                visible: root.stepper
                materialIcon: "chevron_left"
                Accessible.name: Translation.tr("Previous")
                onClicked: root.step(-1)
            }
            ColumnLayout {
                Layout.fillWidth: !root.stepper
                spacing: 0
                IrisText {
                    Layout.fillWidth: true
                    text: root.title
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: IrisStyle.typeTitle
                    font.weight: IrisStyle.weight(Font.Bold)
                    elide: Text.ElideRight
                }
                IrisText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.subtitle
                    color: IrisStyle.muted
                    font.pixelSize: IrisStyle.typeFootnote
                    elide: Text.ElideRight
                }
            }
            IrisIconButton {
                visible: root.stepper
                materialIcon: "chevron_right"
                Accessible.name: Translation.tr("Next")
                onClicked: root.step(1)
            }
            Item { visible: root.stepper; Layout.fillWidth: true }
            // A segmented control has no width of its own: one slot per option.
            IrisSegmented {
                visible: root.pickers && (root.anime || root.kindPicker)
                Layout.preferredWidth: Math.round(options.length * 76 * root.d)
                accessibleName: root.anime ? Translation.tr("Format") : Translation.tr("Kind")
                options: root.anime ? [
                    { value: "", label: Translation.tr("All") },
                    { value: "TV", label: Translation.tr("TV") },
                    { value: "MOVIE", label: Translation.tr("Movie") },
                    { value: "OVA", label: Translation.tr("OVA") }
                ] : [
                    { value: "movie", label: Translation.tr("Movies") },
                    { value: "series", label: Translation.tr("Series") }
                ]
                current: root.anime ? root.format : root.kind
                onPicked: value => { if (root.anime) root.format = value; else root.kind = value }
            }
            IrisSegmented {
                visible: root.pickers && !root.byYear
                Layout.preferredWidth: Math.round(options.length * 88 * root.d)
                accessibleName: Translation.tr("Sort")
                options: root.anime ? [
                    { value: "POPULARITY_DESC", label: Translation.tr("Popular") },
                    { value: "TRENDING_DESC", label: Translation.tr("Trending") },
                    { value: "SCORE_DESC", label: Translation.tr("Top rated") },
                    { value: "START_DATE_DESC", label: Translation.tr("Newest") }
                ] : [
                    { value: "top", label: Translation.tr("Popular") },
                    { value: "imdbRating", label: Translation.tr("Top rated") }
                ]
                current: root.anime ? root.sort : root.catalog
                onPicked: value => { if (root.anime) root.sort = value; else root.catalog = value }
            }
        }

        GridView {
            id: grid
            IrisScrollFeel {}
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.items.length > 0
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            // As many columns as fit at ~130 px (three even in Pocket's column), the cells sharing what is left over.
            readonly property int columns: Math.max(3, Math.floor(width / Math.round(130 * root.d)))
            cellWidth: Math.floor(width / columns)
            cellHeight: Math.round((cellWidth - 14 * root.d) * 1.5 + 64 * root.d)
            cacheBuffer: Math.round(cellHeight * 2)
            model: root.items
            delegate: Item {
                id: cell
                required property var modelData
                width: grid.cellWidth
                height: grid.cellHeight
                MediaPoster {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: cell.width - Math.round(14 * root.d)
                    show: cell.modelData
                    onOpen: root.openShow(cell.modelData)
                }
            }
            onAtYEndChanged: if (atYEnd) Qt.callLater(root.more)
            onContentHeightChanged: if (contentHeight > 0 && contentHeight <= height) Qt.callLater(root.more)
            ScrollBar.vertical: IrisScrollBar {}
            footer: Item {
                width: grid.width
                height: Math.round(48 * root.d)
                IrisText {
                    anchors.centerIn: parent
                    visible: root.loading || root.error.length > 0
                    text: root.loading ? Translation.tr("Loading more…") : Translation.tr("%1 didn't answer (´・ω・`)").arg(root.sourceName)
                    color: IrisStyle.muted
                    font.pixelSize: IrisStyle.typeFootnote
                }
            }
        }

        // Every state says something: offline, still asking, the catalogue quiet, nothing found.
        IrisText {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.items.length === 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            color: IrisStyle.muted
            text: !Network.online ? Network.offlineReason
                : root.loading || root.pageNumber === 0 && root.error.length === 0 ? Translation.tr("Asking %1…").arg(root.sourceName)
                : root.error.length > 0 ? Translation.tr("%1 didn't answer (´・ω・`)").arg(root.sourceName)
                : root.filter.search ? Translation.tr("Nothing called “%1”").arg(root.filter.search)
                : Translation.tr("Nothing here yet")
        }
    }
}
