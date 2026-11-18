import QtQuick

// NiHiL's tile: a flat block with one glyph or its own content. `lit` prints it in the signal colour, `paper` the other
// way round (white on a dark desk), the lead of its block.
Rectangle {
    id: root

    property string icon: ""
    property real iconSize: Math.round(Math.min(root.width, root.height) * 0.46)
    property bool lit: false
    property bool paper: false
    property bool square: false
    // A tile that only shows something leaves the hand alone.
    property bool interactive: true
    property color tone: NihilStyle.piece
    property color ink: root.lit ? NihilStyle.onAccent : root.paper ? NihilStyle.onPlate : NihilStyle.ink
    readonly property bool hovered: mouse.containsMouse
    readonly property bool pressed: mouse.pressed
    property alias mouseArea: mouse
    default property alias content: holder.data

    signal clicked()
    signal rightClicked()

    implicitWidth: NihilStyle.button
    implicitHeight: NihilStyle.button
    radius: NihilStyle.keyRadius(width, height, root.square)
    color: root.lit ? NihilStyle.accent : root.paper ? NihilStyle.plate
        : root.hovered ? Qt.tint(root.tone, NihilStyle.hoverVeil) : root.tone
    scale: root.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: NihilStyle.quick; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: NihilStyle.quick } }

    NIcon {
        anchors.centerIn: parent
        visible: root.icon.length > 0
        text: root.icon
        size: root.iconSize
        color: root.ink
    }

    // Above the tile's own hand: a key inside answers for itself, words and glyphs let every other click through.
    Item { id: holder; anchors.fill: parent; z: 1 }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => event.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}
