import QtQuick
import QtQuick.Shapes

// A soft radial light: the haze the reference spills from its top-left corner. Static. `area` (in its own space) is
// the part it fills, `corner` rounds that part's left corners, so it stays inside a rounded body without a mask.
Shape {
    id: root
    property color colour: "white"
    property real strength: 0.35
    property rect area: Qt.rect(0, 0, root.width, root.height)
    property real corner: 0
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
        PathRectangle {
            x: root.area.x; y: root.area.y; width: root.area.width; height: root.area.height
            topLeftRadius: root.corner; bottomLeftRadius: root.corner
        }
    }
}
