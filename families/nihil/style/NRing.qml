import QtQuick

// The ring NiHiL's big moments stand in: the way out turns on it, the lock counts on it.
ShaderEffect {
    id: root

    property real ticks: 60
    property real level: 0
    // Radians clockwise from the top.
    property real pointer: 0
    property real spread: 0
    property color mark: Qt.alpha(NihilStyle.ink, 0.22)
    property color light: NihilStyle.accent
    property color recess: Qt.alpha(NihilStyle.void_, 0.34)

    readonly property size box: Qt.size(root.width, root.height)

    fragmentShader: Qt.resolvedUrl("ring.frag.qsb")
}
