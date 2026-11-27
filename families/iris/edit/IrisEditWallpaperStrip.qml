pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style

// Top wallpaper strip for Widget Edit Mode (matching rin-shell's desk editor):
// lets you browse and switch static or live video wallpapers right onto the shrunk live desktop card.
Item {
    id: root

    property var screenData: null
    readonly property string monitorName: WallpaperListener.getMonitorName(root.screenData)
    readonly property real d: IrisStyle.density
    readonly property bool present: GlobalStates.widgetEditMode
    readonly property real presentation: presentSpring.value
    readonly property bool shown: root.presentation > 0.001
    IrisSpring { id: presentSpring; surface: "edit"; intent: "open"; to: root.present ? 1 : 0 }

    readonly property int thumbH: Math.round(52 * root.d)
    readonly property int thumbW: Math.round(root.thumbH * 16 / 9)
    readonly property int pad: Math.round(8 * root.d)
    readonly property int barH: root.thumbH + root.pad * 2
    readonly property int marginTop: Math.round(12 * root.d)
    readonly property real barW: Math.min(root.width - Math.round(64 * root.d),
        Math.max(Math.round(320 * root.d), (strip.count + 1) * (root.thumbW + Math.round(8 * root.d)) + root.pad * 2))
    readonly property real barX: Math.round((root.width - root.barW) / 2)
    readonly property real barY: Math.round(root.marginTop - (1 - root.presentation) * (root.barH + root.marginTop + 12))
    readonly property real barRadius: Math.round(18 * root.d)

    readonly property rect hitRect: root.shown && strip.count > 0
        ? Qt.rect(root.barX, Math.max(0, root.barY), root.barW, root.barH)
        : Qt.rect(0, 0, 0, 0)
    readonly property var fieldShapes: root.shown && strip.count > 0 ? [{
        id: "edit-wallpapers",
        x: root.barX,
        y: root.barY,
        width: root.barW,
        height: root.barH,
        radius: root.barRadius,
        frost: root.presentation
    }] : []

    readonly property string activePath: FileUtils.trimFileProtocol(Wallpapers.desktopWallpaperPath(root.monitorName))

    visible: root.shown && strip.count > 0
    opacity: Math.max(0, Math.min(1, root.presentation * 1.4))

    Item {
        id: barBox
        x: root.barX
        y: root.barY
        width: root.barW
        height: root.barH

        ListView {
            id: strip
            anchors.fill: parent
            anchors.margins: root.pad
            orientation: ListView.Horizontal
            spacing: Math.round(8 * root.d)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.present ? Wallpapers.folderModel : null

            footer: Item {
                width: root.thumbH
                height: root.thumbH
                Rectangle {
                    anchors.fill: parent
                    readonly property bool hovered: galleryMouse.containsMouse
                    radius: Math.round(11 * root.d)
                    color: hovered ? IrisStyle.fillHover : IrisStyle.fillQuiet
                    border.width: 1
                    border.color: IrisStyle.rim
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "photo_library"
                        iconSize: Math.round(20 * root.d)
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
                    radius: Math.round(11 * root.d)
                    color: IrisStyle.fillQuiet

                    Image {
                        anchors.fill: parent
                        source: tile.thumbUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize: Qt.size(root.thumbW * 2, root.thumbH * 2)
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

                Rectangle {
                    anchors.fill: parent
                    radius: Math.round(11 * root.d)
                    color: "transparent"
                    border.width: tile.current ? 2 : tileMouse.containsMouse ? 1.5 : 1
                    border.color: tile.current ? IrisStyle.accent
                        : tileMouse.containsMouse ? IrisStyle.text : IrisStyle.rim
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
