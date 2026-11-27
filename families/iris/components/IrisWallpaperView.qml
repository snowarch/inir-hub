pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style

Item {
    id: root

    property var screen: null
    readonly property string monitorName: WallpaperListener.getMonitorName(root.screen)
    readonly property string configuredPath: Wallpapers.desktopWallpaperPath(root.monitorName)
    property string path: Wallpapers.internalPreviewFor(root.monitorName, root.configuredPath)
    property bool active: true
    property bool live: true
    property bool provideTexture: false
    property bool asynchronous: true
    property int fillMode: Image.PreserveAspectCrop
    property size decodeSize: Qt.size(0, 0)
    property int decodeFps: 0

    readonly property bool isVideo: Wallpapers.isVideoFile(root.path)
    readonly property bool isGif: root.path.toLowerCase().endsWith(".gif")
    readonly property string stillUrl: root.active ? Wallpapers.stillUrlFor(root.path) : ""
    readonly property bool motion: root.shown
        && (Config.options?.background?.enableAnimation ?? true)
        && !GlobalStates.screenLocked && !Appearance._gameModeActive && !Wallpapers.batteryPauseActive
        && Wallpapers.videoMotionAllowedOn(root.monitorName)
    readonly property bool shown: root.live && (root.QsWindow.window?.visible ?? false)
        && (root.provideTexture || (root.visible && root.opacity > 0.001))
    readonly property bool playsVideo: root.active && root.isVideo && root.shown
    readonly property bool animated: root.playsVideo || (root.active && root.isGif && root.shown)
    readonly property bool videoFrame: root.playsVideo && (videoLoader.item?.hasFrame ?? false)
    readonly property bool ready: root.isGif ? gif.status === AnimatedImage.Ready
        : still.status === Image.Ready || root.videoFrame

    // A still that is cold when its surface opens fades in instead of popping onto a body already drawn; a warm one
    // (cached, or kept warm by its owner) is there on the first frame. Once shown, a new wallpaper replaces it in place.
    property bool revealed: false
    onReadyChanged: if (root.ready) root.revealed = true

    readonly property real dim: Wallpapers.desktopDim
    // A moving wallpaper is a subtree: sampling it costs a pass per frame, so only samplers ask.
    readonly property Item textureItem: (root.animated || root.dim > 0) && root.provideTexture ? motionTexture.item : still
    readonly property Item stillItem: still

    Item {
        id: content
        anchors.fill: parent
        opacity: root.revealed ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: IrisStyle.revealDuration; easing.type: Easing.OutCubic } }

        Image {
            id: still
            anchors.fill: parent
            visible: !root.isGif && !root.videoFrame && root.stillUrl.length > 0
            source: root.stillUrl
            fillMode: root.fillMode
            asynchronous: root.asynchronous
            // A wallpaper change keeps the old still on screen until the new one is decoded, never a blank frame.
            retainWhileLoading: true
            // A copy an effect samples keeps its own texture: shared with a mipmapped view it flipped its filtering.
            cache: !root.provideTexture
            // Mipmapped, 2 px over the asked size: a plain copy elsewhere at that size would share its texture (IrisImage).
            sourceSize: root.provideTexture ? root.decodeSize
                : Qt.size(root.decodeSize.width > 0 ? root.decodeSize.width + 2 : 0, root.decodeSize.height > 0 ? root.decodeSize.height + 2 : 0)
            // Shown shrunk it needs mipmaps to stay sharp; a texture an effect samples must not have them.
            mipmap: !root.provideTexture
        }

        AnimatedImage {
            id: gif
            anchors.fill: parent
            visible: root.isGif && status === AnimatedImage.Ready
            source: root.active && root.isGif ? "file://" + FileUtils.trimFileProtocol(root.path) : ""
            fillMode: root.fillMode
            asynchronous: true
            cache: false
            playing: visible && root.motion
        }

        Loader {
            id: videoLoader
            anchors.fill: parent
            active: root.playsVideo
            visible: root.videoFrame
            sourceComponent: VideoCrossfader {
                source: root.path
                fillMode: root.fillMode
                shouldPlay: root.motion
                enableTransitions: false
                decodeHeight: root.decodeSize.height > 0 ? root.decodeSize.height : -1
                decodeFps: root.decodeFps
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: root.dim > 0
            color: "black" // iris-literal: Backdrop.qml's dim is black at the configured opacity
            opacity: root.dim
        }
    }

    Loader {
        id: motionTexture
        anchors.fill: parent
        active: (root.animated || root.dim > 0) && root.provideTexture
        visible: false
        sourceComponent: ShaderEffectSource {
            sourceItem: content
            live: true
            hideSource: false
            textureSize: root.decodeSize.width > 0 ? root.decodeSize
                : Qt.size(Math.max(1, Math.round(root.width)), Math.max(1, Math.round(root.height)))
        }
    }
}
