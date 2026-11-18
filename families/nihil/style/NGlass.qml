import QtQuick
import Quickshell

// A piece of NiHiL glass. `region` is its shape for the compositor's blur; with `tracks` the flare follows the pointer.
Item {
    id: root

    property real radius: NihilStyle.rPanel
    property color tint: NihilStyle.glassTint
    property real rim: NihilStyle.glassRim
    property real flare: NihilStyle.glassFlare
    property real grain: NihilStyle.glassGrain
    property real shadow: 1
    property real ignite: 0
    property bool tracks: false
    property point light: Qt.point(root.width * 0.2, -root.height * 0.15)
    readonly property real pad: NihilStyle.s(34)
    readonly property Region region: Region { item: root; radius: root.radius }

    Behavior on ignite { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }

    HoverHandler {
        enabled: root.tracks
        onPointChanged: if (hovered) root.light = point.position
    }

    ShaderEffect {
        x: -root.pad
        y: -root.pad
        width: root.width + root.pad * 2
        height: root.height + root.pad * 2
        visible: root.width > 0 && root.height > 0
        fragmentShader: Qt.resolvedUrl("glass.frag.qsb")

        readonly property size box: Qt.size(root.width, root.height)
        readonly property point lightAt: root.light
        readonly property real pad: root.pad
        readonly property real radius: root.radius
        readonly property real rim: root.rim
        readonly property real flare: root.flare
        readonly property real grain: root.grain
        readonly property real ignite: root.ignite
        readonly property real shadow: root.shadow
        readonly property color tint: root.tint
        readonly property color rimA: NihilStyle.flareA
        readonly property color rimB: NihilStyle.flareB
        readonly property color flareA: NihilStyle.flareA
        readonly property color flareB: NihilStyle.flareB
    }
}
