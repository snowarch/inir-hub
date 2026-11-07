import QtQuick

// Prism's spectrum on whatever a face draws: `layer.enabled: true; layer.effect: PrismSpectrum {}` on a trace, a bar or
// a figure keeps its shape and paints it with the refraction's colours (PrismSpectrum.frag). `angle` is the run's
// direction in degrees (0 left to right, -90 bottom to top), `from`/`to` the part of the spectrum it runs through,
// `white` how much of the run stays white first. Static: it draws again only when its source does.
ShaderEffect {
    id: tint
    property variant source
    property real angle: 0
    property real from: 0
    property real to: 1
    property real white: 0
    property bool mono: false
    property real bright: 1
    readonly property real rad: tint.angle * Math.PI / 180
    readonly property vector4d axis: Qt.vector4d(Math.cos(tint.rad), Math.sin(tint.rad), tint.from, tint.to)
    readonly property vector4d tone: Qt.vector4d(tint.white, tint.mono ? 1 : 0, tint.bright, 0)
    fragmentShader: Qt.resolvedUrl("PrismSpectrum.frag.qsb")
}
