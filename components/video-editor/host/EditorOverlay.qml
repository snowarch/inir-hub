// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.iris.frame
import qs.modules.iris.components
import "../controls"

PanelWindow {
    id: root
    property bool open: false
    required property EditorBody body
    readonly property Item frame: root.body?.frame ?? null
    readonly property real band: EditorSkin.iris ? IrisFrame.band : 0
    onBodyChanged: if (root.body) { root.body.parent = root.contentItem; root.body.anchors.fill = root.contentItem; }
    visible: root.open || (root.frame?.progress ?? 0) > 0
    IrisOutputHold {
        id: outputHold
        wanted: GlobalStates.focusedScreen
        live: root.visible
    }
    screen: outputHold.output
    color: "transparent" // literal: no paint outside the overlay frame
    anchors { left: true; right: true; top: true; bottom: true }
    margins { left: root.band; right: root.band; top: root.band; bottom: root.band }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:video-editor"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open && !root.body?.dialogOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: root.open ? null : bodyRegion
    Region { id: bodyRegion; item: root.frame }
}
