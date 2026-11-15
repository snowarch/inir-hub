pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// Every emoji, folded out in place under the item's reactions (`.claude/ref/language`: a press moves, nothing floats
// over the page): a well to find one by name and the grid, the quick set first; the ones already given stand up as
// keys. Enter takes the first, Escape folds it away.
Item {
    id: root
    property var item: null
    property bool open: false
    signal picked()

    readonly property var given: Array.from(Hub.mine(root.item?.id ?? "").reactions ?? [])
    readonly property real cell: PrismTheme.dp(40)
    readonly property int across: Math.max(6, Math.floor((root.width - PrismTheme.dp(24)) / root.cell))

    implicitHeight: root.open ? card.height : 0
    height: implicitHeight
    clip: true
    visible: height > 0
    Behavior on implicitHeight { NumberAnimation { duration: PrismTheme.ms(260); easing.type: Easing.OutCubic } }

    onOpenChanged: {
        search.input.text = ""
        if (root.open) search.input.forceActiveFocus()
    }
    Keys.onEscapePressed: root.open = false

    function pick(emoji: string): void {
        Hub.react(root.item.id, emoji)
        root.open = false
        root.picked()
    }

    Rectangle {
        id: card
        width: root.width
        height: body.implicitHeight + PrismTheme.dp(24)
        radius: PrismTheme.dp(24)
        color: PrismTheme.card
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
        Column {
            id: body
            x: PrismTheme.dp(12)
            y: PrismTheme.dp(12)
            width: parent.width - PrismTheme.dp(24)
            spacing: PrismTheme.dp(10)
            PrismField {
                id: search
                width: parent.width
                height: PrismTheme.dp(36)
                glyph: "search"
                commitOnEdit: true
                placeholder: Translation.tr("Search emoji")
                onEntered: text => { if (grid.count > 0) root.pick(grid.model[0]) }
            }
            GridView {
                id: grid
                width: root.across * root.cell
                height: root.cell * 5
                clip: true
                cellWidth: root.cell
                cellHeight: root.cell
                boundsBehavior: Flickable.StopAtBounds
                model: root.open ? Hub.emojiSearch(search.input.text) : []
                delegate: Item {
                    id: face
                    required property string modelData
                    readonly property bool mine: root.given.includes(face.modelData)
                    width: root.cell
                    height: root.cell
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: PrismTheme.dp(2)
                        radius: PrismTheme.dp(12)
                        visible: !face.mine
                        color: faceArea.pressed ? PrismTheme.fillPress : faceArea.containsMouse ? PrismTheme.fillHover : "transparent"
                    }
                    PrismKey {
                        anchors.fill: parent
                        anchors.margins: PrismTheme.dp(2)
                        visible: face.mine
                        radius: PrismTheme.dp(12)
                        face: PrismTheme.solid
                        hovered: faceArea.containsMouse
                        down: faceArea.pressed
                    }
                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: face.mine ? -PrismTheme.keyLip / 2 : 0
                        text: face.modelData
                        font.pixelSize: PrismTheme.dp(20)
                    }
                    MouseArea {
                        id: faceArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.role: Accessible.Button
                        Accessible.name: face.modelData
                        onClicked: root.pick(face.modelData)
                    }
                }
                PrismText {
                    anchors.centerIn: parent
                    width: parent.width - PrismTheme.dp(24)
                    visible: grid.count === 0 && search.input.text.length > 0
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 40
                    color: PrismTheme.ink2
                    font.pixelSize: PrismTheme.small
                    text: Translation.tr("No emoji called “%1”").arg(search.input.text.trim())
                }
            }
        }
    }
}
