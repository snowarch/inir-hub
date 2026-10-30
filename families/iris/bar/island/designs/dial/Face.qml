pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.bar.island

// Dial: the day as a ring around its own number, lit as far as the day has gone; the time beside it. While a song
// plays the ring is the song instead, in the accent. It moves with the minute (or the song's second), never between.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property real contentWidth: row.implicitWidth
    readonly property date now: DateTime.clock.date
    readonly property real dayFraction: (root.now.getHours() * 60 + root.now.getMinutes()) / 1440
    readonly property var player: MprisController.activePlayer
    readonly property bool song: MprisController.isPlaying && (root.player?.length ?? 0) > 0
    readonly property real songFraction: root.song ? Math.max(0, Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))) : 0

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(9 * root.d)
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(root.h - 10 * root.d)
            height: width
            Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border.width: Math.max(2, Math.round(2.5 * root.d)); border.color: IrisStyle.hairline }
            ProgressRing {
                anchors.fill: parent
                progress: root.song ? root.songFraction : root.dayFraction
                tint: root.song ? IrisStyle.accent : (root.island?.clockAccent ?? IrisStyle.secondaryAccent)
            }
            IrisText {
                anchors.centerIn: parent
                text: Translation.locale.toString(root.now, "d")
                font.pixelSize: Math.round(12 * root.d)
                font.family: IrisStyle.fontNumbers
                font.weight: IrisStyle.weight(Font.Bold)
                font.features: ({ "tnum": 1 })
                color: IrisStyle.text
            }
        }
        IrisClock {
            anchors.verticalCenter: parent.verticalCenter
            pixelSize: root.island?.figureSize ?? IrisStyle.typeHeadline
            family: root.island?.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(pixelSize)
            separatorColor: root.island?.clockAccent ?? IrisStyle.accent
        }
    }
}
