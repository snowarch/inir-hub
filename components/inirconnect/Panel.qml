pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.iris.frame
import qs.modules.iris.components
import "state"
import "views"

Scope {
    id: root

    readonly property string activeFamily: Plugins.active
    readonly property bool windowed: AndroidState.windowed

    LazyLoader {
        active: !root.windowed

        PanelWindow {
            id: overlayWin
            readonly property Item viewItem: overlayLoader.item
            readonly property Item frame: viewItem?.frame ?? null
            visible: AndroidState.open || (overlayWin.frame?.progress ?? 0) > 0
            IrisOutputHold {
                id: outputHold
                wanted: GlobalStates.focusedScreen
                live: overlayWin.visible
            }
            screen: outputHold.output
            color: "transparent"
            anchors { left: true; right: true; top: true; bottom: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:inirconnect"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: AndroidState.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            mask: (AndroidState.open && AndroidState.pinned) ? bodyRegion : (AndroidState.open ? null : bodyRegion)
            Region { id: bodyRegion; item: overlayWin.frame }

            Loader {
                id: overlayLoader
                anchors.fill: parent
                sourceComponent: {
                    if (root.activeFamily === "iris") return irisOverlayComp
                    if (root.activeFamily === "waffle") return waffleOverlayComp
                    return materialOverlayComp
                }
            }
        }
    }

    LazyLoader {
        active: root.windowed

        FloatingWindow {
            id: floatWin
            title: "iNiR AndroidConnect"
            Binding { target: floatWin; property: "visible"; value: AndroidState.open }
            color: ConnectStyle.surface

            readonly property Item viewItem: windowLoader.item
            readonly property real contentW: Math.round((AndroidState.verticalLayout ? 440 : 640) * ConnectStyle.density)
            readonly property real contentH: {
                const baseH = AndroidState.verticalLayout ? 680 : 440
                const natural = Math.round(viewItem?.implicitHeight ?? 0)
                const minH = Math.round((AndroidState.verticalLayout ? 580 : 420) * ConnectStyle.density)
                return Math.max(minH, natural > 0 ? natural : Math.round(baseH * ConnectStyle.density))
            }

            implicitWidth: floatWin.contentW
            implicitHeight: floatWin.contentH
            minimumSize: Qt.size(Math.round(360 * ConnectStyle.density), Math.round(340 * ConnectStyle.density))
            onClosed: AndroidState.open = false

            readonly property var niriWindow: (NiriService.windows ?? []).find(w => w.title === floatWin.title && w.pid === Quickshell.processId) ?? null
            property bool configuredOnce: false

            Timer {
                id: syncTimer
                interval: 20
                repeat: false
                onTriggered: floatWin.doSyncNiri()
            }

            function syncNiri(): void {
                syncTimer.restart()
            }

            function doSyncNiri(): void {
                const win = floatWin.niriWindow ?? (NiriService.windows ?? []).find(w => w.title === floatWin.title)
                if (!win) {
                    syncTimer.restart()
                    return
                }
                const wid = String(win.id)
                const w = String(Math.round(floatWin.contentW))
                const h = String(Math.round(floatWin.contentH))
                if (!win.isFloating) {
                    Quickshell.execDetached(["niri", "msg", "action", "move-window-to-floating", "--id", wid])
                }
                Quickshell.execDetached(["niri", "msg", "action", "set-window-width", "--id", wid, w])
                Quickshell.execDetached(["niri", "msg", "action", "set-window-height", "--id", wid, h])
            }

            onContentHChanged: if (AndroidState.open) floatWin.syncNiri()
            onContentWChanged: if (AndroidState.open) floatWin.syncNiri()

            onNiriWindowChanged: if (floatWin.niriWindow && !floatWin.configuredOnce) {
                floatWin.configuredOnce = true
                NiriService.focusWindow(floatWin.niriWindow.id)
                floatWin.syncNiri()
            }
            onVisibleChanged: if (!floatWin.visible) floatWin.configuredOnce = false

            Loader {
                id: windowLoader
                anchors.fill: parent
                sourceComponent: {
                    if (root.activeFamily === "iris") return irisWindowComp
                    if (root.activeFamily === "waffle") return waffleWindowComp
                    return materialWindowComp
                }
            }
        }
    }

    Component { id: irisOverlayComp; IrisView { open: AndroidState.open; windowed: false } }
    Component { id: materialOverlayComp; MaterialView { open: AndroidState.open; windowed: false } }
    Component { id: waffleOverlayComp; WaffleView { open: AndroidState.open; windowed: false } }

    Component { id: irisWindowComp; IrisView { open: AndroidState.open; windowed: true } }
    Component { id: materialWindowComp; MaterialView { open: AndroidState.open; windowed: true } }
    Component { id: waffleWindowComp; WaffleView { open: AndroidState.open; windowed: true } }

    /// The Android companion panel: live status, quick actions, and screen mirroring.
    ///
    /// ```kdl
    /// Mod+A { spawn "inir" "inirconnect" "toggle"; }
    /// ```
    IpcHandler {
        target: "inirconnect"
        /// Open or close the Android companion panel
        function toggle(): void { AndroidState.open = !AndroidState.open }
        /// Open the Android companion panel
        function open(): void { AndroidState.open = true }
        /// Close the Android companion panel
        function close(): void { AndroidState.open = false }
        /// Refresh connected ADB and KDE Connect devices
        function refresh(): void { AndroidState.refresh() }
        /// Launch phone screen mirror via scrcpy
        function mirror(): void { AndroidState.openScrcpyWindow() }
        /// Toggle between horizontal and vertical card layouts
        function layout(): void { AndroidState.verticalLayout = !AndroidState.verticalLayout }
        /// Toggle between overlay surface and floating Wayland window mode
        function windowed(): void { AndroidState.windowed = !AndroidState.windowed }
        /// Toggle keeping the overlay panel pinned
        function pin(): void { AndroidState.pinned = !AndroidState.pinned }
        /// Toggle a specific subsheet (wireless, notifications, devices)
        function sheet(name: string): void { AndroidState.toggleSheet(name) }
    }
}
