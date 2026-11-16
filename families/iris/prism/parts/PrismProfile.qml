import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// Who is signed in, as a smoked pane over their own sky (`.claude/ref/language`, glass-card-pink-sky): the wallpaper
// they wear sharp round the pane, the same picture blurred through black smoke inside it, no outline anywhere (his
// 11-16). On the pane: the avatar, the greeting, the name, the day and the weather as clear tags; at its foot one glass pill that acts (their
// wallpaper) and two round glass keys (dark or light, Do Not Disturb). Drawn once: it changes when the wallpaper does.
Item {
    id: root
    implicitHeight: root.inset * 2 + root.pad * 2 + who.height + PrismTheme.dp(14) + PrismTheme.dp(34)

    readonly property int hour: DateTime.clock.date.getHours()
    readonly property bool silent: { const _ = PrismModel.revision; return Boolean(Config.getNestedValue("notifications.silent", false)) }
    readonly property bool dark: Appearance.m3colors.darkmode
    readonly property string sky: Wallpapers.stillUrlFor(String(Wallpapers.effectiveWallpaperPath ?? ""))
    readonly property real inset: PrismTheme.dp(10)
    readonly property real pad: PrismTheme.dp(12)

    // The sky, sharp round the glass.
    ClippingRectangle {
        anchors.fill: parent
        radius: PrismTheme.dp(24)
        color: PrismTheme.night
        Image {
            anchors.fill: parent
            source: root.sky
            sourceSize.width: Math.max(64, Math.round(root.width))
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(300); easing.type: Easing.OutCubic } }
        }
    }

    // The pane: the same sky blurred under black smoke, its corners concentric with the card's.
    ClippingRectangle {
        id: pane
        x: root.inset
        y: root.inset
        width: root.width - root.inset * 2
        height: root.height - root.inset * 2
        radius: PrismTheme.dp(24) - root.inset
        color: PrismTheme.night
        Image {
            id: frosted
            x: -pane.x
            y: -pane.y
            width: root.width
            height: root.height
            source: root.sky
            sourceSize.width: 96
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            visible: false
        }
        MultiEffect {
            anchors.fill: frosted
            source: frosted
            visible: frosted.status === Image.Ready
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 48
        }
        Rectangle { anchors.fill: parent; color: PrismTheme.glassSheet }
    }

    Item {
        id: content
        anchors.fill: pane
        anchors.margins: root.pad

        Item {
            id: avatar
            property int sourceIndex: 0
            property bool sky: Directories.userAvatarPaths.length === 0
            width: PrismTheme.dp(50)
            height: width
            anchors.verticalCenter: who.verticalCenter
            Image {
                id: photo
                anchors.fill: parent
                // No picture of them: their sky, sharp, as the reference's avatar is.
                source: avatar.sky ? root.sky : Directories.avatarSourceAt(avatar.sourceIndex)
                sourceSize.width: width * 2
                sourceSize.height: height * 2
                fillMode: Image.PreserveAspectCrop
                visible: false
                onStatusChanged: if (status === Image.Error && !avatar.sky) Qt.callLater(() => {
                    if (avatar.sourceIndex + 1 < Directories.userAvatarPaths.length) avatar.sourceIndex++
                    else avatar.sky = true
                })
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
            id: who
            anchors.left: avatar.right
            anchors.leftMargin: PrismTheme.dp(12)
            anchors.right: parent.right
            spacing: PrismTheme.dp(2)
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
                font.pixelSize: PrismTheme.head + 2
                font.weight: Font.Bold
                font.letterSpacing: -(PrismTheme.head + 2) * 0.035
            }
            Item { width: 1; height: PrismTheme.dp(3) }
            // The day and the weather as clear tags; the weather steps out when the two do not fit.
            Row {
                spacing: PrismTheme.dp(5)
                Tag { id: day; text: Translation.locale.toString(DateTime.clock.date, "ddd d MMM") }
                Tag {
                    text: Weather.enabled && Weather.hasData ? String(Weather.data?.temp ?? "") : ""
                    visible: text.length > 0 && day.width + PrismTheme.dp(5) + width <= who.width
                }
            }
        }

        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: PrismTheme.dp(8)
            Key {
                width: parent.width - parent.spacing * 2 - PrismTheme.dp(34) * 2
                glyph: "wallpaper"
                text: Translation.tr("Wallpaper")
                onClicked: PrismModel.openWallpaperGallery()
            }
            Key {
                glyph: root.dark ? "dark_mode" : "light_mode"
                Accessible.name: Translation.tr("Dark Mode")
                onClicked: MaterialThemeLoader.setDarkMode(!root.dark)
            }
            Key {
                glyph: root.silent ? "notifications_off" : "notifications"
                lit: root.silent
                Accessible.name: Translation.tr("Do not disturb")
                onClicked: Config.setNestedValue("notifications.silent", !root.silent)
            }
        }
    }

    // A tag printed on the pane: a smoked pill, mono caps.
    component Tag: Rectangle {
        property alias text: label.text
        width: label.implicitWidth + PrismTheme.dp(14)
        height: PrismTheme.dp(20)
        radius: height / 2
        color: PrismTheme.frost
        PrismText {
            id: label
            anchors.centerIn: parent
            text: ""
            mono: true
            color: PrismTheme.paper
            font.pixelSize: PrismTheme.caption - 1
            font.letterSpacing: 0.6
            font.capitalization: Font.AllUppercase
        }
    }

    // A smoked key: round with a glyph, or the pill that acts when it has words. Lit, it turns white.
    component Key: Item {
        id: key
        property string glyph: ""
        property string text: ""
        property bool lit: false
        signal clicked()
        implicitWidth: PrismTheme.dp(34)
        implicitHeight: PrismTheme.dp(34)
        scale: area.pressed ? 0.96 : 1
        Behavior on scale { NumberAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: key.lit ? PrismTheme.paper : area.pressed ? PrismTheme.frostPress : area.containsMouse ? PrismTheme.frostHover : PrismTheme.frost
            Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
        }
        Row {
            anchors.centerIn: parent
            spacing: PrismTheme.dp(6)
            PrismGlyph {
                anchors.verticalCenter: parent.verticalCenter
                text: key.glyph
                filled: true
                iconSize: PrismTheme.dp(17)
                color: key.lit ? PrismTheme.night : PrismTheme.paper
            }
            PrismText {
                visible: key.text.length > 0
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, key.width - PrismTheme.dp(20) - PrismTheme.dp(23))
                text: key.text
                elide: Text.ElideRight
                color: PrismTheme.paper
                font.pixelSize: PrismTheme.body
                font.weight: Font.Medium
            }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: key.clicked()
        }
    }
}
