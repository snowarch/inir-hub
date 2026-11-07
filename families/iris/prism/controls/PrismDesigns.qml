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

    // Each design's panes, read off the design itself: sidebar, page, rail, sheet.
    readonly property var drawings: ({
        prism: [
            { x: 0, y: 0, w: 0.22, h: 1, a: 0.16, r: 0.04 },
            { x: 0.26, y: 0.06, w: 0.46, h: 0.3, tone: "spectrum", r: 0.04 },
            { x: 0.26, y: 0.44, w: 0.46, h: 0.08, a: 0.22, r: 0.02 },
            { x: 0.26, y: 0.58, w: 0.46, h: 0.08, a: 0.22, r: 0.02 },
            { x: 0.26, y: 0.72, w: 0.46, h: 0.08, a: 0.22, r: 0.02 },
            { x: 0.76, y: 0, w: 0.24, h: 1, a: 0.1, r: 0.04 },
            { x: 0.8, y: 0.08, w: 0.08, h: 0.12, tone: "accent", r: 0.04 }
        ],
        classic: [
            { x: 0, y: 0, w: 0.28, h: 1, a: 0.14, r: 0.04 },
            { x: 0.05, y: 0.1, w: 0.18, h: 0.06, a: 0.3, r: 0.02 },
            { x: 0.05, y: 0.22, w: 0.14, h: 0.06, tone: "accent", r: 0.02 },
            { x: 0.05, y: 0.34, w: 0.16, h: 0.06, a: 0.3, r: 0.02 },
            { x: 0.34, y: 0.08, w: 0.3, h: 0.1, a: 0.4, r: 0.02 },
            { x: 0.34, y: 0.28, w: 0.62, h: 0.14, a: 0.12, r: 0.03 },
            { x: 0.34, y: 0.48, w: 0.62, h: 0.14, a: 0.12, r: 0.03 },
            { x: 0.34, y: 0.68, w: 0.62, h: 0.14, a: 0.12, r: 0.03 }
        ],
        folio: [
            { x: 0.22, y: 0.08, w: 0.56, h: 0.12, a: 0.4, r: 0.02 },
            { x: 0.22, y: 0.3, w: 0.56, h: 0.05, a: 0.22, r: 0.02 },
            { x: 0.22, y: 0.4, w: 0.5, h: 0.05, a: 0.22, r: 0.02 },
            { x: 0.22, y: 0.5, w: 0.56, h: 0.05, a: 0.22, r: 0.02 },
            { x: 0.22, y: 0.66, w: 0.56, h: 0.05, a: 0.22, r: 0.02 },
            { x: 0.22, y: 0.76, w: 0.38, h: 0.05, tone: "accent", r: 0.02 }
        ],
        pocket: [
            { x: 0.62, y: 0, w: 0.38, h: 1, a: 0.16, r: 0.05 },
            { x: 0.67, y: 0.1, w: 0.28, h: 0.08, a: 0.4, r: 0.02 },
            { x: 0.67, y: 0.28, w: 0.28, h: 0.1, a: 0.16, r: 0.03 },
            { x: 0.67, y: 0.44, w: 0.28, h: 0.1, tone: "accent", r: 0.03 },
            { x: 0.67, y: 0.6, w: 0.28, h: 0.1, a: 0.16, r: 0.03 },
            { x: 0.06, y: 0.1, w: 0.4, h: 0.05, a: 0.08, r: 0.02 }
        ],
        drawer: [
            { x: 0.04, y: 0.34, w: 0.92, h: 0.66, a: 0.16, r: 0.06 },
            { x: 0.44, y: 0.4, w: 0.12, h: 0.03, a: 0.4, r: 0.02 },
            { x: 0.1, y: 0.52, w: 0.24, h: 0.08, tone: "accent", r: 0.02 },
            { x: 0.38, y: 0.52, w: 0.2, h: 0.08, a: 0.3, r: 0.02 },
            { x: 0.62, y: 0.52, w: 0.2, h: 0.08, a: 0.3, r: 0.02 },
            { x: 0.1, y: 0.7, w: 0.8, h: 0.1, a: 0.12, r: 0.03 }
        ],
        original: [
            { x: 0, y: 0, w: 0.2, h: 1, a: 0.14, r: 0.04 },
            { x: 0.05, y: 0.1, w: 0.1, h: 0.14, tone: "accent", r: 0.03 },
            { x: 0.05, y: 0.32, w: 0.1, h: 0.14, a: 0.35, r: 0.03 },
            { x: 0.05, y: 0.54, w: 0.1, h: 0.14, a: 0.35, r: 0.03 },
            { x: 0.26, y: 0.08, w: 0.7, h: 0.84, a: 0.1, r: 0.04 },
            { x: 0.3, y: 0.18, w: 0.5, h: 0.05, a: 0.3, r: 0.02 },
            { x: 0.3, y: 0.34, w: 0.6, h: 0.05, a: 0.22, r: 0.02 },
            { x: 0.3, y: 0.5, w: 0.6, h: 0.05, a: 0.22, r: 0.02 },
            { x: 0.3, y: 0.66, w: 0.6, h: 0.05, a: 0.22, r: 0.02 }
        ]
    })

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
                shapes: root.drawings[card.modelData.value] ?? []
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
