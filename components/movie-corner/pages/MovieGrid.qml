pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// One page for every list of titles: a search, Popular, Top rated, a genre, a year. Posters in a grid; the next
// Cinemeta page is asked for as the end comes into view.
Item {
    id: root
    required property MovieCornerData store
    // { kind, catalog, genre, search }
    property var filter: ({})
    property string title: ""
    property string subtitle: ""
    // Films or series, and popular or top rated; a search hides them.
    property bool pickers: true
    // Titles already at hand (Continue, Following): listed as they are, Cinemeta is not asked.
    property var local: null
    // What an empty local list says (it has its own next step).
    property string emptyText: ""
    property string kind: "movie"
    property string catalog: "top"
    // ‹ › beside the title, to walk the years.
    property bool seasonNav: false
    signal openShow(var show)
    signal stepSeason(int by)

    readonly property real d: IrisStyle.density
    property var items: []
    property int pageNumber: 0
    property bool hasNext: true
    property bool loading: false
    property string error: ""
    property int _ticket: 0

    readonly property var asked: Object.assign({}, root.filter, root.pickers ? { kind: root.kind, catalog: root.filter.catalog === "year" ? "year" : root.catalog } : {})
    onAskedChanged: reloadLater.restart()
    onLocalChanged: reloadLater.restart()
    Component.onCompleted: reloadLater.restart()
    // The filter arrives a property at a time: ask once they have all landed.
    Timer { id: reloadLater; interval: 0; onTriggered: root.reload() }

    function reload(): void {
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
        if (root.local !== null) { root.items = root.local; root.hasNext = false; root.pageNumber = 1; return }
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
                visible: root.seasonNav
                materialIcon: "chevron_left"
                Accessible.name: Translation.tr("Previous year")
                onClicked: root.stepSeason(-1)
            }
            ColumnLayout {
                Layout.fillWidth: !root.seasonNav
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
                visible: root.seasonNav
                materialIcon: "chevron_right"
                Accessible.name: Translation.tr("Next year")
                onClicked: root.stepSeason(1)
            }
            Item { visible: root.seasonNav; Layout.fillWidth: true }
            IrisSegmented {
                visible: root.pickers
                accessibleName: Translation.tr("Kind")
                options: [
                    { value: "movie", label: Translation.tr("Movies") },
                    { value: "series", label: Translation.tr("Series") }
                ]
                current: root.kind
                onPicked: value => root.kind = value
            }
            IrisSegmented {
                visible: root.pickers && root.filter.catalog !== "year" && !root.filter.search
                accessibleName: Translation.tr("Sort")
                options: [
                    { value: "top", label: Translation.tr("Popular") },
                    { value: "imdbRating", label: Translation.tr("Top rated") }
                ]
                current: root.catalog
                onPicked: value => root.catalog = value
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
                MoviePoster {
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
                    text: root.loading ? Translation.tr("Loading more…") : Translation.tr("Cinemeta didn't answer (´・ω・`)")
                    color: IrisStyle.muted
                    font.pixelSize: IrisStyle.typeFootnote
                }
            }
        }

        // Every state says something: offline, still asking, Cinemeta quiet, nothing found.
        IrisText {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.items.length === 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            color: IrisStyle.muted
            text: root.local !== null ? (root.emptyText.length > 0 ? root.emptyText : Translation.tr("Nothing here yet"))
                : !Network.online ? Network.offlineReason
                : root.loading || root.pageNumber === 0 && root.error.length === 0 ? Translation.tr("Asking Cinemeta…")
                : root.error.length > 0 ? Translation.tr("Cinemeta didn't answer (´・ω・`)")
                : root.filter.search ? Translation.tr("Nothing called “%1”").arg(root.filter.search)
                : Translation.tr("Nothing here yet")
        }
    }
}
