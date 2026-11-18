pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.nihil.style

// A picture as a NiHiL piece: a circle when small, a pill when wide, a rounded square when large. The widget draws
// its picture (or folder of them) into this face's clip.
NihilFace {
    id: root

    readonly property bool empty: String(root.widget.currentPath ?? "").length === 0

    ClippingRectangle {
        id: host
        anchors.centerIn: parent
        width: root.small ? Math.min(parent.width, parent.height) : parent.width
        height: root.small ? width : parent.height
        radius: root.large ? root.radius : Math.min(width, height) / 2
        color: NihilStyle.piece

        Column {
            visible: root.empty
            anchors.centerIn: parent
            spacing: root.dp(6)
            NIcon { anchors.horizontalCenter: parent.horizontalCenter; text: "add_photo_alternate"; size: root.dp(28); color: NihilStyle.inkSoft }
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                figures: true
                font.pixelSize: root.dp(11)
                color: NihilStyle.inkSoft
                text: Translation.tr("Drop a picture here")
            }
        }
    }
    Component.onCompleted: root.widget.irisPhotoHost = host
    Component.onDestruction: if (root.widget.irisPhotoHost === host) root.widget.irisPhotoHost = null
}
