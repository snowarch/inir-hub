import QtQuick
import QtQuick.Effects
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// The right column: who is signed in and the bell (Do Not Disturb), the settings changed from the factory profile
// numbered as the reference's top artists, and what is playing.
Item {
    id: root
    property bool active: true
    signal seeAllChanges()
    signal reach(var row)

    readonly property var changes: PrismModel.changes

    Column {
        id: column
        x: PrismTheme.dp(22)
        width: parent.width - PrismTheme.dp(44)
        spacing: 0

        Item {
            width: parent.width
            height: PrismTheme.dp(78)
            Item {
                id: avatar
                property int sourceIndex: 0
                width: PrismTheme.dp(40)
                height: width
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: PrismTheme.raised
                    PrismGlyph { anchors.centerIn: parent; text: "person"; filled: true; color: PrismTheme.ink2; visible: photo.status !== Image.Ready }
                }
                Image {
                    id: photo
                    anchors.fill: parent
                    source: Directories.avatarSourceAt(avatar.sourceIndex)
                    sourceSize.width: width * 2
                    sourceSize.height: height * 2
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                    onStatusChanged: if (status === Image.Error && avatar.sourceIndex + 1 < Directories.userAvatarPaths.length) Qt.callLater(() => avatar.sourceIndex++)
                }
                MultiEffect {
                    anchors.fill: parent
                    visible: photo.status === Image.Ready
                    source: photo
                    maskEnabled: true
                    maskSource: round
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1
                }
                Rectangle { id: round; anchors.fill: parent; radius: width / 2; visible: false; layer.enabled: true }
            }
            Column {
                anchors.left: avatar.right
                anchors.leftMargin: PrismTheme.dp(12)
                anchors.right: bell.left
                anchors.rightMargin: PrismTheme.dp(12)
                anchors.verticalCenter: parent.verticalCenter
                spacing: PrismTheme.dp(1)
                PrismText { width: parent.width; text: SystemInfo.username; font.pixelSize: PrismTheme.row; font.weight: Font.DemiBold }
                PrismText { width: parent.width; text: SystemInfo.hostname; color: PrismTheme.ink2; font.pixelSize: PrismTheme.small }
            }
            PrismRound {
                id: bell
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: PrismTheme.dp(36)
                readonly property bool silent: { const _ = PrismModel.revision; return Boolean(Config.getNestedValue("notifications.silent", false)) }
                glyph: silent ? "notifications_off" : "notifications"
                lit: silent
                glyphSize: PrismTheme.dp(17)
                onClicked: Config.setNestedValue("notifications.silent", !silent)
            }
        }
        Rectangle { width: parent.width; height: 1; color: PrismTheme.line }
        Item { width: 1; height: PrismTheme.dp(18) }

        PrismHeading {
            width: parent.width
            eyebrow: Translation.tr("Yours")
            title: Translation.tr("Changes")
            titleSize: PrismTheme.head
            link: root.changes.length > 4 ? Translation.tr("See all") : ""
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
        Repeater {
            model: root.changes.slice(0, 4)
            delegate: Item {
                id: change
                required property var modelData
                required property int index
                width: column.width
                height: PrismTheme.dp(54)
                PrismThumb {
                    id: thumb
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: change.modelData.glyph
                    tint: PrismModel.page(change.modelData.page).tint
                    size: PrismTheme.dp(38)
                }
                Column {
                    anchors.left: thumb.right
                    anchors.leftMargin: PrismTheme.dp(12)
                    anchors.right: rank.left
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
                    text: String(change.index + 1).padStart(2, "0")
                    figures: true
                    color: PrismTheme.ink3
                    font.pixelSize: PrismTheme.small
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
        Item { width: 1; height: PrismTheme.dp(14) }
        Rectangle { width: parent.width; height: 1; color: PrismTheme.line }
    }

    PrismNowPlaying {
        x: column.x
        width: column.width
        anchors.top: column.bottom
        anchors.topMargin: PrismTheme.dp(20)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PrismTheme.dp(22)
        active: root.active
    }
}
