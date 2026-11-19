pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

// A NiHiL panel's window: the focused screen, clear, its glass set in it by the panel. A click on nothing or Escape
// emits `dismissed`. Put the glass's `region` in `blurPieces` so the compositor blurs behind it.
PanelWindow {
    id: root

    required property bool open
    property string namespace: "nihil"
    property list<Region> blurPieces
    property real shown: root.open ? 1 : 0
    default property alias content: stage.data
    signal dismissed()

    screen: GlobalStates.focusedScreen ?? Quickshell.screens[0]
    visible: root.open || root.shown > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:" + root.namespace
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }

    BackgroundEffect.blurRegion: CompositorService.blurRegions && NihilStyle.blur && root.open ? zone : null
    Region { id: zone; regions: root.blurPieces }

    Behavior on shown { NumberAnimation { duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic } }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    Item {
        id: stage
        anchors.fill: parent
        focus: root.open
        opacity: root.shown
        transform: Translate { y: (1 - root.shown) * NihilStyle.s(10) }
        Keys.onEscapePressed: root.dismissed()
    }
}
