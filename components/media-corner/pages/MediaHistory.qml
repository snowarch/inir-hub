pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../state"
import "../state/watch.js" as Watch

ColumnLayout {
    id: root
    readonly property real d: IrisStyle.density
    readonly property var rows: Watch.historyRows(CornerWatch.progress)
    CornerHeading { page: true; eyebrow: Translation.tr("Library"); title: Translation.tr("Watch history") }
    IrisText {
        visible: CornerWatch.progressLoaded && root.rows.length === 0
        Layout.fillWidth: true
        text: Translation.tr("Nothing here yet")
    }
    RowLayout {
        visible: !CornerWatch.progressLoaded
        Layout.fillWidth: true
        IrisText {
            Layout.fillWidth: true
            text: CornerWatch.progressLoadFailed ? Translation.tr("Could not load playback history") : Translation.tr("Looking…")
            wrapMode: Text.WordWrap
        }
        IrisButton {
            visible: CornerWatch.progressLoadFailed
            text: Translation.tr("Retry")
            onClicked: CornerWatch.retryProgressLoad()
        }
    }
    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: root.rows
        delegate: Loader {
            id: row
            required property var modelData
            width: ListView.view.width
            sourceComponent: modelData.heading ? heading : entry
            Component {
                id: heading
                IrisText {
                    width: row.width
                    text: row.modelData.title
                    textFormat: Text.PlainText
                    font.weight: IrisStyle.weight(Font.Bold)
                    elide: Text.ElideRight
                    topPadding: Math.round(10 * root.d)
                }
            }
            Component {
                id: entry
                IrisButton {
                    id: entryButton
                    readonly property var kept: CornerWatch.progress[row.modelData.key]
                    readonly property var episode: row.modelData.episode
                    width: row.width
                    quiet: true
                    readonly property string caption: episode ? Translation.tr("Episode %1").arg(episode.episode) + (episode.season ? " · " + Translation.tr("Season %1").arg(episode.season) : "") : Translation.tr("Film")
                    Accessible.name: row.modelData.title + " · " + caption
                    implicitHeight: Math.round(44 * root.d)
                    IrisText {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(12 * root.d)
                        verticalAlignment: Text.AlignVCenter
                        textFormat: Text.PlainText
                        text: entryButton.caption
                    }
                    onClicked: {
                        if (!kept?.show) return
                        CornerState.openShow(kept.show)
                        CornerWatch.begin(kept.show, kept.episode ?? null)
                    }
                }
            }
        }
    }
}
