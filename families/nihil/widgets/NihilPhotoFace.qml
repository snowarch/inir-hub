import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules.common.functions
import qs.modules.nihil.style

// A picture of your own, the whole face. The widget keeps its media and draws it in this clip; the face adds the key to the
// next picture of a folder and an empty frame that asks for one.
NihilWidgetFace {
    id: root

    readonly property bool empty: String(root.widget.currentPath ?? "").length === 0
    readonly property bool failed: !root.empty && Boolean(root.widget.activeFailed)
    readonly property bool dropping: Boolean(root.widget.dropHover)
    readonly property bool showsPicture: !root.empty && !root.failed

    padding: root.showsPicture ? 0 : root.dp(16)

    ClippingRectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"

        Item {
            id: host
            anchors.fill: parent
        }
    }

    Component.onCompleted: root.widget.irisPhotoHost = host
    Component.onDestruction: if (root.widget.irisPhotoHost === host) root.widget.irisPhotoHost = null

    NButton {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.dp(10)
        width: root.dp(32)
        height: root.dp(32)
        visible: root.showsPicture && root.widget.sourceMode === "folder" && root.widget.mediaCount > 1 && !root.small
        icon: "skip_next"
        Accessible.name: Translation.tr("Next picture")
        onClicked: root.widget.advance(1, false)
    }

    FaceBlank {
        visible: !root.showsPicture
        face: root
        glyph: root.dropping ? "download" : root.failed ? "hide_image" : "image_add"
        title: root.dropping ? Translation.tr("Drop to show it")
            : root.failed ? Translation.tr("This picture won't open") : Translation.tr("Add a photo")
        detail: root.failed ? FileUtils.fileNameForPath(String(root.widget.currentPath ?? ""))
            : Translation.tr("Drop a picture or a folder here")
    }
}
