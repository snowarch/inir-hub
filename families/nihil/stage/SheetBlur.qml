pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.nihil.style

// What the compositor blurs behind the sheet: the band, each body pulled out of it and the coves that weld them, walked
// in whole pixels from the same curve the shader draws. Rebuilt in the window's polish, so the blur moves with the frame.
Scope {
    id: root

    required property var window
    // { width, height, flipped, band, full, bodies: [{ x, width, reach, radius }] }, everything measured from the edge the
    // sheet hangs from; `reach` is where a body ends.
    property var shape: null
    readonly property bool wanted: CompositorService.blurRegions && NihilStyle.blur

    property bool dirty: false
    property bool settled: true
    property var pool: []
    property int used: 0

    readonly property Region target: Region {}
    readonly property Component piece: Component { Region {} }

    onShapeChanged: {
        root.dirty = true
        root.settled = false
        settle.restart()
        frame.restart()
    }
    onWantedChanged: root.publish(false)

    function take(): void {
        if (!root.dirty) return
        root.dirty = false
        frame.stop()
        root.place(root.build())
    }
    Connections {
        target: root.window?.contentItem ?? null
        ignoreUnknownSignals: true
        function onPolished(): void { root.take() }
    }
    Timer { id: frame; interval: 0; onTriggered: root.take() }
    Timer {
        id: settle
        interval: 96
        onTriggered: {
            root.settled = true
            root.place(root.build())
            root.publish(true)
        }
    }

    // A pixel is in when its centre is: Niri blurs whole pixels, without antialiasing.
    function lo(v: real): real { return Math.floor(v - 0.5) + 1 }
    function hi(v: real): real { return Math.ceil(v - 0.5) }

    function build(): var {
        const s = root.shape
        if (!s || !root.wanted) return []
        if (s.full) return [[0, 0, s.width, s.height, 0]]
        const out = []
        if (s.band > 0.5) out.push([0, 0, s.width, root.hi(s.band), 0])
        const stride = root.settled ? 1 : 3
        for (const body of s.bodies) {
            const drop = body.reach - s.band
            if (drop <= 0.5 || body.width <= 0.5) continue
            const left = root.lo(body.x), right = root.hi(body.x + body.width)
            const radius = Math.min(body.radius, drop, body.width / 2)
            out.push([left, Math.max(0, root.lo(s.band - radius)), right - left, root.hi(body.reach) - Math.max(0, root.lo(s.band - radius)), radius])
            const k = Math.min(NihilStyle.fuse, drop * 0.8)
            const rootK = Math.sqrt(k)
            for (let a = 0; a < k; a += stride) {
                const side = rootK - Math.sqrt(a + stride / 2)
                const b = side * side
                if (b < 0.5) break
                const l = root.lo(body.x - b), r = root.hi(body.x + body.width + b)
                out.push([l, Math.round(s.band + a), r - l, stride, 0])
            }
        }
        if (s.flipped)
            for (const rect of out) rect[1] = s.height - rect[1] - rect[3]
        return out
    }

    function place(rects: var): void {
        while (root.pool.length < rects.length) {
            const made = root.piece.createObject(root.target)
            root.target.regions.push(made)
            root.pool.push(made)
        }
        const reach = Math.max(root.used, rects.length)
        for (let n = 0; n < reach; n++) {
            const rect = rects[n] ?? [0, 0, 0, 0, 0]
            const region = root.pool[n]
            region.x = rect[0]
            region.y = rect[1]
            region.width = rect[2]
            region.height = rect[3]
            region.radius = rect[4]
        }
        const emptied = root.used > 0 !== rects.length > 0
        root.used = rects.length
        if (emptied) root.publish(false)
    }

    // Niri reads a region again when it is handed over anew.
    function publish(fresh: bool): void {
        if (!root.window) return
        const effect = root.window.BackgroundEffect
        if (fresh) effect.blurRegion = null
        effect.blurRegion = root.wanted && root.used > 0 ? root.target : null
        root.window.contentItem?.Window.window?.update()
    }
    Component.onCompleted: root.publish(false)
    Component.onDestruction: if (root.window) root.window.BackgroundEffect.blurRegion = null
}
