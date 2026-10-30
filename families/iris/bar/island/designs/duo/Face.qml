pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Duo: the time and the live thing as two beads on one thread. Nothing playing, it is the time alone; a song opens the
// second bead (cover and its pulse) joined to the first by a bridge.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property real bead: Math.round(root.h - 10 * root.d)
    readonly property real contentWidth: row.implicitWidth
    readonly property var player: MprisController.activePlayer
    readonly property bool live: MprisController.isPlaying && String(root.player?.trackTitle ?? "").length > 0

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: root.bead
            width: clock.implicitWidth + Math.round(20 * root.d)
            radius: height / 2
            color: IrisStyle.fillQuiet
            IrisClock {
                id: clock
                anchors.centerIn: parent
                pixelSize: Math.round((root.island?.figureSize ?? IrisStyle.typeHeadline) * 0.92)
                family: root.island?.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(pixelSize)
                separatorColor: root.island?.clockAccent ?? IrisStyle.accent
            }
        }
        Rectangle {
            visible: root.live
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(10 * root.d)
            height: Math.round(root.bead * 0.42)
            color: IrisStyle.fillQuiet
        }
        Rectangle {
            visible: root.live
            anchors.verticalCenter: parent.verticalCenter
            height: root.bead
            width: liveRow.implicitWidth + Math.round(12 * root.d)
            radius: height / 2
            color: IrisStyle.tintFill(IrisStyle.accent)
            Row {
                id: liveRow
                anchors.centerIn: parent
                spacing: Math.round(6 * root.d)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.round(root.bead - 8 * root.d); height: width; radius: width / 2
                    clip: true
                    color: IrisStyle.fillActive
                    Image { anchors.fill: parent; source: String(root.player?.trackArtUrl ?? ""); fillMode: Image.PreserveAspectCrop; sourceSize.width: 64; sourceSize.height: 64; asynchronous: true }
                }
                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "graphic_eq"
                    iconSize: Math.round(16 * root.d)
                    color: IrisStyle.accent
                }
            }
        }
    }
}
