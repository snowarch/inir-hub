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

    LazyLoader {
        active: root.opened
        component: FloatingWindow {
            title: Translation.tr("Presets")
            visible: true
            color: InkSkin.page
            implicitWidth: Math.round(InkSkin.body * 72 * InkSkin.d)
            implicitHeight: Math.round(InkSkin.body * 42 * InkSkin.d)
            minimumSize: Qt.size(Math.round(InkSkin.body * 24), Math.round(InkSkin.body * 24))
            onClosed: root.opened = false
            PresetsBody {
                anchors.fill: parent
                requestedName: root.pendingApply
                onRequestHandled: root.pendingApply = ""
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
