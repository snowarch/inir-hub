pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.iris.prism.core

// The sizes a widget comes in, each drawn as the room it takes on the grid: one cell, two side by side, a square of
// four. The one it has stands on the solid card.
RowLayout {
    id: root
    required property var widget
    Layout.fillWidth: true
    spacing: PrismTheme.dp(6)

    Repeater {
        model: root.widget.sizeChoices
        SheetCard {
            id: card
            required property string modelData
            readonly property real cell: PrismTheme.dp(13)
            readonly property real gap: PrismTheme.dp(3)
            chosen: root.widget.sizeClass === card.modelData
            label: root.widget.sizeLabels[card.modelData] ?? card.modelData
            onPicked: root.widget.commitSize(card.modelData)
            Grid {
                anchors.centerIn: parent
                columns: 2
                spacing: card.gap
                Repeater {
                    model: 4
                    Rectangle {
                        required property int index
                        readonly property bool taken: card.modelData === "large" || index === 0 || (card.modelData === "medium" && index === 1)
                        visible: taken || card.modelData === "large" || index < 2
                        width: card.cell
                        height: card.cell
                        radius: PrismTheme.dp(4)
                        color: !taken ? Qt.alpha(card.chosen ? PrismTheme.inkSolid : PrismTheme.ink, 0.12)
                            : card.chosen ? PrismTheme.inkSolid : card.hovered ? PrismTheme.ink : PrismTheme.ink2
                    }
                }
            }
        }
    }
}
