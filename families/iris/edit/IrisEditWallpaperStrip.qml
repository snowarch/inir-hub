pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style

// The wallpapers of the folder, in a row above the shrunk desktop. A tap previews one on the desktop at once; Done
// applies it, Escape puts back the one that was there (DesktopEditHistory's draft). The row opens on the wallpaper on
// show, slides by a page from the arrows at its ends, and a wheel or a swipe moves it smoothly. Where more pictures
// lie past an end, the row fades into the air there instead of ending on a cut.
Item {
    id: root

    property var screenData: null
    property real panelReserve: 0
    property real presentation: 0

    readonly property string monitorName: WallpaperListener.getMonitorName(root.screenData)
    readonly property real d: IrisStyle.density
    readonly property real dpr: root.screenData?.devicePixelRatio ?? 1
    readonly property real p: Math.max(0, Math.min(1, root.presentation))
    readonly property bool shown: root.p > 0.002

    readonly property real roomW: Math.max(240, root.width - root.panelReserve)
    readonly property real aspect: root.height > 0 ? Math.max(1.2, Math.min(2.4, root.width / root.height)) : 16 / 9
    readonly property int thumbH: Math.round(Math.max(48 * root.d, Math.min(82 * root.d, root.height * 0.085)))
    readonly property int thumbW: Math.round(root.thumbH * root.aspect)
    readonly property int gap: Math.round(12 * root.d)
    readonly property int sidePad: Math.round(24 * root.d)
    readonly property int marginTop: Math.round(16 * root.d)
    // Room around a tile for its ring and its hover lift, inside the row: the row clips there, never through a ring.
    readonly property int ringPad: Math.round(8 * root.d)
    readonly property int arrowSize: Math.round(30 * root.d)
    readonly property real thumbRadius: IrisStyle.radiusChip
    // One thumbnail size for the row, from the size a tile shows at on this screen.
    readonly property string thumbSize: Images.thumbnailSizeNameForDimensions(Math.round(root.thumbW * root.dpr), Math.round(root.thumbH * root.dpr))

    readonly property real stripMaxW: Math.max(160, root.roomW - root.sidePad * 2)
    readonly property real stripY: Math.round(root.marginTop - (1 - root.p) * (root.marginTop + root.thumbH + 16))
    // Space reserved above the live desktop card so strip and card never overlap.
    readonly property real reserveTop: root.marginTop + root.thumbH + Math.round(22 * root.d)

    readonly property rect hitRect: root.shown && strip.count > 0
        ? Qt.rect(root.sidePad, Math.max(0, root.stripY - root.ringPad), root.stripMaxW, root.thumbH + root.ringPad * 2)
        : Qt.rect(0, 0, 0, 0)

    readonly property string appliedPath: FileUtils.trimFileProtocol(Wallpapers.desktopWallpaperPath(root.monitorName))
    // What the desktop shows: the draft while there is one.
    readonly property string shownPath: DesktopEditHistory.wallpaperDraft.length > 0 ? DesktopEditHistory.wallpaperDraft : root.appliedPath

    visible: root.shown && strip.count > 0
    opacity: root.p

    // Opens on the wallpaper on show, centred, once the folder has been read. Asked again as the folder fills and the
    // row takes its width, until the person moves it: centred in a row still growing, it stood at the left end.
    property bool moved: false
    function reveal(): void {
        if (root.moved) return
        for (let i = 0; i < strip.count; i++) {
            if (FileUtils.trimFileProtocol(String(Wallpapers.folderModel.get(i, "filePath") ?? "")) === root.shownPath) {
                strip.positionViewAtIndex(i, ListView.Center)
                break
            }
        }
        slide.to = strip.contentX
    }
    onShownChanged: if (root.shown) { root.moved = false; Qt.callLater(root.reveal) }
    Connections {
        target: strip
        function onCountChanged(): void { if (root.shown) Qt.callLater(root.reveal) }
        function onWidthChanged(): void { if (root.shown) Qt.callLater(root.reveal) }
    }

    // One smooth slide for wheel, swipe and arrows: each asks for a place and the row eases there.
    function slideTo(x: real): void {
        root.moved = true
        slide.to = root.clampX(x)
        slide.restart()
    }
    // The row's own bounds, from its origin (a ListView of tiles that differ in width moves it off 0).
    function clampX(x: real): real {
        return Math.max(strip.originX, Math.min(strip.originX + Math.max(0, strip.contentWidth - strip.width), x))
    }
    NumberAnimation {
        id: slide
        target: strip
        property: "contentX"
        duration: IrisStyle.duration(260)
        easing.type: Easing.OutCubic
    }

    Item {
        id: stripFrame
        x: root.sidePad
        y: root.stripY - root.ringPad
        width: root.stripMaxW
        height: root.thumbH + root.ringPad * 2

        ListView {
            id: strip
            readonly property real naturalW: strip.contentWidth > 0 ? Math.min(strip.contentWidth, stripFrame.width) : stripFrame.width
            readonly property bool overflows: strip.contentWidth > stripFrame.width + 1
            x: Math.max(0, Math.round((stripFrame.width - strip.naturalW) / 2))
            width: strip.naturalW
            height: stripFrame.height
            clip: true
            // Faded at an end with more pictures past it (IrisScrollEdge's mask): rendered offscreen only then.
            layer.enabled: stripEdge.active
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: stripEdge.mask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }
            orientation: ListView.Horizontal
            // Each tile carries its own gap: a folder entry takes no room at all (a ListView spacing still spaced it).
            spacing: 0
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 2400
            cacheBuffer: root.thumbW * 6
            reuseItems: true
            model: root.shown ? Wallpapers.folderModel : null
            onMovementStarted: { root.moved = true; slide.stop() }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    const delta = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y)
                        ? event.angleDelta.x : event.angleDelta.y
                    // A touchpad scrolls in phases and is followed 1:1; a wheel (no phase) moves the row one tile a notch.
                    // Qt on Wayland gives a wheel's notch a 15 px pixelDelta too, so pixels alone crawled.
                    if (event.phase !== Qt.NoScrollPhase && (event.pixelDelta.x !== 0 || event.pixelDelta.y !== 0)) {
                        root.moved = true
                        slide.stop()
                        const px = Math.abs(event.pixelDelta.x) > Math.abs(event.pixelDelta.y) ? event.pixelDelta.x : event.pixelDelta.y
                        strip.contentX = root.clampX(strip.contentX - px)
                        slide.to = strip.contentX
                    } else {
                        root.slideTo((slide.running ? slide.to : strip.contentX) - delta / 120 * (root.thumbW + root.gap))
                    }
                    event.accepted = true
                }
            }

            footer: Item {
                width: root.thumbH
                height: strip.height
                Rectangle {
                    y: root.ringPad
                    width: root.thumbH
                    height: root.thumbH
                    readonly property bool hovered: galleryMouse.containsMouse
                    radius: root.thumbRadius
                    color: hovered ? IrisStyle.veilStrong : IrisStyle.veil
                    border.width: 1
                    border.color: hovered ? IrisStyle.onMediaTertiary : IrisStyle.onMediaFill
                    scale: galleryMouse.pressed ? IrisStyle.pressScale(0.94) : 1
                    Behavior on scale { NumberAnimation { duration: IrisStyle.duration(120); easing.type: IrisStyle.feedbackEasing } }
                    Behavior on color { ColorAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "photo_library"
                        iconSize: Math.round(22 * root.d)
                        color: IrisStyle.onMedia
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
                required property bool fileIsDir
                readonly property string cleanPath: FileUtils.trimFileProtocol(tile.filePath)
                readonly property bool isVideo: Wallpapers.isVideoFile(tile.cleanPath)
                readonly property bool current: tile.cleanPath.length > 0 && tile.cleanPath === root.shownPath
                readonly property bool drafted: tile.current && DesktopEditHistory.wallpaperDraft.length > 0
                readonly property bool hovered: tileMouse.containsMouse

                width: tile.fileIsDir ? 0 : root.thumbW + root.gap
                height: strip.height
                visible: !tile.fileIsDir

                Item {
                    id: face
                    y: root.ringPad
                    width: root.thumbW
                    height: root.thumbH
                    scale: tileMouse.pressed ? IrisStyle.pressScale(0.95) : tile.hovered && !tile.current ? 1.03 : 1
                    Behavior on scale { NumberAnimation { duration: IrisStyle.duration(tileMouse.pressed ? 90 : 200); easing.type: IrisStyle.feedbackEasing } }

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: root.thumbRadius
                        color: IrisStyle.veil

                        // The cached thumbnail (a video's own still), never the original: a row of 4K pictures was
                        // decoded whole for tiles 150 px wide each time Edit Mode opened.
                        ThumbnailImage {
                            anchors.fill: parent
                            sourcePath: tile.fileIsDir ? "" : tile.cleanPath
                            cleanVideoStill: true
                            thumbnailSizeName: root.thumbSize
                            fillMode: Image.PreserveAspectCrop
                            cache: true
                            sourceSize: Qt.size(Math.round(root.thumbW * root.dpr), Math.round(root.thumbH * root.dpr))
                        }

                        // The rest of the row recedes a little, so the one on show reads at a glance.
                        Rectangle {
                            anchors.fill: parent
                            color: "black"
                            opacity: tile.current || tile.hovered ? 0 : 0.22
                            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
                        }

                        // A hairline keeps each picture's edge crisp over the blurred desktop, dark ones included.
                        Rectangle {
                            anchors.fill: parent
                            radius: root.thumbRadius
                            color: "transparent"
                            border.width: 1
                            border.color: IrisStyle.onMediaFill
                        }

                        Rectangle {
                            visible: tile.isVideo
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.margins: Math.round(6 * root.d)
                            width: Math.round(18 * root.d)
                            height: Math.round(18 * root.d)
                            radius: width / 2
                            color: IrisStyle.veilStrong
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "play_arrow"
                                fill: 1
                                iconSize: Math.round(12 * root.d)
                                color: IrisStyle.onMedia
                            }
                        }
                    }

                    // The ring: accent on the wallpaper on show, a quiet one under the pointer.
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -Math.round(3 * root.d)
                        radius: root.thumbRadius + Math.round(3 * root.d)
                        color: "transparent"
                        border.width: Math.max(2, Math.round(2 * root.d))
                        border.color: tile.current ? IrisStyle.accent : IrisStyle.onMediaTertiary
                        opacity: tile.current || tile.hovered ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
                    }

                    // A drafted wallpaper says so on its face: shown, not applied until Done.
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Math.round(6 * root.d)
                        width: Math.round(20 * root.d)
                        height: width
                        radius: width / 2
                        color: IrisStyle.accent
                        opacity: tile.current ? 1 : 0
                        scale: tile.current ? 1 : 0.6
                        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
                        Behavior on scale { NumberAnimation { duration: IrisStyle.duration(200); easing.type: Easing.OutBack } }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: tile.drafted ? "visibility" : "check"
                            iconSize: Math.round(13 * root.d)
                            color: IrisStyle.inkOnAccent
                        }
                    }
                }

                MouseArea {
                    id: tileMouse
                    y: root.ringPad
                    width: root.thumbW
                    height: root.thumbH
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!tile.cleanPath) return
                        DesktopEditHistory.draftWallpaper(tile.cleanPath, root.monitorName)
                        // The picked one slides fully into view.
                        const left = tile.x - root.gap
                        const right = tile.x + root.thumbW + root.gap - strip.width
                        if (left < strip.contentX) root.slideTo(left)
                        else if (right > strip.contentX) root.slideTo(right)
                    }
                    StyledToolTip { text: Translation.tr("Preview: Done applies it"); visible: tile.drafted && tileMouse.containsMouse }
                }
            }
        }
    }

    // A page back and on, at the ends of a row longer than its room.
    component Arrow: Rectangle {
        id: arrow
        property bool forward: false
        readonly property bool needed: strip.overflows && (arrow.forward ? stripEdge.atBottom : stripEdge.atTop)
        y: root.stripY + Math.round((root.thumbH - height) / 2)
        width: root.arrowSize
        height: root.arrowSize
        radius: width / 2
        color: arrowMouse.containsMouse ? IrisStyle.veilStrong : IrisStyle.veil
        border.width: 1
        border.color: IrisStyle.onMediaFill
        opacity: arrow.needed ? 1 : 0
        visible: opacity > 0
        scale: arrowMouse.pressed ? IrisStyle.pressScale(0.9) : 1
        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
        Behavior on scale { NumberAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
        MaterialSymbol {
            anchors.centerIn: parent
            text: arrow.forward ? "chevron_right" : "chevron_left"
            iconSize: Math.round(20 * root.d)
            color: IrisStyle.onMedia
        }
        MouseArea {
            id: arrowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const page = Math.max(root.thumbW + root.gap, strip.width - (root.thumbW + root.gap))
                const from = slide.running ? slide.to : strip.contentX
                root.slideTo(from + (arrow.forward ? page : -page))
            }
        }
        Accessible.role: Accessible.Button
        Accessible.name: arrow.forward ? Translation.tr("Next") : Translation.tr("Previous")
    }
    IrisScrollEdge {
        id: stripEdge
        x: stripFrame.x + strip.x
        y: stripFrame.y
        width: strip.width
        height: strip.height
        flick: strip
        horizontal: true
        blurs: false
        reach: Math.round(Math.min(root.thumbW * 0.6, 96 * root.d))
    }
    Arrow {
        x: stripFrame.x + strip.x + Math.round(6 * root.d)
    }
    Arrow {
        forward: true
        x: stripFrame.x + strip.x + strip.width - width - Math.round(6 * root.d)
    }
}
