pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common

// A NiHiL panel's window: the whole focused screen, clear, its pieces set in it by the panel. A click on nothing or
// Escape closes it (`dismissed`); the pieces rise from the bar's edge as it opens and sink back as it closes.
PanelWindow {
    id: root

    required property bool open
    property string namespace: "nihil"
    readonly property bool barBottom: Config.options?.nihil?.bar?.bottom ?? true
    // Where the panel's pieces may stand: the screen less the bar's room.
    readonly property real edgeTop: root.barBottom ? NihilStyle.edge : NihilStyle.barZone
    readonly property real edgeBottom: root.barBottom ? NihilStyle.barZone : NihilStyle.edge
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

    Behavior on shown { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    Item {
        id: stage
        anchors.fill: parent
        focus: root.open
        opacity: root.shown
        transform: Translate { y: (1 - root.shown) * NihilStyle.s(14) * (root.barBottom ? 1 : -1) }
        Keys.onEscapePressed: root.dismissed()
    }
}
