import QtQuick

// A level set by hand. Also the shell's scrubber (part control.scrubber): `moved` follows the hand, `seekRequested` is
// where it let go.
Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0.05
    property bool knob: true
    property color fillColor: NihilStyle.accent
    property string name: ""
    signal moved(real value)
    signal seekRequested(real value)

    readonly property real span: Math.max(0.0001, root.to - root.from)
    readonly property real share: NihilStyle.clamp((root.value - root.from) / root.span, 0, 1)
    property real _held: 0
    readonly property real shown: hand.pressed ? root._held : root.share
    readonly property real side: NihilStyle.s(16)

    implicitWidth: NihilStyle.s(190)
    implicitHeight: NihilStyle.s(24)
    activeFocusOnTab: true
    Accessible.role: Accessible.Slider
    Accessible.name: root.name

    function snap(next: real): real {
        const stepped = root.stepSize > 0 ? Math.round((next - root.from) / root.stepSize) * root.stepSize + root.from : next
        return NihilStyle.clamp(Number(stepped.toFixed(4)), root.from, root.to)
    }
    function held(px: real): real {
        const share = NihilStyle.clamp((px - root.side / 2) / Math.max(1, root.width - root.side), 0, 1)
        const next = root.snap(root.from + share * root.span)
        root._held = (next - root.from) / root.span
        root.moved(next)
        return next
    }
    function nudge(steps: int): void {
        const next = root.snap(root.value + steps * (root.stepSize > 0 ? root.stepSize : root.span / 20))
        root.moved(next)
        root.seekRequested(next)
    }
    Keys.onLeftPressed: root.nudge(-1)
    Keys.onDownPressed: root.nudge(-1)
    Keys.onRightPressed: root.nudge(1)
    Keys.onUpPressed: root.nudge(1)

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: NihilStyle.s(4)
        radius: height / 2
        color: NihilStyle.pieceRaised
        Rectangle {
            width: root.side / 2 + root.shown * (root.width - root.side)
            height: parent.height
            radius: parent.radius
            color: root.fillColor
        }
    }

    Rectangle {
        visible: root.knob
        anchors.verticalCenter: parent.verticalCenter
        x: root.shown * (root.width - width)
        width: root.side
        height: root.side
        radius: width / 2
        color: NihilStyle.ink
        scale: hand.pressed ? 1.18 : 1
        Behavior on scale { NumberAnimation { duration: NihilStyle.quick } }
    }

    MouseArea {
        id: hand
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        property real last: 0
        onPressed: event => hand.last = root.held(event.x)
        onPositionChanged: event => { if (hand.pressed) hand.last = root.held(event.x) }
        onReleased: root.seekRequested(hand.last)
        onWheel: event => root.nudge(event.angleDelta.y > 0 ? 1 : -1)
    }
}
