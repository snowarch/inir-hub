import QtQuick

// A soft light around what is chosen.
ShaderEffect {
    property color tone: NihilStyle.accent
    property real strength: 0.75

    fragmentShader: Qt.resolvedUrl("bloom.frag.qsb")
}
