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
import qs.modules.iris.components

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
        readonly property bool desktopMenuOpen: desktopMenu.active

        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:iris-background"
        // The lightweight background is used specifically when desktop widgets
        // are disabled. Bare-desktop actions are shell actions, not widget
        // actions, so keep the surface pointer-capable and only request keyboard
        // focus while its menu is actually open.
        WlrLayershell.keyboardFocus: panel.desktopMenuOpen
            ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
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

        MouseArea {
            anchors.fill: parent
            z: 20
            acceptedButtons: Qt.RightButton | Qt.LeftButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    if (desktopMenu.active) desktopMenu.close()
                    return
                }
                desktopMenuAnchor.x = mouse.x
                desktopMenuAnchor.y = mouse.y
                desktopMenu.requestOpen()
            }
        }

        Item {
            id: desktopMenuAnchor
            z: 21
            width: 1
            height: 1
        }

        // Keep the normal iRiS desktop menu available even when the heavy
        // desktop-widget canvas is intentionally unloaded. The Widgets tile
        // enables that module before entering edit mode instead of opening an
        // editor with no canvas behind it.
        IrisDesktopMenu {
            id: desktopMenu
            z: 22
            anchorItem: desktopMenuAnchor
            model: [
                { type: "quick", items: [
                    { text: Translation.tr("Wallpaper"), iconName: "wallpaper",
                        image: panel.video || panel.gif
                            ? (Config.options?.background?.thumbnailPath ?? "") : panel.previewPath,
                        action: () => {
                            GlobalStates.wallpaperSelectorTargetMonitor = panel.monitorName
                            GlobalActions.runLauncher(["wallpaperSelector", "toggle"])
                        } },
                    { text: Translation.tr("Widgets"), iconName: "widgets",
                        action: () => {
                            Config.setNestedValue("iris.modules.desktopWidgets", true)
                            GlobalStates.setWidgetEditMode(true)
                        } },
                    { text: Translation.tr("Studio"), iconName: "palette",
                        action: () => { GlobalStates.irisStudioOpen = true } },
                    { text: Translation.tr("Search"), iconName: "search",
                        action: () => { GlobalStates.searchOpen = true } }
                ] },
                { type: "separator" },
                { text: Translation.tr("Edit iRiS"), iconName: "edit",
                    action: () => { GlobalStates.irisEdit = true } },
                { text: Translation.tr("Quick controls"), iconName: "tune",
                    action: () => { GlobalStates.controlPanelOpen = true } },
                { text: Translation.tr("Settings"), iconName: "settings",
                    action: () => {
                        Quickshell.execDetached([Quickshell.shellPath("scripts/inir"),
                            "iris", "settings", ""])
                    } },
                { type: "separator" },
                { text: Translation.tr("Reload shell"), iconName: "refresh",
                    action: () => {
                        Quickshell.execDetached(["/usr/bin/bash",
                            Quickshell.shellPath("scripts/restart-shell.sh")])
                    } }
            ]
        }
    }
}
