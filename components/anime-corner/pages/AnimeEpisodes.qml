pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.state
import "../state"

// A show's episodes as numbers, to play any one: the ones seen dimmed with a tick, the one you are on lit with how
// far into it you are. A long show (One Piece) is walked a hundred at a time, opening on the hundred you are in.
ColumnLayout {
    id: root
    // ani-cli's history entry for the show, or null when it was never watched.
    property var entry: null
    // The title ani-cli searches when there is no entry.
    property string title: ""
    // The AniList show, so the engine finds it by all its names on every site.
    property var show: null
    property int count: 0
    readonly property real d: IrisStyle.density
    readonly property string current: root.entry ? CornerWatch.stateOf(root.entry).episode : ""
    readonly property int perRange: 100
    readonly property int ranges: Math.max(1, Math.ceil(root.count / root.perRange))
    property int range: 0
    readonly property int first: root.range * root.perRange + 1
    readonly property int last: Math.min(root.count, (root.range + 1) * root.perRange)

    function home(): void {
        const at = Number(root.current) || 1
        root.range = Math.max(0, Math.min(root.ranges - 1, Math.floor((at - 1) / root.perRange)))
    }
    onCurrentChanged: root.home()
    onCountChanged: root.home()
    onEntryChanged: root.home()

    visible: root.count > 0
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
            text: root.current.length > 0 ? Translation.tr("On episode %1").arg(root.current) : Translation.tr("%1 episodes").arg(root.count)
            color: IrisStyle.muted
            font.pixelSize: IrisStyle.typeFootnote
        }
        Item { Layout.fillWidth: true }
        IrisIconButton {
            visible: root.ranges > 1
            enabled: root.range > 0
            materialIcon: "chevron_left"
            Accessible.name: Translation.tr("Previous episodes")
            onClicked: root.range--
        }
        IrisText {
            visible: root.ranges > 1
            text: "%1–%2".arg(root.first).arg(root.last)
            font.pixelSize: IrisStyle.typeLabel
            font.weight: IrisStyle.weight(Font.DemiBold)
            font.features: { "tnum": 1 }
        }
        IrisIconButton {
            visible: root.ranges > 1
            enabled: root.range < root.ranges - 1
            materialIcon: "chevron_right"
            Accessible.name: Translation.tr("Next episodes")
            onClicked: root.range++
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: Math.round(6 * root.d)
        Repeater {
            model: Math.max(0, root.last - root.first + 1)
            delegate: MouseArea {
                id: cell
                required property int index
                readonly property string episode: String(root.first + cell.index)
                readonly property var state: CornerWatch.episodeState(root.entry, cell.episode)
                readonly property bool here: cell.episode === root.current
                width: Math.round(54 * root.d)
                height: Math.round(40 * root.d)
                enabled: CornerWatch.canTarget && CornerWatch.canStart
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: Translation.tr("Play episode %1").arg(cell.episode)
                onClicked: {
                    CornerWatch.lookFor(root.show)
                    CornerWatch.play(root.entry, root.title, cell.episode)
                }

                Rectangle {
                    anchors.fill: parent
                    radius: IrisStyle.tileRadius(height)
                    color: cell.here ? IrisStyle.accentContainer
                        : cell.containsMouse ? IrisStyle.tintFillHover(IrisStyle.accent) : IrisStyle.fillQuiet
                    border.width: 1
                    border.color: cell.here ? IrisStyle.tintBorder(IrisStyle.accent) : IrisStyle.hairline
                    clip: true
                    Row {
                        anchors.centerIn: parent
                        spacing: Math.round(2 * root.d)
                        MaterialSymbol {
                            visible: cell.state.seen
                            anchors.verticalCenter: parent.verticalCenter
                            text: "check"
                            iconSize: Math.round(14 * root.d)
                            color: IrisStyle.muted
                        }
                        IrisText {
                            text: cell.episode
                            color: cell.here ? IrisStyle.inkOnAccentContainer : cell.state.seen ? IrisStyle.muted : IrisStyle.text
                            font.pixelSize: IrisStyle.typeLabel
                            font.weight: IrisStyle.weight(cell.here ? Font.Bold : Font.Medium)
                            font.features: { "tnum": 1 }
                        }
                    }
                    // How far into it, along its foot.
                    Rectangle {
                        visible: !cell.state.seen && cell.state.progress > 0
                        anchors { left: parent.left; bottom: parent.bottom }
                        width: parent.width * cell.state.progress
                        height: Math.round(3 * root.d)
                        color: IrisStyle.identity.orange
                    }
                }
            }
        }
    }
}
