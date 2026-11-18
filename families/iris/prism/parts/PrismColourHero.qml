pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.fx
import qs.modules.iris.prism.controls

// Colour's head (his 11-18: "más énfasis en la estética visual de acentos y colores", "menos colorcitos locos"): each
// colour iRiS wears drawn as light, the page's own art lit in that one colour over the night, not a flat chip. The
// accent leads, wider; each says its role, its name and what it is now, and a press goes to its group.
Item {
    id: root
    signal pickGroup(string title)

    readonly property real gap: PrismTheme.dp(10)
    readonly property real cardHeight: PrismTheme.dp(176)
    implicitHeight: root.cardHeight

    readonly property var roles: [
        { group: "Accent", name: "Accent", use: "Switches, levels, the chosen", path: "iris.appearance.accent", share: 1.7, get colour() { return IrisStyle.accent } },
        { group: "Highlight", name: "Highlight", use: "The glanced detail", path: "iris.appearance.highlight", share: 1, get colour() { return IrisStyle.secondaryAccent } },
        { group: "Signal", name: "Signal", use: "Live, urgent, final", path: "iris.appearance.signal", share: 1, get colour() { return IrisStyle.signal } }
    ].filter(role => role.group !== "Highlight" || !IrisStyle.mono)
    readonly property real shares: root.roles.reduce((sum, role) => sum + role.share, 0)

    Row {
        width: root.width
        height: root.cardHeight
        spacing: root.gap
        Repeater {
            model: root.roles
            delegate: Item {
                id: card
                required property var modelData
                required property int index
                readonly property var row: PrismModel.find(card.modelData.path)
                readonly property string said: { const _ = PrismModel.revision; return card.row ? PrismModel.sayNow(card.row) : "" }
                readonly property color c: card.modelData.colour
                readonly property color onArt: PrismTheme.light ? PrismTheme.ink : PrismTheme.paper
                width: Math.floor((root.width - root.gap * (root.roles.length - 1)) * card.modelData.share / root.shares)
                height: root.cardHeight

                PrismFlow {
                    anchors.fill: parent
                    radius: PrismTheme.dp(22)
                    palette: [Qt.darker(card.c, 1.35), card.c, Qt.lighter(card.c, 1.22)]
                    seed: 0.17 + card.index * 0.31
                    centre: Qt.point(0.72, 0.28)
                    thickness: 0.8
                    strength: PrismTheme.light ? 0.85 : 1
                }
                // The pointer shades the card; nothing grows.
                Rectangle {
                    anchors.fill: parent
                    radius: PrismTheme.dp(22)
                    color: card.onArt
                    opacity: hit.pressed ? 0.1 : hit.containsMouse ? 0.05 : 0
                    Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
                }
                PrismText {
                    x: PrismTheme.dp(18)
                    y: PrismTheme.dp(16)
                    width: parent.width - PrismTheme.dp(36)
                    text: Translation.tr(card.modelData.use)
                    color: ColorUtils.applyAlpha(card.onArt, 0.72) // iris-literal: the role's use, quiet on its own light
                    font.pixelSize: PrismTheme.small
                    elide: Text.ElideRight
                }
                Column {
                    x: PrismTheme.dp(18)
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: PrismTheme.dp(16)
                    width: parent.width - PrismTheme.dp(36)
                    spacing: PrismTheme.dp(1)
                    PrismText {
                        width: parent.width
                        text: Translation.tr(card.modelData.name)
                        color: card.onArt
                        font.pixelSize: PrismTheme.dp(22)
                        font.weight: Font.Bold
                        font.letterSpacing: -PrismTheme.dp(22) * 0.025
                        elide: Text.ElideRight
                    }
                    PrismText {
                        width: parent.width
                        visible: card.said.length > 0
                        text: card.said
                        color: ColorUtils.applyAlpha(card.onArt, 0.62) // iris-literal: the value, the second tone of the name
                        font.pixelSize: PrismTheme.dp(22)
                        font.weight: Font.Bold
                        font.letterSpacing: -PrismTheme.dp(22) * 0.025
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    id: hit
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pickGroup(card.modelData.group)
                }
                Accessible.role: Accessible.Button
                Accessible.name: Translation.tr(card.modelData.name) + ", " + card.said
            }
        }
    }
}
