import QtQuick
import qs.services
import qs.modules.iris.prism.core

// On and off as an object (`.claude/ref/language`: the Figma toggle's deep well, the rocker's printed I and O): a well
// cut into the card and a white key with its state printed on it, a bar for on, a ring for off, the same in every
// language. On, the well fills with the person's accent (the spectrum is the art's, never a control's: a page of
// switches read as a page of rainbows); off, it is empty and the key rests at the start. Three ways to tell.
Item {
    id: root
    property bool checked: false
    signal toggled(bool value)

    readonly property real pad: PrismTheme.dp(3)
    readonly property real keyWidth: PrismTheme.dp(34)
    implicitWidth: PrismTheme.dp(70)
    implicitHeight: PrismTheme.dp(32)

    Accessible.role: Accessible.CheckBox
    Accessible.checkable: true
    Accessible.checked: root.checked
    Accessible.name: root.checked ? Translation.tr("On") : Translation.tr("Off")

    PrismWell {
        anchors.fill: parent
        hovered: area.containsMouse && !root.checked
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: height / 2
        color: PrismTheme.accent
        opacity: root.checked ? (area.containsMouse ? 0.88 : 1) : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
    }
    PrismKey {
        x: root.checked ? root.width - root.pad - width : root.pad
        y: root.pad
        width: root.keyWidth
        height: root.height - root.pad * 2
        face: PrismTheme.paper
        hovered: area.containsMouse
        down: area.pressed
        Behavior on x { NumberAnimation { duration: PrismTheme.ms(240); easing.type: Easing.OutCubic } }
        Rectangle {
            anchors.centerIn: parent
            width: root.checked ? PrismTheme.dp(2) : PrismTheme.dp(9)
            height: PrismTheme.dp(9)
            radius: root.checked ? 1 : width / 2
            color: root.checked ? PrismTheme.night : "transparent"
            border.width: root.checked ? 0 : PrismTheme.dp(1.5)
            border.color: PrismTheme.night
            opacity: root.checked ? 0.78 : 0.42
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
