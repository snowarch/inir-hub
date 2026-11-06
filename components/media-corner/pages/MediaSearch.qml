pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

// What the search field finds, on both catalogues at once: anime on AniList, films and series on Cinemeta, a shelf
// each. «See all» opens the whole list of that shelf.
MediaPage {
    id: root
    required property var anime
    required property var movies
    property string query: ""

    readonly property bool found: animeRow.items.length + filmRow.items.length + seriesRow.items.length > 0
    readonly property bool settled: animeRow.settled && filmRow.settled && seriesRow.settled
    // What didn't answer, so a failure never reads as «nothing called that».
    readonly property string down: Array.from(new Set([animeRow.failed ? root.anime.down : "", filmRow.failed || seriesRow.failed ? root.movies.down : ""])).filter(text => text.length > 0).join("  ·  ")
    onQueryChanged: root.contentY = 0

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
        store: root.anime
        title: Translation.tr("Anime")
        filter: root.query.length > 0 ? { search: root.query } : null
        allPlace: "anime:search"
    }
    MediaRow {
        id: filmRow
        store: root.movies
        title: Translation.tr("Films")
        filter: root.query.length > 0 ? { kind: "movie", search: root.query } : null
        allPlace: "movie:search:movie"
    }
    MediaRow {
        id: seriesRow
        store: root.movies
        title: Translation.tr("Series")
        filter: root.query.length > 0 ? { kind: "series", search: root.query } : null
        allPlace: "movie:search:series"
    }
    IrisText {
        Layout.fillWidth: true
        Layout.topMargin: root.found ? 0 : Math.round(60 * root.d)
        visible: !root.found || root.down.length > 0
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: IrisStyle.muted
        text: root.down.length > 0 ? root.down
            : root.settled ? Translation.tr("Nothing called “%1”").arg(root.query)
            : Translation.tr("Looking for “%1”…").arg(root.query)
    }
    IrisButton {
        Layout.alignment: Qt.AlignHCenter
        visible: root.down.length > 0
        quiet: true
        text: Translation.tr("Retry")
        onClicked: CornerState.attempt++
    }
}
