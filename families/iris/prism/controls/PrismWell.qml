import QtQuick
import qs.modules.iris.prism.core

// A well cut into the card, where keys slide and art shows through (`.claude/ref/language`: the Figma toggle, the
// faders' grooves): a step darker than the card, no lip or outline.
Rectangle {
    id: root
    property bool hovered: false
    radius: height / 2
    color: root.hovered ? PrismTheme.keyHover(PrismTheme.sunk) : PrismTheme.sunk
    Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
}
