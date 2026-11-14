pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"
import "../state/streams.js" as Streams

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
        // What has aired: the next one to air says so while it runs; otherwise AniList's count.
        const aired = Number(root.show?.nextEpisode ?? 0) > 0 ? root.show.nextEpisode - 1 : Number(root.show?.episodes) || 0
        const out = []
        for (let first = 1; first <= aired; first += root.perGroup) {
            const last = Math.min(aired, first + root.perGroup - 1), episodes = []
            for (let n = first; n <= last; n++) episodes.push({ episode: n })
            out.push({ label: `${first}–${last}`, episodes })
        }
        return out
    }
    property int picked: 0
    readonly property int group: Math.min(root.picked, Math.max(0, root.groups.length - 1))
    onShowChanged: root.picked = 0

    visible: root.groups.length > 0
    Layout.fillWidth: true
    spacing: Math.round(8 * root.d)

    IrisText {
        text: Translation.tr("Episodes")
        font.pixelSize: IrisStyle.typeHeadline
        font.weight: IrisStyle.weight(Font.Bold)
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
    Flow {
        Layout.fillWidth: true
        spacing: Math.round(6 * root.d)
        Repeater {
            model: root.groups[root.group]?.episodes ?? []
            IrisChip {
                required property var modelData
                glyph: root.show && CornerWatch.isSeen(Streams.watchKey(root.show, modelData)) ? "check" : ""
                label: modelData.title ? `${modelData.episode}. ${modelData.title}` : String(modelData.episode)
                Accessible.description: Translation.tr("Watch episode %1").arg(modelData.episode)
                onClicked: CornerWatch.begin(root.show, modelData)
            }
        }
    }
}
