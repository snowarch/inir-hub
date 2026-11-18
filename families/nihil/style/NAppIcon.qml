import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services

// An app's own icon, found from its id or icon name.
IconImage {
    property string appId: ""
    property real size: NihilStyle.s(32)

    implicitSize: size
    asynchronous: true
    source: Quickshell.iconPath(AppSearch.guessIcon(appId), "application-x-executable")
}
