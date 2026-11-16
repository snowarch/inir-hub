import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"
import "../pages"

Rectangle {
    id: root
    readonly property real d: IrisStyle.density
    readonly property var recentKeys: Object.keys(CornerWatch.progress).filter(key => CornerWatch.progress[key]?.show).sort((a, b) => CornerWatch.progress[b].at - CornerWatch.progress[a].at)
    readonly property var filteredRecentKeys: recentKeys.filter(key => CornerWatch.matchesSaved(CornerWatch.progress[key]?.show, CornerState.savedQuery))
    readonly property var recent: recentKeys.length ? CornerWatch.progress[recentKeys[0]] : null
    property string pendingHistoryRemoval: ""
    property bool listExpanded: true
    property bool watchingExpanded: false
    function clockTime(seconds: real): string {
        const value = Number.isFinite(seconds) ? Math.max(0, Math.floor(seconds)) : 0
        return Math.floor(value / 60) + ":" + String(value % 60).padStart(2, "0")
    }
    color: IrisStyle.surfaceHighOpaque
    radius: IrisStyle.radiusPanel
    border.width: 1
    border.color: Qt.alpha(IrisStyle.text, 0.08)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(20 * root.d)
        spacing: Math.round(12 * root.d)
        IrisButton {
            Layout.fillWidth: true
            quiet: true
            text: Translation.tr("Sources")
            onClicked: CornerState.pick("sources")
        }
        SavedFilter { Layout.fillWidth: true }
        SavedSort { Layout.fillWidth: true }
        IrisButton {
            Layout.fillWidth: true
            quiet: true
            text: (root.listExpanded ? "▾  " : "▸  ") + Translation.tr("Want to watch")
            onClicked: root.listExpanded = !root.listExpanded
        }
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: (root.listExpanded || CornerState.savedQuery.trim()) ? CornerWatch.sortedSavedKeys.filter(key => CornerWatch.matchesSaved(CornerWatch.watchlist[key], CornerState.savedQuery)) : []
            delegate: IrisButton {
                required property string modelData
                width: ListView.view.width
                quiet: true
                text: String(CornerWatch.watchlist[modelData]?.title ?? "")
                onClicked: CornerState.openShow(CornerWatch.watchlist[modelData])
            }
        }
        IrisText {
            visible: CornerState.savedQuery.trim().length > 0 && CornerWatch.sortedSavedKeys.filter(key => CornerWatch.matchesSaved(CornerWatch.watchlist[key], CornerState.savedQuery)).length === 0 && root.filteredRecentKeys.length === 0
            Layout.fillWidth: true
            text: Translation.tr("Nothing here yet")
            color: IrisStyle.textTertiary
        }
        IrisButton {
            Layout.fillWidth: true
            quiet: true
            text: (root.watchingExpanded ? "▾  " : "▸  ") + Translation.tr("Watching")
            onClicked: root.watchingExpanded = !root.watchingExpanded
        }
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, Math.round(160 * root.d))
            clip: true
            model: (root.watchingExpanded || CornerState.savedQuery.trim()) ? (CornerState.savedQuery.trim() ? root.filteredRecentKeys : root.filteredRecentKeys.slice(0, 5)) : []
            delegate: ColumnLayout {
                id: historyRow
                required property string modelData
                width: ListView.view.width
                RowLayout {
                    Layout.fillWidth: true
                    IrisButton {
                        Layout.fillWidth: true
                        quiet: true
                        readonly property var entry: CornerWatch.progress[historyRow.modelData]
                        text: String(entry?.show?.title ?? "") + (entry?.episode ? " · " + (entry.episode.season ? entry.episode.season + "×" : "") + entry.episode.episode : "")
                        onClicked: {
                            if (!entry?.show) return
                            CornerState.openShow(entry.show)
                            CornerWatch.begin(entry.show, entry.episode ?? null)
                        }
                    }
                    IrisIconButton {
                        materialIcon: "close"
                        enabled: !(CornerWatch.busy && CornerWatch._current?.key === historyRow.modelData)
                        Accessible.name: Translation.tr("Remove history entry")
                        onClicked: root.pendingHistoryRemoval = historyRow.modelData
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.pendingHistoryRemoval === historyRow.modelData
                    IrisButton {
                        quiet: true
                        Layout.fillWidth: true
                        text: Translation.tr("Confirm remove history entry")
                        onClicked: { CornerWatch.forget(historyRow.modelData); root.pendingHistoryRemoval = "" }
                    }
                    IrisButton { Layout.fillWidth: true; quiet: true; text: Translation.tr("Cancel"); onClicked: root.pendingHistoryRemoval = "" }
                }
            }
        }
        Rectangle {
            visible: CornerWatch.phase === "playing" || root.recent !== null
            Layout.fillWidth: true
            implicitHeight: card.implicitHeight + Math.round(32 * root.d)
            radius: Math.round(28 * root.d)
            color: IrisStyle.surfaceHighestOpaque
            border.width: 1
            border.color: Qt.alpha(IrisStyle.text, 0.08)
            ColumnLayout {
                id: card
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Math.round(16 * root.d)
                spacing: Math.round(8 * root.d)
                IrisText {
                    Layout.fillWidth: true
                    text: CornerWatch.phase === "playing" ? CornerWatch.title : String(root.recent?.show?.title ?? "")
                    color: IrisStyle.text
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                IrisText {
                    id: playbackTime
                    Layout.fillWidth: true
                    readonly property real position: CornerWatch.phase === "playing" ? CornerWatch.position : Number(root.recent?.position ?? 0)
                    readonly property real duration: CornerWatch.phase === "playing" ? CornerWatch.duration : Number(root.recent?.duration ?? 0)
                    text: root.clockTime(position) + (duration > 0 ? " / " + root.clockTime(duration) : "")
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeFootnote
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(3 * root.d)
                    radius: height / 2
                    color: IrisStyle.fillQuiet
                    Rectangle {
                        width: parent.width * (playbackTime.duration > 0 ? Math.max(0, Math.min(1, playbackTime.position / playbackTime.duration || 0)) : 0)
                        height: parent.height
                        radius: height / 2
                        color: IrisStyle.text
                    }
                }
                RowLayout {
                    visible: CornerWatch.phase === "playing"
                    Layout.alignment: Qt.AlignHCenter
                    IrisIconButton {
                        materialIcon: "replay_10"
                        enabled: CornerWatch.controlLinked
                        Accessible.name: Translation.tr("Seek backward")
                        onClicked: CornerWatch.control("back")
                    }
                    IrisIconButton {
                        materialIcon: CornerWatch.paused ? "play_arrow" : "pause"
                        enabled: CornerWatch.controlLinked
                        Accessible.name: Translation.tr(CornerWatch.paused ? "Resume" : "Pause")
                        onClicked: CornerWatch.control("pause")
                    }
                    IrisIconButton {
                        materialIcon: "forward_10"
                        enabled: CornerWatch.controlLinked
                        Accessible.name: Translation.tr("Seek forward")
                        onClicked: CornerWatch.control("forward")
                    }
                }
                RowLayout {
                    visible: CornerWatch.phase === "playing"
                    Layout.alignment: Qt.AlignHCenter
                    IrisIconButton {
                        materialIcon: "remove"
                        enabled: CornerWatch.controlLinked
                        Accessible.name: Translation.tr("Show subtitles earlier")
                        onClicked: CornerWatch.control("subtitleEarlier")
                    }
                    IrisText {
                        text: Translation.tr("Subtitle delay: %1 s").arg(CornerWatch.subtitleDelay.toFixed(1))
                        color: IrisStyle.textSecondary
                        font.pixelSize: IrisStyle.typeFootnote
                    }
                    IrisIconButton {
                        materialIcon: "add"
                        enabled: CornerWatch.controlLinked
                        Accessible.name: Translation.tr("Show subtitles later")
                        onClicked: CornerWatch.control("subtitleLater")
                    }
                    IrisIconButton {
                        materialIcon: CornerWatch.fullscreen ? "fullscreen_exit" : "fullscreen"
                        enabled: CornerWatch.controlLinked
                        Accessible.name: CornerWatch.fullscreen ? Translation.tr("Exit fullscreen") : Translation.tr("Fullscreen")
                        onClicked: CornerWatch.control("fullscreen")
                    }
                }
                PlaybackTracks { Layout.fillWidth: true }
                IrisButton {
                    Layout.fillWidth: true
                    quiet: true
                    text: Translation.tr(CornerWatch.phase === "playing" ? "Stop" : "Continue")
                    onClicked: {
                        if (CornerWatch.phase === "playing") CornerWatch.stop()
                        else if (root.recent?.show) CornerWatch.begin(root.recent.show, root.recent.episode ?? null)
                    }
                }
            }
        }
    }
}
