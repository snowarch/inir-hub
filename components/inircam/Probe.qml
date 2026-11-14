import QtQuick
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// Asks ffprobe about a stream: used by "Test connection" and to tell a wrong
// password apart from an unreachable camera when playback fails (Qt only
// reports a generic "could not open" error).
//
// result: { ok, kind: "ok" | "auth" | "path" | "offline" | "error",
//           width, height, fps, codec, message }
Item {
    id: root
    visible: false

    property bool running: proc.running
    property var result: null

    signal finished(var result)

    function probe(url) {
        if (!url) {
            root.finish({ ok: false, kind: "error", message: Translation.tr("No stream address") })
            return
        }
        if (proc.running) proc.running = false
        root.result = null
        // The address holds the camera login, so it goes in through stdin rather
        // than the command line, where other users could read it.
        root._input = url + "\n"
        proc.command = [
            "bash", "-c",
            "IFS= read -r url; exec timeout -k 2 9 ffprobe \"$@\" -i /dev/stdin < <(printf %s \"$url\")",
            "inircam-probe",
            "-v", "error",
            "-rtsp_transport", "tcp",
            "-timeout", "5000000",
            "-select_streams", "v:0",
            "-show_entries", "stream=codec_name,width,height,avg_frame_rate",
            "-of", "json"
        ]
        proc.running = true
    }

    function cancel() {
        proc.running = false
    }

    function classify(exitCode, stdout, stderr) {
        const err = String(stderr || "")
        if (exitCode === 0) {
            try {
                const data = JSON.parse(stdout)
                const s = data.streams && data.streams[0]
                if (s) {
                    let fps = 0
                    const parts = String(s.avg_frame_rate || "0/1").split("/")
                    if (Number(parts[1]) > 0) fps = Math.round(Number(parts[0]) / Number(parts[1]))
                    return {
                        ok: true,
                        kind: "ok",
                        width: s.width || 0,
                        height: s.height || 0,
                        fps: fps,
                        codec: String(s.codec_name || "").toUpperCase(),
                        message: ""
                    }
                }
            } catch (e) {}
            return { ok: false, kind: "error", message: Translation.tr("Connected, but no video stream found") }
        }
        if (/401|unauthori[sz]ed|authori[sz]ation failed/i.test(err)) {
            return { ok: false, kind: "auth", message: Translation.tr("Wrong username or password") }
        }
        if (/404|not found|method describe failed/i.test(err)) {
            return { ok: false, kind: "path", message: Translation.tr("Camera answered, but the stream address is wrong") }
        }
        if (exitCode === 124 || /timed out|refused|no route|unreachable|network is down|name or service/i.test(err)) {
            return { ok: false, kind: "offline", message: Translation.tr("No response from the camera") }
        }
        return { ok: false, kind: "error", message: Translation.tr("The camera didn't send video at this address") }
    }

    function finish(r) {
        root.result = r
        root.finished(r)
    }

    property string _stdout: ""
    property string _stderr: ""
    property string _input: ""

    Process {
        id: proc
        stdinEnabled: true
        onStarted: {
            root._stdout = ""
            root._stderr = ""
            write(root._input)
            root._input = ""
        }
        stdout: StdioCollector { id: out; waitForEnd: true; onStreamFinished: root._stdout = text }
        stderr: StdioCollector { id: err; waitForEnd: true; onStreamFinished: root._stderr = text }
        onExited: function(exitCode) {
            root.finish(root.classify(exitCode, out.text || root._stdout, err.text || root._stderr))
        }
    }
}