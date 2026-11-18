import QtQuick
import QtQuick.Effects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// The right column (Technical Minimalism, his 11-17: "puede ser util para otras cosas"): who is signed in and the bell,
// then what helps on the page open. On a page, its index (every group numbered, the one being read marked, a dot where
// something differs from the factory; a press goes there) and what was changed on it; on Home, every change. What is
// playing at its foot.
Item {
    id: root
    property bool active: true
    property string pageId: ""
    property string pageName: ""
    // The page's groups: { title, changed, first }.
    property var groups: []
    property string current: ""
    signal seeAllChanges()
    signal reach(var row)
    signal pickGroup(string title)

    // Home, or no one page (a search): every change.
    readonly property bool home: root.pageId === "general" || root.pageId.length === 0
    readonly property var allChanges: PrismModel.changes
    readonly property var changes: root.home ? root.allChanges : root.allChanges.filter(row => row.page === root.pageId)
    readonly property bool indexed: !root.home && root.groups.length > 1
    readonly property real indexRow: PrismTheme.dp(30)
    readonly property real changeRow: PrismTheme.dp(46)
    readonly property real cap: PrismTheme.dp(9.5)
    readonly property real changesTop: changesHead.y + changesHead.height + PrismTheme.dp(6)
    readonly property real room: player.y - PrismTheme.dp(20) - root.changesTop
    readonly property int shown: Math.max(1, Math.floor(root.room / root.changeRow))

    component Caption: PrismText {
        mono: true
        color: PrismTheme.ink3
        font.pixelSize: root.cap
        font.letterSpacing: root.cap * 0.1
    }
    component Head: Item {
        id: head
        property string title: ""
        property string count: ""
        property string link: ""
        signal linkClicked()
        width: column.width
        height: PrismTheme.dp(26)
        Caption { anchors.verticalCenter: parent.verticalCenter; text: head.title.toUpperCase() }
        Caption {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: head.link.length === 0
            text: head.count
        }
        PrismText {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: head.link.length > 0
            mono: true
            text: head.link.toUpperCase()
            color: linkArea.containsMouse ? PrismTheme.ink : PrismTheme.ink2
            font.pixelSize: root.cap
            font.letterSpacing: root.cap * 0.1
            MouseArea {
                id: linkArea
                anchors.fill: parent
                anchors.margins: -PrismTheme.dp(6)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: head.linkClicked()
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: PrismTheme.line }
    }

    Column {
        id: column
        x: PrismTheme.dp(22)
        width: parent.width - PrismTheme.dp(44)
        spacing: 0

        // Who is signed in.
        Item {
            width: parent.width
            height: PrismTheme.dp(88)
            Item {
                id: avatar
                property int sourceIndex: 0
                width: PrismTheme.dp(42)
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
                spacing: PrismTheme.dp(2)
                PrismText {
                    width: parent.width
                    text: SystemInfo.displayName || SystemInfo.username
                    elide: Text.ElideRight
                    font.pixelSize: PrismTheme.dp(15)
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.2
                }
                Caption {
                    width: parent.width
                    text: (Translation.locale.toString(DateTime.clock.date, "ddd d MMM")
                        + (Weather.enabled && Weather.hasData ? "  ·  " + String(Weather.data?.temp ?? "") : "")).toUpperCase()
                }
            }
            PrismRound {
                id: bell
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: PrismTheme.dp(34)
                readonly property bool silent: { const _ = PrismModel.revision; return Boolean(Config.getNestedValue("notifications.silent", false)) }
                glyph: silent ? "notifications_off" : "notifications"
                lit: silent
                glyphSize: PrismTheme.dp(16)
                Accessible.name: silent ? Translation.tr("Notifications are silent") : Translation.tr("Silence notifications")
                onClicked: Config.setNestedValue("notifications.silent", !silent)
            }
        }

        // The page's index.
        Head {
            visible: root.indexed
            title: Translation.tr("On this page")
            count: String(root.groups.length).padStart(2, "0")
        }
        Column {
            visible: root.indexed
            width: parent.width
            topPadding: PrismTheme.dp(6)
            bottomPadding: PrismTheme.dp(18)
            Repeater {
                model: root.indexed ? root.groups : []
                delegate: Item {
                    id: group
                    required property var modelData
                    required property int index
                    readonly property bool here: String(group.modelData.title) === root.current
                    width: column.width
                    height: root.indexRow
                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: -PrismTheme.dp(8)
                        anchors.rightMargin: -PrismTheme.dp(8)
                        radius: PrismTheme.dp(9)
                        color: groupArea.containsMouse ? PrismTheme.fill : "transparent"
                    }
                    // The group being read: a short line in the accent before its number.
                    Rectangle {
                        visible: group.here
                        x: -PrismTheme.dp(10)
                        anchors.verticalCenter: parent.verticalCenter
                        width: PrismTheme.dp(2)
                        height: PrismTheme.dp(12)
                        radius: 1
                        color: PrismTheme.mark
                    }
                    Caption {
                        id: number
                        anchors.verticalCenter: parent.verticalCenter
                        width: PrismTheme.dp(28)
                        text: String(group.index + 1).padStart(2, "0")
                        color: group.here ? PrismTheme.ink : PrismTheme.ink3
                    }
                    PrismText {
                        anchors.left: number.right
                        anchors.right: dot.left
                        anchors.rightMargin: PrismTheme.dp(8)
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr(String(group.modelData.title))
                        color: group.here || groupArea.containsMouse ? PrismTheme.ink : PrismTheme.ink2
                        font.pixelSize: PrismTheme.body
                        font.weight: group.here ? Font.DemiBold : Font.Normal
                    }
                    Rectangle {
                        id: dot
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: PrismTheme.dp(5)
                        height: width
                        radius: width / 2
                        color: PrismTheme.mark
                        opacity: group.modelData.changed ? 1 : 0
                    }
                    MouseArea {
                        id: groupArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.role: Accessible.Link
                        Accessible.name: Translation.tr(String(group.modelData.title))
                        onClicked: root.pickGroup(String(group.modelData.first ?? group.modelData.title))
                    }
                }
            }
        }

        // What differs from the factory: here, or everywhere on Home.
        Head {
            id: changesHead
            title: root.home ? Translation.tr("Your changes") : Translation.tr("Changed here")
            count: String(root.changes.length).padStart(2, "0")
            link: root.allChanges.length > (root.home ? root.shown : 0) ? Translation.tr("All %1").arg(root.allChanges.length) : ""
            onLinkClicked: root.seeAllChanges()
        }
        PrismText {
            visible: root.changes.length === 0
            width: parent.width
            topPadding: PrismTheme.dp(12)
            text: root.home ? Translation.tr("Everything is as it came.") : Translation.tr("This page is as it came.")
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.small
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }
        Column {
            width: parent.width
            topPadding: PrismTheme.dp(6)
            Repeater {
                // Keyed: a write elsewhere keeps the rows that stayed instead of rebuilding the list.
                model: ScriptModel { objectProp: "key"; values: root.changes.slice(0, root.shown) }
                delegate: Item {
                    id: change
                    required property var modelData
                    required property int index
                    width: column.width
                    height: root.changeRow
                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: -PrismTheme.dp(8)
                        anchors.rightMargin: -PrismTheme.dp(8)
                        radius: PrismTheme.dp(10)
                        color: changeArea.containsMouse ? PrismTheme.fill : "transparent"
                    }
                    PrismGlyph {
                        id: glyph
                        anchors.verticalCenter: parent.verticalCenter
                        text: String(change.modelData.glyph ?? PrismModel.page(change.modelData.page).glyph)
                        iconSize: PrismTheme.dp(16)
                        color: PrismTheme.ink2
                    }
                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: PrismTheme.dp(28)
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: PrismTheme.dp(2)
                        PrismText {
                            width: parent.width
                            text: Translation.tr(change.modelData.label)
                            font.pixelSize: PrismTheme.body
                            font.weight: Font.Medium
                        }
                        Caption {
                            width: parent.width
                            text: (root.home ? Translation.tr(String(PrismModel.page(change.modelData.page).name ?? "")) + "  ·  " : "")
                                + String(PrismModel.sayNow(change.modelData)).toUpperCase()
                            color: PrismTheme.ink2
                        }
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
    }

    PrismNowPlaying {
        id: player
        x: column.x
        width: column.width
        // A square cover where the column is tall enough, never over the index.
        height: player.playing ? Math.max(PrismTheme.dp(180), Math.min(column.width, root.height * 0.36)) : player.idleHeight
        y: root.height - PrismTheme.dp(22) - height
        active: root.active
    }
}
