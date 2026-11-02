pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Duo · Eclipse: the time on its bead and a moon passing over the bead's end. Nothing playing, it is tonight's moon in
// its real phase; a song turns it into the cover, and a shadow crosses the cover as the song runs out.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property real bead: Math.round(root.h - 10 * root.d)
    readonly property real moon: Math.round(root.bead + 2 * root.d)
    readonly property real contentWidth: Math.round(time.width + root.moon * 0.7)
    readonly property date now: DateTime.clock.date
    readonly property var player: MprisController.activePlayer
    readonly property bool live: MprisController.isPlaying && String(root.player?.trackTitle ?? "").length > 0
    readonly property real progress: root.live ? Math.max(0, Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))) : 0
    // Days into the lunar month (0 new, ~14.8 full), from a known new moon (2000-01-06 18:14 UTC).
    readonly property real lunar: {
        const synodic = 29.530588853
        const age = ((root.now.getTime() - Date.UTC(2000, 0, 6, 18, 14)) / 86400000) % synodic
        return (age < 0 ? age + synodic : age) / synodic
    }
    // Where the shadow disc sits, in moon widths: 0 covers it, +-1 is clear. A song wanes from full to dark.
    readonly property real shade: root.live ? 1 - root.progress
        : root.lunar < 0.5 ? -2 * root.lunar : 2 * (1 - root.lunar)

    Item {
        anchors.centerIn: parent
        width: root.contentWidth
        height: root.moon

        Rectangle {
            id: time
            anchors.verticalCenter: parent.verticalCenter
            height: root.bead
            width: clock.implicitWidth + Math.round(20 * root.d) + Math.round(root.moon * 0.3)
            radius: height / 2
            color: IrisStyle.fillQuiet
            IrisClock {
                id: clock
                anchors.verticalCenter: parent.verticalCenter
                x: Math.round(10 * root.d)
                pixelSize: Math.round((root.island?.figureSize ?? IrisStyle.typeHeadline) * 0.92)
                family: root.island?.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(pixelSize)
                separatorColor: root.island?.clockAccent ?? IrisStyle.accent
            }
        }
        ClippingRectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width - width
            width: root.moon
            height: width
            radius: width / 2
            color: root.live ? IrisStyle.fillActive : ColorUtils.applyAlpha(IrisStyle.text, 0.86)
            border.width: 1
            border.color: IrisStyle.hairlineStrong
            Image {
                id: cover
                anchors.fill: parent
                visible: root.live
                source: root.live ? String(root.player?.trackArtUrl ?? "") : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: width * 2
                sourceSize.height: height * 2
                asynchronous: true
            }
            MaterialSymbol {
                anchors.centerIn: parent
                visible: root.live && cover.status !== Image.Ready
                text: "music_note"
                iconSize: Math.round(parent.width * 0.55)
                color: IrisStyle.text
            }
            Rectangle {
                x: Math.round(root.shade * parent.width)
                width: parent.width
                height: parent.height
                radius: width / 2
                color: root.live ? IrisStyle.veilStrong : IrisStyle.surfaceOpaque
                Behavior on x { enabled: IrisStyle.motionEnabled; NumberAnimation { duration: IrisStyle.duration(900); easing.type: Easing.OutCubic } }
            }
        }
    }
}
