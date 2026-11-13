pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

// One page for every list: a search, Popular, Top rated, a genre, a season or a year. Posters in a grid; the next page
// is asked for as the end comes into view. `store` is AnimeData (AniList) or MovieData (Cinemeta).
Item {
    id: root
    required property var store
    // { place, title, subtitle, filter, pickers?, stepper?, sort?, kind?, catalog? }: see MediaCorner.specOf.
    required property var spec
    signal step(int by)

    readonly property bool anime: root.store.anime
    readonly property var filter: root.spec?.filter ?? {}
    readonly property string place: root.spec?.place ?? ""
    readonly property bool pickers: root.spec?.pickers ?? true
    // What the person picked, where the place leaves it open. Another place starts over.
    property string sort: "POPULARITY_DESC"
    property string format: ""
    property string kind: "movie"
    property string catalog: "top"
    onPlaceChanged: {
        root.sort = "POPULARITY_DESC"
        root.format = ""
        root.kind = "movie"
        root.catalog = "top"
    }

    readonly property real d: IrisStyle.density
    property var items: []
    property int pageNumber: 0
    property bool hasNext: true
    property bool loading: false
    property string error: ""
    property int _ticket: 0

    readonly property bool byYear: root.filter.catalog === "year"
    readonly property var asked: Object.assign({}, root.filter, root.filter.search ? {}
        : root.anime ? { sort: root.spec?.sort ?? root.sort, format: root.format }
        : { kind: root.spec?.kind ?? root.kind, catalog: root.byYear ? "year" : root.spec?.catalog ?? root.catalog })
    readonly property string askedKey: JSON.stringify(root.asked)
    onAskedKeyChanged: reloadLater.restart()
    Component.onCompleted: reloadLater.restart()
    // A place changes the list and resets the pickers: ask once it has all landed.
    Timer { id: reloadLater; interval: 0; onTriggered: root.reload() }
    Timer { id: moreLater; interval: 0; onTriggered: root.more() }
    Connections {
        target: CornerState
        function onAttemptChanged(): void {
            if (root.items.length === 0) root.reload()
            else if (root.error.length > 0) root.more()
        }
    }

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
        if (root.loading || !root.hasNext) return
        const ticket = root._ticket
        root.error = ""
        root.loading = true
        root.store.page(root.asked, root.pageNumber + 1, (result, error) => {
            if (ticket !== root._ticket) return
            root.loading = false
            if (error) { root.error = root.store.down; return }
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

        // The title, then the pickers: beside it while they fit, under it when they don't.
        GridLayout {
            Layout.fillWidth: true
            columns: root.width >= pickerRow.widest + Math.round(320 * root.d) ? 2 : 1
            columnSpacing: Math.round(12 * root.d)
            rowSpacing: Math.round(8 * root.d)
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(12 * root.d)
                IrisIconButton {
                    visible: root.spec?.stepper ?? false
                    materialIcon: "chevron_left"
                    Accessible.name: Translation.tr("Previous")
                    onClicked: root.step(-1)
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    IrisText {
                        Layout.fillWidth: true
                        text: root.spec?.title ?? ""
                        font.family: IrisStyle.fontTitle
                        font.pixelSize: IrisStyle.typeTitle
                        font.weight: IrisStyle.weight(Font.Bold)
                        elide: Text.ElideRight
                    }
                    IrisText {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: root.spec?.subtitle ?? ""
                        color: IrisStyle.muted
                        font.pixelSize: IrisStyle.typeFootnote
                        elide: Text.ElideRight
                    }
                }
                IrisIconButton {
                    visible: root.spec?.stepper ?? false
                    materialIcon: "chevron_right"
                    Accessible.name: Translation.tr("Next")
                    onClicked: root.step(1)
                }
            }
            // A segmented control has no width of its own: one slot per option.
            Flow {
                id: pickerRow
                readonly property int widest: (kindPicker.visible ? kindPicker.width + spacing : 0) + (sortPicker.visible ? sortPicker.width : 0)
                Layout.fillWidth: parent.columns === 1
                Layout.preferredWidth: parent.columns === 1 ? -1 : pickerRow.widest
                spacing: Math.round(12 * root.d)
                IrisSegmented {
                    id: kindPicker
                    visible: root.pickers && (root.anime || root.spec?.kind === undefined)
                    width: Math.round(options.length * 76 * root.d)
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
                // Where the place says the order (Top rated, Trending…), a picker would only contradict its title.
                IrisSegmented {
                    id: sortPicker
                    visible: root.pickers && !root.byYear && root.spec?.sort === undefined && root.spec?.catalog === undefined
                    width: Math.round(options.length * 88 * root.d)
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
        }

        GridView {
            id: grid
            IrisScrollFeel {}
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.items.length > 0
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            // As many columns as fit at ~130 px (three even in a narrow window), the cells sharing what is left over.
            readonly property int columns: Math.max(3, Math.floor(width / Math.round(130 * root.d)))
            cellWidth: Math.floor(width / columns)
            // A 2:3 cover, the gap and two lines of title over one of detail, at the type's real size.
            cellHeight: Math.round((cellWidth - 14 * root.d) * 1.5 + 8 * root.d + 12 * root.d) + Math.ceil(2 * IrisStyle.typeLabel * 1.35 + IrisStyle.typeFootnote * 1.4)
            cacheBuffer: Math.round(cellHeight * 2)
            // Keyed by id: a new page adds its posters and leaves the others and the scroll alone.
            model: ScriptModel { values: root.items; objectProp: "id" }
            delegate: Item {
                id: cell
                required property var modelData
                width: grid.cellWidth
                height: grid.cellHeight
                MediaPoster {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: cell.width - Math.round(14 * root.d)
                    show: cell.modelData
                }
            }
            onAtYEndChanged: if (atYEnd) moreLater.restart()
            onContentHeightChanged: if (contentHeight > 0 && contentHeight <= height) moreLater.restart()
            ScrollBar.vertical: IrisScrollBar {}
            footer: Item {
                width: grid.width
                height: Math.round(48 * root.d)
                RowLayout {
                    anchors.centerIn: parent
                    visible: root.loading || root.error.length > 0
                    spacing: Math.round(12 * root.d)
                    IrisText {
                        text: root.loading ? Translation.tr("Loading more…") : root.error
                        color: IrisStyle.muted
                        font.pixelSize: IrisStyle.typeFootnote
                    }
                    IrisButton {
                        visible: !root.loading
                        quiet: true
                        text: Translation.tr("Retry")
                        onClicked: root.more()
                    }
                }
            }
        }

        // Every state says something: still asking, why it failed, nothing found. It always asks: NetworkManager can say
        // "limited" with the internet working, so only a request that fails says offline.
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.items.length === 0
            spacing: Math.round(12 * root.d)
            Item { Layout.fillHeight: true }
            IrisText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: IrisStyle.muted
                text: root.error.length > 0 ? root.error
                    : root.loading || root.pageNumber === 0 ? Translation.tr("Asking %1…").arg(root.store.sourceName)
                    : root.filter.search ? Translation.tr("Nothing called “%1”").arg(root.filter.search)
                    : Translation.tr("Nothing here yet")
            }
            IrisButton {
                Layout.alignment: Qt.AlignHCenter
                visible: root.error.length > 0
                text: Translation.tr("Retry")
                onClicked: root.reload()
            }
            Item { Layout.fillHeight: true }
        }
    }
}
