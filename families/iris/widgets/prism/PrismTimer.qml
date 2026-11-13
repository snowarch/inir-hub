pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.widgets

// Timers in Prism: the timer that matters on the tab (running, then held, then the countdown), whether it runs on the
// flap, its time in the pane beside its key, the other two on the foot. A key starts and holds; a right click resets;
// the wheel on a resting countdown sets it a minute at a time.
PrismFolder {
    id: root

    readonly property var timers: [
        { key: "focus", glyph: TimerService.pomodoroBreak ? "coffee" : "target",
            label: TimerService.pomodoroLongBreak ? Translation.tr("Long break") : TimerService.pomodoroBreak ? Translation.tr("Break") : Translation.tr("Focus"),
            value: root.widget.formatSeconds(TimerService.pomodoroSecondsLeft),
            running: TimerService.pomodoroRunning, paused: TimerService.pomodoroPaused,
            tint: TimerService.pomodoroBreak ? root.accent2 : root.highlight },
        { key: "stopwatch", glyph: "timer", label: Translation.tr("Stopwatch"),
            value: root.widget.formatSeconds(TimerService.stopwatchTime / 100),
            running: TimerService.stopwatchRunning, paused: TimerService.stopwatchPaused, tint: root.accent },
        { key: "countdown", glyph: "hourglass_top", label: Translation.tr("Timer"),
            value: root.widget.formatSeconds(TimerService.countdownSecondsLeft),
            running: TimerService.countdownRunning, paused: TimerService.countdownPaused, tint: root.highlight }
    ]
    readonly property var lead: {
        const active = root.timers.filter(timer => timer.running && !timer.paused)
        const held = root.timers.filter(timer => timer.running || timer.paused)
        return active[0] ?? held[0] ?? root.timers[2]
    }
    readonly property var others: root.timers.filter(timer => timer.key !== root.lead.key)
    function live(timer: var): bool { return timer.running && !timer.paused }
    function state(timer: var): string {
        return root.live(timer) ? Translation.tr("Running") : timer.paused ? Translation.tr("Paused") : Translation.tr("Ready")
    }
    function toggle(key: string): void {
        if (key === "focus") TimerService.togglePomodoro()
        else if (key === "stopwatch") TimerService.toggleStopwatch()
        else TimerService.toggleCountdown()
    }
    function reset(key: string): void {
        if (key === "focus") TimerService.resetPomodoro()
        else if (key === "stopwatch") TimerService.stopwatchReset()
        else TimerService.resetCountdown()
    }

    shelf: root.nothing ? root.signal : root.lead.tint
    tabGlyph: root.lead.glyph
    tabText: root.lead.label
    flapText: root.state(root.lead)
    lightPass: root.live(root.lead) ? 1 : 0.55

    component Key: Rectangle {
        id: key
        required property var timer
        radius: width / 2
        color: root.live(key.timer) ? (root.nothing ? root.signal : key.timer.tint) : keyHover.hovered ? root.fillHover : root.fill
        scale: keyTap.pressed ? 0.92 : 1
        Behavior on color { ColorAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
        Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
        MaterialSymbol {
            anchors.centerIn: parent
            text: root.live(key.timer) ? "pause" : "play_arrow"
            fill: 1
            iconSize: Math.round(key.width * 0.5)
            color: root.live(key.timer) ? root.onFill(key.color) : root.ink
        }
        HoverHandler { id: keyHover; cursorShape: Qt.PointingHandCursor }
        TapHandler {
            id: keyTap
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            gesturePolicy: TapHandler.WithinBounds
            onTapped: (point, button) => button === Qt.RightButton ? root.reset(key.timer.key) : root.toggle(key.timer.key)
        }
        WheelHandler {
            enabled: key.timer.key === "countdown" && !key.timer.running
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => TimerService.adjustCountdownDuration(event.angleDelta.y > 0 ? 60 : -60)
        }
        Accessible.role: Accessible.Button
        Accessible.name: key.timer.label + ", " + key.timer.value
    }

    // ── the pane: the time, and its key ──
    FaceFigure {
        id: leadTime
        face: root
        x: root.inset
        y: Math.round(root.paneMiddle - height / 2)
        width: Math.min(implicitWidth, root.innerWidth - leadKey.width - root.dp(12))
        text: root.lead.value
        size: root.type(34, 52, 72)
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: root.px(20)
    }
    Key {
        id: leadKey
        timer: root.lead
        width: root.pick(40, 52, 64)
        height: width
        x: root.width - root.inset - width
        y: Math.round(root.paneMiddle - height / 2)
    }

    // ── the foot: the other two ──
    Repeater {
        model: root.small ? root.others.slice(0, 1) : root.others
        Item {
            id: other
            required property var modelData
            required property int index
            readonly property real columnWidth: root.medium ? (root.innerWidth - root.dp(16)) / 2 : root.innerWidth
            x: Math.round(root.inset + (root.medium ? other.index * (other.columnWidth + root.dp(16)) : 0))
            y: Math.round(root.footTop + (root.small ? (root.footHeight - height) / 2 - root.dp(2)
                : root.medium ? (root.footHeight - height) / 2 - root.dp(2) : root.dp(26) + other.index * root.dp(66)))
            width: other.columnWidth
            height: root.pick(32, 36, 52)
            Key {
                id: otherKey
                timer: other.modelData
                width: other.height
                height: other.height
            }
            Column {
                anchors.left: otherKey.right
                anchors.leftMargin: root.dp(10)
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                FaceText {
                    face: root
                    width: parent.width
                    text: other.modelData.value
                    size: root.type(14, 16, 24)
                    weight: Font.Bold
                    font.family: root.fontNumbers
                    font.features: ({ "tnum": 1 })
                }
                FaceText {
                    face: root
                    width: parent.width
                    text: other.modelData.label + (root.large ? " · " + root.state(other.modelData) : "")
                    color: root.inkSecondary
                    size: root.type(11, 11.5, 13)
                    weight: Font.Medium
                }
            }
        }
    }
}
