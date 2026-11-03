pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.iris.frame
import qs.modules.iris.components
import qs.modules.iris.field as Field

// A Corner over the desktop, as Settings' overlay host (settings/IrisSettingsOverlay.qml): on the output in focus, the
// whole screen listening while it is open so a click outside closes it. `body` is the Corner (an IrisCornerBody).
PanelWindow {
    id: root
    property bool open: false
    property string namespace: "quickshell:iris-corner"
    required property Item body
    readonly property Item frame: root.body?.frame ?? null
    onBodyChanged: if (root.body) { root.body.parent = root.contentItem; root.body.anchors.fill = root.contentItem }
    visible: root.open || (root.frame?.progress ?? 0) > 0
    IrisOutputHold {
        id: outputHold
        wanted: GlobalStates.focusedScreen
        live: root.visible
    }
    screen: outputHold.output
    color: "transparent"
    anchors { left: true; right: true; top: true; bottom: true }
    margins { left: IrisFrame.band; right: IrisFrame.band; top: IrisFrame.band; bottom: IrisFrame.band }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: root.namespace
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // Open, the whole screen listens so a click outside closes it; closing, only the body still drawn does.
    mask: root.open ? null : bodyRegion
    Region { id: bodyRegion; item: root.frame }
    Field.IrisBlurRegion {
        window: root
        shapes: root.frame?.blurShapes ?? []
        windowWidth: root.width
        windowHeight: root.height
    }
}
