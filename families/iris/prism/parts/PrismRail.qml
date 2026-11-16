import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// The right column: who is signed in as a pane of glass over their wallpaper (their wallpaper, dark or light, Do Not
// Disturb at hand), the settings changed from the factory profile, and what is playing.
Item {
    id: root
    property bool active: true
    signal seeAllChanges()
    signal reach(var row)

    readonly property var changes: PrismModel.changes
    // Four changes beside a song; with nothing playing, as many as the column holds (the player folds to a line).
    readonly property real rowHeight: PrismTheme.dp(54)
    readonly property int shown: player.playing ? 4
        : Math.max(4, Math.min(12, Math.floor((root.height - list.y - PrismTheme.dp(15 + 20 + 22)) / root.rowHeight)))

    Column {
        id: column
        x: PrismTheme.dp(22)
        width: parent.width - PrismTheme.dp(44)
        spacing: 0

        Item { width: 1; height: PrismTheme.dp(14) }
        PrismProfile { width: parent.width }
        Item { width: 1; height: PrismTheme.dp(22) }

        PrismHeading {
            width: parent.width
            eyebrow: Translation.tr("Yours")
            title: Translation.tr("Changes")
            titleSize: PrismTheme.head
            link: root.changes.length > root.shown ? Translation.tr("See all") : ""
            onLinkClicked: root.seeAllChanges()
        }
        Item { width: 1; height: PrismTheme.dp(12) }

        PrismText {
            visible: root.changes.length === 0
            width: parent.width
            topPadding: PrismTheme.dp(6)
            bottomPadding: PrismTheme.dp(12)
            text: Translation.tr("Everything is as it came.")
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.small
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }
        Column {
            id: list
            width: parent.width
            Repeater {
                // Keyed: a write elsewhere keeps the rows that stayed instead of rebuilding the list.
                model: ScriptModel { objectProp: "key"; values: root.changes.slice(0, root.shown) }
                delegate: Item {
                    id: change
                    required property var modelData
                    required property int index
                    width: column.width
                    height: root.rowHeight
                    PrismThumb {
                        id: thumb
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: change.modelData.glyph
                        salt: String(change.modelData.label ?? "")
                        tint: PrismModel.page(change.modelData.page).tint
                        size: PrismTheme.dp(38)
                    }
                    Column {
                        anchors.left: thumb.right
                        anchors.leftMargin: PrismTheme.dp(12)
                        anchors.right: parent.right
                        anchors.rightMargin: PrismTheme.dp(8)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: PrismTheme.dp(2)
                        PrismText {
                            width: parent.width
                            text: Translation.tr(change.modelData.label)
                            font.pixelSize: PrismTheme.body
                            font.weight: Font.DemiBold
                            color: changeArea.containsMouse ? PrismTheme.accent : PrismTheme.ink
                        }
                        Row {
                            width: parent.width
                            spacing: PrismTheme.dp(4)
                            PrismGlyph { anchors.verticalCenter: parent.verticalCenter; text: PrismModel.page(change.modelData.page).glyph; iconSize: PrismTheme.dp(12); color: PrismTheme.ink3 }
                            PrismText {
                                width: parent.width - PrismTheme.dp(16)
                                anchors.verticalCenter: parent.verticalCenter
                                text: PrismModel.sayNow(change.modelData)
                                color: PrismTheme.ink2
                                font.pixelSize: PrismTheme.small
                            }
                        }
                    }
                    PrismText {
                        id: rank
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: false // his 11-15: no numbering
                        mono: true
                        color: PrismTheme.ink3
                        font.pixelSize: PrismTheme.caption - 1
                        font.letterSpacing: 0.6
                    }
                    MouseArea {
                        id: changeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.reach(change.modelData)
                    }
                }
            }
        }
        Item { width: 1; height: PrismTheme.dp(14) }
        Rectangle { width: parent.width; height: 1; color: PrismTheme.line }
    }

    PrismNowPlaying {
        id: player
        x: column.x
        width: column.width
        y: column.y + column.height + PrismTheme.dp(20)
        height: Math.max(0, root.height - PrismTheme.dp(22) - y)
        active: root.active
    }
}
