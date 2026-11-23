import QtQuick

// Buttons joined on one tonal, rounded plate.
Rectangle {
    id: root
    default property alias content: row.data
    implicitWidth: row.implicitWidth + InkSkin.small
    implicitHeight: row.implicitHeight + InkSkin.small
    radius: InkSkin.radius
    color: InkSkin.plate
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0
    }
}
