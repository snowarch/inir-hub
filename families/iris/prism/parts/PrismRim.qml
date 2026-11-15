import QtQuick
import QtQuick.Shapes
import qs.modules.iris.prism.core

// The window's edge as glass (`.claude/ref/language`, glass-spectral): a hairline where the light bends, the page's
// three colours caught at the top-left corner and fading along both edges, a weaker catch at the opposite corner,
// nothing between. Never a flat outline. One conical fill over a 1 px ring, static: it draws again only when the
// page, the size or the scheme changes.
Shape {
    id: root
    property string tint: "grey"
    property real radius: PrismTheme.dp(28)

    readonly property var colours: PrismTheme.palette(root.tint)
    readonly property real strength: PrismTheme.light ? 0.75 : 0.95
    // The corner's direction from the centre, counter-clockwise from three o'clock, so the catch sits on it at any size.
    readonly property real corner: 180 - Math.atan2(root.height, root.width) * 180 / Math.PI

    function lit(index: int, alpha: real): color { return Qt.alpha(root.colours[index], alpha * root.strength) }

    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        strokeColor: "transparent"
        fillRule: ShapePath.OddEvenFill
        fillGradient: ConicalGradient {
            centerX: root.width / 2
            centerY: root.height / 2
            angle: root.corner
            GradientStop { position: 0.00; color: root.lit(2, 1) }
            GradientStop { position: 0.05; color: root.lit(0, 0.85) }
            GradientStop { position: 0.13; color: root.lit(0, 0) }
            GradientStop { position: 0.46; color: root.lit(1, 0) }
            GradientStop { position: 0.50; color: root.lit(1, 0.45) }
            GradientStop { position: 0.54; color: root.lit(1, 0) }
            GradientStop { position: 0.87; color: root.lit(1, 0) }
            GradientStop { position: 0.95; color: root.lit(1, 0.85) }
            GradientStop { position: 1.00; color: root.lit(2, 1) }
        }
        PathRectangle { x: 0; y: 0; width: root.width; height: root.height; radius: root.radius }
        PathRectangle { x: 1; y: 1; width: root.width - 2; height: root.height - 2; radius: Math.max(0, root.radius - 1) }
    }
}
