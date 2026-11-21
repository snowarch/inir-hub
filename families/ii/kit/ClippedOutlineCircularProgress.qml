pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property int implicitSize: 18
    property int lineWidth: 2
    property real value: 0
    property color colPrimary: Appearance?.colors.colOnSecondaryContainer ?? "#8EB840"
    property color colSecondary: ColorUtils.transparentize(colPrimary, 0.5) ?? "#888888"
    property real gapAngle: 360 / 18
    property bool enableAnimation: true
    property int animationDuration: 800
    property var easingType: Easing.OutCubic

    default property Item textMask: Item {}

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    // The arc moves in half-pixel steps of its length, and only a visible jump (a seek, a new reading) eases. A
    // song's position, read four times a second, moved a small ring by a fraction of a pixel: each move redrew the
    // whole window, and an ease on every reading kept the window drawing at the screen's rate.
    readonly property real arcSteps: Math.max(1, Math.ceil(4 * Math.PI * root.arcRadius))
    property real degree: Math.round(root.value * root.arcSteps) / root.arcSteps * 360
    property real centerX: root.width / 2
    property real centerY: root.height / 2
    property real arcRadius: root.implicitSize / 2 - root.lineWidth / 2
    property real startAngle: -90

    Behavior on degree {
        enabled: root.enableAnimation && Math.abs(targetValue - root.degree) * root.arcSteps / 360 > 4
        NumberAnimation {
            duration: root.animationDuration
            easing.type: root.easingType
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.colPrimary
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.centerX
                centerY: root.centerY
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: root.startAngle + root.gapAngle
                sweepAngle: root.degree - root.gapAngle * 2
            }
        }

        ShapePath {
            strokeColor: root.colSecondary
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.centerX
                centerY: root.centerY
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: root.startAngle + root.degree + root.gapAngle
                sweepAngle: 360 - root.degree - root.gapAngle * 2
            }
        }
    }

    Item {
        anchors.fill: parent
        children: [root.textMask]
    }
}
