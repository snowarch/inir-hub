import QtQuick
import qs.services
import qs.modules.iris.prism.core

// A piece's mark picked from a few: each a squircle with its glyph, the worn one solid; the first is the piece's own,
// with a dot under it.
Flow {
    id: root
    property var glyphs: []
    property string current: ""
    property string ownGlyph: "circle"
    property bool enabled_: true
    signal picked(string glyph)
    spacing: PrismTheme.dp(6)
    opacity: root.enabled_ ? 1 : 0.38

    Repeater {
        model: [""].concat(Array.from(root.glyphs ?? []))
        delegate: Item {
            id: tile
            required property string modelData
            readonly property bool own: tile.modelData.length === 0
            readonly property bool chosen: tile.modelData === root.current
            width: PrismTheme.dp(38)
            height: width
            Rectangle {
                anchors.fill: parent
                radius: PrismTheme.dp(11)
                color: tile.chosen ? PrismTheme.solid : area.pressed ? PrismTheme.fillPress : area.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
                Behavior on color { ColorAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
            }
            PrismGlyph {
                anchors.centerIn: parent
                text: tile.own ? root.ownGlyph : tile.modelData
                filled: tile.chosen
                iconSize: PrismTheme.dp(18)
                color: tile.chosen ? PrismTheme.inkSolid : PrismTheme.ink
            }
            Rectangle {
                visible: tile.own
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: PrismTheme.dp(4)
                width: PrismTheme.dp(4)
                height: width
                radius: width / 2
                color: tile.chosen ? PrismTheme.inkSolid : PrismTheme.ink3
            }
            MouseArea {
                id: area
                anchors.fill: parent
                enabled: root.enabled_
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.RadioButton
                Accessible.name: tile.own ? Translation.tr("Default") : tile.modelData
                onClicked: root.picked(tile.modelData)
            }
        }
    }
}
