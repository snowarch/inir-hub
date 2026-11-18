import QtQuick

// The layer effect that prints an icon or a cover in one bit.
ShaderEffect {
    fragmentShader: Qt.resolvedUrl("IrisInk.frag.qsb")
    readonly property vector4d frame: Qt.vector4d(width, height, Math.max(1, Math.min(3, Math.round(Math.min(width, height) / 64))), 0)
}
