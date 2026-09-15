pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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

    // One dial per way of keeping time. Presets carry the timer's orange as a
    // figure; Focus and Stopwatch are glyphs. A running kind wears a ring.
    component Dial: IrisButton {
        id: dial
        property string figure: ""
        property string glyph: ""
        property string caption: ""
        property bool running: false
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: Math.round(62 * root.d)
        buttonRadius: Math.round(16 * root.d)
        buttonRadiusPressed: Math.round(14 * root.d)
        colBackground: ColorUtils.applyAlpha(IrisStyle.secondaryAccent, dial.running ? 0.22 : 0.1)
        colBackgroundHover: ColorUtils.applyAlpha(IrisStyle.secondaryAccent, dial.running ? 0.3 : 0.18)
        Accessible.name: dial.caption
        Rectangle {
            anchors.fill: parent
            radius: dial.buttonRadius
            color: "transparent"
            border.width: dial.running ? Math.max(1, Math.round(1.5 * root.d)) : 0
            border.color: ColorUtils.applyAlpha(IrisStyle.secondaryAccent, 0.7)
        }
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0
            IrisText {
                Layout.alignment: Qt.AlignHCenter
                visible: dial.figure.length > 0
                text: dial.figure
                color: dial.enabled ? IrisStyle.secondaryAccent : ColorUtils.applyAlpha(IrisStyle.secondaryAccent, 0.4)
                font.family: IrisStyle.fontNumbers
                font.pixelSize: 22 * IrisStyle.typeScale
                font.weight: Font.Bold
                font.features: ({ "tnum": 1 })
            }
            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                visible: dial.glyph.length > 0
                text: dial.glyph
                fill: dial.running ? 1 : 0
                iconSize: 22 * root.d
                color: IrisStyle.secondaryAccent
            }
            IrisText {
                Layout.alignment: Qt.AlignHCenter
                text: dial.caption
                color: ColorUtils.applyAlpha(IrisStyle.text, dial.enabled ? 0.62 : 0.3)
                font.pixelSize: 10.5 * IrisStyle.typeScale
                font.weight: Font.Medium
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6 * root.d
        Repeater {
            model: [5, 15, 30]
            Dial {
                required property int modelData
                figure: String(modelData)
                caption: Translation.tr("min")
                // A running countdown is never overwritten by a preset.
                enabled: !TimerService.countdownRunning
                onClicked: {
                    TimerService.setCountdownDuration(modelData * 60)
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
