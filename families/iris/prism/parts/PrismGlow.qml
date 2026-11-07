import QtQuick
import QtQuick.Shapes

// A soft radial light: the haze the reference spills from its top-left corner. Static.
Shape {
    id: root
    property color colour: "white"
    property real strength: 0.35
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        strokeWidth: -1
        fillGradient: RadialGradient {
            centerX: root.width / 2; centerY: root.height / 2
            focalX: centerX; focalY: centerY
            centerRadius: Math.max(root.width, root.height) / 2
            GradientStop { position: 0; color: Qt.alpha(root.colour, root.strength) }
            GradientStop { position: 0.45; color: Qt.alpha(root.colour, root.strength * 0.4) }
            GradientStop { position: 1; color: Qt.alpha(root.colour, 0) }
        }
        PathRectangle { x: 0; y: 0; width: root.width; height: root.height }
    }
}
