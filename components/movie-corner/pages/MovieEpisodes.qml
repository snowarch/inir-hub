pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

// A series' episodes, one season at a time: its picture, number and name, the ones seen with a tick and the one you
// are in with how far. A click plays it; ‹ › walk the seasons, opening on the one Continue is in.
ColumnLayout {
    id: root
    property var show: null
    property var episodes: []
    property var seasons: []
    readonly property real d: IrisStyle.density
    readonly property var next: CornerWatch.nextOf(root.show)
    property int season: 0
    readonly property var shown: root.episodes.filter(e => e.season === root.season)

    function home(): void {
        const wanted = root.next ? Number(root.next.season) : Number(root.seasons[0] ?? 0)
        root.season = root.seasons.includes(wanted) ? wanted : Number(root.seasons[0] ?? 0)
    }
    onSeasonsChanged: root.home()

    visible: root.episodes.length > 0
    spacing: Math.round(10 * root.d)

    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(8 * root.d)
        IrisText {
            text: Translation.tr("Episodes")
            font.family: IrisStyle.fontTitle
            font.pixelSize: IrisStyle.typeTitle
            font.weight: IrisStyle.weight(Font.Bold)
        }
        IrisText {
            Layout.fillWidth: true
            text: root.next ? Translation.tr("On season %1, episode %2").arg(root.next.season).arg(root.next.episode) : Translation.tr("%1 episodes").arg(root.shown.length)
            color: IrisStyle.muted
            font.pixelSize: IrisStyle.typeFootnote
            elide: Text.ElideRight
        }
        IrisIconButton {
            visible: root.seasons.length > 1
            enabled: root.seasons.indexOf(root.season) > 0
            materialIcon: "chevron_left"
            Accessible.name: Translation.tr("Previous season")
            onClicked: root.season = root.seasons[root.seasons.indexOf(root.season) - 1]
        }
        IrisText {
            text: Translation.tr("Season %1").arg(root.season)
            font.pixelSize: IrisStyle.typeLabel
            font.weight: IrisStyle.weight(Font.DemiBold)
            font.features: { "tnum": 1 }
        }
        IrisIconButton {
            visible: root.seasons.length > 1
            enabled: root.seasons.indexOf(root.season) < root.seasons.length - 1
            materialIcon: "chevron_right"
            Accessible.name: Translation.tr("Next season")
            onClicked: root.season = root.seasons[root.seasons.indexOf(root.season) + 1]
        }
    }

    Repeater {
        model: root.shown
        delegate: MouseArea {
            id: row
            required property var modelData
            readonly property var entry: Object.assign({}, root.show ?? {}, { season: row.modelData.season, episode: row.modelData.episode, episodeTitle: row.modelData.title })
            readonly property var state: CornerWatch.stateOf(row.entry)
            readonly property bool here: root.next !== null && root.next.season === row.modelData.season && root.next.episode === row.modelData.episode
            // Not out yet: listed, not playable.
            readonly property bool out: row.modelData.released.length === 0 || Date.parse(row.modelData.released) <= Date.now()
            Layout.fillWidth: true
            implicitHeight: Math.round(72 * root.d)
            enabled: row.out && CornerWatch.canStart
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: Translation.tr("Play episode %1").arg(row.modelData.episode)
            onClicked: CornerWatch.watch(row.entry)

            Rectangle {
                anchors.fill: parent
                radius: IrisStyle.radiusTile
                color: row.here ? IrisStyle.accentContainer : row.containsMouse ? IrisStyle.fillHover : "transparent"
            }
            RowLayout {
                anchors.fill: parent
                anchors.margins: Math.round(6 * root.d)
                spacing: Math.round(12 * root.d)
                ClippingRectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: Math.round(height * 16 / 9)
                    radius: Math.max(4, IrisStyle.radiusTile - Math.round(6 * root.d))
                    color: IrisStyle.fillQuiet
                    IrisImage { anchors.fill: parent; source: /^https:\/\//.test(row.modelData.image) ? row.modelData.image : "" }
                    // How far into it, along its foot.
                    Rectangle {
                        visible: !row.state.finished && row.state.progress > 0
                        anchors { left: parent.left; bottom: parent.bottom }
                        width: parent.width * row.state.progress
                        height: Math.round(3 * root.d)
                        color: IrisStyle.identity.orange
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(2 * root.d)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Math.round(6 * root.d)
                        MaterialSymbol {
                            visible: row.state.finished
                            text: "check"
                            iconSize: Math.round(14 * root.d)
                            color: IrisStyle.muted
                        }
                        IrisText {
                            Layout.fillWidth: true
                            text: Translation.tr("%1. %2").arg(row.modelData.episode).arg(row.modelData.title)
                            textFormat: Text.PlainText
                            color: row.here ? IrisStyle.inkOnAccentContainer : row.state.finished ? IrisStyle.muted : IrisStyle.text
                            font.pixelSize: IrisStyle.typeLabel
                            font.weight: IrisStyle.weight(row.here ? Font.Bold : Font.Medium)
                            elide: Text.ElideRight
                        }
                    }
                    IrisText {
                        Layout.fillWidth: true
                        text: row.out ? row.modelData.overview : Translation.tr("Out on %1").arg(new Date(row.modelData.released).toLocaleDateString(Qt.locale(), Locale.ShortFormat))
                        textFormat: Text.PlainText
                        color: row.here ? IrisStyle.inkOnAccentContainer : IrisStyle.muted
                        font.pixelSize: IrisStyle.typeFootnote
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
