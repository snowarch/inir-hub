import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.iris.frame
import qs.modules.iris.components
import qs.modules.iris.prism.core

// Prism's host: an overlay on the focused output, a light scrim over the desktop and the panel centred at its
// resting size (or the whole room with the green light). Click outside or Esc puts it away.
PanelWindow {
    id: root
    visible: GlobalStates.settingsOverlayOpen || shown.opacity > 0
    IrisOutputHold {
        id: outputHold
        wanted: GlobalStates.focusedScreen
        live: root.visible
    }
    screen: outputHold.output
    color: "transparent"
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:iris-prism"
    WlrLayershell.layer: GlobalStates.settingsNativeDialogOpen ? WlrLayer.Bottom : WlrLayer.Overlay
    WlrLayershell.keyboardFocus: GlobalStates.settingsNativeDialogOpen || !GlobalStates.settingsOverlayOpen ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

    function close(): void { GlobalStates.settingsOverlayOpen = false }

    PrismRequests { onOpened: panel.forceActiveFocus() }

    Item {
        id: shown
        anchors.fill: parent
        opacity: GlobalStates.settingsOverlayOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.28) // iris-literal: Prism's own fills and scrims, scheme-aware above
            MouseArea { anchors.fill: parent; onClicked: root.close() }
        }

        // The panel's own shadow, cheap and static.
        RectangularShadow {
            anchors.fill: panel
            radius: PrismTheme.dp(28)
            blur: PrismTheme.dp(60)
            offset.y: PrismTheme.dp(20)
            color: Qt.rgba(0, 0, 0, PrismTheme.light ? 0.22 : 0.5) // iris-literal: Prism's own fills and scrims, scheme-aware above
        }

        PrismPanel {
            id: panel
            readonly property real band: IrisFrame.band + PrismTheme.dp(24)
            width: PrismState.wide ? root.width - band * 2 : Math.min(root.width - band * 2, PrismTheme.dp(1280))
            height: PrismState.wide ? root.height - band * 2 : Math.min(root.height - band * 2, PrismTheme.dp(840))
            anchors.centerIn: parent
            scale: GlobalStates.settingsOverlayOpen ? 1 : 0.97
            Behavior on scale { NumberAnimation { duration: PrismTheme.ms(220); easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: PrismTheme.ms(260); easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: PrismTheme.ms(260); easing.type: Easing.OutCubic } }
            active: GlobalStates.settingsOverlayOpen
            focus: true
            onCloseRequested: root.close()
            MouseArea { anchors.fill: parent; z: -1; acceptedButtons: Qt.AllButtons }
        }
    }
}
