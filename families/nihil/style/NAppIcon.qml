import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services

// An app's own icon, found from its id or icon name.
IconImage {
    id: root
    property string appId: ""
    property real size: NihilStyle.s(32)

    implicitSize: root.size
    asynchronous: true
    // A window without an id, or an id no theme knows, shows the generic program icon.
    source: Quickshell.iconPath((root.appId.length > 0 ? AppSearch.guessIcon(root.appId) : "") || "application-x-executable",
        "application-x-executable")
}
