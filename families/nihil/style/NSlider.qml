import QtQuick

// A level set by hand on a line of dots: lit up to the value, the knob standing on it. Drag, wheel or arrow keys.
// `moved` follows the hand, `seekRequested` is the value it let go on. The shell's own scrubber too (part
// control.scrubber: `value` from 0 to 1, `knob`, `fillColor`, `stepSize`).
Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0.05
    property bool knob: true
    property color fillColor: NihilStyle.litLevel
    property string name: ""
    signal moved(real value)
    signal seekRequested(real value)

    readonly property real span: Math.max(0.0001, root.to - root.from)
    readonly property real share: NihilStyle.clamp((root.value - root.from) / root.span, 0, 1)
    property real _held: 0
    readonly property real shown: hand.pressed ? root._held : root.share
    readonly property real side: NihilStyle.s(18)

    implicitWidth: NihilStyle.s(190)
    implicitHeight: NihilStyle.s(26)
    activeFocusOnTab: true
    Accessible.role: Accessible.Slider
    Accessible.name: root.name

    function snap(next: real): real {
        const step = root.stepSize > 0 ? Math.round((next - root.from) / root.stepSize) * root.stepSize + root.from : next
        return NihilStyle.clamp(Number(step.toFixed(4)), root.from, root.to)
    }
    function held(px: real): real {
        const next = root.snap(root.from + NihilStyle.clamp((px - root.side / 2) / Math.max(1, root.width - root.side), 0, 1) * root.span)
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

    Canvas {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: NihilStyle.s(6)
        renderStrategy: Canvas.Cooperative
        readonly property real at: root.shown
        readonly property color lit: root.fillColor
        readonly property color off: NihilStyle.dotOff
        readonly property bool squareDots: NihilStyle.squareDots
        onAtChanged: requestPaint()
        onLitChanged: requestPaint()
        onOffChanged: requestPaint()
        onSquareDotsChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const dot = height * 0.7
            const count = Math.max(2, Math.floor(width / (height * 1.5)))
            const pitch = (width - dot) / (count - 1)
            for (let i = 0; i < count; ++i) {
                const cx = dot / 2 + i * pitch
                ctx.fillStyle = cx <= root.side / 2 + track.at * (width - root.side) ? track.lit : track.off
                ctx.beginPath()
                if (track.squareDots) ctx.rect(cx - dot / 2, height / 2 - dot / 2, dot, dot)
                else ctx.arc(cx, height / 2, dot / 2, 0, Math.PI * 2)
                ctx.fill()
            }
        }
    }

    Rectangle {
        visible: root.knob
        anchors.verticalCenter: parent.verticalCenter
        x: root.shown * (root.width - width)
        width: root.side
        height: root.side
        radius: NihilStyle.keyRadius(width, height, false)
        color: root.fillColor
        scale: hand.pressed ? 1.16 : 1
        Behavior on x { enabled: !hand.pressed; NumberAnimation { duration: NihilStyle.quick; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: NihilStyle.quick } }
        NFocus { shown: root.activeFocus }
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
