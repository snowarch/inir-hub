import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// One sidebar line: glyph and name; the open one in full ink with the accent bar at the sidebar's edge.
Item {
    id: root
    property string glyph: "circle"
    property string text: ""
    property bool current: false
    property string trailing: ""   // a glyph on the right, shown on hover (a pin's remove)
    property real edge: width      // where the sidebar ends, for the bar
    signal clicked()
    signal trailingClicked()

    implicitHeight: PrismTheme.dp(30)
    PrismGlyph {
        id: icon
        x: PrismTheme.dp(4)
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        filled: root.current
        iconSize: PrismTheme.dp(16)
        color: root.current || area.containsMouse ? PrismTheme.ink : PrismTheme.ink2
    }
    PrismText {
        anchors.left: icon.right
        anchors.leftMargin: PrismTheme.dp(12)
        anchors.right: tail.visible ? tail.left : parent.right
        anchors.rightMargin: PrismTheme.dp(6)
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        font.pixelSize: PrismTheme.body
        font.weight: root.current ? Font.DemiBold : Font.Normal
        color: root.current || area.containsMouse ? PrismTheme.ink : PrismTheme.ink2
    }
    Rectangle {
        x: root.edge - width
        anchors.verticalCenter: parent.verticalCenter
        width: PrismTheme.dp(3)
        height: root.current ? PrismTheme.dp(18) : 0
        radius: width / 2
        color: PrismTheme.accent
        Behavior on height { NumberAnimation { duration: PrismTheme.ms(220); easing.type: Easing.OutCubic } }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
    PrismGlyph {
        id: tail
        visible: root.trailing.length > 0
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(14)
        anchors.verticalCenter: parent.verticalCenter
        text: root.trailing
        iconSize: PrismTheme.dp(15)
        color: tailArea.containsMouse ? PrismTheme.ink : PrismTheme.ink3
        opacity: area.containsMouse || tailArea.containsMouse ? 1 : 0.6
        MouseArea {
            id: tailArea
            anchors.fill: parent
            anchors.margins: -PrismTheme.dp(6)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.trailingClicked()
        }
    }
}
