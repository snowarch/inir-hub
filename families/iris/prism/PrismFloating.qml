pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.iris.prism.core

// Prism as a window of its own (`iris.appearance.settingsHost` = window): the same panel in a Niri window that tiles,
// floats and takes focus like any app, the desktop left alone behind it. Its lights act on the window: red and yellow
// put Settings away, green maximises its column.
FloatingWindow {
    id: root
    // Untranslated: niri's rule that opens Settings at two thirds of the screen matches this title (as the classic one).
    title: "iNiR Settings"
    visible: GlobalStates.settingsOverlayOpen
    color: PrismTheme.canvas
    implicitWidth: PrismTheme.dp(1280)
    implicitHeight: PrismTheme.dp(840)
    minimumSize: Qt.size(PrismTheme.dp(760), PrismTheme.dp(520))
    onClosed: GlobalStates.settingsOverlayOpen = false

    readonly property var niriWindow: {
        const list = NiriService.windows ?? []
        return list.find(w => w.title === root.title && w.pid === Quickshell.processId) ?? null
    }
    Binding {
        target: GlobalStates
        property: "settingsWindowBehind"
        value: root.visible && root.niriWindow !== null && !root.niriWindow.is_focused
    }
    // Opened over IPC it carries no activation token, so Niri maps it without focus.
    property bool focusedOnce: false
    onNiriWindowChanged: if (root.niriWindow && !root.focusedOnce) {
        root.focusedOnce = true
        NiriService.focusWindow(root.niriWindow.id)
    }
    onVisibleChanged: if (!root.visible) root.focusedOnce = false
    Component.onDestruction: GlobalStates.settingsWindowBehind = false
    Connections {
        target: GlobalStates
        function onSettingsRaiseRequestChanged(): void {
            if (root.niriWindow) NiriService.focusWindow(root.niriWindow.id)
        }
    }

    PrismRequests { onOpened: panel.forceActiveFocus() }

    PrismPanel {
        id: panel
        anchors.fill: parent
        windowed: true
        active: GlobalStates.settingsOverlayOpen
        focus: true
        onCloseRequested: GlobalStates.settingsOverlayOpen = false
        onGrowRequested: if (root.niriWindow) {
            NiriService.focusWindow(root.niriWindow.id)
            NiriService.maximizeColumn()
        }
    }
}
