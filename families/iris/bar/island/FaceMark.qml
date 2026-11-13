pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import qs.modules.iris.style

// Face ID: corner brackets, two eyes and a smile, sprung in as the screen unlocks.
Item {
    id: faceMark
    property color tint: IrisStyle.identity.green
    property bool live: false
    scale: faceMark.live ? 1 : 0.55
    opacity: faceMark.live ? 1 : 0
    Behavior on scale { NumberAnimation { duration: IrisStyle.duration(520); easing.type: Easing.OutBack; easing.overshoot: 2.2 } }
    Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(200); easing.type: IrisStyle.feedbackEasing } }
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        readonly property real w: width
        readonly property real k: width * 0.3
        readonly property real r: width * 0.16
        ShapePath {
            strokeColor: faceMark.tint
            strokeWidth: Math.max(1.6, faceMark.width * 0.075)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                readonly property real w: faceMark.width
                readonly property real k: faceMark.width * 0.28
                readonly property real r: faceMark.width * 0.16
                path: `M 0 ${k} L 0 ${r} Q 0 0 ${r} 0 L ${k} 0 `
                    + `M ${w - k} 0 L ${w - r} 0 Q ${w} 0 ${w} ${r} L ${w} ${k} `
                    + `M ${w} ${w - k} L ${w} ${w - r} Q ${w} ${w} ${w - r} ${w} L ${w - k} ${w} `
                    + `M ${k} ${w} L ${r} ${w} Q 0 ${w} 0 ${w - r} L 0 ${w - k} `
                    + `M ${w * 0.36} ${w * 0.34} L ${w * 0.36} ${w * 0.44} `
                    + `M ${w * 0.64} ${w * 0.34} L ${w * 0.64} ${w * 0.44} `
                    + `M ${w * 0.5} ${w * 0.36} L ${w * 0.5} ${w * 0.56} L ${w * 0.45} ${w * 0.56} `
                    + `M ${w * 0.34} ${w * 0.68} Q ${w * 0.5} ${w * 0.8} ${w * 0.66} ${w * 0.68}`
            }
        }
    }
}
