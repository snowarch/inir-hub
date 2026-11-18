import QtQuick
import qs.services
import qs.modules.nihil.prism.core

// A folded choice laid out in place under its row: every option a key with its name printed on it, the chosen one
// solid (`.claude/ref/language`: the keycaps collage).
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
            implicitHeight: PrismTheme.dp(32)
            PrismKey {
                anchors.fill: parent
                face: chip.chosen ? PrismTheme.solid : PrismTheme.keyQuiet
                hovered: area.containsMouse
                down: area.pressed
                PrismText {
                    id: label
                    anchors.centerIn: parent
                    text: Translation.tr(chip.modelData.label)
                    font.pixelSize: PrismTheme.small
                    font.weight: Font.DemiBold
                    color: chip.chosen ? PrismTheme.inkSolid : PrismTheme.ink
                }
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
