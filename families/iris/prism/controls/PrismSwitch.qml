import QtQuick
import qs.services
import qs.modules.iris.prism.core

// On and off (B · Carpeta, his 11-18 "tal cual a la imagen"): a short track, the person's accent with a white knob
// when on, a dark track with a grey knob when off. Nothing printed on it.
Item {
    id: root
    property bool checked: false
    signal toggled(bool value)

    readonly property real pad: PrismTheme.dp(3)
    implicitWidth: PrismTheme.dp(44)
    implicitHeight: PrismTheme.dp(26)
    opacity: root.enabled ? 1 : 0.4

    Accessible.role: Accessible.CheckBox
    Accessible.checkable: true
    Accessible.checked: root.checked
    Accessible.name: root.checked ? Translation.tr("On") : Translation.tr("Off")

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? PrismTheme.accent : area.containsMouse ? PrismTheme.keyHover(PrismTheme.track) : PrismTheme.track
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(180); easing.type: Easing.OutCubic } }
    }
    Rectangle {
        id: knob
        x: root.checked ? root.width - root.pad - width : root.pad
        y: root.pad
        width: root.height - 2 * root.pad
        height: width
        radius: width / 2
        color: root.checked ? PrismTheme.paper : PrismTheme.knobOff
        scale: area.pressed ? 0.9 : 1
        Behavior on x { NumberAnimation { duration: PrismTheme.ms(220); easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(180); easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: PrismTheme.ms(90); easing.type: Easing.OutCubic } }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
