pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.fx
import qs.modules.iris.prism.controls

// Home is the person's: their desktop as it stands beside what they change every day. The picture fills its card to the
// day's height (a press opens Wallpaper); at its foot its name alone (his 11-20: no row of colours under it), with the
// next wallpaper a press away. The day's card holds its keys, then the two levels people reach for
// most, so neither card stands half empty (his 11-19: "distribuí mejor el wallpaper"). A machine without a sound server
// or a dimmable screen simply shows no level: nothing here says what is missing.
Item {
    id: root
    signal reach(var row)

    readonly property real gap: PrismTheme.dp(14)
    readonly property real pad: PrismTheme.dp(18)
    readonly property bool stacked: root.width < PrismTheme.dp(720)
    readonly property real deskWidth: root.stacked ? root.width : Math.round((root.width - root.gap) * 0.47)
    readonly property real dayWidth: root.stacked ? root.width : root.width - root.deskWidth - root.gap
    readonly property real dayHeight: root.pad + tiles.implicitHeight + (root.levels ? PrismTheme.dp(16) + levels.implicitHeight : 0) + root.pad
    readonly property real topHeight: root.stacked ? 0 : Math.max(PrismTheme.dp(220), root.dayHeight)
    // The screen Settings stands on, or the first one: its brightness is the one people mean.
    readonly property var monitor: Brightness.monitors.find(entry => entry.screen?.name === NiriService.currentOutput) ?? Brightness.monitors[0] ?? null
    // A screen that answers with a level (a nested or virtual output reads "ready" with none).
    readonly property bool dims: Boolean(root.monitor?.ready) && Number.isFinite(Number(root.monitor?.brightness))
    readonly property bool levels: Audio.ready || root.dims
    implicitHeight: root.stacked ? desk.height + root.gap + day.height : root.topHeight

    // The desktop.
    ClippingRectangle {
        id: desk
        width: root.deskWidth
        // Stacked (the side column open), a band, not a poster: the day's keys stay in view under it.
        height: root.stacked ? Math.round(root.width * 0.36) : root.topHeight
        radius: PrismTheme.cardRadius
        color: PrismTheme.night
        // Under the picture, and in its place while there is none: the desktop's own colours as art, never a black hole.
        PrismFlow {
            anchors.fill: parent
            tint: "blue"
            seed: 0.41
            centre: Qt.point(0.5, 0.45)
            thickness: 0.6
        }
        Image {
            anchors.fill: parent
            source: Wallpapers.stillUrlFor(String(Wallpapers.effectiveWallpaperPath ?? ""))
            sourceSize.width: Math.round(desk.width * 2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            scale: deskArea.containsMouse ? 1.025 : 1
            Behavior on scale { NumberAnimation { duration: PrismTheme.ms(520); easing.type: Easing.OutCubic } }
        }
        // The foot darkens just enough for white words, whatever the picture.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.round(parent.height * 0.5)
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: PrismTheme.spotScrim }
            }
        }
        MouseArea {
            id: deskArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Link
            Accessible.name: Translation.tr("Wallpaper")
            onClicked: PrismState.go("wallpaper")
        }
        // The picture's name (a file's own name only when a person would say it).
        Column {
            x: root.pad
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.pad
            width: parent.width - 2 * root.pad - next.width - PrismTheme.dp(12)
            spacing: PrismTheme.dp(8)
            PrismText {
                width: parent.width
                readonly property string path: String(Wallpapers.effectiveWallpaperPath ?? "")
                text: path.length > 0 ? PrismModel.wallpaperName(path) : Translation.tr("Choose a wallpaper")
                color: PrismTheme.paper
                font.pixelSize: PrismTheme.row
                font.weight: Font.DemiBold
                font.letterSpacing: -PrismTheme.row * 0.01
            }
        }
        PrismRound {
            id: next
            anchors.right: parent.right
            anchors.rightMargin: PrismTheme.dp(14)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PrismTheme.dp(14)
            overArt: true
            smoked: true
            implicitWidth: PrismTheme.dp(34)
            glyph: "shuffle"
            Accessible.name: Translation.tr("Next wallpaper")
            onClicked: Wallpapers.nextWallpaper(Appearance.m3colors.darkmode, NiriService.currentOutput)
        }
    }

    // Every day: its keys, then sound and light, each level moving the real thing.
    Rectangle {
        id: day
        x: root.stacked ? 0 : root.deskWidth + root.gap
        y: root.stacked ? desk.height + root.gap : 0
        width: root.dayWidth
        height: root.stacked ? root.dayHeight : root.topHeight
        radius: PrismTheme.cardRadius
        color: PrismTheme.card
        PrismHome {
            id: tiles
            x: root.pad
            y: root.pad
            width: parent.width - 2 * root.pad
            onReach: row => root.reach(row)
        }
        Column {
            id: levels
            visible: root.levels
            x: root.pad
            // Side by side, the levels sit at the card's foot, level with the picture's name.
            y: parent.height - root.pad - height
            width: parent.width - 2 * root.pad
            spacing: PrismTheme.dp(10)
            Row {
                visible: Audio.ready
                width: parent.width
                spacing: PrismTheme.dp(10)
                PrismRound {
                    id: mute
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: PrismTheme.dp(30)
                    ghost: !Boolean(Audio.sink?.audio?.muted)
                    lit: Boolean(Audio.sink?.audio?.muted)
                    glyph: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                    glyphSize: PrismTheme.dp(16)
                    Accessible.name: Translation.tr("Mute")
                    onClicked: Audio.toggleMute()
                }
                PrismSlider {
                    id: volume
                    width: parent.width - mute.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    label: Math.round(volume.live) + "%"
                    Accessible.name: Translation.tr("Volume")
                    from: 0
                    to: 100
                    value: Math.round(Audio.value * 100)
                    onMoved: value => { Audio.lastUserChange = Date.now(); if (Audio.sink?.audio) Audio.sink.audio.volume = value / 100 }
                    onCommitted: value => { Audio.lastUserChange = Date.now(); if (Audio.sink?.audio) Audio.sink.audio.volume = value / 100 }
                }
            }
            Row {
                visible: root.dims
                width: parent.width
                spacing: PrismTheme.dp(10)
                Item {
                    width: PrismTheme.dp(30)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    PrismGlyph {
                        anchors.centerIn: parent
                        text: "light_mode"
                        iconSize: PrismTheme.dp(16)
                        color: PrismTheme.ink2
                    }
                }
                PrismSlider {
                    id: light
                    width: parent.width - PrismTheme.dp(30) - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    label: Math.round(light.live) + "%"
                    Accessible.name: Translation.tr("Brightness")
                    from: 1
                    to: 100
                    value: Math.round(Number(root.monitor?.brightness ?? 0) * 100)
                    onMoved: value => root.monitor?.setBrightness(value / 100)
                    onCommitted: value => root.monitor?.setBrightness(value / 100)
                }
            }
        }
    }
}
