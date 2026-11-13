import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import "Brands.js" as Brands
import qs.services

// Live camera view. RTSP streams are pulled via ffmpeg into a continuously
// updated JPEG frame (reliable across Qt Multimedia/VAAPI backends); other
// sources use Qt Multimedia directly.
Item {
    id: root

    required property var camera
    property string quality: "main"
    property bool active: true
    property bool muted: true
    property int retrySeconds: 15
    property bool lowLatency: true

    readonly property string streamUrlStr: root.camera ? Brands.streamUrl(root.camera, root.quality).toString() : ""
    readonly property bool useFfmpeg: /^rtsps?:/i.test(root.streamUrlStr)
    readonly property string framePath: "/tmp/inircam-feed-" + Quickshell.processId + "-" + (root.camera ? root.camera.id : "none") + "-" + root.quality + ".jpg"

    property string status: "idle"   // idle · connecting · live · error
    property string note: ""
    property int _frameNonce: 0
    property bool _ffmpegStarting: false

    signal snapshotSaved(string path)
    signal snapshotFailed(string reason)

    function start() {
        retry.stop()
        if (!root.camera || root.streamUrlStr === "") {
            root.status = "idle"
            root.note = ""
            return
        }
        root.status = "connecting"
        root.note = ""
        if (root.useFfmpeg) startFfmpeg()
        else startPlayer()
    }

    function stop() {
        retry.stop()
        stopPlayer()
        stopFfmpeg()
        root.status = "idle"
    }

    function startPlayer() {
        stopFfmpeg()
        player.stop()
        player.source = ""
        player.source = root.streamUrlStr
        player.play()
    }

    function stopPlayer() {
        player.stop()
        player.source = ""
    }

    function startFfmpeg() {
        // RTSP frames are supplied by the inircam-feeds helper (external ffmpeg).
        // We only poll/display the frame file here.
        stopPlayer()
        stopFfmpeg(false)
        root._ffmpegStarting = true
        framePoll.interval = 1200
        framePoll.restart()
    }

    function stopFfmpeg(resetState = true) {
        framePoll.stop()
        root._ffmpegStarting = false
        // do not kill external ffmpeg here; helper manages process lifetime
        if (resetState) {
            root._frameNonce = 0
            frameImg.source = ""
        }
    }

    function takeSnapshot() {
        if (root.status !== "live") {
            root.snapshotFailed(Translation.tr("No picture to save"))
            return
        }
        const name = ((root.camera && root.camera.name) || "camera").replace(/[^A-Za-z0-9 _-]/g, "_")
        const stamp = Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss")
        const path = `${Directories.picturesPath}/inircam-${name}-${stamp}.jpg`
        if (root.useFfmpeg) {
            snapProc._path = path
            snapProc.command = ["cp", root.framePath, path]
            snapProc.running = true
            return
        }
        const ok = video.grabToImage(function(result) {
            if (result) root.snapshotSaved(path)
            else root.snapshotFailed(Translation.tr("The picture could not be saved"))
        })
        if (!ok) root.snapshotFailed(Translation.tr("The picture could not be saved"))
    }

    implicitWidth: 320
    implicitHeight: 180

    onActiveChanged: root.active ? root.start() : root.stop()
    onStreamUrlStrChanged: if (root.active) root.start()
    Component.onCompleted: if (root.active) root.start()
    Component.onDestruction: {
        root.stop()
        // best-effort cleanup of frame file
        cleanupProc.command = ["rm", "-f", root.framePath]
        cleanupProc.running = true
    }

    // ── Qt Multimedia path (non-RTSP) ───────────────────────────────────
    MediaPlayer {
        id: player
        videoOutput: video
        audioOutput: audio
        loops: 1
        playbackOptions.playbackIntent: root.lowLatency

        onPlaybackStateChanged: {
            if (root.useFfmpeg) return
            if (playbackState === MediaPlayer.PlayingState) root.status = "live"
            else if (playbackState === MediaPlayer.StoppedState && root.active && root.status === "live") {
                // unexpected stop -> reconnect
                root.status = "connecting"
                retry.restart()
            }
        }
        onErrorOccurred: function(error, errorString) {
            if (root.useFfmpeg) return
            root.status = "error"
            root.note = errorString || Translation.tr("The camera could not be reached")
            retry.restart()
        }
    }

    AudioOutput {
        id: audio
        muted: root.muted
    }

    VideoOutput {
        id: video
        anchors.fill: parent
        visible: !root.useFfmpeg && root.status === "live"
        fillMode: VideoOutput.PreserveAspectCrop
    }

    // ── ffmpeg frame path (RTSP, passive viewer) ──────────────────────
    // External helper (inircam-feeds) keeps ffmpeg frame pullers running.

    Timer {
        id: framePoll
        interval: 125
        repeat: true
        running: false
        onTriggered: {
            root._frameNonce++
            frameImg.source = "file://" + root.framePath + "?t=" + root._frameNonce
            // ramp to steady poll after initial delay
            if (interval > 125) interval = 125
        }
    }

    Image {
        id: frameImg
        anchors.fill: parent
        visible: root.useFfmpeg
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: false
        smooth: true
        source: ""
        onStatusChanged: {
            if (!root.useFfmpeg) return
            if (status === Image.Ready) {
                root._ffmpegStarting = false
                root.status = "live"
                root.note = ""
            } else if (status === Image.Error) {
                // file not ready yet while connecting; keep waiting
                if (root.status !== "connecting") root.status = "connecting"
            }
        }
    }

    Process {
        id: snapProc
        property string _path: ""
        onExited: (code) => {
            if (code === 0) root.snapshotSaved(_path)
            else root.snapshotFailed(Translation.tr("The picture could not be saved"))
        }
    }

    Process {
        id: cleanupProc
    }

    // ── Retry + status overlay ──────────────────────────────────────────
    Timer {
        id: retry
        interval: Math.max(1, root.retrySeconds) * 1000
        repeat: false
        onTriggered: if (root.active) root.start()
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colSurfaceContainerHighest
        visible: root.status !== "live"
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 24
        spacing: 4
        visible: root.status !== "live"

        MaterialSymbol {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.status === "connecting" ? "sync" : "videocam_off"
            iconSize: Appearance.font.pixelSize.huge
            color: Appearance.colors.colOnSurfaceVariant
            RotationAnimator on rotation {
                running: root.status === "connecting"
                from: 0; to: 360; duration: 1100; loops: Animation.Infinite
            }
        }
        StyledText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.status === "connecting" ? Translation.tr("Connecting…") : Translation.tr("No picture")
            color: Appearance.colors.colOnSurface
            font.pixelSize: Appearance.font.pixelSize.small
        }
        StyledText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            visible: root.note !== ""
            text: root.note
            color: Appearance.colors.colOnSurfaceVariant
            font.pixelSize: Appearance.font.pixelSize.smaller
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.Wrap
        }
    }
}
