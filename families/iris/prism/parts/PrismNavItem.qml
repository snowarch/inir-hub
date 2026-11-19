import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// One sidebar line: glyph and name. The open page is the one thing in the list that wears the person's accent: a quiet
// plate of it, its glyph in the accent's ink and its name in full ink. Pointed, a line takes Prism's quiet fill.
Item {
    id: root
    property string glyph: "circle"
    property string text: ""
    property bool current: false
    property string trailing: ""   // a glyph on the right, shown on hover (a pin's remove)
    signal clicked()
    signal trailingClicked()

    implicitHeight: PrismTheme.dp(34)
    readonly property bool pointed: area.containsMouse || tailArea.containsMouse

    Rectangle {
        anchors.fill: parent
        radius: PrismTheme.dp(10)
        color: root.current ? PrismTheme.accentPlate : area.pressed ? PrismTheme.fillPress : root.pointed ? PrismTheme.fill : "transparent"
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
    }
    PrismGlyph {
        id: icon
        x: PrismTheme.dp(10)
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        filled: root.current
        iconSize: PrismTheme.dp(18)
        color: root.current ? PrismTheme.accentInk : root.pointed ? PrismTheme.ink : PrismTheme.ink2
    }
    PrismText {
        anchors.left: icon.right
        anchors.leftMargin: PrismTheme.dp(12)
        anchors.right: tail.visible ? tail.left : parent.right
        anchors.rightMargin: PrismTheme.dp(8)
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        font.pixelSize: PrismTheme.body
        font.weight: root.current ? Font.DemiBold : Font.Normal
        color: root.current || root.pointed ? PrismTheme.ink : PrismTheme.inkNav
    }
    PrismGlyph {
        id: tail
        visible: root.trailing.length > 0 && root.pointed
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(10)
        anchors.verticalCenter: parent.verticalCenter
        text: root.trailing
        iconSize: PrismTheme.dp(15)
        color: tailArea.containsMouse ? PrismTheme.ink : PrismTheme.ink2
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.PageTab
        Accessible.name: root.text
        onClicked: root.clicked()
    }
    MouseArea {
        id: tailArea
        visible: root.trailing.length > 0
        anchors.right: parent.right
        width: PrismTheme.dp(34)
        height: parent.height
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: Translation.tr("Unpin")
        onClicked: root.trailingClicked()
    }
}
