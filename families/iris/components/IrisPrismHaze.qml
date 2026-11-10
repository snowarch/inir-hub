import QtQuick
import QtQuick.Shapes
import qs.modules.iris.style

// Prism's haze (.claude/ref/iris-prism, omusic-app): a black body lit from one corner by the spectrum, cool at the
// corner and warm across from it, so the black reads as glass in a dark room and never as a flat fill. Laid over the
// body's own colour, its radius the body's; every colour is IrisStyle.prismStops. Static: nothing here moves.
Item {
    id: root
    property real radius: IrisStyle.radiusPanel
    // The corner the light comes from: "bottomRight", "bottomLeft", "topRight", "topLeft".
    property string from: "bottomRight"
    // 0 to 1: how much light the body takes.
    property real strength: 1

    readonly property bool atRight: root.from.endsWith("Right")
    readonly property bool atBottom: root.from.startsWith("bottom")
    readonly property var stops: IrisStyle.prismStops
    readonly property real reach: Math.max(root.width, root.height)
    readonly property real amount: root.strength * (IrisStyle.light ? 0.5 : 1)

    component Glow: ShapePath {
        id: glow
        property real cx: 0
        property real cy: 0
        property real size: 1
        property color near: "transparent"
        property color far: "transparent"
        property real alpha: 0
        property real w: 0
        property real h: 0
        property real round: 0
        strokeWidth: -1
        fillGradient: RadialGradient {
            centerX: glow.cx; centerY: glow.cy
            focalX: glow.cx; focalY: glow.cy
            centerRadius: glow.size
            GradientStop { position: 0; color: Qt.alpha(glow.near, glow.alpha) }
            GradientStop { position: 0.45; color: Qt.alpha(glow.far, glow.alpha * 0.42) }
            GradientStop { position: 1; color: Qt.alpha(glow.far, 0) }
        }
        PathRectangle { width: glow.w; height: glow.h; radius: glow.round }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        // The cool light at its corner: blue at the source, violet as it falls.
        Glow {
            w: root.width; h: root.height; round: root.radius
            cx: root.atRight ? root.width : 0
            cy: root.atBottom ? root.height : 0
            size: root.reach * 0.95
            near: root.stops[2]
            far: root.stops[0]
            alpha: 0.44 * root.amount
        }
        // Its warm end, across the body and much fainter.
        Glow {
            w: root.width; h: root.height; round: root.radius
            cx: root.atRight ? root.width * 0.12 : root.width * 0.88
            cy: root.atBottom ? root.height * 0.2 : root.height * 0.8
            size: root.reach * 0.6
            near: root.stops[5]
            far: root.stops[6]
            alpha: 0.14 * root.amount
        }
    }
}
