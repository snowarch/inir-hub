pragma ComponentBehavior: Bound

import QtQuick

// A glyph button of the tuner: a quiet plate on hover, the accent when it is the main action or on.
Item {
    id: root

    property var look
    property string glyph: ""
    property bool filled: false
    property bool accent: false        // the main action: an accent disc
    property bool on: false            // a kept star: the glyph in the accent
    property string label: ""
    property real size: Math.round(32 * (root.look?.d ?? 1))
    signal clicked()

    implicitWidth: root.size
    implicitHeight: root.size
    opacity: root.enabled ? 1 : 0.38
    scale: mouse.pressed ? (root.accent ? 0.92 : 0.96) : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Accessible.role: Accessible.Button
    Accessible.name: root.label

    Rectangle {
        anchors.fill: parent
        radius: root.accent ? width / 2 : Math.min(width / 2, root.look?.radiusSmall ?? 8)
        // A family with solid controls (Prism: white on dark) gives `solid`; the rest wear the accent.
        color: root.accent ? (mouse.pressed ? Qt.darker(root.look.solid ?? root.look.accent, 1.12) : root.look.solid ?? root.look.accent)
            : mouse.pressed ? root.look.press : mouse.containsMouse ? root.look.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    RadioGlyph {
        anchors.centerIn: parent
        look: root.look
        name: root.glyph
        filled: root.filled || root.on || root.accent
        size: Math.round(root.size * (root.accent ? 0.5 : 0.56))
        color: root.accent ? root.look.onSolid ?? root.look.onAccent : root.on ? root.look.accent : root.look.ink
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
