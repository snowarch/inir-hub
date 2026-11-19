import QtQuick
import qs.modules.nihil.style

// How full something is: a rounded track, filled with the accent's light up to the level.
Item {
    id: root

    property real level: 0
    property color tint: NihilStyle.accent
    property color ink: NihilStyle.ink
    readonly property bool lightFill: Qt.colorEqual(root.tint, NihilStyle.accent)
    readonly property real shown: NihilStyle.clamp(root.level, 0, 1)

    implicitHeight: NihilStyle.s(5)

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.height
        radius: height / 2
        color: Qt.alpha(root.ink, 0.14)
    }
    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(track.height, root.width * root.shown)
        height: track.height
        clip: true
        Behavior on width { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }

        Rectangle {
            width: root.width
            height: parent.height
            radius: height / 2
            color: root.tint
            gradient: root.lightFill ? fill : null
        }
        Gradient {
            id: fill
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: NihilStyle.specA }
            GradientStop { position: 1; color: NihilStyle.specB }
        }
    }
}
