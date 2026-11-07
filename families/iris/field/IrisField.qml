pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.frame

Item {
    id: root

    property var shapes: []
    property color tint: IrisStyle.bodySurface
    property color rim: IrisStyle.rim
    property real rimWidth: IrisStyle.edgeWidth
    property color sheen: IrisStyle.glassEdgeColour
    property real smoothing: IrisStyle.fuse
    property bool framed: IrisFrame.framed
    // Drawn under a transform (the edit card, the arrival): the cached field is sampled smoothly, and at `renderScale`
    // it is rendered at the size it is shown, so the card's resting picture lands texel on pixel instead of stepping.
    property real renderScale: 1
    property bool resampled: false
    property real band: IrisFrame.band
    property real cornerRadius: IrisFrame.cornerRadius
    readonly property int capacity: 20
    // The bodies' shadow is drawn by the pass itself, from the joined silhouette (IrisField.frag `shade`).
    readonly property real shadowFall: Math.round(3 * IrisStyle.density)
    readonly property real shadowBlur: Math.round(16 * IrisStyle.density)
    readonly property bool casts: IrisStyle.shadow.a > 0.004
    readonly property real reach: root.smoothing + 2 + IrisStyle.afterglowReach + IrisStyle.leakReach + IrisStyle.streakReach
        + (root.casts ? root.shadowFall + 1.5 * root.shadowBlur : 0)
    property bool compositorAllowed: false
    // A field that does not cover its output: its window's position on the output and the output's size.
    property point sceneOrigin: Qt.point(0, 0)
    property size sceneSize: Qt.size(0, 0)
    readonly property int glassCode: IrisStyle.glassCompositor ? (root.compositorAllowed ? 2 : 1) : IrisStyle.glassWallpaper ? 1 : 0
    // The music frame stays the compositor's glass: what the swell adds is blurred by strips below the chassis
    // (IrisWaveBlur), so the moving band is one material with the resting one.
    property int frameGlass: root.glassCode
    property vector4d edgeWave: Qt.vector4d(0, 0, 0, 0)
    property real waveClock: 0
    property real frameMusicLevel: 0
    property int frameMusicAppearance: IrisFrame.musicAppearanceCode
    property color frameMusicInk: IrisFrame.musicInk
    property real frameMusicLight: IrisFrame.musicLight
    property real frameMusicLightWidth: IrisFrame.musicLightWidth
    // One matter (2026-10-15, the maintainer: the Dock on the frame "se ve separado del frame" once it is glass): a
    // body welded to the frame, directly or through the bodies it hangs from, is the frame's material wherever it is
    // joined; its own material is for when it floats. A glass body on a solid band read as two things fitted together.
    function glassOf(shape: var, depth: int): int {
        if (!shape) return 0
        if (root.framed && root.weldedToFrame(shape, depth ?? 0)) return root.frameGlass
        return root.ownGlass(shape)
    }
    function weldedToFrame(shape: var, depth: int): bool {
        const list = !shape.joins ? [] : Array.isArray(shape.joins) ? shape.joins : [shape.joins]
        if (list.includes("frame")) return true
        if (depth >= 4) return false
        const all = root.shapes ?? []
        return list.some(name => { const other = all.find(candidate => candidate?.id === name); return other ? root.weldedToFrame(other, depth + 1) : false })
    }
    function ownGlass(shape: var): int {
        const g = shape.glass
        if (g === undefined || g === null || g === "inherit") return root.glassCode
        if (g === "compositor") return IrisCompositorBlur.active && root.compositorAllowed ? 2 : 1
        if (g === "wallpaper" || g === true) return 1
        return 0
    }
    // The window's chassis field lends its backdrop to every other field and pane in that window.
    property bool providesBackdrop: false
    // A picture of a screen (Settings' previews) lends its own wallpaper instead: the window's would show what is behind
    // Settings, at the wrong place and scale. Anything with ready, texture and clearTexture, covering this field's scene.
    property Item backdropOverride: null
    readonly property bool wantsBackdrop: root.visible && ((root.framed && root.frameGlass === 1)
        || (root.shapes ?? []).some(shape => root.glassOf(shape) === 1))
    readonly property Item windowHost: root.QsWindow.contentItem ?? null
    readonly property Item sharedBackdrop: root.wantsBackdrop && !root.providesBackdrop && !root.backdropOverride
        ? IrisGlassBackdrops.find(root.windowHost, null) : null
    readonly property Item backdropSource: root.backdropOverride ?? root.sharedBackdrop ?? backdropLoader.item

    Loader {
        id: backdropLoader
        active: !root.backdropOverride && ((root.providesBackdrop && root.visible && root.glassCode === 1)
            || (root.wantsBackdrop && !root.sharedBackdrop))
        sourceComponent: IrisGlassSource {
            screen: root.QsWindow.window?.screen ?? null
        }
        onItemChanged: {
            if (!root.providesBackdrop) return
            if (backdropLoader.item) IrisGlassBackdrops.register(root.windowHost, backdropLoader.item)
            else IrisGlassBackdrops.unregister(root._lent)
            root._lent = backdropLoader.item
        }
    }
    property Item _lent: null
    Component.onDestruction: if (root._lent) IrisGlassBackdrops.unregister(root._lent)

    Item {
        id: noBackdrop
        visible: false
        width: 1
        height: 1
        layer.enabled: true
    }

    // The frame's interior that no band, wave, frame light or body (with its fillet) reaches. The
    // chassis field covers the whole output, so while music moves the band every frame this is most
    // of the screen skipping the shader.
    readonly property vector4d quietRect: {
        if (!root.framed) return Qt.vector4d(0, 0, 0, 0)
        const wave = Math.max(root.edgeWave.x, root.edgeWave.y, root.edgeWave.z, root.edgeWave.w, 0)
        const edge = root.band + wave + root.frameMusicLightWidth + root.reach + 16
        let left = edge, top = edge, right = root.width - edge, bottom = root.height - edge
        const margin = root.reach + 32 + root.trailSpan
        for (const s of root.shapes ?? []) {
            const x0 = s.x - margin, y0 = s.y - margin
            const x1 = s.x + s.width + margin, y1 = s.y + s.height + margin
            if (x1 <= left || x0 >= right || y1 <= top || y0 >= bottom) continue
            const keep = [
                { area: (right - x1) * (bottom - top), l: x1, t: top, r: right, b: bottom },
                { area: (x0 - left) * (bottom - top), l: left, t: top, r: x0, b: bottom },
                { area: (right - left) * (bottom - y1), l: left, t: y1, r: right, b: bottom },
                { area: (right - left) * (y0 - top), l: left, t: top, r: right, b: y0 }
            ].reduce((best, c) => c.area > best.area ? c : best)
            left = keep.l; top = keep.t; right = keep.r; bottom = keep.b
        }
        if (right - left < 64 || bottom - top < 64) return Qt.vector4d(0, 0, 0, 0)
        return Qt.vector4d(left, top, right, bottom)
    }

    readonly property rect bounds: {
        if (root.framed) return Qt.rect(0, 0, root.width, root.height)
        const list = root.shapes ?? []
        if (list.length === 0) return Qt.rect(0, 0, 0, 0)
        let left = Infinity;
        let top = Infinity;
        let right = -Infinity;
        let bottom = -Infinity;
        for (const s of list) {
            const r = root.reach + root.trailSpan
            left = Math.min(left, s.x - r)
            top = Math.min(top, s.y - r)
            right = Math.max(right, s.x + s.width + r)
            bottom = Math.max(bottom, s.y + s.height + r)
        }
        const x = Math.max(0, Math.floor(left));
        const y = Math.max(0, Math.floor(top))
        return Qt.rect(x, y, Math.ceil(Math.min(root.width, right)) - x,
            Math.ceil(Math.min(root.height, bottom)) - y)
    }

    // Light streak's trails: what each body (by its id) moved since the field last drew, stretched to the trail's length,
    // and zero once nothing has moved for a few frames. Only while Trails is on; nothing runs at rest.
    readonly property bool trailing: IrisStyle.streak && IrisStyle.streakTrails > 0
    property var trails: []
    property real trailSpan: 0
    property var _seen: ({})
    function trace() {
        if (!root.trailing) {
            if (root.trailSpan > 0) { root.trails = []; root.trailSpan = 0 }
            root._seen = {}
            return
        }
        const list = root.shapes ?? []
        const seen = {}
        const out = []
        let span = 0
        for (let i = 0; i < root.capacity; i++) {
            const s = list[i]
            let t = Qt.vector4d(0, 0, 0, 0)
            if (s && s.id) {
                const g = [s.x + s.width / 2, s.y + s.height / 2, s.width / 2, s.height / 2]
                const was = root._seen[s.id]
                // A jump is a body taking another's place, not motion.
                if (was && Math.abs(g[0] - was[0]) + Math.abs(g[1] - was[1]) < 300) {
                    const d = g.map((v, k) => Math.max(-180, Math.min(180, (v - was[k]) * 5)))
                    t = Qt.vector4d(d[0], d[1], d[2], d[3])
                    span = Math.max(span, Math.abs(d[0]) + Math.abs(d[2]), Math.abs(d[1]) + Math.abs(d[3]))
                }
                seen[s.id] = g
            }
            out.push(t)
        }
        root._seen = seen
        if (span > 0 || root.trailSpan > 0) {
            root.trails = out
            root.trailSpan = span
        }
        if (span > 0) trailStill.restart()
    }
    Timer {
        id: trailStill
        interval: 60
        onTriggered: { root.trails = []; root.trailSpan = 0 }
    }
    onTrailingChanged: root.trace()

    ShaderEffect {
        id: pass
        visible: root.bounds.width > 0 && root.bounds.height > 0
        x: root.bounds.x
        y: root.bounds.y
        width: root.bounds.width
        height: root.bounds.height
        // One shader per texture: every look in one pass cost every Intel laptop its frames (IrisField.frag).
        fragmentShader: Qt.resolvedUrl("IrisField" + (IrisStyle.afterglow ? "Glow" : IrisStyle.leak ? "Leak" : IrisStyle.streak ? "Streak" : "Plain") + ".frag.qsb")
        blending: true
        // Kept as a texture: a frame the chassis draws for its content alone (a bubble's live number, the clock) copies it
        // instead of running the field over the output again. The pass reruns only when a uniform or a texture it reads
        // changes. At rest that was ~1 full-field frame a second, twice as dear under Afterglow (11-02). Only the chassis:
        // its size is the output's; a floating field's bounds follow its bodies and would reallocate the layer per frame.
        layer.enabled: root.framed
        layer.smooth: root.resampled
        layer.textureSize: root.renderScale < 1 ? Qt.size(Math.round(pass.width * root.renderScale), Math.round(pass.height * root.renderScale))
            : Qt.size(0, 0)

        // Every per-body uniform in one pass over the table. A moving body rewrites `shapes` every frame, and as ~55
        // bindings (one per uniform, each with its own closures and lookups) that pass cost several times the work.
        readonly property var packed: {
            const list = root.shapes ?? []
            const n = Math.min(list.length, root.capacity)
            const zero = Qt.vector4d(0, 0, 0, 0)
            const index = {}
            for (let i = 0; i < n; i++)
                if (list[i]?.id) index[list[i].id] = i
            const geometry = [], corners = [], link = []
            let glassy = false
            // The first body that wears a picture (`art`: a layered item or a ShaderEffectSource, `artShow` 0..1,
            // `artRise`: pixels past the band's inner line it takes to come in).
            let artAt = -1
            const slot = (s, which) => {
                const names = !s || !s.joins ? [] : Array.isArray(s.joins) ? s.joins : [s.joins]
                const name = names[which]
                if (!name) return 0
                if (name === "frame") return root.framed ? -1 : 0
                const at = index[name]
                return at === undefined ? 0 : at + 1
            }
            for (let i = 0; i < root.capacity; i++) {
                const s = list[i]
                if (artAt < 0 && i < n && s?.art) artAt = i
                geometry.push(s ? Qt.vector4d(s.x + s.width / 2, s.y + s.height / 2, s.width / 2, s.height / 2) : zero)
                const c = s ? IrisFrame.cornersOf(s) : null
                corners.push(c ? Qt.vector4d(c.tl, c.tr, c.br, c.bl) : zero)
                // A glass body still materialising carries its frost in the fraction: 1 - 0.4 * (1 - frost).
                const g = root.glassOf(s)
                const material = g > 0 && s.frost !== undefined ? g - 0.4 * (1 - Math.max(0, Math.min(1, Number(s.frost)))) : g
                glassy = glassy || material > 0
                link.push(s ? Qt.vector4d(Number(s.fuse ?? root.smoothing), slot(s, 0), slot(s, 1), material + (s.paints ? 4 : 0)) : zero)
            }
            const worn = artAt >= 0 ? list[artAt] : null
            return { count: n, geometry: geometry, corners: corners, link: link, glassy: glassy, art: worn?.art ?? null,
                artLane: worn ? Qt.vector4d(artAt + 1, Math.max(0, Math.min(1, Number(worn.artShow ?? 1))),
                    worn.art.width / Math.max(1, worn.art.height), Math.max(0, Number(worn.artRise ?? 0))) : zero }
        }
        onPackedChanged: if (root.trailing) root.trace()
        readonly property vector4d viewport: Qt.vector4d(pass.x, pass.y,
            Math.max(1, pass.width), Math.max(1, pass.height))
        readonly property vector2d screen: Qt.vector2d(Math.max(1, root.width), Math.max(1, root.height))
        readonly property vector4d scene: Qt.vector4d(root.sceneOrigin.x, root.sceneOrigin.y,
            root.sceneSize.width > 0 ? root.sceneSize.width : Math.max(1, root.width),
            root.sceneSize.height > 0 ? root.sceneSize.height : Math.max(1, root.height))
        readonly property vector4d field: Qt.vector4d(root.smoothing, root.framed ? 1 : 0,
            root.band, root.cornerRadius)
        readonly property color tint: root.tint
        readonly property vector4d quiet: root.quietRect
        readonly property vector4d extent: Qt.vector4d(pass.packed.count, root.reach + 32 + root.trailSpan + root.frameMusicLightWidth,
            pass.packed.glassy || (root.framed && root.frameGlass > 0) ? 1 : 0, 0)
        readonly property color rim: root.rim
        readonly property color sheen: root.sheen
        readonly property vector4d bodyTop: IrisStyle.bodyTop
        readonly property vector4d bodyFoot: IrisStyle.bodyFoot
        readonly property vector4d edgeGlass: IrisStyle.afterglow || IrisStyle.streak ? Qt.vector4d(0, 0, 1, 0)
            : Qt.vector4d(IrisStyle.glassEdgeLight, IrisStyle.glassEdgeLine, IrisStyle.edgeWidth, IrisStyle.edgeLit ? 1 : 0)
        // z: one device pixel in the field's units; both edges are drawn that many pixels wide.
        readonly property vector4d edge: Qt.vector4d(root.rimWidth, root.rim.a > 0 ? 1 : 0, IrisStyle.devicePx / Math.max(0.2, root.renderScale), 0)
        readonly property vector4d glowMix: IrisStyle.afterglowMix
        readonly property vector4d glowShadow: IrisStyle.afterglowShadow
        readonly property vector4d glowLight: IrisStyle.afterglowLight
        readonly property vector4d glowBloom: IrisStyle.afterglowBloomInk
        readonly property vector4d glowShape: IrisStyle.afterglowShape
        readonly property vector4d streakMix: IrisStyle.streakMix
        readonly property vector4d streakHue0: IrisStyle.streakHue0
        readonly property vector4d streakHue1: IrisStyle.streakHue1
        readonly property vector4d streakHue2: IrisStyle.streakHue2
        readonly property vector4d streakSource: IrisStyle.streakLightOn(Qt.size(pass.scene.z, pass.scene.w), IrisFrame.islandEdge)
        readonly property vector4d trail0: root.trails[0] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail1: root.trails[1] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail2: root.trails[2] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail3: root.trails[3] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail4: root.trails[4] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail5: root.trails[5] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail6: root.trails[6] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail7: root.trails[7] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail8: root.trails[8] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail9: root.trails[9] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail10: root.trails[10] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail11: root.trails[11] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail12: root.trails[12] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail13: root.trails[13] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail14: root.trails[14] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail15: root.trails[15] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail16: root.trails[16] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail17: root.trails[17] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail18: root.trails[18] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d trail19: root.trails[19] ?? Qt.vector4d(0, 0, 0, 0)
        readonly property vector4d leakMix: IrisStyle.leakMix
        readonly property vector4d leakGrain: IrisStyle.leakFilm
        readonly property vector4d leakShape: IrisStyle.leakBody
        readonly property vector4d leakStop0: IrisStyle.leakStop0
        readonly property vector4d leakStop1: IrisStyle.leakStop1
        readonly property vector4d leakStop2: IrisStyle.leakStop2
        readonly property vector4d leakStop3: IrisStyle.leakStop3
        readonly property vector4d leakStop4: IrisStyle.leakStop4
        readonly property vector4d leakCore: IrisStyle.leakCore
        readonly property vector4d leakAt0: IrisStyle.leakAt0
        readonly property vector4d leakAt1: IrisStyle.leakAt1
        readonly property vector4d leakAt2: IrisStyle.leakAt2
        readonly property vector4d leakForm0: IrisStyle.leakForm0
        readonly property vector4d leakForm1: IrisStyle.leakForm1
        readonly property vector4d leakForm2: IrisStyle.leakForm2
        readonly property vector4d leakHue0: IrisStyle.leakHue0
        readonly property vector4d leakHue1: IrisStyle.leakHue1
        readonly property vector4d leakHue2: IrisStyle.leakHue2
        readonly property vector4d shape0: pass.packed.geometry[0]
        readonly property vector4d shape1: pass.packed.geometry[1]
        readonly property vector4d shape2: pass.packed.geometry[2]
        readonly property vector4d shape3: pass.packed.geometry[3]
        readonly property vector4d shape4: pass.packed.geometry[4]
        readonly property vector4d shape5: pass.packed.geometry[5]
        readonly property vector4d shape6: pass.packed.geometry[6]
        readonly property vector4d shape7: pass.packed.geometry[7]
        readonly property vector4d shape8: pass.packed.geometry[8]
        readonly property vector4d shape9: pass.packed.geometry[9]
        readonly property vector4d shape10: pass.packed.geometry[10]
        readonly property vector4d shape11: pass.packed.geometry[11]
        readonly property vector4d shape12: pass.packed.geometry[12]
        readonly property vector4d shape13: pass.packed.geometry[13]
        readonly property vector4d shape14: pass.packed.geometry[14]
        readonly property vector4d shape15: pass.packed.geometry[15]
        readonly property vector4d shape16: pass.packed.geometry[16]
        readonly property vector4d shape17: pass.packed.geometry[17]
        readonly property vector4d shape18: pass.packed.geometry[18]
        readonly property vector4d shape19: pass.packed.geometry[19]
        readonly property vector4d corners0: pass.packed.corners[0]
        readonly property vector4d corners1: pass.packed.corners[1]
        readonly property vector4d corners2: pass.packed.corners[2]
        readonly property vector4d corners3: pass.packed.corners[3]
        readonly property vector4d corners4: pass.packed.corners[4]
        readonly property vector4d corners5: pass.packed.corners[5]
        readonly property vector4d corners6: pass.packed.corners[6]
        readonly property vector4d corners7: pass.packed.corners[7]
        readonly property vector4d corners8: pass.packed.corners[8]
        readonly property vector4d corners9: pass.packed.corners[9]
        readonly property vector4d corners10: pass.packed.corners[10]
        readonly property vector4d corners11: pass.packed.corners[11]
        readonly property vector4d corners12: pass.packed.corners[12]
        readonly property vector4d corners13: pass.packed.corners[13]
        readonly property vector4d corners14: pass.packed.corners[14]
        readonly property vector4d corners15: pass.packed.corners[15]
        readonly property vector4d corners16: pass.packed.corners[16]
        readonly property vector4d corners17: pass.packed.corners[17]
        readonly property vector4d corners18: pass.packed.corners[18]
        readonly property vector4d corners19: pass.packed.corners[19]
        readonly property vector4d link0: pass.packed.link[0]
        readonly property vector4d link1: pass.packed.link[1]
        readonly property vector4d link2: pass.packed.link[2]
        readonly property vector4d link3: pass.packed.link[3]
        readonly property vector4d link4: pass.packed.link[4]
        readonly property vector4d link5: pass.packed.link[5]
        readonly property vector4d link6: pass.packed.link[6]
        readonly property vector4d link7: pass.packed.link[7]
        readonly property vector4d link8: pass.packed.link[8]
        readonly property vector4d link9: pass.packed.link[9]
        readonly property vector4d link10: pass.packed.link[10]
        readonly property vector4d link11: pass.packed.link[11]
        readonly property vector4d link12: pass.packed.link[12]
        readonly property vector4d link13: pass.packed.link[13]
        readonly property vector4d link14: pass.packed.link[14]
        readonly property vector4d link15: pass.packed.link[15]
        readonly property vector4d link16: pass.packed.link[16]
        readonly property vector4d link17: pass.packed.link[17]
        readonly property vector4d link18: pass.packed.link[18]
        readonly property vector4d link19: pass.packed.link[19]
        readonly property bool backdropReady: root.backdropSource?.ready ?? false
        readonly property vector4d glass: Qt.vector4d(pass.backdropReady ? 1 : 0, root.framed ? root.frameGlass : 0,
            IrisStyle.glassTint, IrisStyle.glassLip)
        readonly property vector4d edgeWave: root.edgeWave
        readonly property vector4d waveClock: Qt.vector4d(root.waveClock, 0, 0, 0)
        readonly property vector4d frameLight: Qt.vector4d(root.frameMusicAppearance, root.frameMusicLevel,
            root.frameMusicLight, root.frameMusicLightWidth)
        readonly property color frameInk: root.frameMusicInk
        readonly property color shade: IrisStyle.shadow
        readonly property vector4d shadeShape: Qt.vector4d(root.shadowFall, root.shadowBlur, root.casts ? 1 : 0, 0)
        readonly property Item backdrop: pass.backdropReady ? root.backdropSource.texture : noBackdrop
        readonly property Item clearBackdrop: pass.backdropReady ? (root.backdropSource.clearTexture ?? root.backdropSource.texture) : noBackdrop
        readonly property vector4d artLane: pass.packed.artLane
        readonly property Item art: pass.packed.art ?? noBackdrop
    }
}
