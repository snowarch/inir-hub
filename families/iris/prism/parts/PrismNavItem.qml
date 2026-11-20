import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// One sidebar line: its glyph on a small key, and its name. Where you stand reads at three levels (his 11-20: "no se sabe
// dónde se está"): the open page is the one thing in the list that wears the person's accent (its key filled with it, a
// quiet plate of it, its name in full ink a step larger, his 11-19 "un pequeño zoom"); the other pages of its chapter
// keep full ink; the rest step back to the secondary ink. Pointed, a line takes Prism's quiet fill.
Item {
    id: root
    property string glyph: "circle"
    property string text: ""
    property bool current: false
    // In the open page's chapter (or nothing is open): full ink. Elsewhere, the secondary ink.
    property bool inGroup: true
    property string trailing: ""   // a glyph on the right, shown on hover (a pin's remove)
    signal clicked()
    signal trailingClicked()

    implicitHeight: root.current ? PrismTheme.dp(38) : PrismTheme.dp(34)
    Behavior on implicitHeight { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
    readonly property bool pointed: area.containsMouse || tailArea.containsMouse

    Rectangle {
        anchors.fill: parent
        radius: PrismTheme.dp(10)
        color: root.current ? PrismTheme.accentPlate : area.pressed ? PrismTheme.fillPress : root.pointed ? PrismTheme.fill : "transparent"
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
    }
    Rectangle {
        id: icon
        x: PrismTheme.dp(6)
        anchors.verticalCenter: parent.verticalCenter
        width: PrismTheme.dp(26)
        height: width
        radius: PrismTheme.dp(8)
        // Light, the column is already frost: a key stands in white.
        color: root.current ? PrismTheme.accent : PrismTheme.light ? PrismTheme.raised : PrismTheme.keyQuiet
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
        PrismGlyph {
            anchors.centerIn: parent
            text: root.glyph
            filled: root.current
            iconSize: PrismTheme.dp(16)
            color: root.current ? PrismTheme.inkAccent : root.inGroup || root.pointed ? PrismTheme.ink : PrismTheme.ink2
        }
    }
    PrismText {
        anchors.left: icon.right
        anchors.leftMargin: PrismTheme.dp(10)
        anchors.right: tail.visible ? tail.left : parent.right
        anchors.rightMargin: PrismTheme.dp(8)
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        font.pixelSize: root.current ? PrismTheme.row : PrismTheme.body
        font.weight: root.current ? Font.DemiBold : root.inGroup ? Font.Medium : Font.Normal
        font.letterSpacing: root.current ? -PrismTheme.row * 0.01 : 0
        color: root.current || root.pointed ? PrismTheme.ink : root.inGroup ? PrismTheme.inkNav : PrismTheme.ink2
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
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
