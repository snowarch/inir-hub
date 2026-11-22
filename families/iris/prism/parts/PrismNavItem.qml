import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// One sidebar line: its glyph and its name, nothing behind them. Where you stand reads at three levels (his 11-20: "no se
// sabe dónde se está"): the open page alone wears the person's accent (its glyph filled with it, a quiet plate of it,
// its name in full ink a step larger, his 11-19 "un pequeño zoom"); the other pages of its chapter keep a name's weight;
// the rest are lighter, never greyer, and no glyph sits on a key (his 11-21: the keys and the grey read as one muted
// block). Pointed, a line takes Prism's quiet fill.
Item {
    id: root
    property string glyph: "circle"
    property string text: ""
    property bool current: false
    // In the open page's chapter (or nothing is open): a name's weight and the glyph in full ink. Elsewhere, lighter.
    property bool inGroup: true
    property string trailing: ""   // a glyph on the right, shown on hover (a pin's remove)
    // Something on the page differs from iNiR's (his 11-21: the dot that said where the changes were): a small dot at the
    // line's end, in the ink, as the page's parts mark theirs, so the accent still names only where you stand.
    property bool changed: false
    // The open page's plate is drawn here, or by the list, which slides one plate from page to page (PrismSidebar).
    property bool plate: true
    signal clicked()
    signal trailingClicked()

    implicitHeight: root.current ? PrismTheme.dp(38) : PrismTheme.dp(34)
    onCurrentChanged: if (root.current && PrismTheme.motion) pop.restart()
    Behavior on implicitHeight { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
    readonly property bool pointed: area.containsMouse || tailArea.containsMouse

    Rectangle {
        anchors.fill: parent
        radius: PrismTheme.dp(10)
        color: root.current && root.plate ? PrismTheme.accentPlate : area.pressed ? PrismTheme.fillPress
            : root.pointed && !root.current ? PrismTheme.fill : "transparent"
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
    }
    // The glyph on the line itself, in a box of one width so every name starts on the same pixel.
    Item {
        id: icon
        x: PrismTheme.dp(8)
        anchors.verticalCenter: parent.verticalCenter
        width: PrismTheme.dp(22)
        height: width
        // Chosen, the glyph lands: a short pop as it takes the accent.
        SequentialAnimation {
            id: pop
            NumberAnimation { target: icon; property: "scale"; to: 0.8; duration: PrismTheme.ms(70); easing.type: Easing.OutQuad }
            NumberAnimation { target: icon; property: "scale"; to: 1; duration: PrismTheme.ms(300); easing.type: Easing.OutBack; easing.overshoot: 2.4 }
        }
        PrismGlyph {
            anchors.centerIn: parent
            text: root.glyph
            filled: root.current
            iconSize: PrismTheme.dp(19)
            color: root.current ? PrismTheme.accentInk : root.inGroup || root.pointed ? PrismTheme.ink : PrismTheme.inkNav
            Behavior on color { ColorAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
        }
    }
    PrismText {
        anchors.left: icon.right
        anchors.leftMargin: PrismTheme.dp(10)
        anchors.right: tail.visible ? tail.left : parent.right
        anchors.rightMargin: root.changed && !tail.visible ? PrismTheme.dp(24) : PrismTheme.dp(8)
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        font.pixelSize: root.current ? PrismTheme.row : PrismTheme.body
        // A long name (any language) never cuts: it gives up the open page's step, then a pixel or two, to fit.
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: PrismTheme.small
        font.weight: root.current ? Font.DemiBold : root.inGroup ? Font.Medium : Font.Normal
        font.letterSpacing: root.current ? -PrismTheme.row * 0.01 : 0
        color: root.current || root.pointed ? PrismTheme.ink : PrismTheme.inkNav
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
    }
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(12)
        anchors.verticalCenter: parent.verticalCenter
        width: PrismTheme.dp(5)
        height: width
        radius: width / 2
        visible: scale > 0 && !tail.visible
        scale: root.changed ? 1 : 0
        // Quiet at rest: with many pages changed, bright dots out-shouted the names.
        color: root.current || root.pointed ? PrismTheme.ink : PrismTheme.ink2
        Behavior on scale { NumberAnimation { duration: PrismTheme.ms(220); easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
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
        Accessible.description: root.changed ? Translation.tr("Changed here") : ""
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
