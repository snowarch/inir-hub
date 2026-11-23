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
    property bool startWithNew: false

    LazyLoader {
        active: root.opened
        component: FloatingWindow {
            id: window
            title: Translation.tr("Ink Notes")
            visible: true
            color: InkSkin.page
            implicitWidth: Math.round(InkSkin.body * 66 * InkSkin.d)
            implicitHeight: Math.round(InkSkin.body * 42 * InkSkin.d)
            minimumSize: Qt.size(Math.round(InkSkin.body * 24), Math.round(InkSkin.body * 22))
            onClosed: root.opened = false
            InkBody {
                anchors.fill: parent
                startWithNew: root.startWithNew
                onCloseRequested: root.opened = false
                Component.onCompleted: root.startWithNew = false
            }
        }
    }

    /// Ink Notes: Markdown notes in plain files.
    ///
    /// ```kdl
    /// Mod+Shift+N { spawn "inir" "inknotes" "toggle"; }
    /// ```
    IpcHandler {
        target: "inknotes"
        /// Open the window, or close it when it is open
        function toggle(): void { root.opened = !root.opened }
        /// Open the window
        function open(): void { root.opened = true }
        /// Close the window, saving the open note first
        function close(): void { root.opened = false }
        /// Open the window with a new note ready to type in
        function newNote(): void { root.startWithNew = true; root.opened = true }
    }
}
