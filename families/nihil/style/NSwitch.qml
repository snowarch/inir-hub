import QtQuick

// On or off. Also the shell's own switch (part control.switch): `toggled` asks, `on` follows the value given.
Rectangle {
    id: root

    property bool on: false
    property string name: ""
    signal toggled()

    readonly property real inset: NihilStyle.s(3)

    implicitWidth: NihilStyle.s(44)
    implicitHeight: NihilStyle.s(24)
    width: implicitWidth
    height: implicitHeight
    radius: height / 2
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
        x: root.on ? root.width - width - root.inset : root.inset
        y: root.inset
        width: side * (tap.pressed ? 1.2 : 1)
        height: side
        radius: side / 2
        color: root.on ? NihilStyle.onAccent : NihilStyle.ink
        Behavior on x { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: NihilStyle.quick } }
    }

    MouseArea {
        id: tap
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
