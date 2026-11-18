pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common

// A request for a password from the system: built only while one is open, on the screen in use when it came.
Scope {
    id: root

    property var targetScreen: null

    Connections {
        target: PolkitService
        function onActiveChanged(): void {
            root.targetScreen = PolkitService.active ? GlobalStates.focusedScreen : null
        }
    }

    Loader {
        active: PolkitService.active
        sourceComponent: PanelWindow {
            screen: root.targetScreen ?? GlobalStates.focusedScreen ?? Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:polkit"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            NihilPolkitCard { anchors.fill: parent }
        }
    }
}
