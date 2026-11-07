import QtQuick
import qs.modules.iris.prism.core

// A Settings design drawn small, as its panes stand: blocks in the box's own units (0..1), each a tone of ink, the
// accent or the spectrum. `lit` draws it on the solid card of the chosen design.
Item {
    id: root
    property var shapes: []
    property bool lit: false
    readonly property color ink: root.lit ? PrismTheme.inkSolid : PrismTheme.ink

    Repeater {
        model: root.shapes
        delegate: Rectangle {
            id: block
            required property var modelData
            x: Math.round(block.modelData.x * root.width)
            y: Math.round(block.modelData.y * root.height)
            width: Math.max(1, Math.round(block.modelData.w * root.width))
            height: Math.max(1, Math.round(block.modelData.h * root.height))
            radius: Math.min(height / 2, (block.modelData.r ?? 0) * root.width)
            color: block.modelData.tone === "accent" ? PrismTheme.accent
                : block.modelData.tone === "spectrum" ? "transparent"
                : Qt.alpha(root.ink, block.modelData.a ?? 0.2)
            gradient: block.modelData.tone === "spectrum" ? spectrum : null
        }
    }
    // The beam broken into colour, as Prism's hero holds it.
    Gradient {
        id: spectrum
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: PrismTheme.tint("red") }
        GradientStop { position: 0.3; color: PrismTheme.tint("orange") }
        GradientStop { position: 0.55; color: PrismTheme.tint("green") }
        GradientStop { position: 0.8; color: PrismTheme.tint("blue") }
        GradientStop { position: 1; color: PrismTheme.tint("violet") }
    }
}
