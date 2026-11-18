import QtQuick

// Where the keyboard is: the one outline NiHiL draws, only while a piece holds focus from the Tab key.
Rectangle {
    property bool shown: false
    property real gap: NihilStyle.s(3)
    anchors.fill: parent
    anchors.margins: -gap
    // A key's content sits in a holder without corners of its own: the curve then follows the key's shape.
    radius: (parent.radius ?? NihilStyle.keyRadius(parent.width, parent.height, false)) + gap
    visible: shown
    color: "transparent"
    border.width: NihilStyle.s(2)
    border.color: NihilStyle.ink
}
