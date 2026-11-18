pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// A choice of whole palettes (his 11-18: themes as a wall of words read as nothing): each one a card painted in its
// own paper and ink, its colours laid on it as stripes of paint, its name in its own text colour. The chosen one wears
// a check; the wallpaper's own is the wallpaper itself.
Item {
    id: root
    property var choices: []
    property var current
    signal picked(var value)

    readonly property real gap: PrismTheme.dp(8)
    readonly property int columns: Math.max(2, Math.floor((root.width + root.gap) / (PrismTheme.dp(132) + root.gap)))
    readonly property real cardWidth: Math.floor((root.width - (root.columns - 1) * root.gap) / root.columns)
    readonly property real cardHeight: PrismTheme.dp(78)
    readonly property string wallPath: String(Wallpapers.effectiveWallpaperPath ?? "")
    implicitHeight: grid.implicitHeight

    function same(a: var, b: var): bool { return String(a ?? "") === String(b ?? "") }

    Grid {
        id: grid
        columns: root.columns
        spacing: root.gap
        Repeater {
            model: root.choices
            delegate: ClippingRectangle {
                id: card
                required property var modelData
                readonly property var palette: card.modelData.palette ?? ({})
                readonly property bool wall: Boolean(card.palette.wallpaper)
                readonly property bool chosen: root.same(card.modelData.value, root.current)
                readonly property color ink: card.wall ? PrismTheme.paper : (card.palette.fg ?? PrismTheme.ink)
                width: root.cardWidth
                height: root.cardHeight
                radius: PrismTheme.dp(16)
                color: card.wall ? PrismTheme.night : (card.palette.bg ?? PrismTheme.fill)
                Image {
                    anchors.fill: parent
                    visible: card.wall
                    source: card.wall ? Wallpapers.stillUrlFor(root.wallPath) : ""
                    sourceSize.width: Math.round(root.cardWidth * 2)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    Rectangle { anchors.fill: parent; color: PrismTheme.night; opacity: 0.3 }
                }
                PrismText {
                    x: PrismTheme.dp(12)
                    y: PrismTheme.dp(10)
                    width: parent.width - PrismTheme.dp(24) - (card.chosen ? PrismTheme.dp(22) : 0)
                    text: Translation.tr(String(card.modelData.label ?? ""))
                    color: card.ink
                    font.pixelSize: PrismTheme.small
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                // Its colours as strokes of paint along the foot, the first the widest.
                Row {
                    visible: !card.wall
                    x: PrismTheme.dp(12)
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: PrismTheme.dp(12)
                    spacing: PrismTheme.dp(4)
                    Repeater {
                        model: Array.from(card.palette.dots ?? [])
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: (card.width - PrismTheme.dp(32)) * (index === 0 ? 0.5 : 0.25)
                            height: PrismTheme.dp(12)
                            radius: height / 2
                            color: modelData
                        }
                    }
                }
                Rectangle {
                    visible: card.chosen
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: PrismTheme.dp(8)
                    width: PrismTheme.dp(20)
                    height: width
                    radius: width / 2
                    color: card.ink
                    PrismGlyph {
                        anchors.centerIn: parent
                        text: "check"
                        iconSize: PrismTheme.dp(14)
                        color: card.wall ? PrismTheme.night : (card.palette.bg ?? PrismTheme.canvas)
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    color: card.ink
                    opacity: hit.pressed ? 0.12 : hit.containsMouse ? 0.06 : 0
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
