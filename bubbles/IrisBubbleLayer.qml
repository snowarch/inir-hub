pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.iris.components

// Bubbles off the Island on one output. Floating bubbles rest anchored to a
// corner or edge of the screen, or wherever they were let go; a bubble being
// carried (from the Island or from here) is drawn under the pointer with the
// places it can land. Letting go resolves the drop: near its slot on the Island
// it melts back in, near a zone it snaps there, anywhere else it stays free.
// The surface never takes the keyboard and its input is only the bubbles.
PanelWindow {
    id: root

    required property var modelData
    readonly property string screenName: root.modelData?.name ?? ""
    readonly property real d: IrisStyle.density
    readonly property var options: Config.options?.iris?.bubbles ?? ({})
    // The Island's three slots, then the extra bubbles ("extra-<kind>"), in the
    // order they line up when they share a zone.
    readonly property var islandSlots: ["left", "right", "utility"]
    readonly property var extraKinds: ["weather", "notifications", "controls", "sound", "mic", "tools", "media", "tray"]
    readonly property var allSlots: root.islandSlots.concat(root.extraKinds.map(kind => "extra-" + kind))
    function isExtra(slot: string): bool { return slot.startsWith("extra-") }
    function optionsFor(slot: string): var {
        return root.isExtra(slot) ? root.options?.extras?.[slot.slice(6)] : root.options?.[slot]
    }
    function configPath(slot: string): string {
        return root.isExtra(slot) ? "iris.bubbles.extras." + slot.slice(6) : "iris.bubbles." + slot
    }
    // "island" means not floating: a slot resting on the Island, or an extra that is off.
    function placeName(slot: string): string {
        const o = root.optionsFor(slot)
        if (root.isExtra(slot)) return (o?.enable ?? false) ? String(o?.place ?? "right") : "island"
        return String(o?.place ?? "island")
    }
    readonly property bool hasPlayer: String(MprisController.activePlayer?.trackTitle ?? "").length > 0
    readonly property int trayCount: SystemTray.items.values.filter(item => item && item.id).length
    function kindOf(slot: string): string {
        if (!root.isExtra(slot)) return String(root.kinds[slot] ?? "")
        const kind = slot.slice(6)
        if (kind === "media" && !root.hasPlayer) return ""
        if (kind === "tray" && root.trayCount === 0) return ""
        return kind
    }
    readonly property bool anyFloating: root.allSlots.some(slot => root.placeName(slot) !== "island")
    readonly property var kinds: GlobalStates.irisBubbleKinds?.[root.screenName] ?? ({})
    readonly property var island: GlobalStates.irisIslandGeometry?.[root.screenName] ?? null
    readonly property var drag: GlobalStates.irisBubbleDrag && GlobalStates.irisBubbleDrag.screen === root.screenName
        ? GlobalStates.irisBubbleDrag : null
    readonly property bool carryingIsland: root.drag?.slot === "island"
    readonly property real size: root.island?.bubble ?? Math.round(40 * root.d)
    readonly property real margin: Math.round(Math.max(0, Number(root.options?.edgeGap ?? 20)) * root.d)
    readonly property real snapRadius: Math.round(110 * root.d)
    readonly property real attachRadius: Math.round(80 * root.d)

    screen: root.modelData
    visible: root.anyFloating || root.drag !== null || landing.running
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:iris-bubbles"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { left: true; right: true; top: true; bottom: true }
    // Only the resting bubbles take input; a carried bubble keeps the implicit
    // grab of the surface it was pressed on, so this layer never needs more.
    // One fixed bubble per slot keeps these regions bound to real items (a bubble
    // that is not floating collapses to nothing).
    mask: Region {
        Region { item: leftBubble }
        Region { item: rightBubble }
        Region { item: utilityBubble }
        Region { item: weatherBubble }
        Region { item: notificationsBubble }
        Region { item: controlsBubble }
        Region { item: soundBubble }
        Region { item: micBubble }
        Region { item: toolsBubble }
        Region { item: mediaBubble }
        Region { item: trayBubble }
    }

    // ── Places ───────────────────────────────────────────────────────────
    readonly property var zones: {
        const half = root.size / 2
        const edge = root.margin + half
        // The top row keeps clear of the Island's own band when it rests up there.
        const g = root.island
        const top = g && !g.bottomEdge ? Math.max(edge, g.y + g.bubble / 2) : edge
        const bottom = g && g.bottomEdge ? Math.min(root.height - edge, g.y + g.height - g.bubble / 2) : root.height - edge
        return [
            { zone: "top-left", x: edge, y: top },
            { zone: "top-right", x: root.width - edge, y: top },
            { zone: "left", x: edge, y: root.height / 2 },
            { zone: "right", x: root.width - edge, y: root.height / 2 },
            { zone: "bottom-left", x: edge, y: bottom },
            { zone: "bottom-right", x: root.width - edge, y: bottom }
        ]
    }
    // Where a slot emerges beside the resting Island (its centre).
    function slotCentre(slot: string): point {
        const g = root.island
        if (!g) return Qt.point(root.width / 2, root.margin + root.size / 2)
        const cy = g.bottomEdge ? g.y + g.height - g.bubble / 2 : g.y + g.bubble / 2
        const step = g.bubble + g.gap
        if (slot === "left") return Qt.point(g.x - g.gap - g.bubble / 2, cy)
        if (slot === "utility") return Qt.point(g.x + g.width + (g.auxiliarySlot - 1) * step + g.gap + g.bubble / 2, cy)
        return Qt.point(g.x + g.width + g.gap + g.bubble / 2, cy)
    }
    function clampPoint(x: real, y: real): point {
        const lo = root.margin + root.size / 2
        return Qt.point(Math.max(lo, Math.min(root.width - lo, x)), Math.max(lo, Math.min(root.height - lo, y)))
    }
    // A zone holds a line of bubbles: along the edge inward from a corner, and
    // centred on the middle of a side edge.
    function placeOf(slot: string): point {
        const zone = root.placeName(slot)
        const found = root.zones.find(z => z.zone === zone)
        if (!found) {
            const o = root.optionsFor(slot)
            return root.clampPoint(Number(o?.fx ?? 0.5) * root.width, Number(o?.fy ?? 0.5) * root.height)
        }
        const line = root.allSlots.filter(other => root.placeName(other) === zone && root.kindOf(other).length > 0)
        const index = Math.max(0, line.indexOf(slot))
        const step = root.size + Math.round(8 * root.d)
        if (zone === "left" || zone === "right") return Qt.point(found.x, found.y + (index - (line.length - 1) / 2) * step)
        return Qt.point(found.x + (zone.endsWith("left") ? index : -index) * step, found.y)
    }
    // What a drop at (x, y) would do for this drag: re-attach, snap or free.
    function resolve(x: real, y: real): var {
        if (!root.drag) return null
        if (root.carryingIsland) return { zone: y > root.height / 2 ? "bottom" : "top" }
        if (!root.isExtra(root.drag.slot)) {
            const slot = root.slotCentre(root.drag.slot)
            if (Math.hypot(x - slot.x, y - slot.y) < root.attachRadius) return { zone: "island", x: slot.x, y: slot.y }
        }
        let best = null
        for (const z of (root.options?.snap ?? true) ? root.zones : []) {
            const distance = Math.hypot(x - z.x, y - z.y)
            if (distance < root.snapRadius && (!best || distance < best.distance)) best = { zone: z.zone, x: z.x, y: z.y, distance: distance }
        }
        if (best) return best
        const free = root.clampPoint(x, y)
        return { zone: "free", x: free.x, y: free.y }
    }
    readonly property var target: root.drag ? root.resolve(root.drag.x, root.drag.y) : null

    // One batched write, so the place and its position change together.
    function writeEntry(slot: string, place): void {
        const path = root.configPath(slot)
        const updates = {}
        updates[path + ".place"] = place.zone
        if (place.zone === "free") {
            updates[path + ".fx"] = Math.round(place.x / Math.max(1, root.width) * 10000) / 10000
            updates[path + ".fy"] = Math.round(place.y / Math.max(1, root.height) * 10000) / 10000
        }
        Config.setNestedValues(updates)
    }

    // A release: glide the carried bubble to where it lands, then hand it over.
    // A quick drag can be released before this layer has loaded, so the same
    // resolution also runs once on completion.
    Component.onCompleted: root.land()
    Connections {
        target: GlobalStates
        function onIrisBubbleDragChanged(): void { root.land() }
    }
    function land(): void {
        const drag = root.drag
        if (!drag || !drag.released || landing.running) return
        const place = root.resolve(drag.x, drag.y)
        if (root.carryingIsland) {
            const bottom = place.zone === "bottom"
            const current = String(Config.options?.iris?.bar?.position ?? "top") === "bottom"
            GlobalStates.irisBubbleDrag = null
            if (bottom !== current) Config.setNestedValue("iris.bar.position", bottom ? "bottom" : "top")
            return
        }
        landing.slot = drag.slot
        landing.kind = drag.kind
        landing.fromX = drag.x
        landing.fromY = drag.y
        landing.attaching = place.zone === "island"
        root.writeEntry(drag.slot, place)
        // Written first, so a zone's line already counts this bubble in its place.
        const lands = landing.attaching ? Qt.point(place.x, place.y) : root.placeOf(drag.slot)
        landing.toX = lands.x
        landing.toY = lands.y
        landing.restart()
    }
    SequentialAnimation {
        id: landing
        property string slot: ""
        property string kind: ""
        property real fromX: 0
        property real fromY: 0
        property real toX: 0
        property real toY: 0
        property bool attaching: false
        NumberAnimation {
            target: carried
            property: "travel"
            from: 0
            to: 1
            duration: IrisStyle.settleDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: IrisStyle.morphCurve
        }
        ScriptAction { script: GlobalStates.irisBubbleDrag = null }
    }

    // ── Floating bubbles ─────────────────────────────────────────────────
    component FloatingBubble: Item {
        id: bubble
        required property string slot
        readonly property string kind: root.kindOf(bubble.slot)
        readonly property bool floating: root.placeName(bubble.slot) !== "island" && bubble.kind.length > 0
        readonly property point place: root.placeOf(bubble.slot)
        readonly property bool carried: root.drag?.slot === bubble.slot || (landing.running && landing.slot === bubble.slot)
        // Not floating: no size, so its input region is empty too.
        width: bubble.floating ? root.size : 0
        height: width
        x: Math.round(bubble.place.x - root.size / 2)
        y: Math.round(bubble.place.y - root.size / 2)
        visible: bubble.floating
        opacity: bubble.carried ? 0 : 1

        // It floats: a soft shadow keeps the black disc off the windows below.
        RectangularShadow {
            anchors.fill: parent
            radius: width / 2
            offset.y: 3 * root.d
            blur: 14 * root.d
            color: Qt.rgba(0, 0, 0, 0.5)
        }
        IrisBubbleFace {
            anchors.fill: parent
            kind: bubble.kind
            pressed: grip.pressed && !grip.lifting
            hovered: bubbleHover.hovered
        }
        HoverHandler { id: bubbleHover; cursorShape: Qt.PointingHandCursor }
        WheelHandler {
            enabled: bubble.kind === "sound" || bubble.kind === "mic"
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const step = (event.angleDelta.y || event.pixelDelta.y * 4) > 0 ? 0.05 : -0.05
                if (bubble.kind === "mic") Audio.setSourceVolume((Audio.micVolume ?? 0) + step)
                else Audio.setSinkVolume((Audio.value ?? 0) + step)
            }
        }
        IrisBubbleGrip {
            id: grip
            anchors.fill: parent
            slot: bubble.slot
            kind: bubble.kind
            screenName: root.screenName
            onTapped: root.activate(bubble)
        }
        Binding {
            target: GlobalStates
            property: "irisMediaBubble"
            when: bubble.floating && bubble.kind === "media" && !bubble.carried
                && root.screenName === (GlobalStates.focusedScreen?.name ?? "")
            value: ({ x: bubble.x, y: bubble.y, width: bubble.width, height: bubble.height, radius: bubble.width / 2,
                screen: root.screenName, floating: true })
            restoreMode: Binding.RestoreNone
        }
    }
    FloatingBubble { id: leftBubble; slot: "left" }
    FloatingBubble { id: rightBubble; slot: "right" }
    FloatingBubble { id: utilityBubble; slot: "utility" }
    FloatingBubble { id: weatherBubble; slot: "extra-weather" }
    FloatingBubble { id: notificationsBubble; slot: "extra-notifications" }
    FloatingBubble { id: controlsBubble; slot: "extra-controls" }
    FloatingBubble { id: soundBubble; slot: "extra-sound" }
    FloatingBubble { id: micBubble; slot: "extra-mic" }
    FloatingBubble { id: toolsBubble; slot: "extra-tools" }
    FloatingBubble { id: mediaBubble; slot: "extra-media" }
    FloatingBubble { id: trayBubble; slot: "extra-tray" }

    // What a floating bubble does when tapped: the same as on the Island, with
    // surfaces growing out of the bubble where they can.
    function activate(bubble): void {
        const kind = bubble.kind
        if (kind === "media") {
            if (String(Config.options?.iris?.player?.bubbleOpens ?? "card") === "card") GlobalStates.irisMediaCardOpen = !GlobalStates.irisMediaCardOpen
            else GlobalStates.irisIslandPageRequest = "media"
        } else if (kind === "timer" || kind === "record") {
            GlobalStates.irisIslandPageRequest = "activity"
        } else if (kind === "controls") {
            GlobalStates.irisMorphOrigin = { x: bubble.x, y: bubble.y, width: bubble.width, height: bubble.height,
                radius: bubble.width / 2, screen: root.screenName }
            GlobalStates.controlPanelOpen = true
        } else if (kind === "notifications") {
            GlobalStates.openSidebarRight(root.screenName)
        } else if (kind === "weather") {
            GlobalStates.irisIslandPageRequest = "desktop"
        } else if (kind === "tray" || kind === "tools") {
            GlobalStates.irisIslandPageRequest = kind
        } else if (kind === "sound") {
            Audio.toggleMute()
        } else if (kind === "mic") {
            Audio.toggleMicMute()
        }
    }

    // ── While carrying ───────────────────────────────────────────────────
    // Landing places: quiet rings that answer when the bubble is over them.
    Repeater {
        model: !root.drag || root.carryingIsland ? []
            : root.isExtra(root.drag.slot) ? root.zones
            : root.zones.concat([{ zone: "island", x: root.slotCentre(root.drag.slot).x, y: root.slotCentre(root.drag.slot).y }])
        delegate: Rectangle {
            id: hint
            required property var modelData
            readonly property bool active: root.target?.zone === hint.modelData.zone && !root.drag?.released
            width: root.size + 10 * root.d
            height: width
            x: Math.round(hint.modelData.x - width / 2)
            y: Math.round(hint.modelData.y - height / 2)
            radius: width / 2
            color: hint.active ? ColorUtils.applyAlpha(IrisStyle.accent, 0.18) : ColorUtils.applyAlpha(IrisStyle.surface, 0.28)
            border.width: Math.max(1, Math.round(1.5 * root.d))
            border.color: hint.active ? IrisStyle.accent : ColorUtils.applyAlpha(IrisStyle.text, 0.28)
            scale: hint.active ? 1.08 : 1
            opacity: root.drag?.released ? 0 : 1
            Behavior on scale { NumberAnimation { duration: IrisStyle.duration(140); easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: IrisStyle.duration(120) } }
            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120) } }
        }
    }
    // Carrying the Island: the two edges it can rest on.
    Repeater {
        model: root.carryingIsland ? ["top", "bottom"] : []
        delegate: Rectangle {
            id: edgeHint
            required property string modelData
            readonly property bool active: root.target?.zone === edgeHint.modelData
            width: Math.round(root.drag?.width ?? 160 * root.d)
            height: Math.round(root.size)
            x: Math.round((root.width - width) / 2)
            y: edgeHint.modelData === "top" ? root.margin : root.height - height - root.margin
            radius: height / 2
            color: edgeHint.active ? ColorUtils.applyAlpha(IrisStyle.accent, 0.18) : ColorUtils.applyAlpha(IrisStyle.surface, 0.28)
            border.width: Math.max(1, Math.round(1.5 * root.d))
            border.color: edgeHint.active ? IrisStyle.accent : ColorUtils.applyAlpha(IrisStyle.text, 0.28)
            Behavior on color { ColorAnimation { duration: IrisStyle.duration(120) } }
        }
    }

    // The carried bubble: lifted a little while held, gliding to its place on release.
    Item {
        id: carried
        property real travel: 0
        readonly property bool shown: (root.drag !== null && root.drag.slot !== "island") || landing.running
        readonly property real px: landing.running ? landing.fromX + (landing.toX - landing.fromX) * carried.travel : (root.drag?.x ?? 0)
        readonly property real py: landing.running ? landing.fromY + (landing.toY - landing.fromY) * carried.travel : (root.drag?.y ?? 0)
        visible: carried.shown
        width: root.size
        height: root.size
        x: carried.px - width / 2
        y: carried.py - height / 2
        z: 10
        scale: landing.running ? 1.12 - 0.12 * carried.travel : 1.12

        RectangularShadow {
            anchors.fill: parent
            radius: width / 2
            offset.y: (landing.running ? 10 - 7 * carried.travel : 10) * root.d
            blur: (landing.running ? 26 - 12 * carried.travel : 26) * root.d
            color: Qt.rgba(0, 0, 0, landing.running && landing.attaching ? 0.55 * (1 - carried.travel) : 0.55)
        }
        IrisBubbleFace {
            anchors.fill: parent
            kind: landing.running ? landing.kind : String(root.drag?.kind ?? "")
        }
    }
    // Carrying the Island: a resting-shape ghost under the pointer.
    Rectangle {
        visible: root.carryingIsland && !(root.drag?.released ?? false)
        width: Math.round(root.drag?.width ?? 160 * root.d)
        height: Math.round(root.size)
        x: (root.drag?.x ?? 0) - width / 2
        y: (root.drag?.y ?? 0) - height / 2
        radius: height / 2
        color: IrisStyle.surface
        opacity: 0.9
        scale: 1.04
    }
}
