import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.iris.frame
import qs.modules.iris.components
import qs.modules.iris.style
import qs.modules.iris.field as Field
import qs.modules.iris.prism.core
import qs.services

// Prism's host: an overlay on the focused output, a light scrim over the desktop and the panel centred at its
// resting size (or the whole room with the green light). Click outside or Esc puts it away. Its material is iRiS's
// glass: under Blur the compositor blurs the panel's shape (Niri: this region; Umbriel: its layer rule, so the scrim
// and the shadow stay under its alpha threshold), under Glass the wallpaper is blurred inside it.
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
    WlrLayershell.keyboardFocus: PolkitService.active ? WlrKeyboardFocus.None : GlobalStates.settingsNativeDialogOpen || !GlobalStates.settingsOverlayOpen ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

    function close(): void { GlobalStates.settingsOverlayOpen = false }

    PrismRequests { onOpened: panel.forceActiveFocus() }

    // A blurred body only changes size, never fades (iRiS's rule): under Blur the panel opens by its scale alone and
    // the region follows it; closing, the blur leaves at once and the veil fades out over the desktop.
    Field.IrisBlurRegion {
        window: root
        shapes: GlobalStates.settingsOverlayOpen && PrismTheme.glassBlur ? [{
            x: panel.x + panel.width * (1 - panel.scale) / 2, y: panel.y + panel.height * (1 - panel.scale) / 2,
            width: panel.width * panel.scale, height: panel.height * panel.scale, radius: PrismTheme.corner * panel.scale }] : []
        windowWidth: root.width
        windowHeight: root.height
    }
    // Under Glass: the wallpaper, blurred once for this window while Settings shows.
    Loader {
        id: glassLoader
        active: root.visible && PrismTheme.glassWallpaper
        sourceComponent: Field.IrisGlassSource { screen: root.screen }
    }

    Item {
        id: shown
        anchors.fill: parent
        opacity: GlobalStates.settingsOverlayOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(160 / PrismTheme.openSpeed); easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, Math.min(IrisStyle.shadowCeiling, 0.28)) // iris-literal: Prism's own scrim, under Umbriel's blur threshold
            MouseArea { anchors.fill: parent; onClicked: root.close() }
        }
    }

    // The panel's own shadow, cheap and static.
    RectangularShadow {
        anchors.fill: panel
        opacity: panel.opacity
        radius: PrismTheme.corner
        blur: PrismTheme.dp(60)
        offset.y: PrismTheme.dp(20)
        color: Qt.rgba(0, 0, 0, Math.min(IrisStyle.shadowCeiling, PrismTheme.light ? 0.22 : 0.5)) // iris-literal: Prism's own shadow, under Umbriel's blur threshold
    }

    PrismPanel {
        id: panel
        readonly property real band: IrisFrame.band + PrismTheme.room(24)
        width: PrismState.wide ? root.width - band * 2 : Math.min(root.width - band * 2, PrismTheme.restWidth(root.width))
        height: PrismState.wide ? root.height - band * 2 : Math.min(root.height - band * 2, PrismTheme.restHeight(root.height))
        // Centred on whole pixels: a half-pixel place would resample every layer inside it (the glass, the list's fade).
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        opacity: PrismTheme.glassBlur && GlobalStates.settingsOverlayOpen ? 1 : shown.opacity
        scale: GlobalStates.settingsOverlayOpen ? 1 : 0.97
        Behavior on scale { NumberAnimation { duration: PrismTheme.ms(220 / PrismTheme.openSpeed); easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: PrismTheme.ms(260 / PrismTheme.openSpeed); easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: PrismTheme.ms(260 / PrismTheme.openSpeed); easing.type: Easing.OutCubic } }
        active: GlobalStates.settingsOverlayOpen
        backdrop: glassLoader.item?.ready ? glassLoader.item.texture : null
        screenAt: Qt.point(panel.x, panel.y)
        focus: true
        onCloseRequested: root.close()
        MouseArea { anchors.fill: parent; z: -1; acceptedButtons: Qt.AllButtons }
    }
}
