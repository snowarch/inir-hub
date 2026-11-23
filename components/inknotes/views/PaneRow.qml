import QtQuick
import QtQuick.Layouts
import "../skin"

// One row of the folders pane.
Rectangle {
    id: root
    property string label: ""
    property string symbol: ""
    property string badge: ""
    property bool selected: false
    signal clicked()
    signal menu(point at)
    implicitHeight: Math.round(InkSkin.rowHeight * 0.8)
    radius: InkSkin.smallRadius
    color: root.selected ? InkSkin.rowOn : area.containsMouse ? InkSkin.hover : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: InkSkin.gap
        anchors.rightMargin: InkSkin.gap
        spacing: InkSkin.gap
        InkGlyph { name: root.symbol; color: root.selected ? InkSkin.rowOnInk : InkSkin.muted }
        InkText { Layout.fillWidth: true; text: root.label; color: root.selected ? InkSkin.rowOnInk : InkSkin.text }
        InkText { visible: root.badge !== ""; text: root.badge; role: "meta"; color: InkSkin.muted }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.menu(Qt.point(mouse.x, mouse.y)) : root.clicked()
    }
}
