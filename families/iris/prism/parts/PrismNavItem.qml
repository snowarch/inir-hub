import QtQuick
import QtQuick.Shapes
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// One sidebar line: glyph, name and its number in the contents, printed small at the right as a book's contents page
// prints its page numbers (`.claude/ref/language`, Délavé's numbered dividers). The open one is a tab of the page
// itself (his 11-10, "más distinguible en dónde se está"): the page's sheet runs out through the column's edge to hold
// it, joined by soft inner corners, its glyph printed on the page's art and its name in the person's accent. A hovered
// line takes a quiet plate in Prism's grey.
Item {
    id: root
    property string glyph: "circle"
    property string text: ""
    property bool current: false
    // The accent bar at the sidebar's edge: on the open page, or on its open group when the page lists its groups.
    property bool marked: root.current
    property string trailing: ""   // a glyph on the right, shown on hover (a pin's remove)
    property real edge: width      // where the sidebar ends, for the bar and the tab
    property string tint: ""       // the page's art, worn by the open page's glyph
    property int number: 0         // its place in the contents
    signal clicked()
    signal trailingClicked()

    implicitHeight: PrismTheme.dp(30)
    readonly property bool tabbed: root.current && root.tint.length > 0
    // The plate: from a step left of the glyph to short of the edge, rounded like the row hover.
    Rectangle {
        visible: !root.tabbed
        x: -PrismTheme.dp(8)
        width: root.edge - x - PrismTheme.dp(14)
        height: parent.height
        radius: PrismTheme.dp(9)
        color: root.current ? PrismTheme.accentPlate : area.containsMouse || tailArea.containsMouse ? PrismTheme.fill : "transparent"
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
    }
    // The tab: the page's own sheet, out through the column's edge, its inner corners soft where it meets it.
    Shape {
        visible: root.tabbed
        x: -PrismTheme.dp(8)
        y: -fillet
        width: root.edge - x
        height: root.height + fillet * 2
        readonly property real fillet: PrismTheme.dp(10)
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: PrismTheme.canvas
            strokeColor: "transparent"
            strokeWidth: 0
            PathSvg {
                readonly property real w: root.edge + PrismTheme.dp(8)
                readonly property real h: root.height
                readonly property real f: PrismTheme.dp(10)
                readonly property real r: PrismTheme.dp(10)
                path: `M ${r} ${f} L ${w - f} ${f} Q ${w} ${f} ${w} 0 L ${w} ${h + f * 2} Q ${w} ${h + f} ${w - f} ${h + f} `
                    + `L ${r} ${h + f} Q 0 ${h + f} 0 ${h + f - r} L 0 ${f + r} Q 0 ${f} ${r} ${f} Z`
            }
        }
    }
    // The open page's glyph printed on its art, the cover its rows wear.
    PrismThumb {
        visible: root.tabbed
        x: PrismTheme.dp(1)
        anchors.verticalCenter: parent.verticalCenter
        size: PrismTheme.dp(22)
        glyph: root.glyph
        tint: root.tint
    }
    PrismGlyph {
        id: icon
        x: PrismTheme.dp(4)
        anchors.verticalCenter: parent.verticalCenter
        opacity: root.tabbed ? 0 : 1
        text: root.glyph
        filled: root.current
        iconSize: PrismTheme.dp(16)
        color: root.current ? PrismTheme.accentInk : area.containsMouse ? PrismTheme.ink : PrismTheme.inkNav
    }
    PrismText {
        anchors.left: icon.right
        anchors.leftMargin: PrismTheme.dp(12)
        anchors.right: tail.visible ? tail.left : numberText.visible ? numberText.left : parent.right
        anchors.rightMargin: PrismTheme.dp(6)
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        font.pixelSize: PrismTheme.body
        font.weight: root.current ? Font.DemiBold : Font.Normal
        color: root.current ? PrismTheme.accentInk : area.containsMouse ? PrismTheme.ink : PrismTheme.inkNav
    }
    PrismText {
        id: numberText
        visible: false // his 11-15: no numbering
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(18)
        anchors.verticalCenter: parent.verticalCenter
        text: String(root.number).padStart(2, "0")
        mono: true
        color: root.current ? PrismTheme.accentInk : PrismTheme.ink3
        opacity: root.current || area.containsMouse ? 1 : 0.7
        font.pixelSize: PrismTheme.caption - 1
        font.letterSpacing: 0.6
    }
    Rectangle {
        x: root.edge - width
        anchors.verticalCenter: parent.verticalCenter
        width: PrismTheme.dp(3)
        height: root.marked && !root.tabbed ? PrismTheme.dp(18) : 0
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
