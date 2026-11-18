import QtQuick

// A reading: the figure that leads the tile, its unit beside it, and the level drawn as strokes along the foot.
NTile {
    id: root

    property string figure: ""
    property string unit: ""
    property real figureSize: NihilStyle.s(38)
    // Below zero the tile has no level to draw.
    property real level: -1
    property int strokes: 20
    property color strokeColor: root.ink

    Row {
        x: root.pad
        anchors.bottom: strip.visible ? strip.top : parent.bottom
        anchors.bottomMargin: strip.visible ? NihilStyle.s(6) : root.pad - NihilStyle.s(4)
        spacing: NihilStyle.s(3)
        NFigure {
            id: number
            size: root.figureSize
            text: root.figure
            color: root.ink
        }
        NCaps {
            anchors.baseline: number.baseline
            visible: root.unit.length > 0
            text: root.unit
            color: root.inkSoft
        }
    }

    NTicks {
        id: strip
        visible: root.level >= 0
        x: root.pad
        width: root.width - root.pad * 2
        height: NihilStyle.s(14)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.pad
        count: root.strokes
        level: Math.max(0, root.level)
        litColor: root.strokeColor
    }
}
