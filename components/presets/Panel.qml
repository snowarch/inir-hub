pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "skin"
import "views"

Scope {
    id: root
    property bool opened: false
    property string pendingApply: ""

    // Cleared on the next turn: clearing inside the change that delivered the name loops the binding.
    Timer { id: clearRequest; interval: 0; onTriggered: root.pendingApply = "" }

    LazyLoader {
        active: root.opened
        component: FloatingWindow {
            title: Translation.tr("Presets")
            visible: true
            color: PrSkin.page
            implicitWidth: Math.round(PrSkin.body * 72)
            implicitHeight: Math.round(PrSkin.body * 42)
            minimumSize: Qt.size(Math.round(PrSkin.body * 24), Math.round(PrSkin.body * 24))
            onClosed: root.opened = false
            PresetsBody {
                anchors.fill: parent
                requestedName: root.pendingApply
                onRequestHandled: clearRequest.restart()
                onCloseRequested: root.opened = false
            }
        }
    }

    /// Presets: save the look of the desktop and apply it again.
    ///
    /// ```kdl
    /// Mod+Shift+P { spawn "inir" "presets" "toggle"; }
    /// ```
    IpcHandler {
        target: "presets"
        /// Open the window, or close it when it is open
        function toggle(): void { root.opened = !root.opened }
        /// Open the window
        function open(): void { root.opened = true }
        /// Close the window
        function close(): void { root.opened = false }
        /// Open the window and apply the preset with this name
        function apply(name: string): void { root.pendingApply = name; root.opened = true }
    }
}
