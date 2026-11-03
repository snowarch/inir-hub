pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// One page for every list of shows: a search, Popular, Trending, a genre, a season. Posters in a grid; the next
// AniList page is asked for as the end comes into view.
Item {
    id: root
    required property AnimeCornerData store
    // { search, genre, sort, format, season, year, status, ids }
    property var filter: ({})
    property string title: ""
    property string subtitle: ""
    // Sort and format pickers; a search sorts by match and hides them.
    property bool pickers: true
    // Shows already at hand (ani-cli's history): listed as they are, AniList is not asked.
    property var local: null
    property string sort: "POPULARITY_DESC"
    property string format: ""
    // ‹ › beside the title, to walk the seasons.
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

    readonly property var asked: Object.assign({}, root.filter, root.pickers ? { sort: root.sort, format: root.format } : {})
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
            // AniList repeats a show across pages when popularity shifts mid-scroll.
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
                Accessible.name: Translation.tr("Previous season")
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
                Accessible.name: Translation.tr("Next season")
                onClicked: root.stepSeason(1)
            }
            Item { visible: root.seasonNav; Layout.fillWidth: true }
            IrisSegmented {
                visible: root.pickers
                accessibleName: Translation.tr("Format")
                options: [
                    { value: "", label: Translation.tr("All") },
                    { value: "TV", label: Translation.tr("TV") },
                    { value: "MOVIE", label: Translation.tr("Movie") },
                    { value: "OVA", label: Translation.tr("OVA") }
                ]
                current: root.format
                onPicked: value => root.format = value
            }
            IrisSegmented {
                visible: root.pickers
                accessibleName: Translation.tr("Sort")
                options: [
                    { value: "POPULARITY_DESC", label: Translation.tr("Popular") },
                    { value: "TRENDING_DESC", label: Translation.tr("Trending") },
                    { value: "SCORE_DESC", label: Translation.tr("Top rated") },
                    { value: "START_DATE_DESC", label: Translation.tr("Newest") }
                ]
                current: root.sort
                onPicked: value => root.sort = value
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
                AnimePoster {
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
                    text: root.loading ? Translation.tr("Loading more…") : Translation.tr("AniList didn't answer (´・ω・`)")
                    color: IrisStyle.muted
                    font.pixelSize: IrisStyle.typeFootnote
                }
            }
        }

        // Every state says something: offline, still asking, AniList quiet, nothing found.
        IrisText {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.items.length === 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            color: IrisStyle.muted
            text: root.local !== null ? Translation.tr("Nothing watched with ani-cli yet")
                : !Network.online ? Network.offlineReason
                : root.loading || root.pageNumber === 0 && root.error.length === 0 ? Translation.tr("Asking AniList…")
                : root.error.length > 0 ? Translation.tr("AniList didn't answer (´・ω・`)")
                : root.filter.search ? Translation.tr("No anime called “%1”").arg(root.filter.search)
                : Translation.tr("Nothing here yet")
        }
    }
}
