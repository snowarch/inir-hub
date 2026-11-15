pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// Wallpaper's hero is the wallpaper (a settings page about a picture opens on the picture, the way macOS's Wallpaper
// pane does), worn as the glass card of `.claude/ref/language` (glass-card-pink-sky): what it is printed as small
// glass tags on the picture, a frosted sheet at its foot with its name, one white pill that acts and a round glass key
// beside it. Under it the wallpapers to go back to, one press each, and the way to all of them.
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
        height: PrismTheme.dp(280)
        radius: PrismTheme.dp(24)
        color: PrismTheme.night
        Image {
            id: picture
            anchors.fill: parent
            source: Wallpapers.stillUrlFor(root.worn)
            sourceSize.width: PrismTheme.dp(1100)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            scale: artArea.containsMouse ? 1.02 : 1
            Behavior on scale { NumberAnimation { duration: PrismTheme.ms(520); easing.type: Easing.OutCubic } }
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

        // What it is, printed small on the picture.
        Row {
            x: PrismTheme.dp(18)
            y: PrismTheme.dp(18)
            spacing: PrismTheme.dp(6)
            Repeater {
                model: [PrismModel.wallpaperKind(root.worn)]
                delegate: Rectangle {
                    required property string modelData
                    width: tag.implicitWidth + PrismTheme.dp(18)
                    height: PrismTheme.dp(24)
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
            visible: root.restorable > 0
            anchors.right: parent.right
            anchors.rightMargin: PrismTheme.dp(16)
            y: PrismTheme.dp(14)
            overArt: true
            smoked: true
            implicitWidth: PrismTheme.dp(34)
            glyph: "restart_alt"
            Accessible.name: Translation.tr("Restore defaults")
            onClicked: root.restore()
        }

        // The frosted sheet: the picture under it, blurred and darkened, holds the name and what acts.
        ShaderEffectSource {
            id: under
            x: sheet.x; y: sheet.y; width: sheet.width; height: sheet.height
            sourceItem: picture
            sourceRect: Qt.rect(sheet.x, sheet.y, sheet.width, sheet.height)
            visible: false
        }
        MultiEffect {
            x: sheet.x; y: sheet.y; width: sheet.width; height: sheet.height
            source: under
            blurEnabled: true
            blur: 1
            blurMax: 48
            brightness: -0.12
        }
        Rectangle {
            id: sheet
            y: art.height - height
            width: art.width
            height: PrismTheme.dp(88)
            color: PrismTheme.glassSheet
            Rectangle { width: parent.width; height: 1; color: PrismTheme.spotEdge }

            Column {
                x: PrismTheme.dp(24)
                width: actions.x - x - PrismTheme.dp(20)
                anchors.verticalCenter: parent.verticalCenter
                spacing: PrismTheme.dp(3)
                PrismText {
                    width: parent.width
                    text: Translation.tr("Worn now").toUpperCase()
                    mono: true
                    color: PrismTheme.spotInk2
                    font.pixelSize: PrismTheme.caption - 1
                    font.letterSpacing: 0.8
                }
                PrismText {
                    width: parent.width
                    text: PrismModel.wallpaperName(root.worn)
                    elide: Text.ElideRight
                    color: PrismTheme.paper
                    font.pixelSize: PrismTheme.title
                    font.weight: Font.Bold
                    font.letterSpacing: -PrismTheme.title * 0.035
                }
            }
            Row {
                id: actions
                x: sheet.width - width - PrismTheme.dp(20)
                anchors.verticalCenter: parent.verticalCenter
                spacing: PrismTheme.dp(8)
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
                    implicitWidth: PrismTheme.dp(38)
                    glyph: "shuffle"
                    Accessible.name: Translation.tr("Next wallpaper")
                    onClicked: Wallpapers.nextWallpaper(Appearance.m3colors.darkmode, NiriService.currentOutput)
                }
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
            PrismKey {
                anchors.fill: parent
                radius: PrismTheme.dp(16)
                face: PrismTheme.keyQuiet
                hovered: all.containsMouse
                down: all.pressed
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
}
