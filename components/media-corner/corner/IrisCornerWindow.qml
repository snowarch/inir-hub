pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.style

// A Corner in a window, as Settings' window host (settings/IrisSettingsWindow.qml): Niri owns its shape and motion,
// the body fills it. Closing the window closes the Corner.
FloatingWindow {
    id: root
    property bool open: false
    required property Item body
    signal closeRequested()
    readonly property Item frame: root.body?.frame ?? null
    onBodyChanged: if (root.body) { root.body.parent = root.contentItem; root.body.anchors.fill = root.contentItem }
    visible: root.open
    surfaceFormat: ({ opaque: false })
    color: root.frame?.material === "compositor" ? "transparent" : IrisStyle.surface
    implicitWidth: Math.round(1180 * IrisStyle.density)
    implicitHeight: Math.round(820 * IrisStyle.density)
    minimumSize: Qt.size(Math.round(420 * IrisStyle.density), Math.round(420 * IrisStyle.density))
    onClosed: root.closeRequested()

    readonly property var niriWindow: (NiriService.windows ?? []).find(w => w.title === root.title && w.pid === Quickshell.processId) ?? null
    // Opened over IPC it carries no activation token, so Niri maps it without focus.
    property bool focusedOnce: false
    onNiriWindowChanged: if (root.niriWindow && !root.focusedOnce) {
        root.focusedOnce = true
        NiriService.focusWindow(root.niriWindow.id)
    }
    onVisibleChanged: if (!root.visible) root.focusedOnce = false

}
