import QtQuick
import QtQuick.Layouts
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// One pick drawn as what it gives, as Prism Settings draws its layouts: a card with the drawing on top and its name
// under it; the one in use stands on the solid card (never an outline).
Item {
    id: root
    property bool chosen: false
    property string label: ""
    // The drawing's room on the card; a host lays its drawing in `art`.
    property real artHeight: PrismTheme.dp(34)
    default property alias art: artBox.data
    readonly property bool hovered: area.containsMouse
    readonly property bool pressed: area.pressed
    signal picked()

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.maximumWidth: Number.POSITIVE_INFINITY
    implicitHeight: root.artHeight + PrismTheme.dp(40)

    Rectangle {
        anchors.fill: parent
        radius: PrismTheme.dp(14)
        color: root.chosen ? PrismTheme.solid : area.pressed ? PrismTheme.fillPress : area.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
    }
    Item {
        id: artBox
        x: PrismTheme.dp(6)
        y: PrismTheme.dp(8)
        width: root.width - PrismTheme.dp(12)
        height: root.artHeight
        scale: area.pressed ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
    }
    PrismText {
        x: PrismTheme.dp(4)
        width: root.width - PrismTheme.dp(8)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PrismTheme.dp(9)
        horizontalAlignment: Text.AlignHCenter
        text: root.label
        color: root.chosen ? PrismTheme.inkSolid : root.hovered ? PrismTheme.ink : PrismTheme.ink2
        font.pixelSize: PrismTheme.small
        font.weight: Font.DemiBold
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: PrismTheme.caption * 0.8
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
    }
    Accessible.role: Accessible.RadioButton
    Accessible.name: root.label
    Accessible.checked: root.chosen
}
