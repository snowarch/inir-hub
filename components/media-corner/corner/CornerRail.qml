import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

Rectangle {
    id: root
    readonly property real d: IrisStyle.density
    readonly property var recentKeys: Object.keys(CornerWatch.progress).filter(key => CornerWatch.progress[key]?.show).sort((a, b) => CornerWatch.progress[b].at - CornerWatch.progress[a].at)
    readonly property var recent: recentKeys.length ? CornerWatch.progress[recentKeys[0]] : null
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
            model: root.listExpanded ? Object.keys(CornerWatch.watchlist) : []
            delegate: IrisButton {
                required property string modelData
                width: ListView.view.width
                quiet: true
                text: String(CornerWatch.watchlist[modelData]?.title ?? "")
                onClicked: CornerState.openShow(CornerWatch.watchlist[modelData])
            }
        }
        IrisButton {
            Layout.fillWidth: true
            quiet: true
            text: (root.watchingExpanded ? "▾  " : "▸  ") + Translation.tr("Watching")
            onClicked: root.watchingExpanded = !root.watchingExpanded
        }
        Repeater {
            model: root.watchingExpanded ? root.recentKeys.slice(0, 5) : []
            IrisButton {
                required property string modelData
                Layout.fillWidth: true
                quiet: true
                text: String(CornerWatch.progress[modelData]?.show?.title ?? "")
                onClicked: CornerState.openShow(CornerWatch.progress[modelData].show)
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
