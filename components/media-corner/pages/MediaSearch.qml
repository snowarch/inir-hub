pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.components

// What the search field finds, on both catalogues at once: anime on AniList, films and series on Cinemeta, a shelf
// each. «See all» opens the whole list of that shelf.
Flickable {
    id: root
    required property var anime
    required property var movies
    property string query: ""
    signal openShow(var show)
    signal openSection(string id)

    readonly property real d: IrisStyle.density
    readonly property bool found: animeRow.items.length + filmRow.items.length + seriesRow.items.length > 0
    readonly property bool settled: animeRow.settled && filmRow.settled && seriesRow.settled

    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    IrisScrollFeel {}
    ScrollBar.vertical: IrisScrollBar {}
    onQueryChanged: root.contentY = 0

    ColumnLayout {
        id: column
        width: root.width
        spacing: Math.round(22 * root.d)

        IrisText {
            Layout.fillWidth: true
            text: Translation.tr("Results for “%1”").arg(root.query)
            font.family: IrisStyle.fontTitle
            font.pixelSize: IrisStyle.typeTitle
            font.weight: IrisStyle.weight(Font.Bold)
            elide: Text.ElideRight
        }
        MediaRow {
            id: animeRow
            Layout.fillWidth: true
            store: root.anime
            title: Translation.tr("Anime")
            filter: root.query.length > 0 ? { search: root.query } : null
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("anime:search")
        }
        MediaRow {
            id: filmRow
            Layout.fillWidth: true
            store: root.movies
            title: Translation.tr("Films")
            filter: root.query.length > 0 ? { kind: "movie", search: root.query } : null
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("movie:search:movie")
        }
        MediaRow {
            id: seriesRow
            Layout.fillWidth: true
            store: root.movies
            title: Translation.tr("Series")
            filter: root.query.length > 0 ? { kind: "series", search: root.query } : null
            onOpenShow: show => root.openShow(show)
            onOpenAll: root.openSection("movie:search:series")
        }
        IrisText {
            Layout.fillWidth: true
            Layout.topMargin: Math.round(60 * root.d)
            visible: !root.found
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: IrisStyle.muted
            text: !Network.online ? Network.offlineReason
                : root.settled ? Translation.tr("Nothing called “%1”").arg(root.query)
                : Translation.tr("Looking for “%1”…").arg(root.query)
        }
    }
}
