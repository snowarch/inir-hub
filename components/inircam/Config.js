.pragma library

// Behavior defaults for InirCam, merged with ~/.config/inir/inircam/config.json.
// Missing/misspelled keys fall back to these values.
var DEFAULTS = {
  version: 1,
  connection: {
    alwaysConnected: false,
    keepConnectedSeconds: 180,
    keepFullQualitySeconds: 30,
    retrySeconds: 15,
    statusCheckSeconds: 60,
    lowLatency: true
  },
  sound: {
    closeAfterMutedSeconds: 20
  },
  grid: {
    columns: 2,
    showNumbers: true,
    click: "enlarge",
    doubleClick: "fullscreen"
  },
  fullscreen: {
    fill: false,
    showStrip: true
  },
  wall: {
    columns: 0,
    click: "fullscreen",
    fill: false
  },
  pinned: {
    width: 360,
    snapDistance: 28
  },
  keys: {
    cameraNumbers: true,
    actions: {
      manage: "c",
      settings: "s",
      back: "Escape",
      grid: "g",
      enlarge: "Return",
      enlargeAlt: "Space",
      fullscreen: "f",
      mute: "m",
      snapshot: "S",
      pin: "p",
      wall: "w",
      close: "q",
      save: "Ctrl+Return",
      delete: "Delete",
      next: "Right",
      previous: "Left",
      toggleStrip: "t",
      refresh: "r"
    }
  }
}

var _spec = null

function spec() {
  if (_spec) return _spec
  _spec = buildSpec(DEFAULTS, [])
  return _spec
}

function buildSpec(obj, path) {
  var entries = []
  for (var k in obj) {
    var v = obj[k]
    var p = path.concat([k])
    if (v !== null && typeof v === "object" && !Array.isArray(v)) entries = entries.concat(buildSpec(v, p))
    else entries.push({ path: p, type: typeof v, value: v })
  }
  return entries
}

function clone(obj) { return JSON.parse(JSON.stringify(obj)) }

function typeOf(v) {
  if (Array.isArray(v)) return "array"
  return typeof v
}

function leaf(map, path, create) {
  var cur = map
  for (var i = 0; i < path.length - 1; i++) {
    var k = path[i]
    if (cur[k] === undefined || cur[k] === null || typeof cur[k] !== "object" || Array.isArray(cur[k])) {
      if (!create) return null
      cur[k] = {}
    }
    cur = cur[k]
  }
  return cur
}

function merge(user) {
  var out = clone(DEFAULTS)
  var unknown = []
  if (!user || typeof user !== "object" || Array.isArray(user)) return { config: out, unknown: unknown }

  for (var i = 0; i < spec().length; i++) {
    var e = spec()[i]
    var parent = leaf(user, e.path, false)
    if (!parent) continue
    var key = e.path[e.path.length - 1]
    if (!(key in parent)) continue
    var v = parent[key]
    if (typeOf(v) !== e.type) continue
    var dst = leaf(out, e.path, true)
    dst[key] = v
  }

  collectUnknown(user, [], unknown)
  return { config: out, unknown: unknown }
}

function collectUnknown(user, path, out) {
  for (var k in user) {
    var p = path.concat([k])
    var defParent = leaf(DEFAULTS, p, false)
    var inDefaults = defParent && (k in defParent)
    var v = user[k]
    if (!inDefaults) {
      if (p.length === 1 && k === "version") continue
      out.push({ path: p, value: v })
      continue
    }
    var dv = leaf(DEFAULTS, p, false)[k]
    if (dv !== null && typeof dv === "object" && !Array.isArray(dv) && v && typeof v === "object" && !Array.isArray(v))
      collectUnknown(v, p, out)
  }
}

function keyPath(event) {
  var mods = []
  if (event.modifiers & Qt.ControlModifier) mods.push("Ctrl")
  if (event.modifiers & Qt.AltModifier) mods.push("Alt")
  if (event.modifiers & Qt.ShiftModifier) mods.push("Shift")
  if (event.modifiers & Qt.MetaModifier) mods.push("Meta")
  var name = keyName(event)
  if (!name) return ""
  if (mods.length === 0) return name
  return mods.join("+") + "+" + name
}

function keyName(event) {
  var k = event.key
  var t = event.text || ""
  if (k >= Qt.Key_A && k <= Qt.Key_Z) return (event.modifiers & Qt.ShiftModifier) ? t : t.toLowerCase()
  if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k)
  if (k === Qt.Key_Escape) return "Escape"
  if (k === Qt.Key_Return || k === Qt.Key_Enter) return "Return"
  if (k === Qt.Key_Backspace) return "BackSpace"
  if (k === Qt.Key_Delete) return "Delete"
  if (k === Qt.Key_Tab) return "Tab"
  if (k === Qt.Key_Space) return "Space"
  if (k === Qt.Key_Left) return "Left"
  if (k === Qt.Key_Right) return "Right"
  if (k === Qt.Key_Up) return "Up"
  if (k === Qt.Key_Down) return "Down"
  if (k === Qt.Key_Home) return "Home"
  if (k === Qt.Key_End) return "End"
  if (k === Qt.Key_PageUp) return "PageUp"
  if (k === Qt.Key_PageDown) return "PageDown"
  if (k >= Qt.Key_F1 && k <= Qt.Key_F12) return "F" + (k - Qt.Key_F1 + 1)
  if (t.length === 1) return t
  return ""
}

function keyId(event) {
  var n = keyName(event)
  if (n.length === 1 && n >= "1" && n <= "9") return Number(n)
  return 0
}
