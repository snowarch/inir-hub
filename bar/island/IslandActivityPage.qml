pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.mediaControls.components
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.frame
import qs.modules.iris.pieces

ColumnLayout {
    id: page
    required property Item island
    spacing: 12 * IrisStyle.density

    RowLayout {
        Layout.fillWidth: true
        visible: page.island.recording
        spacing: 12 * IrisStyle.density
        Item {
            Layout.preferredWidth: 40 * IrisStyle.density
            Layout.preferredHeight: 40 * IrisStyle.density
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: IrisStyle.tintFill(IrisStyle.danger)
            }
            RecordDot { anchors.centerIn: parent; width: 14 * IrisStyle.density; height: width }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            IrisText {
                text: Translation.tr("Screen recording")
                font.pixelSize: 14 * IrisStyle.typeScale
                font.weight: Font.DemiBold
            }
            IrisText {
                text: RecorderStatus.effectiveAudioMode === "none" ? Translation.tr("No audio")
                    : RecorderStatus.effectiveAudioMode === "microphone" ? Translation.tr("Microphone")
                    : RecorderStatus.effectiveAudioMode === "both" ? Translation.tr("System and microphone")
                    : Translation.tr("System audio")
                role: IrisText.Meta
            }
        }
        IrisNumber {
            text: page.island.clockText(RecorderStatus.elapsedSeconds)
            color: IrisStyle.danger
            pixelSize: 28 * IrisStyle.typeScale
            weight: Font.Bold
            letterSpacing: -0.6
        }
        GlyphButton {
            glyph: "stop"
            emphasized: true
            danger: true
            Accessible.name: Translation.tr("Stop recording")
            onClicked: {
                Quickshell.execDetached([Directories.recordScriptPath, "--stop"])
                RecorderStatus.scheduleQuickCheck()
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        visible: page.island.recording && page.island.timerKind.length > 0
        implicitHeight: 1
        color: IrisStyle.fill
    }

    RowLayout {
        Layout.fillWidth: true
        visible: page.island.timerKind.length > 0
        spacing: 12 * IrisStyle.density
        Item {
            Layout.preferredWidth: 40 * IrisStyle.density
            Layout.preferredHeight: 40 * IrisStyle.density
            ProgressRing {
                anchors.fill: parent
                visible: page.island.timerKind !== "stopwatch"
                tint: IrisStyle.secondaryAccent
                stroke: 3 * IrisStyle.density
                progress: page.island.timerProgress
            }
            Glyph {
                anchors.centerIn: parent
                text: page.island.timerGlyph
                iconSize: 18 * IrisStyle.density
                color: IrisStyle.secondaryAccent
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            IrisText {
                text: page.island.timerLabel
                font.pixelSize: 14 * IrisStyle.typeScale
                font.weight: Font.DemiBold
            }
            IrisText {
                text: page.island.timerPaused ? Translation.tr("Paused")
                    : page.island.timerKind === "pomodoro"
                        ? Translation.tr("Cycle %1 of %2").arg(TimerService.pomodoroCycle + 1).arg(TimerService.cyclesBeforeLongBreak)
                    : Translation.tr("Running")
                role: IrisText.Meta
            }
        }
        IrisNumber {
            text: page.island.clockText(page.island.timerSeconds)
            countDown: page.island.timerKind !== "stopwatch"
            color: page.island.timerPaused ? IrisStyle.subtext : IrisStyle.secondaryAccent
            pixelSize: 28 * IrisStyle.typeScale
            weight: Font.Bold
            letterSpacing: -0.6
        }
        GlyphButton {
            glyph: page.island.timerPaused ? "play_arrow" : "pause"
            colBackground: IrisStyle.tintFill(IrisStyle.secondaryAccent)
            colBackgroundHover: IrisStyle.tintFillHover(IrisStyle.secondaryAccent)
            glyphColor: IrisStyle.secondaryAccent
            Accessible.name: page.island.timerPaused ? Translation.tr("Resume") : Translation.tr("Pause")
            onClicked: {
                if (page.island.timerKind === "pomodoro") TimerService.togglePomodoro()
                else if (page.island.timerKind === "countdown") TimerService.toggleCountdown()
                else TimerService.toggleStopwatch()
            }
        }
        GlyphButton {
            glyph: "close"
            colBackground: IrisStyle.fill
            colBackgroundHover: IrisStyle.fillHover
            glyphSize: 18 * IrisStyle.density
            Accessible.name: Translation.tr("Stop timer")
            onClicked: {
                if (page.island.timerKind === "pomodoro") TimerService.stopPomodoro()
                else if (page.island.timerKind === "countdown") TimerService.stopCountdown()
                else TimerService.stopStopwatch()
            }
        }
    }
}
