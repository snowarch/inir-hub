import QtQuick

// A place pressed into the glass. `highlighted` raises the aurora from its lower edge: what is on is highlighted, never filled.
ShaderEffect {
    id: root

    property real radius: NihilStyle.radiusCard
    property real highlighted: 0
    property bool hovered: false

    Behavior on highlighted { NumberAnimation { duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic } }
    property real hover: root.hovered ? 1 : 0
    Behavior on hover { NumberAnimation { duration: NihilStyle.durationShort } }

    readonly property size box: Qt.size(root.width, root.height)
    readonly property color fill: NihilStyle.inset
    readonly property color shade: NihilStyle.insetShadow
    readonly property color edge: NihilStyle.insetHighlight
    readonly property color glow: NihilStyle.text
    readonly property color highlight: NihilStyle.highlight
    readonly property color highlightTint: NihilStyle.highlightTint

    fragmentShader: Qt.resolvedUrl("inset.frag.qsb")
}
