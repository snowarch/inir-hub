pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// Volume: the speaker mutes, the bar sets it by click, drag or wheel. Heard at once; written when the hand stops.
Row {
    id: root

    property var look
    property real barWidth: Math.round(112 * (root.look?.d ?? 1))
    spacing: Math.round(4 * (root.look?.d ?? 1))

    readonly property bool prism: root.look?.grammar === "prism"

    // Prism's level: a pill that fills white from the left, the speaker and the figure inside it, the spectrum only at
    // its head. A tap on the speaker mutes; anywhere else sets the level.
    Item {
        id: level
        visible: root.prism
        anchors.verticalCenter: parent.verticalCenter
        width: root.prism ? Math.round(168 * (root.look?.d ?? 1)) : 0
        height: Math.round(34 * (root.look?.d ?? 1))
        readonly property real value: Radio.muted ? 0 : Radio.liveVolume / 100
        readonly property real reach: Math.max(height, width * level.value)
        Rectangle {
            id: well
            anchors.fill: parent
            radius: height / 2
            color: root.look.raised
            clip: true
            Rectangle {
                width: level.reach
                height: parent.height
                radius: parent.radius
                color: root.look.solid ?? root.look.accent
                visible: level.value > 0
                Rectangle {
                    anchors { right: parent.right; rightMargin: Math.round(parent.radius * 0.35); verticalCenter: parent.verticalCenter }
                    width: Math.max(2, Math.round(3 * (root.look?.d ?? 1)))
                    height: parent.height - Math.round(14 * (root.look?.d ?? 1))
                    radius: width / 2
                    gradient: Gradient {
                        GradientStop { position: 0; color: root.look.spectrum?.[0] ?? "transparent" }
                        GradientStop { position: 0.5; color: root.look.spectrum?.[3] ?? "transparent" }
                        GradientStop { position: 1; color: root.look.spectrum?.[6] ?? "transparent" }
                    }
                }
            }
        }
        RadioGlyph {
            id: speaker
            x: Math.round(11 * (root.look?.d ?? 1))
            anchors.verticalCenter: parent.verticalCenter
            look: root.look
            name: Radio.muted || Radio.liveVolume === 0 ? "volume_off" : Radio.liveVolume < 50 ? "volume_down" : "volume_up"
            filled: true
            size: Math.round(16 * (root.look?.d ?? 1))
            color: level.reach > speaker.x + speaker.width ? root.look.onSolid ?? root.look.onAccent : root.look.muted
        }
        Text {
            id: figure
            anchors.right: parent.right
            anchors.rightMargin: Math.round(13 * (root.look?.d ?? 1))
            anchors.verticalCenter: parent.verticalCenter
            text: String(Math.round(level.value * 100))
            font.family: root.look.font
            font.pixelSize: root.look.meta
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
            color: level.reach > figure.x + figure.width ? root.look.onSolid ?? root.look.onAccent : root.look.muted
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            property bool muting: false
            function set(x: real): void { Radio.setVolume(Math.max(0, Math.min(1, x / width)) * 100) }
            onPressed: mouse => {
                muting = mouse.x < speaker.x + speaker.width + Math.round(6 * (root.look?.d ?? 1))
                if (!muting) set(mouse.x)
            }
            onPositionChanged: mouse => { if (pressed && !muting) set(mouse.x) }
            onClicked: if (muting) Radio.toggleMute()
            onWheel: wheel => Radio.nudgeVolume(wheel.angleDelta.y > 0 ? 1 : -1)
        }
        Accessible.role: Accessible.Slider
        Accessible.name: Translation.tr("Volume")
    }

    RadioButton {
        visible: !root.prism
        anchors.verticalCenter: parent.verticalCenter
        look: root.look
        glyph: Radio.muted || Radio.liveVolume === 0 ? "volume_off" : "volume_up"
        label: Radio.muted ? Translation.tr("Unmute") : Translation.tr("Mute")
        onClicked: Radio.toggleMute()
    }
    Item {
        id: bar
        visible: !root.prism
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
