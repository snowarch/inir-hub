import QtQuick
import qs.modules.iris.prism.core

// A key as an object (`.claude/ref/language`: keycap-glass, keycaps-collage): a cap, its fill alone setting it off,
// never an outline (his 11-16). Pointed at, the cap lifts a step; pressed, it sinks a little. What the key carries is
// laid on its cap and sinks with it.
Item {
    id: root
    property color face: PrismTheme.keyQuiet
    property bool hovered: false
    property bool down: false
    property real radius: height / 2
    default property alias contents: cap.data

    Rectangle {
        id: body
        anchors.fill: parent
        radius: root.radius
        scale: root.down ? 0.96 : 1
        color: root.hovered && !root.down ? PrismTheme.keyHover(root.face) : root.face
        Behavior on scale { NumberAnimation { duration: PrismTheme.ms(90); easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
        Item {
            id: cap
            anchors.fill: parent
        }
    }
}
