pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.iris.field
import qs.modules.iris.frame
import qs.modules.iris.style

// Joined to the frame (`iris.surround.widgets`): a desktop widget left against a wall of the frame is one body with it,
// as a bubble is. The weld comes from where the widget stands: pushed as near the wall as it goes it joins, pulled away
// it lets go. Its body is then the frame's material, drawn by a field of its own under the content; whoever drew the
// body before (a plate, a face, a Prism slab) steps aside while `welded`. Fills the body it stands in for.
Item {
    id: weld

    required property var widget
    property real radius: 0
    // The body would be drawn at all (a plate that is on, a face that is not a Design's print).
    property bool can: true

    readonly property bool joinsFrame: IrisFrame.framed && weld.can && weld.visible
        && Boolean(Config.options?.iris?.surround?.widgets ?? true) && Boolean(weld.widget?.powerActive ?? true)
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

    Loader {
        id: cut
        active: weld.melt > 0
        opacity: weld.cover
        // The fillet's radius is the widget's own round, as a line of bubbles melted into a wall (IrisStyle.edgeFuseFor):
        // the corner beside the wall turns into one S of two equal arcs.
        readonly property real fuse: Math.max(8, Math.round(weld.radius * 4 * (1 - Math.SQRT1_2)))
        // Room for the fillets beside the body; cut at each joined wall, where the frame itself stands above.
        readonly property real room: Math.round(cut.fuse * 2 + 24 * IrisStyle.density)
        readonly property real cutLeft: weld.meltLeft > 0 ? -weld.reachOut.left : -cut.room
        readonly property real cutTop: weld.meltTop > 0 ? -weld.reachOut.top : -cut.room
        readonly property real cutRight: weld.width + (weld.meltRight > 0 ? weld.reachOut.right : cut.room)
        readonly property real cutBottom: weld.height + (weld.meltBottom > 0 ? weld.reachOut.bottom : cut.room)
        x: cut.cutLeft
        y: cut.cutTop
        width: cut.cutRight - cut.cutLeft
        height: cut.cutBottom - cut.cutTop
        sourceComponent: Item {
            clip: true
            IrisField {
                id: field
                readonly property real pad: cut.room + weld.neckMost
                readonly property real deep: field.pad * 2
                x: -field.pad - cut.cutLeft
                y: -field.pad - cut.cutTop
                width: weld.width + field.pad * 2
                height: weld.height + field.pad * 2
                framed: false
                compositorAllowed: false
                smoothing: cut.fuse
                sceneOrigin: Qt.point(weld.origin.x - field.pad, weld.origin.y - field.pad)
                sceneSize: Qt.size(weld.sceneWidth, weld.sceneHeight)
                shapes: {
                    const pad = field.pad, deep = field.deep
                    // The body reaches for its walls; each wall is a slab past the cut for the body to join.
                    const left = pad - weld.reachOut.left * weld.meltLeft
                    const top = pad - weld.reachOut.top * weld.meltTop
                    const right = pad + weld.width + weld.reachOut.right * weld.meltRight
                    const bottom = pad + weld.height + weld.reachOut.bottom * weld.meltBottom
                    const out = [], walls = []
                    const wall = (id, melt, x, y, width, height) => {
                        if (melt <= 0) return
                        out.push({ id: id, x: x, y: y, width: width, height: height, radius: 0, paints: true, fuse: cut.fuse * melt })
                        walls.push(id)
                    }
                    wall("wallLeft", weld.meltLeft, pad - weld.reachOut.left - deep, -deep, deep, field.height + deep * 2)
                    wall("wallRight", weld.meltRight, pad + weld.width + weld.reachOut.right, -deep, deep, field.height + deep * 2)
                    wall("wallTop", weld.meltTop, -deep, pad - weld.reachOut.top - deep, field.width + deep * 2, deep)
                    wall("wallBottom", weld.meltBottom, -deep, pad + weld.height + weld.reachOut.bottom, field.width + deep * 2, deep)
                    out.push({ id: "widget", x: left, y: top, width: right - left, height: bottom - top, radius: weld.radius,
                        fuse: cut.fuse * weld.melt, joins: walls.slice(0, 2) })
                    return out
                }
            }
        }
    }
}
