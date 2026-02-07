import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property Component regionComponent: Component {
        Region {}
    }

    // Capture target screen when opening (don't follow focus while open)
    property var targetScreen: null

    Connections {
        target: GlobalStates
        function onOverlayOpenChanged() {
            if (GlobalStates.overlayOpen) {
                // Set target screen when opening for use by Component.onCompleted
                const outputName = NiriService.currentOutput
                root.targetScreen = Quickshell.screens.find(s => s.name === outputName) ?? Quickshell.screens[0] ?? null
            }
        }
    }
    
    Loader {
        id: overlayLoader
        active: GlobalStates.overlayOpen
        sourceComponent: PanelWindow {
            id: overlayWindow
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:overlay"
            WlrLayershell.layer: WlrLayer.Overlay
            // Use OnDemand for pinned widgets, but disable during GameMode to avoid input capture
            WlrLayershell.keyboardFocus: GlobalStates.overlayOpen 
                ? WlrKeyboardFocus.Exclusive 
                : (OverlayContext.clickableWidgets.length > 0 && !GameMode.active 
                    ? WlrKeyboardFocus.OnDemand 
                    : WlrKeyboardFocus.None)
            color: "transparent"

            mask: Region {
                item: GlobalStates.overlayOpen ? overlayContent : null
                regions: OverlayContext.clickableWidgets.map((widget) => regionComponent.createObject(this, {
                    item: widget
                }));
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            CompositorFocusGrab {
                id: grab
                windows: [overlayWindow]
                active: false
                onCleared: () => {
                    if (!active) GlobalStates.overlayOpen = false;
                }
            }

            Connections {
                target: GlobalStates
                function onOverlayOpenChanged() {
                    delayedGrabTimer.restart()
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: Config.options.overlay.animationDurationMs ?? Appearance.animation.elementMoveFast.duration
                onTriggered: {
                    grab.active = GlobalStates.overlayOpen;
                }
            }

            OverlayContent {
                id: overlayContent
                anchors.fill: parent
            }
        }
    }

    IpcHandler {
        target: "overlay"

        function toggle(): void {
            GlobalStates.overlayOpen = !GlobalStates.overlayOpen;
        }
    }

    Loader {
        active: CompositorService.isHyprland
        sourceComponent: Item {
            GlobalShortcut {
                name: "overlayToggle"
                description: "Toggles overlay on press"

                onPressed: {
                    GlobalStates.overlayOpen = !GlobalStates.overlayOpen;
                }
            }
        }
    }
}
