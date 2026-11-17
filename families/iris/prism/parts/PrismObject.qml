pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import "PrismObjects.js" as Objects

// A page's object in its art (`.claude/ref/language/letter-holo.png`): the thing the page sets, its lines white light
// with the desktop's hues glowing under them, a few parts filled faintly in those hues. A pin on each part a group owns
// (`PrismSpots`): pointing names the group and its value and draws its parts in the accent, a press goes to the group.
// Static: drawn again only on a size, colour, page or pointed group. A page with no object draws nothing (`drawn`).
Item {
    id: root
    property string pageId: ""
    property string tint: "grey"
    property real turn: 0
    // The page's groups ({ title, rows, changed }), as PrismPanel.groups.
    property var groups: []
    // A head stands its object at its right edge, under the window's corner; a well centres it.
    property bool atRight: false
    signal goGroup(string title)

    readonly property var spec: Objects.of(root.pageId)
    readonly property bool drawn: root.spec !== null
    // What the parts reach, in the spec's units: the drawing is fitted to its box by these, never by the spec's frame,
    // so an object fills the well or the head it is given. A pin's half stays inside.
    readonly property var reach: {
        const out = { x: 0, y: 0, w: 1.6, h: 1 }
        if (!root.drawn) return out
        let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity
        const take = (x, y) => { x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y) }
        for (const part of root.spec.parts) {
            if (part.k === "box") { take(part.x, part.y); take(part.x + part.w, part.y + part.h) }
            else if (part.k === "circle" || part.k === "arc") { take(part.cx - part.d / 2, part.cy - part.d / 2); take(part.cx + part.d / 2, part.cy + part.d / 2) }
            else for (const p of part.pts) take(p[0], p[1])
            if (part.pin) take(part.pin[0], part.pin[1])
        }
        return { x: x0, y: y0, w: Math.max(0.01, x1 - x0), h: Math.max(0.01, y1 - y0) }
    }
    readonly property real margin: PrismTheme.dp(10)
    readonly property real k: Math.max(1, Math.min((root.width - root.margin * 2) / root.reach.w, (root.height - root.margin * 2) / root.reach.h))
    readonly property real ox: (root.atRight ? root.width - root.margin - root.reach.w * root.k
        : (root.width - root.reach.w * root.k) / 2) - root.reach.x * root.k
    readonly property real oy: (root.height - root.reach.h * root.k) / 2 - root.reach.y * root.k
    readonly property var hues: PrismTheme.paletteAt(root.tint, root.turn)
    readonly property real line: Math.max(PrismTheme.dp(1.3), root.k * 0.008)
    readonly property real inset: Math.max(PrismTheme.dp(3), root.k * 0.014)
    readonly property color core: PrismTheme.light ? PrismTheme.ink : PrismTheme.paper
    // A small object keeps its parts in sight under its pins.
    readonly property real pinSize: Math.round(Math.max(PrismTheme.dp(11), Math.min(PrismTheme.dp(16), root.k * 0.11)))

    // The group a part belongs to on this page: its own group, or the group a row of it came from.
    function owner(name: string): string {
        if (name.length === 0) return ""
        const entry = root.groups.find(group => group.title === name
            || Array.from(group.rows ?? []).some(row => row.section === name || row.from === name))
        return entry ? String(entry.title) : ""
    }
    function rounded(x: real, y: real, w: real, h: real, r: real): string {
        r = Math.min(r, w / 2, h / 2)
        if (r < 0.5) return `M${x} ${y} H${x + w} V${y + h} H${x} Z`
        return `M${x + r} ${y} H${x + w - r} A${r} ${r} 0 0 1 ${x + w} ${y + r} V${y + h - r} A${r} ${r} 0 0 1 ${x + w - r} ${y + h} `
            + `H${x + r} A${r} ${r} 0 0 1 ${x} ${y + h - r} V${y + r} A${r} ${r} 0 0 1 ${x + r} ${y} Z`
    }
    function ring(cx: real, cy: real, r: real): string {
        return `M${cx - r} ${cy} A${r} ${r} 0 1 1 ${cx + r} ${cy} A${r} ${r} 0 1 1 ${cx - r} ${cy} Z`
    }

    // Every part as a path in this item's pixels, its hue from where it stands across the object. A part without a
    // group of its own belongs to the one before it (a speaker's cones are its output's); faint ones to none.
    readonly property var plan: {
        const out = { parts: [], halo: ["", "", ""], lines: "", faint: "", bold: "", fills: ["", "", ""], spots: [] }
        if (!root.drawn) return out
        const k = root.k, ox = root.ox, oy = root.oy, inset = root.inset
        const px = p => `${ox + p[0] * k} ${oy + p[1] * k}`
        let last = ""
        for (const part of root.spec.parts) {
            const own = String(part.g ?? "")
            const g = root.owner(own || (part.faint ? "" : last))
            if (own) last = own
            let d = "", outer = "", box = Qt.rect(0, 0, 0, 0), radius = 0
            if (part.k === "box") {
                const x = ox + part.x * k, y = oy + part.y * k, w = part.w * k, h = part.h * k
                radius = part.r * Math.min(w, h) / 2
                d = outer = root.rounded(x, y, w, h, radius)
                if (part.two && Math.min(w, h) > inset * 4)
                    d += " " + root.rounded(x + inset, y + inset, w - inset * 2, h - inset * 2, Math.max(0, radius - inset))
                box = Qt.rect(x, y, w, h)
            } else if (part.k === "circle" || part.k === "arc") {
                const r = part.d * k / 2, cx = ox + part.cx * k, cy = oy + part.cy * k
                if (part.k === "circle") {
                    d = outer = root.ring(cx, cy, r)
                    if (part.two && r > inset * 2) d += " " + root.ring(cx, cy, r - inset)
                } else {
                    const a0 = part.from * Math.PI / 180, a1 = part.to * Math.PI / 180
                    d = `M${cx + r * Math.cos(a0)} ${cy + r * Math.sin(a0)} A${r} ${r} 0 ${part.to - part.from > 180 ? 1 : 0} 1 `
                        + `${cx + r * Math.cos(a1)} ${cy + r * Math.sin(a1)}`
                }
                box = Qt.rect(cx - r, cy - r, r * 2, r * 2)
                radius = r
            } else {
                const pts = part.pts
                d = outer = "M" + px(pts[0]) + (part.k === "curve" ? " C" + pts.slice(1).map(px).join(" ")
                    : pts.slice(1).map(p => " L" + px(p)).join("")) + (part.closed ? " Z" : "")
                const xs = pts.map(p => ox + p[0] * k), ys = pts.map(p => oy + p[1] * k)
                box = Qt.rect(Math.min(...xs), Math.min(...ys), Math.max(...xs) - Math.min(...xs), Math.max(...ys) - Math.min(...ys))
            }
            const across = ((box.x + box.width / 2 - ox) / k - root.reach.x) / root.reach.w
            const hue = Math.max(0, Math.min(2, Math.floor(across * 3)))
            out.parts.push({ group: g, d: d })
            if (part.faint) out.faint += " " + d
            else {
                out.halo[hue] += " " + d
                if (part.lit) out.bold += " " + d
                else out.lines += " " + d
            }
            if (part.fill && outer.length > 0) out.fills[hue] += " " + outer
            const ownGroup = root.owner(own)
            if (ownGroup.length > 0) {
                // On the part's edge, never over what it draws: a box's top right corner, a ring's shoulder.
                const at = part.pin ? Qt.point(ox + part.pin[0] * k, oy + part.pin[1] * k)
                    : part.k === "box" ? Qt.point(box.x + box.width - Math.min(radius, box.width / 2) * 0.29, box.y + Math.min(radius, box.height / 2) * 0.29)
                    : part.k === "circle" ? Qt.point(box.x + box.width / 2 + radius * 0.707, box.y + box.height / 2 - radius * 0.707)
                    : Qt.point(box.x + box.width / 2, box.y + box.height / 2)
                // A small object keeps its pins apart: one that would touch a pin before it is left off.
                if (!out.spots.some(spot => Math.hypot(spot.x - at.x, spot.y - at.y) < root.pinSize * 1.4))
                    out.spots.push({ group: ownGroup, x: at.x, y: at.y, part: box, radius: radius })
            }
        }
        return out
    }
    // The pointed group's parts, drawn again in the accent over the white.
    readonly property string pointedPath: {
        const title = pins.hovering
        if (title.length === 0) return ""
        return root.plan.parts.filter(part => part.group === title).map(part => part.d).join(" ")
    }

    component Stroke: ShapePath {
        id: band
        property color hue
        property string path
        property real weight: root.line
        property bool filled: false
        strokeColor: band.filled ? "transparent" : band.hue
        strokeWidth: band.filled ? -1 : band.weight
        fillColor: band.filled ? band.hue : "transparent"
        fillRule: ShapePath.WindingFill
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathSvg { path: band.path }
    }

    // The hues' light under the lines: the same paths, wide, blurred.
    Shape {
        id: halo
        anchors.fill: parent
        visible: false
        layer.enabled: root.drawn
        preferredRendererType: Shape.CurveRenderer
        Stroke { hue: root.hues[0]; weight: root.line * 2.5; path: root.plan.halo[0] }
        Stroke { hue: root.hues[1]; weight: root.line * 2.5; path: root.plan.halo[1] }
        Stroke { hue: root.hues[2]; weight: root.line * 2.5; path: root.plan.halo[2] }
    }
    MultiEffect {
        anchors.fill: halo
        visible: root.drawn
        source: halo
        blurEnabled: true
        blur: 0.8
        blurMax: 24
        opacity: PrismTheme.light ? 0.5 : 0.8
    }
    Shape {
        anchors.fill: parent
        visible: root.drawn
        preferredRendererType: Shape.CurveRenderer
        Stroke { filled: true; hue: Qt.alpha(root.hues[0], PrismTheme.light ? 0.22 : 0.26); path: root.plan.fills[0] }
        Stroke { filled: true; hue: Qt.alpha(root.hues[1], PrismTheme.light ? 0.22 : 0.26); path: root.plan.fills[1] }
        Stroke { filled: true; hue: Qt.alpha(root.hues[2], PrismTheme.light ? 0.22 : 0.26); path: root.plan.fills[2] }
        Stroke { hue: Qt.alpha(root.core, 0.38); path: root.plan.faint }
        Stroke { hue: root.core; path: root.plan.lines }
        Stroke { hue: root.core; weight: root.line * 1.8; path: root.plan.bold }
        Stroke { hue: PrismTheme.accent; weight: root.line * 1.8; path: root.pointedPath }
    }

    PrismSpots {
        id: pins
        property string hovering: ""
        anchors.fill: parent
        visible: root.drawn
        scrim: false
        pin: root.pinSize
        radius: 0
        spots: root.plan.spots
        groups: root.groups
        pointed: pins.hovering
        sayOf: title => PrismModel.glanceOf(root.groups.find(group => String(group.title) === title)).say
        onPoint: title => pins.hovering = title
        onPick: title => { if (title.length > 0) root.goGroup(title) }
    }
}
