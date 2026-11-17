// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQml
import Quickshell
import qs.services
import qs.modules.common

Scope {
    id: root
    required property EditorSession session
    required property PlaybackController playback
    property bool stopping: false
    property bool copied: false
    property var pendingExport: null
    property bool returningToEditor: false
    readonly property bool busy: probe.busy || thumbnails.busy || estimate.busy || snapshot.busy || render.busy || action.busy
    readonly property bool actionBusy: action.busy
    readonly property var estimateSpec: root.session.ready && root.session.compressOpen && !root.session.renderOpen ? root.session.exportSpec(false, root.session.compressFormat) : null
    onEstimateSpecChanged: {
        root.estimateDelay.stop();
        estimate.cancel();
        root.session.estimating = !!root.estimateSpec && !root.stopping;
        if (root.session.estimating) {
            Object.assign(root.session, { estimatedSize: 0, estimateError: "" });
            root.estimateDelay.restart();
        }
    }
    signal stopped()

    function cancelWork(): void {
        root.estimateDelay.stop();
        root.exportLater.stop();
        root.pendingExport = null;
        root.returningToEditor = false;
        for (const job of [probe, thumbnails, estimate, snapshot, render]) job.cancel();
    }
    function shutdown(): void {
        root.stopping = true;
        root.cancelWork();
        root.cancelLater.stop();
        root.playback.stop();
        root.copiedReset.stop();
        action.cancel();
        root.checkStopped.restart();
    }
    function loadVideo(): void {
        if (root.stopping) return;
        root.cancelWork();
        if (root.session.inputPath) probe.request("probe", { input: root.session.inputPath });
    }
    function beginExport(): void {
        if (!root.pendingExport || root.stopping) return;
        const { replace, format } = root.pendingExport;
        root.pendingExport = null;
        estimate.cancel();
        thumbnails.cancel();
        root.session.thumbnailsLoading = false;
        root.estimateDelay.stop();
        Object.assign(root.session, {
            renderState: "rendering", renderFormat: format, renderError: "", renderOutputPath: "",
            renderOutputSize: 0, renderProgress: 0, renderDuration: 0,
            renderReplaced: false, renderElapsed: 0, renderOpen: true
        });
        root.playback.pause();
        render.request("export", root.session.exportSpec(replace, format));
    }
    function finishCancel(): void {
        if (root.stopping) return;
        if (render.busy) {
            root.returningToEditor = true;
            root.session.renderState = "cancelling";
            render.cancel();
            return;
        }
        root.returningToEditor = false;
        if (root.session.renderState === "done" && root.session.renderReplaced) {
            root.session.load(root.session.renderOutputPath);
            return;
        }
        render.cancel();
        root.session.renderOpen = false;
        root.session.renderState = "idle";
        root.playback.play();
    }
    function openOutput(folder): void {
        const path = root.session.renderOutputPath;
        if (!path) return;
        action.runCommand(["xdg-open", folder ? path.substring(0, path.lastIndexOf("/")) : path], Translation.tr("Could not open the exported file or folder."));
    }
    function copyPath(): void {
        if (root.session.renderOutputPath) action.runCommand(["wl-copy", "--", root.session.renderOutputPath], Translation.tr("Could not copy the path. Check wl-clipboard."));
    }
    property Timer estimateDelay: Timer {
        interval: Appearance.animation.elementMoveFast.duration
        onTriggered: if (!root.stopping && root.estimateSpec) estimate.request("estimate", root.estimateSpec)
    }
    property Timer exportLater: Timer { interval: 0; onTriggered: root.beginExport() }
    property Timer cancelLater: Timer { interval: 0; onTriggered: root.finishCancel() }
    property Timer copiedReset: Timer { interval: 2200; onTriggered: root.copied = false }
    property Timer checkStopped: Timer { interval: 0; onTriggered: if (root.stopping && !root.busy) root.stopped() }
    onBusyChanged: if (root.stopping && !root.busy) root.checkStopped.restart()

    RenderJob {
        id: probe
        onMessage: data => {
            Object.assign(root.session, { metadata: data, inputPath: data.path, status: "ready", thumbnailsLoading: true });
            thumbnails.request("thumbnails", { input: data.path });
        }
        onFailed: data => root.session.fail(data)
    }
    RenderJob {
        id: thumbnails
        onMessage: data => {
            if (data.event === "thumbnail") {
                const images = root.session.thumbnails.slice();
                images[data.index] = data.url;
                root.session.thumbnails = images;
            } else root.session.thumbnailsLoading = false;
        }
        onFailed: data => { root.session.thumbnailsLoading = false; root.session.auxiliaryError = root.session.describeError(data); }
    }
    RenderJob {
        id: estimate
        onMessage: data => { root.session.estimatedSize = data.estimatedSize; root.session.estimating = false; }
        onFailed: data => { root.session.estimating = false; root.session.estimateError = root.session.describeError(data); }
    }
    RenderJob {
        id: snapshot
        onMessage: data => { root.session.snapshotPath = data.path; root.session.auxiliaryError = ""; Notifications.send(Translation.tr("Snapshot saved"), data.path, "normal", 5000); }
        onFailed: data => root.session.auxiliaryError = root.session.describeError(data)
    }
    RenderJob {
        id: render
        onBusyChanged: if (root.returningToEditor && !render.busy) root.cancelLater.restart()
        onMessage: data => {
            if (data.event === "started") {
                Notifications.send(Translation.tr("Exporting…"), root.session.fileName, "normal", 5000);
                Object.assign(root.session, { renderOutputPath: data.outputPath, renderDuration: data.duration, renderWidth: data.width, renderHeight: data.height });
            } else if (data.event === "progress") {
                root.session.renderProgress = Math.max(root.session.renderProgress, data.value || 0);
                root.session.renderElapsed = data.elapsed || 0;
            } else if (data.event === "finished") {
                Object.assign(root.session, { renderState: "done", renderProgress: 1, renderOutputPath: data.outputPath, renderOutputSize: data.size, renderReplaced: data.replacedSource === true });
                Notifications.send(Translation.tr("Export Complete"), Translation.tr("Saved to %1").arg(data.outputPath), "normal", 5000);
            }
        }
        onFailed: data => { root.session.renderState = "error"; root.session.renderError = root.session.describeError(data) + (data.detail ? "\n" + data.detail : ""); Notifications.send(Translation.tr("Export Failed"), root.session.describeError(data), "normal", 5000); }
    }
    RenderJob {
        id: action
        onFailed: data => root.session.auxiliaryError = root.session.describeError(data) + (data.detail ? "\n" + data.detail : "")
        onCompleted: {
            if (action.command[0] === "wl-copy") { root.copied = true; root.copiedReset.restart(); }
        }
    }
    Connections {
        target: root.session
        function onLoadRequested(): void { root.loadVideo(); }
        function onExportRequested(replace, format): void {
            if (!root.session.ready || root.stopping) return;
            root.pendingExport = { replace, format };
            root.exportLater.restart();
        }
        function onSnapshotRequested(): void { if (root.session.ready && !root.stopping) snapshot.request("snapshot", { input: root.session.inputPath, positionSeconds: root.playback.position / 1000, outputDir: Directories.picturesPath }); }
        function onCancelRequested(): void { root.cancelLater.restart(); }
    }
}
