import QtQuick
import qs.services
import qs.modules.iris.prism.core

// Every Settings design as a small drawing of its panes, laid out under its row; the one in use stands on the solid
// card. Picking another opens it in Prism's place.
Flow {
    id: root
    property var choices: []
    property var current
    signal picked(var value)
    spacing: PrismTheme.dp(8)
    // Every design on one line while the room allows, each card as wide as its share.
    readonly property real cardWidth: Math.max(PrismTheme.dp(84), Math.min(PrismTheme.dp(124),
        (root.width - root.spacing * Math.max(0, root.choices.length - 1)) / Math.max(1, root.choices.length)))

    Repeater {
        model: root.choices
        delegate: Item {
            id: card
            required property var modelData
            readonly property bool chosen: card.modelData.value === root.current
            implicitWidth: Math.floor(root.cardWidth)
            implicitHeight: Math.round(root.cardWidth * 0.9)
            Rectangle {
                anchors.fill: parent
                radius: PrismTheme.dp(14)
                color: card.chosen ? PrismTheme.solid : area.pressed ? PrismTheme.fillPress : area.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
                Behavior on color { ColorAnimation { duration: PrismTheme.ms(160) } }
            }
            PrismSketch {
                x: PrismTheme.dp(12)
                y: PrismTheme.dp(12)
                width: card.width - PrismTheme.dp(24)
                height: card.height - PrismTheme.dp(50)
                shapes: PrismModel.drawing(card.modelData.value)
                lit: card.chosen
                scale: area.pressed ? 0.96 : 1
                Behavior on scale { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
            }
            PrismText {
                x: PrismTheme.dp(12)
                width: card.width - PrismTheme.dp(24)
                anchors.bottom: parent.bottom
                anchors.bottomMargin: PrismTheme.dp(10)
                text: Translation.tr(card.modelData.label)
                font.pixelSize: PrismTheme.small
                font.weight: Font.DemiBold
                color: card.chosen ? PrismTheme.inkSolid : PrismTheme.ink
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (!card.chosen) root.picked(card.modelData.value)
            }
        }
    }
}
