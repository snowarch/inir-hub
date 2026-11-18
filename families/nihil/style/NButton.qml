import QtQuick

// A press target: glass-quiet at rest, lit under the pointer. `icon` and `label` fill it; other content may sit inside.
MouseArea {
    id: root

    property string icon: ""
    property string label: ""
    property real iconSize: NihilStyle.s(18)
    property bool lit: false
    property color tone: NihilStyle.piece
    property real radius: NihilStyle.rKey
    readonly property color ink: root.lit ? NihilStyle.onAccent : NihilStyle.ink
    default property alias content: holder.data

    implicitWidth: root.label.length > 0 ? row.implicitWidth + NihilStyle.s(24) : NihilStyle.s(36)
    implicitHeight: NihilStyle.s(36)
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    activeFocusOnTab: true
    Keys.onSpacePressed: root.clicked(null)
    Keys.onReturnPressed: root.clicked(null)
    Accessible.role: Accessible.Button
    Accessible.name: root.label

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.lit ? NihilStyle.accent : root.pressed ? NihilStyle.pieceRaised
            : root.containsMouse || root.activeFocus ? NihilStyle.piece : root.tone
        scale: root.pressed ? 0.97 : 1
        Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
        Behavior on scale { NumberAnimation { duration: NihilStyle.quick } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: NihilStyle.s(7)
        NIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon.length > 0
            text: root.icon
            size: root.iconSize
            color: root.ink
        }
        NText {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label.length > 0
            text: root.label
            color: root.ink
        }
    }

    Item { id: holder; anchors.fill: parent }
}
