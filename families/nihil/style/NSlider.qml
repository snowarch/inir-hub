import QtQuick

// A level set by hand: a pill of ticks that the light fills, with a grip at its end. Under a pill's height it is a thin
// line with a bead. Also the shell's scrubber (part control.scrubber): `moved` follows the hand, `seekRequested` is where
// it let go.
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
    readonly property bool pill: root.height >= NihilStyle.s(26)
    readonly property real fillWidth: root.pill ? root.height + root.shown * (root.width - root.height) : root.shown * root.width

    implicitWidth: NihilStyle.s(220)
    implicitHeight: NihilStyle.s(32)
    activeFocusOnTab: true
    Accessible.role: Accessible.Slider
    Accessible.name: root.name

    function snap(next: real): real {
        const stepped = root.stepSize > 0 ? Math.round((next - root.from) / root.stepSize) * root.stepSize + root.from : next
        return NihilStyle.clamp(Number(stepped.toFixed(4)), root.from, root.to)
    }
    function held(px: real): real {
        const inset = root.pill ? root.height / 2 : 0
        const share = NihilStyle.clamp((px - inset) / Math.max(1, root.width - inset * 2), 0, 1)
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
        height: root.pill ? root.height : NihilStyle.s(4)
        radius: height / 2
        color: root.pill ? NihilStyle.fillHover : Qt.alpha(NihilStyle.text, 0.16)
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: root.fillWidth
        height: root.pill ? root.height : NihilStyle.s(4)
        radius: height / 2
        color: root.fillColor
    }
    Repeater {
        model: root.pill ? Math.max(0, Math.floor((root.width - root.height) / NihilStyle.s(11))) : 0
        Rectangle {
            required property int index
            readonly property real along: root.height / 2 + (index + 1) * NihilStyle.s(11)
            x: along
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(1, NihilStyle.s(1.5))
            height: root.height * 0.3
            radius: width / 2
            color: along < root.fillWidth - root.height * 0.4 ? Qt.alpha(NihilStyle.accentText, 0.26) : Qt.alpha(NihilStyle.text, 0.2)
        }
    }
    Rectangle {
        visible: root.pill
        x: root.fillWidth - root.height * 0.42
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(2, NihilStyle.s(3))
        height: root.height * 0.5
        radius: width / 2
        color: NihilStyle.accentText
    }
    Rectangle {
        visible: !root.pill && root.knob
        x: root.fillWidth - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: NihilStyle.s(14)
        height: width
        radius: width / 2
        color: root.fillColor
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
