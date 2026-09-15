pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell.Services.SystemTray
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style

// What a bubble shows, wherever it lives: beside the Island or floating on its
// own. One black disc and the minimal presentation of its kind — a cover with
// its progress ring, a timer, the recording dot, a level ring, a count. State is
// read from the shared services; the Island passes the values it already owns
// (artwork tint, YT Music aware playback) so both places read the same.
Item {
    id: root

    property string kind: ""
    readonly property real d: IrisStyle.density

    // Media
    readonly property var player: MprisController.activePlayer
    property bool playing: root.player?.isPlaying ?? false
    property real mediaProgress: (root.player?.length ?? 0) > 0
        ? Math.max(0, Math.min(1, (root.player?.position ?? 0) / root.player.length)) : 0
    property color tint: IrisStyle.text
    // A shared-element copy of the cover is flying: the cover and its ring step aside.
    property bool coverHidden: false
    readonly property alias artwork: cover

    // Timers
    readonly property string timerKind: TimerService.pomodoroRunning ? "pomodoro"
        : TimerService.countdownRunning ? "countdown"
        : TimerService.stopwatchRunning ? "stopwatch" : ""
    readonly property bool timerPaused: root.timerKind === "pomodoro" ? TimerService.pomodoroPaused
        : root.timerKind === "countdown" ? TimerService.countdownPaused : TimerService.stopwatchPaused
    readonly property real timerProgress: root.timerKind === "pomodoro"
        ? 1 - TimerService.pomodoroSecondsLeft / Math.max(1, TimerService.pomodoroLapDuration)
        : root.timerKind === "countdown"
            ? 1 - TimerService.countdownSecondsLeft / Math.max(1, TimerService.countdownDuration) : 0
    readonly property string timerGlyph: root.timerKind === "pomodoro" && TimerService.pomodoroBreak ? "coffee"
        : root.timerKind === "stopwatch" ? "timer" : "hourglass_top"

    property int trayCount: SystemTray.items.values.filter(item => item && item.id
        && (!(Config.options?.iris?.tray?.hidePassive ?? false) || item.status !== Status.Passive)).length

    // Press and hover feedback belong to the face, never to a clipping host.
    property bool pressed: false
    property bool hovered: false

    component Glyph: MaterialSymbol {
        fill: 1
        color: IrisStyle.text
    }
    component Ring: Shape {
        id: ring
        property real progress: 0
        property color tint: IrisStyle.text
        property real stroke: Math.max(2, 2.5 * root.d)
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: ColorUtils.applyAlpha(ring.tint, 0.22)
            strokeWidth: ring.stroke
            fillColor: "transparent"
            PathAngleArc {
                centerX: ring.width / 2; centerY: ring.height / 2
                radiusX: ring.width / 2 - ring.stroke / 2; radiusY: radiusX
                startAngle: 0; sweepAngle: 360
            }
        }
        ShapePath {
            strokeColor: ring.tint
            strokeWidth: ring.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.width / 2; centerY: ring.height / 2
                radiusX: ring.width / 2 - ring.stroke / 2; radiusY: radiusX
                startAngle: -90
                sweepAngle: 360 * Math.max(0, Math.min(1, ring.progress))
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: IrisStyle.surface
    }

    Item {
        anchors.fill: parent
        scale: root.pressed ? 0.88 : root.hovered ? 1.06 : 1
        Behavior on scale { NumberAnimation { duration: IrisStyle.duration(120); easing.type: Easing.OutCubic } }

        IrisArtwork {
            id: cover
            visible: root.kind === "media"
            opacity: root.coverHidden ? 0 : 1
            anchors.centerIn: parent
            width: parent.width - 12 * root.d
            height: width
            source: MediaArtwork.displaySource
            circular: true
        }
        // Minimal keeps conveying state: a paused cover dims under a pause glyph.
        Rectangle {
            visible: root.kind === "media" && opacity > 0
            anchors.fill: cover
            radius: width / 2
            color: ColorUtils.applyAlpha(IrisStyle.surface, 0.55)
            opacity: !root.playing && !root.coverHidden ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: Easing.OutCubic } }
            Glyph {
                anchors.centerIn: parent
                text: "pause"
                iconSize: 15 * root.d
            }
        }
        Ring {
            visible: root.kind === "media" || (root.kind === "timer" && root.timerKind !== "stopwatch")
            anchors.fill: parent
            anchors.margins: 2 * root.d
            // The ring belongs to the cover: it leaves with it and returns once it lands.
            opacity: root.coverHidden ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120); easing.type: Easing.OutCubic } }
            tint: root.kind === "media" ? root.tint : IrisStyle.secondaryAccent
            progress: root.kind === "media" ? root.mediaProgress : root.timerProgress
        }
        Glyph {
            visible: root.kind === "timer"
            anchors.centerIn: parent
            text: root.timerPaused ? "pause" : root.timerGlyph
            iconSize: 16 * root.d
            color: IrisStyle.secondaryAccent
        }
        Rectangle {
            id: recordDot
            visible: root.kind === "record"
            anchors.centerIn: parent
            width: 12 * root.d
            height: width
            radius: width / 2
            color: IrisStyle.danger
            SequentialAnimation on opacity {
                running: recordDot.visible && IrisStyle.motionEnabled
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                onRunningChanged: if (!running) recordDot.opacity = 1
            }
        }
        Glyph {
            visible: root.kind === "controls"
            anchors.centerIn: parent
            text: Network.wifiEnabled ? "wifi" : "tune"
            fill: 0
            iconSize: 19 * root.d
        }
        Glyph {
            visible: root.kind === "tools"
            anchors.centerIn: parent
            text: "timer"
            iconSize: 19 * root.d
            color: IrisStyle.secondaryAccent
        }
        IrisText {
            visible: root.kind === "tray"
            anchors.centerIn: parent
            text: root.trayCount
            font.family: IrisStyle.fontNumbers
            font.features: ({ "tnum": 1 })
            font.pixelSize: 16 * IrisStyle.typeScale
            font.weight: Font.Bold
            color: IrisStyle.accent
        }
        // Level bubbles: the ring is the level, the glyph its state; muted
        // reads quiet for sound and red for a microphone.
        Ring {
            visible: root.kind === "sound" || root.kind === "mic"
            anchors.fill: parent
            anchors.margins: 3 * root.d
            readonly property bool muted: root.kind === "mic" ? Audio.micMuted : (Audio.sink?.audio?.muted ?? false)
            tint: muted ? (root.kind === "mic" ? IrisStyle.danger : IrisStyle.muted) : IrisStyle.text
            progress: muted ? 0 : Math.min(1, root.kind === "mic" ? (Audio.micVolume ?? 0) : (Audio.value ?? 0))
            Behavior on progress { NumberAnimation { duration: IrisStyle.duration(110); easing.type: Easing.OutCubic } }
        }
        Glyph {
            visible: root.kind === "sound" || root.kind === "mic"
            anchors.centerIn: parent
            text: root.kind === "mic" ? (Audio.micMuted ? "mic_off" : "mic")
                : (Audio.sink?.audio?.muted ?? false) ? "volume_off" : "volume_up"
            iconSize: 15 * root.d
            color: root.kind === "mic" && Audio.micMuted ? IrisStyle.danger : IrisStyle.text
        }
        Glyph {
            visible: root.kind === "weather"
            anchors.centerIn: parent
            text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
            iconSize: 19 * root.d
        }
        Glyph {
            visible: root.kind === "notifications"
            anchors.centerIn: parent
            text: "notifications"
            iconSize: 18 * root.d
        }
        Rectangle {
            visible: root.kind === "notifications"
            readonly property int count: Notifications.list?.length ?? 0
            x: parent.width - width * 0.9
            y: -height * 0.1
            height: Math.round(15 * root.d)
            width: Math.max(height, notificationCount.implicitWidth + 7 * root.d)
            radius: height / 2
            color: IrisStyle.danger
            border.width: Math.max(1, Math.round(1.5 * root.d))
            border.color: IrisStyle.surface
            IrisText {
                id: notificationCount
                anchors.centerIn: parent
                text: parent.count > 9 ? "9+" : parent.count
                color: "#ffffff"
                font.family: IrisStyle.fontNumbers
                font.pixelSize: 9.5 * IrisStyle.typeScale
                font.weight: Font.Bold
            }
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: root.kind === "controls" ? Translation.tr("Quick controls")
        : root.kind === "notifications" ? Translation.tr("Notifications")
        : root.kind === "tray" ? Translation.tr("Tray")
        : root.kind === "tools" ? Translation.tr("Timers")
        : root.kind === "weather" ? Translation.tr("Weather")
        : root.kind === "media" ? Translation.tr("Now playing")
        : root.kind === "sound" ? Translation.tr("Sound")
        : root.kind === "mic" ? Translation.tr("Microphone")
        : root.kind === "record" ? Translation.tr("Screen recording") : Translation.tr("Timer")
}
