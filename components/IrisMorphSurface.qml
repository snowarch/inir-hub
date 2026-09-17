pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs
import qs.modules.iris.style

Item {
    id: root

    property bool open: false
    property bool contentReady: true
    property string motionSurface: ""
    property var origin: null
    property Item originItem: null
    property real originItemRadius: 0
    property real radius: IrisStyle.radius
    property color color: IrisStyle.surface
    property color light: "transparent"
    property string lightFrom: "top"
    property real contentScaleFrom: 0.965
    property real contentFadeStart: IrisStyle.contentRise
    property real contentFadeSpan: IrisStyle.contentSpan
    property real contentExitStart: IrisStyle.contentExitRise
    property real contentExitSpan: IrisStyle.contentExitSpan
    property int animationDuration: 0
    property bool contentTravels: false
    default property alias content: contentHost.data
    readonly property real progress: root.presentation
    readonly property var bodyRect: {
        void (chassis.x + chassis.y + chassis.width + chassis.height + chassis.radius + root.x + root.y)
        return { x: root.x + chassis.x, y: root.y + chassis.y,
            width: chassis.width, height: chassis.height, radius: chassis.radius }
    }
    readonly property bool settled: root.presentation >= 1
    signal closed()

    property var originScene: null
    property real fromRadius: root.radius
    readonly property rect from: root.originItem ? root.itemRect()
        : root.origin ? Qt.rect(root.origin.x - root.x, root.origin.y - root.y, root.origin.width, root.origin.height)
        : root.originScene
        ? Qt.rect(root.originScene.x - root.x, root.originScene.y - root.y, root.originScene.width, root.originScene.height)
        : Qt.rect(root.width * 0.04, root.height * 0.04, root.width * 0.92, root.height * 0.92)
    function itemRect(): rect {
        void (root.x + root.y + root.width + root.height + (root.Window.window?.height ?? 0))
        const item = root.originItem
        const p = item.mapToItem(root, 0, 0)
        return Qt.rect(p.x, p.y, item.width * item.scale, item.height * item.scale)
    }
    property bool armed: false
    readonly property alias presentation: presentationSpring.value
    IrisSpring {
        id: presentationSpring
        surface: root.motionSurface
        to: root.armed ? 1 : 0
        intent: root.animationDuration > 0 ? "move" : "auto"
        minimum: 0
    }
    onPresentationChanged: if (root.presentation <= 0 && !root.open) root.closed()

    readonly property bool fromIsland: !root.originItem && !root.origin && root.originScene !== null

    function captureOrigin(): void {
        if (root.originItem) { root.fromRadius = root.originItemRadius; return }
        if (root.origin) { root.fromRadius = root.origin.radius ?? root.radius; return }
        const origin = root.origin ?? GlobalStates.irisMorphOrigin
        const screenName = root.origin ? "" : (GlobalStates.focusedScreen?.name ?? "")
        if (origin && origin.width > 0 && (!origin.screen || origin.screen === screenName)) {
            root.originScene = Qt.rect(origin.x, origin.y, origin.width, origin.height)
            root.fromRadius = origin.radius ?? origin.height / 2
        } else {
            root.originScene = null
            root.fromRadius = root.radius
        }
    }
    readonly property bool canArm: root.open && root.contentReady && root.width > 0 && root.height > 0
    function arm(): void {
        if (!root.canArm || root.armed) return
        if (root.presentation <= 0) root.captureOrigin()
        root.armed = true
    }
    onCanArmChanged: if (root.canArm) Qt.callLater(root.arm)
    onOpenChanged: {
        if (!root.open) {
            root.armed = false
            if (root.fromIsland) Qt.callLater(root.captureOrigin)
        } else {
            Qt.callLater(root.arm)
        }
    }
    Component.onCompleted: Qt.callLater(root.arm)

    function lerp(a: real, b: real): real { return a + (b - a) * Math.min(1, root.presentation) }

    readonly property real swell: Math.max(0, root.presentation - 1)
    readonly property real anchorX: Math.max(0, Math.min(root.width, root.from.x + root.from.width / 2))
    readonly property real anchorY: Math.max(0, Math.min(root.height, root.from.y + root.from.height / 2))
    readonly property real swellX: Math.max(0, root.width - root.from.width) * root.swell
    readonly property real swellY: Math.max(0, root.height - root.from.height) * root.swell

    readonly property real snapX: Math.round(root.x) - root.x
    readonly property real snapY: Math.round(root.y) - root.y

    ClippingRectangle {
        id: chassis
        x: Math.round(root.x + root.lerp(root.from.x, 0)
            - root.swellX * root.anchorX / Math.max(1, root.width)) - root.x
        y: Math.round(root.y + root.lerp(root.from.y, 0)
            - root.swellY * root.anchorY / Math.max(1, root.height)) - root.y
        width: Math.round(root.lerp(root.from.width, root.width) + root.swellX)
        height: Math.round(root.lerp(root.from.height, root.height) + root.swellY)
        radius: Math.min(width / 2, height / 2, root.lerp(root.fromRadius, root.radius))
        color: root.color
        // Visible from the request: forceActiveFocus() is ignored on invisible subtrees.
        visible: root.open || root.presentation > 0
        opacity: root.armed || root.presentation > 0 ? 1 : 0

        Rectangle {
            id: lightWash
            readonly property real reach: Math.min(IrisStyle.lightReach, (lightWash.across ? parent.width : parent.height) * 0.6)
            x: root.lightFrom === "left" ? IrisStyle.lightJoinContour
                : root.lightFrom === "right" ? parent.width - IrisStyle.lightJoinContour - width : IrisStyle.lightContour
            y: root.lightFrom === "top" ? IrisStyle.lightJoinContour
                : root.lightFrom === "bottom" ? parent.height - IrisStyle.lightJoinContour - height : IrisStyle.lightContour
            width: lightWash.across ? lightWash.reach : Math.max(0, parent.width - 2 * IrisStyle.lightContour)
            height: lightWash.across ? Math.max(0, parent.height - 2 * IrisStyle.lightContour) : lightWash.reach
            radius: Math.max(0, chassis.radius - IrisStyle.lightContour)
            visible: IrisStyle.auraStrength > 0 && root.light.a > 0
            readonly property bool across: root.lightFrom === "left" || root.lightFrom === "right"
            readonly property bool reversed: root.lightFrom === "bottom" || root.lightFrom === "right"
            opacity: Math.max(0, Math.min(1, root.presentation))
            gradient: Gradient {
                orientation: lightWash.across ? Gradient.Horizontal : Gradient.Vertical
                GradientStop { position: 0; color: lightWash.reversed ? "transparent" : IrisStyle.aura(root.light) }
                GradientStop { position: 0.5; color: IrisStyle.auraFading(root.light) }
                GradientStop { position: 1; color: lightWash.reversed ? IrisStyle.aura(root.light) : "transparent" }
            }
        }

        Item {
            id: contentHost
            x: root.contentTravels ? 0 : root.snapX - chassis.x
            y: root.contentTravels ? 0 : root.snapY - chassis.y
            width: root.width
            height: root.height
            opacity: root.open
                ? IrisStyle.ramp(root.presentation, root.contentFadeStart, root.contentFadeSpan)
                : IrisStyle.ramp(root.presentation, root.contentExitStart, root.contentExitSpan)
            scale: {
                if (root.presentation >= 1) return 1
                if (IrisStyle.revealFades) return 1
                if (IrisStyle.revealInflates)
                    return Math.max(0.35, Math.min(1, chassis.height / Math.max(1, root.height)))
                return root.contentScaleFrom + (1 - root.contentScaleFrom) * root.presentation
            }
            enabled: root.open
        }
    }
}
