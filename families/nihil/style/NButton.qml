import QtQuick

// NiHiL's button: a flat round piece (a circle, a squircle with `square`, a pill when it is wider than tall) with one
// glyph or its own content. `lit` paints it in the signal colour; `split` paints its left half lit, as the bar's tray
// chevron is.
Rectangle {
    id: root

    property string icon: ""
    property real iconSize: Math.round(Math.min(root.width, root.height) * 0.42)
    property bool lit: false
    property bool split: false
    property bool square: false
    property color tone: NihilStyle.piece
    property color ink: root.lit ? NihilStyle.onAccent : NihilStyle.ink
    readonly property bool hovered: mouse.containsMouse
    readonly property bool pressed: mouse.pressed
    property alias mouseArea: mouse
    default property alias content: holder.data

    signal clicked()
    signal rightClicked()

    implicitWidth: NihilStyle.button
    implicitHeight: NihilStyle.button
    radius: NihilStyle.keyRadius(width, height, root.square)
    color: root.lit ? NihilStyle.accent : root.hovered ? Qt.tint(root.tone, NihilStyle.hoverVeil) : root.tone
    scale: root.pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: NihilStyle.quick; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: NihilStyle.quick } }

    Item {
        visible: root.split
        width: Math.round(parent.width / 2)
        height: parent.height
        clip: true
        Rectangle { width: root.width; height: root.height; radius: root.radius; color: NihilStyle.accent }
    }

    NIcon {
        anchors.centerIn: parent
        visible: root.icon.length > 0
        text: root.icon
        size: root.iconSize
        color: root.ink
    }

    Item { id: holder; anchors.fill: parent }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => event.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}
