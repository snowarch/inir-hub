import QtQuick
import QtQuick.Effects
import qs.modules.iris.style

// A floating body's soft shadow, in place of a bare RectangularShadow and with the same properties. Round, it is that
// RectangularShadow. Under a Kiri Design it is the same ramp measured from the body's Kiri outline (IrisField.frag
// kiriBox, `radius` its radius, 0 the Design's own): RectangularShadow rounds every corner by most of its blur, so a cut
// corner stood over a round shade.
Item {
    id: root

    property real radius: 0
    property real blur: 0
    property real spread: 0
    property color color: "black"
    property vector2d offset: Qt.vector2d(0, 0)
    readonly property real reach: Math.ceil(1.3 * root.blur + Math.max(0, root.spread)) + 1

    RectangularShadow {
        anchors.fill: parent
        visible: !IrisStyle.fieldChamfer
        radius: root.radius
        blur: root.blur
        spread: root.spread
        offset: root.offset
        color: root.color
    }
    ShaderEffect {
        visible: IrisStyle.fieldChamfer && root.width > 0 && root.height > 0
        x: root.offset.x - root.reach
        y: root.offset.y - root.reach
        width: root.width + 2 * root.reach
        height: root.height + 2 * root.reach
        blending: true
        fragmentShader: Qt.resolvedUrl("IrisBodyShadow.frag.qsb")
        readonly property color shade: root.color
        readonly property vector4d box: Qt.vector4d(width, height, root.reach, root.spread)
        readonly property vector4d cut: Qt.vector4d(root.radius > 0.5 ? root.radius : IrisStyle.chamferCut / IrisStyle.kiriCut, root.blur, 0, 0)
    }
}
