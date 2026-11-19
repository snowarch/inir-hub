pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// Wallpaper opens on the person's own desktop: their picture large, the Island where it sits, and on it the two things
// people come here for, a new picture and the next one. Under it the pictures they wore before, one press each to wear
// again, and the way to all of them. No file names, no counts: the pictures say it.
Item {
    id: root

    readonly property string worn: String(Wallpapers.effectiveWallpaperPath ?? "")
    readonly property real gap: PrismTheme.dp(12)
    // As many tiles as keep each near a thumbnail's width; the last one opens every wallpaper.
    readonly property int most: Math.max(3, Math.min(6, Math.floor((root.width + root.gap) / (PrismTheme.dp(170) + root.gap)) - 1))
    readonly property var choices: PrismModel.wallpaperChoices(root.most)
    readonly property real tileW: Math.floor((root.width - root.gap * root.most) / (root.most + 1))
    readonly property real tileH: Math.round(root.tileW * 10 / 16)
    implicitHeight: desk.height + root.gap + root.tileH

    ClippingRectangle {
        id: desk
        width: root.width
        height: Math.round(Math.min(root.width * 0.45, PrismTheme.dp(380)))
        radius: PrismTheme.cardRadius
        color: PrismTheme.night
        Image {
            anchors.fill: parent
            source: Wallpapers.stillUrlFor(root.worn)
            sourceSize.width: Math.round(desk.width * 1.5)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            scale: deskArea.containsMouse ? 1.015 : 1
            Behavior on scale { NumberAnimation { duration: PrismTheme.ms(520); easing.type: Easing.OutCubic } }
        }
        // The Island, where it sits on the screen: this is the desktop, not a file.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(parent.height * 0.04)
            width: Math.round(parent.width * 0.14)
            height: Math.round(parent.height * 0.055)
            radius: height / 2
            color: PrismTheme.night
        }
        // A step of smoke at the foot so the keys hold over a bright picture.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.round(parent.height * 0.36)
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Qt.alpha(PrismTheme.night, 0.55) }
            }
        }
        MouseArea {
            id: deskArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: Translation.tr("Change wallpaper")
            onClicked: PrismModel.openWallpaperGallery()
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: PrismTheme.dp(20)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PrismTheme.dp(20)
            spacing: PrismTheme.dp(10)
            PrismRound {
                anchors.verticalCenter: parent.verticalCenter
                overArt: true
                smoked: true
                implicitWidth: PrismTheme.dp(36)
                glyph: "shuffle"
                Accessible.name: Translation.tr("Next wallpaper")
                onClicked: Wallpapers.nextWallpaper(Appearance.m3colors.darkmode, NiriService.currentOutput)
            }
            PrismPill {
                tone: "art"
                glyph: "photo_library"
                text: Translation.tr("Change wallpaper")
                onClicked: PrismModel.openWallpaperGallery()
            }
        }
    }

    // The ones worn before, then the way to all of them.
    Row {
        y: desk.height + root.gap
        spacing: root.gap
        Repeater {
            model: root.choices
            delegate: MouseArea {
                id: tile
                required property string modelData
                width: root.tileW
                height: root.tileH
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: PrismModel.wallpaperName(tile.modelData)
                onClicked: PrismModel.wearWallpaper(tile.modelData)
                ClippingRectangle {
                    anchors.fill: parent
                    radius: PrismTheme.dp(16)
                    color: PrismTheme.fill
                    scale: tile.pressed ? 0.97 : 1
                    Behavior on scale { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
                    Image {
                        anchors.fill: parent
                        source: Wallpapers.stillUrlFor(tile.modelData)
                        sourceSize.width: PrismTheme.dp(340)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: tile.containsMouse ? 1 : 0.88
                        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
        MouseArea {
            id: all
            // With few to go back to, the way to all of them takes the rest of the line.
            width: root.width - (root.tileW + root.gap) * root.choices.length
            height: root.tileH
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: Translation.tr("All wallpapers")
            onClicked: PrismModel.openWallpaperGallery()
            Rectangle {
                anchors.fill: parent
                radius: PrismTheme.dp(16)
                color: all.pressed ? PrismTheme.fillPress : all.containsMouse ? PrismTheme.fillHover : PrismTheme.card
                Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
            }
            Column {
                anchors.centerIn: parent
                spacing: PrismTheme.dp(6)
                PrismGlyph {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "photo_library"
                    iconSize: PrismTheme.dp(22)
                    color: PrismTheme.ink
                }
                PrismText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Translation.tr("All wallpapers")
                    color: PrismTheme.ink2
                    font.pixelSize: PrismTheme.small
                    font.weight: Font.Medium
                }
            }
        }
    }
}
