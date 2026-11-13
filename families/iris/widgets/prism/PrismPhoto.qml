pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.iris.widgets

// A photo in Prism: the picture fills the folder below its head, as if slid into it; the folder's name (or the
// picture's) is on the tab and where it is in the folder on the flap, which turns to the next one. Empty or failed,
// the pane says what to do.
PrismFolder {
    id: root

    readonly property bool empty: String(root.widget.currentPath ?? "").length === 0
    readonly property bool failed: !root.empty && Boolean(root.widget.activeFailed)
    readonly property bool folder: root.widget.sourceMode === "folder" && !root.empty
    readonly property bool showsPicture: !root.empty && !root.failed
    readonly property int count: root.widget.mediaCount ?? 0

    tabGlyph: root.folder ? "photo_library" : "image"
    tabText: root.folder ? FileUtils.folderNameForPath(String(root.widget.folderPath ?? ""))
        : root.empty ? Translation.tr("Image") : FileUtils.fileNameForPath(root.widget.currentPath ?? "").replace(/\.[^.]+$/, "")
    flapGlyph: root.count > 1 ? "arrow_forward" : ""
    flapText: root.count > 1 ? String((Math.max(0, root.widget.currentIndex ?? 0)) + 1) + "/" + root.count : ""

    ClippingRectangle {
        id: frame
        visible: root.showsPicture
        x: root.pick(6, 6, 8)
        y: root.paneTop
        width: root.width - 2 * x
        height: root.height - y - x
        radius: Math.max(0, root.radius - x)
        color: "transparent"
        Item {
            id: host
            anchors.fill: parent
        }
    }
    Component.onCompleted: if (!root.designed) root.widget.irisPhotoHost = host
    onDesignedChanged: if (!root.designed) root.widget.irisPhotoHost = host
    Component.onDestruction: if (root.widget.irisPhotoHost === host) root.widget.irisPhotoHost = null

    Item {
        enabled: root.count > 1
        x: root.flapLeft
        y: root.flapTop
        width: root.flapRight - root.flapLeft
        height: root.paneTop - root.flapTop
        HoverHandler { cursorShape: root.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor }
        TapHandler { onTapped: root.widget.advance(1, false) }
    }

    FaceText {
        face: root
        visible: !root.showsPicture
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.paneMiddle - height / 2)
        text: root.failed ? Translation.tr("This picture won't open") : root.widget.dropHover ? Translation.tr("Drop to show it") : Translation.tr("Add a photo")
        size: root.type(15, 18, 24)
        weight: Font.Bold
        wrapMode: Text.WordWrap
    }
    FaceText {
        face: root
        visible: !root.showsPicture
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.footTop + (root.footHeight - height) / 2 - root.dp(2))
        text: root.failed ? String(root.widget.currentName ?? "") : Translation.tr("Drop a picture or a folder here")
        color: root.inkSecondary
        size: root.type(11.5, 12.5, 14)
        weight: Font.Medium
        wrapMode: Text.WordWrap
        elide: Text.ElideRight
        maximumLineCount: 2
    }
}
