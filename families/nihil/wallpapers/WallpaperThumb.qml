pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style

// One wallpaper in the grid: its picture (the cached thumbnail, the picture itself while there is none, a video's
// first frame), its name under it; the one in use carries a lit badge, the one the keys are on rises a touch.
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
        x: NihilStyle.s(5)
        y: NihilStyle.s(5) - (root.focused ? NihilStyle.s(2) : 0)
        width: root.width - NihilStyle.s(10)
        height: Math.round(width * 10 / 16)
        radius: NihilStyle.rowRadius
        color: NihilStyle.well
        Behavior on y { NumberAnimation { duration: NihilStyle.quick } }

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
            x: NihilStyle.s(8); y: NihilStyle.s(8)
            width: badge.implicitWidth + NihilStyle.s(20)
            height: NihilStyle.s(26)
            radius: height / 2
            color: NihilStyle.accent
            Row {
                id: badge
                anchors.centerIn: parent
                spacing: NihilStyle.s(4)
                NIcon { anchors.verticalCenter: parent.verticalCenter; text: "check"; size: NihilStyle.s(14); color: NihilStyle.onAccent }
                NText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr("In use")
                    font.pixelSize: NihilStyle.textSmall
                    font.weight: Font.DemiBold
                    color: NihilStyle.onAccent
                }
            }
        }
        Rectangle {
            visible: root.video
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: NihilStyle.s(8)
            width: NihilStyle.s(26); height: width; radius: width / 2
            color: NihilStyle.piece
            NIcon { anchors.centerIn: parent; text: "play_arrow"; size: NihilStyle.s(16); color: NihilStyle.ink }
        }
    }

    NText {
        x: frame.x + NihilStyle.s(4)
        y: frame.y + frame.height + NihilStyle.s(7)
        width: frame.width - NihilStyle.s(8)
        text: FileUtils.fileNameForPath(root.path).replace(/\.[^.]+$/, "")
        font.pixelSize: NihilStyle.textSmall
        color: root.current || root.focused ? NihilStyle.ink : NihilStyle.inkSoft
    }

    MouseArea {
        id: hand
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
    }
}
