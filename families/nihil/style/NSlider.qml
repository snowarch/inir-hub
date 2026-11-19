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
    readonly property bool lightFill: Qt.colorEqual(root.fillColor, NihilStyle.accent)
    property string name: ""
    signal moved(real value)
    signal seekRequested(real value)

    readonly property real span: Math.max(0.0001, root.to - root.from)
    readonly property real share: NihilStyle.clamp((root.value - root.from) / root.span, 0, 1)
    property real _held: 0
    readonly property real shown: hand.pressed ? root._held : root.share
    readonly property real side: 0

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

    // The level on a ruler, a needle of light where it stands.
    ShaderEffect {
        anchors.fill: parent
        readonly property size box: Qt.size(width, height)
        readonly property real level: root.shown
        readonly property real cell: NihilStyle.s(5.5) + 0.5
        readonly property real needle: root.knob ? 1 : 0
        readonly property color mark: Qt.alpha(NihilStyle.ink, 0.22)
        readonly property color specA: root.lightFill ? NihilStyle.specA : root.fillColor
        readonly property color specB: root.lightFill ? NihilStyle.specB : root.fillColor
        readonly property color needleInk: NihilStyle.ink
        fragmentShader: Qt.resolvedUrl("ruler.frag.qsb")
    }

    MouseArea {
        id: hand
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        property real last: 0
        onPressed: event => hand.last = root.held(event.x)
        onPositionChanged: event => { if (hand.pressed) hand.last = root.held(event.x) }
        onReleased: root.seekRequested(hand.last)
        onWheel: event => root.nudge(event.angleDelta.y > 0 ? 1 : -1)
    }
}
