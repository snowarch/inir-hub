pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.iris.frame

Region {
    id: root

    property var shapes: []
    property bool framed: false
    property bool joinsFrame: root.framed
    property real windowWidth: 0
    property real windowHeight: 0
    property real band: IrisFrame.band
    property real cornerRadius: IrisFrame.cornerRadius
    // The compositor blurs exactly the shape it is given, and this region can only ever approximate
    // the field's SDF silhouette. So it is kept strictly inside it: anything that falls short is a
    // sharp pixel the field then paints over, while anything that overshoots is blur outside the
    // body, which is what reads as the blur not sticking to the shape. The field's edge ramps over
    // 1.4 px, so 2 clears it whole.
    property real inset: 2
    // Rebuilding this region is JS plus 64 bound sub-regions, and the chassis composes its table
    // from several sources that each arrive on their own: measured at 594 rebuilds a second during
    // a morph, eight per frame, for a shape the compositor reads once per frame. The zero timer
    // takes the last of those eight instead of each one, so the region still lands on its own frame
    // and never trails the body it belongs to. The settle pass carries the exact resting contour.
    property var held: []
    // A body that leaves (a dismissed banner, a closed card) takes its region with it in the same turn: the
    // region reaches the compositor only with a frame that has something to draw, and a turn later the frame
    // that removed the body is gone, so its blur stayed until the next repaint.
    onShapesChanged: {
        if ((root.shapes ?? []).length < (root.held ?? []).length) { perFrame.stop(); root.held = root.shapes ?? [] }
        else if (!perFrame.running) perFrame.restart()
        settle.restart()
    }
    property Timer perFrame: Timer { interval: 0; onTriggered: root.held = root.shapes ?? [] }
    property Timer settle: Timer { interval: 96; onTriggered: { root.held = root.shapes ?? []; root.kick() } }
    readonly property var pieces: root.build(root.held ?? [])
    readonly property bool empty: root.pieces.length === 0 && !root.framed

    // The window this region blurs. The region publishes itself, as DMS's WindowBlur does: nothing
    // while the window is hidden, a fresh commit once the shape settles (a nested Region can change
    // without the compositor hearing of it) and null before the window goes, so no blur outlives
    // the body it belonged to.
    property var window: null
    function apply(): void {
        if (!root.window) return
        root.window.BackgroundEffect.blurRegion = root.empty || !root.window.visible ? null : root
    }
    function kick(): void {
        if (!root.window || root.empty || !root.window.visible) return root.apply()
        root.window.BackgroundEffect.blurRegion = null
        root.window.BackgroundEffect.blurRegion = root
    }
    onEmptyChanged: root.apply()
    onWindowChanged: root.apply()
    property Connections windowState: Connections {
        target: root.window
        ignoreUnknownSignals: true
        function onVisibleChanged(): void { root.window.visible ? root.kick() : root.apply() }
    }
    Component.onCompleted: root.apply()
    Component.onDestruction: if (root.window) root.window.BackgroundEffect.blurRegion = null

    function bandRects(): var {
        const w = root.windowWidth, h = root.windowHeight, b = root.band
        return [{ x: 0, y: 0, width: w, height: b }, { x: 0, y: h - b, width: w, height: b },
            { x: 0, y: 0, width: b, height: h }, { x: w - b, y: 0, width: b, height: h }]
    }
    // The shader's smooth union of two perpendicular edges is, within 1.2 % of k, a quarter circle of radius 0.8536 k.
    function joinPieces(s: var, t: var, out: var): void {
        const k = Math.max(0, Number(s.fuse ?? 0))
        const f = k * 0.8536
        const r = Number(s.radius ?? 0)
        const ox = Math.min(s.x + s.width, t.x + t.width) - Math.max(s.x, t.x)
        const oy = Math.min(s.y + s.height, t.y + t.height) - Math.max(s.y, t.y)
        const i = root.inset
        // Inside a fused body the inset is a seam, not a margin: base and fillets reach `i` into both shapes.
        const fillet = (x, y, w, h, ex, ey, gl, gr, gt, gb) => out.push({ x: x - gl, y: y - gt, width: w + gl + gr, height: h + gt + gb, radius: 0,
            cut: { x: ex - i, y: ey - i, width: 2 * w + 2 * i, height: 2 * h + 2 * i } })
        if (ox > 0 && ox >= oy) {
            const below = s.y + s.height / 2 > t.y + t.height / 2
            const c = below ? t.y + t.height : t.y
            const gap = below ? s.y - c : c - (s.y + s.height)
            if (gap > k / 2) return
            const y0 = below ? c - i : Math.min(c, s.y + s.height) - r
            const y1 = below ? Math.max(c, s.y) + r : c + i
            out.push({ x: Math.max(s.x, t.x) + i, y: y0, width: Math.max(0, ox - 2 * i), height: y1 - y0, radius: 0 })
            if (f < 1) return
            const narrow = s.width <= t.width ? s : t
            const into = narrow === s ? below : !below
            const fh = Math.min(f, (into ? narrow.y + narrow.height - c : c - narrow.y) - Number(narrow.radius ?? 0) / 2)
            if (fh < 1) return
            const fy = into ? c : c - fh
            const ey = into ? c : c - 2 * fh
            const gt = into ? i : 0, gb = into ? 0 : i
            if (narrow.x - f >= Math.min(s.x, t.x) - 0.5) fillet(narrow.x - f, fy, f, fh, narrow.x - 2 * f, ey, 0, i, gt, gb)
            if (narrow.x + narrow.width + f <= Math.max(s.x + s.width, t.x + t.width) + 0.5) fillet(narrow.x + narrow.width, fy, f, fh, narrow.x + narrow.width, ey, i, 0, gt, gb)
        } else if (oy > 0) {
            const right = s.x + s.width / 2 > t.x + t.width / 2
            const c = right ? t.x + t.width : t.x
            const gap = right ? s.x - c : c - (s.x + s.width)
            if (gap > k / 2) return
            const x0 = right ? c - i : Math.min(c, s.x + s.width) - r
            const x1 = right ? Math.max(c, s.x) + r : c + i
            out.push({ x: x0, y: Math.max(s.y, t.y) + i, width: x1 - x0, height: Math.max(0, oy - 2 * i), radius: 0 })
            if (f < 1) return
            const narrow = s.height <= t.height ? s : t
            const into = narrow === s ? right : !right
            const fw = Math.min(f, (into ? narrow.x + narrow.width - c : c - narrow.x) - Number(narrow.radius ?? 0) / 2)
            if (fw < 1) return
            const fx = into ? c : c - fw
            const ex = into ? c : c - 2 * fw
            const gl = into ? i : 0, gr = into ? 0 : i
            if (narrow.y - f >= Math.min(s.y, t.y) - 0.5) fillet(fx, narrow.y - f, fw, f, ex, narrow.y - 2 * f, gl, gr, 0, i)
            if (narrow.y + narrow.height + f <= Math.max(s.y + s.height, t.y + t.height) + 0.5) fillet(fx, narrow.y + narrow.height, fw, f, ex, narrow.y + narrow.height, gl, gr, i, 0)
        }
    }
    function build(list: var): var {
        const byId = {}
        for (const s of list) if (s.id) byId[s.id] = s
        const out = []
        const joined = []
        for (const s of list) {
            const i = root.inset
            out.push({ x: s.x + i, y: s.y + i, width: s.width - 2 * i, height: s.height - 2 * i, radius: Math.max(0, Number(s.radius ?? 0) - i) })
            const joins = !s.joins ? [] : Array.isArray(s.joins) ? s.joins : [s.joins]
            for (const id of joins) {
                if (id === "frame") {
                    if (root.joinsFrame) for (const t of root.bandRects()) root.joinPieces(s, t, joined)
                } else if (byId[id]) root.joinPieces(s, byId[id], joined)
            }
        }
        // Past the pool, a fillet goes before a body does.
        return out.concat(joined).slice(0, 64)
    }

    component Piece: Region {
        id: piece
        required property int index
        readonly property var p: root.pieces[piece.index] ?? null
        // Rounded inwards: a region is whole pixels, and the half pixel taken here is one the field
        // paints over, while the half pixel given away would be blur past the body's edge.
        x: piece.p ? Math.ceil(piece.p.x) : 0
        y: piece.p ? Math.ceil(piece.p.y) : 0
        width: piece.p ? Math.max(0, Math.floor(piece.p.x + piece.p.width) - Math.ceil(piece.p.x)) : 0
        height: piece.p ? Math.max(0, Math.floor(piece.p.y + piece.p.height) - Math.ceil(piece.p.y)) : 0
        radius: piece.p ? Math.min(Math.ceil(piece.p.radius), piece.width / 2, piece.height / 2) : 0
        Region {
            shape: RegionShape.Ellipse
            intersection: Intersection.Subtract
            // What is subtracted rounds the other way, for the same reason.
            x: piece.p?.cut ? Math.floor(piece.p.cut.x) : 0
            y: piece.p?.cut ? Math.floor(piece.p.cut.y) : 0
            width: piece.p?.cut ? Math.ceil(piece.p.cut.width) : 0
            height: piece.p?.cut ? Math.ceil(piece.p.cut.height) : 0
        }
    }

    Region {
        width: root.framed ? root.windowWidth : 0
        height: root.framed ? root.windowHeight : 0
        Region {
            intersection: Intersection.Subtract
            x: root.band - root.inset
            y: root.band - root.inset
            width: Math.max(0, root.windowWidth - 2 * (root.band - root.inset))
            height: Math.max(0, root.windowHeight - 2 * (root.band - root.inset))
            radius: root.cornerRadius + root.inset
        }
    }
    Piece { index: 0 }
    Piece { index: 1 }
    Piece { index: 2 }
    Piece { index: 3 }
    Piece { index: 4 }
    Piece { index: 5 }
    Piece { index: 6 }
    Piece { index: 7 }
    Piece { index: 8 }
    Piece { index: 9 }
    Piece { index: 10 }
    Piece { index: 11 }
    Piece { index: 12 }
    Piece { index: 13 }
    Piece { index: 14 }
    Piece { index: 15 }
    Piece { index: 16 }
    Piece { index: 17 }
    Piece { index: 18 }
    Piece { index: 19 }
    Piece { index: 20 }
    Piece { index: 21 }
    Piece { index: 22 }
    Piece { index: 23 }
    Piece { index: 24 }
    Piece { index: 25 }
    Piece { index: 26 }
    Piece { index: 27 }
    Piece { index: 28 }
    Piece { index: 29 }
    Piece { index: 30 }
    Piece { index: 31 }
    Piece { index: 32 }
    Piece { index: 33 }
    Piece { index: 34 }
    Piece { index: 35 }
    Piece { index: 36 }
    Piece { index: 37 }
    Piece { index: 38 }
    Piece { index: 39 }
    Piece { index: 40 }
    Piece { index: 41 }
    Piece { index: 42 }
    Piece { index: 43 }
    Piece { index: 44 }
    Piece { index: 45 }
    Piece { index: 46 }
    Piece { index: 47 }
    Piece { index: 48 }
    Piece { index: 49 }
    Piece { index: 50 }
    Piece { index: 51 }
    Piece { index: 52 }
    Piece { index: 53 }
    Piece { index: 54 }
    Piece { index: 55 }
    Piece { index: 56 }
    Piece { index: 57 }
    Piece { index: 58 }
    Piece { index: 59 }
    Piece { index: 60 }
    Piece { index: 61 }
    Piece { index: 62 }
    Piece { index: 63 }
}
