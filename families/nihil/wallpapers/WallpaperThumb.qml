pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style

// One wallpaper: the cached thumbnail filling its place, the picture itself while there is none, a video's first frame.
// The marked one wears the light, the one in use carries a check. A click marks it, a double click wears it.
Item {
    id: root

    property string path: ""
    property bool current: false
    property bool focused: false
    property bool live: true
    property bool fallback: false

    readonly property bool video: Wallpapers.isVideoFile(root.path)

    signal marked()
    signal picked()

    onPathChanged: root.fallback = false

    ClippingRectangle {
        id: frame
        anchors.fill: parent
        anchors.margins: NihilStyle.s(5)
        radius: NihilStyle.r(16)
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
            visible: root.current || root.video
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: NihilStyle.s(7)
            width: NihilStyle.s(26)
            height: width
            radius: width / 2
            color: root.current ? NihilStyle.accent : NihilStyle.scrim

            NIcon {
                anchors.centerIn: parent
                text: root.current ? "check" : "play"
                size: NihilStyle.s(15)
                color: root.current ? NihilStyle.accentInk : "#FFFFFF"
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: NihilStyle.s(2)
        radius: NihilStyle.r(19)
        color: "transparent"
        border.width: NihilStyle.s(2)
        border.color: NihilStyle.accent
        opacity: root.focused ? 1 : hand.containsMouse ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: NihilStyle.quick } }
    }

    MouseArea {
        id: hand
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.marked()
        onDoubleClicked: root.picked()
    }
}
