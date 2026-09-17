pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.iris.components
import qs.modules.iris.style

Scope {
    id: root
    required property string side
    readonly property bool left: root.side === "left"
    readonly property var options: Config.options?.iris?.sidebars?.[root.side] ?? ({})
    readonly property bool enabled: (root.options.enable ?? true) && (root.options.hoverReveal ?? false)
    readonly property bool panelOpen: root.left ? GlobalStates.sidebarLeftOpen : GlobalStates.sidebarRightOpen

    PanelWindow {
        id: reserve
        readonly property string outputName: root.left ? GlobalStates.sidebarLeftTargetOutput : GlobalStates.sidebarRightTargetOutput
        readonly property real d: IrisStyle.density
        // Holds its output while mapped: moving it resizes tiled windows on both outputs.
        IrisOutputHold {
            id: reserveHold
            wanted: Quickshell.screens.find(s => s.name === reserve.outputName) ?? GlobalStates.focusedScreen
            live: reserve.visible
        }
        screen: reserveHold.output
        visible: (root.options.enable ?? true) && (root.options.pinned ?? false) && root.panelOpen && !GlobalStates.screenLocked
        color: "transparent"
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: Math.round(Math.max(300, Math.min(600, Number(root.options.width ?? 380))) * d)
            + ((root.options.notch ?? false) ? 0 : Math.round(24 * d))
        WlrLayershell.namespace: "quickshell:iris-sidebar-reserve-" + root.side
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        anchors { left: root.left; right: !root.left; top: true; bottom: true }
        implicitWidth: 1
        Item { id: noInput; width: 0; height: 0 }
        mask: Region { item: noInput }
    }

    Variants {
        model: root.enabled ? Quickshell.screens : []
        PanelWindow {
            id: strip
            required property var modelData
            screen: modelData
            visible: !root.panelOpen && !GlobalStates.screenLocked && !GlobalStates.widgetEditMode
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:iris-sidebar-edge-" + root.side
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors { left: root.left; right: !root.left; top: true; bottom: true }
            implicitWidth: 1

            HoverHandler { id: edgeHover }
            Timer {
                interval: 140
                running: edgeHover.hovered
                onTriggered: {
                    GlobalStates.irisSidebarPeek = root.side
                    if (root.left) GlobalStates.openSidebarLeft(strip.modelData?.name ?? "")
                    else GlobalStates.openSidebarRight(strip.modelData?.name ?? "")
                }
            }
        }
    }
}
