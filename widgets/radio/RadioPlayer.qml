pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "radio.js" as R

// The stream itself, played by mpv (an iNiR dependency on every distro). mpv's own socket says what the station
// announces (the ICY title), whether sound has started and whether it is paused; with mpv-mpris (an iNiR dependency)
// the station is a player the shell's media controls and the media keys reach. A pause from there reads as stopped.
Scope {
    id: root

    property real volume: 60
    property bool muted: false
    property var station: null
    readonly property bool active: proc.running
    property bool audible: false
    property bool paused: false
    property string onAir: ""         // what the station says plays now ("Artist - Title"), when it says
    property string failure: ""

    signal dead()                     // the stream never started, or stopped by itself

    readonly property string socketPath: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/inir-radio-mpv.sock`

    function play(next): void {
        root.station = next
        root.audible = false
        root.paused = false
        root.onAir = ""
        root.failure = ""
        root.unlink()
        if (proc.running) {
            root._restart = true
            proc.running = false
        } else startSoon.restart()
    }
    function stop(): void {
        root.station = null
        root._restart = false
        root.unlink()
        proc.running = false
    }
    function togglePause(): void { root.send(["cycle", "pause"]) }
    function send(command: var): void {
        const link = links.item
        if (root.linked && link) {
            link.write(JSON.stringify({ command: command }) + "\n")
            link.flush()
        }
    }
    property bool linked: false
    function unlink(): void {
        root.linked = false
        links.active = false
    }
    onVolumeChanged: root.send(["set_property", "volume", Math.round(root.volume)])
    onMutedChanged: root.send(["set_property", "mute", root.muted])

    property bool _restart: false
    Timer {
        id: startSoon
        interval: 60
        onTriggered: if (root.station) {
            root._began = false
            proc.running = true
            launched.restart()
        }
    }
    // A program that can't be found never starts and never exits: mpv is missing.
    property bool _began: false
    Timer {
        id: launched
        interval: 1500
        onTriggered: if (root.station !== null && !root._began && !proc.running) {
            root.failure = "mpv"
            root.dead()
        }
    }

    Process {
        id: proc
        command: ["mpv", "--no-video", "--no-terminal", "--idle=no", "--force-window=no", "--cache=yes",
            "--network-timeout=12", "--title=iNiR Radio", `--force-media-title=${String(root.station?.name ?? "Radio")}`,
            `--volume=${Math.round(root.volume)}`, `--mute=${root.muted ? "yes" : "no"}`,
            `--input-ipc-server=${root.socketPath}`, String(root.station?.url ?? "")]
        onStarted: {
            root._began = true
            socketWait.restart()
        }
        onExited: (code, status) => {
            root.unlink()
            if (root._restart) {
                root._restart = false
                startSoon.restart()
                return
            }
            if (root.station !== null) {
                root.failure = code === 127 ? "mpv" : "stream"
                root.dead()
            }
        }
    }
    // mpv makes its socket a moment after it starts, and a Socket whose connect failed never tries again: each try
    // is a new one.
    Timer {
        id: socketWait
        interval: 250
        repeat: true
        property int tries: 0
        onRunningChanged: if (running) tries = 0
        onTriggered: {
            if (root.linked || !proc.running || ++tries > 40) { stop(); return }
            links.active = false
            links.active = true
        }
    }
    // A stream that hasn't made a sound in this long is dead for us.
    Timer {
        interval: 12000
        running: proc.running && !root.audible
        onTriggered: {
            root.failure = "silent"
            root.station = null
            proc.running = false
            root.dead()
        }
    }

    Loader {
        id: links
        active: false
        sourceComponent: Socket {
            path: root.socketPath
            connected: true
            onConnectionStateChanged: if (connected) {
                root.linked = true
                root.send(["observe_property", 1, "metadata"])
                root.send(["observe_property", 2, "core-idle"])
                root.send(["observe_property", 3, "pause"])
            }
            parser: SplitParser {
                onRead: line => root.heard(line)
            }
        }
    }
    function heard(line: string): void {
        let m = null
        try { m = JSON.parse(line) } catch (e) { return }
        if (m?.event !== "property-change") return
        if (m.name === "core-idle" && m.data === false) root.audible = true
        else if (m.name === "pause") root.paused = m.data === true
        else if (m.name === "metadata" && m.data) {
            const icy = R.unescape(m.data["icy-title"] ?? m.data["StreamTitle"] ?? "")
            if (icy.length > 0) root.onAir = icy
        }
    }
}
