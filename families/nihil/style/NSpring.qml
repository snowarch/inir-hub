import QtQuick

// A value that follows `to` as a critically damped spring: it takes up a new target from the speed it has and never
// passes it. Runs only while it is moving; `NihilStyle.motion` sets its pace and 0 makes it jump.
Item {
    id: root

    property real to: 0
    // How quick it is, in radians per second.
    property real pace: 16
    property real value: root.to
    property real velocity: 0
    property bool moving: false
    // Takes a new target at once: for a body that is still folded away.
    property bool snap: false
    readonly property real omega: NihilStyle.motion > 0 ? root.pace / NihilStyle.motion : 0

    visible: false
    width: 0
    height: 0

    function jump(): void {
        root.moving = false
        root.velocity = 0
        root.value = root.to
    }
    onToChanged: {
        if (root.snap || root.omega <= 0) root.jump()
        else root.moving = true
    }

    FrameAnimation {
        running: root.moving
        onTriggered: {
            const dt = Math.min(frameTime, 0.05)
            const offset = root.value - root.to
            const decay = Math.exp(-root.omega * dt)
            const carry = (root.velocity + root.omega * offset) * dt
            const next = (offset + carry) * decay
            root.velocity = (root.velocity - carry * root.omega) * decay
            if (Math.abs(next) < 0.05 && Math.abs(root.velocity) < 0.5) root.jump()
            else root.value = root.to + next
        }
    }
}
