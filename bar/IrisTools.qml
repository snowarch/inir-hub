pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

ColumnLayout {
    id: root
    readonly property real d: IrisStyle.density
    signal activityRequested()
    spacing: 12 * root.d

    // Working copy of the persisted minutes; written back once an adjustment ends.
    property var presets: {
        const saved = Persistent.states?.timer?.countdown?.presets ?? []
        return [0, 1, 2].map(i => Math.max(1, Math.min(180, Number(saved[i] ?? [5, 15, 30][i]))))
    }
    function adjustPreset(index: int, steps: int): void {
        const next = root.presets.slice()
        let value = next[index]
        for (let i = 0; i < Math.abs(steps); i++) {
            if (steps > 0) value = value < 10 ? value + 1 : value + 5 - value % 5
            else value = value <= 10 ? value - 1 : value - (value % 5 || 5)
        }
        next[index] = Math.max(1, Math.min(180, value))
        root.presets = next
    }
    function savePresets(): void {
        if (Persistent.states?.timer?.countdown) Persistent.states.timer.countdown.presets = root.presets.slice()
    }

    // One dial per way of keeping time: a round face whose orange arc is the
    // share of an hour it holds (5, 15, 30 min), Focus and Stopwatch as glyphs.
    // A running kind closes its ring and fills with the timer colour.
    component Dial: Item {
        id: dial
        property string figure: ""
        property string glyph: ""
        property string caption: ""
        property bool running: false
        // Share of the face the arc covers; 0 leaves only the track.
        property real share: 0
        // Presets take the wheel and a vertical drag to change their minutes.
        property bool adjustable: false
        signal clicked()
        signal adjusted(int steps)
        signal adjustFinished()
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: face.height + label.implicitHeight + 6 * root.d
        opacity: dial.enabled ? 1 : 0.45
        Accessible.role: Accessible.Button
        Accessible.name: dial.caption

        IrisButton {
            id: face
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.round(56 * root.d)
            height: width
            buttonRadius: width / 2
            buttonRadiusPressed: width / 2
            colBackground: dial.running ? ColorUtils.applyAlpha(IrisStyle.secondaryAccent, 0.2) : ColorUtils.applyAlpha(IrisStyle.text, 0.07)
            colBackgroundHover: dial.running ? ColorUtils.applyAlpha(IrisStyle.secondaryAccent, 0.28) : ColorUtils.applyAlpha(IrisStyle.text, 0.13)
            onClicked: dial.clicked()
            scale: presetPointer.pressed && !presetPointer.dragging ? 0.94 : 1
            Behavior on scale { NumberAnimation { duration: IrisStyle.duration(110); easing.type: Easing.OutCubic } }

            Shape {
                id: arc
                anchors.fill: parent
                anchors.margins: 3 * root.d
                preferredRendererType: Shape.CurveRenderer
                readonly property real stroke: Math.max(2, 2.5 * root.d)
                ShapePath {
                    strokeColor: ColorUtils.applyAlpha(IrisStyle.secondaryAccent, 0.18)
                    strokeWidth: arc.stroke
                    fillColor: "transparent"
                    PathAngleArc {
                        centerX: arc.width / 2; centerY: arc.height / 2
                        radiusX: arc.width / 2 - arc.stroke / 2; radiusY: radiusX
                        startAngle: 0; sweepAngle: 360
                    }
                }
                ShapePath {
                    strokeColor: IrisStyle.secondaryAccent
                    strokeWidth: arc.stroke
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: arc.width / 2; centerY: arc.height / 2
                        radiusX: arc.width / 2 - arc.stroke / 2; radiusY: radiusX
                        startAngle: -90
                        sweepAngle: 360 * (dial.running ? 1 : dial.share)
                    }
                }
            }
            IrisText {
                anchors.centerIn: parent
                visible: dial.figure.length > 0
                text: dial.figure
                color: IrisStyle.secondaryAccent
                font.family: IrisStyle.fontNumbers
                font.pixelSize: 19 * IrisStyle.typeScale
                font.weight: Font.Bold
                font.features: ({ "tnum": 1 })
            }
            MaterialSymbol {
                anchors.centerIn: parent
                visible: dial.glyph.length > 0
                text: dial.glyph
                fill: dial.running ? 1 : 0
                iconSize: 22 * root.d
                color: IrisStyle.secondaryAccent
            }
        }
        // Presets own the pointer: a press that stays put starts the timer,
        // a vertical drag (or the wheel) changes its minutes instead.
        MouseArea {
            id: presetPointer
            anchors.fill: face
            enabled: dial.adjustable && dial.enabled
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            property real anchorY: 0
            property bool dragging: false
            onPressed: mouse => { anchorY = mouse.y; dragging = false }
            onPositionChanged: mouse => {
                if (!pressed) return
                const step = 8 * root.d
                if (!dragging && Math.abs(anchorY - mouse.y) < step) return
                dragging = true
                const steps = Math.trunc((anchorY - mouse.y) / step)
                if (steps === 0) return
                anchorY -= steps * step
                dial.adjusted(steps)
            }
            onReleased: {
                if (dragging) dial.adjustFinished()
                else dial.clicked()
                dragging = false
            }
            onCanceled: { if (dragging) dial.adjustFinished(); dragging = false }
            property real wheelAccumulator: 0
            onWheel: wheel => {
                wheelAccumulator += wheel.angleDelta.y || wheel.pixelDelta.y * 4
                const steps = Math.trunc(wheelAccumulator / 120)
                if (steps === 0) return
                wheelAccumulator -= steps * 120
                dial.adjusted(steps)
                dial.adjustFinished()
            }
        }
        IrisText {
            id: label
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: dial.caption
            color: ColorUtils.applyAlpha(IrisStyle.text, 0.62)
            font.pixelSize: 11 * IrisStyle.typeScale
            font.weight: Font.Medium
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6 * root.d
        Repeater {
            model: 3
            Dial {
                id: preset
                required property int index
                readonly property int minutes: root.presets[preset.index] ?? 5
                figure: String(preset.minutes)
                caption: Translation.tr("min")
                share: Math.min(1, preset.minutes / 60)
                adjustable: true
                // A running countdown is never overwritten by a preset.
                enabled: !TimerService.countdownRunning
                onAdjusted: steps => root.adjustPreset(preset.index, steps)
                onAdjustFinished: root.savePresets()
                onClicked: {
                    TimerService.setCountdownDuration(preset.minutes * 60)
                    TimerService.toggleCountdown()
                    root.activityRequested()
                }
            }
        }
        Dial {
            glyph: "self_improvement"
            caption: Translation.tr("Focus")
            running: TimerService.pomodoroRunning
            onClicked: {
                if (!TimerService.pomodoroRunning) TimerService.togglePomodoro()
                root.activityRequested()
            }
        }
        Dial {
            glyph: "timer"
            caption: Translation.tr("Stopwatch")
            running: TimerService.stopwatchRunning
            onClicked: {
                if (!TimerService.stopwatchRunning) TimerService.toggleStopwatch()
                root.activityRequested()
            }
        }
    }
}
