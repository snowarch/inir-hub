import QtQuick
import qs.modules.iris.prism.core

// A key as an object (`.claude/ref/language`: keycap-glass, keycaps-collage, the tactile faders): a cap standing on
// its own side, which shows under it as a lip, and a hairline of light along its top. Pointed at, the cap warms a step;
// pressed, it sinks onto its side. What the key carries is laid on its cap and sinks with it.
Item {
    id: root
    property color face: PrismTheme.keyQuiet
    property bool hovered: false
    property bool down: false
    property real radius: height / 2
    default property alias contents: cap.data

    readonly property real lip: PrismTheme.keyLip

    Rectangle {
        y: root.lip
        width: root.width
        height: root.height - root.lip
        radius: root.radius
        color: PrismTheme.keySide(root.face)
    }
    Rectangle {
        id: rim
        y: root.down ? root.lip : 0
        width: root.width
        height: root.height - root.lip
        radius: root.radius
        color: PrismTheme.keyRim(root.face)
        Behavior on y { NumberAnimation { duration: PrismTheme.ms(90); easing.type: Easing.OutCubic } }
        Rectangle {
            y: 1
            width: parent.width
            height: parent.height - 1
            radius: root.radius
            color: root.hovered && !root.down ? PrismTheme.keyHover(root.face) : root.face
            Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
        }
        Item {
            id: cap
            anchors.fill: parent
        }
    }
}
