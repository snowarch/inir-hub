import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import qs.modules.common.widgets

Item {
    id: root

    property int implicitSize: 18
    property int lineWidth: 2
    property real value: 0
    property color colPrimary: Appearance.colors.colOnSecondaryContainer
    property color colSecondary: ColorUtils.transparentize(colPrimary, 0.5)
    property real gapAngle: 360 / 18
    property bool fill: true
    property int fillOverflow: 2
    property bool enableAnimation: true
    property int animationDuration: 800
    property var easingType: Easing.OutCubic
    property bool accountForLightBleeding: true
    default property Item textMask: Item {
        width: implicitSize
        height: implicitSize
        StyledText {
            anchors.centerIn: parent
            text: Math.round(root.value * 100)
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.Medium
        }
    }

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    // The arc moves in half-pixel steps of its length, and only a visible jump (a seek, a new reading) eases. A
    // song's position, read four times a second, moved a small ring by a fraction of a pixel: each move redrew the
    // whole window, and an ease on every reading kept the window drawing at the screen's rate.
    readonly property real arcSteps: Math.max(1, Math.ceil(4 * Math.PI * root.arcRadius))
    property real degree: Math.round(root.value * root.arcSteps) / root.arcSteps * 360
    property real centerX: root.width / 2
    property real centerY: root.height / 2
    property real arcRadius: root.implicitSize / 2 - root.lineWidth / 2 - (0.5 * root.accountForLightBleeding)
    property real startAngle: -90

    Behavior on degree {
        enabled: root.enableAnimation && Math.abs(targetValue - root.degree) * root.arcSteps / 360 > 4
        NumberAnimation {
            duration: root.animationDuration
            easing.type: root.easingType
        }

    }

    Rectangle {
        id: contentItem
        anchors.fill: parent
        radius: implicitSize / 2
        color: root.colSecondary
        visible: false
        layer.enabled: true
        layer.smooth: true

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                id: primaryPath
                pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting
                strokeColor: root.colPrimary
                strokeWidth: root.lineWidth
                capStyle: ShapePath.RoundCap
                fillColor: root.colPrimary

                startX: root.centerX
                startY: root.centerY

                PathAngleArc {
                    moveToStart: false
                    centerX: root.centerX
                    centerY: root.centerY
                    radiusX: root.arcRadius
                    radiusY: root.arcRadius
                    startAngle: root.startAngle
                    sweepAngle: root.degree
                }
                PathLine {
                    x: primaryPath.startX
                    y: primaryPath.startY
                }
            }
        }
    }

    OpacityMask {
        anchors.fill: parent
        source: contentItem
        invert: true
        maskSource: root.textMask
    }
}
