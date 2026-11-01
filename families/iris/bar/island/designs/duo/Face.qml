pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
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
            height: Math.round(3 * root.d)
            color: IrisStyle.fillActive
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
                ClippingRectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.round(root.bead - 8 * root.d); height: width; radius: width / 2
                    color: IrisStyle.fillActive
                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: cover.status !== Image.Ready
                        text: "music_note"
                        iconSize: Math.round(parent.width * 0.6)
                        color: IrisStyle.text
                    }
                    Image {
                        id: cover
                        anchors.fill: parent
                        source: String(root.player?.trackArtUrl ?? "")
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: width * 2
                        sourceSize.height: height * 2
                        asynchronous: true
                    }
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
