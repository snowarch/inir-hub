import QtQuick
import qs.services
import qs.modules.iris.prism.core

// Colour picks as discs: the chosen one grows and wears a check, never a ring. Each disc says what it is (his 11-07:
// "no dice que carajo es cada chip de colorcito"): a caption under the disc under the pointer, else under the chosen
// one, hung below the discs so the row keeps its height and the discs never move.
Item {
    id: root
    property var choices: []      // { label, value, colour }
    property var current
    signal picked(var value)
    property int aimed: -1
    readonly property int chosenIndex: root.choices.findIndex(choice => choice.value === root.current)
    readonly property int namedIndex: root.aimed >= 0 ? root.aimed : root.chosenIndex
    readonly property real step: PrismTheme.dp(28) + discs.spacing
    implicitWidth: discs.implicitWidth
    implicitHeight: discs.implicitHeight

    PrismText {
        visible: root.namedIndex >= 0
        y: discs.height - PrismTheme.dp(2)
        x: Math.max(0, Math.min(root.width - width, root.namedIndex * root.step + PrismTheme.dp(14) - width / 2))
        text: Translation.tr(String(root.choices[root.namedIndex]?.label ?? ""))
        color: root.aimed >= 0 ? PrismTheme.ink : PrismTheme.ink2
        font.pixelSize: PrismTheme.caption
        font.weight: Font.DemiBold
    }

    Row {
        id: discs
        spacing: PrismTheme.dp(6)
        Repeater {
            model: root.choices
            delegate: Item {
                id: swatch
                required property var modelData
                required property int index
                readonly property bool chosen: modelData.value === root.current
                Accessible.role: Accessible.RadioButton
                Accessible.name: Translation.tr(String(modelData.label ?? ""))
                Accessible.checked: swatch.chosen
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
                    onContainsMouseChanged: if (containsMouse) root.aimed = swatch.index; else if (root.aimed === swatch.index) root.aimed = -1
                    onClicked: root.picked(swatch.modelData.value)
                }
            }
        }
    }
}
