pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// Wallpaper's hero is the wallpaper (a settings page about a picture opens on the picture, the way macOS's Wallpaper
// pane does): what is worn, its name and kind over a shade, the white pill to the gallery, shuffle beside it; under it
// the wallpapers to go back to, one press each, and the way to all of them.
Item {
    id: root
    property int restorable: 0
    signal restore()

    readonly property string worn: String(Wallpapers.effectiveWallpaperPath ?? "")
    readonly property var choices: PrismModel.wallpaperChoices(root.most)
    readonly property real gap: PrismTheme.dp(10)
    // As many tiles as keep each one near a thumbnail's width, the last one "All".
    readonly property int most: Math.max(3, Math.min(7, Math.floor((root.width + root.gap) / (PrismTheme.dp(150) + root.gap)) - 1))
    readonly property real tileW: Math.floor((root.width - root.gap * root.most) / (root.most + 1))
    readonly property real tileH: Math.round(root.tileW * 10 / 16)
    implicitHeight: art.height + (strip.visible ? root.gap + root.tileH : 0)

    ClippingRectangle {
        id: art
        width: root.width
        height: PrismTheme.dp(232)
        radius: PrismTheme.dp(24)
        color: PrismTheme.night
        Image {
            anchors.fill: parent
            source: Wallpapers.stillUrlFor(root.worn)
            sourceSize.width: PrismTheme.dp(1100)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            scale: artArea.containsMouse ? 1.02 : 1
            Behavior on scale { NumberAnimation { duration: PrismTheme.ms(520); easing.type: Easing.OutCubic } }
        }
        // The words stand on a shade from the left, so the picture stays whole on the right.
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.alpha(PrismTheme.night, 0.72) }
                GradientStop { position: 0.55; color: Qt.alpha(PrismTheme.night, 0.18) }
                GradientStop { position: 1; color: Qt.alpha(PrismTheme.night, 0) }
            }
        }
        MouseArea {
            id: artArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: Translation.tr("Change wallpaper")
            onClicked: PrismModel.openWallpaperGallery()
        }
        Column {
            x: PrismTheme.dp(28)
            y: PrismTheme.dp(26)
            width: Math.min(parent.width * 0.6, parent.width - x * 2)
            spacing: PrismTheme.dp(4)
            PrismText {
                width: parent.width
                text: PrismModel.wallpaperKind(root.worn) + " · " + Translation.tr("Worn now")
                color: Qt.rgba(1, 1, 1, 0.7) // iris-literal: Prism's own ink over its art, the same in every scheme
                font.pixelSize: PrismTheme.body
            }
            PrismText {
                width: parent.width
                text: PrismModel.wallpaperName(root.worn)
                elide: Text.ElideRight
                color: PrismTheme.paper
                font.pixelSize: PrismTheme.display
                font.weight: Font.Bold
                font.letterSpacing: -0.6
            }
        }
        Row {
            x: PrismTheme.dp(28)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PrismTheme.dp(26)
            spacing: PrismTheme.dp(10)
            PrismPill {
                tone: "art"
                glyph: "photo_library"
                text: Translation.tr("Change wallpaper")
                onClicked: PrismModel.openWallpaperGallery()
            }
            PrismRound {
                anchors.verticalCenter: parent.verticalCenter
                overArt: true
                smoked: true
                implicitWidth: PrismTheme.dp(34)
                glyph: "shuffle"
                Accessible.name: Translation.tr("Next wallpaper")
                onClicked: Wallpapers.nextWallpaper(Appearance.m3colors.darkmode, NiriService.currentOutput)
            }
            PrismRound {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.restorable > 0
                overArt: true
                smoked: true
                implicitWidth: PrismTheme.dp(34)
                glyph: "restart_alt"
                Accessible.name: Translation.tr("Restore defaults")
                onClicked: root.restore()
            }
        }
    }

    // The way back: the last wallpapers, a press wears one; the last tile opens them all.
    Row {
        id: strip
        y: art.height + root.gap
        visible: root.choices.length > 0
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
                        sourceSize.width: PrismTheme.dp(320)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: tile.containsMouse ? 1 : 0.86
                        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
        MouseArea {
            id: all
            // With few wallpapers to go back to, the way to all of them takes the rest of the line (no hole).
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
                color: all.pressed ? PrismTheme.fillPress : all.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
                Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
            }
            Column {
                anchors.centerIn: parent
                spacing: PrismTheme.dp(4)
                PrismGlyph {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "grid_view"
                    iconSize: PrismTheme.dp(20)
                    color: PrismTheme.ink
                }
                PrismText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Translation.tr("All wallpapers")
                    color: PrismTheme.ink2
                    font.pixelSize: PrismTheme.small
                }
            }
        }
    }
}
