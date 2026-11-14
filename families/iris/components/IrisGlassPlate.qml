pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
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
    // Body, sheen, bevel and lip in one shader pass: masked layers cost two offscreen textures and a MultiEffect per rim.
    ShaderEffect {
        anchors.fill: parent
        blending: true
        fragmentShader: Qt.resolvedUrl("IrisGlassRim.frag.qsb")
        // The body: clear, a breath of white over whatever is under it.
        readonly property color fill: Qt.rgba(1, 1, 1, root.light ? 0.46 : 0.085) // iris-literal: glass body
        // The sheen: light gathered in the upper half.
        readonly property color sheen: Qt.rgba(1, 1, 1, root.light ? 0.5 : 0.13) // iris-literal: sheen
        readonly property color base: "transparent"
        // The bevel: a bright rim fading down from the top.
        readonly property color lit: Qt.rgba(1, 1, 1, root.light ? 0.95 : 0.42) // iris-literal: specular rim
        // The lip: a darker rim rising from the bottom, the glass's thickness.
        readonly property color lip: Qt.rgba(0, 0, 0, root.light ? 0.14 : 0.4) // iris-literal: glass lip
        readonly property vector4d fade: Qt.vector4d(0.6, 0.55, 0.55, 0)
        readonly property vector4d box: Qt.vector4d(Math.max(1, width), Math.max(1, height), root.radius, root.line)
        readonly property real aa: IrisStyle.devicePx
    }
}
