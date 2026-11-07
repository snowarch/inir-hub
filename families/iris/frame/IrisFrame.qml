pragma Singleton

import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.iris.style
import qs.services

QtObject {
    id: root

    readonly property var bar: Config.options?.iris?.bar ?? ({})
    readonly property var dock: Config.options?.iris?.dock ?? ({})
    readonly property var surround: Config.options?.iris?.surround ?? ({})
    readonly property real d: IrisStyle.density

    // Bodies of Places that meet the frame, keyed by owner ({ screen, shapes }): the chassis of that
    // output draws them in its field, so the join, the shadow and the compositor blur are the frame's own.
    property var placeBodies: ({})
    function publishPlace(key: string, screen: string, shapes: var): void {
        if (!key) return
        if (shapes.length === 0 && !root.placeBodies[key]) return
        const next = Object.assign({}, root.placeBodies)
        if (shapes.length > 0 && screen) next[key] = { screen: screen, shapes: shapes }
        else delete next[key]
        root.placeBodies = next
    }
    // Each output's chassis says whether it is drawn and seen there: its canvas not withdrawn, nothing fullscreen over it.
    property var chassisShown: ({})
    function showChassis(screen: string, shown: bool): void {
        if (!screen || Boolean(root.chassisShown[screen]) === shown) return
        const next = Object.assign({}, root.chassisShown)
        if (shown) next[screen] = true
        else delete next[screen]
        root.chassisShown = next
    }
    readonly property bool nativeRaster: SystemInfo.runtimeHas(["field-region"])
    // Places in Overlay windows of their own (Settings, side panels, menus) in the order they opened: Niri stacks a
    // later one above an earlier one.
    property var overlayPlaces: []
    function stackOverlay(key: string, screen: string, shown: bool): void {
        const at = root.overlayPlaces.findIndex(p => p.key === key)
        if (shown && screen && at >= 0 && root.overlayPlaces[at].screen === screen) return
        const rest = root.overlayPlaces.filter(p => p.key !== key)
        if (!shown && at < 0) return
        root.overlayPlaces = shown && screen ? rest.concat([{ key: key, screen: screen }]) : rest
    }
    // Such a Place hands its body to the chassis (one field, one blur) where the chassis is seen and no Overlay Place
    // opened before it is still there: that one's own body and content would sit between this body and its content.
    // `anyRuntime` aside, only on qs-rs: Quickshell walks the blur of a big moving body coarsely, its own field is exact.
    function leases(key: string, screen: string, anyRuntime: bool): bool {
        if (!key || !root.chassisShown[screen] || !(anyRuntime || root.nativeRaster)) return false
        const first = root.overlayPlaces.find(p => p.screen === screen)
        return first !== undefined && first.key === key
    }
    // What stands on each output: the lines of bubbles, the Island, the Dock, the side panels. The stage publishes it, so
    // every body that opens (a card, the Control Center, a menu) keeps off it and curves around it the same way.
    property var surfaces: ({})
    function publishSurfaces(screen: string, list: var): void {
        const next = Object.assign({}, root.surfaces)
        next[screen] = list
        root.surfaces = next
    }
    // The bodies open right now (a card, the Control Center): only what opens over them, a menu, keeps off these. They live
    // apart from `surfaces` because their own placement reads that.
    property var openBodies: ({})
    function publishOpen(key: string, screen: string, rect: var): void {
        const next = Object.assign({}, root.openBodies)
        if (rect) next[key] = Object.assign({}, rect, { screen: screen })
        else delete next[key]
        root.openBodies = next
    }
    // Less the one the opener stands on, read by the line itself (`core`), since lines run out into a corner they share.
    function besides(screen: string, origin: var, overOpen: bool): var {
        const cx = Number(origin?.x ?? 0) + Number(origin?.width ?? 0) / 2
        const cy = Number(origin?.y ?? 0) + Number(origin?.height ?? 0) / 2
        const open = overOpen ? Object.keys(root.openBodies).map(key => root.openBodies[key]).filter(b => b.screen === screen) : []
        return (root.surfaces[screen] ?? []).concat(open).filter(s => {
            const c = s.core ?? s
            return !(cx >= c.x && cx <= c.x + c.width && cy >= c.y && cy <= c.y + c.height)
        })
    }
    function placeShapesOn(screen: string): var {
        const out = []
        for (const key in root.placeBodies) {
            const entry = root.placeBodies[key]
            if (entry.screen === screen) for (const shape of entry.shapes) out.push(shape)
        }
        return out
    }
    readonly property bool musicActive: {
        Config.revision
        return root.framed && Boolean(Config.options?.background?.edgeWidgets?.organic?.enable ?? false)
            && String(root.surround?.music ?? "widget") === "frame"
    }
    function musicReach(edge: string): real {
        Config.revision
        if (!root.musicActive) return 0
        const mode = String(root.surround?.musicEdges ?? "sides")
        if (mode === "sides" && (edge === "top" || edge === "bottom")) return 0
        if (mode === "horizontal" && (edge === "left" || edge === "right")) return 0
        return 18 * root.d * Math.max(0.5, Math.min(3, Number(root.surround?.musicStrength ?? 160) / 100))
    }
    function safeInset(edge: string): real { return root.inset(edge) + root.musicReach(edge) }
    readonly property int musicAppearanceCode: ({ sculpted: 0, etched: 1, satin: 2 })[String(root.surround?.musicAppearance ?? "etched")] ?? 1
    readonly property color musicInk: {
        const colour = String(root.surround?.musicColour ?? "pearl")
        return colour === "accent" ? IrisStyle.accent
            : colour === "highlight" ? IrisStyle.secondaryAccent
            : colour === "wallpaper" ? IrisStyle.wallpaperLight : IrisStyle.text
    }
    readonly property real musicLight: Math.max(0, Math.min(1, Number(root.surround?.musicLight ?? 35) / 100))
    readonly property real musicLightWidth: Math.max(1, Math.min(18, Number(root.surround?.musicLightWidth ?? 5))) * root.d

    readonly property bool framed: Boolean(root.surround?.enable ?? false)
    // Holo: the frame's own spectral light, drawn by the field over the band's material whatever it is (glass, solid, flat).
    readonly property bool holo: root.framed && String(root.surround?.style ?? "plain") === "holo"
    readonly property real holoLight: root.holo ? Math.max(0, Math.min(1, Number(root.surround?.holoLight ?? 45) / 100)) : 0
    readonly property real holoHalo: root.holo ? Math.max(0, Math.min(1, Number(root.surround?.holoHalo ?? 40) / 100)) : 0
    // How far the rim's halo falls over the screen, like the eclipse's.
    readonly property real holoSpill: root.holo ? Math.round(64 * root.holoHalo * root.d) : 0
    readonly property real band: root.framed
        ? Math.max(1, Math.round(Number(root.surround?.thickness ?? 10) * root.d)) : 0
    readonly property real cornerRadius: root.framed
        ? Math.max(0, Math.round(Number(root.surround?.radius ?? 22) * root.d)) : 0

    readonly property var edges: ["top", "bottom", "left", "right"]
    function opposite(edge: string): string {
        return ({ top: "bottom", bottom: "top", left: "right", right: "left" })[edge] ?? "bottom"
    }
    function vertical(edge: string): bool { return edge === "left" || edge === "right" }
    readonly property string islandEdge: root.edges.includes(String(root.bar?.position ?? "top")) ? String(root.bar.position) : "top"
    // The rail (`iris.surround.rail`): the frame grows wide on one side and the Dock lives in it, top to bottom, like a
    // browser's sidebar (.claude/ref/iris-frame). Never on the Island's own edge.
    readonly property string railEdge: {
        const wanted = String(root.surround?.rail ?? "none")
        return root.framed && (root.dock?.enable ?? true) && (wanted === "left" || wanted === "right")
            && wanted !== root.islandEdge ? wanted : ""
    }
    readonly property bool rail: root.railEdge.length > 0
    // The rail meets the frame's top and bottom lines in a fillet as round as the frame's own corners.
    readonly property real railFuse: Math.round(root.cornerRadius * 4 * (1 - Math.SQRT1_2))
    // The frame's own wall on a side: its band, and on the rail's side the rail too. What rests in a corner beside the
    // rail (a line of bubbles, a card) keeps off it as it keeps off the band.
    function wallOn(side: string): real { return root.band + (root.rail && side === root.railEdge ? root.dockBand : 0) }
    readonly property string dockEdge: {
        if (root.rail) return root.railEdge
        const wanted = String(root.dock?.position ?? "auto")
        return root.edges.includes(wanted) && wanted !== root.islandEdge ? wanted : root.opposite(root.islandEdge)
    }
    readonly property string wantedIsland: String(root.bar?.position ?? "top")
    readonly property string wantedDock: String(root.dock?.position ?? "auto")
    property string settledIsland: ""
    property string settledDock: ""
    Component.onCompleted: { root.settledIsland = root.islandEdge; root.settledDock = root.dockEdge }
    onWantedIslandChanged: {
        if (root.edges.includes(root.wantedIsland) && root.wantedIsland === root.wantedDock
                && root.settledIsland.length > 0 && root.settledIsland !== root.wantedIsland)
            Config.setNestedValue("iris.dock.position", root.settledIsland)
        root.settle()
    }
    onWantedDockChanged: {
        if (root.edges.includes(root.wantedDock) && root.wantedDock === root.islandEdge
                && root.settledDock.length > 0 && root.settledDock !== root.wantedDock)
            Config.setNestedValue("iris.bar.position", root.settledDock)
        root.settle()
    }
    function settle(): void {
        Qt.callLater(() => { root.settledIsland = root.islandEdge; root.settledDock = root.dockEdge })
    }
    readonly property bool notch: Boolean(root.bar?.notch ?? false)
    readonly property real islandFullBand: Math.max(32, Math.round(Number(root.bar?.height ?? 42) * root.d))
    // A menu bar gives windows back all but its strip: the notch hangs over them.
    readonly property bool islandMenubar: String(root.bar?.layout ?? "island") === "menubar" && !root.vertical(root.islandEdge)
    readonly property real islandBand: root.islandMenubar
        ? Math.max(Math.round(24 * root.d), Math.round(root.islandFullBand * 0.72)) : root.islandFullBand
    readonly property real islandMargin: root.notch ? 0 : Math.max(0, Math.round(Number(root.bar?.margin ?? 8) * root.d))
    readonly property bool islandAutoHide: Boolean(root.bar?.autoHide ?? false)
    readonly property real islandVisualDepth: root.islandAutoHide ? 0 : root.islandBand + root.islandMargin
    readonly property real islandDepth: (root.bar?.reserveSpace ?? true) && !root.islandAutoHide
        ? root.islandVisualDepth : 0
    // The rail keeps its own size (iris.surround.railSize): a sidebar reads slimmer than a Dock.
    readonly property real railIcon: Math.max(22, Math.min(54, Number(root.surround?.railSize ?? 46) - 18)) * root.d
    readonly property real dockIcon: root.rail ? root.railIcon
        : Math.max(28, Math.min(64, Number(root.dock?.iconSize ?? 40))) * root.d
    readonly property real dockBand: root.dockIcon + 18 * root.d
    readonly property real dockMargin: root.rail || Boolean(root.dock?.notch ?? false) ? 0 : 10 * root.d
    readonly property real dockVisualDepth: root.rail ? root.dockBand
        : (root.dock?.enable ?? true) && !(root.dock?.autoHide ?? false) ? root.dockBand + root.dockMargin : 0
    readonly property real dockDepth: root.rail ? root.dockBand
        : (root.dock?.enable ?? true) && (root.dock?.reserveSpace ?? true) && !(root.dock?.autoHide ?? false)
        ? root.dockVisualDepth : 0
    // What an auto-hidden Island or Dock still shows on a workspace with no windows (revealOnEmpty).
    function emptyDepth(edge: string): real {
        let depth = 0
        if (edge === root.islandEdge && root.islandAutoHide && (root.bar?.revealOnEmpty ?? true))
            depth = root.islandBand + root.islandMargin
        if (edge === root.dockEdge && !root.rail && (root.dock?.enable ?? true) && (root.dock?.autoHide ?? false)
                && (root.dock?.revealOnEmpty ?? true))
            depth = Math.max(depth, root.dockBand + root.dockMargin)
        return depth
    }

    readonly property var bubbles: Config.options?.iris?.bubbles ?? ({})
    readonly property bool piecesAttached: root.bubbles?.attach ?? true
    readonly property bool piecesReserve: root.piecesAttached && (root.bubbles?.reserve ?? true)
    readonly property string pieceJoin: root.piecesAttached ? String(root.bubbles?.join ?? "notch") : "float"
    readonly property bool piecesMelt: root.pieceJoin === "notch" || root.pieceJoin === "weld"
    readonly property real pieceGap: root.pieceJoin === "gap" ? Math.max(root.islandMargin, Math.round(8 * root.d)) : 0
    readonly property real pieceInset: root.band + root.pieceGap
    readonly property real pieceScale: Math.max(0.6, Math.min(1.4, Number(root.bubbles?.scale ?? 100) / 100))
    readonly property real pieceBand: Math.round(root.islandBand * root.pieceScale)
    readonly property real pieceDepth: root.pieceGap + root.pieceBand
    // How pieces meet a given edge. On the Island's own edge they meet it the way the Island does: melted with it,
    // or floating at its margin when it floats (two grammars on one edge read as parts from different kits). A corner
    // plate takes its edge's join on both walls (IrisStage.zones): floating, it keeps that margin from the frame's side
    // too, never floating off one wall and welded to the other.
    readonly property bool islandSpans: ["full", "pods"].includes(String(root.bar?.layout ?? "island")) || root.islandMenubar
    function joinOn(side: string): string {
        if (!root.piecesAttached) return "float"
        if (side === root.islandEdge && !root.notch && !root.islandSpans && root.pieceJoin !== "gap") return "gap"
        return root.pieceJoin
    }
    function meltsOn(side: string): bool { const join = root.joinOn(side); return join === "notch" || join === "weld" }
    function pieceGapOn(side: string): real {
        return root.joinOn(side) === "gap" ? Math.max(root.islandMargin, Math.round(Number(root.bar?.margin ?? 8) * root.d), Math.round(8 * root.d)) : 0
    }
    function pieceInsetOn(side: string): real { return root.wallOn(side) + root.pieceGapOn(side) }
    function pieceDepthOn(side: string): real { return root.pieceGapOn(side) + root.pieceBand }
    // An announcement is never switched on: like Material's bar indicator it shows whenever its state is there.
    readonly property var announcements: ["shellUpdate"]
    property var availableExtras: null
    function extraOn(extras: var, id: string): bool {
        return root.announcements.includes(id) || Boolean(extras?.[id]?.enable ?? false)
    }
    function edgeOf(place: string): string {
        if (place.startsWith("edge:")) return ["top", "bottom", "left", "right"].includes(place.slice(5)) ? place.slice(5) : ""
        if (place === "top-left" || place === "top-right") return "top"
        if (place === "bottom-left" || place === "bottom-right") return "bottom"
        if (place === "left" || place === "right") return place
        if (place === "left-top" || place === "left-bottom") return "left"
        if (place === "right-top" || place === "right-bottom") return "right"
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
        // A piece that has nothing to show (no update, no player, an empty tray) is not on its edge: the edge
        // reserves nothing for it. IrisPieces feeds availableExtras (it imports this singleton, not the other way).
        for (const id of Object.keys(extras))
            if (root.extraOn(extras, id) && (root.availableExtras === null || root.availableExtras.includes(id))) note(extras[id]?.place)
        for (const app of (o?.apps ?? [])) if (app) note(app?.place)
        return edges
    }


    readonly property var theme: Config.options?.iris?.appearance?.theme ?? ({})
    readonly property real bodyAir: Math.round(Math.max(0, Math.min(40, Number(root.theme?.air ?? 8))) * root.d)
    readonly property real bodyMargin: Math.round(8 * root.d)
    readonly property string placementMode: String(root.theme?.placement ?? "auto")

    function place(origin: var, width: real, height: real, screenWidth: real, screenHeight: real, radius: real, avoid: var, air: real): var {
        if (!origin) return { sideways: false, towardsLeft: false, towardsUp: false, x: (screenWidth - width) / 2, y: (screenHeight - height) / 2 }
        const ob = origin.obstacle ?? origin
        const cx = origin.x + origin.width / 2
        const cy = origin.y + origin.height / 2
        // The theme's air from the frame's inner edge on every side (past the music it carries), `air` from what opened
        // the body (negative welds it on). A piece on an edge is drawn as a strip deeper than the item it sits in, so
        // the body keeps its air from that strip, not the item: on a thin edge the item alone left it pressed under the piece.
        const wall = side => root.wallOn(side) + root.musicReach(side)
        let left = wall("left") + root.bodyAir
        let right = screenWidth - width - wall("right") - root.bodyAir
        let top = wall("top") + root.bodyAir
        let bottom = screenHeight - height - wall("bottom") - root.bodyAir
        const strip = side => root.piecesAttached && root.pieceEdges.includes(side) ? root.pieceDepthOn(side) : 0
        const sitsOn = side => side === "left" ? ob.x - wall("left") <= strip("left") + 1
            : side === "right" ? screenWidth - wall("right") - ob.x - ob.width <= strip("right") + 1
            : side === "top" ? ob.y - wall("top") <= strip("top") + 1
            : screenHeight - wall("bottom") - ob.y - ob.height <= strip("bottom") + 1
        const reach = side => sitsOn(side) ? wall(side) + strip(side) : 0
        const near = {
            left: Math.max(ob.x + ob.width, reach("left")), right: Math.min(ob.x, reach("right") > 0 ? screenWidth - reach("right") : ob.x),
            top: Math.max(ob.y + ob.height, reach("top")), bottom: Math.min(ob.y, reach("bottom") > 0 ? screenHeight - reach("bottom") : ob.y)
        }
        for (const b of (avoid ?? [])) {
            if (!b || b.width <= 0 || b.height <= 0) continue
            const fullHeight = b.y <= root.bodyMargin + 1
                && b.y + b.height >= screenHeight - root.bodyMargin - 1
            if (fullHeight) {
                if (b.x + b.width <= screenWidth / 2) left = Math.max(left, b.x + b.width + root.bodyAir)
                else if (b.x >= screenWidth / 2) right = Math.min(right, b.x - width - root.bodyAir)
            }
            const fullWidth = b.x <= root.bodyMargin + 1
                && b.x + b.width >= screenWidth - root.bodyMargin - 1
            if (fullWidth) {
                if (b.y + b.height <= screenHeight / 2) top = Math.max(top, b.y + b.height + root.bodyAir)
                else if (b.y >= screenHeight / 2) bottom = Math.min(bottom, b.y - height - root.bodyAir)
            }
        }
        if (right < left) right = left
        if (bottom < top) bottom = top
        const nearSide = Math.min(cx, screenWidth - cx) < Math.min(cy, screenHeight - cy) - Math.min(origin.width, origin.height)
        const sideways = root.placementMode === "along" ? !nearSide : nearSide
        const towardsLeft = screenWidth - cx < cx
        const towardsUp = screenHeight - cy < cy
        const straight = Math.min(origin.width, origin.height) / 2 + radius
        const clamp = (value, low, high) => Math.max(low, Math.min(high, value))
        const along = (centre, size, low, high) => {
            const wanted = Math.max(low, Math.min(high, centre - size / 2))
            return Math.max(centre + straight - size, Math.min(centre - straight, wanted))
        }
        const candidate = side => {
            if (side) {
                const rawX = towardsLeft ? near.right - width - air : near.left + air
                return { sideways: true, towardsLeft: towardsLeft, towardsUp: towardsUp,
                    x: clamp(rawX, left, right), y: clamp(along(cy, height, top, bottom), top, bottom) }
            }
            const rawY = towardsUp ? near.bottom - height - air : near.top + air
            return { sideways: false, towardsLeft: towardsLeft, towardsUp: towardsUp,
                x: clamp(along(cx, width, left, right), left, right), y: clamp(rawY, top, bottom) }
        }
        const overlap = (a, b) => Math.max(0, Math.min(a.x + width, b.x + b.width) - Math.max(a.x, b.x))
            * Math.max(0, Math.min(a.y + height, b.y + b.height) - Math.max(a.y, b.y))
        const score = a => {
            let sum = 0
            for (const b of (avoid ?? [])) if (b && b.width > 0 && b.height > 0) sum += overlap(a, b)
            return sum
        }
        // Landing on something: slide along the opener, which keeps the two side by side, and only then step away from it.
        const fits = a => a.x >= left - 0.5 && a.x <= right + 0.5 && a.y >= top - 0.5 && a.y <= bottom + 0.5
        const clear = a => {
            let at = a
            for (let pass = 0; pass < 6; pass++) {
                const b = (avoid ?? []).find(o => o && o.width > 0 && o.height > 0 && overlap(at, o) > 0)
                if (!b) break
                const ys = [{ y: b.y + b.height + root.bodyAir }, { y: b.y - height - root.bodyAir }]
                const xs = [{ x: b.x + b.width + root.bodyAir }, { x: b.x - width - root.bodyAir }]
                let next = null
                for (const moves of at.sideways ? [ys, xs] : [xs, ys]) {
                    const reachable = moves.map(move => Object.assign({}, at, move)).filter(fits)
                        .sort((p, q) => Math.hypot(p.x - at.x, p.y - at.y) - Math.hypot(q.x - at.x, q.y - at.y))
                    if (reachable.length > 0) { next = reachable[0]; break }
                }
                if (!next) break
                at = next
            }
            return at
        }
        const primary = clear(candidate(sideways))
        const alternate = clear(candidate(!sideways))
        if (score(alternate) + 1 < score(primary)) return alternate
        if (primary.sideways) {
            return { sideways: true, towardsLeft: towardsLeft, towardsUp: towardsUp,
                x: primary.x, y: primary.y }
        }
        return { sideways: false, towardsLeft: towardsLeft, towardsUp: towardsUp,
            x: primary.x, y: primary.y }
    }

    // A body's four radii: its `radius` wherever its `corners` ({ tl, tr, bl, br }) leave one out, as a Rectangle reads its
    // own. The field, its blur twins and the morph's clip all read a body's corners through this.
    function cornersOf(body: var): var {
        const r = Number(body?.radius ?? 0), c = body?.corners
        return c ? { tl: Number(c.tl ?? r), tr: Number(c.tr ?? r), bl: Number(c.bl ?? r), br: Number(c.br ?? r) }
            : { tl: r, tr: r, bl: r, br: r }
    }
    // The fillet a body melted into a wall draws there: the field's polynomial smooth union of two perpendicular edges
    // bulges k/4 along the diagonal, which is a circular fillet of radius k / (4·(1 − 1/√2)).
    function filletRadius(fuse: real): real { return fuse / (4 * (1 - Math.SQRT1_2)) }
    // How each corner of a body near the frame nests ({ tl, tr, bl, br }): the corner that faces the frame's own corner, or
    // the fillet of what stands on the wall beside it (its opener or any surface in `beside`), takes that curve less the air
    // between them; the others keep `radius`.
    function nestRadius(rect: var, radius: real, origin: var, originFuse: real, screenWidth: real, screenHeight: real, beside: var): var {
        const own = { tl: radius, tr: radius, bl: radius, br: radius }
        if (!rect || rect.width <= 0 || rect.height <= 0) return own
        const reach = Math.max(root.bodyAir, root.bodyMargin) + 2 * root.d
        const floor = Math.round(6 * root.d)
        const gap = { left: rect.x - root.band, right: screenWidth - root.band - rect.x - rect.width,
            top: rect.y - root.band, bottom: screenHeight - root.band - rect.y - rect.height }
        const stands = [origin?.obstacle ?? origin].concat(beside ?? []).filter(s => !!s)
        const touches = (r, wall) => r && (wall === "left" ? r.x - root.band
            : wall === "right" ? screenWidth - root.band - r.x - r.width
            : wall === "top" ? r.y - root.band : screenHeight - root.band - r.y - r.height) <= 1.5
        const nests = { tl: [], tr: [], bl: [], br: [] }
        const corner = (end, side) => nests[(end === "top" ? "t" : "b") + (side === "left" ? "l" : "r")]
        for (const side of ["left", "right"]) {
            for (const end of ["top", "bottom"]) {
                if (gap[side] > reach) continue
                if (root.framed && gap[end] <= reach) {
                    corner(end, side).push(root.cornerRadius - (gap[side] + gap[end]) / 2)
                    continue
                }
                for (const o of stands) {
                    if (!touches(o, side) || o.width <= 0) continue
                    const between = end === "top" ? rect.y - (o.y + o.height) : o.y - (rect.y + rect.height)
                    if (between >= -1 && between <= reach)
                        corner(end, side).push(root.filletRadius(o.fuse ?? originFuse) - (gap[side] + between) / 2)
                }
            }
        }
        for (const end of ["top", "bottom"]) {
            for (const side of ["left", "right"]) {
                if (gap[end] > reach) continue
                for (const o of stands) {
                    if (!touches(o, end) || o.height <= 0) continue
                    const between = side === "left" ? rect.x - (o.x + o.width) : o.x - (rect.x + rect.width)
                    if (between >= -1 && between <= reach)
                        corner(end, side).push(root.filletRadius(o.fuse ?? originFuse) - (gap[end] + between) / 2)
                }
            }
        }
        // In the elbow of two lines that meet in a corner: the fillet they make, whichever walls they stand on.
        const onRow = o => o.x < rect.x + rect.width + reach && o.x + o.width > rect.x - reach
        const onColumn = o => o.y < rect.y + rect.height + reach && o.y + o.height > rect.y - reach
        for (const end of ["top", "bottom"]) {
            for (const side of ["left", "right"]) {
                const across = o => end === "top" ? rect.y - (o.y + o.height) : o.y - (rect.y + rect.height)
                const along = o => side === "left" ? rect.x - (o.x + o.width) : o.x - (rect.x + rect.width)
                const row = stands.find(o => onRow(o) && across(o) >= -1 && across(o) <= reach)
                const column = stands.find(o => onColumn(o) && along(o) >= -1 && along(o) <= reach)
                if (row && column && row !== column)
                    corner(end, side).push(root.filletRadius(row.fuse ?? originFuse) - (across(row) + along(column)) / 2)
            }
        }
        // Or nothing: a corner much tighter than the body would square a sheet off to the floor; it keeps its own radius and floats.
        const settle = list => {
            if (list.length === 0) return radius
            const nested = Math.min(...list)
            if (nested < Math.max(floor * 2, radius * 0.4)) return radius
            return Math.round(Math.min(Math.min(rect.width, rect.height) / 2, nested))
        }
        return { tl: settle(nests.tl), tr: settle(nests.tr), bl: settle(nests.bl), br: settle(nests.br) }
    }

    function reserve(edge: string, chassisPresent: bool): real {
        let inner = 0
        if (chassisPresent && edge === root.islandEdge) inner = Math.max(inner, root.islandDepth)
        if (chassisPresent && root.piecesReserve && root.pieceEdges.includes(edge))
            inner = Math.max(inner, root.pieceDepthOn(edge))
        if (edge === root.dockEdge) inner = Math.max(inner, root.dockDepth)
        return Math.round(root.band + inner)
    }
    function inset(edge: string): real {
        let inner = 0
        if (edge === root.islandEdge) inner = Math.max(inner, root.islandVisualDepth)
        if (root.piecesAttached && root.pieceEdges.includes(edge))
            inner = Math.max(inner, root.pieceDepthOn(edge))
        if (edge === root.dockEdge) inner = Math.max(inner, root.dockVisualDepth)
        return Math.round(root.band + inner)
    }
}
