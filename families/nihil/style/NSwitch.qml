import QtQuick

// On or off. Also the shell's own switch (part control.switch): `toggled` asks, `on` follows the value given.
// A well with a bead; on, the bead is lit and the light rises from the well's lower edge.
Item {
    id: root

    property bool on: false
    property string name: ""
    signal toggled()

    readonly property real inset: NihilStyle.s(4)

    implicitWidth: NihilStyle.s(46)
    implicitHeight: NihilStyle.s(26)
    width: implicitWidth
    height: implicitHeight

    activeFocusOnTab: true
    Keys.onSpacePressed: root.toggled()
    Keys.onReturnPressed: root.toggled()
    Accessible.role: Accessible.CheckBox
    Accessible.name: root.name
    Accessible.checked: root.on
    Accessible.onPressAction: root.toggled()

    NWell {
        anchors.fill: parent
        radius: height / 2
        lit: root.on ? 1 : 0
        hovered: tap.containsMouse
    }
    Rectangle {
        readonly property real side: root.height - root.inset * 2
        x: root.on ? root.width - width - root.inset : root.inset
        y: root.inset
        width: side * (tap.pressed ? 1.25 : 1)
        height: side
        radius: height / 2
        color: root.on ? NihilStyle.ink : NihilStyle.inkFaint
        Behavior on x { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutQuint } }
        Behavior on width { NumberAnimation { duration: NihilStyle.quick } }
        Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
    }

    MouseArea {
        id: tap
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
