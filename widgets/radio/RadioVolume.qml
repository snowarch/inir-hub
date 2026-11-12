pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// Volume: the speaker mutes, the bar sets it by click, drag or wheel. Heard at once; written when the hand stops.
Row {
    id: root

    property var look
    property real barWidth: Math.round(112 * (root.look?.d ?? 1))
    spacing: Math.round(4 * (root.look?.d ?? 1))

    RadioButton {
        anchors.verticalCenter: parent.verticalCenter
        look: root.look
        glyph: Radio.muted || Radio.liveVolume === 0 ? "volume_off" : "volume_up"
        label: Radio.muted ? Translation.tr("Unmute") : Translation.tr("Mute")
        onClicked: Radio.toggleMute()
    }
    Item {
        id: bar
        anchors.verticalCenter: parent.verticalCenter
        width: root.barWidth
        height: Math.round(28 * (root.look?.d ?? 1))
        readonly property real level: Radio.muted ? 0 : Radio.liveVolume / 100

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: Math.round(4 * (root.look?.d ?? 1))
            radius: height / 2
            color: root.look.track ?? root.look.line
            Rectangle {
                width: parent.width * bar.level
                height: parent.height
                radius: parent.radius
                color: root.look.accent
            }
        }
        Rectangle {
            readonly property real knob: Math.round((drag.containsMouse || drag.pressed ? 14 : 10) * (root.look?.d ?? 1))
            width: knob
            height: knob
            radius: knob / 2
            x: Math.round(bar.level * (bar.width - knob))
            anchors.verticalCenter: parent.verticalCenter
            color: root.look.accent
            Behavior on width { NumberAnimation { duration: 120 } }
        }
        MouseArea {
            id: drag
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function set(x: real): void { Radio.setVolume(Math.max(0, Math.min(1, x / width)) * 100) }
            onPressed: mouse => drag.set(mouse.x)
            onPositionChanged: mouse => { if (pressed) drag.set(mouse.x) }
            onWheel: wheel => Radio.nudgeVolume(wheel.angleDelta.y > 0 ? 1 : -1)
        }
        Accessible.role: Accessible.Slider
        Accessible.name: Translation.tr("Volume")
    }
}
