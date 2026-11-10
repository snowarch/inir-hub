pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.field
import qs.modules.iris.style

// The body of a widget joined to the frame, in its output's coordinates: the frame's material from the widget out to
// its walls, filleted as a line of bubbles is, one silhouette with the welds beside it. Drawn under the widget on the
// desktop and by the frame's window while the compositor shows its overview. `weld` is an IrisWidgetWeld.
Item {
    id: body

    required property var weld
    readonly property var neighbours: body.weld.neighbours
    readonly property rect rest: body.weld.rest
    readonly property var reach: body.weld.reachOut
    readonly property real fuse: body.weld.fuse
    // Room for the fillets beside the body; cut at each joined wall, where the frame itself stands above, and halfway
    // to a neighbour, whose own body draws the other half of the same silhouette.
    readonly property real room: Math.round(body.fuse * 2 + 24 * IrisStyle.density)
    readonly property real bridge: Math.round(22 * IrisStyle.density)
    readonly property rect cut: {
        const w = body.weld, r = body.rest
        let left = w.meltLeft > 0 ? r.x - body.reach.left : r.x - body.room
        let top = w.meltTop > 0 ? r.y - body.reach.top : r.y - body.room
        let right = r.x + r.width + (w.meltRight > 0 ? body.reach.right : body.room)
        let bottom = r.y + r.height + (w.meltBottom > 0 ? body.reach.bottom : body.room)
        for (const other of body.neighbours) {
            const o = other.box
            const dx = Math.max(o.x - r.x - r.width, r.x - o.x - o.width)
            const dy = Math.max(o.y - r.y - r.height, r.y - o.y - o.height)
            if (dx >= dy) {
                if (o.x >= r.x + r.width) right = Math.min(right, Math.round((r.x + r.width + o.x) / 2))
                else if (o.x + o.width <= r.x) left = Math.max(left, Math.round((r.x + o.x + o.width) / 2))
            } else {
                if (o.y >= r.y + r.height) bottom = Math.min(bottom, Math.round((r.y + r.height + o.y) / 2))
                else if (o.y + o.height <= r.y) top = Math.max(top, Math.round((r.y + o.y + o.height) / 2))
            }
        }
        return Qt.rect(left, top, Math.max(0, right - left), Math.max(0, bottom - top))
    }
    x: body.cut.x
    y: body.cut.y
    width: body.cut.width
    height: body.cut.height
    clip: true

    IrisField {
        id: field
        readonly property real pad: body.room + body.weld.neckMost
        readonly property real deep: field.pad * 2
        readonly property real fx: body.rest.x - field.pad
        readonly property real fy: body.rest.y - field.pad
        x: field.fx - body.cut.x
        y: field.fy - body.cut.y
        width: body.rest.width + field.pad * 2
        height: body.rest.height + field.pad * 2
        framed: false
        plain: true
        compositorAllowed: false
        smoothing: body.fuse
        sceneOrigin: Qt.point(field.fx, field.fy)
        sceneSize: Qt.size(body.weld.sceneWidth, body.weld.sceneHeight)
        shapes: {
            const w = body.weld, r = body.rest, deep = field.deep
            const all = [w].concat(body.neighbours)
            // Each wall is a slab past the cut for the bodies on it to join, as strong as the most joined of them.
            const melts = { left: 0, top: 0, right: 0, bottom: 0 }
            for (const one of all) {
                melts.left = Math.max(melts.left, one.meltLeft); melts.top = Math.max(melts.top, one.meltTop)
                melts.right = Math.max(melts.right, one.meltRight); melts.bottom = Math.max(melts.bottom, one.meltBottom)
            }
            const out = []
            const wall = (id, melt, x, y, width, height) => {
                if (melt > 0) out.push({ id: id, x: x - field.fx, y: y - field.fy, width: width, height: height, radius: 0,
                    paints: true, fuse: body.fuse * melt })
            }
            const line = w.walls
            wall("wallLeft", melts.left, line.left - deep, field.fy - deep, deep, field.height + deep * 2)
            wall("wallRight", melts.right, line.right, field.fy - deep, deep, field.height + deep * 2)
            wall("wallTop", melts.top, field.fx - deep, line.top - deep, field.width + deep * 2, deep)
            wall("wallBottom", melts.bottom, field.fx - deep, line.bottom, field.width + deep * 2, deep)
            const wallsOf = one => [["wallLeft", one.meltLeft], ["wallRight", one.meltRight], ["wallTop", one.meltTop],
                ["wallBottom", one.meltBottom]].filter(pair => pair[1] > 0).map(pair => pair[0])
            // A corner on a joined wall is square: the wall is the same matter, and two rounds side by side left a hole.
            const cornersOf = one => {
                const r = one.bodyRadius
                return { tl: r * (1 - Math.max(one.meltLeft, one.meltTop)), tr: r * (1 - Math.max(one.meltRight, one.meltTop)),
                    br: r * (1 - Math.max(one.meltRight, one.meltBottom)), bl: r * (1 - Math.max(one.meltLeft, one.meltBottom)) }
            }
            const b = w.box
            out.push({ id: "widget", x: b.x - field.fx, y: b.y - field.fy, width: b.width, height: b.height,
                radius: w.bodyRadius, corners: cornersOf(w), fuse: body.fuse * w.melt, joins: wallsOf(w).slice(0, 2) })
            body.neighbours.forEach((other, index) => {
                const o = other.box
                // Two bodies a finger apart on one wall close into one, with a notch where they met: a smooth union
                // fills a gap only up to a quarter of its reach. Both fields work the same reach out, so the halves agree.
                const gap = Math.max(o.x - b.x - b.width, b.x - o.x - o.width, o.y - b.y - b.height, b.y - o.y - o.height, 0)
                const reach = Math.max(body.fuse * w.melt, other.fuse * other.melt, gap <= body.bridge ? gap * 2.6 : 0)
                out.push({ id: "beside" + index, x: o.x - field.fx, y: o.y - field.fy, width: o.width, height: o.height,
                    radius: other.bodyRadius, corners: cornersOf(other), fuse: reach, joins: wallsOf(other).slice(0, 1).concat(["widget"]) })
            })
            return out.slice(0, field.capacity)
        }
    }

    // Tucked, the body is a tab on the frame that says which widget waits in it.
    MaterialSymbol {
        visible: opacity > 0
        opacity: Math.max(0, body.weld.tuck * 2 - 1)
        x: body.weld.box.x + (body.weld.box.width - width) / 2 - body.cut.x
        y: body.weld.box.y + (body.weld.box.height - height) / 2 - body.cut.y
        text: body.weld.glyph
        fill: 1
        iconSize: Math.round(18 * IrisStyle.density)
        color: IrisStyle.textSecondary
    }
}
