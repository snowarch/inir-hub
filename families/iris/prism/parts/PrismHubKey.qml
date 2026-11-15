import QtQuick
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// A key of the hub (`.claude/ref/language`): a kind with its count, a vote, a reaction. Its name and the figure it
// counts printed side by side; the chosen one is the white key.
Item {
    id: root
    property string label: ""
    property string glyph: ""
    property string count: ""
    property bool chosen: false
    property bool enabled_: true
    signal press()

    implicitWidth: line.implicitWidth + PrismTheme.dp(28)
    implicitHeight: PrismTheme.dp(34)
    opacity: root.enabled_ ? 1 : 0.45

    PrismKey {
        anchors.fill: parent
        radius: height / 2
        face: root.chosen ? PrismTheme.solid : PrismTheme.keyQuiet
        hovered: area.containsMouse && root.enabled_
        down: area.pressed && root.enabled_
        Row {
            id: line
            anchors.centerIn: parent
            spacing: PrismTheme.dp(6)
            PrismGlyph {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.glyph.length > 0
                text: root.glyph
                filled: root.chosen
                iconSize: PrismTheme.dp(16)
                color: root.chosen ? PrismTheme.inkSolid : PrismTheme.ink
            }
            PrismText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.label.length > 0
                text: root.label
                font.pixelSize: PrismTheme.small
                font.weight: Font.DemiBold
                color: root.chosen ? PrismTheme.inkSolid : PrismTheme.ink
            }
            PrismText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.count.length > 0
                text: root.count
                figures: true
                font.pixelSize: PrismTheme.caption
                font.weight: Font.DemiBold
                color: root.chosen ? PrismTheme.inkSolid : PrismTheme.ink3
                opacity: root.chosen ? 0.65 : 1
            }
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled_
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: root.label
        onClicked: root.press()
    }
}
