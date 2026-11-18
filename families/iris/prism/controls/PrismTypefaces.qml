pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// A choice of typefaces seen, not read (his 11-18): each one a card with "Ag" set in itself and its name under it, as a
// foundry shows its families. The chosen one stands solid. A face that is not installed is set in Prism's own.
Item {
    id: root
    property var choices: []
    property var current
    // What each card sets: letters for faces we read, a figure for the face of clocks and levels.
    property string sample: "Ag"
    signal picked(var value)

    readonly property real gap: PrismTheme.dp(8)
    readonly property int columns: Math.max(3, Math.floor((root.width + root.gap) / (PrismTheme.dp(96) + root.gap)))
    readonly property real cardWidth: Math.floor((root.width - (root.columns - 1) * root.gap) / root.columns)
    readonly property var families: Qt.fontFamilies()
    implicitHeight: grid.implicitHeight

    function same(a: var, b: var): bool { return String(a ?? "") === String(b ?? "") }
    // The face a choice sets: a pairing shows its title face (or its text face where that one is missing), a face
    // names itself, the default its label; what this computer lacks is set in Prism's own.
    function faceOf(choice: var): string {
        const named = Array.isArray(choice.values) ? [choice.values[1], choice.values[0]] : [choice.value, choice.label]
        return named.map(face => String(face ?? "")).find(face => face.length > 0 && root.families.includes(face)) ?? PrismTheme.fontMain
    }

    Grid {
        id: grid
        columns: root.columns
        spacing: root.gap
        Repeater {
            model: root.choices
            delegate: Rectangle {
                id: card
                required property var modelData
                readonly property bool chosen: root.same(card.modelData.value, root.current)
                readonly property color ink: card.chosen ? PrismTheme.inkSolid : PrismTheme.ink
                width: root.cardWidth
                height: PrismTheme.dp(86)
                radius: PrismTheme.dp(16)
                color: card.chosen ? PrismTheme.solid : hit.pressed ? PrismTheme.fillPress : hit.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
                Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
                PrismText {
                    x: PrismTheme.dp(12)
                    y: PrismTheme.dp(8)
                    text: root.sample
                    color: card.ink
                    font.family: root.faceOf(card.modelData)
                    font.pixelSize: PrismTheme.dp(34)
                    font.weight: Font.DemiBold
                }
                PrismText {
                    x: PrismTheme.dp(12)
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: PrismTheme.dp(10)
                    width: parent.width - PrismTheme.dp(24)
                    text: Translation.tr(String(card.modelData.label ?? ""))
                    color: card.ink
                    opacity: card.chosen ? 0.9 : 0.72
                    font.pixelSize: PrismTheme.small
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: hit
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(card.modelData.value)
                }
                Accessible.role: Accessible.RadioButton
                Accessible.checked: card.chosen
                Accessible.name: Translation.tr(String(card.modelData.label ?? ""))
            }
        }
    }
}
