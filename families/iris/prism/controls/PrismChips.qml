import QtQuick
import qs.services
import qs.modules.iris.prism.core

// A folded choice laid out in place under its row: every option a chip, the chosen one solid.
Flow {
    id: root
    property var choices: []
    property var current
    signal picked(var value)
    spacing: PrismTheme.dp(6)

    Repeater {
        model: root.choices
        delegate: Item {
            id: chip
            required property var modelData
            readonly property bool chosen: JSON.stringify(modelData.value) === JSON.stringify(root.current)
            implicitWidth: label.implicitWidth + PrismTheme.dp(28)
            implicitHeight: PrismTheme.dp(30)
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: chip.chosen ? PrismTheme.solid : area.pressed ? PrismTheme.fillPress : area.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
                Behavior on color { ColorAnimation { duration: PrismTheme.ms(140) } }
            }
            PrismText {
                id: label
                anchors.centerIn: parent
                text: Translation.tr(chip.modelData.label)
                font.pixelSize: PrismTheme.small
                font.weight: Font.DemiBold
                color: chip.chosen ? PrismTheme.inkSolid : PrismTheme.ink
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(chip.modelData.value)
            }
        }
    }
}
