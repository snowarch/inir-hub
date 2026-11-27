pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style

// Top wallpaper thumbnail strip for Widget Edit Mode (1:1 with rin-shell's desk editor):
// centered in the left stage above the shrunk live desktop card, floating cleanly over the
// frosted stage with accent ring on current and muted ring on hover.
Item {
    id: root

    property var screenData: null
    property real panelReserve: 0
    property real presentation: 0

    readonly property string monitorName: WallpaperListener.getMonitorName(root.screenData)
    readonly property real d: IrisStyle.density
    readonly property bool present: GlobalStates.widgetEditMode
    readonly property real p: Math.max(0, Math.min(1, root.presentation))
    readonly property bool shown: root.p > 0.002

    readonly property real roomW: Math.max(240, root.width - root.panelReserve)
    readonly property real aspect: root.height > 0 ? Math.max(1.2, Math.min(2.4, root.width / root.height)) : 16 / 9
    readonly property int thumbH: Math.round(Math.max(48 * root.d, Math.min(82 * root.d, root.height * 0.085)))
    readonly property int thumbW: Math.round(root.thumbH * root.aspect)
    readonly property int gap: Math.round(12 * root.d)
    readonly property int sidePad: Math.round(24 * root.d)
    readonly property int marginTop: Math.round(16 * root.d)
    readonly property int ringPad: Math.round(4 * root.d)
    readonly property real thumbRadius: Math.round(10 * root.d)

    readonly property real stripMaxW: Math.max(160, root.roomW - root.sidePad * 2)
    readonly property real stripY: Math.round(root.marginTop - (1 - root.p) * (root.marginTop + root.thumbH + 16))
    // Space reserved above the live desktop card so strip and card never overlap.
    readonly property real reserveTop: root.marginTop + root.thumbH + Math.round(22 * root.d)

    readonly property rect hitRect: root.shown && strip.count > 0
        ? Qt.rect(root.sidePad, Math.max(0, root.stripY - root.ringPad), root.stripMaxW, root.thumbH + root.ringPad * 2)
        : Qt.rect(0, 0, 0, 0)
    readonly property var fieldShapes: []

    readonly property string activePath: FileUtils.trimFileProtocol(Wallpapers.desktopWallpaperPath(root.monitorName))

    visible: root.shown && strip.count > 0
    opacity: root.p

    Item {
        id: stripFrame
        x: root.sidePad
        y: root.stripY - root.ringPad
        width: root.stripMaxW
        height: root.thumbH + root.ringPad * 2
        clip: true

        ListView {
            id: strip
            readonly property real naturalW: strip.contentWidth > 0 ? Math.min(strip.contentWidth, stripFrame.width) : stripFrame.width
            x: Math.max(0, Math.round((stripFrame.width - strip.naturalW) / 2))
            y: root.ringPad
            width: strip.naturalW
            height: root.thumbH
            orientation: ListView.Horizontal
            spacing: root.gap
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: root.thumbW * 4
            model: root.shown ? Wallpapers.folderModel : null

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    const delta = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y)
                        ? event.angleDelta.x : event.angleDelta.y
                    const maxX = Math.max(0, strip.contentWidth - strip.width)
                    strip.contentX = Math.max(0, Math.min(maxX, strip.contentX - delta * 0.65))
                    event.accepted = true
                }
            }

            footer: Item {
                width: root.thumbH + root.gap
                height: root.thumbH
                Rectangle {
                    x: root.gap
                    width: root.thumbH
                    height: root.thumbH
                    readonly property bool hovered: galleryMouse.containsMouse
                    radius: root.thumbRadius
                    color: hovered ? IrisStyle.fillHover : IrisStyle.fillQuiet
                    border.width: hovered ? 2 : 1
                    border.color: hovered ? IrisStyle.textSecondary : IrisStyle.rim
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "photo_library"
                        iconSize: Math.round(22 * root.d)
                        color: IrisStyle.text
                    }
                    MouseArea {
                        id: galleryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: GlobalStates.wallpaperSelectorOpen = true
                    }
                    StyledToolTip { text: Translation.tr("Open wallpaper gallery") }
                }
            }

            delegate: Item {
                id: tile
                required property string filePath
                required property string fileName
                required property bool fileIsDir
                readonly property string cleanPath: FileUtils.trimFileProtocol(tile.filePath)
                readonly property bool isVideo: Wallpapers.isVideoFile(tile.cleanPath)
                readonly property bool current: tile.cleanPath.length > 0 && tile.cleanPath === root.activePath
                readonly property string thumbUrl: {
                    if (tile.fileIsDir || !tile.cleanPath) return ""
                    const still = Wallpapers.stillUrlFor(tile.cleanPath)
                    return still.length > 0 ? still : ("file://" + tile.cleanPath)
                }

                width: tile.fileIsDir ? 0 : root.thumbW
                height: root.thumbH
                visible: !tile.fileIsDir

                ClippingRectangle {
                    anchors.fill: parent
                    radius: root.thumbRadius
                    color: IrisStyle.fillQuiet

                    Image {
                        anchors.fill: parent
                        source: tile.thumbUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize: Qt.size(160, 90)
                    }

                    Rectangle {
                        visible: tile.isVideo
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: Math.round(4 * root.d)
                        width: Math.round(18 * root.d)
                        height: Math.round(18 * root.d)
                        radius: width / 2
                        color: ColorUtils.applyAlpha("#000000", 0.65)
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "play_arrow"
                            iconSize: Math.round(12 * root.d)
                            color: "#ffffff"
                        }
                    }
                }

                // Crisp outer selection/hover ring matching rin-shell's desk editor strip.
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: root.thumbRadius + 2
                    color: "transparent"
                    border.width: tile.current || tileMouse.containsMouse ? 2 : 0
                    border.color: tile.current ? IrisStyle.accent : IrisStyle.textSecondary
                }

                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!tile.cleanPath) return
                        if (Wallpapers.applyToMonitor) Wallpapers.applyToMonitor(tile.cleanPath, root.monitorName)
                        else Wallpapers.select(tile.cleanPath)
                    }
                }
            }
        }
    }
}
