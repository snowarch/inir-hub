import QtQuick
import qs.modules.nihil.style

// NiHiL's mark, drawn from dots: one dot in a ring (Start), or four dots on a grid (its menu).
Item {
    id: root
    property real size: 20
    property color color: NihilStyle.ink
    property bool grid: false
    // What the ring's hole shows: the piece the mark sits on.
    property color ground: NihilStyle.piece
    width: root.size
    height: root.size

    Grid {
        visible: root.grid
        anchors.centerIn: parent
        columns: 2
        spacing: root.size * 0.16
        Repeater {
            model: 4
            Rectangle {
                width: root.size * 0.42
                height: width
                radius: width / 2
                color: root.color
            }
        }
    }
    Rectangle {
        visible: !root.grid
        anchors.fill: parent
        radius: width / 2
        color: root.color
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.62
            height: width
            radius: width / 2
            color: root.ground
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.5
                height: width
                radius: width / 2
                color: root.color
            }
        }
    }
}
