pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.iris.style

Item {
    id: root
    visible: false
    width: 0
    height: 0

    property real to: 0
    property real value: 0
    property real velocity: 0
    property string intent: "auto"
    property string surface: ""
    property bool animate: true
    property real minimum: -1e9
    property real epsilon: 0.0005

    property bool running: false
    readonly property bool moving: root.running

    property real from: 0
    property real elapsed: 0

    property real clock: 0
    property real lastClock: 0
    NumberAnimation on clock {
        running: root.running
        from: 0
        to: 1
        duration: 1000
        loops: Animation.Infinite
    }
    onRunningChanged: root.lastClock = root.clock

    function params(): var {
        const intent = root.intent !== "auto" ? root.intent : root.to >= root.value ? "emerge" : "recede"
        return IrisStyle.springFor(intent, root.surface)
    }
    function jump(): void {
        root.running = false
        root.velocity = 0
        root.value = root.to
    }
    function kick(): void {
        if (!root.animate || root.params().response <= 0) { root.jump(); return }
        if (Math.abs(root.value - root.to) < root.epsilon && Math.abs(root.velocity) < root.epsilon * 12) {
            root.jump()
            return
        }
        root.from = root.value
        root.elapsed = 0
        root.running = true
    }
    onToChanged: root.kick()
    onAnimateChanged: if (!root.animate) root.jump()
    Component.onCompleted: root.value = root.to

    onClockChanged: {
        if (!root.running) return
        let frame = root.clock - root.lastClock
        if (frame < 0) frame += 1
        root.lastClock = root.clock
        if (frame <= 0) return
        const p = root.params()
        if (p.response <= 0) { root.jump(); return }
        const dt = Math.min(frame, 0.05)
        if (p.curve) {
            root.elapsed += dt * 1000
            if (root.elapsed >= p.response) { root.jump(); return }
            const next = root.from + (root.to - root.from) * IrisStyle.cubicBezier(p.curve, root.elapsed / p.response)
            root.velocity = (next - root.value) / dt
            root.value = Math.max(root.minimum, next)
            return
        }
        const w = 2 * Math.PI / (p.response / 1000)
        const zeta = 1 - p.bounce
        const x0 = root.value - root.to
        const v0 = root.velocity
        let x, v
        if (zeta < 0.9999) {
            const wd = w * Math.sqrt(1 - zeta * zeta)
            const e = Math.exp(-zeta * w * dt)
            const b = (v0 + zeta * w * x0) / wd
            const c = Math.cos(wd * dt), s = Math.sin(wd * dt)
            x = e * (x0 * c + b * s)
            v = -zeta * w * x + e * (-x0 * wd * s + b * wd * c)
        } else {
            const e = Math.exp(-w * dt)
            const b = v0 + w * x0
            x = (x0 + b * dt) * e
            v = (b - w * (x0 + b * dt)) * e
        }
        let next = root.to + x
        if (next < root.minimum) { next = root.minimum; v = 0 }
        if (Math.abs(x) < root.epsilon && Math.abs(v) < root.epsilon * 12) {
            root.jump()
            return
        }
        root.velocity = v
        root.value = next
    }
}
