import QtQuick

// A level set by hand along a tile: its name and figure above, a row of strokes under them, the last one lit in the
// signal. Drag or wheel; `opens` adds a key that leads to the level's own list.
NTile {
    id: root

    property real value: 0
    property string figure: Math.round(root.value * 100) + "%"
    property bool opens: false
    signal moved(real value)
    signal opened()

    readonly property real share: NihilStyle.clamp(root.value, 0, 1)

    function at(px: real): real { return NihilStyle.clamp((px - root.pad) / (root.width - root.pad * 2), 0, 1) }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: event => root.moved(root.at(event.x))
        onPositionChanged: event => { if (pressed) root.moved(root.at(event.x)) }
        onWheel: event => root.moved(NihilStyle.clamp(root.share + (event.angleDelta.y > 0 ? 0.05 : -0.05), 0, 1))
    }

    NFigure {
        anchors.right: more.visible ? more.left : parent.right
        anchors.rightMargin: more.visible ? NihilStyle.s(8) : root.pad
        y: NihilStyle.s(6)
        size: NihilStyle.s(24)
        text: root.figure
        color: root.ink
    }

    NButton {
        id: more
        visible: root.opens
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.s(6)
        y: NihilStyle.s(6)
        width: NihilStyle.s(30); height: width
        tone: NihilStyle.pieceRaised
        icon: "chevron_right"
        iconSize: NihilStyle.s(18)
        onClicked: root.opened()
    }

    NTicks {
        x: root.pad
        width: root.width - root.pad * 2
        height: NihilStyle.s(18)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: NihilStyle.s(12)
        count: 40
        level: root.share
        marked: true
        litColor: root.ink
    }
}
