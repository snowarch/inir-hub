pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.style
import qs.modules.iris.frame
import qs.modules.iris.preview
import qs.modules.iris.preview.parts

PreviewScene {
    id: edgeRoot
    // The Island as it stands on this screen, at its own size: its edge, layout, notch, clock, room and bubbles are
    // the ones the rows set, read from the Island itself. A drawn stand-in kept a fixed clock and empty bubbles while
    // the rows changed them (his 10-30: "no coordinan con lo que se cambia").
    readonly property real naturalWidth: Math.round(640 * edgeRoot.d)
    readonly property real naturalHeight: Math.round(320 * edgeRoot.d)
    narrowest: Math.round(200 * edgeRoot.d)
    lowest: Math.round(110 * edgeRoot.d)
    // Along a top or bottom edge the Island and what hangs under it fill a band; down a side it needs the height.
    cardHeight: edgeRoot.edge === "left" || edgeRoot.edge === "right" ? 0 : Math.round(170 * edgeRoot.d)
    readonly property string edge: IrisFrame.islandEdge
    readonly property string layout: String(edgeRoot.opt("iris.bar.layout", "island"))
    readonly property bool spans: edgeRoot.layout === "full" || (edgeRoot.layout === "menubar" && edgeRoot.edge !== "left" && edgeRoot.edge !== "right")
    readonly property bool notch: edgeRoot.opt("iris.bar.notch", false)
    subject: {
        const g = screen.island, v = screen.view, k = screen.s
        return Qt.rect((g.x - v.x) * k, (g.y - v.y) * k, g.width * k, g.height * k)
    }
    // The Island's parts, off its inner side: its face (the middle), its shape (the round ends), where it meets the
    // edge (notch) and the edge it stands on (layout). Bubbles beside it push the ends' numbers out past them.
    spots: {
        const g = screen.island, v = screen.view, k = screen.s, d = edgeRoot.d
        if (!g || !(g.width > 0)) return []
        const w = edgeRoot.width, h = edgeRoot.height, edge = edgeRoot.edge
        const vertical = edge === "left" || edge === "right"
        const at = r => Qt.rect((r.x - v.x) * k, (r.y - v.y) * k, r.width * k, r.height * k)
        const isle = at(g)
        let x0 = isle.x, y0 = isle.y, x1 = isle.x + isle.width, y1 = isle.y + isle.height
        for (const one of screen.satellites) {
            const b = at(one)
            x0 = Math.min(x0, b.x); y0 = Math.min(y0, b.y); x1 = Math.max(x1, b.x + b.width); y1 = Math.max(y1, b.y + b.height)
        }
        const off = Math.round(22 * d), keep = Math.round(16 * d)
        const cx = x => Math.max(keep, Math.min(w - keep, x)), cy = y => Math.max(keep, Math.min(h - keep, y))
        const r = Math.min(isle.width, isle.height) / 2
        const midX = isle.x + isle.width / 2, midY = isle.y + isle.height / 2
        const inX = edge === "left" ? 1 : edge === "right" ? -1 : 0, inY = edge === "top" ? 1 : edge === "bottom" ? -1 : 0
        const face = vertical ? Qt.rect(isle.x, isle.y + r, isle.width, Math.max(0, isle.height - 2 * r))
            : Qt.rect(isle.x + r, isle.y, Math.max(0, isle.width - 2 * r), isle.height)
        const pad = Math.round(6 * d)
        const notch = edge === "top" ? Qt.rect(isle.x - r, 0, isle.width + 2 * r, isle.y + isle.height)
            : edge === "bottom" ? Qt.rect(isle.x - r, isle.y, isle.width + 2 * r, h - isle.y)
            : edge === "left" ? Qt.rect(0, isle.y - r, isle.x + isle.width, isle.height + 2 * r)
            : Qt.rect(isle.x, isle.y - r, w - isle.x, isle.height + 2 * r)
        const band = edge === "top" ? Qt.rect(0, 0, w, isle.y + isle.height + pad)
            : edge === "bottom" ? Qt.rect(0, isle.y - pad, w, h - isle.y + pad)
            : edge === "left" ? Qt.rect(0, 0, isle.x + isle.width + pad, h) : Qt.rect(isle.x - pad, 0, w - isle.x + pad, h)
        // The edge's number at its end away from the Island.
        const farEnd = vertical ? (midY < h / 2 ? h - off * 2 : off * 2) : (midX < w / 2 ? w - off * 2 : off * 2)
        return [
            { group: "Face", x: cx(midX + inX * (isle.width / 2 + off)), y: cy(midY + inY * (isle.height / 2 + off)), part: face, radius: r * 0.6 },
            { group: "Shape", x: vertical ? cx(midX) : cx(x1 + off), y: vertical ? cy(y1 + off) : cy(midY), part: isle, radius: r },
            { group: "Notch", x: vertical ? cx(midX) : cx(x0 - off), y: vertical ? cy(y0 - off) : cy(midY), part: notch, radius: r },
            // Across the whole edge the Island's ends are the edge's: the edge's number goes inside, a quarter along.
            edgeRoot.spans ? { group: "Layout", x: vertical ? cx(midX + inX * (isle.width / 2 + off)) : cx(w * 0.25), y: vertical ? cy(h * 0.25) : cy(midY + inY * (isle.height / 2 + off)), part: band, radius: 0 }
                : { group: "Layout", x: vertical ? cx(midX) : farEnd, y: vertical ? farEnd : cy(midY), part: band, radius: 0 }
        ]
    }
    IrisScreenPreview {
        id: screen
        anchors.fill: parent
        radius: 0
        outlined: false
        // At its own size, as every other scene: scaled past 1 the clock and glyphs are bitmaps blown up (his 10-30: blurry).
        maxScale: 1
        focusRect: screen.islandReach
        notices: true
    }
    Caption {
        anchors.leftMargin: Math.round((edgeRoot.edge === "left" ? edgeRoot.subject.x + edgeRoot.subject.width : 0) + 14 * edgeRoot.d)
        glyph: ({ top: "vertical_align_top", bottom: "vertical_align_bottom", left: "align_horizontal_left", right: "align_horizontal_right" })[edgeRoot.edge] ?? "pill"
        text: Translation.tr(({ top: "Top edge", bottom: "Bottom edge", left: "Left edge", right: "Right edge" })[edgeRoot.edge] ?? "")
            + " · " + (edgeRoot.layout === "menubar" ? Translation.tr("a menu bar with a notch") : edgeRoot.spans ? Translation.tr("a shelf across it") : edgeRoot.notch ? Translation.tr("melts into it") : Translation.tr("floats off it"))
    }
}
