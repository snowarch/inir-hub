pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common.functions
import qs.modules.iris.style

// The glass edge: a line all round and a light that fades smoothly down from the top, both antialiased along the
// curve. One shader draws both; a masked layer per edge cost two offscreen textures and a MultiEffect each.
ShaderEffect {
    id: root
    property real radius: 0
    readonly property real lineWidth: IrisStyle.edgeWidth * IrisStyle.devicePx
    readonly property bool shown: IrisStyle.glassEdgeLight > 0 || IrisStyle.glassEdgeLine > 0
    visible: root.shown

    blending: true
    fragmentShader: Qt.resolvedUrl("IrisGlassRim.frag.qsb")
    readonly property color fill: "transparent"
    readonly property color sheen: "transparent"
    readonly property color base: IrisStyle.glassEdgeLine > 0 ? ColorUtils.applyAlpha(IrisStyle.glassEdgeColour, IrisStyle.glassEdgeLine) : "transparent"
    readonly property color lit: IrisStyle.glassEdgeLight > IrisStyle.glassEdgeLine ? ColorUtils.applyAlpha(IrisStyle.glassEdgeColour, IrisStyle.glassEdgeLight) : "transparent"
    readonly property color lip: "transparent"
    readonly property vector4d fade: Qt.vector4d(0.55, 1, 0, 0)
    readonly property vector4d box: Qt.vector4d(Math.max(1, width), Math.max(1, height), root.radius, root.lineWidth)
    readonly property real aa: IrisStyle.devicePx
}
