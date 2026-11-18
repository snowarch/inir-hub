import QtQuick

// A figure that leads its tile: the heaviest cut, tight, in numbers that keep their width.
NText {
    id: root
    property real size: NihilStyle.s(44)
    font.pixelSize: root.size
    font.weight: Font.Black
    font.letterSpacing: -root.size * 0.035
    font.features: ({ "tnum": 1 })
    renderType: Text.QtRendering
    elide: Text.ElideNone
}
