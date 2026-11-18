import QtQuick

// One signal to choose: a disc in its colour, a dot in the middle of the chosen one, its name under it.
Item {
    id: root

    property color swatch: NihilStyle.accent
    property string label: ""
    property bool chosen: false
    signal picked()

    readonly property bool lightDisc: (0.299 * root.swatch.r + 0.587 * root.swatch.g + 0.114 * root.swatch.b) > 0.6

    implicitWidth: NihilStyle.s(66)
    implicitHeight: disc.height + word.implicitHeight + NihilStyle.s(7)
    activeFocusOnTab: true
    Keys.onSpacePressed: root.picked()
    Keys.onReturnPressed: root.picked()
    Accessible.role: Accessible.RadioButton
    Accessible.name: root.label
    Accessible.checked: root.chosen

    Rectangle {
        id: disc
        anchors.horizontalCenter: parent.horizontalCenter
        width: NihilStyle.s(44)
        height: width
        radius: NihilStyle.keyRadius(width, height, false)
        color: root.swatch
        scale: tap.pressed ? 0.94 : tap.containsMouse ? 1.05 : 1
        Behavior on scale { NumberAnimation { duration: NihilStyle.quick; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: NihilStyle.calm } }
        Rectangle {
            anchors.centerIn: parent
            width: root.chosen ? NihilStyle.s(14) : 0
            height: width
            radius: NihilStyle.squareDots ? NihilStyle.s(2) : width / 2
            color: root.lightDisc ? NihilStyle.neutral(NihilStyle.m3.m3scrim, 0.08) : NihilStyle.neutral(NihilStyle.m3.m3scrim, 0.99)
            Behavior on width { NumberAnimation { duration: NihilStyle.quick; easing.type: Easing.OutCubic } }
        }
        NFocus { shown: root.activeFocus }
    }
    NText {
        id: word
        anchors.top: disc.bottom
        anchors.topMargin: NihilStyle.s(7)
        width: root.width
        horizontalAlignment: Text.AlignHCenter
        figures: true
        text: root.label.toUpperCase()
        font.pixelSize: NihilStyle.s(10)
        color: root.chosen ? NihilStyle.ink : NihilStyle.inkSoft
    }
    MouseArea {
        id: tap
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
    }
}
