pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// Home's two widgets, in the grammar of the Apple widget set: the wallpaper itself, large, with a shuffle and the way
// to the gallery; and Sound & light, the two levels a person reaches for most, as Prism's lying pills. They act on
// the desktop at once: nothing here is a setting to look for.
Item {
    id: root
    readonly property bool stacked: root.width < PrismTheme.dp(560)
    readonly property real cardHeight: PrismTheme.dp(196)
    implicitHeight: root.stacked ? root.cardHeight * 2 + PrismTheme.dp(10) : root.cardHeight

    readonly property string wallPath: String(Wallpapers.effectiveWallpaperPath ?? "")
    readonly property string wallName: {
        const file = root.wallPath.split("/").pop() ?? ""
        const bare = file.replace(/\.[^.]+$/, "").replace(/[_-]+/g, " ").trim()
        return bare.length > 0 ? bare : Translation.tr("Your wallpaper")
    }
    // The screen Settings stands on, or the first one: its brightness is the one people mean.
    readonly property var monitor: Brightness.monitors.find(entry => entry.screen?.name === NiriService.currentOutput) ?? Brightness.monitors[0] ?? null
    // A screen that answers with a level (a nested or virtual output reads "ready" with none).
    readonly property bool dims: Boolean(root.monitor?.ready) && Number.isFinite(Number(root.monitor?.brightness))

    // The wallpaper, edge to edge: its name over a shade at the foot, shuffle and the gallery as smoked circles.
    ClippingRectangle {
        id: wall
        width: root.stacked ? root.width : Math.round((root.width - PrismTheme.dp(10)) * 0.58)
        height: root.cardHeight
        radius: PrismTheme.dp(24)
        color: PrismTheme.night
        Image {
            anchors.fill: parent
            source: Wallpapers.stillUrlFor(root.wallPath)
            sourceSize.width: PrismTheme.dp(720)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            scale: wallArea.containsMouse ? 1.03 : 1
            Behavior on scale { NumberAnimation { duration: PrismTheme.ms(420); easing.type: Easing.OutCubic } }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.35; color: Qt.alpha(PrismTheme.night, 0) }
                GradientStop { position: 1; color: Qt.alpha(PrismTheme.night, 0.78) }
            }
        }
        MouseArea {
            id: wallArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Link
            Accessible.name: Translation.tr("Wallpaper")
            onClicked: PrismState.go("wallpaper")
        }
        Column {
            anchors.left: parent.left
            anchors.leftMargin: PrismTheme.dp(20)
            anchors.right: wallKeys.left
            anchors.rightMargin: PrismTheme.dp(12)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PrismTheme.dp(18)
            spacing: PrismTheme.dp(2)
            PrismText {
                text: Translation.tr("Wallpaper")
                color: Qt.alpha(PrismTheme.paper, 0.7)
                font.pixelSize: PrismTheme.small
            }
            PrismText {
                width: parent.width
                text: root.wallName
                elide: Text.ElideRight
                color: PrismTheme.paper
                font.pixelSize: PrismTheme.head
                font.weight: Font.Bold
                font.letterSpacing: -0.2
            }
        }
        Row {
            id: wallKeys
            anchors.right: parent.right
            anchors.rightMargin: PrismTheme.dp(16)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PrismTheme.dp(16)
            spacing: PrismTheme.dp(8)
            PrismRound {
                overArt: true
                smoked: true
                glyph: "photo_library"
                Accessible.name: Translation.tr("Gallery")
                onClicked: PrismState.go("wallpaper")
            }
            PrismRound {
                overArt: true
                solid: true
                implicitWidth: PrismTheme.dp(38)
                glyphSize: PrismTheme.dp(20)
                glyph: "shuffle"
                Accessible.name: Translation.tr("Next wallpaper")
                onClicked: Wallpapers.nextWallpaper(Appearance.m3colors.darkmode, NiriService.currentOutput)
            }
        }
    }

    // Sound & light: the output's volume and the screen's brightness, each a pill that moves the real thing.
    Rectangle {
        x: root.stacked ? 0 : wall.width + PrismTheme.dp(10)
        y: root.stacked ? wall.height + PrismTheme.dp(10) : 0
        width: root.stacked ? root.width : root.width - wall.width - PrismTheme.dp(10)
        height: root.cardHeight
        radius: PrismTheme.dp(24)
        color: PrismTheme.fill

        Column {
            anchors.fill: parent
            anchors.margins: PrismTheme.dp(18)
            spacing: PrismTheme.dp(12)
            Item {
                width: parent.width
                height: PrismTheme.dp(34)
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    PrismText {
                        text: Translation.tr("Now")
                        color: PrismTheme.ink2
                        font.pixelSize: PrismTheme.small
                    }
                    PrismText {
                        text: Translation.tr("Sound & light")
                        font.pixelSize: PrismTheme.row
                        font.weight: Font.Bold
                    }
                }
                // Mute answers in place: the circle goes solid while the sound is off.
                PrismRound {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Audio.ready
                    lit: Boolean(Audio.sink?.audio?.muted)
                    glyph: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                    Accessible.name: Translation.tr("Mute")
                    onClicked: Audio.toggleMute()
                }
            }
            PrismSlider {
                id: volume
                width: parent.width
                visible: Audio.ready
                glyph: "volume_up"
                label: Math.round(volume.live) + "%"
                Accessible.name: Translation.tr("Volume")
                from: 0
                to: 100
                value: Math.round(Audio.value * 100)
                onMoved: value => { Audio.lastUserChange = Date.now(); if (Audio.sink?.audio) Audio.sink.audio.volume = value / 100 }
                onCommitted: value => { Audio.lastUserChange = Date.now(); if (Audio.sink?.audio) Audio.sink.audio.volume = value / 100 }
            }
            PrismSlider {
                id: light
                width: parent.width
                visible: root.dims
                glyph: "light_mode"
                label: Math.round(light.live) + "%"
                Accessible.name: Translation.tr("Brightness")
                from: 1
                to: 100
                value: Math.round(Number(root.monitor?.brightness ?? 0) * 100)
                onMoved: value => root.monitor?.setBrightness(value / 100)
                onCommitted: value => root.monitor?.setBrightness(value / 100)
            }
            // A machine with neither (no sound server, a screen without a dimmer) says so instead of an empty card.
            PrismText {
                visible: !Audio.ready && !root.dims
                width: parent.width
                text: Translation.tr("No sound device or dimmable screen was found.")
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.small
                wrapMode: Text.WordWrap
                maximumLineCount: 3
            }
        }
    }
}
