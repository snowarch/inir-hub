pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.functions

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: panel
        required property var modelData

        readonly property string monitorName: WallpaperListener.getMonitorName(panel.modelData)
        readonly property string configuredPath: Wallpapers.currentMainWallpaperPath(panel.monitorName)
        readonly property string previewPath: Wallpapers.internalPreviewFor(panel.monitorName, panel.configuredPath)
        readonly property string lowerPath: panel.previewPath.toLowerCase()
        readonly property bool animated: lowerPath.endsWith(".gif") || lowerPath.endsWith(".mp4")
            || lowerPath.endsWith(".webm") || lowerPath.endsWith(".mkv")
            || lowerPath.endsWith(".avi") || lowerPath.endsWith(".mov")
        readonly property string fallbackThumbnail: Config.options?.background?.thumbnailPath ?? ""
        // iRiS never owns animated wallpaper decoding. If the shared wallpaper
        // pipeline has no static thumbnail, leave the internal layer empty and
        // let the external owner remain visible instead of waking a decoder.
        readonly property string effectivePath: panel.animated
            ? panel.fallbackThumbnail : panel.previewPath
        readonly property bool externalWallpaper: AwwwBackend.supportsVisibleMainWallpaper(
            panel.configuredPath, "fill", false, false)
            && !Wallpapers.internalPreviewActive

        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:iris-background"
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        Image {
            anchors.fill: parent
            visible: !panel.externalWallpaper && panel.effectivePath.length > 0
            source: {
                const path = panel.effectivePath
                if (!path) return ""
                return path.startsWith("file://") ? path : "file://" + FileUtils.trimFileProtocol(path)
            }
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true
            mipmap: false
        }

        Rectangle {
            anchors.fill: parent
            visible: !panel.externalWallpaper && panel.effectivePath.length === 0
            color: Appearance.m3colors.m3background
        }
    }
}
