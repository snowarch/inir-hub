import QtQuick
import qs.modules.nihil.style

// A flat screen of ink over whatever is under it.
ShaderEffect {
    id: root
    property color ink: IrisStyle.text
    property real level: 0.5
    property real cell: Math.max(2, Math.round(2 * IrisStyle.density))
    fragmentShader: Qt.resolvedUrl("IrisDither.frag.qsb")
    readonly property vector4d frame: Qt.vector4d(width, height, root.cell, root.level)
}
