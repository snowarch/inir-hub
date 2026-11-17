import QtQuick

// The refraction art: beam, spectrum and a frosted glass card at `card` (in this item's pixels). Static: the shader
// draws again only when a size or the card moves.
ShaderEffect {
    id: root

    property rect card: Qt.rect(width * 0.62, height * 0.14, height * 0.72, height * 0.72)
    property real cardRadius: 18
    property real cornerRadius: 22
    property color base: "#08080a" // iris-literal: the art's black, the same in every scheme
    // Where the beam enters and breaks, as fractions of the box.
    property point source: Qt.point(-0.04, 1.08)
    property point prismAt: Qt.point(0.5, 0.56)
    property real spread: 0.8

    readonly property vector2d size: Qt.vector2d(width, height)
    readonly property vector4d beam: Qt.vector4d(source.x * width, source.y * height, prismAt.x * width, prismAt.y * height)
    readonly property vector4d fan: Qt.vector4d(spread, Math.max(140, width * 0.7), 1.1, -0.1)
    readonly property vector4d glass: Qt.vector4d(card.x, card.y, card.width, card.height)
    readonly property vector4d glassLook: Qt.vector4d(cardRadius, 0.06, 7.0, 1.0)
    readonly property vector4d bg: Qt.vector4d(base.r, base.g, base.b, 1)
    readonly property real radius: cornerRadius
    readonly property real grain: 0.018

    fragmentShader: Qt.resolvedUrl("prism_refraction.frag.qsb")
    blending: true
}
