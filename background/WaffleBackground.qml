pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions as CF
import qs.modules.common.widgets
import qs.modules.waffle.looks
import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: panelRoot
        required property var modelData

        // Waffle background config
        readonly property var wBg: Config.options?.waffles?.background ?? {}
        readonly property var wEffects: wBg.effects ?? {}

        // Multi-monitor wallpaper support
        readonly property bool _multiMonEnabled: WallpaperListener.multiMonitorEnabled
        readonly property string _monitorName: WallpaperListener.getMonitorName(panelRoot.modelData)
        readonly property var _perMonitorData: _multiMonEnabled
            ? (WallpaperListener.effectivePerMonitor[_monitorName] ?? { path: "" })
            : ({ path: "" })

        // Wallpaper source — per-monitor when multi-monitor enabled, otherwise config
        readonly property string wallpaperSourceRaw: {
            if (_multiMonEnabled && _perMonitorData.path) return _perMonitorData.path;
            if (wBg.useMainWallpaper ?? true) return Config.options?.background?.wallpaperPath ?? "";
            return wBg.wallpaperPath || Config.options?.background?.wallpaperPath || "";
        }

        readonly property string wallpaperThumbnail: {
            if (wBg.useMainWallpaper ?? true) return Config.options?.background?.thumbnailPath ?? "";
            return wBg.thumbnailPath || Config.options?.background?.thumbnailPath || "";
        }

        readonly property bool enableAnimation: wBg.enableAnimation ?? Config.options?.background?.enableAnimation ?? true
        readonly property bool enableAnimatedBlur: wEffects.enableAnimatedBlur ?? false
        readonly property int thumbnailBlurStrength: wEffects.thumbnailBlurStrength ?? Config.options?.background?.effects?.thumbnailBlurStrength ?? 70
        readonly property bool externalMainWallpaperActive: (wBg.useMainWallpaper ?? true)
            && AwwwBackend.supportsVisibleMainWallpaper(wallpaperSourceRaw, Config.options?.background?.fillMode ?? "fill", false, enableAnimatedBlur)
        readonly property bool showInternalStaticWallpaper: !externalMainWallpaperActive || (Appearance.effectsEnabled && blurProgress > 0)

        readonly property bool wallpaperIsVideo: {
            const lowerPath = wallpaperSourceRaw.toLowerCase();
            return lowerPath.endsWith(".mp4") || lowerPath.endsWith(".webm") || lowerPath.endsWith(".mkv") || lowerPath.endsWith(".avi") || lowerPath.endsWith(".mov");
        }

        readonly property bool wallpaperIsGif: {
            return wallpaperSourceRaw.toLowerCase().endsWith(".gif");
        }

        // Effective source: use thumbnail if animation disabled for videos/GIFs
        readonly property string wallpaperSource: {
            if (!panelRoot.enableAnimation && (panelRoot.wallpaperIsVideo || panelRoot.wallpaperIsGif)) {
                return panelRoot.wallpaperThumbnail || panelRoot.wallpaperSourceRaw;
            }
            return panelRoot.wallpaperSourceRaw;
        }

        readonly property string wallpaperUrl: {
            const path = wallpaperSource;
            if (!path) return "";
            if (path.startsWith("file://")) return path;
            return "file://" + path;
        }

        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:wBackground"
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        // Wallpaper scaling — decode at correct resolution for quality parity with ii/material.
        // Uses magick identify to detect actual image size, same approach as Background.qml.
        readonly property real _preferredScale: (wBg.parallax?.workspaceZoom ?? 1.05)
        property real _effectiveWallpaperScale: _preferredScale
        property int _wallpaperWidth: panelRoot.screen.width
        property int _wallpaperHeight: panelRoot.screen.height

        onWallpaperSourceChanged: _wallpaperSizeDebounce.restart()

        Timer {
            id: _wallpaperSizeDebounce
            interval: 80
            repeat: false
            onTriggered: {
                const path = panelRoot.wallpaperSourceRaw
                if (!path || path.length === 0) return
                if (panelRoot.wallpaperIsVideo) return
                _getWallpaperSizeProc.path = path
                _getWallpaperSizeProc.running = true
            }
        }

        Process {
            id: _getWallpaperSizeProc
            property string path: panelRoot.wallpaperSourceRaw
            command: ["/usr/bin/magick", "identify", "-format", "%w %h", path]
            stdout: StdioCollector {
                id: _sizeOutput
                onStreamFinished: {
                    const output = (_sizeOutput.text ?? "").trim()
                    const parts = output.split(/\s+/).filter(Boolean)
                    const w = Number(parts[0])
                    const h = Number(parts[1])
                    const sw = panelRoot.screen?.width ?? 0
                    const sh = panelRoot.screen?.height ?? 0
                    if (!Number.isFinite(w) || !Number.isFinite(h) || w <= 0 || h <= 0 || sw <= 0 || sh <= 0)
                        return
                    panelRoot._wallpaperWidth = Math.round(w)
                    panelRoot._wallpaperHeight = Math.round(h)
                    if (w <= sw || h <= sh) {
                        panelRoot._effectiveWallpaperScale = Math.max(sw / w, sh / h)
                    } else {
                        panelRoot._effectiveWallpaperScale = Math.min(panelRoot._preferredScale, w / sw, h / sh)
                    }
                }
            }
        }

        property bool hasFullscreenWindow: {
            if (CompositorService.isNiri && NiriService.windows) {
                return NiriService.windows.some(w => w.is_focused && w.is_fullscreen)
            }
            return false
        }

        // Hide wallpaper (show only backdrop for overview)
        readonly property bool backdropOnly: wBg.backdrop?.hideWallpaper ?? false

        visible: !backdropOnly && (GlobalStates.screenLocked || !hasFullscreenWindow || !(wBg.hideWhenFullscreen ?? true))

        // Dynamic focus based on windows
        property bool hasWindowsOnCurrentWorkspace: {
            try {
                if (CompositorService.isNiri && typeof NiriService !== "undefined" && NiriService.windows && NiriService.workspaces) {
                    const allWs = Object.values(NiriService.workspaces);
                    if (!allWs || allWs.length === 0) return false;
                    const currentNumber = NiriService.getCurrentWorkspaceNumber();
                    const currentWs = allWs.find(ws => ws.idx === currentNumber);
                    if (!currentWs) return false;
                    return NiriService.windows.some(w => w.workspace_id === currentWs.id);
                }
                return false;
            } catch (e) { return false; }
        }

        property bool focusWindowsPresent: !GlobalStates.screenLocked && hasWindowsOnCurrentWorkspace
        property real focusPresenceProgress: focusWindowsPresent ? 1 : 0
        Behavior on focusPresenceProgress {
            animation: Looks.transition.opacity.createObject(this)
        }

        // Blur progress
        property real blurProgress: {
            const blurEnabled = wEffects.enableBlur ?? false;
            const blurRadius = wEffects.blurRadius ?? 0;
            if (!blurEnabled || blurRadius <= 0) return 0;

            const blurStatic = Math.max(0, Math.min(100, Number(wEffects.blurStatic) || 0));
            const dynamicPart = (100 - blurStatic) * focusPresenceProgress;
            return (blurStatic + dynamicPart) / 100;
        }

        Item {
            anchors.fill: parent
            clip: true

            // Static Image with crossfade transitions (non-GIF, non-video images only)
            WallpaperCrossfader {
                id: wallpaper
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: panelRoot.wallpaperUrl && !panelRoot.wallpaperIsGif && !panelRoot.wallpaperIsVideo
                    ? panelRoot.wallpaperUrl
                    : ""
                visible: panelRoot.showInternalStaticWallpaper && !panelRoot.wallpaperIsGif && !panelRoot.wallpaperIsVideo && ready && !blurEffect.visible
                sourceSize {
                    width: Math.round(panelRoot.screen.width * panelRoot._effectiveWallpaperScale)
                    height: Math.round(panelRoot.screen.height * panelRoot._effectiveWallpaperScale)
                }
            }

            // Animated GIF wallpaper
            // Always loaded for GIFs: plays when animation enabled, frozen (first frame) when disabled
            AnimatedImage {
                id: gifWallpaper
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: panelRoot.wallpaperIsGif
                    ? (panelRoot.wallpaperSourceRaw.startsWith("file://")
                        ? panelRoot.wallpaperSourceRaw
                        : "file://" + panelRoot.wallpaperSourceRaw)
                    : ""
                asynchronous: true
                cache: true
                visible: panelRoot.wallpaperIsGif && !blurEffect.visible && !panelRoot.externalMainWallpaperActive
                playing: visible && panelRoot.enableAnimation

                layer.enabled: Appearance.effectsEnabled && panelRoot.enableAnimatedBlur && (panelRoot.wEffects.blurRadius ?? 0) > 0
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: ((panelRoot.wEffects.blurRadius ?? 32) * Math.max(0, Math.min(1, panelRoot.thumbnailBlurStrength / 100))) / 100.0
                    blurMax: 64
                }
            }

            // Video wallpaper (Qt Multimedia)
            // Always loaded for videos: plays when animation enabled, frozen (paused) when disabled
            Video {
                id: videoWallpaper
                anchors.fill: parent
                visible: panelRoot.wallpaperIsVideo && !blurEffect.visible
                source: {
                    if (!panelRoot.wallpaperIsVideo) return "";
                    const path = panelRoot.wallpaperSourceRaw;
                    if (!path) return "";
                    return path.startsWith("file://") ? path : ("file://" + path);
                }
                fillMode: VideoOutput.PreserveAspectCrop
                loops: MediaPlayer.Infinite
                muted: true
                autoPlay: true

                readonly property bool shouldPlay: panelRoot.enableAnimation

                function pauseAndShowFirstFrame() {
                    pause()
                    seek(0)
                }

                onPlaybackStateChanged: {
                    if (playbackState === MediaPlayer.PlayingState && !shouldPlay) {
                        pauseAndShowFirstFrame()
                    }
                    if (playbackState === MediaPlayer.StoppedState && visible && shouldPlay) {
                        play()
                    }
                }

                onShouldPlayChanged: {
                    if (visible && panelRoot.wallpaperIsVideo) {
                        if (shouldPlay) play()
                        else pauseAndShowFirstFrame()
                    }
                }

                onVisibleChanged: {
                    if (visible && panelRoot.wallpaperIsVideo) {
                        if (shouldPlay) play()
                        else pauseAndShowFirstFrame()
                    } else {
                        pause()
                    }
                }

                layer.enabled: Appearance.effectsEnabled && panelRoot.enableAnimatedBlur && (panelRoot.wEffects.blurRadius ?? 0) > 0
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: ((panelRoot.wEffects.blurRadius ?? 32) * Math.max(0, Math.min(1, panelRoot.thumbnailBlurStrength / 100))) / 100.0
                    blurMax: 64
                }
            }

            // Blur effect - only for static images (performance)
            MultiEffect {
                id: blurEffect
                anchors.fill: parent
                source: wallpaper
                visible: Appearance.effectsEnabled && panelRoot.blurProgress > 0 &&
                         !panelRoot.wallpaperIsGif && !panelRoot.wallpaperIsVideo &&
                         wallpaper.ready
                blurEnabled: visible
                blur: panelRoot.blurProgress * ((panelRoot.wEffects.blurRadius ?? 32) / 100.0)
                blurMax: 64
            }

            // Dim overlay
            Rectangle {
                anchors.fill: parent
                color: {
                    const baseN = Number(panelRoot.wEffects.dim) || 0;
                    const dynN = Number(panelRoot.wEffects.dynamicDim) || 0;
                    const extra = panelRoot.focusPresenceProgress > 0 ? dynN * panelRoot.focusPresenceProgress : 0;
                    const total = Math.max(0, Math.min(100, baseN + extra));
                    return Qt.rgba(0, 0, 0, total / 100);
                }
                Behavior on color {
                    animation: Looks.transition.color.createObject(this)
                }
            }
        }
    }
}
