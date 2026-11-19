pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style

// One wallpaper: the cached thumbnail filling its place, the picture itself while there is none, a video's first frame.
// The one in use carries a check; the one under the hand or the keys shows its name.
Item {
    id: root

    property string path: ""
    property bool current: false
    property bool focused: false
    property bool live: true
    property bool fallback: false

    readonly property bool hovered: hand.containsMouse
    readonly property bool video: Wallpapers.isVideoFile(root.path)

    signal picked()

    onPathChanged: root.fallback = false

    ClippingRectangle {
        id: frame
        anchors.fill: parent
        anchors.margins: NihilStyle.s(4)
        radius: NihilStyle.rCard
        color: NihilStyle.piece

        Image {
            anchors.fill: parent
            asynchronous: true
            cache: false
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: Math.round(frame.width * 1.5)
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: NihilStyle.quick } }
            // A video whose first frame is not made yet has no file to show: nothing, not the root folder.
            readonly property string file: !root.live || root.path.length === 0 ? ""
                : root.video ? String(Wallpapers.getVideoFirstFramePath(root.path) ?? "")
                : root.fallback ? root.path
                : String(Wallpapers.getExpectedThumbnailPath(root.path, "large") ?? "")
            source: file.length > 0 ? "file://" + file : ""
            onStatusChanged: {
                if (status !== Image.Error || root.fallback || root.video)
                    return
                Wallpapers.ensureThumbnailForPath(root.path, "large")
                root.fallback = true
            }
        }

        Rectangle {
            visible: root.current
            x: NihilStyle.s(8)
            y: NihilStyle.s(8)
            width: NihilStyle.s(26)
            height: NihilStyle.s(26)
            radius: width / 2
            color: NihilStyle.accent

            NIcon {
                anchors.centerIn: parent
                text: "check"
                size: NihilStyle.s(16)
                color: NihilStyle.accentInk
            }
        }

        Rectangle {
            visible: root.video
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: NihilStyle.s(8)
            width: NihilStyle.s(26)
            height: NihilStyle.s(26)
            radius: width / 2
            color: NihilStyle.scrim

            NIcon {
                anchors.centerIn: parent
                text: "play"
                size: NihilStyle.s(14)
            }
        }

        Rectangle {
            x: NihilStyle.s(8)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: NihilStyle.s(8)
            width: Math.min(name.implicitWidth + NihilStyle.s(18), frame.width - NihilStyle.s(16))
            height: NihilStyle.s(26)
            radius: height / 2
            color: NihilStyle.scrim
            opacity: root.focused ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: NihilStyle.quick } }

            NText {
                id: name
                x: NihilStyle.s(9)
                width: parent.width - NihilStyle.s(18)
                anchors.verticalCenter: parent.verticalCenter
                text: FileUtils.fileNameForPath(root.path).replace(/\.[^.]+$/, "")
                elide: Text.ElideRight
                font.pixelSize: NihilStyle.textSmall
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
