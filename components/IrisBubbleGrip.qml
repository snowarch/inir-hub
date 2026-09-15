pragma ComponentBehavior: Bound

import QtQuick
import qs

// The pointer contract every bubble shares. A click taps; holding (or pulling
// the bubble away) lifts it, and from then on the bubble travels with the
// pointer through GlobalStates.irisBubbleDrag, which the bubble layer draws and
// resolves on release. The press keeps its implicit grab, so the pointer is
// followed past the edges of the surface the bubble lives in.
MouseArea {
    id: root

    property string slot: ""
    property string kind: ""
    property string screenName: ""
    // Screen-local y of the owning surface's top edge (a bottom bar sits low).
    property real screenOffsetY: 0
    readonly property bool lifting: root.lifted
    signal tapped()

    property bool lifted: false
    property point pressScene: Qt.point(0, 0)
    property point lastScene: Qt.point(0, 0)
    // Where the bubble's centre sat when it was pressed, and how far the
    // pointer was from it, so the bubble does not jump to centre on the pointer.
    property point grabOffset: Qt.point(0, 0)

    acceptedButtons: Qt.LeftButton
    preventStealing: true
    cursorShape: root.lifted ? Qt.ClosedHandCursor : Qt.PointingHandCursor

    function toScreen(x: real, y: real): point {
        const p = root.mapToItem(null, x, y)
        return Qt.point(p.x, p.y + root.screenOffsetY)
    }
    function publish(released: bool): void {
        GlobalStates.irisBubbleDrag = {
            slot: root.slot,
            kind: root.kind,
            screen: root.screenName,
            x: root.lastScene.x - root.grabOffset.x,
            y: root.lastScene.y - root.grabOffset.y,
            size: root.width,
            released: released
        }
    }
    function lift(): void {
        if (root.lifted || !root.pressed || root.slot.length === 0) return
        root.lifted = true
        root.publish(false)
    }

    Timer { id: hold; interval: 320; onTriggered: root.lift() }

    onPressed: mouse => {
        root.lifted = false
        root.pressScene = root.toScreen(mouse.x, mouse.y)
        root.lastScene = root.pressScene
        const centre = root.toScreen(root.width / 2, root.height / 2)
        root.grabOffset = Qt.point(root.pressScene.x - centre.x, root.pressScene.y - centre.y)
        hold.restart()
    }
    onPositionChanged: mouse => {
        if (!root.pressed) return
        root.lastScene = root.toScreen(mouse.x, mouse.y)
        if (!root.lifted) {
            // Pulling the bubble away lifts it without waiting for the hold.
            if (Math.hypot(root.lastScene.x - root.pressScene.x, root.lastScene.y - root.pressScene.y) > 10 * (root.width / 40)) root.lift()
            return
        }
        root.publish(false)
    }
    onReleased: {
        hold.stop()
        if (root.lifted) {
            root.lifted = false
            root.publish(true)
        } else {
            root.tapped()
        }
    }
    onCanceled: {
        hold.stop()
        if (root.lifted) {
            root.lifted = false
            root.publish(true)
        }
    }
}
