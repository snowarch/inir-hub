pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.settings

// The wallpaper in use, and the ways to change it.
Item {
    id: root

    readonly property string path: Wallpapers.effectiveWallpaperPath
    readonly property string fileName: root.path.split("/").pop()
    readonly property bool sideBySide: root.width >= NihilStyle.s(520)

    implicitHeight: root.sideBySide ? picture.height : picture.height + actions.implicitHeight + NihilStyle.s(14)

    ClippingRectangle {
        id: picture
        width: root.sideBySide ? Math.round(root.width * 0.46) : root.width
        height: Math.round(width * 9 / 16)
        radius: NihilStyle.sectionRowRadius
        color: NihilStyle.well
        Image {
            id: still
            anchors.fill: parent
            source: Wallpapers.effectiveWallpaperUrl
            sourceSize.width: 720
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        NSpinner {
            anchors.centerIn: parent
            visible: still.status === Image.Loading
        }
        NEmpty {
            anchors.centerIn: parent
            width: parent.width - NihilStyle.s(24)
            visible: still.status === Image.Error || still.status === Image.Null
            glyph: "hide_image"
            title: Translation.tr("No wallpaper to show")
        }
    }

    Column {
        id: actions
        x: root.sideBySide ? picture.width + NihilStyle.s(16) : 0
        y: root.sideBySide ? (root.height - height) / 2 : picture.height + NihilStyle.s(14)
        width: root.sideBySide ? root.width - x : root.width
        spacing: NihilStyle.s(8)
        NText {
            width: parent.width
            figures: true
            text: root.fileName
            font.pixelSize: NihilStyle.textSmall
            color: NihilStyle.inkSoft
        }
        NKey {
            width: parent.width
            height: NihilStyle.s(42)
            lit: true
            glyph: "wallpaper"
            label: Translation.tr("Choose a wallpaper")
            onClicked: SettingsModel.run("wallpaper")
        }
        NKey {
            width: parent.width
            height: NihilStyle.s(42)
            glyph: "shuffle"
            label: Translation.tr("Surprise me")
            onClicked: Wallpapers.randomFromCurrentFolder()
        }
        LightDark { width: parent.width }
    }
}
