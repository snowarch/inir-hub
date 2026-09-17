pragma Singleton

import QtQuick
import qs.modules.common
import qs.modules.iris.style

QtObject {
    id: root

    readonly property var bar: Config.options?.iris?.bar ?? ({})
    readonly property var dock: Config.options?.iris?.dock ?? ({})
    readonly property var surround: Config.options?.iris?.surround ?? ({})
    readonly property real d: IrisStyle.density

    readonly property bool framed: Boolean(root.surround?.enable ?? false)
    readonly property real band: root.framed
        ? Math.max(1, Math.round(Number(root.surround?.thickness ?? 10) * root.d)) : 0
    readonly property real cornerRadius: root.framed
        ? Math.max(0, Math.round(Number(root.surround?.radius ?? 22) * root.d)) : 0

    readonly property string islandEdge: String(root.bar?.position ?? "top") === "bottom" ? "bottom" : "top"
    readonly property string dockEdge: root.islandEdge === "top" ? "bottom" : "top"
    readonly property bool notch: Boolean(root.bar?.notch ?? false)
    readonly property real islandBand: Math.max(32, Math.round(Number(root.bar?.height ?? 42) * root.d))
    readonly property real islandMargin: root.notch ? 0 : Math.max(0, Math.round(Number(root.bar?.margin ?? 8) * root.d))
    readonly property real islandDepth: (root.bar?.reserveSpace ?? true)
        ? root.islandBand + root.islandMargin * 2 : 0
    readonly property real dockIcon: Math.max(28, Math.min(64, Number(root.dock?.iconSize ?? 40))) * root.d
    readonly property real dockBand: root.dockIcon + 18 * root.d
    readonly property real dockMargin: root.notch ? 0 : 10 * root.d
    readonly property real dockDepth: (root.dock?.autoHide ?? false) ? 0 : root.dockBand + root.dockMargin * 2

    readonly property var bubbles: Config.options?.iris?.bubbles ?? ({})
    readonly property bool piecesAttached: root.bubbles?.attach ?? true
    readonly property bool piecesReserve: root.piecesAttached && (root.bubbles?.reserve ?? true)
    readonly property real pieceInset: root.band + root.islandMargin
    function edgeOf(place: string): string {
        if (place === "top-left" || place === "top-right") return "top"
        if (place === "bottom-left" || place === "bottom-right") return "bottom"
        if (place === "left" || place === "right") return place
        return ""
    }
    readonly property var pieceEdges: {
        const o = root.bubbles
        const edges = []
        const note = place => {
            const edge = root.edgeOf(String(place ?? ""))
            if (edge.length > 0 && !edges.includes(edge)) edges.push(edge)
        }
        for (const id of ["left", "right", "utility"]) note(o?.[id]?.place ?? "island")
        const extras = o?.extras ?? ({})
        for (const id of Object.keys(extras)) if (extras[id]?.enable) note(extras[id]?.place)
        for (const app of (o?.apps ?? [])) if (app) note(app?.place)
        return edges
    }

    function clear(edge: string): real {
        let depth = root.band
        if (root.piecesAttached && root.pieceEdges.includes(edge))
            depth = Math.max(depth, root.pieceInset + root.islandBand)
        return Math.round(depth)
    }

    readonly property var theme: Config.options?.iris?.appearance?.theme ?? ({})
    readonly property real bodyAir: Math.round(Math.max(0, Math.min(40, Number(root.theme?.air ?? 8))) * root.d)
    readonly property real bodyMargin: Math.round(8 * root.d)
    readonly property real neckShare: Math.max(0.2, Math.min(1, Number(root.theme?.neck ?? 62) / 100))
    readonly property string placementMode: String(root.theme?.placement ?? "auto")

    function place(origin: var, width: real, height: real, screenWidth: real, screenHeight: real, radius: real): var {
        const ob = origin.obstacle ?? origin
        const cx = origin.x + origin.width / 2
        const cy = origin.y + origin.height / 2
        const left = root.bodyMargin + root.clear("left")
        const right = screenWidth - width - root.bodyMargin - root.clear("right")
        const top = root.bodyMargin + root.clear("top")
        const bottom = screenHeight - height - root.bodyMargin - root.clear("bottom")
        const nearSide = Math.min(cx, screenWidth - cx) < Math.min(cy, screenHeight - cy) - Math.min(origin.width, origin.height)
        const sideways = root.placementMode === "along" ? !nearSide : nearSide
        const towardsLeft = screenWidth - cx < cx
        const towardsUp = screenHeight - cy < cy
        const neck = Math.min(origin.width, origin.height) * root.neckShare
        const straight = neck / 2 + radius
        const along = (centre, size, low, high) => {
            const wanted = Math.max(low, Math.min(high, centre - size / 2))
            return Math.max(centre + straight - size, Math.min(centre - straight, wanted))
        }
        if (sideways) {
            return { sideways: true, towardsLeft: towardsLeft, towardsUp: towardsUp,
                x: towardsLeft ? Math.max(left, ob.x - width - root.bodyAir) : Math.min(right, ob.x + ob.width + root.bodyAir),
                y: along(cy, height, top, bottom) }
        }
        return { sideways: false, towardsLeft: towardsLeft, towardsUp: towardsUp,
            x: along(cx, width, left, right),
            y: towardsUp ? Math.max(top, ob.y - height - root.bodyAir) : Math.min(bottom, ob.y + ob.height + root.bodyAir) }
    }

    function neck(origin: var, placement: var, body: var, progress: real): var {
        const ob = origin.obstacle ?? origin
        const cross = Math.round(Math.min(origin.width, origin.height) * root.neckShare * Math.min(1, progress))
        if (cross < 2 || body.width <= 1 || body.height <= 1) return null
        const reach = IrisStyle.weld
        if (placement.sideways) {
            const x0 = placement.towardsLeft ? body.x + body.width - reach : ob.x + ob.width - reach
            const x1 = placement.towardsLeft ? ob.x + reach : body.x + reach
            if (x1 <= x0) return null
            return { x: x0, y: origin.y + origin.height / 2 - cross / 2, width: x1 - x0, height: cross }
        }
        const y0 = placement.towardsUp ? body.y + body.height - reach : ob.y + ob.height - reach
        const y1 = placement.towardsUp ? ob.y + reach : body.y + reach
        if (y1 <= y0) return null
        return { x: origin.x + origin.width / 2 - cross / 2, y: y0, width: cross, height: y1 - y0 }
    }
    readonly property int neckFuse: Math.max(8, Math.round(3 * root.bodyAir))

    function reserve(edge: string): real {
        let inner = 0
        if (edge === root.islandEdge) inner = Math.max(inner, root.islandDepth)
        if (root.piecesReserve && root.pieceEdges.includes(edge)) inner = Math.max(inner, root.islandDepth)
        return Math.round(root.band + inner)
    }
    function inset(edge: string): real {
        let depth = root.band
        if (edge === root.islandEdge) depth += root.islandDepth
        if (edge === root.dockEdge) depth += root.dockDepth
        return Math.round(depth)
    }
}
