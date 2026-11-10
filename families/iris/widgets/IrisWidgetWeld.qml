pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.shared.background.widgets
import qs.modules.iris.components
import qs.modules.iris.frame
import qs.modules.iris.style

// Joined to the frame (`iris.surround.widgets`): a desktop widget left against a wall of the frame is one body with it,
// as a bubble is. The weld comes from where the widget stands: pushed as near the wall as it goes it joins, pulled away
// it lets go. While joined it IS the frame: its body is a shape of the frame's own field (IrisWelds.shapesOn, drawn by
// the frame's window with the frame's matter, texture and line) and the widget itself moves into that window, over
// its body; whoever drew the body before (a plate, a face, a Prism slab) steps aside while `welded`.
Item {
    id: weld

    required property var widget
    property real radius: 0
    // The body would be drawn at all (a plate that is on, a face that is not a Design's print).
    property bool can: true

    readonly property string outputName: weld.widget?.outputName ?? ""
    // Held back by the weld itself (tucked, or kept by the frame's window in the overview) it is still joined.
    readonly property bool withheld: (weld.widget?.presence ?? 1) < 1
    // Arranging happens on the desktop, with its grid and sheets: a widget joins once it is left there.
    readonly property bool joinsFrame: IrisFrame.framed && weld.can && (weld.visible || weld.withheld)
        && !GlobalStates.widgetEditMode && !(weld.widget?.isDragging ?? false)
        && Boolean(Config.options?.iris?.surround?.widgets ?? false) && Boolean(weld.widget?.powerActive ?? true)
    readonly property real reach: Math.round(8 * IrisStyle.density)
    readonly property real neckMost: Math.round(72 * IrisStyle.density)
    readonly property point origin: {
        void (weld.width + weld.height + weld.x + weld.y)
        const at = weld.widget ? weld.mapToItem(weld.widget, 0, 0) : Qt.point(0, 0)
        return Qt.point((weld.widget?.x ?? 0) + at.x, (weld.widget?.y ?? 0) + at.y)
    }
    readonly property real sceneWidth: weld.widget?.scaledScreenWidth ?? weld.QsWindow.window?.screen?.width ?? 1920
    readonly property real sceneHeight: weld.widget?.scaledScreenHeight ?? weld.QsWindow.window?.screen?.height ?? 1080
    // How far each side stands from its wall, and from the nearest it may come to it (the desktop's work area: the
    // Island's strip keeps widgets off its wall). A widget pushed as near as it goes is welded; its body crosses the rest.
    readonly property var gaps: ({
        left: weld.origin.x - IrisFrame.wallOn("left"),
        top: weld.origin.y - IrisFrame.wallOn("top"),
        right: weld.sceneWidth - IrisFrame.wallOn("right") - weld.origin.x - weld.width,
        bottom: weld.sceneHeight - IrisFrame.wallOn("bottom") - weld.origin.y - weld.height
    })
    readonly property var room: {
        const placed = weld.widget?.placement ?? null
        if (!placed) return weld.gaps
        return { left: weld.widget.x - placed.safeLeft, top: weld.widget.y - placed.safeTop,
            right: placed.safeRight - weld.widget.x - weld.widget.width,
            bottom: placed.safeBottom - weld.widget.y - weld.widget.height }
    }
    function weldsOn(side: string): bool {
        return weld.joinsFrame && weld.room[side] <= weld.reach && weld.gaps[side] <= weld.neckMost
            && weld.gaps[side] > -weld.reach
    }
    readonly property bool onLeft: weld.weldsOn("left")
    readonly property bool onTop: weld.weldsOn("top")
    readonly property bool onRight: weld.weldsOn("right")
    readonly property bool onBottom: weld.weldsOn("bottom")
    readonly property bool wanted: weld.onLeft || weld.onTop || weld.onRight || weld.onBottom
    // The join is a morph, never a switch: each side melts in on its own scalar (the body reaches for the wall while the
    // fillets grow from nothing to the widget's own round, as a line of bubbles does) and out again.
    property real meltLeft: weld.onLeft ? 1 : 0
    property real meltTop: weld.onTop ? 1 : 0
    property real meltRight: weld.onRight ? 1 : 0
    property real meltBottom: weld.onBottom ? 1 : 0
    Behavior on meltLeft { enabled: IrisStyle.motionEnabled; NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.OutCubic } }
    Behavior on meltTop { enabled: IrisStyle.motionEnabled; NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.OutCubic } }
    Behavior on meltRight { enabled: IrisStyle.motionEnabled; NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.OutCubic } }
    Behavior on meltBottom { enabled: IrisStyle.motionEnabled; NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.OutCubic } }
    readonly property real melt: Math.max(weld.meltLeft, weld.meltTop, weld.meltRight, weld.meltBottom)
    // The frame's material stands over the widget's own body from the first third of the way in; the body under it
    // steps aside only then, and is back before the weld lets go, so neither way shows a hole.
    readonly property real cover: Math.min(1, weld.melt * 3)
    readonly property bool welded: weld.wanted && weld.cover >= 1
    // A side's last distance to its wall is kept while it melts out: the widget is already leaving.
    property var held: ({ left: 0, top: 0, right: 0, bottom: 0 })
    function hold(): void {
        const next = {}
        let moved = false
        for (const side of IrisFrame.edges) {
            next[side] = weld.weldsOn(side) ? Math.max(0, weld.gaps[side]) : weld.held[side]
            if (next[side] !== weld.held[side]) moved = true
        }
        if (moved) weld.held = next
    }
    onGapsChanged: weld.hold()
    onWantedChanged: weld.hold()
    Component.onCompleted: weld.hold()
    readonly property var reachOut: weld.held

    // How it rests on the frame (`iris.surround.widgetsRest`, or its own `iris.frame`): open, or tucked into a tab on
    // its wall until the pointer comes for it.
    readonly property string restMode: {
        const own = String(weld.widget?._readConfigKey("iris.frame") ?? "")
        return own === "open" || own === "tucked" ? own : String(Config.options?.iris?.surround?.widgetsRest ?? "open")
    }
    readonly property bool stows: weld.wanted && weld.restMode === "tucked" && !GlobalStates.widgetEditMode
        && !(weld.widget?.isDragging ?? false)
    property bool called: false
    property bool tabPointed: false
    readonly property bool pointed: ownHover.hovered || weld.tabPointed
    onPointedChanged: {
        if (weld.pointed) { leave.stop(); weld.called = true }
        else leave.restart()
    }
    Timer { id: leave; interval: 320; onTriggered: weld.called = weld.pointed }
    HoverHandler { id: ownHover }
    IrisSpring {
        id: tucking
        surface: "widgets"
        intent: "move"
        animate: IrisStyle.motionEnabled
        to: weld.stows && !weld.called ? 1 : 0
    }
    readonly property real tuck: Math.max(0, Math.min(1, tucking.value))
    readonly property real shown: Math.max(0, Math.min(1, 1 - weld.tuck / 0.35))
    readonly property string glyph: DesktopWidgetRegistry.entry(DesktopWidgetRegistry.baseKey(weld.widget?.configEntryName ?? ""))?.icon ?? "widgets"

    // The body in the desktop's coordinates: the widget's own box, or the tab it tucks into on its first wall.
    readonly property string tuckSide: weld.onLeft ? "left" : weld.onRight ? "right" : weld.onTop ? "top" : "bottom"
    readonly property rect rest: {
        const x = weld.origin.x, y = weld.origin.y, w = weld.width, h = weld.height, t = weld.tuck
        if (t <= 0) return Qt.rect(x, y, w, h)
        const deep = Math.round(26 * IrisStyle.density), along = Math.round(64 * IrisStyle.density)
        const upright = weld.tuckSide === "left" || weld.tuckSide === "right"
        const tw = upright ? deep : Math.min(w, along), th = upright ? Math.min(h, along) : deep
        const tx = weld.tuckSide === "right" ? x + w - tw : upright ? x : x + (w - tw) / 2
        const ty = weld.tuckSide === "bottom" ? y + h - th : upright ? y + (h - th) / 2 : y
        return Qt.rect(x + (tx - x) * t, y + (ty - y) * t, w + (tw - w) * t, h + (th - h) * t)
    }
    readonly property rect box: {
        const r = weld.rest
        const left = r.x - weld.reachOut.left * weld.meltLeft, top = r.y - weld.reachOut.top * weld.meltTop
        return Qt.rect(left, top, r.x + r.width + weld.reachOut.right * weld.meltRight - left,
            r.y + r.height + weld.reachOut.bottom * weld.meltBottom - top)
    }
    // Where each wall's inner line runs beside the widget.
    readonly property var walls: ({ left: weld.origin.x - weld.reachOut.left, top: weld.origin.y - weld.reachOut.top,
        right: weld.origin.x + weld.width + weld.reachOut.right, bottom: weld.origin.y + weld.height + weld.reachOut.bottom })
    readonly property real bodyRadius: weld.radius + (Math.min(weld.radius, Math.round(13 * IrisStyle.density)) - weld.radius) * weld.tuck
    // The fillet's radius is the body's own round, as a line of bubbles melted into a wall (IrisStyle.edgeFuseFor):
    // the corner beside the wall turns into one S of two equal arcs.
    readonly property real fuse: Math.max(8, Math.round(weld.bodyRadius * 4 * (1 - Math.SQRT1_2)))
    // A corner on a joined wall is square: the wall is the same matter.
    readonly property var corners: {
        const r = weld.bodyRadius
        return { tl: r * (1 - Math.max(weld.meltLeft, weld.meltTop)), tr: r * (1 - Math.max(weld.meltRight, weld.meltTop)),
            br: r * (1 - Math.max(weld.meltRight, weld.meltBottom)), bl: r * (1 - Math.max(weld.meltLeft, weld.meltBottom)) }
    }
    Component.onDestruction: IrisWelds.remove(weld)
    onMeltChanged: if (weld.melt > 0) IrisWelds.add(weld); else IrisWelds.remove(weld)

    // In the frame's window while joined: there the frame draws its body, and the compositor's overview leaves it be.
    property Item home: null
    readonly property Item host: IrisWelds.hostOn(weld.outputName)
    readonly property bool hosted: weld.melt > 0 && weld.host !== null
    function settle(): void {
        const w = weld.widget
        if (!w) return
        if (weld.hosted) {
            if (w.parent === weld.host) return
            if (!weld.home) weld.home = w.parent
            w.parent = weld.host
        } else if (weld.home) {
            w.parent = weld.home
            weld.home = null
        }
    }
    onHostedChanged: weld.settle()
    onHostChanged: weld.settle()
    Binding {
        target: weld.widget
        property: "presence"
        value: weld.shown
        when: weld.wanted
        restoreMode: Binding.RestoreBindingOrValue
    }
}
