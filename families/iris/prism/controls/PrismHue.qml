import QtQuick
import qs.modules.iris.prism.core

// A hue as a fader: the spectrum is its groove and a key of the hue itself stands on it.
// A drag shows the hue as it goes; release writes it once.
Item {
    id: root
    property real value: 0
    property bool enabled_: true
    signal moved(real value)
    signal committed(real value)

    property real live: root.value
    property bool held: false
    onValueChanged: if (!root.held) root.live = root.value

    implicitWidth: PrismTheme.dp(240)
    implicitHeight: PrismTheme.dp(32)
    opacity: root.enabled_ ? 1 : 0.38

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: PrismTheme.dp(8)
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.hsva(0, 0.62, 1, 1) } // iris-literal: the hue track is every hue at Prism's spectrum strength
            GradientStop { position: 1 / 6; color: Qt.hsva(1 / 6, 0.62, 1, 1) } // iris-literal: the hue track
            GradientStop { position: 2 / 6; color: Qt.hsva(2 / 6, 0.62, 1, 1) } // iris-literal: the hue track
            GradientStop { position: 3 / 6; color: Qt.hsva(3 / 6, 0.62, 1, 1) } // iris-literal: the hue track
            GradientStop { position: 4 / 6; color: Qt.hsva(4 / 6, 0.62, 1, 1) } // iris-literal: the hue track
            GradientStop { position: 5 / 6; color: Qt.hsva(5 / 6, 0.62, 1, 1) } // iris-literal: the hue track
            GradientStop { position: 1; color: Qt.hsva(1, 0.62, 1, 1) } // iris-literal: the hue track
        }
    }
    // A key in the colour it stands on (the keycaps collage), the fader's cap in shape.
    PrismKey {
        id: knob
        width: PrismTheme.dp(28)
        height: PrismTheme.dp(20)
        radius: PrismTheme.dp(7)
        y: Math.round((root.height - height) / 2) - PrismTheme.dp(1)
        x: (root.width - width) * Math.max(0, Math.min(1, root.live / 360))
        face: Qt.hsva(Math.max(0, Math.min(1, root.live / 360)), 0.62, 1, 1) // iris-literal: the key wears the hue it stands on
        hovered: area.containsMouse
        down: area.pressed
    }
    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.enabled_
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        function at(x: real): real { return Math.round(Math.max(0, Math.min(1, (x - knob.width / 2) / Math.max(1, root.width - knob.width))) * 360) }
        onPressed: mouse => { root.held = true; root.live = area.at(mouse.x); root.moved(root.live) }
        onPositionChanged: mouse => { if (pressed) { root.live = area.at(mouse.x); root.moved(root.live) } }
        onReleased: { root.committed(root.live); root.held = false }
        onCanceled: { root.held = false; root.live = root.value }
    }
}
