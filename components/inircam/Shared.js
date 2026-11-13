.pragma library

// Shared state across InirCam components (substream failures, etc.)
var subBroken = {}

function cameraKey(camera, quality) {
  if (!camera) return ""
  return (camera.id || "") + "|" + (quality || "main")
}

function nextTag() {
  // simple counter stored on the library object
  if (typeof SharedSerial === "undefined") {
    // not possible in pragma library global; use property on this
  }
  if (!_serial) _serial = 0
  _serial += 1
  return "t" + _serial
}
var _serial = 0
