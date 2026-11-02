import QtQuick
import qs.modules.iris.style

// The light the field gives its bodies (IrisStyle.bodyTop, bodyFoot, the lit top edge), for a body drawn outside it: a
// desktop widget, a plate on the wall. Laid over the body's own colour, its radius the body's.
Rectangle {
    id: root
    visible: !IrisStyle.selfLit
    color: "transparent"
    gradient: Gradient {
        GradientStop { position: 0; color: Qt.rgba(IrisStyle.bodyTop.x, IrisStyle.bodyTop.y, IrisStyle.bodyTop.z, IrisStyle.bodyTop.w) }
        GradientStop { position: 1; color: Qt.rgba(IrisStyle.bodyFoot.x, IrisStyle.bodyFoot.y, IrisStyle.bodyFoot.z, IrisStyle.bodyFoot.w) }
    }
    Rectangle {
        visible: IrisStyle.edgeStyle === "light"
        x: Math.round(root.radius * 0.6)
        y: 1
        width: root.width - 2 * x
        height: 1
        color: Qt.alpha(IrisStyle.glassEdgeColour, IrisStyle.glassEdgeLight)
    }
}
