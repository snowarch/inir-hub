import QtQuick

// The procedural pattern, painted live: `pattern` 0 beam, 1 streaks, 2 haze, 3 plain.
ShaderEffect {
    property real seed: 0.37
    property real pattern: 0
    property real grain: NihilStyle.glassGrain
    property real glow: 1
    property real rainbow: 0
    property color base: NihilStyle.background
    property color highlight: NihilStyle.highlight
    property color highlightTint: NihilStyle.highlightTint
    readonly property size box: Qt.size(width, height)

    fragmentShader: Qt.resolvedUrl("pattern.frag.qsb")
}
