pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    required property Component contentComponent
    property var targetScreen: null

    Connections {
        target: PolkitService
        function onActiveChanged(): void {
            if (PolkitService.active)
                root.targetScreen = GlobalStates.focusedScreen
            else
                root.targetScreen = null
        }
    }

    Loader {
        active: PolkitService.active
        sourceComponent: PanelWindow {
            id: panelWindow
            screen: root.targetScreen ?? GlobalStates.focusedScreen

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"
            WlrLayershell.namespace: "quickshell:polkit"
            // An auth prompt takes the keys at once; every shell surface that holds them gives them up meanwhile.
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore

            Loader {
                anchors.fill: parent
                // A Loader is a focus scope: without focus its content's field never holds the keys.
                focus: true
                sourceComponent: root.contentComponent
            }
        }
    }
}
