// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.iris.style
import "host"
import "state"
import "controls"

Scope {
    id: root
    readonly property bool windowed: EditorOptions.windowed
    property bool opened: false
    property bool resident: false
    property bool promptOpen: false
    property string promptPath: ""
    property string promptError: ""
    property string pendingOpenPath: ""
    property bool reopenAfterClose: false
    property bool backendStopped: true

    RecordingBridge { enabled: EditorOptions.showEditPrompt; onRecordingFinished: path => root.showPrompt(path) }

    function showPrompt(path): void {
        EditorOptions.reload();
        if (!EditorOptions.showEditPrompt || !path) return;
        root.promptOpen = false;
        root.promptPath = path;
        root.promptError = "";
        promptShow.restart();
    }
    Timer { id: promptShow; interval: 0; onTriggered: root.promptOpen = true }

    function openVideo(path): void {
        EditorOptions.reload();
        root.pendingOpenPath = path || "";
        openLater.restart();
    }
    function finishOpen(): void {
        root.promptOpen = false;
        const path = root.pendingOpenPath;
        if (sessionHost.item) {
            if (sessionHost.item.closing) { root.reopenAfterClose = true; return; }
            grace.stop();
            root.opened = true;
            sessionHost.item.loadVideo(path);
            sessionHost.item.focusWindow();
        } else {
            grace.stop();
            root.backendStopped = false;
            root.resident = true;
            root.opened = true;
        }
    }
    function requestClose(): void {
        openLater.stop();
        root.reopenAfterClose = false;
        promptShow.stop();
        promptDismiss.restart();
        if (!root.resident) return;
        root.opened = false;
        if (!root.windowed && EditorSkin.iris) grace.restart();
        if (sessionHost.item) sessionHost.item.shutdown();
        else { root.backendStopped = true; root.tryRelease(); }
    }
    function tryRelease(): void {
        if (root.opened || !root.backendStopped || grace.running) return;
        windowDismiss.restart();
    }

    Timer {
        id: grace
        interval: IrisStyle.settleDuration + 120
        onTriggered: root.tryRelease()
    }
    Timer {
        id: windowDismiss
        interval: 0
        onTriggered: {
            if (root.opened) return;
            root.resident = false;
            if (root.reopenAfterClose) { root.reopenAfterClose = false; openLater.restart(); }
        }
    }
    Timer { id: openLater; interval: 0; onTriggered: root.finishOpen() }
    Timer { id: promptDismiss; interval: 0; onTriggered: root.promptOpen = false }

    LazyLoader {
        id: sessionHost
        active: root.resident
        component: Scope {
            id: holder
            property bool closing: false
            function loadVideo(path): void { if (!holder.closing) editorSession.load(path); }
            function focusWindow(): void { if (windowHost.item) windowHost.item.focusWindow(); }
            function shutdown(): void { if (!holder.closing) { holder.closing = true; videoBackend.shutdown(); } }
            Component.onCompleted: if (root.pendingOpenPath) editorSession.load(root.pendingOpenPath)

            EditorSession { id: editorSession }
            PlaybackController { id: playerController; session: editorSession }
            VideoBackend {
                id: videoBackend
                session: editorSession
                playback: playerController
                onStopped: { root.backendStopped = true; root.tryRelease(); }
            }

            LazyLoader {
                active: !root.windowed
                component: EditorOverlay {
                    open: root.opened
                    body: EditorBody {
                        windowed: false
                        open: root.opened
                        closing: holder.closing
                        session: editorSession
                        playback: playerController
                        backend: videoBackend
                        onCloseRequested: root.requestClose()
                    }
                }
            }
            LazyLoader {
                id: windowHost
                active: root.windowed
                component: EditorWindow {
                    open: root.opened
                    onCloseRequested: root.requestClose()
                    body: EditorBody {
                        windowed: true
                        open: root.opened
                        closing: holder.closing
                        session: editorSession
                        playback: playerController
                        backend: videoBackend
                        onCloseRequested: root.requestClose()
                    }
                }
            }
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
                if (EditorOptions.openInLosslessCut) external.request("launch_losslesscut", { input: root.promptPath });
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
        /// Toggle between floating window and desktop overlay mode
        function toggleHost(): void { EditorOptions.set("windowed", !EditorOptions.windowed); }
        /// Close the editor and recording prompt, stopping active jobs
        function close(): void { external.cancel(); root.requestClose(); }
    }
}
