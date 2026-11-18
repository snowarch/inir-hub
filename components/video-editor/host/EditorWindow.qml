// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.services
import "../controls"

FloatingWindow {
    id: root
    property bool open: false
    required property Item body
    signal closeRequested()
    title: Translation.tr("Video Editor")
    onBodyChanged: if (root.body) { root.body.parent = root.contentItem; root.body.anchors.fill = root.contentItem; }
    visible: root.open
    color: EditorSkin.page
    implicitWidth: Math.round(1180 * EditorSkin.d)
    implicitHeight: Math.round(820 * EditorSkin.d)
    minimumSize: Qt.size(Math.round(420 * EditorSkin.d), Math.round(420 * EditorSkin.d))
    onClosed: root.closeRequested()

    readonly property var niriWindow: (NiriService.windows ?? []).find(w => w.title === root.title && w.pid === Quickshell.processId) ?? null
    property bool focusedOnce: false
    function focusWindow(): void { if (root.niriWindow) NiriService.focusWindow(root.niriWindow.id); }
    onNiriWindowChanged: if (root.niriWindow && !root.focusedOnce) {
        root.focusedOnce = true;
        root.focusWindow();
    }
    onVisibleChanged: if (!root.visible) root.focusedOnce = false
}
