import QtQuick

// The procedural field, painted live: `form` 0 drift, 1 eclipse, 2 fluted, 3 stippled ridge.
ShaderEffect {
    property real seed: 0.37
    property real form: 0
    property real grain: NihilStyle.glassGrain
    property real glow: 1
    property color base: NihilStyle.base
    property color mid: NihilStyle.mid
    property color high: NihilStyle.high
    property color spark: NihilStyle.flareB
    readonly property size box: Qt.size(width, height)

    fragmentShader: Qt.resolvedUrl("field.frag.qsb")
}
