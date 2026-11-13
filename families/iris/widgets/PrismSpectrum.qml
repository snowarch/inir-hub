import QtQuick
import qs.modules.iris.style

// Prism's spectrum on whatever a face draws: `layer.enabled: true; layer.effect: PrismSpectrum {}` on a trace, a bar or
// a figure keeps its shape and paints it with the refraction's colours (PrismBands.frag), from IrisStyle.prismStops. `angle` is the run's
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
    // Prism's light, the shell's one source of it (IrisStyle.prismStops).
    readonly property var stops: IrisStyle.prismStops
    readonly property vector4d s0: Qt.vector4d(stops[0].r, stops[0].g, stops[0].b, 1)
    readonly property vector4d s1: Qt.vector4d(stops[1].r, stops[1].g, stops[1].b, 1)
    readonly property vector4d s2: Qt.vector4d(stops[2].r, stops[2].g, stops[2].b, 1)
    readonly property vector4d s3: Qt.vector4d(stops[3].r, stops[3].g, stops[3].b, 1)
    readonly property vector4d s4: Qt.vector4d(stops[4].r, stops[4].g, stops[4].b, 1)
    readonly property vector4d s5: Qt.vector4d(stops[5].r, stops[5].g, stops[5].b, 1)
    readonly property vector4d s6: Qt.vector4d(stops[6].r, stops[6].g, stops[6].b, 1)
    fragmentShader: Qt.resolvedUrl("PrismBands.frag.qsb")
}
