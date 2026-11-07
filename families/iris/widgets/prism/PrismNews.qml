pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.services.deferred
import qs.modules.iris.widgets

// News in Prism: the source on the tab, how long ago on the flap, the headline in the pane, the next ones on the foot.
// A tap opens the story. Before the first headline arrives, the pane says why: fetching, offline, or a feed that failed.
PrismFolder {
    id: root

    readonly property var stories: {
        const all = Array.from(NewsService.articles ?? [])
        if (all.length === 0)
            return []
        const start = root.widget.headlineIndex % all.length
        return all.slice(start).concat(all.slice(0, start)).slice(0, root.small ? 1 : root.medium ? 2 : 4)
    }
    readonly property var lead: root.stories[0] ?? null
    readonly property bool offline: !Network.online
    readonly property bool failed: !root.offline && NewsService.lastError.length > 0 && !NewsService.loading

    tabGlyph: "newspaper"
    tabText: root.lead ? String(root.lead.source || Translation.tr("News")) : Translation.tr("News")
    flapText: root.lead ? NewsService.formatTime(root.lead.timestamp) : root.offline ? Translation.tr("Offline") : ""

    FaceText {
        id: headline
        face: root
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.paneMiddle - height / 2)
        text: root.lead ? IrisFaceData.unwidowed(String(root.lead.title ?? ""))
            : root.offline ? Translation.tr("Offline") : root.failed ? Translation.tr("Headlines didn't load") : Translation.tr("Fetching headlines…")
        color: root.lead ? root.ink : root.inkSecondary
        size: root.type(14, 16, 21)
        weight: Font.Bold
        lineHeight: 0.96
        wrapMode: Text.WordWrap
        maximumLineCount: root.large ? 4 : 3
        elide: Text.ElideRight
        HoverHandler { cursorShape: root.lead ? Qt.PointingHandCursor : Qt.ArrowCursor }
        TapHandler { enabled: root.lead !== null; onTapped: NewsService.openArticle(root.lead) }
    }
    FaceText {
        visible: !root.lead || root.small
        face: root
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.footTop + (root.footHeight - height) / 2 - root.dp(2))
        text: root.lead ? String(root.lead.source ?? "") : root.offline ? Network.offlineReason : root.failed ? Translation.tr("The feed did not answer") : ""
        color: root.inkTertiary
        size: 12.5
        weight: Font.Medium
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
    }
    Column {
        visible: !root.small
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.large ? root.footTop + root.dp(20) : root.footTop + (root.footHeight - height) / 2 - root.dp(2))
        spacing: root.dp(12)
        Repeater {
            model: root.small ? [] : root.stories.slice(1)
            Item {
                id: story
                required property var modelData
                width: root.innerWidth
                height: storyTitle.height + storyWhen.height
                FaceText {
                    id: storyTitle
                    face: root
                    width: parent.width
                    text: String(story.modelData.title ?? "")
                    size: root.type(13, 13.5, 15)
                    weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                FaceText {
                    id: storyWhen
                    face: root
                    y: storyTitle.height
                    width: parent.width
                    text: String(story.modelData.source ?? "") + " · " + NewsService.formatTime(story.modelData.timestamp)
                    color: root.inkTertiary
                    size: 11.5
                    weight: Font.Medium
                    elide: Text.ElideRight
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: NewsService.openArticle(story.modelData) }
            }
        }
    }
}
