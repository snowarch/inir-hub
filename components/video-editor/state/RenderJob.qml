// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQml
import Quickshell.Io
import qs.services
import qs.modules.common.functions

Process {
    id: root
    readonly property string backendPath: FileUtils.trimFileProtocol(Plugins.path("video-editor", "scripts/video_backend.py"))
    property bool busy: false
    property bool cancelling: false
    property string result: ""
    property int serial: 0
    property string ticket: ""
    property var pending: null
    property string operation: ""
    readonly property bool jsonProtocol: root.operation !== ""
    property string failureText: ""

    signal message(var data)
    signal failed(var data)
    signal completed()

    function request(operation, payload): void {
        const next = Object.assign({}, payload, { requestId: String(++root.serial) });
        root.pending = { command: ["python3", root.backendPath, operation, JSON.stringify(next)], ticket: next.requestId, operation: operation };
        if (root.busy) root.interrupt();
        else root.pump.restart();
    }

    function runCommand(args, errorText): void {
        root.pending = { command: args, ticket: String(++root.serial), operation: "", failure: errorText };
        if (root.busy) root.interrupt();
        else root.pump.restart();
    }

    function interrupt(): void {
        if (root.cancelling) return;
        root.cancelling = true;
        if (root.running) root.signal(15);
    }

    function cancel(): void {
        root.pending = null;
        root.pump.stop();
        if (root.busy) root.interrupt();
    }

    function finish(code): void {
        if (!root.busy) return;
        if (!root.cancelling && root.result !== "error") {
            if (code !== 0 || root.jsonProtocol && root.result !== "success") root.failed({ code: root.jsonProtocol ? "worker_failed" : "action_failed", detail: errors.text, message: root.failureText });
            else root.completed();
        }
        root.busy = false;
        root.cancelling = false;
        if (root.pending) root.pump.restart();
    }

    function validMessage(data): bool {
        switch (root.operation) {
        case "probe":
            return data.event === "metadata" && typeof data.path === "string" && typeof data.url === "string"
                && Number.isFinite(data.duration) && data.duration > 0
                && Number.isFinite(data.video?.width) && Number.isFinite(data.video?.height)
                && data.video.width >= 2 && data.video.height >= 2;
        case "thumbnails": return data.event === "thumbnails_finished" || data.event === "thumbnail" && Number.isInteger(data.index) && data.index >= 0 && typeof data.url === "string";
        case "estimate": return data.event === "estimate" && Number.isFinite(data.estimatedSize);
        case "snapshot": return data.event === "snapshot_done" && typeof data.path === "string";
        case "recording_path": return data.event === "recording_path" && Number.isInteger(data.pid) && typeof data.path === "string";
        case "launch_losslesscut": return data.event === "launched";
        case "export":
            if (data.event === "progress") return Number.isFinite(data.value) && Number.isFinite(data.elapsed);
            return ["started", "finished"].includes(data.event) && typeof data.outputPath === "string"
                && Number.isFinite(data.duration) && Number.isFinite(data.width) && Number.isFinite(data.height)
                && (data.event === "started" || Number.isFinite(data.size));
        default: return false;
        }
    }

    property Timer pump: Timer {
        interval: 0
        onTriggered: {
            if (root.busy || !root.pending) return;
            const next = root.pending;
            root.pending = null;
            root.ticket = next.ticket;
            root.operation = next.operation;
            root.failureText = next.failure || "";
            root.result = "";
            root.cancelling = false;
            root.command = next.command;
            root.busy = true;
            root.running = true;
            root.settle.restart();
        }
    }
    property Timer settle: Timer { interval: 0; onTriggered: if (root.busy && !root.running) root.finish(-1) }
    onRunningChanged: if (!root.running && root.busy) root.settle.restart()
    onExited: (exitCode, exitStatus) => root.finish(exitStatus === 0 ? exitCode : -1)
    stderr: StdioCollector { id: errors }
    stdout: SplitParser {
        onRead: line => {
            if (!root.jsonProtocol || root.cancelling || !root.busy || root.result === "error") return;
            try {
                const data = JSON.parse(String(line));
                if (!data || typeof data.requestId !== "string" || typeof data.event !== "string") throw new Error("Invalid backend message");
                if (data.requestId !== root.ticket) return;
                if (data.event === "error") {
                    if (typeof data.code !== "string" || ["detail", "message", "dependency"].some(key => data[key] !== undefined && typeof data[key] !== "string")) throw new Error("Invalid backend error");
                    root.result = "error";
                    root.failed(data);
                } else {
                    if (!root.validMessage(data)) throw new Error("Unexpected backend response");
                    if (!["started", "progress", "thumbnail"].includes(data.event)) root.result = "success";
                    root.message(data);
                }
            } catch (error) {
                root.result = "error";
                root.failed({ code: "invalid_response", detail: String(error) });
                root.interrupt();
            }
        }
    }
}
