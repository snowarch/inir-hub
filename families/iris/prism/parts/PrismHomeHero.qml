pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// Home is the person's: their desktop as it stands (picture, Island, the three colours iRiS takes from it; a press
// opens Wallpaper) beside what they change every day, then the two levels they reach for most. A machine without a
// sound server or a dimmable screen simply shows no level: nothing here says what is missing.
Item {
    id: root
    signal reach(var row)

    readonly property real gap: PrismTheme.dp(14)
    readonly property bool stacked: root.width < PrismTheme.dp(760)
    readonly property real deskWidth: root.stacked ? root.width : Math.round((root.width - root.gap) * 0.42)
    readonly property real dayWidth: root.stacked ? root.width : root.width - root.deskWidth - root.gap
    readonly property real topHeight: root.stacked ? 0 : Math.max(PrismTheme.dp(236), day.implicitHeight)
    // The screen Settings stands on, or the first one: its brightness is the one people mean.
    readonly property var monitor: Brightness.monitors.find(entry => entry.screen?.name === NiriService.currentOutput) ?? Brightness.monitors[0] ?? null
    // A screen that answers with a level (a nested or virtual output reads "ready" with none).
    readonly property bool dims: Boolean(root.monitor?.ready) && Number.isFinite(Number(root.monitor?.brightness))
    readonly property bool levels: Audio.ready || root.dims
    readonly property real levelsY: root.stacked ? desk.height + root.gap + day.height + root.gap : root.topHeight + root.gap
    implicitHeight: root.levelsY + (root.levels ? levelsCard.height : -root.gap)

    // The desktop.
    ClippingRectangle {
        id: desk
        width: root.deskWidth
        height: root.stacked ? Math.round(root.width * 0.5) : root.topHeight
        radius: PrismTheme.cardRadius
        color: PrismTheme.night
        Image {
            anchors.fill: parent
            source: Wallpapers.stillUrlFor(String(Wallpapers.effectiveWallpaperPath ?? ""))
            sourceSize.width: Math.round(desk.width * 2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            scale: deskArea.containsMouse ? 1.02 : 1
            Behavior on scale { NumberAnimation { duration: PrismTheme.ms(520); easing.type: Easing.OutCubic } }
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(parent.height * 0.05)
            width: Math.round(parent.width * 0.22)
            height: Math.round(parent.height * 0.07)
            radius: height / 2
            color: PrismTheme.night
        }
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.round(parent.height * 0.4)
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Qt.alpha(PrismTheme.night, 0.6) }
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
        // The three colours iRiS wears, taken from the picture.
        Row {
            x: PrismTheme.dp(18)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PrismTheme.dp(18)
            spacing: PrismTheme.dp(6)
            Repeater {
                model: [IrisStyle.accent, IrisStyle.secondaryAccent, IrisStyle.signal]
                delegate: Rectangle {
                    required property color modelData
                    width: PrismTheme.dp(24)
                    height: width
                    radius: width / 2
                    color: modelData
                }
            }
        }
        PrismRound {
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

    // Every day.
    Rectangle {
        id: day
        x: root.stacked ? 0 : root.deskWidth + root.gap
        y: root.stacked ? desk.height + root.gap : 0
        width: root.dayWidth
        height: root.stacked ? implicitHeight : root.topHeight
        implicitHeight: tiles.implicitHeight + PrismTheme.dp(36)
        radius: PrismTheme.cardRadius
        color: PrismTheme.card
        PrismHome {
            id: tiles
            x: PrismTheme.dp(18)
            y: PrismTheme.dp(18)
            width: parent.width - PrismTheme.dp(36)
            onReach: row => root.reach(row)
        }
    }

    // Sound and light: each level moves the real thing.
    Rectangle {
        id: levelsCard
        visible: root.levels
        y: root.levelsY
        width: root.width
        height: PrismTheme.dp(72)
        radius: PrismTheme.cardRadius
        color: PrismTheme.card
        Row {
            x: PrismTheme.dp(18)
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - PrismTheme.dp(36)
            spacing: PrismTheme.dp(18)
            readonly property int shown: (Audio.ready ? 1 : 0) + (root.dims ? 1 : 0)
            readonly property real share: (width - (Audio.ready ? mute.width + spacing : 0) - spacing * (shown - 1)) / Math.max(1, shown)
            PrismRound {
                id: mute
                visible: Audio.ready
                anchors.verticalCenter: parent.verticalCenter
                lit: Boolean(Audio.sink?.audio?.muted)
                glyph: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                Accessible.name: Translation.tr("Mute")
                onClicked: Audio.toggleMute()
            }
            PrismSlider {
                id: volume
                visible: Audio.ready
                width: parent.share
                anchors.verticalCenter: parent.verticalCenter
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
                visible: root.dims
                width: parent.share
                anchors.verticalCenter: parent.verticalCenter
                glyph: "light_mode"
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
