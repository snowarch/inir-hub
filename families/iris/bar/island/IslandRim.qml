pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs.modules.iris.style

// The light on an edge face's rim (Aura, Comet, Lumen, Glyph): a soft halo and a fine line, both one conical gradient
// turned to `angle`. The face hands in up to six stops as [position, colour]; a face with fewer repeats its last.
Item {
    id: rim
    property real line: Math.max(1.5, Math.round(2 * IrisStyle.density))
    property real angle: 0
    property var stops: []
    property real halo: 0.3
    property bool showHalo: true

    function stop(i: int): var {
        const list = rim.stops ?? []
        return list[Math.min(i, list.length - 1)] ?? [i / 5, "transparent"]
    }

    Repeater {
        model: rim.showHalo ? [{ inset: 0, alpha: rim.halo, width: 5 }, { inset: 1.5, alpha: 1, width: 1 }]
            : [{ inset: 1.5, alpha: 1, width: 1 }]
        Shape {
            id: ring
            required property var modelData
            readonly property real gap: Math.round(ring.modelData.inset * IrisStyle.density)
            readonly property real thick: rim.line * ring.modelData.width
            anchors.fill: parent
            anchors.margins: Math.round(2 * IrisStyle.density)
            opacity: ring.modelData.alpha
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillRule: ShapePath.OddEvenFill
                fillGradient: ConicalGradient {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    angle: rim.angle
                    GradientStop { position: rim.stop(0)[0]; color: rim.stop(0)[1] }
                    GradientStop { position: rim.stop(1)[0]; color: rim.stop(1)[1] }
                    GradientStop { position: rim.stop(2)[0]; color: rim.stop(2)[1] }
                    GradientStop { position: rim.stop(3)[0]; color: rim.stop(3)[1] }
                    GradientStop { position: rim.stop(4)[0]; color: rim.stop(4)[1] }
                    GradientStop { position: rim.stop(5)[0]; color: rim.stop(5)[1] }
                }
                PathRectangle { x: ring.gap; y: ring.gap; width: ring.width - 2 * ring.gap; height: ring.height - 2 * ring.gap; radius: (ring.height - 2 * ring.gap) / 2 }
                PathRectangle {
                    x: ring.gap + ring.thick
                    y: ring.gap + ring.thick
                    width: Math.max(0, ring.width - 2 * (ring.gap + ring.thick))
                    height: Math.max(0, ring.height - 2 * (ring.gap + ring.thick))
                    radius: Math.max(0, (ring.height - 2 * (ring.gap + ring.thick)) / 2)
                }
            }
        }
    }
}
