pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The screen's workspaces as dots on one pill: the one in use a long lit bar, the others full or faint by whether
// they hold windows. A tap goes to one, the wheel walks them.
NButton {
    id: root

    required property var screen
    readonly property var spaces: (NiriService.allWorkspaces ?? [])
        .filter(space => !root.screen || space.output === root.screen.name)
        .sort((a, b) => a.idx - b.idx)
    readonly property real dot: NihilStyle.s(8)
    readonly property real step: NihilStyle.s(10)

    width: dots.implicitWidth + NihilStyle.s(36)
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
                width: space.current ? root.dot * 3 : root.dot
                height: root.dot
                radius: height / 2
                color: space.current ? NihilStyle.accent : NihilStyle.ink
                opacity: space.current || space.held ? 1 : 0.28
                Behavior on width { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
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
