import QtQuick

// The light as a line: the palette's spectrum laid along its width. What fills a level, marks the live thing.
Rectangle {
    id: root

    readonly property bool full: NihilStyle.rainbow >= 0.5
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: root.full ? "#FF4D3A" : NihilStyle.specA }
        GradientStop { position: 0.25; color: root.full ? "#FFB23E" : Qt.tint(NihilStyle.specA, "#55FFFFFF") }
        GradientStop { position: 0.5; color: root.full ? "#F2F0E8" : "#F2F0E8" }
        GradientStop { position: 0.75; color: root.full ? "#4CC9FF" : Qt.tint(NihilStyle.specB, "#55FFFFFF") }
        GradientStop { position: 1.0; color: root.full ? "#8A63FF" : NihilStyle.specB }
    }
}
