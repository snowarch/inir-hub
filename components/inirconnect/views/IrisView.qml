pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.iris.frame
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"
import "../components"

Item {
    id: root
    property bool windowed: false
    property bool open: false
    readonly property alias frame: surfaceFrame
    readonly property real d: IrisStyle.density
    readonly property real baseRadius: IrisStyle.surfaceRadius("controlCenter", IrisStyle.radiusPanel)
    readonly property int pad: IrisStyle.concentricPad(root.baseRadius, Math.round(16 * root.d))

    readonly property string screenName: root.QsWindow.window?.screen?.name ?? (GlobalStates.focusedScreen?.name ?? "")
    readonly property real screenW: root.QsWindow.window?.screen?.width ?? 1920
    readonly property real screenH: root.QsWindow.window?.screen?.height ?? 1080
    readonly property real availW: root.width > 0 ? root.width : root.screenW
    readonly property real availH: root.height > 0 ? root.height : root.screenH
    readonly property bool isVertical: AndroidState.verticalLayout
    property bool displayedVertical: AndroidState.verticalLayout
    property real contentProgress: 1.0

    onIsVerticalChanged: {
        if (!root.open) {
            root.displayedVertical = root.isVertical
            root.contentProgress = 1.0
            return
        }
        morphTransition.restart()
    }

    SequentialAnimation {
        id: morphTransition
        NumberAnimation {
            target: root
            property: "contentProgress"
            to: 0.0
            duration: 80
            easing.type: Easing.InQuad
        }
        ScriptAction {
            script: {
                root.displayedVertical = root.isVertical
            }
        }
        NumberAnimation {
            target: root
            property: "contentProgress"
            to: 1.0
            duration: 240
            easing.type: Easing.BezierSpline
            easing.bezierCurve: IrisStyle.morphCurve
        }
    }

    implicitWidth: Math.round((root.isVertical ? 440 : 640) * root.d)
    implicitHeight: Math.round(headerBar.implicitHeight + 10 * root.d + bodyCol.implicitHeight + 2 * root.pad)

    readonly property var appBubble: (Config.options?.iris?.bubbles?.apps ?? []).find(a => a?.appId === "inirconnect") ?? null
    readonly property string bubbleZone: String(root.appBubble?.place ?? "top-right")
    readonly property bool clustered: Boolean(Config.options?.iris?.bubbles?.cluster ?? true)
    readonly property string targetFieldId: root.appBubble
        ? (root.clustered && root.bubbleZone !== "free" && !root.bubbleZone.startsWith("edge:") ? "plate:" + root.bubbleZone : "piece:app:inirconnect")
        : "island"

    readonly property var bubbleOrigin: {
        const isl = IrisFrame.islandGeometry?.[root.screenName] ?? null
        if (!root.appBubble && isl && isl.width > 0) {
            return { x: isl.x, y: isl.y, width: isl.width, height: isl.height, radius: isl.height / 2, obstacle: isl, fuse: IrisStyle.fuseDeep }
        }
        const list = IrisFrame.surfaces[root.screenName] ?? []
        const z = root.bubbleZone
        for (const s of list) {
            const c = s.core ?? null
            if (!c) continue
            const cx = c.x + c.width / 2
            const cy = c.y + c.height / 2
            if (z === "top-right" && cy < root.availH * 0.25 && cx > root.availW * 0.5)
                return { x: c.x, y: c.y, width: c.width, height: c.height, radius: IrisStyle.pieceRadius(Math.min(c.width, c.height)), obstacle: s, fuse: s.fuse }
            if (z === "top-left" && cy < root.availH * 0.25 && cx <= root.availW * 0.5)
                return { x: c.x, y: c.y, width: c.width, height: c.height, radius: IrisStyle.pieceRadius(Math.min(c.width, c.height)), obstacle: s, fuse: s.fuse }
            if (z === "bottom-right" && cy > root.availH * 0.75 && cx > root.availW * 0.5)
                return { x: c.x, y: c.y, width: c.width, height: c.height, radius: IrisStyle.pieceRadius(Math.min(c.width, c.height)), obstacle: s, fuse: s.fuse }
            if (z === "bottom-left" && cy > root.availH * 0.75 && cx <= root.availW * 0.5)
                return { x: c.x, y: c.y, width: c.width, height: c.height, radius: IrisStyle.pieceRadius(Math.min(c.width, c.height)), obstacle: s, fuse: s.fuse }
            if ((z === "left" || z.startsWith("left-")) && cx < root.availW * 0.25)
                return { x: c.x, y: c.y, width: c.width, height: c.height, radius: IrisStyle.pieceRadius(Math.min(c.width, c.height)), obstacle: s, fuse: s.fuse }
            if ((z === "right" || z.startsWith("right-")) && cx > root.availW * 0.75)
                return { x: c.x, y: c.y, width: c.width, height: c.height, radius: IrisStyle.pieceRadius(Math.min(c.width, c.height)), obstacle: s, fuse: s.fuse }
        }
        if (isl && isl.width > 0)
            return { x: isl.x, y: isl.y, width: isl.width, height: isl.height, radius: isl.height / 2, obstacle: isl, fuse: IrisStyle.fuseDeep }
        return null
    }

    readonly property var besides: root.bubbleOrigin ? IrisFrame.besides(root.screenName, root.bubbleOrigin, false) : []
    readonly property var placement: !root.windowed && root.bubbleOrigin
        ? IrisFrame.place(root.bubbleOrigin, surfaceFrame.width, surfaceFrame.height, root.availW, root.availH,
            root.baseRadius, root.besides, IrisStyle.cardJoins ? -IrisStyle.weld : Math.max(IrisFrame.bodyAir, IrisStyle.cardGap), root.screenName)
        : null

    readonly property var room: {
        const gap = Math.round(14 * root.d)
        const side = edge => IrisFrame.safeInset(edge, root.screenName) + gap
        const left = side("left"), top = side("top")
        return {
            x: left,
            y: top,
            width: Math.max(0, root.availW - left - side("right")),
            height: Math.max(0, root.availH - top - side("bottom"))
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: AndroidState.open = false
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.open && !root.windowed
        onClicked: AndroidState.open = false
    }

    IrisBodyShadow {
        visible: !root.windowed
        readonly property var body: surfaceFrame.bodyRect
        x: body?.x ?? 0
        y: (body?.y ?? 0) + 6 * root.d * surfaceFrame.progress
        width: body?.width ?? 0
        height: body?.height ?? 0
        radius: body?.radius ?? surfaceFrame.radius
        blur: 28 * root.d
        spread: -4 * root.d
        color: IrisStyle.shadow
        opacity: IrisStyle.shadowAt(surfaceFrame.progress)
    }

    IrisMorphSurface {
        id: surfaceFrame
        open: root.open
        motionSurface: "controlCenter"
        settles: true
        compositorBlurred: !root.windowed
        ownField: !root.windowed
        overlay: !root.windowed
        leasesOnAnyRuntime: !root.windowed
        fieldBacked: !root.windowed && surfaceFrame.chassisLeases
        chassisKey: "inirconnect"
        chassisJoin: {
            if (root.windowed || !IrisStyle.cardJoins || root.targetFieldId.length === 0)
                return { id: "inirconnect" }
            const joinRise = IrisStyle.ramp(surfaceFrame.progress, 0.08, 0.3)
            return {
                id: "inirconnect",
                joins: joinRise > 0 ? root.targetFieldId : "",
                fuse: Math.round(IrisStyle.fuseDeep * joinRise)
            }
        }
        glass: !root.windowed
        color: root.windowed ? IrisStyle.surface : IrisStyle.bodySurface
        light: IrisStyle.surfaceLight("controlCenter", IrisStyle.wallpaperLight)
        lightFrom: root.placement
            ? (root.placement.sideways ? (root.placement.towardsLeft ? "right" : "left") : (root.placement.towardsUp ? "bottom" : "top"))
            : "top"
        radius: root.windowed ? 0 : root.baseRadius
        corners: !root.windowed && root.placement && !IrisStyle.cardJoins
            ? IrisFrame.nestRadius({ x: root.placement.x, y: root.placement.y, width: surfaceFrame.width, height: surfaceFrame.height },
                root.baseRadius, root.bubbleOrigin?.obstacle ?? root.bubbleOrigin, Number(root.bubbleOrigin?.fuse ?? IrisStyle.fuse), root.availW, root.availH, root.besides)
            : null
        origin: !root.windowed ? root.bubbleOrigin : null
        width: root.windowed ? root.availW : Math.round(Math.min(root.room.width, (root.isVertical ? 440 : 640) * root.d))
        readonly property real naturalHeight: headerBar.implicitHeight + Math.round(10 * root.d) + bodyCol.implicitHeight + 2 * root.pad
        readonly property real minTargetHeight: Math.round((root.isVertical ? 580 : 430) * root.d)
        height: root.windowed ? root.availH : Math.min(root.room.height, Math.max(surfaceFrame.minTargetHeight, surfaceFrame.naturalHeight))
        x: root.windowed ? 0 : (root.placement ? Math.round(root.placement.x) : Math.round(root.room.x + (root.room.width - width) / 2))
        y: root.windowed ? 0 : (root.placement ? Math.round(root.placement.y) : Math.round(root.room.y + (root.room.height - height) / 2))

        Behavior on x {
            enabled: !root.windowed && surfaceFrame.settled && IrisStyle.motionEnabled
            NumberAnimation {
                duration: IrisStyle.morphDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: IrisStyle.morphCurve
            }
        }

        Behavior on y {
            enabled: !root.windowed && surfaceFrame.settled && IrisStyle.motionEnabled
            NumberAnimation {
                duration: IrisStyle.morphDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: IrisStyle.morphCurve
            }
        }

        Behavior on width {
            enabled: !root.windowed && surfaceFrame.settled && IrisStyle.motionEnabled
            NumberAnimation {
                duration: IrisStyle.morphDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: IrisStyle.morphCurve
            }
        }

        Behavior on height {
            enabled: !root.windowed && surfaceFrame.settled && IrisStyle.motionEnabled
            NumberAnimation {
                duration: IrisStyle.morphDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: IrisStyle.morphCurve
            }
        }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: mainLayout
            x: root.pad
            y: root.pad
            width: surfaceFrame.width - 2 * root.pad
            height: surfaceFrame.height - 2 * root.pad
            spacing: Math.round(10 * root.d)

            HeaderBar {
                id: headerBar
                Layout.fillWidth: true
            }

            Flickable {
                id: bodyScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: bodyCol.implicitHeight
                contentWidth: width
                contentHeight: bodyCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: bodyCol
                    width: bodyScroll.width
                    height: Math.max(bodyScroll.height, bodyCol.implicitHeight)
                    spacing: Math.round(10 * root.d)

                    DeviceSheet {
                        Layout.fillWidth: true
                    }

                    NotificationsSheet {
                        Layout.fillWidth: true
                    }

                    ShareSheet {
                        Layout.fillWidth: true
                    }

                    WirelessSheet {
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        id: contentGrid
                        columns: root.displayedVertical ? 1 : 2
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        rowSpacing: Math.round(12 * root.d)
                        columnSpacing: Math.round(14 * root.d)
                        opacity: root.contentProgress
                        scale: 0.96 + 0.04 * root.contentProgress
                        transformOrigin: Item.Top

                        PhoneMirror {
                            id: phoneMirror
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: root.displayedVertical ? -1 : Math.round(230 * root.d)
                        }

                        ColumnLayout {
                            id: rightCol
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: root.displayedVertical ? -1 : Math.round(330 * root.d)
                            spacing: Math.round(10 * root.d)

                            StatusCards {
                                Layout.fillWidth: true
                            }

                            MediaCard {
                                visible: AndroidState.mediaVisible
                                Layout.fillWidth: true
                            }

                            QuickActions {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }
                }

                Rectangle {
                    visible: bodyScroll.contentHeight > bodyScroll.height + 2
                    anchors.right: parent.right
                    y: bodyScroll.visibleArea.yPosition * bodyScroll.height
                    width: Math.round(4 * root.d)
                    height: Math.max(Math.round(24 * root.d), bodyScroll.visibleArea.heightRatio * bodyScroll.height)
                    radius: width / 2
                    color: IrisStyle.subtext
                    opacity: 0.45
                }
            }
        }
    }
}
