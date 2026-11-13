import QtQuick
import QtMultimedia
import Quickshell
import "Shared.js" as Shared

// Renders a camera stream from the shared StreamPool.
Item {
  id: root

  required property var pool
  required property var camera
  required property var play
  property bool capture: false
  property bool muted: true

  readonly property var live: pool.stream(camera, play.quality)
  readonly property string status: {
    if (!play.on) return "off"
    if (!live) return "connecting"
    return live.status || "connecting"
  }
  readonly property string why: live ? (live.why || "") : ""
  readonly property var diag: live ? live.diag : null
  readonly property string retryLabel: (live && live.retryIn > 0) ? ("Retrying in " + live.retryIn + "s") : ""

  readonly property bool isLive: status === "live"
  readonly property bool isConnecting: status === "connecting"
  readonly property bool isError: status === "error"

  signal snapshotSaved(string path)
  signal snapshotFailed(string reason)

  function thumbSource() {
    if (!camera || !camera.id) return ""
    return "file:///tmp/inircam-thumb-" + camera.id + ".jpg"
  }

  function captureThumb() {
    if (!isLive || !camera || !camera.id) return
    var path = "/tmp/inircam-thumb-" + camera.id + ".jpg"
    video.grabToImage(function(result) {
      if (result && result.saveToFile) result.saveToFile(path)
    })
  }

  function takeSnapshot() {
    var name = (camera && camera.name ? camera.name : "camera").replace(/[^A-Za-z0-9 _-]/g, "_")
    var ts = Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss")
    var path = (Quickshell.env("HOME") || "/tmp") + "/Pictures/inircam-" + name + "-" + ts + ".jpg"
    video.grabToImage(function(result) {
      try {
        if (result && result.saveToFile(path)) root.snapshotSaved(path)
        else root.snapshotFailed("Could not save snapshot")
      } catch (e) {
        root.snapshotFailed(String(e))
      }
    })
  }

  implicitWidth: 320
  implicitHeight: 180

  Rectangle {
    anchors.fill: parent
    color: "#101418"
    radius: 10
    clip: true

    Image {
      id: thumb
      anchors.fill: parent
      visible: !root.isLive
      source: root.thumbSource()
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      opacity: 0.35
    }

    VideoOutput {
      id: video
      anchors.fill: parent
      visible: root.isLive
      fillMode: VideoOutput.PreserveAspectCrop
    }

    Item {
      anchors.fill: parent
      visible: !root.isLive

      Column {
        anchors.centerIn: parent
        spacing: 6
        width: Math.min(parent.width - 24, 320)

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.isConnecting ? "Connecting…" : (root.isError ? "Offline" : "Idle")
          color: "white"
          font.pixelSize: 14
          font.weight: Font.Medium
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.Wrap
          visible: root.why !== "" || root.retryLabel !== ""
          text: root.why !== "" ? root.why : root.retryLabel
          color: "#c9d1d9"
          font.pixelSize: 11
        }
      }
    }

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.margins: 8
      height: 18
      width: statusRow.implicitWidth + 10
      radius: 9
      color: root.isLive ? "#1f7a3f" : (root.isError ? "#8b2e2e" : "#4a5568")
      opacity: 0.95
      visible: root.play.on

      Row {
        id: statusRow
        anchors.centerIn: parent
        spacing: 4
        Text {
          text: root.isLive ? "LIVE" : (root.isConnecting ? "…" : "ERR")
          color: "white"
          font.pixelSize: 10
          font.weight: Font.DemiBold
        }
      }
    }
  }

  // Bind player output when live stream/player changes.
  Binding {
    target: video
    property: "player"
    value: (root.live && root.live.player) ? root.live.player : null
    when: true
  }
  Binding {
    target: root.live ? root.live.player : null
    property: "muted"
    value: root.muted
    when: root.live && root.live.player
  }

  Timer {
    interval: 20000
    repeat: true
    running: root.capture && root.isLive
    triggeredOnStart: true
    onTriggered: root.captureThumb()
  }

  Component.onCompleted: {
    if (root.pool && root.pool.hold) root.pool.hold(camera, play.quality)
  }
  Component.onDestruction: {
    if (root.pool && root.pool.release) root.pool.release(camera, play.quality)
  }
  onCameraChanged: {
    if (root.pool) { /* hold/release handled by pool keying externally in simple cases */ }
  }
}
