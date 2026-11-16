pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"
import "../state/streams.js" as Streams
import "../state/watch.js" as Watch

// A show's episodes: a series by season (Cinemeta), an anime in hundreds (AniList only gives how many). Each opens Watch.
ColumnLayout {
    id: root
    required property var show
    readonly property real d: IrisStyle.density
    readonly property int perGroup: 100

    // [{ label, episodes: [{ season?, episode, title? }] }]
    readonly property var groups: {
        if (root.show?.kind === "series") {
            const all = Array.from(root.show.episodes ?? [])
            return Array.from(root.show.seasons ?? []).map(season => ({
                label: Translation.tr("Season %1").arg(season),
                episodes: all.filter(e => e.season === season).map(e => ({ season, episode: e.episode, title: e.title }))
            }))
        }
        // A total alone does not say what has aired. Use it only for finished titles.
        const aired = Number(root.show?.nextEpisode ?? 0) > 0 ? root.show.nextEpisode - 1
            : root.show?.status === "FINISHED" ? Number(root.show?.episodes) || 0 : 0
        const out = []
        for (let first = 1; first <= aired; first += root.perGroup) {
            const last = Math.min(aired, first + root.perGroup - 1), episodes = []
            for (let n = first; n <= last; n++) episodes.push({ episode: n })
            out.push({ label: `${first}–${last}`, episodes })
        }
        return out
    }
    property bool markingEpisodes: false
    property int picked: 0
    readonly property int group: Math.min(root.picked, Math.max(0, root.groups.length - 1))
    readonly property var nextUnseen: root.show?.kind === "series"
        ? Watch.nextUnseen(root.groups, CornerWatch.progress,
            episode => Streams.watchKey(root.show, episode),
            key => CornerWatch.isSeen(key), 0)
        : null
    readonly property var summary: Watch.summarizeEpisodes(root.groups[root.group]?.episodes ?? [],
        CornerWatch.progress, CornerWatch.seenMarks, episode => Streams.watchKey(root.show, episode))
    onShowChanged: { root.picked = 0; root.markingEpisodes = false }

    visible: root.groups.length > 0
    Layout.fillWidth: true
    spacing: Math.round(8 * root.d)

    IrisText {
        text: Translation.tr("Episodes")
        font.pixelSize: IrisStyle.typeHeadline
        font.weight: IrisStyle.weight(Font.Bold)
    }
    IrisButton {
        visible: root.nextUnseen !== null
        text: Translation.tr("Continue series")
        onClicked: CornerWatch.begin(root.show, root.nextUnseen)
    }
    Flow {
        Layout.fillWidth: true
        visible: root.groups.length > 1
        spacing: Math.round(6 * root.d)
        Repeater {
            model: root.groups
            IrisButton {
                required property var modelData
                required property int index
                quiet: index !== root.group
                text: modelData.label
                onClicked: root.picked = index
            }
        }
    }
    IrisText {
        Layout.fillWidth: true
        visible: CornerWatch.seenMarksLoaded && CornerWatch.progressLoaded
        text: Translation.tr("%1 of %2 known episodes watched").arg(root.summary.watched).arg(root.summary.known)
        color: IrisStyle.textSecondary
    }
    IrisText {
        Layout.fillWidth: true
        visible: CornerWatch.seenMarksLoaded && CornerWatch.progressLoaded
        text: root.summary.next ? Translation.tr("Next known unwatched episode: %1").arg(root.summary.next.episode) : Translation.tr("No known unwatched episodes")
        color: IrisStyle.textSecondary
    }
    IrisButton {
        enabled: CornerWatch.seenMarksLoaded
        quiet: true
        text: root.markingEpisodes ? Translation.tr("Done marking episodes") : Translation.tr("Mark episodes watched or unwatched")
        onClicked: root.markingEpisodes = !root.markingEpisodes
    }
    Flow {
        Layout.fillWidth: true
        spacing: Math.round(6 * root.d)
        Repeater {
            model: root.groups[root.group]?.episodes ?? []
            IrisChip {
                required property var modelData
                glyph: root.show && CornerWatch.isSeen(Streams.watchKey(root.show, modelData)) ? "check" : ""
                label: modelData.title ? `${modelData.episode}. ${modelData.title}` : String(modelData.episode)
                Accessible.description: root.markingEpisodes
                    ? (CornerWatch.isSeen(Streams.watchKey(root.show, modelData)) ? Translation.tr("Mark episode %1 as unwatched") : Translation.tr("Mark episode %1 as watched")).arg(modelData.episode)
                    : Translation.tr("Watch episode %1").arg(modelData.episode)
                onClicked: {
                    if (root.markingEpisodes) {
                        const key = Streams.watchKey(root.show, modelData)
                        CornerWatch.setSeen(key, !CornerWatch.isSeen(key))
                    } else CornerWatch.begin(root.show, modelData)
                }
            }
        }
    }
    Flow {
        Layout.fillWidth: true
        spacing: Math.round(6 * root.d)
        Repeater {
            model: CornerWatch.busy && CornerWatch.show?.id === root.show?.id ? [] : (root.groups[root.group]?.episodes ?? []).filter(episode => Boolean(CornerWatch.progress[Streams.watchKey(root.show, episode)]?.position))
            IrisButton {
                required property var modelData
                quiet: true
                text: Translation.tr("Reset episode %1 progress").arg(modelData.episode)
                onClicked: CornerWatch.resetProgress(Streams.watchKey(root.show, modelData))
            }
        }
    }
}
