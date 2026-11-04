pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.iris.components

// The expanded Live Activities (DESIGN.md S6): every running thing as one block, what it is in the Read voice, its
// one figure, its progress, its controls as capsules (secondary left, primary right, destructive in signal). Under
// them, who is using the mic, the camera or the screen.
ColumnLayout {
    id: page
    required property Item island
    readonly property real d: IrisStyle.density
    spacing: 0

    // Jobs that just ended stay a moment (LiveActivities.retireMs) so the page does not jump when one finishes.
    readonly property var jobs: LiveActivities.list.slice().sort((a, b) => b.started - a.started)
    readonly property bool timing: page.island.timerKind.length > 0
    readonly property bool privacy: Privacy.anyActive
    // Under Nothing: one signal, dots, Dot figures. Under Apple each block wears its colour and a capsule bar.
    readonly property bool nothing: page.island.nothingLook

    // Apple's live activity: round controls at the start (the main one in the activity's colour, close in grey), the
    // name small in its colour over its one big figure at the end; under it, how far it is.
    component Block: ColumnLayout {
        id: block
        property string title: ""
        property string meta: ""
        property string figure: ""
        property int roll: 0
        property bool live: false
        property bool failed: false
        property real progress: -1
        property bool indeterminate: false
        property bool first: false
        property bool ring: false
        property bool hasExtra: false
        property string glyph: ""
        property color tint: IrisStyle.accent
        readonly property color ink: block.failed ? IrisStyle.danger : page.nothing ? IrisStyle.text : block.tint
        default property alias controls: chips.data
        property alias lead: leadRow.data
        property alias extra: extraColumn.data
        Layout.fillWidth: true
        spacing: Math.round(10 * page.d)

        Rectangle {
            visible: !block.first
            Layout.fillWidth: true
            Layout.topMargin: Math.round(4 * page.d)
            Layout.bottomMargin: Math.round(4 * page.d)
            implicitHeight: 1
            color: IrisStyle.hairline
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(12 * page.d)
            RowLayout {
                id: leadRow
                visible: children.length > 0
                Layout.alignment: Qt.AlignVCenter
                spacing: Math.round(10 * page.d)
            }
            Rectangle {
                visible: block.glyph.length > 0
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: Math.round(40 * page.d)
                implicitHeight: implicitWidth
                radius: width / 2
                color: page.nothing ? IrisStyle.fill : IrisStyle.tintFill(block.ink)
                Glyph {
                    anchors.centerIn: parent
                    text: block.glyph
                    iconSize: Math.round(20 * page.d)
                    color: block.ink
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Math.round(1 * page.d)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(7 * page.d)
                    Rectangle {
                        visible: block.live
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: Math.round(7 * page.d)
                        implicitHeight: implicitWidth
                        radius: width / 2
                        color: page.nothing ? IrisStyle.signal : block.tint
                        SequentialAnimation on opacity {
                            running: block.live && block.visible && IrisStyle.motionEnabled
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
                        }
                    }
                    IrisText {
                        Layout.fillWidth: true
                        text: block.title
                        color: block.failed ? IrisStyle.signalInk : page.nothing ? IrisStyle.text : block.ink
                        font.pixelSize: IrisStyle.typeLabel
                        font.weight: IrisStyle.weight(Font.DemiBold)
                        elide: Text.ElideRight
                    }
                }
                IrisText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: block.meta
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeBody
                    elide: Text.ElideRight
                }
            }
            IrisDotText {
                visible: page.nothing && block.figure.length > 0
                Layout.alignment: Qt.AlignVCenter
                text: block.figure
                direction: block.roll
                pixelSize: IrisStyle.typeDotM
                color: block.ink
            }
            IrisNumber {
                visible: !page.nothing && !block.ring && block.figure.length > 0
                Layout.alignment: Qt.AlignVCenter
                text: block.figure
                countDown: block.roll < 0
                color: block.ink
                pixelSize: Math.round(IrisStyle.typeHero * 0.92)
                weight: IrisStyle.figureWeight
            }
            // A job's share as a ring with its figure inside (a price alert, a transfer).
            Item {
                visible: !page.nothing && block.ring
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: Math.round(52 * page.d)
                implicitHeight: implicitWidth
                ProgressRing {
                    anchors.fill: parent
                    stroke: Math.max(3, 4.5 * page.d)
                    tint: block.ink
                    progress: Math.max(0, block.progress)
                    Behavior on progress { NumberAnimation { duration: IrisStyle.duration(320); easing.type: Easing.OutCubic } }
                    RotationAnimation on rotation {
                        running: block.indeterminate && block.visible && IrisStyle.motionEnabled
                        from: 0; to: 360; duration: 1200; loops: Animation.Infinite
                    }
                }
                Tabular {
                    anchors.centerIn: parent
                    text: block.figure
                    color: IrisStyle.text
                    font.pixelSize: block.figure.length > 4 ? IrisStyle.typeFootnote : IrisStyle.typeMeta
                    font.weight: IrisStyle.weight(Font.DemiBold)
                }
            }
        }
        ColumnLayout {
            id: extraColumn
            visible: block.hasExtra
            Layout.fillWidth: true
            spacing: Math.round(8 * page.d)
        }
        Rectangle {
            id: bar
            visible: !page.nothing && !block.ring && (block.progress >= 0 || block.indeterminate)
            Layout.fillWidth: true
            implicitHeight: Math.round(6 * page.d)
            radius: IrisStyle.capsule(height)
            color: IrisStyle.tintFill(block.ink)
            clip: block.indeterminate
            Rectangle {
                height: parent.height
                radius: parent.radius
                color: block.ink
                width: block.indeterminate ? parent.width * 0.3 : parent.width * Math.max(0, Math.min(1, block.progress))
                Behavior on width { enabled: !block.indeterminate; NumberAnimation { duration: IrisStyle.duration(240); easing.type: Easing.OutCubic } }
                // A job that can't say how far it is: a short capsule travels the track.
                NumberAnimation on x {
                    running: bar.visible && block.indeterminate && IrisStyle.motionEnabled
                    from: -bar.width * 0.3
                    to: bar.width
                    duration: 1400
                    loops: Animation.Infinite
                }
            }
        }
        IrisDotStrip {
            visible: page.nothing && (block.progress >= 0 || block.indeterminate)
            Layout.fillWidth: true
            value: Math.max(0, block.progress)
            indeterminate: block.indeterminate
            fillColor: block.failed ? IrisStyle.signal : IrisStyle.text
        }
        RowLayout {
            id: chips
            visible: children.length > 0
            Layout.fillWidth: true
            spacing: Math.round(8 * page.d)
        }
    }
    // A round control: the main one tinted in its activity's colour, the others grey (Apple's pause and close).
    component Round: MouseArea {
        id: round
        property string glyph: ""
        property color tint: IrisStyle.text
        property bool main: false
        implicitWidth: Math.round(44 * page.d)
        implicitHeight: implicitWidth
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        scale: round.pressed ? IrisStyle.pressScale(0.9) : 1
        Behavior on scale { NumberAnimation { duration: IrisStyle.duration(round.pressed ? 80 : 200); easing.type: IrisStyle.feedbackEasing } }
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: round.main && !page.nothing ? (round.containsMouse ? IrisStyle.trackOf(round.tint) : IrisStyle.tintFillHover(round.tint))
                : round.containsMouse ? IrisStyle.fillActive : IrisStyle.fillHover
            Behavior on color { ColorAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
        }
        Glyph {
            anchors.centerIn: parent
            text: round.glyph
            iconSize: Math.round(22 * page.d)
            color: round.main && !page.nothing ? round.tint : IrisStyle.text
        }
    }
    component Gap: Item { Layout.fillWidth: true }
    component Use: RowLayout {
        id: use
        property bool active: false
        property bool alarm: true
        property color tint: IrisStyle.text
        property string what: ""
        property string who: ""
        default property alias controls: useControls.data
        visible: use.active
        Layout.fillWidth: true
        spacing: Math.round(10 * page.d)
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: Math.round(7 * page.d)
            implicitHeight: implicitWidth
            radius: width / 2
            color: page.nothing ? (use.alarm ? IrisStyle.signal : IrisStyle.text) : use.tint
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(2 * page.d)
            IrisText {
                Layout.fillWidth: true
                text: use.what
                font.pixelSize: IrisStyle.typeBody
                font.weight: IrisStyle.weight(Font.Medium)
                elide: Text.ElideRight
            }
            IrisText {
                Layout.fillWidth: true
                text: use.who.length > 0 ? use.who : Translation.tr("An app")
                role: IrisText.Meta
                elide: Text.ElideRight
            }
        }
        RowLayout { id: useControls; spacing: Math.round(8 * page.d) }
    }


    Block {
        visible: page.island.recording
        first: true
        live: true
        tint: IrisStyle.danger
        title: Translation.tr("Screen recording")
        meta: RecorderStatus.effectiveAudioMode === "none" ? Translation.tr("No audio")
            : RecorderStatus.effectiveAudioMode === "microphone" ? Translation.tr("Microphone")
            : RecorderStatus.effectiveAudioMode === "both" ? Translation.tr("System and microphone")
            : Translation.tr("System audio")
        figure: page.island.clockText(RecorderStatus.elapsedSeconds)
        roll: 1
        lead: Round {
            main: true
            tint: IrisStyle.danger
            glyph: "stop"
            Accessible.name: Translation.tr("Stop")
            onClicked: {
                Quickshell.execDetached([Directories.recordScriptPath, "--stop"])
                RecorderStatus.scheduleQuickCheck()
            }
        }
    }

    Block {
        id: timerBlock
        readonly property bool pomodoro: page.island.timerKind === "pomodoro"
        readonly property int cycles: Math.max(1, Number(TimerService.cyclesBeforeLongBreak) || 4)
        readonly property int cycle: Math.max(0, Number(TimerService.pomodoroCycle) || 0) % timerBlock.cycles
        visible: page.timing
        first: !page.island.recording
        live: !page.island.timerPaused
        tint: IrisStyle.identity.orange
        title: page.island.timerLabel
        meta: page.island.timerPaused ? Translation.tr("Paused")
            : timerBlock.pomodoro
                ? Translation.tr("Cycle %1 of %2").arg(timerBlock.cycle + 1).arg(timerBlock.cycles)
            : Translation.tr("Running")
        figure: page.island.clockText(page.island.timerSeconds)
        roll: page.island.timerKind === "stopwatch" ? 1 : -1
        progress: page.island.timerKind === "stopwatch" || timerBlock.pomodoro ? -1 : page.island.timerProgress
        lead: [
            Round {
                main: true
                tint: IrisStyle.identity.orange
                glyph: page.island.timerPaused ? "play_arrow" : "pause"
                Accessible.name: page.island.timerPaused ? Translation.tr("Resume") : Translation.tr("Pause")
                onClicked: {
                    if (page.island.timerKind === "pomodoro") TimerService.togglePomodoro()
                    else if (page.island.timerKind === "countdown") TimerService.toggleCountdown()
                    else TimerService.toggleStopwatch()
                }
            },
            Round {
                glyph: "close"
                Accessible.name: Translation.tr("Stop")
                onClicked: {
                    if (page.island.timerKind === "pomodoro") TimerService.stopPomodoro()
                    else if (page.island.timerKind === "countdown") TimerService.stopCountdown()
                    else TimerService.stopStopwatch()
                }
            }
        ]
        // A pomodoro as its stages, the way a washer shows its cycle: each focus and break a segment, the one
        // running fills with the time spent in it.
        hasExtra: timerBlock.pomodoro && !page.nothing
        extra: RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(4 * page.d)
            Repeater {
                model: timerBlock.cycles * 2
                Rectangle {
                    id: stage
                    required property int index
                    readonly property bool rest: stage.index % 2 === 1
                    readonly property int step: Math.floor(stage.index / 2)
                    readonly property int here: timerBlock.cycle * 2 + (TimerService.pomodoroBreak ? 1 : 0)
                    readonly property real fill: stage.index < stage.here ? 1 : stage.index === stage.here ? page.island.timerProgress : 0
                    Layout.fillWidth: true
                    Layout.preferredWidth: stage.rest ? 1 : 3
                    implicitHeight: Math.round(10 * page.d)
                    radius: IrisStyle.capsule(height)
                    color: IrisStyle.tintFill(stage.rest ? IrisStyle.identity.teal : IrisStyle.identity.orange)
                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        width: Math.max(stage.fill > 0 ? height : 0, parent.width * Math.max(0, Math.min(1, stage.fill)))
                        color: stage.rest ? IrisStyle.identity.teal : IrisStyle.identity.orange
                        Behavior on width { NumberAnimation { duration: IrisStyle.duration(400); easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }

    Repeater {
        model: page.jobs
        Block {
            id: job
            required property var modelData
            required property int index
            readonly property real value: Number(job.modelData.progress ?? -1)
            readonly property bool ended: Boolean(job.modelData.ended)
            readonly property var actions: Array.from(job.modelData.actions ?? [])
            readonly property string app: String(job.modelData.app ?? "")
            first: job.index === 0 && !page.island.recording && !page.timing
            glyph: String(job.modelData.glyph ?? "bolt")
            ring: job.value >= 0 || (!job.ended && job.value < 0)
            failed: Boolean(job.modelData.failed)
            tint: IrisStyle.identityColor(String(job.modelData.tint ?? "lavender"))
            title: String(job.modelData.title ?? "")
            meta: [job.app !== job.title ? job.app : "", String(job.modelData.detail ?? "")]
                .filter(part => part.length > 0).join(" · ")
            figure: job.ended ? (job.failed ? "" : "100%") : job.value >= 0 ? page.island.percentOf(job.modelData) + (page.nothing ? "" : "%")
                : page.island.elapsedOf(job.modelData)
            roll: 1
            progress: job.ended ? (job.failed ? job.value : 1) : job.value
            indeterminate: !job.ended && job.value < 0
            // The app's own buttons (Stop, Show in folder): stopping ones in signal on the left, the rest on the right,
            // the last of them primary.
            Repeater {
                model: job.ended ? [] : job.actions.filter(action => /^(cancel|stop|abort)$/i.test(action.id))
                IrisButton {
                    required property var modelData
                    text: modelData.text.length > 0 ? modelData.text : Translation.tr("Stop")
                    danger: true
                    onClicked: Notifications.attemptInvokeAction(job.modelData.notificationId, modelData.id)
                }
            }
            IrisButton {
                text: job.ended ? Translation.tr("Dismiss") : Translation.tr("Hide")
                onClicked: LiveActivities.dismiss(String(job.modelData.id))
            }
            Gap {}
            Repeater {
                id: others
                model: job.ended ? [] : job.actions.filter(action => !/^(cancel|stop|abort)$/i.test(action.id))
                IrisButton {
                    required property var modelData
                    required property int index
                    text: modelData.text
                    emphasized: index === others.count - 1
                    onClicked: Notifications.attemptInvokeAction(job.modelData.notificationId, modelData.id)
                }
            }
        }
    }

    // Who is listening or watching. Mic and camera are the signal; the screen is ink, as in the compact marks.
    ColumnLayout {
        visible: page.privacy
        Layout.fillWidth: true
        spacing: Math.round(10 * page.d)
        Rectangle {
            visible: page.island.recording || page.timing || page.jobs.length > 0
            Layout.fillWidth: true
            Layout.topMargin: Math.round(4 * page.d)
            Layout.bottomMargin: Math.round(4 * page.d)
            implicitHeight: 1
            color: IrisStyle.hairline
        }
        IrisLabel { text: Translation.tr("In use") }

        Use {
            active: Privacy.micActive
            tint: IrisStyle.identity.orange
            what: Translation.tr("Microphone")
            who: Privacy.micApps.join(", ")
            IrisButton {
                text: Audio.micMuted ? Translation.tr("Unmute") : Translation.tr("Mute")
                selected: Audio.micMuted
                onClicked: Audio.toggleMicMute()
            }
        }
        Use {
            active: Privacy.cameraActive
            tint: IrisStyle.identity.green
            what: Translation.tr("Camera")
            who: Privacy.cameraApps.join(", ")
        }
        Repeater {
            model: Privacy.casts
            Use {
                id: cast
                required property var modelData
                active: true
                alarm: false
                what: Translation.tr("Screen")
                who: [Privacy.castViewer(cast.modelData), Privacy.castTarget(cast.modelData)]
                    .filter(part => part.length > 0).join(" · ")
                IrisButton {
                    // niri can only stop PipeWire casts; a screencopy one is stopped by the app that runs it.
                    visible: cast.modelData.kind === "PipeWire"
                    text: Translation.tr("Stop")
                    danger: true
                    onClicked: NiriService.stopCast(cast.modelData.session_id)
                }
            }
        }
    }
}
