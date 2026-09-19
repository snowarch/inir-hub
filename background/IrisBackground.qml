pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: panel
        required property var modelData

        readonly property string monitorName: WallpaperListener.getMonitorName(panel.modelData)
        readonly property string configuredPath: Wallpapers.currentMainWallpaperPath(panel.monitorName)
        readonly property string previewPath: Wallpapers.internalPreviewFor(panel.monitorName, panel.configuredPath)
        readonly property bool video: Wallpapers.isVideoFile(panel.previewPath)
        readonly property bool gif: panel.previewPath.toLowerCase().endsWith(".gif")
        readonly property string effectivePath: panel.video ? Wallpapers.stillUrlFor(panel.previewPath) : panel.previewPath
        readonly property bool motion: (Config.options?.background?.enableAnimation ?? true)
            && !GlobalStates.screenLocked && !Appearance._gameModeActive && !Wallpapers.batteryPauseActive
            && Wallpapers.videoMotionAllowedOn(panel.monitorName)
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
            sourceSize: Qt.size(panel.width * (panel.screen?.devicePixelRatio ?? 1), panel.height * (panel.screen?.devicePixelRatio ?? 1))
            source: {
                const path = panel.effectivePath
                if (!path || panel.externalWallpaper) return ""
                return path.startsWith("file://") ? path : "file://" + FileUtils.trimFileProtocol(path)
            }
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true
            mipmap: false
        }

        AnimatedImage {
            anchors.fill: parent
            visible: panel.gif && status === AnimatedImage.Ready
            source: panel.gif ? "file://" + FileUtils.trimFileProtocol(panel.previewPath) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            playing: visible && panel.motion
        }

        VideoCrossfader {
            anchors.fill: parent
            visible: panel.video
            source: panel.video ? panel.previewPath : ""
            fillMode: VideoOutput.PreserveAspectCrop
            enableTransitions: Config.options?.background?.transition?.enable ?? true
            transitionBaseDuration: Config.options?.background?.transition?.duration ?? 800
            shouldPlay: panel.motion
        }

        Rectangle {
            anchors.fill: parent
            visible: !panel.externalWallpaper && panel.effectivePath.length === 0
            color: Appearance.m3colors.m3background
        }
    }
}
