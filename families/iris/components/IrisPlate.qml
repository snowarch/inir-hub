pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.iris.style

// A plate (a group of rows, a tile, a card) in the look that is worn: Apple's fill, Nothing's hairline, Synth's opaque
// panel standing on its drop edge, Gel's gloss under a light cap. Set colour and radius as on a Rectangle.
Rectangle {
    id: root

    readonly property string style: IrisStyle.plateStyle
    // A plate that is chosen or open keeps the look's make but not its cap: the tint is the state.
    property bool lit: false
    border.width: IrisStyle.plateEdge.a > 0 && root.color.a > 0 ? 1 : 0
    border.color: IrisStyle.plateEdge

    // Synth: the panel stands on its edge, darker, two pixels under it.
    Rectangle {
        z: -1
        visible: root.style === "key" && root.color.a > 0
        width: root.width
        height: root.height
        y: Math.round(2 * IrisStyle.density)
        radius: root.radius
        color: IrisStyle.synthKeyEdge
    }
    // Gel: a light cap over the upper half, inside the plate's own curve.
    Rectangle {
        visible: root.style === "gloss" && root.color.a > 0
        x: 1
        y: 1
        width: root.width - 2
        height: Math.round(root.height * 0.5)
        topLeftRadius: Math.max(0, root.radius - 1)
        topRightRadius: Math.max(0, root.radius - 1)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, IrisStyle.light ? 0.7 : (root.lit ? 0.22 : 0.12)) } // iris-literal: gel's cap
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
        }
    }
}
