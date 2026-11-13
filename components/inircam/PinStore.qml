import QtQuick
import Quickshell.Io
import qs.modules.common

// The pinned cameras: which camera floats on the desktop, where, how wide.
// Kept under the shell's state directory, its name starting with this item's id.
Item {
    id: root
    visible: false
    width: 0
    height: 0

    readonly property string path: `${Directories.stateUserPath}/inircam-pins.json`

    property var pins: []
    property bool ready: false

    function loadFromText(text) {
        let doc = []
        try {
            doc = JSON.parse(text || "[]")
        } catch (e) {
            doc = []
        }
        const list = Array.isArray(doc) ? doc : (Array.isArray(doc && doc.pins) ? doc.pins : [])
        const out = []
        for (let i = 0; i < list.length; i++) {
            const p = list[i] || {}
            if (!p.cameraId) continue
            out.push({
                id: String(p.id || ("pin-" + i)),
                cameraId: String(p.cameraId),
                x: Number(p.x) || 80,
                y: Number(p.y) || 120,
                width: Math.max(220, Math.min(960, Number(p.width) || 360)),
                onTop: p.onTop !== false,
                output: String(p.output || "")
            })
        }
        root.pins = out
        root.ready = true
    }

    function save() {
        if (!root.ready) return
        store.setText(JSON.stringify(root.pins, null, 2))
    }

    function pinFor(cameraId) {
        const id = String(cameraId || "")
        for (let i = 0; i < root.pins.length; i++) {
            if (root.pins[i].cameraId === id) return root.pins[i]
        }
        return null
    }

    function add(cameraId) {
        const id = String(cameraId || "")
        if (!id || root.pinFor(id)) return null
        const pin = {
            id: "pin-" + Date.now() + "-" + root.pins.length,
            cameraId: id,
            x: 80 + (root.pins.length % 6) * 36,
            y: 100 + (root.pins.length % 6) * 36,
            width: 360,
            onTop: true,
            output: ""
        }
        root.pins = root.pins.concat([pin])
        root.save()
        return pin
    }

    function remove(pinId) {
        const id = String(pinId || "")
        const next = []
        for (let i = 0; i < root.pins.length; i++) {
            if (root.pins[i].id !== id) next.push(root.pins[i])
        }
        root.pins = next
        root.save()
    }

    function update(pinId, fields) {
        const id = String(pinId || "")
        const next = []
        let changed = false
        for (let i = 0; i < root.pins.length; i++) {
            const p = root.pins[i]
            if (p.id !== id) {
                next.push(p)
                continue
            }
            const np = Object.assign({}, p, fields || {})
            np.width = Math.max(220, Math.min(960, Number(np.width) || p.width))
            next.push(np)
            changed = true
        }
        if (changed) {
            root.pins = next
            root.save()
        }
    }

    function toggle(cameraId) {
        const existing = root.pinFor(cameraId)
        if (existing) {
            root.remove(existing.id)
            return false
        }
        root.add(cameraId)
        return true
    }

    FileView {
        id: store
        path: root.path
        atomicWrites: true
        printErrors: false
        onLoaded: root.loadFromText(text())
        onLoadFailed: {
            root.pins = []
            root.ready = true
        }
    }
}