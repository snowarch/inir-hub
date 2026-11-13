import QtQuick
import QtQuick.Layouts
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// One setting as a line of Prism's chart, at the sheet's size: its number, its name and the control on the right, on a
// hairline. A line with `tappable` is an action as a whole (its glyph at the right); `danger` names it in red. What a
// line lays under itself (a folded choice's chips) goes in `under`, as a Loader active only while it is out: what is
// in there counts in the line's height.
Item {
    id: root
    property int number: 1
    property string label: ""
    property string detail: ""
    property bool changed: false
    property bool tappable: false
    property bool danger: false
    property string glyph: ""
    property bool rule: true
    property real controlWidth: control.children.length > 0 ? control.children[0].implicitWidth : 0
    default property alias control: control.data
    property alias under: underBox.data
    readonly property bool hovered: hover.hovered
    signal tapped()
    // The lit number of a changed line puts its factory value back.
    signal restore()

    Layout.fillWidth: true
    readonly property real underHeight: {
        let sum = 0
        for (let i = 0; i < underBox.children.length; i++)
            sum += underBox.children[i].visible ? underBox.children[i].height : 0
        return sum
    }
    implicitHeight: line.height + (root.underHeight > 0 ? root.underHeight + PrismTheme.dp(12) : 0)
    Behavior on implicitHeight { NumberAnimation { duration: PrismTheme.ms(220); easing.type: Easing.OutCubic } }

    HoverHandler { id: hover; cursorShape: root.tappable ? Qt.PointingHandCursor : Qt.ArrowCursor }
    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -PrismTheme.dp(8)
        anchors.rightMargin: -PrismTheme.dp(8)
        radius: PrismTheme.dp(12)
        color: root.tappable && tap.pressed ? (root.danger ? Qt.alpha(PrismTheme.tint("red"), 0.18) : PrismTheme.fillPress)
            : root.hovered ? (root.danger ? Qt.alpha(PrismTheme.tint("red"), 0.1) : PrismTheme.fill) : "transparent"
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
    }
    TapHandler { id: tap; enabled: root.tappable; gesturePolicy: TapHandler.WithinBounds; onTapped: root.tapped() }

    Item {
        id: line
        width: parent.width
        height: Math.max(PrismTheme.dp(46), name.implicitHeight + PrismTheme.dp(16))

        PrismText {
            id: figure
            width: PrismTheme.dp(26)
            anchors.verticalCenter: parent.verticalCenter
            text: String(root.number).padStart(2, "0")
            figures: true
            color: root.changed ? PrismTheme.accent : PrismTheme.ink3
            font.pixelSize: PrismTheme.small
            font.weight: root.changed ? Font.Bold : Font.Normal
            HoverHandler { enabled: root.changed; cursorShape: Qt.PointingHandCursor }
            TapHandler { enabled: root.changed; onTapped: root.restore() }
        }
        Column {
            id: name
            anchors.left: figure.right
            anchors.right: control.left
            anchors.rightMargin: PrismTheme.dp(12)
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(1)
            PrismText {
                width: parent.width
                text: root.label
                color: root.danger ? PrismTheme.tint("red") : PrismTheme.ink
                font.pixelSize: PrismTheme.body
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
                maximumLineCount: 2
            }
            PrismText {
                width: parent.width
                visible: root.detail.length > 0
                text: root.detail
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.caption
            }
        }
        Item {
            id: control
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: root.tappable ? PrismTheme.dp(28) : root.controlWidth
            height: control.children.length > 0 ? control.children[0].implicitHeight : 0
        }
        PrismGlyph {
            visible: root.tappable && root.glyph.length > 0
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: PrismTheme.dp(28)
            height: PrismTheme.dp(28)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.glyph
            filled: true
            iconSize: PrismTheme.dp(18)
            color: root.danger ? PrismTheme.tint("red") : root.hovered ? PrismTheme.ink : PrismTheme.ink2
        }
        Rectangle {
            visible: root.rule
            anchors.left: name.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: PrismTheme.line
        }
    }
    Item {
        id: underBox
        anchors.top: line.bottom
        anchors.topMargin: PrismTheme.dp(4)
        x: name.x
        width: root.width - name.x
        height: root.underHeight
    }
}
