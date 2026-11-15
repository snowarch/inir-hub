import QtQuick
import qs.modules.iris.prism.core

// A well cut into the card, where keys slide and art shows through (`.claude/ref/language`: the Figma toggle, the
// faders' grooves). Dark, its lower lip catches the light; light, its upper lip falls in shade.
Item {
    id: root
    property real radius: height / 2
    property bool hovered: false

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: PrismTheme.wellEdge
    }
    Rectangle {
        y: PrismTheme.light ? 1 : 0
        width: root.width
        height: root.height - 1
        radius: root.radius
        color: root.hovered ? PrismTheme.keyHover(PrismTheme.sunk) : PrismTheme.sunk
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
    }
}
