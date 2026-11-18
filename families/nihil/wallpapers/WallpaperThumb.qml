pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style

// One wallpaper in the block: the picture filling its tile (the cached thumbnail, the picture itself while there is none,
// a video's first frame). The one in use carries the signal's tile; the one the hand or the keys are on shows its name.
Item {
    id: root

    property string path: ""
    property bool current: false
    property bool focused: false
    property bool live: true
    readonly property bool hovered: hand.containsMouse
    signal picked()

    readonly property bool video: Wallpapers.isVideoFile(root.path)
    property bool fallback: false
    onPathChanged: root.fallback = false

    ClippingRectangle {
        id: frame
        width: root.width - NihilStyle.seam
        height: root.height - NihilStyle.seam
        radius: NihilStyle.rowRadius
        color: NihilStyle.well

        Image {
            id: picture
            anchors.fill: parent
            asynchronous: true
            cache: false
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: Math.round(frame.width * 1.5)
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: NihilStyle.quick } }
            source: !root.live || root.path.length === 0 ? ""
                : root.video ? "file://" + Wallpapers.getVideoFirstFramePath(root.path)
                : root.fallback ? "file://" + root.path
                : "file://" + Wallpapers.getExpectedThumbnailPath(root.path, "large")
            onStatusChanged: {
                if (status !== Image.Error || root.fallback || root.video) return
                Wallpapers.ensureThumbnailForPath(root.path, "large")
                root.fallback = true
            }
        }
        Rectangle {
            anchors.fill: parent
            color: NihilStyle.ink
            opacity: hand.pressed ? 0.12 : 0
        }

        Rectangle {
            visible: root.current
            x: NihilStyle.s(6)
            y: NihilStyle.s(6)
            width: NihilStyle.s(30); height: width
            radius: NihilStyle.s(7)
            color: NihilStyle.accent
            NIcon { anchors.centerIn: parent; text: "check"; size: NihilStyle.s(18); weight: 2.6; color: NihilStyle.onAccent }
        }
        Rectangle {
            visible: root.video
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: NihilStyle.s(6)
            width: NihilStyle.s(30); height: width
            radius: NihilStyle.s(7)
            color: NihilStyle.piece
            NIcon { anchors.centerIn: parent; text: "play_arrow"; size: NihilStyle.s(18); color: NihilStyle.ink }
        }
        Rectangle {
            visible: root.focused
            x: NihilStyle.s(6)
            width: Math.min(name.implicitWidth + NihilStyle.s(16), frame.width - NihilStyle.s(12))
            height: NihilStyle.s(26)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: NihilStyle.s(6)
            radius: NihilStyle.s(7)
            color: NihilStyle.plate
            NText {
                id: name
                x: NihilStyle.s(8)
                width: parent.width - NihilStyle.s(16)
                anchors.verticalCenter: parent.verticalCenter
                text: FileUtils.fileNameForPath(root.path).replace(/\.[^.]+$/, "")
                font.pixelSize: NihilStyle.textSmall
                font.weight: Font.Bold
                color: NihilStyle.onPlate
            }
        }
    }

    MouseArea {
        id: hand
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
    }
}
