.pragma library

// State shared by every camera picture in this component (one copy per engine).

// Cameras whose low-res stream does not work; their tiles use the full stream.
var subBroken = {}

// Full-stream resolution per camera ("2304×1296"), once seen.
var mainResolution = {}

function markSubBroken(cameraId) {
    if (cameraId) subBroken[cameraId] = true
}

function noteResolution(cameraId, width, height) {
    if (cameraId && width > 0 && height > 0) mainResolution[cameraId] = width + "×" + height
}