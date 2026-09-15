pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs
import qs.modules.iris.style

// A surface that grows out of the Island part that opened it and collapses
// back into it. Position/size this item at the surface's resting geometry; the
// clipping chassis interpolates from GlobalStates.irisMorphOrigin to that rect
// on one progress value, so reversing mid-flight stays a single coherent shape.
Item {
    id: root

    property bool open: false
    // Consumers whose size depends on laid-out content hold the morph until it
    // exists; otherwise the first frames would chase a placeholder rectangle.
    property bool contentReady: true
    // Optional scene-space origin ({x, y, width, height, radius}) owned by the
    // consumer, e.g. a Dock icon; falls back to the Island's published origin.
    property var origin: null
    // Or an item to grow out of, mapped live so a window resize during the
    // open (e.g. a layer surface growing to catch outside clicks) cannot skew it.
    property Item originItem: null
    property real originItemRadius: 0
    property real radius: IrisStyle.radius
    property color color: IrisStyle.surface
    property real contentScaleFrom: 0.965
    property real contentFadeStart: 0.35
    property real contentFadeSpan: 0.5
    property int animationDuration: IrisStyle.settleDuration
    // Content normally rests in place while the chassis grows around it. A
    // surface that travels (an origin of its own size) carries its content.
    property bool contentTravels: false
    default property alias content: contentHost.data
    readonly property real progress: root.presentation
    readonly property bool settled: root.presentation >= 1
    signal closed()

    // Origin in scene (window) coordinates, captured when an open starts. The
    // local rect is derived reactively: a fresh layer surface is still 0×0 when
    // the open request lands, so converting eagerly would bake in a stale offset.
    property var originScene: null
    property real fromRadius: root.radius
    // A consumer-owned origin is followed live: it is usually derived from the
    // window's own size, which a fresh layer surface does not know yet.
    readonly property rect from: root.originItem ? root.itemRect()
        : root.origin ? Qt.rect(root.origin.x - root.x, root.origin.y - root.y, root.origin.width, root.origin.height)
        : root.originScene
        ? Qt.rect(root.originScene.x - root.x, root.originScene.y - root.y, root.originScene.width, root.originScene.height)
        : Qt.rect(root.width * 0.04, root.height * 0.04, root.width * 0.92, root.height * 0.92)
    function itemRect(): rect {
        // Re-evaluated whenever this surface or the window moves/resizes.
        void (root.x + root.y + root.width + root.height + (root.Window.window?.height ?? 0))
        const item = root.originItem
        const p = item.mapToItem(root, 0, 0)
        return Qt.rect(p.x, p.y, item.width * item.scale, item.height * item.scale)
    }
    property bool armed: false
    property real presentation: root.armed ? 1 : 0
    Behavior on presentation {
        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: IrisStyle.morphCurve
        }
    }
    onPresentationChanged: if (root.presentation <= 0 && !root.open) root.closed()

    // Growing out of the Island: that part hides while the shape is in flight
    // (see GlobalStates.irisMorphHandoff), so the Island becomes the surface.
    readonly property bool fromIsland: !root.originItem && !root.origin && root.originScene !== null
    Binding {
        target: GlobalStates
        property: "irisMorphHandoff"
        value: true
        when: root.fromIsland && root.presentation > 0 && root.presentation < 1
        restoreMode: Binding.RestoreValue
    }

    // Expects the surface to be a direct child of its window's content item,
    // so x/y are scene coordinates.
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
            // Collapse into the Island's current shape (it has usually
            // collapsed itself since it opened this surface).
            if (root.fromIsland) Qt.callLater(root.captureOrigin)
        } else {
            Qt.callLater(root.arm)
        }
    }
    Component.onCompleted: Qt.callLater(root.arm)

    function lerp(a: real, b: real): real { return a + (b - a) * root.presentation }

    ClippingRectangle {
        id: chassis
        x: root.lerp(root.from.x, 0)
        y: root.lerp(root.from.y, 0)
        width: root.lerp(root.from.width, root.width)
        height: root.lerp(root.from.height, root.height)
        radius: Math.min(width / 2, height / 2, root.lerp(root.fromRadius, root.radius))
        color: root.color
        // Visible from the open request, not the first animated frame: an
        // invisible subtree silently rejects forceActiveFocus() on open.
        visible: root.open || root.presentation > 0
        // Until armed the origin is not captured yet; never paint the fallback.
        opacity: root.armed || root.presentation > 0 ? 1 : 0

        Item {
            id: contentHost
            x: root.contentTravels ? 0 : -chassis.x
            y: root.contentTravels ? 0 : -chassis.y
            width: root.width
            height: root.height
            // Content arrives once the shape has mostly formed and leaves first.
            opacity: Math.max(0, Math.min(1, (root.presentation - root.contentFadeStart) / Math.max(0.01, root.contentFadeSpan)))
            // Settles from slightly smaller, so content rides the chassis growth.
            scale: root.contentScaleFrom + (1 - root.contentScaleFrom) * root.presentation
            enabled: root.open
        }
    }
}
