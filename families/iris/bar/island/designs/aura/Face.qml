pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Aura: the Island ringed in the spectrum, as a phone's edge lights when its assistant listens; the time in the
// middle. The colours stand still at rest and turn once round while the pointer is over the Island.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property real contentWidth: clock.implicitWidth + Math.round(26 * root.d)
    readonly property real line: Math.max(1.5, Math.round(2 * root.d))
    property real turn: 30
    readonly property bool hovered: aura.hovered

    HoverHandler { id: aura }
    NumberAnimation on turn {
        running: root.hovered && IrisStyle.motionEnabled
        from: root.turn
        to: root.turn + 360
        duration: 2400
        loops: 1
    }

    Repeater {
        model: [{ inset: 0, alpha: 0.28, width: 5 }, { inset: 1.5, alpha: 1, width: 1 }]
        Shape {
            id: ring
            required property var modelData
            readonly property real gap: Math.round(ring.modelData.inset * root.d)
            readonly property real thick: root.line * ring.modelData.width
            anchors.fill: parent
            anchors.margins: Math.round(2 * root.d)
            opacity: ring.modelData.alpha
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillRule: ShapePath.OddEvenFill
                fillGradient: ConicalGradient {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    angle: root.turn
                    GradientStop { position: 0.0; color: IrisStyle.identity.blue }
                    GradientStop { position: 0.2; color: IrisStyle.identity.purple }
                    GradientStop { position: 0.4; color: IrisStyle.identity.pink }
                    GradientStop { position: 0.6; color: IrisStyle.identity.orange }
                    GradientStop { position: 0.8; color: IrisStyle.identity.green }
                    GradientStop { position: 1.0; color: IrisStyle.identity.blue }
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
    IrisClock {
        id: clock
        anchors.centerIn: parent
        family: IrisStyle.figureFace(pixelSize)
        minorFamily: family
        pixelSize: root.island?.figureSize ?? IrisStyle.typeHeadline
        separatorColor: root.island?.clockAccent ?? IrisStyle.accent
    }
}
