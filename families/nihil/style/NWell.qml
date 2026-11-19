import QtQuick

// A place pressed into the glass. `lit` raises the aurora from its lower edge: what is on is lit, never filled.
ShaderEffect {
    id: root

    property real radius: NihilStyle.rCard
    property real lit: 0
    property bool hovered: false

    Behavior on lit { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
    property real hover: root.hovered ? 1 : 0
    Behavior on hover { NumberAnimation { duration: NihilStyle.quick } }

    readonly property size box: Qt.size(root.width, root.height)
    readonly property color fill: NihilStyle.well
    readonly property color shade: NihilStyle.wellShade
    readonly property color edge: NihilStyle.wellEdge
    readonly property color glow: NihilStyle.ink
    readonly property color specA: NihilStyle.specA
    readonly property color specB: NihilStyle.specB

    fragmentShader: Qt.resolvedUrl("well.frag.qsb")
}
