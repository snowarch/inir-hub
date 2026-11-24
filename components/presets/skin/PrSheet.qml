import QtQuick
import QtQuick.Layouts

// A titled card centred over a dimmed window. A click outside it emits closed(); the window's Escape does the same.
Item {
    id: root
    property string title: ""
    property bool open: false
    property real cardWidth: PrSkin.body * 28
    default property alias content: body.data
    signal closed()
    visible: open
    z: 20

    Rectangle {
        anchors.fill: parent
        color: PrSkin.scrim
        MouseArea { anchors.fill: parent; onClicked: root.closed() }
    }
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(root.width - PrSkin.pad * 2, root.cardWidth)
        height: Math.min(root.height - PrSkin.pad * 2, stack.implicitHeight + PrSkin.pad * 2)
        radius: PrSkin.cardRadius
        color: PrSkin.sheet
        border.width: 1
        border.color: PrSkin.edge
        MouseArea { anchors.fill: parent }
        ColumnLayout {
            id: stack
            anchors.fill: parent
            anchors.margins: PrSkin.pad
            spacing: PrSkin.gap
            PrText { Layout.fillWidth: true; text: root.title; role: "title" }
            ColumnLayout { id: body; Layout.fillWidth: true; spacing: PrSkin.gap }
        }
    }
}
