import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// A tile of something a person flips or reads often (Home's Every day, a page's lead), in the grammar of the Apple
// widget set: the state as a disc (the accent when on), the name and what it holds now under it. A press acts.
Item {
    id: root
    property string glyph: "tune"
    property string label: ""
    property string says: ""
    property bool on: false
    property bool isSwitch: true
    // Offered to add (Home's Edit): faint until pointed, a plus for its mark.
    property bool offer: false
    // Home's Edit: the tile comes off from its corner.
    property bool removable: false
    signal clicked()
    signal removeClicked()

    // As tall as its words: a long name in a long language takes two lines, never an ellipsis mid-word.
    readonly property real need: Math.max(PrismTheme.dp(56), words.implicitHeight + PrismTheme.dp(18))
    implicitHeight: root.need
    opacity: root.offer ? (press.containsMouse ? 0.9 : 0.55) : 1
    Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: PrismTheme.dp(16)
        // On, the tile lifts a little under its accent disc; no outline, its fill alone sets it off.
        color: press.pressed ? PrismTheme.fillPress : press.containsMouse || root.on ? PrismTheme.fillHover : PrismTheme.fill
        scale: press.pressed ? 0.97 : 1
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
    }
    Rectangle {
        id: mark
        x: PrismTheme.dp(8)
        anchors.verticalCenter: parent.verticalCenter
        width: PrismTheme.dp(36); height: width; radius: width / 2
        // Off, a quiet disc a step over the tile; on, the accent.
        color: root.on ? PrismTheme.accent : PrismTheme.fillPress
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(180); easing.type: Easing.OutCubic } }
        PrismGlyph {
            anchors.centerIn: parent
            text: root.offer ? "add" : root.glyph
            filled: root.on
            iconSize: PrismTheme.dp(18)
            color: root.on ? PrismTheme.inkAccent : PrismTheme.ink2
        }
    }
    Column {
        id: words
        anchors.left: mark.right
        anchors.leftMargin: PrismTheme.dp(10)
        anchors.right: parent.right
        anchors.rightMargin: root.removable ? PrismTheme.dp(40) : PrismTheme.dp(12)
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
        PrismText {
            width: parent.width
            text: root.label
            font.pixelSize: PrismTheme.body
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            lineHeight: 1.05
        }
        PrismText {
            visible: text.length > 0
            width: parent.width
            text: root.says
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.small
        }
    }
    MouseArea {
        id: press
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: root.isSwitch ? Accessible.CheckBox : Accessible.Button
        Accessible.name: root.label
        Accessible.checked: root.on
        onClicked: root.clicked()
    }
    PrismRound {
        visible: root.removable
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(10)
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: PrismTheme.dp(24)
        glyphSize: PrismTheme.dp(15)
        glyph: "remove"
        onClicked: root.removeClicked()
    }
}
