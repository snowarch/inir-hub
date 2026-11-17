// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQml
import Quickshell
import Quickshell.Io
import qs.services
import "state"

Scope {
    id: root
    property bool opened: false
    property bool promptOpen: false
    property string promptPath: ""
    property string promptError: ""
    property string pendingOpenPath: ""
    property bool reopenAfterClose: false

    EditorOptions { id: options }
    RecordingBridge { enabled: options.showEditPrompt; onRecordingFinished: path => root.showPrompt(path) }
    function showPrompt(path): void {
        options.reload();
        if (!options.showEditPrompt || !path) return;
        root.promptOpen = false;
        root.promptPath = path;
        root.promptError = "";
        promptShow.restart();
    }
    Timer { id: promptShow; interval: 0; onTriggered: root.promptOpen = true }
    function openVideo(path): void {
        options.reload();
        root.pendingOpenPath = path || "";
        openLater.restart();
    }
    function finishOpen(): void {
        root.promptOpen = false;
        const path = root.pendingOpenPath;
        if (window.item) {
            if (window.item.closing) { root.reopenAfterClose = true; return; }
            window.item.loadVideo(path);
            window.item.focusWindow();
        } else root.opened = true;
    }
    function requestClose(): void {
        openLater.stop();
        root.reopenAfterClose = false;
        promptShow.stop();
        promptDismiss.restart();
        if (window.item) window.item.shutdown();
        else windowDismiss.restart();
    }
    Timer {
        id: windowDismiss
        interval: 0
        onTriggered: {
            root.opened = false;
            if (root.reopenAfterClose) { root.reopenAfterClose = false; openLater.restart(); }
        }
    }
    Timer { id: openLater; interval: 0; onTriggered: root.finishOpen() }
    Timer { id: promptDismiss; interval: 0; onTriggered: root.promptOpen = false }
    LazyLoader {
        id: window
        active: root.opened
        component: EditorWindow {
            initialPath: root.pendingOpenPath
            onCloseRequested: windowDismiss.restart()
        }
    }
    LazyLoader {
        id: prompt
        active: root.promptOpen
        component: RecordingPrompt {
            videoPath: root.promptPath
            errorMessage: root.promptError
            busy: external.busy
            onDismissed: promptDismiss.restart()
            onEditRequested: {
                if (options.openInLosslessCut) external.request("launch_losslesscut", { input: root.promptPath });
                else root.openVideo(root.promptPath);
            }
        }
    }
    RenderJob {
        id: external
        onCompleted: promptDismiss.restart()
        onFailed: data => root.promptError = Translation.tr("Could not open LosslessCut. Check that it is installed.") + (data.detail ? "\n" + data.detail : "")
    }
    /// Video Editor: edit local clips, or show the recording-finished prompt.
    ///
    /// ```kdl
    /// Mod+Shift+V { spawn "inir" "video-editor" "toggle"; }
    /// ```
    IpcHandler {
        target: "video-editor"
        /// Open an empty editor, or close the currently open editor
        function toggle(): void { if (root.opened) root.requestClose(); else root.openVideo(""); }
        /// Open an empty editor
        function open(): void { root.openVideo(""); }
        /// Open a local video path or file URL
        function openFile(path: string): void { root.openVideo(path); }
        /// Show the original editing prompt for a completed recording
        function prompt(path: string): void { root.showPrompt(path); }
        /// Close the editor and recording prompt, stopping active jobs
        function close(): void { external.cancel(); root.requestClose(); }
    }
}
