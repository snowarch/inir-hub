pragma ComponentBehavior: Bound

// A component's own surface: the shell loads this file while the active family is one plugin.json's "families" names
// (every family when the list is empty). It sits beside the family and never edits it. Keep this shape:
//   - one window, created only while open (nothing runs while it is closed);
//   - an IpcHandler whose target is the component's id with a toggle: the app launcher of every family lists it by
//     its name and opens it with `inir <id> toggle` (a keybind or another surface can too);
//   - colours, corners and type from the shell's tokens, so the person's theme reaches it;
//   - its own options in its own file (Directories.pluginFile), never in the person's settings.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: root

    property bool open: false

    // Options the person changes live in this file; removing the component leaves their settings as they were.
    FileView {
        path: Directories.pluginFile("__ID__")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }
        JsonAdapter {
            id: options
            property string greeting: "Hello"
        }
    }

    LazyLoader {
        active: root.open
        PanelWindow {
            WlrLayershell.namespace: "quickshell:__ID__"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            implicitWidth: card.implicitWidth
            implicitHeight: card.implicitHeight

            Rectangle {
                id: card
                anchors.fill: parent
                implicitWidth: column.implicitWidth + 48
                implicitHeight: column.implicitHeight + 40
                radius: Appearance.rounding.large
                color: Appearance.colors.colLayer1
                focus: true
                Keys.onEscapePressed: root.open = false

                ColumnLayout {
                    id: column
                    anchors.centerIn: parent
                    spacing: 8
                    StyledText {
                        text: Translation.tr("%1 from __NAME__").arg(options.greeting)
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.title
                    }
                }
            }
        }
    }

    /// __NAME__: open or close it.
    ///
    /// ```kdl
    /// Mod+Shift+P { spawn "inir" "__ID__" "toggle"; }
    /// ```
    IpcHandler {
        target: "__ID__"
        /// Open or close it
        function toggle(): void { root.open = !root.open }
        /// Close it
        function close(): void { root.open = false }
    }
}
