import QtQuick

// On or off: a pill that fills with the signal, its knob sliding to the lit end. The shell's own switch too (part
// control.switch): `toggled` asks for the change, `on` follows the value it is given.
Rectangle {
    id: root

    property bool on: false
    property string name: ""
    signal toggled()

    readonly property real inset: NihilStyle.s(3)

    implicitWidth: NihilStyle.s(46)
    implicitHeight: NihilStyle.s(26)
    width: implicitWidth
    height: implicitHeight
    radius: NihilStyle.keyRadius(width, height, false)
    color: root.on ? NihilStyle.accent : NihilStyle.pieceRaised
    Behavior on color { ColorAnimation { duration: NihilStyle.quick } }

    activeFocusOnTab: true
    Keys.onSpacePressed: root.toggled()
    Keys.onReturnPressed: root.toggled()
    Accessible.role: Accessible.CheckBox
    Accessible.name: root.name
    Accessible.checked: root.on
    Accessible.onPressAction: root.toggled()

    Rectangle {
        readonly property real side: root.height - root.inset * 2
        x: root.on ? root.width - side - root.inset : root.inset
        y: root.inset
        width: side * (tap.pressed ? 1.18 : 1)
        height: side
        radius: Math.max(0, root.radius - root.inset)
        color: root.on ? NihilStyle.onAccent : NihilStyle.inkSoft
        Behavior on x { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: NihilStyle.quick } }
        Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
    }

    MouseArea {
        id: tap
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    NFocus { shown: root.activeFocus }
}
