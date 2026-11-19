import QtQuick
import Quickshell

// A pane of NiHiL glass. `region` is its shape for the compositor's blur; with `followPointer` the light follows the pointer.
// `activeGlow` raises the glow from its bottom edge (what is active); `material` overrides the material for one pane.
Item {
    id: root

    property real radius: NihilStyle.radiusPanel
    property color tint: NihilStyle.glassTint
    property real edgeLight: NihilStyle.glassEdgeLight
    property real edgeGlow: NihilStyle.glassEdgeGlow
    property real grain: NihilStyle.glassGrain
    property int material: NihilStyle.materialIndex
    property real shadow: 1
    property real activeGlow: 0
    property bool followPointer: false
    property point lightPosition: Qt.point(root.width * 0.5, -root.height * 0.4)
    readonly property real pad: NihilStyle.s(30)
    readonly property Region region: Region { item: root; radius: root.radius }

    Behavior on activeGlow { NumberAnimation { duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic } }

    HoverHandler {
        enabled: root.followPointer
        onPointChanged: if (hovered) root.lightPosition = point.position
    }

    ShaderEffect {
        x: -root.pad
        y: -root.pad
        width: root.width + root.pad * 2
        height: root.height + root.pad * 2
        visible: root.width > 0 && root.height > 0 && root.opacity > 0
        fragmentShader: Qt.resolvedUrl("glass.frag.qsb")

        readonly property size box: Qt.size(root.width, root.height)
        readonly property point lightPosition: root.lightPosition
        readonly property real pad: root.pad
        readonly property real radius: root.radius
        readonly property real edgeLight: root.edgeLight
        readonly property real edgeGlow: root.edgeGlow
        readonly property real grain: root.grain
        readonly property real activeGlow: root.activeGlow
        readonly property real shadow: root.shadow
        readonly property real material: root.material
        readonly property real ribWidth: NihilStyle.ribWidth
        readonly property color tint: root.tint
        readonly property color highlight: NihilStyle.highlight
        readonly property color highlightTint: NihilStyle.highlightTint
    }
}
