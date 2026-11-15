import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// Who is signed in, as a glass card over their own sky (`.claude/ref/language`, glass-card-pink-sky): the wallpaper
// they wear, soft as seen through frosted glass, the day and the weather printed as small tags on it, the bell a round
// glass key; a frosted sheet at the foot holds the avatar, the greeting and the name. The picture is decoded small and
// drawn large, so it is soft without a blur pass, and it changes only when the wallpaper does.
Item {
    id: root
    implicitHeight: PrismTheme.dp(168)

    readonly property int hour: DateTime.clock.date.getHours()
    readonly property bool silent: { const _ = PrismModel.revision; return Boolean(Config.getNestedValue("notifications.silent", false)) }

    ClippingRectangle {
        anchors.fill: parent
        radius: PrismTheme.dp(22)
        color: PrismTheme.night
        Image {
            anchors.fill: parent
            source: Wallpapers.stillUrlFor(String(Wallpapers.effectiveWallpaperPath ?? ""))
            sourceSize.width: 72
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(300); easing.type: Easing.OutCubic } }
        }
        // The sheet: frosted, its top edge a hairline of light.
        Rectangle {
            id: sheet
            y: parent.height - height
            width: parent.width
            height: PrismTheme.dp(74)
            color: PrismTheme.glassSheet
            Rectangle { width: parent.width; height: 1; color: PrismTheme.spotEdge }
        }
    }

    // The day and the weather, printed small on the sky.
    Row {
        x: PrismTheme.dp(14)
        y: PrismTheme.dp(14)
        spacing: PrismTheme.dp(6)
        Repeater {
            model: [Translation.locale.toString(DateTime.clock.date, "ddd d MMM"), Weather.enabled && Weather.hasData ? String(Weather.data?.temp ?? "") : ""].filter(word => word.length > 0)
            delegate: Rectangle {
                required property string modelData
                width: tag.implicitWidth + PrismTheme.dp(16)
                height: PrismTheme.dp(22)
                radius: height / 2
                color: PrismTheme.spot
                border.width: 1
                border.color: PrismTheme.spotEdge
                PrismText {
                    id: tag
                    anchors.centerIn: parent
                    text: parent.modelData.toUpperCase()
                    mono: true
                    color: PrismTheme.paper
                    font.pixelSize: PrismTheme.caption - 1
                    font.letterSpacing: 0.8
                }
            }
        }
    }
    PrismRound {
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(12)
        y: PrismTheme.dp(10)
        implicitWidth: PrismTheme.dp(32)
        overArt: true
        smoked: true
        lit: root.silent
        glyph: root.silent ? "notifications_off" : "notifications"
        glyphSize: PrismTheme.dp(16)
        Accessible.name: Translation.tr("Do not disturb")
        onClicked: Config.setNestedValue("notifications.silent", !root.silent)
    }

    Item {
        id: avatar
        property int sourceIndex: 0
        x: PrismTheme.dp(14)
        y: root.height - sheet.height / 2 - height / 2
        width: PrismTheme.dp(44)
        height: width
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: PrismTheme.spot
            border.width: 1
            border.color: PrismTheme.spotEdge
            PrismGlyph { anchors.centerIn: parent; text: "person"; filled: true; color: PrismTheme.paper; visible: photo.status !== Image.Ready }
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
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(14)
        anchors.verticalCenter: avatar.verticalCenter
        spacing: PrismTheme.dp(1)
        PrismText {
            width: parent.width
            text: (root.hour >= 5 && root.hour < 12 ? Translation.tr("Good morning")
                : root.hour >= 12 && root.hour < 19 ? Translation.tr("Good afternoon")
                : root.hour >= 19 ? Translation.tr("Good evening") : Translation.tr("Good night")).toUpperCase()
            mono: true
            color: PrismTheme.spotInk2
            font.pixelSize: PrismTheme.caption - 1
            font.letterSpacing: 0.8
        }
        PrismText {
            width: parent.width
            text: SystemInfo.displayName || SystemInfo.username
            elide: Text.ElideRight
            color: PrismTheme.paper
            font.pixelSize: PrismTheme.head
            font.weight: Font.Bold
            font.letterSpacing: -PrismTheme.head * 0.02
        }
    }
}
