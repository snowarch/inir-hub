pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The screen's workspaces as a sequencer's steps: the one in use a lit bar, those holding windows full, the empty ones
// faint. A tap goes to one, the wheel walks them.
NButton {
    id: root

    required property var screen
    readonly property var spaces: (NiriService.allWorkspaces ?? [])
        .filter(space => !root.screen || space.output === root.screen.name)
        .sort((a, b) => a.idx - b.idx)
    readonly property real dot: NihilStyle.s(9)
    readonly property real step: NihilStyle.s(6)

    width: dots.implicitWidth + NihilStyle.s(28)
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => event.angleDelta.y > 0 ? NiriService.focusWorkspaceUp() : NiriService.focusWorkspaceDown()
    }

    Row {
        id: dots
        anchors.centerIn: parent
        spacing: root.step
        Repeater {
            model: root.spaces
            delegate: Rectangle {
                id: space
                required property var modelData
                readonly property bool current: space.modelData.is_active
                readonly property bool held: space.modelData.active_window_id !== null && space.modelData.active_window_id !== undefined
                anchors.verticalCenter: parent.verticalCenter
                width: space.current ? root.dot * 2.6 : root.dot
                height: space.current ? root.dot * 2.2 : root.dot
                radius: space.current ? NihilStyle.s(4) : height / 2
                color: space.current ? NihilStyle.accent : NihilStyle.ink
                opacity: space.current || space.held ? 1 : 0.26
                Behavior on width { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -root.step / 2
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NiriService.switchToWorkspaceById(space.modelData.id)
                }
            }
        }
    }
}
