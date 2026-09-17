pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell.Services.SystemTray
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style

Item {
    id: root

    property string kind: ""
    property string appId: ""
    readonly property real d: IrisStyle.density

    readonly property var player: MprisController.activePlayer
    property bool playing: root.player?.isPlaying ?? false
    property real mediaProgress: (root.player?.length ?? 0) > 0
        ? Math.max(0, Math.min(1, (root.player?.position ?? 0) / root.player.length)) : 0
    property color tint: IrisStyle.text
    property bool coverHidden: false
    readonly property alias artwork: cover

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

    property bool pressed: false
    property bool hovered: false
    property bool plated: false
    property bool bodyless: false
    property real absorb: root.plated ? 1 : 0
    readonly property real platedInset: 3 * root.d * root.absorb

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
            strokeColor: IrisStyle.tintFill(ring.tint)
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
        visible: root.plated || root.bodyless
        anchors.fill: parent
        radius: width / 2
        color: root.pressed ? IrisStyle.fillActive
            : root.hovered ? IrisStyle.fillHover
            : ColorUtils.applyAlpha(IrisStyle.text, 0)
        Behavior on color { ColorAnimation { duration: IrisStyle.duration(120) } }
    }
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: IrisStyle.bodySurface
        opacity: root.bodyless ? 0 : 1 - root.absorb
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120); easing.type: IrisStyle.feedbackEasing } }
    }

    Item {
        anchors.fill: parent
        scale: root.pressed ? IrisStyle.pressScale(0.88) : root.hovered ? 1.06 : 1
        Behavior on scale { NumberAnimation { duration: IrisStyle.duration(120); easing.type: IrisStyle.feedbackEasing } }

        IrisArtwork {
            id: cover
            visible: root.kind === "media"
            opacity: root.coverHidden ? 0 : 1
            anchors.centerIn: parent
            width: parent.width - 12 * root.d - 2 * root.platedInset
            height: width
            source: MediaArtwork.displaySource
            circular: true
        }
        Rectangle {
            visible: root.kind === "media" && opacity > 0
            anchors.fill: cover
            radius: width / 2
            color: IrisStyle.veilStrong
            opacity: !root.playing && !root.coverHidden ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
            Glyph {
                anchors.centerIn: parent
                text: "pause"
                iconSize: 15 * root.d
            }
        }
        Ring {
            visible: root.kind === "media" || (root.kind === "timer" && root.timerKind !== "stopwatch")
            anchors.fill: parent
            anchors.margins: 2 * root.d + root.platedInset
            opacity: root.coverHidden ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120); easing.type: IrisStyle.feedbackEasing } }
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
        SmartAppIcon {
            visible: root.kind === "app"
            anchors.centerIn: parent
            icon: AppSearch.lookupDesktopEntry(root.appId)?.icon ?? root.appId
            fallback: "application-x-executable"
            iconSize: Math.round(parent.width - (12 + 4 * root.absorb) * root.d)
        }
        Glyph {
            visible: root.kind === "controls"
            anchors.centerIn: parent
            text: Network.wifiEnabled ? "wifi" : "tune"
            fill: 0
            iconSize: 19 * root.d
        }
        readonly property int toolsMinutesLeft: root.timerKind === "pomodoro" ? Math.ceil(TimerService.pomodoroSecondsLeft / 60)
            : root.timerKind === "countdown" ? Math.ceil(TimerService.countdownSecondsLeft / 60) : -1
        Ring {
            visible: root.kind === "tools" && parent.toolsMinutesLeft >= 0
            anchors.fill: parent
            anchors.margins: 3 * root.d + root.platedInset
            tint: IrisStyle.secondaryAccent
            progress: root.timerProgress
        }
        Glyph {
            visible: root.kind === "tools" && parent.toolsMinutesLeft < 0
            anchors.centerIn: parent
            text: "timer"
            iconSize: 19 * root.d
            color: IrisStyle.secondaryAccent
        }
        IrisText {
            visible: root.kind === "tools" && parent.toolsMinutesLeft >= 0
            anchors.centerIn: parent
            text: parent.toolsMinutesLeft
            font.family: IrisStyle.fontNumbers
            font.features: ({ "tnum": 1 })
            font.pixelSize: 13 * IrisStyle.typeScale
            font.weight: Font.Bold
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
        Ring {
            visible: root.kind === "sound" || root.kind === "mic"
            anchors.fill: parent
            anchors.margins: 3 * root.d + root.platedInset
            readonly property bool muted: root.kind === "mic" ? Audio.micMuted : (Audio.sink?.audio?.muted ?? false)
            tint: muted ? (root.kind === "mic" ? IrisStyle.danger : IrisStyle.muted) : IrisStyle.text
            progress: muted ? 0 : Math.min(1, root.kind === "mic" ? (Audio.micVolume ?? 0) : (Audio.value ?? 0))
            Behavior on progress { NumberAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
        }
        Glyph {
            visible: root.kind === "sound" || root.kind === "mic"
            anchors.centerIn: parent
            text: root.kind === "mic" ? (Audio.micMuted ? "mic_off" : "mic")
                : (Audio.sink?.audio?.muted ?? false) ? "volume_off" : "volume_up"
            iconSize: 15 * root.d
            color: root.kind === "mic" && Audio.micMuted ? IrisStyle.danger : IrisStyle.text
        }
        Column {
            id: weatherFace
            readonly property string raw: String(Weather.data?.temp ?? "")
            readonly property bool ready: !weatherFace.raw.startsWith("--") && weatherFace.raw.length > 0
            readonly property string degrees: {
                const value = parseFloat(weatherFace.raw)
                return isNaN(value) ? "" : Math.round(value) + "°"
            }
            visible: root.kind === "weather"
            anchors.centerIn: parent
            anchors.verticalCenterOffset: weatherFace.ready ? root.d : 0
            spacing: -Math.round(2 * root.d)
            Glyph {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
                iconSize: (weatherFace.ready ? 13 : 19) * root.d
            }
            IrisText {
                visible: weatherFace.ready
                anchors.horizontalCenter: parent.horizontalCenter
                text: weatherFace.degrees
                font.family: IrisStyle.fontNumbers
                font.features: ({ "tnum": 1 })
                font.pixelSize: 11.5 * IrisStyle.typeScale
                font.weight: Font.Bold
            }
        }
        Column {
            id: notificationFace
            readonly property int count: Notifications.list?.length ?? 0
            visible: root.kind === "notifications"
            anchors.centerIn: parent
            anchors.verticalCenterOffset: notificationFace.count > 0 ? root.d : 0
            spacing: -Math.round(2 * root.d)
            Glyph {
                anchors.horizontalCenter: parent.horizontalCenter
                text: notificationFace.count > 0 ? "notifications_active" : "notifications"
                iconSize: (notificationFace.count > 0 ? 13 : 18) * root.d
            }
            IrisText {
                visible: notificationFace.count > 0
                anchors.horizontalCenter: parent.horizontalCenter
                text: notificationFace.count > 99 ? "99+" : notificationFace.count
                color: IrisStyle.badgeInk
                font.family: IrisStyle.fontNumbers
                font.features: ({ "tnum": 1 })
                font.pixelSize: 11.5 * IrisStyle.typeScale
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
