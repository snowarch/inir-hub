import QtQuick

// A level as a dial: ticks round three quarters of a circle, its value in the middle, its glyph in the open quarter.
// Drag round it or scroll on it; the glyph is a key of its own.
Item {
    id: root

    property real value: 0
    property string word: ""
    property string glyph: ""
    property bool keyed: false
    property real stepSize: 0.02
    signal moved(real value)
    signal tapped()

    readonly property real level: NihilStyle.clamp(root.value, 0, 1)

    implicitWidth: NihilStyle.s(208)
    implicitHeight: implicitWidth
    activeFocusOnTab: true
    Accessible.role: Accessible.Dial
    Accessible.name: root.word

    function nudge(by: real): void {
        root.moved(NihilStyle.clamp(Math.round((root.level + by) / root.stepSize) * root.stepSize, 0, 1))
    }
    Keys.onLeftPressed: root.nudge(-root.stepSize)
    Keys.onDownPressed: root.nudge(-root.stepSize)
    Keys.onRightPressed: root.nudge(root.stepSize)
    Keys.onUpPressed: root.nudge(root.stepSize)

    ShaderEffect {
        anchors.fill: parent
        readonly property size box: Qt.size(width, height)
        readonly property real level: root.level
        readonly property real ticks: 50
        readonly property color tickColor: Qt.alpha(NihilStyle.text, 0.2)
        readonly property color fillColor: NihilStyle.accent
        readonly property color trackColor: NihilStyle.fill
        fragmentShader: Qt.resolvedUrl("dial.frag.qsb")
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function follow(x: real, y: real): void {
            const dx = x - width / 2
            const dy = y - height / 2
            const gap = Math.PI / 4
            let theta = -Math.atan2(dx, dy)
            if (theta < 0) theta += Math.PI * 2
            if (theta < gap || theta > Math.PI * 2 - gap) return
            root.moved(NihilStyle.clamp((theta - gap) / (Math.PI * 2 - gap * 2), 0, 1))
        }
        onPressed: event => follow(event.x, event.y)
        onPositionChanged: event => { if (pressed) follow(event.x, event.y) }
        onWheel: event => root.nudge(event.angleDelta.y > 0 ? 0.05 : -0.05)
    }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -NihilStyle.s(6)
        NText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(root.level * 100)
            figures: true
            font.pixelSize: root.width * 0.25
            font.weight: Font.ExtraLight
        }
        NText {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(implicitWidth, root.width * 0.5)
            text: root.word
            font.pixelSize: NihilStyle.textSmall
            color: NihilStyle.textSecondary
        }
    }

    NButton {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: NihilStyle.s(40)
        height: width
        radius: width / 2
        tone: "transparent"
        icon: root.glyph
        iconSize: NihilStyle.s(20)
        enabled: root.keyed
        Accessible.name: root.word
        onClicked: root.tapped()
    }
}
