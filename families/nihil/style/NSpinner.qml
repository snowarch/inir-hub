pragma ComponentBehavior: Bound

import QtQuick

// Working on it: a ring of dots, brighter toward its head. Still when hidden or when motion is off.
Item {
    id: root

    property real size: NihilStyle.s(22)
    property color color: NihilStyle.ink

    implicitWidth: root.size
    implicitHeight: root.size

    Repeater {
        model: 8
        Rectangle {
            required property int index
            readonly property real turn: index / 8 * Math.PI * 2
            readonly property real orbit: (root.size - width) / 2
            width: root.size * 0.2
            height: width
            radius: NihilStyle.squareDots ? 0 : width / 2
            x: root.size / 2 - width / 2 + Math.cos(turn) * orbit
            y: root.size / 2 - height / 2 + Math.sin(turn) * orbit
            color: root.color
            opacity: 0.2 + 0.8 * index / 7
        }
    }

    RotationAnimator on rotation {
        from: 0
        to: 360
        duration: 1100
        loops: Animation.Infinite
        running: root.visible && NihilStyle.motion
    }
}
