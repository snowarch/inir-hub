// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQml
import qs.services

QtObject {
    id: root
    property string status: "empty"
    property string inputPath: ""
    property var metadata: ({})
    property string errorMessage: ""
    property string errorDetail: ""
    property string auxiliaryError: ""
    property string snapshotPath: ""
    property bool infoOpen: false
    property bool compressOpen: false
    property real startMs: 0
    property real endMs: -1
    property bool cropEnabled: false
    property real cropX: 0
    property real cropY: 0
    property real cropW: 1
    property real cropH: 1
    property int rotation: 0
    property bool flipHorizontal: false
    property bool flipVertical: false
    property bool mute: false
    property real volume: 1
    property real playbackRate: 1
    property real compressionPercent: 100
    property string compressFormat: "mp4"
    property string outputResolution: "original"
    property real gifScale: 0.5
    property int gifFps: 15
    property string gifDither: "bayer"
    property int gifColors: 256
    property var thumbnails: []
    property bool thumbnailsLoading: false
    property bool estimating: false
    property real estimatedSize: 0
    property string estimateError: ""
    property bool renderOpen: false
    property string renderState: "idle"
    property real renderProgress: 0
    property real renderElapsed: 0
    property real renderDuration: 0
    property string renderFormat: "mp4"
    property string renderOutputPath: ""
    property real renderOutputSize: 0
    property int renderWidth: 0
    property int renderHeight: 0
    property string renderError: ""
    property bool renderReplaced: false

    readonly property bool ready: root.status === "ready"
    readonly property real durationMs: Math.max(0, Number(root.metadata.duration || 0) * 1000)
    readonly property real effectiveEndMs: root.endMs < 0 ? root.durationMs : Math.min(root.endMs, root.durationMs)
    readonly property real frameMs: Math.min(root.durationMs / 2, 1000 / Math.max(1, Number(root.metadata.video?.fps || 30)))
    readonly property string fileName: root.inputPath.split("/").pop() || ""
    readonly property int crf: Math.min(36, Math.round(18 + (100 - root.compressionPercent) * 0.35))

    signal loadRequested(string path)
    signal exportRequested(bool replace, string format)
    signal snapshotRequested()
    signal cancelRequested()

    function load(path): void {
        Object.assign(root, {
            inputPath: String(path || ""), status: path ? "loading" : "empty", metadata: {},
            errorMessage: "", errorDetail: "", auxiliaryError: "", snapshotPath: "",
            infoOpen: false, compressOpen: false, renderOpen: false, renderState: "idle",
            startMs: 0, endMs: -1, cropEnabled: false, cropX: 0, cropY: 0, cropW: 1, cropH: 1,
            compressionPercent: 100, compressFormat: "mp4",
            gifScale: 0.5, gifFps: 15, gifDither: "bayer", gifColors: 256,
            thumbnails: [], thumbnailsLoading: false, estimating: false, estimatedSize: 0, estimateError: ""
        });
        root.resetTransformations();
        root.loadRequested(root.inputPath);
    }

    function setInPoint(position): void { root.startMs = Math.max(0, Math.min(position, root.effectiveEndMs - root.frameMs)); }
    function setOutPoint(position): void { root.endMs = Math.max(root.startMs + root.frameMs, Math.min(position, root.durationMs)); }
    function cycleSpeed(): void {
        const rates = [0.25, 0.5, 1, 1.5, 2];
        root.playbackRate = rates[(rates.indexOf(root.playbackRate) + 1) % rates.length];
    }
    function resetTransformations(): void {
        root.rotation = 0; root.flipHorizontal = false; root.flipVertical = false;
        root.mute = false; root.outputResolution = "original"; root.playbackRate = 1;
    }
    function applyPreset(ratio): void {
        if (!root.ready) return;
        const w = root.metadata.video.width, h = root.metadata.video.height;
        root.cropW = ratio < 0 ? 1 : Math.min(1, h * ratio / w);
        root.cropH = ratio < 0 ? 1 : Math.min(1, w / ratio / h);
        root.cropX = (1 - root.cropW) / 2;
        root.cropY = (1 - root.cropH) / 2;
        root.cropEnabled = true;
    }
    function moveCrop(x, y): void {
        root.cropX = Math.max(0, Math.min(1 - root.cropW, x));
        root.cropY = Math.max(0, Math.min(1 - root.cropH, y));
    }
    function resizeCrop(w, h): void {
        root.cropW = Math.max(2 / root.metadata.video.width, Math.min(1 - root.cropX, w));
        root.cropH = Math.max(2 / root.metadata.video.height, Math.min(1 - root.cropY, h));
    }
    function exportSpec(replace, format): var {
        return { input: root.inputPath, format: format, replaceOriginal: replace,
                 startSeconds: root.startMs / 1000, endSeconds: root.effectiveEndMs / 1000,
                 crop: { x: root.cropX, y: root.cropY, w: root.cropEnabled ? root.cropW : -1,
                         h: root.cropEnabled ? root.cropH : -1, uiW: 1, uiH: 1 },
                 rotation: root.rotation, flipHorizontal: root.flipHorizontal, flipVertical: root.flipVertical,
                 mute: root.mute, playbackRate: root.playbackRate, crf: root.crf,
                 outputResolution: root.outputResolution, gifScale: root.gifScale, gifFps: root.gifFps,
                 gifDither: root.gifDither, gifColors: root.gifColors };
    }
    function describeError(data): string {
        switch (data.code) {
        case "missing_dependency": return Translation.tr("Required program %1 is missing.").arg(data.dependency || "python3");
        case "worker_failed": return Translation.tr("Could not run the video backend. Check Python 3.");
        case "invalid_input": case "local_files_only": return Translation.tr("Choose a local video file.");
        case "input_missing": return Translation.tr("The input video could not be found.");
        case "invalid_video": return Translation.tr("This file has no playable video track.");
        case "invalid_trim": return Translation.tr("The end point must come after the start point.");
        case "invalid_crop": return Translation.tr("The crop area is invalid.");
        case "no_audio": return Translation.tr("This video has no audio track to extract.");
        case "output_exists": return Translation.tr("The output already exists. Save another copy.");
        case "input_changed": return Translation.tr("The input changed during export. The original was kept.");
        case "empty_output": return Translation.tr("The encoder produced an empty output.");
        case "command_timeout": return Translation.tr("Video processing timed out.");
        case "invalid_response": return Translation.tr("The video backend returned an invalid response.");
        case "action_failed": return data.message || Translation.tr("The requested action failed.");
        default: return Translation.tr("Video processing failed.");
        }
    }
    function fail(data): void {
        root.status = "error";
        root.errorMessage = root.describeError(data);
        root.errorDetail = data.detail || "";
    }
    function bytes(value): string {
        if (!(value > 0)) return "—";
        const units = ["B", "KiB", "MiB", "GiB"];
        const i = Math.min(3, Math.floor(Math.log(value) / Math.log(1024)));
        return (value / Math.pow(1024, i)).toFixed(i === 0 ? 0 : 1) + " " + units[i];
    }
    function timecode(ms): string {
        const n = Math.max(0, Math.floor(ms));
        const pad = v => String(v).padStart(2, "0");
        const hours = Math.floor(n / 3600000);
        return (hours > 0 ? pad(hours) + ":" : "") + pad(Math.floor(n / 60000) % 60) + ":" + pad(Math.floor(n / 1000) % 60) + "." + pad(Math.floor(n % 1000 / 10));
    }
}
