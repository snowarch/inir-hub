import QtQuick

// On or off. Also the shell's own switch (part control.switch): `toggled` asks, `on` follows the value given.
// A slot with a square bead: off, a hairline and a faint bead; on, a bone plate with the bead in black and a spark.
Rectangle {
    id: root

    property bool on: false
    property string name: ""
    signal toggled()

    readonly property real inset: NihilStyle.s(3)

    implicitWidth: NihilStyle.s(40)
    implicitHeight: NihilStyle.s(20)
    width: implicitWidth
    height: implicitHeight
    radius: NihilStyle.r(5)
    color: root.on ? NihilStyle.ink : "transparent"
    border.width: 1
    border.color: root.on ? NihilStyle.ink : tap.containsMouse ? NihilStyle.inkSoft : NihilStyle.inkFaint
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
        x: root.on ? root.width - width - root.inset : root.inset
        y: root.inset
        width: side * (tap.pressed ? 1.3 : 1)
        height: side
        radius: Math.max(1, root.radius - root.inset)
        color: root.on ? NihilStyle.onAccent : NihilStyle.inkSoft
        Behavior on x { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutQuint } }
        Behavior on width { NumberAnimation { duration: NihilStyle.quick } }
    }
    NSpark {
        x: root.width - size / 2 - root.inset
        y: -size / 2 + root.inset
        size: NihilStyle.s(18)
        opacity: root.on ? 0.9 : 0
        Behavior on opacity { NumberAnimation { duration: NihilStyle.calm } }
    }

    MouseArea {
        id: tap
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
