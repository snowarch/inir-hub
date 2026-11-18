import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// One sidebar line: glyph and name (B · Carpeta, his 11-17 pick). The open page stands on a plate tinted with the
// accent, its mark in the accent (his 11-18: the accent leads where you are); a hovered line takes a quiet plate.
Item {
    id: root
    property string glyph: "circle"
    property string text: ""
    property bool current: false
    property bool marked: root.current
    property string trailing: ""   // a glyph on the right, shown on hover (a pin's remove)
    property real edge: width      // where the sidebar ends
    signal clicked()
    signal trailingClicked()

    implicitHeight: PrismTheme.dp(34)
    Behavior on implicitHeight { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }

    // The open page: a plate in the accent's tint, no edge bar.
    Rectangle {
        visible: root.current
        x: -PrismTheme.dp(8)
        width: root.edge - x - PrismTheme.dp(10)
        height: parent.height
        radius: PrismTheme.dp(11)
        color: PrismTheme.accentPlate
    }
    Rectangle {
        visible: !root.current
        x: -PrismTheme.dp(8)
        width: root.edge - x - PrismTheme.dp(10)
        height: parent.height
        radius: PrismTheme.dp(11)
        color: area.containsMouse || tailArea.containsMouse ? PrismTheme.fill : "transparent"
    }
    Item {
        id: line
        width: parent.width
        height: parent.height
        PrismGlyph {
            id: icon
            x: PrismTheme.dp(2)
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            filled: root.current
            iconSize: PrismTheme.dp(18)
            color: root.current ? PrismTheme.accentInk : area.containsMouse ? PrismTheme.ink : PrismTheme.ink2
        }
        PrismText {
            anchors.left: icon.right
            anchors.leftMargin: PrismTheme.dp(11)
            anchors.right: tail.visible ? tail.left : parent.right
            anchors.rightMargin: PrismTheme.dp(6)
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            elide: Text.ElideRight
            font.pixelSize: PrismTheme.body
            font.weight: root.current ? Font.DemiBold : Font.Normal
            color: root.current || area.containsMouse ? PrismTheme.ink : PrismTheme.inkNav
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
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
    MouseArea {
        id: tailArea
        visible: tail.visible
        x: line.width - PrismTheme.dp(36)
        y: line.y
        width: PrismTheme.dp(30)
        height: line.height
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.trailingClicked()
    }
}
