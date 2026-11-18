import QtQuick
import qs.modules.nihil.style

// How full something is, as a thin line of light.
Rectangle {
    id: root

    property real level: 0
    property color tint: NihilStyle.accent

    implicitHeight: NihilStyle.s(4)
    radius: height / 2
    color: NihilStyle.piece

    Rectangle {
        width: Math.max(parent.height, parent.width * NihilStyle.clamp(root.level, 0, 1))
        height: parent.height
        radius: parent.radius
        color: root.tint
        Behavior on width { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
    }
}
