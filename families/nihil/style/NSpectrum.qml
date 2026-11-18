import QtQuick

// The accent as light: a line that runs from one of the palette's lights to the other. Fills a level, marks what is on.
Rectangle {
    id: root

    property bool vertical: false
    gradient: Gradient {
        orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal
        GradientStop { position: 0.0; color: NihilStyle.specA }
        GradientStop { position: 1.0; color: NihilStyle.specB }
    }
}
