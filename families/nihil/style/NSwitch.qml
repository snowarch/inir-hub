import QtQuick

// On or off. Also the shell's own switch (part control.switch): `toggled` asks, `on` follows the value given.
// A pill with a round bead: off, a faint track; on, the accent with a white bead.
Rectangle {
    id: root

    property bool on: false
    property string name: ""
    signal toggled()

    readonly property real inset: NihilStyle.s(3)

    implicitWidth: NihilStyle.s(38)
    implicitHeight: NihilStyle.s(22)
    width: implicitWidth
    height: implicitHeight
    radius: height / 2
    color: root.on ? NihilStyle.accent : tap.containsMouse ? NihilStyle.pieceRaised : Qt.alpha(NihilStyle.ink, 0.14)
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
        radius: height / 2
        color: "#FFFFFF"
        Behavior on x { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutQuint } }
        Behavior on width { NumberAnimation { duration: NihilStyle.quick } }
    }

    MouseArea {
        id: tap
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
