import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// The camera list, kept in this component's own file
// (~/.config/inir/plugins/inircam.json, mode 600: it holds camera passwords).
// Removing the component leaves the file as it was.
Item {
    id: root
    visible: false
    width: 0
    height: 0

    readonly property string path: Directories.pluginFile("inircam")

    property var cameras: []
    property bool ready: false

    function normalize(cam) {
        return {
            id: cam.id || String(Date.now()),
            name: cam.name || "Camera",
            brand: cam.brand || "custom",
            host: cam.host || "",
            cameraId: cam.cameraId || "",
            username: cam.username || "",
            password: cam.password || "",
            urlMain: cam.urlMain || cam.url || "",
            urlSub: cam.urlSub || "",
            enabled: cam.enabled !== false
        }
    }

    function loadFromText(text) {
        let doc = {}
        try {
            doc = JSON.parse(text || "{}")
        } catch (e) {
            doc = {}
        }
        const list = Array.isArray(doc.cameras) ? doc.cameras : []
        const out = []
        for (let i = 0; i < list.length; i++) out.push(normalize(list[i] || {}))
        root.cameras = out
        root.ready = true
    }

    function save() {
        if (!root.ready) return
        store.setText(JSON.stringify({ version: 1, cameras: root.cameras }, null, 2))
        // The file holds passwords: only the person reads it.
        lockDown.command = ["chmod", "600", root.path]
        lockDown.running = false
        lockDown.running = true
    }

    function addCamera(cam) {
        const list = root.cameras.slice()
        const c = normalize(cam)
        if (!c.id) c.id = String(Date.now())
        list.push(c)
        root.cameras = list
        root.save()
        return c
    }

    function updateCamera(id, cam) {
        const list = root.cameras.slice()
        for (let i = 0; i < list.length; i++) {
            if (list[i].id !== id) continue
            const c = normalize(cam)
            c.id = id
            list[i] = c
            root.cameras = list
            root.save()
            return c
        }
        return null
    }

    function removeCamera(id) {
        const list = []
        for (let i = 0; i < root.cameras.length; i++) {
            if (root.cameras[i].id !== id) list.push(root.cameras[i])
        }
        root.cameras = list
        root.save()
    }

    function cameraById(id) {
        for (let i = 0; i < root.cameras.length; i++) {
            if (root.cameras[i].id === id) return root.cameras[i]
        }
        return null
    }

    function enabledCameras() {
        const out = []
        for (let i = 0; i < root.cameras.length; i++) {
            if (root.cameras[i].enabled !== false) out.push(root.cameras[i])
        }
        return out
    }

    Process {
        id: lockDown
        running: false
    }

    FileView {
        id: store
        path: root.path
        atomicWrites: true
        printErrors: false
        onLoaded: root.loadFromText(text())
        onLoadFailed: {
            // No file yet: an empty list, written the first time a camera is saved.
            root.cameras = []
            root.ready = true
        }
    }
}