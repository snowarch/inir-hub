.pragma library

// Stream URL builders and brand presets ported/adapted from omacam.
var BRANDS = [
  {
    id: "tapo", label: "Tapo / TP-Link",
    main: "rtsp://{host}:554/stream1", sub: "rtsp://{host}:554/stream2",
    credentials: "camera-account", info: "Tapo app → camera → Settings → Advanced → Camera Account.",
    note: "Some Tapo models use /stream1 & /stream2, others /h264/ch1/main/av_stream & /h264/ch1/sub/av_stream. Use Test connection if unsure.",
    alts: [
      { label: "Tapo stream1/2", main: "rtsp://{host}:554/stream1", sub: "rtsp://{host}:554/stream2" },
      { label: "Tapo h264 main/sub", main: "rtsp://{host}:554/h264/ch1/main/av_stream", sub: "rtsp://{host}:554/h264/ch1/sub/av_stream" }
    ]
  },
  {
    id: "dahua", label: "Dahua / Imou",
    main: "rtsp://{host}:554/cam/realmonitor?channel=1&subtype=0",
    sub: "rtsp://{host}:554/cam/realmonitor?channel=1&subtype=1",
    credentials: "device", info: "Uses the camera's own username and password."
  },
  {
    id: "reolink", label: "Reolink",
    main: "rtsp://{host}:554/h264Preview_01_main", sub: "rtsp://{host}:554/h264Preview_01_sub",
    credentials: "device", info: "Enable RTSP in the camera settings if needed."
  },
  {
    id: "hikvision", label: "Hikvision",
    main: "rtsp://{host}:554/Streaming/Channels/101", sub: "rtsp://{host}:554/Streaming/Channels/102",
    credentials: "device", info: "Uses the camera's own username and password."
  },
  {
    id: "amcrest", label: "Amcrest",
    main: "rtsp://{host}:554/cam/realmonitor?channel=1&subtype=0",
    sub: "rtsp://{host}:554/cam/realmonitor?channel=1&subtype=1",
    credentials: "device", info: "Dahua-compatible RTSP paths."
  },
  {
    id: "unifi", label: "UniFi Protect",
    main: "rtsps://{host}:7441/{cameraId}", sub: "",
    credentials: "device", info: "Enable a stream in Protect settings; use the stream key as camera id.",
    hostLabel: "NVR / console address", idLabel: "Stream key"
  },
  {
    id: "onvif", label: "ONVIF / Generic RTSP",
    main: "rtsp://{host}:554/", sub: "",
    credentials: "device", info: "Many ONVIF cameras need a model-specific stream path."
  },
  {
    id: "http", label: "HTTP / MJPEG",
    main: "http://{host}/", sub: "",
    credentials: "optional", info: "For cameras that expose an HTTP snapshot or MJPEG stream URL."
  },
  {
    id: "custom", label: "Custom URL",
    main: "", sub: "",
    credentials: "optional", info: "Enter a full stream URL (rtsp://, http://, etc.)."
  }
]

function brand(id) {
  for (var i = 0; i < BRANDS.length; i++) if (BRANDS[i].id === id) return BRANDS[i]
  return BRANDS[BRANDS.length - 1]
}

function template(id, which) {
  var b = brand(id)
  return (which === "sub" ? b.sub : b.main) || ""
}

function expand(templateStr, camera) {
  if (!templateStr) return ""
  var host = (camera.host || "").trim()
  var cameraId = (camera.cameraId || "").trim()
  return templateStr.replace(/\{host\}/g, host).replace(/\{cameraId\}/g, cameraId)
}

function needsUser(brandId) { return brandId !== "custom" && brandId !== "http" }

function buildUrl(templateStr, camera) {
  var url = expand(templateStr, camera)
  if (!url) return ""
  var user = encodeURIComponent((camera.username || "").trim())
  var pass = encodeURIComponent(camera.password || "")
  if (!user && !pass) return url
  var scheme = url.indexOf("://")
  if (scheme < 0) return url
  var auth = user + (pass ? ":" + pass : "") + "@"
  return url.slice(0, scheme + 3) + auth + url.slice(scheme + 3)
}

function streamUrl(camera, which) {
  if (!camera) return ""
  if (which === "sub" && camera.urlSub) return buildUrl(camera.urlSub, camera)
  if (which === "main" && camera.urlMain) return buildUrl(camera.urlMain, camera)
  if (camera.url) return buildUrl(camera.url, camera)
  var t = template(camera.brand || "custom", which || "main")
  return buildUrl(t, camera)
}

function redact(url) {
  if (!url) return ""
  return url.replace(/(rtsp[s]?:\/\/)([^@\/\s]+)@/i, "$1•••@")
}

function parseOnvifDeviceServiceUrl(value) {
  var match = String(value || "").trim().match(/^(https?:\/\/)([^@\/\s]+)@(.+)$/i)
  if (!match) return null
  return { url: match[1] + match[3], auth: match[2] }
}
