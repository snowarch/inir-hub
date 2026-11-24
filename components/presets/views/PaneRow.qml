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
    implicitHeight: Math.round(PrSkin.rowHeight * 0.8)
    radius: PrSkin.radius
    color: root.selected ? PrSkin.rowOn : area.containsMouse ? PrSkin.hover : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: PrSkin.gap
        anchors.rightMargin: PrSkin.gap
        spacing: PrSkin.gap
        PrGlyph { name: root.symbol; color: root.selected ? PrSkin.rowOnInk : PrSkin.muted }
        PrText { Layout.fillWidth: true; text: root.label; color: root.selected ? PrSkin.rowOnInk : PrSkin.text }
        PrText { visible: root.badge !== ""; text: root.badge; role: "meta"; color: PrSkin.muted }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.menu(Qt.point(mouse.x, mouse.y)) : root.clicked()
    }
}
