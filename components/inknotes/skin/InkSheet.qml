import QtQuick
import QtQuick.Layouts

// A card over the window with a dimmed backdrop. Clicking outside, or Escape (the window handles it), closes it.
Item {
    id: root
    property string title: ""
    property bool open: false
    property real cardWidth: InkSkin.body * 28
    default property alias content: body.data
    signal closed()
    visible: root.open
    z: 20

    MouseArea { anchors.fill: parent; onClicked: root.closed() }
    Rectangle { anchors.fill: parent; color: InkSkin.scrim; opacity: 0.55 }
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(root.width - InkSkin.pad * 2, root.cardWidth)
        height: Math.min(root.height - InkSkin.pad * 2, column.implicitHeight + InkSkin.pad * 2)
        radius: InkSkin.radius
        color: InkSkin.sheet
        border.width: 1
        border.color: InkSkin.edge
        MouseArea { anchors.fill: parent }
        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: InkSkin.pad
            spacing: InkSkin.gap
            InkText { Layout.fillWidth: true; text: root.title; role: "title" }
            ColumnLayout { id: body; Layout.fillWidth: true; spacing: InkSkin.gap }
        }
    }
}
