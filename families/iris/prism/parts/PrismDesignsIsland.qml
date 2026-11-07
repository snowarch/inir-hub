pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import qs.services
import qs.modules.iris.components
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// The Settings designs as a Dynamic Island at the top of every Settings window: a short dark pill while nothing asks
// for it; aimed at, it grows into a black island holding each design drawn small, the one in use on the white card.
// A press wears that design (`picked`; the host decides how). Black in every scheme, as Apple's island is.
Item {
    id: root
    // The design in use, and the width the island may take.
    property string current: "prism"
    property real room: 640
    signal picked(string design)

    readonly property var designs: PrismModel.designs
    readonly property int count: root.designs.length
    readonly property real pad: PrismTheme.dp(14)
    readonly property real gap: PrismTheme.dp(8)
    readonly property real tileWidth: Math.max(PrismTheme.dp(68), Math.min(PrismTheme.dp(100),
        (root.room - PrismTheme.dp(32) - 2 * root.pad - (root.count - 1) * root.gap) / root.count))
    readonly property real sketchHeight: Math.round(root.tileWidth * 0.62)
    readonly property real fullWidth: Math.round(2 * root.pad + root.count * root.tileWidth + (root.count - 1) * root.gap)
    readonly property real fullHeight: Math.round(root.pad + captionLine.height + PrismTheme.dp(10) + root.sketchHeight
        + PrismTheme.dp(8) + PrismTheme.small * 1.3 + root.pad)
    readonly property real restWidth: PrismTheme.dp(64)
    readonly property real restHeight: PrismTheme.dp(6)

    // Aimed at for a beat opens it; leaving it lets it go after a breath, so a pass on the way to the window's edge
    // never opens it and a slip off its rim never closes it.
    readonly property bool aimed: zoneHover.hovered
    property bool open: false
    onAimedChanged: {
        if (root.aimed) { closeTimer.stop(); openTimer.restart() }
        else { openTimer.stop(); closeTimer.restart() }
    }
    Timer { id: openTimer; interval: 110; onTriggered: root.open = true }
    Timer { id: closeTimer; interval: 260; onTriggered: root.open = false }

    IrisSpring { id: spring; surface: "island"; intent: "move"; to: root.open ? 1 : 0; minimum: 0 }
    readonly property real t: Math.min(1.06, spring.value)
    function mix(a: real, b: real): real { return a + (b - a) * root.t }
    readonly property real reveal: Math.max(0, Math.min(1, (spring.value - 0.55) / 0.4))

    width: root.fullWidth
    height: root.fullHeight
    implicitWidth: root.fullWidth
    implicitHeight: root.fullHeight

    // Where aiming counts: a strip around the pill at rest, the island and a margin once open.
    Item {
        id: zone
        readonly property real margin: PrismTheme.dp(14)
        x: (root.width - width) / 2
        width: root.open ? island.width + 2 * zone.margin : PrismTheme.dp(220)
        height: root.open ? island.height + zone.margin : PrismTheme.dp(26)
        // On the zone that holds the island, so the tiles' own hover never takes it away.
        HoverHandler { id: zoneHover }

        // Open, it floats over the page: a soft shadow that grows with it.
        RectangularShadow {
            anchors.fill: island
            radius: island.radius
            offset.y: PrismTheme.dp(10)
            blur: PrismTheme.dp(36)
            spread: -PrismTheme.dp(6)
            color: Qt.rgba(0, 0, 0, 0.5 * root.reveal) // iris-literal: the island's shadow, the same in every scheme
            visible: root.reveal > 0
            cached: true
        }

        Rectangle {
            id: island
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: Math.max(root.restWidth, root.mix(root.restWidth, root.fullWidth))
            height: Math.max(root.restHeight, root.mix(root.restHeight, root.fullHeight))
            radius: Math.min(height / 2, root.mix(root.restHeight / 2, PrismTheme.dp(30)))
            // At rest a quiet mark in the page's ink; open, the island's black.
            color: Qt.rgba(root.mix(root.restTone.r, PrismTheme.night.r), root.mix(root.restTone.g, PrismTheme.night.g),
                root.mix(root.restTone.b, PrismTheme.night.b), root.mix(root.restTone.a, 1))
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.09 * root.reveal) // iris-literal: the island's rim, the same in every scheme
            antialiasing: true
            clip: root.t < 0.999

            Item {
                id: content
                width: root.fullWidth
                height: root.fullHeight
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                opacity: root.reveal
                visible: opacity > 0
                scale: 0.94 + 0.06 * root.reveal
                transformOrigin: Item.Top

                Row {
                    id: captionLine
                    x: root.pad + PrismTheme.dp(2)
                    y: root.pad
                    spacing: PrismTheme.dp(6)
                    PrismText {
                        text: Translation.tr("Settings window")
                        font.pixelSize: PrismTheme.caption
                        font.weight: Font.DemiBold
                        color: Qt.alpha(PrismTheme.paper, 0.5)
                    }
                }

                Row {
                    x: root.pad
                    y: root.pad + captionLine.height + PrismTheme.dp(10)
                    spacing: root.gap
                    Repeater {
                        model: root.designs
                        delegate: Item {
                            id: tile
                            required property var modelData
                            required property int index
                            readonly property bool chosen: tile.modelData.value === root.current
                            width: root.tileWidth
                            height: root.sketchHeight + PrismTheme.dp(8) + PrismTheme.small * 1.3
                            // Each tile lands a beat after the one before it as the island opens.
                            readonly property real arrive: Math.max(0, Math.min(1, root.reveal * 1.6 - tile.index * 0.1))
                            opacity: tile.arrive
                            transform: Translate { y: (1 - tile.arrive) * PrismTheme.dp(6) }

                            Rectangle {
                                id: card
                                width: parent.width
                                height: root.sketchHeight
                                radius: PrismTheme.dp(12)
                                color: tile.chosen ? PrismTheme.paper
                                    : press.pressed ? Qt.rgba(1, 1, 1, 0.16) : press.containsMouse ? Qt.rgba(1, 1, 1, 0.11) : Qt.rgba(1, 1, 1, 0.06) // iris-literal: fills on the island's black
                                scale: press.pressed ? 0.95 : press.containsMouse && !tile.chosen ? 1.03 : 1
                                Behavior on color { ColorAnimation { duration: PrismTheme.ms(140) } }
                                Behavior on scale { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
                                PrismSketch {
                                    anchors.fill: parent
                                    anchors.margins: PrismTheme.dp(9)
                                    shapes: PrismModel.drawing(tile.modelData.value)
                                    ink: tile.chosen ? PrismTheme.night : PrismTheme.paper
                                }
                            }
                            PrismText {
                                anchors.top: card.bottom
                                anchors.topMargin: PrismTheme.dp(8)
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: Translation.tr(tile.modelData.label)
                                font.pixelSize: PrismTheme.small
                                font.weight: tile.chosen ? Font.DemiBold : Font.Medium
                                color: tile.chosen || press.containsMouse ? PrismTheme.paper : Qt.alpha(PrismTheme.paper, 0.55)
                            }
                            MouseArea {
                                id: press
                                anchors.fill: parent
                                enabled: root.open
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                Accessible.role: Accessible.RadioButton
                                Accessible.name: Translation.tr(tile.modelData.label)
                                Accessible.checked: tile.chosen
                                onClicked: {
                                    if (tile.chosen) return
                                    root.open = false
                                    root.picked(tile.modelData.value)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    // The resting pill: the page's ink, faint, so it reads as a handle on any page.
    readonly property color restTone: Qt.alpha(PrismTheme.ink, zoneHover.hovered ? 0.34 : 0.18)
}
