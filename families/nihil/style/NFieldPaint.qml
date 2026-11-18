import QtQuick

// The procedural field, painted live: `form` 0 beam, 1 fluted, 2 haze, 3 void.
ShaderEffect {
    property real seed: 0.37
    property real form: 0
    property real grain: NihilStyle.glassGrain
    property real glow: 1
    property real rainbow: 0
    property color base: NihilStyle.void_
    property color specA: NihilStyle.specA
    property color specB: NihilStyle.specB
    readonly property size box: Qt.size(width, height)

    fragmentShader: Qt.resolvedUrl("field.frag.qsb")
}
