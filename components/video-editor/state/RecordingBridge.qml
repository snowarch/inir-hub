// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQml
import Quickshell
import qs
import qs.services

Scope {
    id: root
    property var recorder: RecorderStatus
    property var notifications: Notifications
    property var shellState: GlobalStates
    property bool enabled: true
    property int pid: 0
    property string capturedPath: ""
    property string lastKey: ""
    property string deferredPath: ""
    signal recordingFinished(string path)
    function capture(): void {
        if (!root.enabled || !root.recorder.isRecording) return;
        root.pid = root.recorder.recorderPid;
        root.capturedPath = "";
        pathJob.request("recording_path", { pid: root.pid });
    }
    function check(path): void { if (root.enabled && path) completion.request("probe", { input: path }); }
    function deliver(path): void {
        if (root.shellState.screenLocked) root.deferredPath = path;
        else { root.deferredPath = ""; root.recordingFinished(path); }
    }
    onEnabledChanged: {
        if (root.enabled) root.capture();
        else { pathJob.cancel(); completion.cancel(); root.deferredPath = ""; root.capturedPath = ""; }
    }
    RenderJob {
        id: pathJob
        onMessage: data => {
            if (data.pid !== root.pid) return;
            root.capturedPath = data.path;
            if (!root.recorder.isRecording) root.check(root.capturedPath);
        }
    }
    RenderJob {
        id: completion
        onMessage: data => {
            const key = data.path + ":" + data.modifiedNs + ":" + data.size;
            if (key === root.lastKey) return;
            root.lastKey = key;
            root.deliver(data.path);
        }
    }
    Connections {
        target: root.recorder
        function onIsRecordingChanged(): void { if (root.recorder.isRecording) root.capture(); else root.check(root.capturedPath); }
        function onRecorderPidChanged(): void { if (root.recorder.isRecording && root.recorder.recorderPid > 0) root.capture(); }
    }
    Connections {
        target: root.notifications
        function onNotify(notification): void {
            // These are record.sh's protocol identifiers, not UI strings.
            if (notification.appName === "Recorder" && notification.summary === "Recording saved" && String(notification.body).startsWith("/")) root.check(String(notification.body));
        }
    }
    Connections {
        target: root.shellState
        function onScreenLockedChanged(): void { if (root.enabled && !root.shellState.screenLocked && root.deferredPath) root.deliver(root.deferredPath); }
    }
    Component.onCompleted: root.capture()
    Component.onDestruction: { pathJob.cancel(); completion.cancel(); }
}
