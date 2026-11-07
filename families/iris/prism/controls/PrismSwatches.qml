import QtQuick
import qs.services
import qs.modules.iris.prism.core

// Colour picks as discs: the chosen one grows and wears a check, never a ring.
Row {
    id: root
    property var choices: []      // { label, value, colour }
    property var current
    signal picked(var value)
    spacing: PrismTheme.dp(6)

    Repeater {
        model: root.choices
        delegate: Item {
            id: swatch
            required property var modelData
            readonly property bool chosen: modelData.value === root.current
            width: PrismTheme.dp(28)
            height: PrismTheme.dp(32)
            Rectangle {
                anchors.centerIn: parent
                width: swatch.chosen ? PrismTheme.dp(28) : area.containsMouse ? PrismTheme.dp(22) : PrismTheme.dp(18)
                height: width
                radius: width / 2
                color: swatch.modelData.colour
                Behavior on width { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutBack } }
                PrismGlyph {
                    anchors.centerIn: parent
                    visible: swatch.chosen
                    text: "check"
                    iconSize: PrismTheme.dp(16)
                    color: Qt.colorEqual(swatch.modelData.colour, "transparent") ? PrismTheme.ink
                        : (0.299 * swatch.modelData.colour.r + 0.587 * swatch.modelData.colour.g + 0.114 * swatch.modelData.colour.b) > 0.62
                        ? "#000000" : "#ffffff" // iris-literal: a check that reads on any swatch
                }
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(swatch.modelData.value)
            }
        }
    }
}
