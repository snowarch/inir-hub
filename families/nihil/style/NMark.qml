import QtQuick

// NiHiL's mark: a disc of the palette's light eclipsed by the void, a crescent of it left along the lower edge.
Item {
    id: root

    property real size: NihilStyle.s(24)
    // What the eclipsing body is painted with: the surface the mark sits on reads as the void.
    property color body: NihilStyle.void_

    implicitWidth: root.size
    implicitHeight: root.size
    width: root.size
    height: root.size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        gradient: Gradient {
            GradientStop { position: 0; color: NihilStyle.specB }
            GradientStop { position: 1; color: NihilStyle.specA }
        }
    }
    Rectangle {
        width: root.size * 0.8
        height: width
        radius: width / 2
        x: root.size * 0.14
        y: root.size * 0.02
        color: root.body
        border.width: Math.max(1, root.size / 48)
        border.color: Qt.alpha(NihilStyle.specB, 0.35)
    }
}
