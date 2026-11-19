import QtQuick

// The ring NiHiL's big moments stand in: the way out turns on it, the lock counts on it.
ShaderEffect {
    id: root

    property real ticks: 60
    property real level: 0
    // Radians clockwise from the top.
    property real pointer: 0
    property real spread: 0
    property color tickColor: Qt.alpha(NihilStyle.text, 0.22)
    property color fillColor: NihilStyle.accent
    property color trackColor: Qt.alpha(NihilStyle.background, 0.34)

    readonly property size box: Qt.size(root.width, root.height)

    fragmentShader: Qt.resolvedUrl("ring.frag.qsb")
}
