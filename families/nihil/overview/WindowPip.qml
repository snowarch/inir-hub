pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// A window pinned as a floating thumbnail: drag to move, wheel to resize, click to go to it.
PanelWindow {
    id: root

    required property var modelData
    property real side: NihilStyle.s(340)
    readonly property var win: (NiriService.windows ?? []).find(item => item.id === root.modelData.id) ?? null
    readonly property real aspect: (root.win?.layout?.window_size?.[0] ?? 16) / Math.max(1, root.win?.layout?.window_size?.[1] ?? 10)

    screen: GlobalStates.focusedScreen ?? Quickshell.screens[0]
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:nihil-pip"
    anchors { right: true; bottom: true }
    margins { right: NihilStyle.s(24) - offset.x; bottom: NihilStyle.s(24) - offset.y }
    implicitWidth: root.side
    implicitHeight: Math.round(root.side / root.aspect)

    property point offset: Qt.point(0, 0)
    onWinChanged: if (!root.win) NihilState.unpin(root.modelData.id)

    NGlass {
        anchors.fill: parent
        radius: NihilStyle.radiusCard
        followPointer: true
    }
    WindowShot {
        anchors.fill: parent
        anchors.margins: NihilStyle.s(3)
        radius: NihilStyle.radiusCard - NihilStyle.s(3)
        windowId: root.modelData.id
        appId: root.modelData.appId ?? ""
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.SizeAllCursor
        property point grab
        property bool moved: false
        onPressed: mouse => { grab = Qt.point(mouse.x, mouse.y); moved = false }
        onPositionChanged: mouse => {
            moved = true
            root.offset = Qt.point(root.offset.x + mouse.x - grab.x, root.offset.y + mouse.y - grab.y)
        }
        onClicked: if (!moved) NiriService.focusWindow(root.modelData.id)
        onWheel: wheel => root.side = NihilStyle.clamp(root.side + (wheel.angleDelta.y > 0 ? 24 : -24), NihilStyle.s(180), NihilStyle.s(900))
    }
    NButton {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: NihilStyle.s(6)
        width: NihilStyle.s(26)
        height: NihilStyle.s(26)
        radius: height / 2
        tone: NihilStyle.scrim
        icon: "close"
        iconSize: NihilStyle.s(13)
        Accessible.name: Translation.tr("Unpin thumbnail")
        onClicked: NihilState.unpin(root.modelData.id)
    }
}
