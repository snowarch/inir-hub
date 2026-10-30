pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.modules.common.functions
import qs.modules.iris.style

// A control's glass (Button rows: Glass), built as Liquid Glass controls are: a clear body lifted off its surface, a
// sheen over its upper half, a bright bevel along the top, a darker lip along the bottom for its thickness, a soft
// shadow under it. It never reads the person's Edges setting: with edges off, glass was a flat fill (his 10-30).
// Sits under the control's content; the control's own colour stays transparent.
Item {
    id: root
    property real radius: height / 2
    readonly property bool light: IrisStyle.light
    readonly property real d: IrisStyle.density
    readonly property real line: Math.max(1, IrisStyle.devicePx)

    RectangularShadow {
        anchors.fill: parent
        radius: root.radius
        offset.y: Math.round(2 * root.d)
        blur: Math.round(10 * root.d)
        spread: -Math.round(2 * root.d)
        color: Qt.rgba(0, 0, 0, root.light ? 0.12 : 0.34) // iris-literal: shadow ink
    }
    // The body: clear, a breath of white over whatever is under it.
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Qt.rgba(1, 1, 1, root.light ? 0.46 : 0.085) // iris-literal: glass body
    }
    // The sheen: light gathered in the upper half.
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, root.light ? 0.5 : 0.13) } // iris-literal: sheen
            GradientStop { position: 0.55; color: "transparent" }
        }
    }
    // The bevel: a bright rim fading down from the top.
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        antialiasing: true
        border.width: root.line
        border.color: Qt.rgba(1, 1, 1, root.light ? 0.95 : 0.42) // iris-literal: specular rim
        layer.enabled: root.visible
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: topFade
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
    }
    // The lip: a darker rim rising from the bottom, the glass's thickness.
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        antialiasing: true
        border.width: root.line
        border.color: Qt.rgba(0, 0, 0, root.light ? 0.14 : 0.4) // iris-literal: glass lip
        layer.enabled: root.visible
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: bottomFade
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
    }
    Rectangle {
        id: topFade
        anchors.fill: parent
        visible: false
        layer.enabled: root.visible
        gradient: Gradient {
            GradientStop { position: 0; color: "white" }
            GradientStop { position: 0.6; color: "transparent" }
        }
    }
    Rectangle {
        id: bottomFade
        anchors.fill: parent
        visible: false
        layer.enabled: root.visible
        gradient: Gradient {
            GradientStop { position: 0.55; color: "transparent" }
            GradientStop { position: 1; color: "white" }
        }
    }
}
