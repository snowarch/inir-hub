pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"
import "../state/http.js" as Http
import "schedule.js" as Schedule

// A fresh, user-requested snapshot of saved anime; no work continues when hidden.
ColumnLayout {
    id: root
    property bool active: false
    property bool loading: false
    property string failure: ""
    property var entries: []
    property var ids: []
    property var collected: []
    property int offset: 0
    property int checkedAt: 0
    property var request: null
    readonly property real d: IrisStyle.density

    function cancel(): void {
        timeout.stop()
        if (root.request) {
            root.request.onreadystatechange = null
            root.request.abort()
            root.request = null
        }
        root.loading = false
    }
    function refresh(): void {
        if (!root.active) return
        root.cancel()
        root.entries = []
        root.failure = ""
        root.checkedAt = 0
        if (!CornerWatch.watchlistLoaded) {
            root.failure = CornerWatch.watchlistLoadFailed ? Translation.tr("Could not load saved titles") : ""
            root.loading = !CornerWatch.watchlistLoadFailed
            return
        }
        root.ids = Schedule.savedIds(CornerWatch.watchlist)
        root.collected = []
        root.offset = 0
        if (!root.ids.length) return
        root.loading = true
        root.askBatch()
    }
    function askBatch(): void {
        if (!root.active || !root.loading) return
        const batch = root.ids.slice(root.offset, root.offset + 50)
        if (!batch.length) {
            root.entries = Schedule.upcoming(root.collected, Math.floor(Date.now() / 1000))
            root.checkedAt = Math.floor(Date.now() / 1000)
            root.loading = false
            return
        }
        const xhr = new XMLHttpRequest()
        root.request = xhr
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || root.request !== xhr) return
            timeout.stop()
            root.request = null
            if (!root.active) return
            if (xhr.status === 429) {
                let retryAfter = ""
                try { retryAfter = Http.retryAfter(xhr.getResponseHeader("Retry-After")) } catch (e) {}
                root.failure = Translation.tr("The provider limited requests; try again later") + (retryAfter ? " · " + Translation.tr("Retry-After: %1").arg(Http.retryDisplay(retryAfter)) : "")
                root.loading = false
                return
            }
            try {
                if (xhr.status !== 200 || xhr.responseText.length > 1024 * 1024) throw new Error("request failed")
                const reply = JSON.parse(xhr.responseText)
                if (reply.errors || !Array.isArray(reply.data?.Page?.media)) throw new Error("invalid response")
                root.collected = root.collected.concat(reply.data.Page.media)
                root.offset += batch.length
                root.askBatch()
            } catch (e) {
                root.failure = Translation.tr("Could not load the schedule")
                root.loading = false
            }
        }
        try {
            xhr.open("POST", "https://graphql.anilist.co")
            xhr.setRequestHeader("Content-Type", "application/json")
            xhr.setRequestHeader("Accept", "application/json")
            xhr.send(JSON.stringify({ query: "query ($ids: [Int]) { Page(page: 1, perPage: 50) { media(id_in: $ids, type: ANIME, isAdult: false) { id format title { english romaji } nextAiringEpisode { airingAt episode } } } }", variables: { ids: batch } }))
            timeout.restart()
        } catch (e) {
            root.cancel()
            root.failure = Translation.tr("Could not load the schedule")
        }
    }
    onActiveChanged: if (root.active) root.refresh(); else root.cancel()
    Component.onCompleted: if (root.active && !root.loading && !root.checkedAt) root.refresh()
    Connections {
        target: CornerWatch
        function onWatchlistLoadedChanged(): void { if (root.active && CornerWatch.watchlistLoaded) root.refresh() }
        function onWatchlistLoadFailedChanged(): void { if (root.active && CornerWatch.watchlistLoadFailed) root.refresh() }
    }
    Component.onDestruction: root.cancel()
    Timer {
        id: timeout
        interval: 20000
        onTriggered: { root.cancel(); root.failure = Translation.tr("Could not load the schedule") }
    }
    IrisText {
        text: Translation.tr("Upcoming episodes")
        font.pixelSize: IrisStyle.typeHeadline
        font.weight: IrisStyle.weight(Font.Bold)
    }
    IrisButton { text: Translation.tr("Refresh schedule"); enabled: !root.loading; onClicked: root.refresh() }
    IrisText { visible: root.loading; text: Translation.tr("Loading…") }
    IrisText { visible: root.failure.length > 0; text: root.failure; color: IrisStyle.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    IrisText {
        visible: !root.loading && !root.failure && root.entries.length === 0
        text: Translation.tr("No upcoming episodes found")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    IrisText {
        visible: root.checkedAt > 0
        text: Translation.tr("Schedule checked %1").arg(Translation.locale.toString(new Date(root.checkedAt * 1000), "ddd d MMM, hh:mm"))
        color: IrisStyle.textSecondary
    }
    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: root.entries
        delegate: IrisButton {
            required property var modelData
            width: ListView.view.width
            quiet: true
            readonly property string caption: modelData.title + " · " + Translation.tr("Ep. %1, %2").arg(modelData.episode).arg(Translation.locale.toString(new Date(modelData.airingAt * 1000), "ddd d MMM, hh:mm"))
            Accessible.name: caption
            implicitHeight: Math.round(48 * root.d)
            IrisText {
                anchors.fill: parent
                anchors.leftMargin: Math.round(12 * root.d)
                anchors.rightMargin: Math.round(12 * root.d)
                verticalAlignment: Text.AlignVCenter
                textFormat: Text.PlainText
                elide: Text.ElideRight
                text: parent.caption
            }
            onClicked: CornerState.openShow({ id: modelData.id, kind: "anime", title: modelData.title })
        }
    }
}
