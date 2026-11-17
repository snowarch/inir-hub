// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import "state"
import "pages"
import "controls"

FloatingWindow {
    id: root
    property string initialPath: ""
    property bool closing: false
    signal closeRequested()
    title: Translation.tr("Video Editor")
    visible: true
    color: EditorSkin.colors.page
    implicitWidth: Appearance.sizes.sidebarWidth * 2 + Appearance.sizes.searchWidthCollapsed
    implicitHeight: Appearance.sizes.mediaControlsHeight * 5
    minimumSize: Qt.size(Appearance.sizes.sidebarWidth, Appearance.sizes.sidebarWidth)
    readonly property var niriWindow: (NiriService.windows || []).find(w => w.title === root.title && w.pid === Quickshell.processId) || null
    property bool focusedOnce: false

    function focusWindow(): void { if (root.niriWindow) NiriService.focusWindow(root.niriWindow.id); }
    function loadVideo(path): void { if (!root.closing) editorSession.load(path); }
    function shutdown(): void { if (!root.closing) { root.closing = true; videoBackend.shutdown(); } }
    onNiriWindowChanged: if (root.niriWindow && !root.focusedOnce) { root.focusedOnce = true; root.focusWindow(); }
    onClosed: root.shutdown()
    Component.onCompleted: if (root.initialPath) editorSession.load(root.initialPath)

    EditorSession { id: editorSession }
    PlaybackController { id: playerController; session: editorSession }
    VideoBackend { id: videoBackend; session: editorSession; playback: playerController; onStopped: root.closeRequested() }
    Item {
        anchors.fill: parent
        anchors.margins: EditorSkin.pad
        focus: true
        enabled: !root.closing
        Keys.priority: Keys.AfterItem
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (editorSession.renderOpen) editorSession.cancelRequested();
                else root.shutdown();
            } else if (!editorSession.ready || editorSession.renderOpen) return;
            else if (event.key === Qt.Key_Space) playerController.toggle();
            else if (event.key === Qt.Key_Left) playerController.step(-1);
            else if (event.key === Qt.Key_Right) playerController.step(1);
            else if (event.key === Qt.Key_Home) playerController.seek(editorSession.startMs);
            else if (event.key === Qt.Key_End) { playerController.pause(); playerController.seek(editorSession.effectiveEndMs); }
            else if (event.key === Qt.Key_I) editorSession.setInPoint(playerController.position);
            else if (event.key === Qt.Key_O) editorSession.setOutPoint(playerController.position);
            else if (event.key === Qt.Key_S) editorSession.cycleSpeed();
            else if (event.key === Qt.Key_P) editorSession.snapshotRequested();
            else return;
            event.accepted = true;
        }
        EditorPage { anchors.fill: parent; session: editorSession; playback: playerController; backend: videoBackend; onCloseRequested: root.shutdown() }
    }
}
