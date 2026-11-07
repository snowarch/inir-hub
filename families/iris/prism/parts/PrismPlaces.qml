pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// What a search names whole: a page or a group, as capsules that go there. A press opens it; Enter in the search
// takes the first one.
Column {
    id: root
    property var places: []
    signal open(var place)
    spacing: 0

    PrismHeading {
        width: root.width
        eyebrow: Translation.tr("Go to")
        title: Translation.tr("Places")
        titleSize: PrismTheme.title * 0.86
    }
    Item { width: 1; height: PrismTheme.dp(14) }

    Flow {
        id: grid
        width: root.width
        spacing: PrismTheme.dp(8)
        readonly property int columns: Math.max(2, Math.floor((width + spacing) / (PrismTheme.dp(220) + spacing)))
        readonly property real tileWidth: Math.floor((width - (columns - 1) * spacing) / columns)

        Repeater {
            model: root.places
            delegate: Item {
                id: tile
                required property var modelData
                required property int index
                readonly property bool isPage: String(tile.modelData.group ?? "").length === 0
                width: grid.tileWidth
                height: PrismTheme.dp(56)

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: press.pressed ? PrismTheme.fillPress : press.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
                    scale: press.pressed ? 0.97 : 1
                    Behavior on color { ColorAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
                }
                PrismThumb {
                    id: thumb
                    x: PrismTheme.dp(10)
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: tile.modelData.glyph
                    tint: tile.modelData.tint
                }
                Column {
                    anchors.left: thumb.right
                    anchors.leftMargin: PrismTheme.dp(12)
                    anchors.right: arrow.left
                    anchors.rightMargin: PrismTheme.dp(8)
                    anchors.verticalCenter: parent.verticalCenter
                    PrismText {
                        width: parent.width
                        text: Translation.tr(tile.modelData.name)
                        elide: Text.ElideRight
                        font.pixelSize: PrismTheme.body
                        font.weight: Font.DemiBold
                    }
                    // A page says it is one; a group says the page it sits in.
                    PrismText {
                        width: parent.width
                        text: tile.isPage ? Translation.tr("Page") : Translation.tr(PrismModel.page(tile.modelData.page).name)
                        elide: Text.ElideRight
                        color: PrismTheme.ink2
                        font.pixelSize: PrismTheme.caption
                    }
                }
                // The first place is what Enter opens: its arrow stands at rest, the others' come with the pointer.
                PrismGlyph {
                    id: arrow
                    anchors.right: parent.right
                    anchors.rightMargin: PrismTheme.dp(18)
                    anchors.verticalCenter: parent.verticalCenter
                    text: tile.index === 0 && !press.containsMouse ? "keyboard_return" : "arrow_forward"
                    iconSize: PrismTheme.dp(16)
                    color: press.containsMouse ? PrismTheme.ink : PrismTheme.ink2
                    opacity: tile.index === 0 || press.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    id: press
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Link
                    Accessible.name: Translation.tr(tile.modelData.name)
                    onClicked: root.open(tile.modelData)
                }
            }
        }
    }
}
