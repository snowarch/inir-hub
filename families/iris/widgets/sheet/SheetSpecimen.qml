import QtQuick
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// A widget design drawn in its own manner, small, for its card in the sheet: iRiS's big figure, Prism's folder with
// its lit flap, Material's pill, the instrument's dial, the readout's ruled rows; any other design shows its glyph.
// On the chosen (solid) card the drawing takes the solid's ink.
Item {
    id: mark
    property string design: ""
    property string glyph: "widgets"
    property bool lit: false
    readonly property color ink: mark.lit ? PrismTheme.inkSolid : PrismTheme.ink2
    readonly property color faint: Qt.alpha(mark.ink, 0.18)
    readonly property real u: PrismTheme.dp(1)
    readonly property real line: Math.max(1, Math.round(1.5 * mark.u))
    readonly property var known: ["iris", "prism", "material", "instrument", "readout"]

    // iRiS: a plate with its head and a big figure.
    Rectangle {
        visible: mark.design === "iris"
        anchors.centerIn: parent
        width: 36 * mark.u
        height: 30 * mark.u
        radius: 9 * mark.u
        color: mark.faint
        Rectangle { x: 6 * mark.u; y: 6 * mark.u; width: 9 * mark.u; height: 3 * mark.u; radius: height / 2; color: PrismTheme.accent }
        PrismText {
            x: 5 * mark.u
            anchors.bottom: parent.bottom
            text: "21"
            color: mark.ink
            figures: true
            font.pixelSize: 17 * mark.u
            font.weight: Font.Bold
        }
    }

    // Prism: the folder, its dark tab, the flap lit in the accent, the clear pane and a beam through it.
    Item {
        visible: mark.design === "prism"
        anchors.centerIn: parent
        width: 40 * mark.u
        height: 32 * mark.u
        Rectangle { anchors.fill: parent; anchors.topMargin: 2 * mark.u; radius: 8 * mark.u; color: mark.faint }
        Rectangle { x: 0; y: 0; width: 20 * mark.u; height: 12 * mark.u; radius: 6 * mark.u; color: mark.faint }
        Rectangle { x: 23 * mark.u; y: 2 * mark.u; width: 15 * mark.u; height: 7 * mark.u; radius: height / 2; color: PrismTheme.accent }
        Rectangle { x: 0; y: 13 * mark.u; width: parent.width; height: 10 * mark.u; radius: 3 * mark.u; color: Qt.alpha(mark.ink, 0.22) }
        Rectangle {
            x: 4 * mark.u; y: 19 * mark.u; width: 22 * mark.u; height: mark.line; radius: height / 2
            rotation: -22; transformOrigin: Item.Left
            color: mark.lit ? PrismTheme.inkSolid : PrismTheme.ink
        }
        Rectangle { x: 6 * mark.u; y: 26 * mark.u; width: 14 * mark.u; height: 2 * mark.u; radius: mark.u; color: mark.ink }
    }

    // Material: a pill with its dot and two lines.
    Rectangle {
        visible: mark.design === "material"
        anchors.centerIn: parent
        width: 38 * mark.u
        height: 20 * mark.u
        radius: height / 2
        color: mark.faint
        Rectangle {
            id: materialDot
            x: 4 * mark.u
            anchors.verticalCenter: parent.verticalCenter
            width: 12 * mark.u
            height: width
            radius: width / 2
            color: PrismTheme.accent
        }
        Column {
            anchors.left: materialDot.right
            anchors.leftMargin: 4 * mark.u
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2 * mark.u
            Rectangle { width: 14 * mark.u; height: 3 * mark.u; radius: height / 2; color: mark.ink }
            Rectangle { width: 9 * mark.u; height: 3 * mark.u; radius: height / 2; color: Qt.alpha(mark.ink, 0.55) }
        }
    }

    // The instrument: a dial of twelve ticks and a hand.
    Item {
        visible: mark.design === "instrument"
        anchors.centerIn: parent
        width: 30 * mark.u
        height: width
        Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border.width: mark.line; border.color: Qt.alpha(mark.ink, 0.45) }
        Repeater {
            model: 12
            Item {
                id: tick
                required property int index
                anchors.fill: parent
                rotation: tick.index * 30
                Rectangle {
                    x: (parent.width - width) / 2
                    y: 4 * mark.u
                    width: mark.line
                    height: (tick.index % 3 === 0 ? 5 : 3) * mark.u
                    radius: width / 2
                    color: tick.index % 3 === 0 ? mark.ink : Qt.alpha(mark.ink, 0.5)
                }
            }
        }
        Item {
            anchors.fill: parent
            rotation: 52
            Rectangle { x: (parent.width - width) / 2; y: 6 * mark.u; width: 2 * mark.u; height: parent.height / 2 - y; radius: width / 2; color: PrismTheme.accent }
        }
    }

    // The readout: three ruled rows, name to value.
    Column {
        visible: mark.design === "readout"
        anchors.centerIn: parent
        spacing: 6 * mark.u
        Repeater {
            model: [12, 7, 10]
            Item {
                id: readRow
                required property int modelData
                required property int index
                width: 38 * mark.u
                height: 3 * mark.u
                Rectangle { id: readName; width: 9 * mark.u; height: parent.height; radius: mark.u; color: Qt.alpha(mark.ink, 0.55) }
                Rectangle {
                    id: readValue
                    anchors.right: parent.right
                    width: readRow.modelData * mark.u
                    height: parent.height
                    radius: mark.u
                    color: readRow.index === 0 ? PrismTheme.accent : mark.ink
                }
                Row {
                    anchors.left: readName.right
                    anchors.right: readValue.left
                    anchors.margins: 2 * mark.u
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2 * mark.u
                    clip: true
                    Repeater {
                        model: 8
                        Rectangle { width: mark.u; height: width; color: Qt.alpha(mark.ink, 0.5) }
                    }
                }
            }
        }
    }

    PrismGlyph {
        visible: !mark.known.includes(mark.design)
        anchors.centerIn: parent
        text: mark.glyph
        filled: true
        iconSize: PrismTheme.dp(24)
        color: mark.ink
    }
}
