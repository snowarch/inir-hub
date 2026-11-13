import QtQuick
import Quickshell
import Quickshell.Io

// Camera list persisted to ~/.config/inir/inircam/cameras.json (mode 600).
QtObject {
  id: root

  property string dirPath: (Quickshell.env("HOME") || "/tmp") + "/.config/inir/inircam"
  property string path: dirPath + "/cameras.json"
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
    try {
      var obj = JSON.parse(text || "{}")
      var list = Array.isArray(obj.cameras) ? obj.cameras : []
      var out = []
      for (var i = 0; i < list.length; i++) out.push(normalize(list[i] || {}))
      root.cameras = out
    } catch (e) {
      root.cameras = []
    }
    root.ready = true
  }

  function save() {
    if (!root.ready) return
    saveProc.command = ["bash", "-c",
      "set -e; dir=\"$1\"; file=\"$2\"; tmp=\"$file.tmp\"; mkdir -p \"$dir\"; cat > \"$tmp\"; chmod 600 \"$tmp\"; mv \"$tmp\" \"$file\"",
      "bash", root.dirPath, root.path]
    saveProc.running = false
    saveProc.running = true
  }

  function addCamera(cam) {
    var list = root.cameras.slice()
    var c = normalize(cam)
    if (!c.id) c.id = String(Date.now())
    list.push(c)
    root.cameras = list
    save()
    return c
  }

  function updateCamera(id, cam) {
    var list = root.cameras.slice()
    for (var i = 0; i < list.length; i++) {
      if (list[i].id === id) {
        var c = normalize(cam)
        c.id = id
        list[i] = c
        root.cameras = list
        save()
        return c
      }
    }
    return null
  }

  function removeCamera(id) {
    var list = []
    for (var i = 0; i < root.cameras.length; i++) if (root.cameras[i].id !== id) list.push(root.cameras[i])
    root.cameras = list
    save()
  }

  function cameraById(id) {
    for (var i = 0; i < root.cameras.length; i++) if (root.cameras[i].id === id) return root.cameras[i]
    return null
  }

  property Process saveProc: Process {
    stdinEnabled: true
    onStarted: {
      write(JSON.stringify({ cameras: root.cameras }, null, 2))
      stdinEnabled = false
      closeStdin()
    }
    onExited: stdinEnabled = true
  }

  property FileView file: FileView {
    path: root.path
    printErrors: false
    onLoaded: root.loadFromText(text())
    onLoadFailed: {
      // Missing file: start empty and mark ready so we can save first camera.
      root.cameras = []
      root.ready = true
    }
  }

  property bool missing: false
  function refresh() { file.reload() }
  Timer {
    interval: 5000
    repeat: true
    running: root.missing
    onTriggered: file.reload()
  }

  Component.onCompleted: refresh()
}
