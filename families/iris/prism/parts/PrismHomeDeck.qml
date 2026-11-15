pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// Home's two widgets: the wallpaper itself as art cut by a shape, with a shuffle and the way to the gallery; and Sound
// & light, the two levels a person reaches for most, as Prism's faders. They act on the desktop at once: nothing here
// is a setting to look for.
Item {
    id: root
    readonly property bool stacked: root.width < PrismTheme.dp(560)
    readonly property real cardHeight: PrismTheme.dp(196)
    implicitHeight: root.stacked ? root.cardHeight * 2 + PrismTheme.dp(10) : root.cardHeight

    readonly property string wallPath: String(Wallpapers.effectiveWallpaperPath ?? "")
    readonly property string wallName: PrismModel.wallpaperName(root.wallPath)
    // The screen Settings stands on, or the first one: its brightness is the one people mean.
    readonly property var monitor: Brightness.monitors.find(entry => entry.screen?.name === NiriService.currentOutput) ?? Brightness.monitors[0] ?? null
    // A screen that answers with a level (a nested or virtual output reads "ready" with none).
    readonly property bool dims: Boolean(root.monitor?.ready) && Number.isFinite(Number(root.monitor?.brightness))

    // The wallpaper as art cut by a shape (`.claude/ref/language`, landing-art-cut): a band from the left that steps
    // down into a round lobe at the right. What it is sits in the room the cut leaves: its name in the lower notch, the
    // folder's count in the upper one, the shuffle and the gallery as keys on the lobe.
    Item {
        id: wall
        width: root.stacked ? root.width : Math.round((root.width - PrismTheme.dp(10)) * 0.58)
        height: root.cardHeight
        readonly property real band: Math.round(height * 0.56)
        readonly property real lobeTop: Math.round(height * 0.34)
        readonly property real turn: Math.round(width * 0.58)
        readonly property real fillet: PrismTheme.dp(20)
        readonly property real lobe: (height - wall.lobeTop) / 2
        readonly property int count: Number(Wallpapers.folderModel?.count ?? 0)

        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: cut
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }
            Rectangle { anchors.fill: parent; color: PrismTheme.night }
            Image {
                anchors.fill: parent
                source: Wallpapers.stillUrlFor(root.wallPath)
                sourceSize.width: PrismTheme.dp(720)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                scale: wallArea.containsMouse ? 1.03 : 1
                Behavior on scale { NumberAnimation { duration: PrismTheme.ms(420); easing.type: Easing.OutCubic } }
            }
        }
        Shape {
            id: cut
            anchors.fill: parent
            visible: false
            layer.enabled: true
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1
                strokeColor: "transparent"
                fillColor: "white"
                startX: wall.band / 2; startY: 0
                PathLine { x: wall.turn - wall.fillet; y: 0 }
                PathArc { x: wall.turn; y: wall.fillet; radiusX: wall.fillet; radiusY: wall.fillet }
                PathLine { x: wall.turn; y: wall.lobeTop - wall.fillet }
                PathArc { x: wall.turn + wall.fillet; y: wall.lobeTop; radiusX: wall.fillet; radiusY: wall.fillet; direction: PathArc.Counterclockwise }
                PathLine { x: wall.width - wall.lobe; y: wall.lobeTop }
                PathArc { x: wall.width; y: wall.lobeTop + wall.lobe; radiusX: wall.lobe; radiusY: wall.lobe }
                PathArc { x: wall.width - wall.lobe; y: wall.height; radiusX: wall.lobe; radiusY: wall.lobe }
                PathLine { x: wall.turn + wall.fillet; y: wall.height }
                PathArc { x: wall.turn; y: wall.height - wall.fillet; radiusX: wall.fillet; radiusY: wall.fillet }
                PathLine { x: wall.turn; y: wall.band + wall.fillet }
                PathArc { x: wall.turn - wall.fillet; y: wall.band; radiusX: wall.fillet; radiusY: wall.fillet; direction: PathArc.Counterclockwise }
                PathLine { x: wall.band / 2; y: wall.band }
                PathArc { x: 0; y: wall.band / 2; radiusX: wall.band / 2; radiusY: wall.band / 2 }
                PathArc { x: wall.band / 2; y: 0; radiusX: wall.band / 2; radiusY: wall.band / 2 }
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
        // The lower notch: what it is, printed small, and its name.
        Column {
            x: PrismTheme.dp(4)
            width: wall.turn - wall.fillet - PrismTheme.dp(12)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PrismTheme.dp(4)
            spacing: PrismTheme.dp(3)
            PrismText {
                text: PrismModel.wallpaperKind(root.wallPath).toUpperCase()
                mono: true
                color: PrismTheme.ink3
                font.pixelSize: PrismTheme.caption - 1
                font.letterSpacing: 0.8
            }
            PrismText {
                width: parent.width
                text: root.wallName
                elide: Text.ElideRight
                font.pixelSize: PrismTheme.head
                font.weight: Font.Bold
                font.letterSpacing: -PrismTheme.head * 0.03
            }
        }
        // The upper notch: how many there are to go through.
        Column {
            visible: wall.count > 0
            x: wall.turn + wall.fillet + PrismTheme.dp(12)
            y: Math.round((wall.lobeTop - height) / 2) - PrismTheme.dp(2)
            spacing: PrismTheme.dp(2)
            PrismText {
                text: String(wall.count)
                figures: true
                font.pixelSize: PrismTheme.title
                font.weight: Font.Bold
                font.letterSpacing: -0.6
            }
            PrismText {
                // A long word takes a second line in the notch, never a cut one.
                width: Math.min(implicitWidth, wall.width - wall.turn - wall.fillet - PrismTheme.dp(16))
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                text: Translation.tr("Wallpapers").toUpperCase()
                mono: true
                color: PrismTheme.ink3
                font.pixelSize: PrismTheme.caption - 1
                font.letterSpacing: 0.8
            }
        }
        Row {
            id: wallKeys
            anchors.right: parent.right
            anchors.rightMargin: PrismTheme.dp(18)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PrismTheme.dp(18)
            spacing: PrismTheme.dp(8)
            PrismRound {
                overArt: true
                smoked: true
                glyph: "photo_library"
                Accessible.name: Translation.tr("Gallery")
                onClicked: PrismModel.openWallpaperGallery()
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
        color: PrismTheme.card

        Column {
            anchors.fill: parent
            anchors.margins: PrismTheme.dp(18)
            spacing: PrismTheme.dp(12)
            Item {
                width: parent.width
                height: PrismTheme.dp(44)
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: PrismTheme.dp(3)
                    PrismText {
                        text: Translation.tr("Now").toUpperCase()
                        mono: true
                        color: PrismTheme.ink3
                        font.pixelSize: PrismTheme.caption - 1
                        font.letterSpacing: 0.8
                    }
                    PrismText {
                        text: Translation.tr("Sound & light")
                        font.pixelSize: PrismTheme.head
                        font.weight: Font.Bold
                        font.letterSpacing: -PrismTheme.head * 0.03
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
