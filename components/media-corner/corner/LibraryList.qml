pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"
import "../state/streams.js" as Streams

// Yours: Want to watch and Watching, numbered like Settings' changes, with the saved search over them. The rail and the
// places column show this one list; nothing here asks the network.
ColumnLayout {
    id: root
    readonly property real d: IrisStyle.density
    // Want to watch shows this many until «See all».
    property int fold: 5
    property bool unfolded: false
    property string pendingRemoval: ""
    readonly property var wanted: root.unfolded || CornerState.savedQuery.trim().length > 0 ? CornerWatch.wantedKeys : CornerWatch.wantedKeys.slice(0, root.fold)
    spacing: Math.round(6 * root.d)

    function episodeText(episode: var): string {
        if (!episode) return ""
        return (episode.season ? Translation.tr("Season %1").arg(episode.season) + " · " : "") + Translation.tr("Episode %1").arg(episode.episode)
    }
    function kindText(show: var): string {
        return Translation.tr(show?.kind === "anime" ? "Anime" : show?.kind === "movie" ? "Movie" : "Series")
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(6 * root.d)
        SavedFilter { Layout.fillWidth: true }
        SavedSort {}
    }

    CornerHeading {
        Layout.topMargin: Math.round(6 * root.d)
        eyebrow: Translation.tr("Yours")
        title: Translation.tr("Want to watch")
        glyph: "bookmark"
        tint: IrisStyle.identity.yellow
        link: CornerWatch.wantedKeys.length > root.fold && !CornerState.savedQuery.trim() ? (root.unfolded ? Translation.tr("Show less") : Translation.tr("See all")) : ""
        onLinkClicked: root.unfolded = !root.unfolded
    }
    Failure {
        shown: CornerWatch.watchlistLoadFailed
        text: Translation.tr("Could not load saved titles")
        onRetry: CornerWatch.retryWatchlistLoad()
    }
    IrisText {
        visible: CornerWatch.watchlistLoaded && root.wanted.length === 0
        Layout.fillWidth: true
        text: CornerState.savedQuery.trim() ? Translation.tr("Nothing here yet") : Translation.tr("Titles you save show here")
        color: IrisStyle.textSecondary
        font.pixelSize: IrisStyle.typeMeta
        wrapMode: Text.WordWrap
    }
    Repeater {
        model: root.wanted
        CornerRow {
            id: wantedRow
            required property string modelData
            required property int index
            readonly property var show: CornerWatch.watchlist[wantedRow.modelData]
            Layout.fillWidth: true
            number: wantedRow.index + 1
            image: String(wantedRow.show?.image ?? "")
            glyph: wantedRow.show?.kind === "anime" ? "animation" : "movie"
            title: String(wantedRow.show?.title ?? "")
            detail: [root.kindText(wantedRow.show), Translation.tr(String(wantedRow.show?.type ?? ""))].filter((v, i, all) => v && all.indexOf(v) === i).join(" · ")
            onClicked: CornerState.openShow(wantedRow.show)
            trailing: [
                IrisIconButton {
                    materialIcon: "close"
                    opacity: wantedRow.buttonHovered || activeFocus ? 1 : 0
                    Accessible.name: Translation.tr("Remove")
                    onClicked: CornerWatch.toggleWatchlist(wantedRow.show)
                }
            ]
        }
    }

    CornerHeading {
        Layout.topMargin: Math.round(10 * root.d)
        eyebrow: Translation.tr("Yours")
        title: Translation.tr("Watching")
        glyph: "play_circle"
        tint: IrisStyle.identity.green
        link: Translation.tr("See all")
        onLinkClicked: CornerState.pick("history")
    }
    Failure {
        shown: CornerWatch.progressLoadFailed
        text: Translation.tr("Could not load playback history")
        onRetry: CornerWatch.retryProgressLoad()
    }
    IrisText {
        visible: CornerWatch.progressLoaded && CornerWatch.watchingKeys.length === 0
        Layout.fillWidth: true
        text: CornerState.savedQuery.trim() ? Translation.tr("Nothing here yet") : Translation.tr("What you watch shows here")
        color: IrisStyle.textTertiary
        font.pixelSize: IrisStyle.typeMeta
        wrapMode: Text.WordWrap
    }
    Repeater {
        model: CornerWatch.watchingKeys
        ColumnLayout {
            id: watchingRow
            required property string modelData
            required property int index
            readonly property var entry: CornerWatch.progress[watchingRow.modelData]
            readonly property bool playingNow: CornerWatch.current?.key === watchingRow.modelData
            Layout.fillWidth: true
            spacing: Math.round(4 * root.d)
            CornerRow {
                id: entryRow
                Layout.fillWidth: true
                number: watchingRow.index + 1
                image: String(watchingRow.entry?.show?.image ?? "")
                glyph: watchingRow.entry?.show?.kind === "anime" ? "animation" : "movie"
                title: String(watchingRow.entry?.show?.title ?? "")
                detail: watchingRow.playingNow ? Translation.tr("Now playing") : root.episodeText(watchingRow.entry?.episode) || Streams.clock(Number(watchingRow.entry?.position ?? 0))
                progress: Number(watchingRow.entry?.duration) > 0 ? Number(watchingRow.entry.position) / Number(watchingRow.entry.duration) : -1
                onClicked: {
                    if (!watchingRow.entry?.show) return
                    CornerState.openShow(watchingRow.entry.show)
                    CornerWatch.begin(watchingRow.entry.show, watchingRow.entry.episode ?? null)
                }
                trailing: [
                    IrisIconButton {
                        materialIcon: "close"
                        enabled: !watchingRow.playingNow
                        opacity: entryRow.buttonHovered || activeFocus ? 1 : 0
                        Accessible.name: Translation.tr("Remove history entry")
                        onClicked: root.pendingRemoval = watchingRow.modelData
                    }
                ]
            }
            RowLayout {
                visible: root.pendingRemoval === watchingRow.modelData
                Layout.fillWidth: true
                Layout.leftMargin: Math.round(56 * root.d)
                spacing: Math.round(6 * root.d)
                CornerPill {
                    tone: "solid"
                    label: Translation.tr("Confirm remove history entry")
                    onClicked: { CornerWatch.forget(watchingRow.modelData); root.pendingRemoval = "" }
                }
                CornerPill { label: Translation.tr("Cancel"); onClicked: root.pendingRemoval = "" }
            }
        }
    }

    component Failure: RowLayout {
        id: failure
        property bool shown: false
        property string text: ""
        signal retry()
        visible: failure.shown
        Layout.fillWidth: true
        IrisText { Layout.fillWidth: true; text: failure.text; color: IrisStyle.danger; wrapMode: Text.WordWrap; font.pixelSize: IrisStyle.typeMeta }
        IrisButton { quiet: true; text: Translation.tr("Retry"); onClicked: failure.retry() }
    }
}
