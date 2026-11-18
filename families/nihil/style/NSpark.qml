import QtQuick

// A four-point flare. Sits on what is live; `size` is its reach, the rays fade inside it.
ShaderEffect {
    property real size: NihilStyle.s(28)
    property color tint: "#FFFFFF"

    width: size
    height: size
    visible: NihilStyle.sparks && opacity > 0
    fragmentShader: Qt.resolvedUrl("spark.frag.qsb")
}
