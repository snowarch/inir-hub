pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.iris.frame

Variants {
    model: Quickshell.screens

    delegate: Scope {
        id: screenScope
        required property var modelData

        component Reservation: PanelWindow {
            id: stub
            required property string edge
            screen: screenScope.modelData
            visible: true
            color: "transparent"
            WlrLayershell.namespace: "quickshell:iris-reserve-" + stub.edge
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: IrisFrame.reserve(stub.edge)
            // One edge only: opposite-edge anchors lose the exclusive zone.
            anchors {
                top: stub.edge === "top"
                bottom: stub.edge === "bottom"
                left: stub.edge === "left"
                right: stub.edge === "right"
            }
            implicitWidth: 1
            implicitHeight: 1
            mask: Region {}
        }

        Reservation { edge: "top" }
        Reservation { edge: "bottom" }
        Reservation { edge: "left" }
        Reservation { edge: "right" }
    }
}
