pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.nihil.field as Field
import qs.modules.nihil.prism.core

// Prism as a window of its own (`nihil.appearance.settingsHost` = window): the same panel in a Niri window that tiles,
// floats and takes focus like any app, the desktop left alone behind it. Its lights act on the window: red and yellow
// put Settings away, green maximises its column. Under Blur the compositor blurs the whole window behind the panel's
// veil (Niri: this region; Umbriel: its window rule); under Glass a window stays solid, as NiHiL's windows do.
FloatingWindow {
    id: root
    // Untranslated: niri's rule that opens Settings at two thirds of the screen matches this title (as the classic one).
    title: "iNiR Settings"
    // Shown while Settings is open. A Binding, not `visible:`: closed from outside (Niri's close-window), the window
    // turns its own `visible` false, which would cut a plain binding and leave Settings unable to open again.
    Binding { target: root; property: "visible"; value: GlobalStates.settingsOverlayOpen }
    surfaceFormat: ({ opaque: false })
    color: PrismTheme.glassBlur ? "transparent" : PrismTheme.canvas
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
    // Asked for while open: a minimized window comes back from the dock's stash first, then takes focus.
    Connections {
        target: GlobalStates
        function onSettingsRaiseRequestChanged(): void {
            if (!root.niriWindow) return
            if (MinimizedWindows.isMinimized(root.niriWindow.id)) MinimizedWindows.restore(root.niriWindow.id)
            NiriService.focusWindow(root.niriWindow.id)
        }
    }

    PrismRequests { onOpened: panel.forceActiveFocus() }

    Field.IrisBlurRegion {
        window: root
        shapes: PrismTheme.glassBlur ? [{ x: 0, y: 0, width: root.width, height: root.height, radius: 0 }] : []
        windowWidth: root.width
        windowHeight: root.height
    }

    PrismPanel {
        id: panel
        anchors.fill: parent
        windowed: true
        active: GlobalStates.settingsOverlayOpen
        focus: true
        onCloseRequested: GlobalStates.settingsOverlayOpen = false
        // The yellow light minimizes the window as any app's would; opening Settings again brings it back where it was.
        onMinimizeRequested: if (!root.niriWindow || !MinimizedWindows.minimize(root.niriWindow.id)) GlobalStates.settingsOverlayOpen = false
        onGrowRequested: if (root.niriWindow) {
            NiriService.focusWindow(root.niriWindow.id)
            NiriService.maximizeColumn()
        }
    }
}
