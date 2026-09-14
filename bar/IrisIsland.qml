pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.mediaControls.components
import qs.modules.iris.style
import qs.modules.iris.components

// The signature iRiS surface. One black chassis owns the silhouette; live
// activities (screen recording, timers, media) take turns inside it, and a
// second concurrent activity detaches as a minimal satellite that slides out
// from behind the chassis and merges back when the Island expands.
Item {
    id: root

    property var targetScreen
    property real availableWidth: 800
    property real compactHeight: 42
    property bool expanded: false
    property bool pinned: false
    // Expanded page requested by the gesture that opened the Island; empty
    // means "the page of the primary activity".
    property string page: ""

    readonly property real d: IrisStyle.density
    readonly property var options: Config.options?.iris?.bar ?? ({})
    readonly property bool notch: root.options?.notch ?? false
    readonly property bool bottomEdge: String(root.options?.position ?? "top") === "bottom"

    // ── Activities ────────────────────────────────────────────────────────
    readonly property var player: MprisController.activePlayer
    readonly property bool hasMedia: root.player !== null && root.player !== undefined
        && String(root.player.trackTitle ?? "").length > 0
    readonly property bool ytMusic: root.hasMedia && MprisController._isYtMusicMpv(root.player)
    readonly property string title: root.ytMusic ? YtMusic.currentTitle : String(root.player?.trackTitle ?? "")
    readonly property bool playing: root.hasMedia && (root.ytMusic ? YtMusic.isPlaying : (root.player?.isPlaying ?? false))
    // Same effective-progress ownership as the shared media widgets: YT Music
    // streams report real position/duration through YtMusic, not MPRIS.
    readonly property real effectivePosition: root.ytMusic ? YtMusic.currentPosition : (root.player?.position ?? 0)
    readonly property real effectiveLength: root.ytMusic ? YtMusic.currentDuration : (root.player?.length ?? 0)
    readonly property real trackProgress: root.effectiveLength > 0
        ? Math.max(0, Math.min(1, root.effectivePosition / root.effectiveLength)) : 0

    readonly property bool recording: RecorderStatus.isRecording
    readonly property string timerKind: TimerService.pomodoroRunning ? "pomodoro"
        : TimerService.countdownRunning ? "countdown"
        : TimerService.stopwatchRunning ? "stopwatch" : ""
    readonly property bool timerPaused: root.timerKind === "pomodoro" ? TimerService.pomodoroPaused
        : root.timerKind === "countdown" ? TimerService.countdownPaused
        : TimerService.stopwatchPaused
    readonly property int timerSeconds: root.timerKind === "pomodoro" ? TimerService.pomodoroSecondsLeft
        : root.timerKind === "countdown" ? TimerService.countdownSecondsLeft
        : Math.floor(TimerService.stopwatchTime / 100)
    readonly property real timerProgress: root.timerKind === "pomodoro"
        ? 1 - TimerService.pomodoroSecondsLeft / Math.max(1, TimerService.pomodoroLapDuration)
        : root.timerKind === "countdown"
            ? 1 - TimerService.countdownSecondsLeft / Math.max(1, TimerService.countdownDuration) : 0
    readonly property string timerLabel: root.timerKind === "pomodoro"
        ? (TimerService.pomodoroLongBreak ? Translation.tr("Long break")
            : TimerService.pomodoroBreak ? Translation.tr("Break") : Translation.tr("Focus"))
        : root.timerKind === "countdown" ? Translation.tr("Timer") : Translation.tr("Stopwatch")
    readonly property string timerGlyph: root.timerKind === "pomodoro" && TimerService.pomodoroBreak ? "coffee"
        : root.timerKind === "stopwatch" ? "timer" : "hourglass_top"

    readonly property var activities: {
        const list = []
        if (root.recording) list.push("record")
        if (root.timerKind.length > 0) list.push("timer")
        if (root.hasMedia) list.push("media")
        return list
    }
    readonly property string primary: root.activities[0] ?? "idle"
    readonly property string secondary: root.activities[1] ?? ""
    readonly property bool hasSystemActivity: root.recording || root.timerKind.length > 0

    function pageFor(kind: string): string {
        return kind === "media" ? "media" : kind === "idle" || kind === "" ? "desktop" : "activity"
    }
    readonly property string effectivePage: {
        const requested = root.page.length > 0 ? root.page : root.pageFor(root.primary)
        if (requested === "media" && !root.hasMedia) return root.pageFor(root.primary)
        if (requested === "activity" && !root.hasSystemActivity) return root.pageFor(root.primary)
        return requested
    }

    function openPage(nextPage: string, pin: bool): void {
        root.page = nextPage
        if (pin) root.pinned = true
        root.expanded = true
    }

    // Screen-local y of the bar window's top edge (bottom bars sit low).
    property real screenOffsetY: 0
    // Hand the exact visible shape of the part that opened a surface to that
    // surface, so it can grow out of it. Only the focused output publishes.
    function publishOrigin(part): void {
        if (root.targetScreen?.name !== GlobalStates.focusedScreen?.name) return
        if (root.suppressed || !part?.visible) { GlobalStates.irisMorphOrigin = null; return }
        root.handoffPart = part
        const isChassis = part === chassis
        const top = part.mapToItem(null, 0, isChassis ? chassis.topInset : 0)
        const height = isChassis ? chassis.bodyHeight : part.height
        GlobalStates.irisMorphOrigin = {
            x: top.x, y: top.y + root.screenOffsetY,
            width: part.width * part.scale, height: height,
            radius: isChassis ? chassis.radius : part.width / 2,
            screen: root.targetScreen?.name ?? ""
        }
    }

    // The part a morphing surface grew out of; hidden while that morph flies.
    property Item handoffPart: null
    property bool controlsFromSatellite: false
    readonly property bool handingOff: GlobalStates.irisMorphHandoff
        && root.targetScreen?.name === GlobalStates.focusedScreen?.name

    function clockText(total: real): string {
        const s = Math.max(0, Math.floor(total))
        const h = Math.floor(s / 3600)
        const m = Math.floor((s % 3600) / 60)
        const sec = s % 60
        const pad = n => n < 10 ? "0" + n : String(n)
        return h > 0 ? h + ":" + pad(m) + ":" + pad(sec) : m + ":" + pad(sec)
    }

    // ── Feedback (volume / brightness / microphone HUD) ─────────────────
    property string feedbackKind: "volume"
    readonly property bool feedback: feedbackTimer.running && !root.expanded
    readonly property var brightnessMonitor: Brightness.getMonitorForScreen(root.targetScreen)
    readonly property real feedbackValue: root.feedbackKind === "brightness"
        ? (root.brightnessMonitor?.brightness ?? 0)
        : root.feedbackKind === "mic" ? (Audio.micVolume ?? 0) : (Audio.value ?? 0)
    readonly property bool feedbackMuted: root.feedbackKind === "mic" ? Audio.micMuted
        : root.feedbackKind === "volume" ? (Audio.sink?.audio?.muted ?? false) : false
    readonly property string feedbackIcon: root.feedbackKind === "brightness" ? "light_mode"
        : root.feedbackKind === "mic" ? (Audio.micMuted ? "mic_off" : "mic")
        : root.feedbackMuted ? "volume_off"
        : root.feedbackValue < 0.34 ? "volume_mute"
        : root.feedbackValue < 0.67 ? "volume_down" : "volume_up"

    function showFeedback(kind: string): void {
        if (!(Config.options?.iris?.modules?.osd ?? true) || root.expanded
            || root.targetScreen?.name !== GlobalStates.focusedScreen?.name) return
        root.feedbackKind = kind
        feedbackTimer.restart()
    }

    // ── Artwork tint ─────────────────────────────────────────────────────
    // Live-activity accents follow the artwork like the system waveform does;
    // greyscale covers fall back to plain text colour instead of inventing hue.
    ColorQuantizer {
        id: tintQuantizer
        source: root.hasMedia ? MediaArtwork.displaySource : ""
        depth: 2
        rescaleSize: 48
    }
    readonly property color artTint: {
        const colors = tintQuantizer.colors ?? []
        let best = null
        let bestScore = -1
        for (let i = 0; i < colors.length; i++) {
            const c = colors[i]
            const score = Math.max(0, c.hslSaturation) * (1 - Math.abs(c.hslLightness - 0.5))
            if (score > bestScore) { bestScore = score; best = c }
        }
        if (!best || best.hslSaturation < 0.14 || best.hslHue < 0) return IrisStyle.text
        return Qt.hsla(best.hslHue, Math.max(0.5, best.hslSaturation),
            Math.max(0.64, Math.min(0.76, best.hslLightness + 0.22)), 1)
    }

    // ── Geometry ─────────────────────────────────────────────────────────
    readonly property bool visualExpanded: root.expanded && details.status === Loader.Ready
    readonly property real bubble: root.compactHeight
    readonly property real satelliteGap: Math.round(6 * root.d)
    readonly property real fillet: root.notch ? Math.round(12 * root.d) : 0
    readonly property real expandedWidth: Math.min(root.availableWidth - 2 * (root.bubble + root.satelliteGap),
        (root.effectivePage === "activity" ? 384 : 440) * root.d)
    readonly property real padding: Math.round(20 * root.d)
    readonly property string compactMode: root.feedback ? "feedback"
        : IrisStyle.cluster ? "clock" : root.primary
    readonly property real chassisTargetWidth: root.visualExpanded ? root.expandedWidth
        : Math.min(root.availableWidth, (root.compactMode === "feedback" ? 280
            : root.compactMode === "clock" ? 96
            : root.compactMode === "media" ? 320
            : root.compactMode === "idle" ? 180 : 236) * root.d)
    readonly property bool leftSatelliteShown: IrisStyle.cluster && !root.visualExpanded && !root.feedback
        && root.primary !== "idle"
    readonly property bool rightSatelliteShown: !root.visualExpanded && !root.feedback
        && (IrisStyle.cluster || root.secondary.length > 0)

    property real sideReserve: root.leftSatelliteShown || root.rightSatelliteShown
        ? root.bubble + root.satelliteGap : root.fillet
    Behavior on sideReserve { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.OutCubic } }

    implicitWidth: chassis.width + 2 * Math.max(root.sideReserve, root.fillet)
    implicitHeight: chassis.bodyHeight

    Accessible.role: Accessible.Grouping
    Accessible.name: Translation.tr("Dynamic Island")

    // ── Behaviour ────────────────────────────────────────────────────────
    // Intent, not contact: the Island only opens once the pointer settles on a
    // real part of it (chassis or satellite). Sweeping across the screen edge
    // keeps restarting the dwell, and panels are never opened by hover alone.
    readonly property bool pointerOnIsland: chassisHover.hovered || leftSatellite.hovered || rightSatellite.hovered
    property point dwellAnchor: Qt.point(-1000, -1000)

    // Fullscreen windows own the output: the resting Island steps aside and
    // only transient feedback or an explicitly opened Island is presented.
    readonly property bool fullscreenCovered: CompositorService.isNiri
        && GameMode.hasFullscreenOnOutput(root.targetScreen?.name ?? "")
        && !NiriService.inOverview
    readonly property bool suppressed: root.fullscreenCovered && !feedbackTimer.running && !root.expanded
    opacity: root.suppressed || (root.handingOff && root.handoffPart === chassis) ? 0 : 1
    visible: opacity > 0.01
    // Hand-off hides on the same frame and returns with a short fade.
    Behavior on opacity {
        enabled: !root.handingOff
        NumberAnimation { duration: IrisStyle.duration(160); easing.type: Easing.OutCubic }
    }

    function trackDwell(position: point): void {
        // Scrolling reshapes the Island under a still pointer (HUD, satellites
        // merging); that must never read as intent to expand.
        if (root.feedback || wheelQuiet.running) { hoverDelay.stop(); return }
        if (Math.abs(position.x - root.dwellAnchor.x) + Math.abs(position.y - root.dwellAnchor.y) < 6) return
        root.dwellAnchor = position
        if ((root.options?.hoverExpand ?? true) && !root.expanded && root.pointerOnIsland) hoverDelay.restart()
    }

    onPointerOnIslandChanged: {
        if (root.pointerOnIsland) {
            leaveDelay.stop()
        } else {
            hoverDelay.stop()
            root.dwellAnchor = Qt.point(-1000, -1000)
            if (root.expanded && !root.pinned) leaveDelay.restart()
        }
    }
    Timer {
        id: hoverDelay
        interval: Math.max(60, Number(root.options?.hoverDelay ?? 160))
        onTriggered: {
            if (!root.pointerOnIsland || root.expanded || root.feedback || wheelQuiet.running) return
            if (rightSatellite.hovered && IrisStyle.cluster) return
            if (rightSatellite.hovered) root.openPage(root.pageFor(root.secondary), false)
            else if (leftSatellite.hovered) root.openPage(root.pageFor(root.primary), false)
            else root.openPage(IrisStyle.cluster ? "desktop" : root.pageFor(root.primary), false)
        }
    }
    Timer { id: wheelQuiet; interval: 900 }
    Timer { id: leaveDelay; interval: 320; onTriggered: { if (!root.pointerOnIsland && !root.pinned) root.expanded = false } }

    Binding {
        target: GlobalStates
        property: "irisControlsWarm"
        value: root.pointerOnIsland || root.expanded
        when: root.targetScreen?.name === GlobalStates.focusedScreen?.name
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: GlobalStates
        property: "irisSettingsWarm"
        value: root.expanded
        when: root.targetScreen?.name === GlobalStates.focusedScreen?.name
        restoreMode: Binding.RestoreNone
    }

    // Scroll over the resting Island adjusts volume (or brightness); Shift
    // swaps the two. Touchpad pixel deltas accumulate into the same steps.
    property real wheelAccumulator: 0
    function applyWheel(event): void {
        const action = String(root.options?.scrollAction ?? "volume")
        if (action === "none") return
        hoverDelay.stop()
        wheelQuiet.restart()
        const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y * 4
        root.wheelAccumulator += delta
        const steps = Math.trunc(root.wheelAccumulator / 120)
        if (steps === 0) return
        root.wheelAccumulator -= steps * 120
        const brightness = (action === "brightness") !== Boolean(event.modifiers & Qt.ShiftModifier)
        if (brightness) {
            if (root.brightnessMonitor)
                root.brightnessMonitor.setBrightness(Math.max(0, Math.min(1, root.brightnessMonitor.brightness + steps * 0.05)))
        } else {
            Audio.setSinkVolume(Math.max(0, Math.min(1, (Audio.value ?? 0) + steps * 0.05)))
        }
    }

    onExpandedChanged: {
        if (!root.expanded) root.pinned = false
    }

    Timer {
        id: feedbackTimer
        interval: 1800
        onTriggered: {
            GlobalStates.osdVolumeOpen = false
            GlobalStates.osdBrightnessOpen = false
            GlobalStates.osdMicOpen = false
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.playing && !root.ytMusic
        onTriggered: root.player?.positionChanged()
    }
    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged(): void { root.showFeedback("volume") }
        function onMutedChanged(): void { root.showFeedback("volume") }
    }
    Connections {
        target: Audio
        function onMicVolumeChanged(): void { root.showFeedback("mic") }
        function onMicMutedChanged(): void { root.showFeedback("mic") }
    }
    Connections {
        target: Brightness
        function onBrightnessChanged(): void { root.showFeedback("brightness") }
    }
    Connections {
        target: Notifications
        function onPopupListChanged(): void {
            if ((Notifications.popupList?.length ?? 0) > 0 && !root.pinned) root.expanded = false
        }
    }
    Connections {
        target: GlobalStates
        function onOsdVolumeOpenChanged(): void { if (GlobalStates.osdVolumeOpen) root.showFeedback("volume") }
        function onOsdBrightnessOpenChanged(): void { if (GlobalStates.osdBrightnessOpen) root.showFeedback("brightness") }
        function onOsdMicOpenChanged(): void { if (GlobalStates.osdMicOpen) root.showFeedback("mic") }
        function onSearchOpenChanged(): void {
            root.publishOrigin(chassis)
            if (GlobalStates.searchOpen) root.expanded = false
        }
        // Opening and closing both publish: the surface grows out of the shape
        // that opened it and collapses into whatever the Island looks like now.
        function onControlPanelOpenChanged(): void {
            // Close into the same part that opened it (satellite or chassis).
            if (GlobalStates.controlPanelOpen)
                root.controlsFromSatellite = IrisStyle.cluster && rightSatellite.shown
            root.publishOrigin(root.controlsFromSatellite && rightSatellite.shown ? rightSatellite : chassis)
            if (GlobalStates.controlPanelOpen) root.expanded = false
        }
        function onSettingsOverlayOpenChanged(): void {
            root.publishOrigin(chassis)
            if (GlobalStates.settingsOverlayOpen) root.expanded = false
        }
    }

    // ── Inline parts ─────────────────────────────────────────────────────
    component Tabular: IrisText {
        font.features: ({ "tnum": 1 })
    }

    component Glyph: MaterialSymbol {
        fill: 1
        color: IrisStyle.text
    }

    component GlyphButton: IrisButton {
        id: glyphButton
        property string glyph: ""
        property real glyphSize: 22 * root.d
        property color glyphColor: glyphButton.emphasized && glyphButton.danger ? IrisStyle.onDanger : IrisStyle.text
        quiet: !glyphButton.emphasized
        implicitWidth: Math.round(38 * root.d)
        implicitHeight: implicitWidth
        buttonRadius: height / 2
        buttonRadiusPressed: height / 2
        Glyph {
            anchors.centerIn: parent
            text: glyphButton.glyph
            iconSize: glyphButton.glyphSize
            color: glyphButton.enabled ? glyphButton.glyphColor : IrisStyle.muted
        }
    }

    component RecordDot: Rectangle {
        id: dot
        implicitWidth: 9 * root.d
        implicitHeight: implicitWidth
        radius: width / 2
        color: IrisStyle.danger
        SequentialAnimation on opacity {
            running: dot.visible && IrisStyle.motionEnabled
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
            onRunningChanged: if (!running) dot.opacity = 1
        }
    }

    component ProgressRing: Shape {
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
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.width / 2 - ring.stroke / 2
                radiusY: radiusX
                startAngle: 0
                sweepAngle: 360
            }
        }
        ShapePath {
            strokeColor: ring.tint
            strokeWidth: ring.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.width / 2 - ring.stroke / 2
                radiusY: radiusX
                startAngle: -90
                sweepAngle: 360 * Math.max(0, Math.min(1, ring.progress))
            }
        }
    }

    // Live waveform over the shared cava subscription. Bars are centred like
    // the system waveform and fall flat when playback pauses.
    component Waveform: Item {
        id: wave
        property bool running: false
        property color tint: IrisStyle.text
        property real barHeight: 16 * root.d
        readonly property int bars: 5
        implicitWidth: wave.bars * 3 * root.d + (wave.bars - 1) * 2 * root.d
        implicitHeight: wave.barHeight

        CavaProcess { id: cava; active: wave.running && wave.visible }
        readonly property var raw: {
            const pts = cava.points ?? []
            if (pts.length === 0) return []
            const per = pts.length / wave.bars
            const out = []
            for (let i = 0; i < wave.bars; i++) {
                const from = Math.floor(i * per)
                const to = Math.max(from + 1, Math.floor((i + 1) * per))
                let band = 0
                for (let k = from; k < to && k < pts.length; k++) band = Math.max(band, pts[k] ?? 0)
                out.push(band)
            }
            return out
        }
        // Without cava the bars hold a still silhouette rather than faking motion.
        readonly property var restShape: [0.45, 0.8, 0.6, 0.9, 0.5]

        Row {
            anchors.centerIn: parent
            spacing: 2 * root.d
            Repeater {
                model: wave.bars
                Rectangle {
                    required property int index
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3 * root.d
                    radius: width / 2
                    color: wave.tint
                    height: {
                        const level = !wave.running ? 0
                            : wave.raw.length > 0 ? Math.min(1, (wave.raw[index] ?? 0) / Math.max(1, cava.normalizationCeiling))
                            : wave.restShape[index]
                        return Math.max(3 * root.d, level * wave.barHeight)
                    }
                    Behavior on height { NumberAnimation { duration: IrisStyle.duration(90); easing.type: Easing.OutQuad } }
                }
            }
        }
    }

    // Detached minimal presentation. Emerges from behind the chassis edge so
    // splitting and merging read as the same material separating.
    component Satellite: Item {
        id: satellite
        property string kind: ""
        property bool shown: false
        property bool leftSide: false
        readonly property alias hovered: satelliteHover.hovered
        signal activated()

        property real emerge: satellite.shown ? 1 : 0
        Behavior on emerge { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }

        // A notch chassis hangs from the edge; its satellite floats free of it.
        width: root.notch ? root.bubble - Math.round(8 * root.d) : root.bubble
        height: width
        z: -1
        y: root.bottomEdge ? root.height - (root.bubble + height) / 2 : (root.bubble - height) / 2
        x: satellite.leftSide
            ? chassis.x + (-root.satelliteGap - width) * satellite.emerge
            : chassis.x + chassis.width - width + (root.satelliteGap + width) * satellite.emerge
        visible: satellite.emerge > 0.01
        opacity: root.handingOff && root.handoffPart === satellite ? 0 : Math.min(1, satellite.emerge * 1.6)
        scale: 0.72 + 0.28 * satellite.emerge

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: IrisStyle.surface
        }
        Item {
            anchors.fill: parent
            scale: satelliteHover.hovered ? 1.06 : 1
            Behavior on scale { NumberAnimation { duration: IrisStyle.duration(120); easing.type: Easing.OutCubic } }

            IrisArtwork {
                visible: satellite.kind === "media"
                anchors.centerIn: parent
                width: parent.width - 12 * root.d
                height: width
                source: MediaArtwork.displaySource
                circular: true
            }
            ProgressRing {
                visible: satellite.kind === "media" || (satellite.kind === "timer" && root.timerKind !== "stopwatch")
                anchors.fill: parent
                anchors.margins: 2 * root.d
                tint: satellite.kind === "media" ? root.artTint : IrisStyle.secondaryAccent
                progress: satellite.kind === "media" ? root.trackProgress : root.timerProgress
            }
            Glyph {
                visible: satellite.kind === "timer"
                anchors.centerIn: parent
                text: root.timerPaused ? "pause" : root.timerGlyph
                iconSize: 16 * root.d
                color: IrisStyle.secondaryAccent
            }
            RecordDot {
                visible: satellite.kind === "record"
                anchors.centerIn: parent
                width: 12 * root.d
                height: width
            }
            Glyph {
                visible: satellite.kind === "controls"
                anchors.centerIn: parent
                text: Network.wifiEnabled ? "wifi" : "tune"
                fill: 0
                iconSize: 19 * root.d
            }
        }
        HoverHandler {
            id: satelliteHover
            cursorShape: Qt.PointingHandCursor
            onPointChanged: root.trackDwell(point.scenePosition)
        }
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => root.applyWheel(event)
        }
        TapHandler { onTapped: satellite.activated() }
        Accessible.role: Accessible.Button
        Accessible.name: satellite.kind === "controls" ? Translation.tr("Quick controls")
            : satellite.kind === "media" ? Translation.tr("Now playing")
            : satellite.kind === "record" ? Translation.tr("Screen recording") : root.timerLabel
    }

    // ── Satellites ───────────────────────────────────────────────────────
    Satellite {
        id: leftSatellite
        leftSide: true
        kind: root.primary
        shown: root.leftSatelliteShown
        onActivated: root.openPage(root.pageFor(root.primary), true)
    }
    Satellite {
        id: rightSatellite
        kind: IrisStyle.cluster ? "controls" : root.secondary
        shown: root.rightSatelliteShown
        onActivated: {
            if (IrisStyle.cluster) GlobalStates.controlPanelOpen = true
            else root.openPage(root.pageFor(root.secondary), true)
        }
    }

    // Concave fillets melt a notch-mode Island into the screen edge.
    Repeater {
        model: root.notch ? 2 : 0
        RoundCorner {
            required property int index
            implicitSize: root.fillet
            color: IrisStyle.surface
            // Solid black fillets would outline a chassis tinted by artwork.
            opacity: artBackdrop.active && root.visualExpanded ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140) } }
            y: root.bottomEdge ? root.height - root.fillet : 0
            x: index === 0 ? chassis.x - root.fillet : chassis.x + chassis.width
            corner: index === 0
                ? (root.bottomEdge ? RoundCorner.CornerEnum.BottomRight : RoundCorner.CornerEnum.TopRight)
                : (root.bottomEdge ? RoundCorner.CornerEnum.BottomLeft : RoundCorner.CornerEnum.TopLeft)
        }
    }

    // ── Chassis ──────────────────────────────────────────────────────────
    // A clipping chassis: artwork, compact rows and expanded pages are all cut
    // by the same continuous silhouette while it morphs, so no rectangular
    // content corner can escape the rounded shape mid-transition.
    ClippingRectangle {
        id: chassis
        // Notch mode keeps one uniform radius and lets the chassis overflow the
        // screen edge by that radius; the layer surface hides those corners.
        // ClippingRectangle does not re-mask when per-corner radii change live.
        property real bodyHeight: root.visualExpanded ? (details.item?.implicitHeight ?? 0) + root.padding * 2 : root.compactHeight
        readonly property real topInset: root.notch && !root.bottomEdge ? chassis.radius : 0
        readonly property real bottomInset: root.notch && root.bottomEdge ? chassis.radius : 0
        x: (root.width - width) / 2
        y: -chassis.topInset
        width: root.chassisTargetWidth
        height: chassis.bodyHeight + chassis.topInset + chassis.bottomInset
        color: IrisStyle.surface
        radius: root.visualExpanded ? Math.max(IrisStyle.radius, 30 * root.d) : root.compactHeight / 2

        // One object morphing: width, height and radius chase the same liquid
        // curve, so the island reads as a single shape changing.
        Behavior on width { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
        Behavior on bodyHeight { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
        Behavior on radius { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }

        HoverHandler {
            id: chassisHover
            onPointChanged: root.trackDwell(point.scenePosition)
        }
        // Any press inside an Island opened by hover commits it (pins), so the
        // user can move away after interacting without it vanishing.
        PointHandler {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onActiveChanged: if (active && root.expanded) root.pinned = true
        }
        WheelHandler {
            enabled: !root.visualExpanded
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => root.applyWheel(event)
        }

        // Artwork vibrancy: the blurred cover tints the whole expanded chassis
        // (not an inset card) and is released as soon as the page closes.
        Loader {
            id: artBackdrop
            anchors.fill: parent
            active: details.active && root.effectivePage === "media"
                && (Config.options?.iris?.player?.artworkBackground ?? true)
                && MediaArtwork.displaySource.length > 0
            opacity: details.opacity * (root.effectivePage === "media" ? 1 : 0)
            sourceComponent: IrisMediaBackdrop { source: MediaArtwork.displaySource }
        }

        // ── Compact presentations ────────────────────────────────────────
        Item {
            id: compactLayer
            anchors.left: parent.left
            anchors.right: parent.right
            y: root.bottomEdge ? chassis.height - chassis.bottomInset - height : chassis.topInset
            height: root.compactHeight
            opacity: root.visualExpanded ? 0 : 1
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: IrisStyle.duration(root.visualExpanded ? 80 : 200)
                    easing.type: root.visualExpanded ? Easing.OutQuad : Easing.InCubic
                }
            }

            component CompactRow: RowLayout {
                id: compactRow
                property string mode: ""
                anchors.fill: parent
                anchors.leftMargin: 14 * root.d
                anchors.rightMargin: 15 * root.d
                spacing: 9 * root.d
                opacity: root.compactMode === compactRow.mode ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: Easing.OutCubic } }
            }

            CompactRow {
                mode: "idle"
                IrisText {
                    text: Qt.locale().toString(DateTime.clock.date, "ddd d")
                    role: IrisText.Meta
                    font.pixelSize: 12 * IrisStyle.typeScale
                    font.weight: Font.Medium
                }
                Item { Layout.fillWidth: true }
                Tabular {
                    text: DateTime.timeDisplay
                    font.pixelSize: 13 * IrisStyle.typeScale
                    font.weight: Font.DemiBold
                }
            }

            CompactRow {
                mode: "media"
                IrisArtwork {
                    Layout.preferredWidth: 24 * root.d
                    Layout.preferredHeight: 24 * root.d
                    source: MediaArtwork.displaySource
                    circular: Config.options?.iris?.player?.roundCover ?? true
                    radius: circular ? width / 2 : 6 * root.d
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3 * root.d
                    IrisText {
                        Layout.fillWidth: true
                        text: root.title
                        font.pixelSize: 12 * IrisStyle.typeScale
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        visible: root.effectiveLength > 0
                        implicitHeight: 2.5 * root.d
                        radius: height / 2
                        color: ColorUtils.applyAlpha(IrisStyle.text, 0.18)
                        Rectangle {
                            height: parent.height
                            radius: parent.radius
                            color: IrisStyle.text
                            width: parent.width * root.trackProgress
                        }
                    }
                }
                Tabular {
                    text: DateTime.timeDisplay
                    color: IrisStyle.subtext
                    font.pixelSize: 12 * IrisStyle.typeScale
                    font.weight: Font.Medium
                }
                Waveform {
                    running: root.playing && root.compactMode === "media" && !root.visualExpanded
                    tint: root.artTint
                    barHeight: 15 * root.d
                }
            }

            CompactRow {
                mode: "record"
                RecordDot { Layout.alignment: Qt.AlignVCenter }
                IrisText {
                    Layout.fillWidth: true
                    text: Translation.tr("Recording")
                    font.pixelSize: 12 * IrisStyle.typeScale
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Tabular {
                    text: root.clockText(RecorderStatus.elapsedSeconds)
                    color: IrisStyle.danger
                    font.pixelSize: 13 * IrisStyle.typeScale
                    font.weight: Font.DemiBold
                }
            }

            CompactRow {
                mode: "timer"
                Glyph {
                    text: root.timerPaused ? "pause" : root.timerGlyph
                    iconSize: 17 * root.d
                    color: IrisStyle.secondaryAccent
                }
                IrisText {
                    Layout.fillWidth: true
                    text: root.timerLabel
                    font.pixelSize: 12 * IrisStyle.typeScale
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Tabular {
                    text: root.clockText(root.timerSeconds)
                    color: root.timerPaused ? IrisStyle.subtext : IrisStyle.secondaryAccent
                    font.pixelSize: 13 * IrisStyle.typeScale
                    font.weight: Font.DemiBold
                }
            }

            CompactRow {
                mode: "clock"
                Item { Layout.fillWidth: true }
                Tabular {
                    text: DateTime.timeDisplay
                    font.pixelSize: 13 * IrisStyle.typeScale
                    font.weight: Font.DemiBold
                }
                Item { Layout.fillWidth: true }
            }

            // Apple-style HUD: glyph, continuous level capsule, value.
            CompactRow {
                mode: "feedback"
                Glyph {
                    text: root.feedbackIcon
                    iconSize: 18 * root.d
                    color: root.feedbackMuted ? IrisStyle.subtext : IrisStyle.text
                    Layout.preferredWidth: 20 * root.d
                }
                IrisScrubber {
                    Layout.fillWidth: true
                    seekable: false
                    value: root.feedbackMuted ? 0 : Math.min(1, root.feedbackValue)
                    fillColor: IrisStyle.text
                    Behavior on value { NumberAnimation { duration: IrisStyle.duration(110); easing.type: Easing.OutCubic } }
                }
                Tabular {
                    Layout.preferredWidth: 32 * root.d
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(root.feedbackValue * 100)
                    color: IrisStyle.subtext
                    font.pixelSize: 12 * IrisStyle.typeScale
                    font.weight: Font.DemiBold
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: !root.visualExpanded
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: root.expanded ? Translation.tr("Collapse island") : Translation.tr("Expand island")
                onClicked: mouse => {
                    if (mouse.button === Qt.MiddleButton) {
                        if (root.hasMedia) MprisController.togglePlaying()
                        return
                    }
                    if (root.pinned) root.expanded = false
                    else root.openPage(IrisStyle.cluster ? "desktop" : root.pageFor(root.primary), true)
                }
            }
        }

        // ── Expanded presentations ───────────────────────────────────────
        Loader {
            id: details
            anchors.top: parent.top
            anchors.topMargin: root.padding + chassis.topInset
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(0, root.expandedWidth - root.padding * 2)
            active: root.expanded || opacity > 0
            // The requested page survives until the content has faded out, so
            // closing never swaps pages (and heights) mid-collapse.
            onActiveChanged: if (!active) root.page = ""
            opacity: root.visualExpanded ? 1 : 0
            scale: root.visualExpanded ? 1 : 0.94
            transformOrigin: root.bottomEdge ? Item.Bottom : Item.Top
            visible: opacity > 0
            enabled: root.expanded
            Behavior on opacity {
                NumberAnimation {
                    duration: IrisStyle.duration(root.visualExpanded ? 200 : 90)
                    easing.type: root.visualExpanded ? Easing.InOutQuad : Easing.OutQuad
                }
            }
            Behavior on scale { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }

            sourceComponent: ColumnLayout {
                id: expandedContent
                spacing: 14 * root.d

                component Page: ColumnLayout {
                    id: pageItem
                    property string name: ""
                    readonly property bool current: root.effectivePage === pageItem.name
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    opacity: pageItem.current ? 1 : 0
                    visible: opacity > 0
                    enabled: pageItem.current
                    Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(160); easing.type: Easing.OutCubic } }
                }

                Item {
                    id: pageStack
                    Layout.fillWidth: true
                    implicitHeight: root.effectivePage === "media" ? mediaPage.implicitHeight
                        : root.effectivePage === "activity" ? activityPage.implicitHeight
                        : desktopPage.implicitHeight

                    // Now playing
                    Page {
                        id: mediaPage
                        name: "media"
                        spacing: 14 * root.d

                        PlayerBase {
                            id: media
                            player: root.player
                            positionUpdatesActive: mediaPage.current && root.visualExpanded
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14 * root.d
                            IrisArtwork {
                                Layout.preferredWidth: 58 * root.d
                                Layout.preferredHeight: 58 * root.d
                                source: MediaArtwork.displaySource
                                circular: Config.options?.iris?.player?.roundCover ?? true
                                radius: circular ? width / 2 : 14 * root.d
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2 * root.d
                                IrisText {
                                    Layout.fillWidth: true
                                    text: media.effectiveTitle
                                    font.pixelSize: 15 * IrisStyle.typeScale
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                IrisText {
                                    Layout.fillWidth: true
                                    text: media.effectiveArtist
                                    visible: text.length > 0
                                    color: ColorUtils.applyAlpha(IrisStyle.text, 0.62)
                                    font.pixelSize: 13 * IrisStyle.typeScale
                                    elide: Text.ElideRight
                                }
                            }
                            Waveform {
                                Layout.alignment: Qt.AlignVCenter
                                running: media.effectiveIsPlaying && mediaPage.current && root.visualExpanded
                                tint: root.artTint
                                barHeight: 20 * root.d
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: media.effectiveLength > 0
                            spacing: 3 * root.d
                            IrisScrubber {
                                Layout.fillWidth: true
                                seekable: media.effectiveCanSeek
                                value: media.effectiveLength > 0 ? media.effectivePosition / media.effectiveLength : 0
                                fillColor: IrisStyle.text
                                trackColor: ColorUtils.applyAlpha(IrisStyle.text, 0.2)
                                onSeekRequested: next => media.seek(next * media.effectiveLength)
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Tabular {
                                    text: root.clockText(media.effectivePosition)
                                    color: ColorUtils.applyAlpha(IrisStyle.text, 0.55)
                                    font.pixelSize: 11 * IrisStyle.typeScale
                                    font.weight: Font.Medium
                                }
                                Item { Layout.fillWidth: true }
                                Tabular {
                                    text: "-" + root.clockText(media.effectiveLength - media.effectivePosition)
                                    color: ColorUtils.applyAlpha(IrisStyle.text, 0.55)
                                    font.pixelSize: 11 * IrisStyle.typeScale
                                    font.weight: Font.Medium
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: -6 * root.d
                            Layout.bottomMargin: -4 * root.d
                            spacing: 18 * root.d
                            Item { Layout.fillWidth: true }
                            GlyphButton {
                                glyph: "fast_rewind"
                                glyphSize: 26 * root.d
                                implicitWidth: 44 * root.d
                                enabled: media.effectiveCanGoPrevious
                                Accessible.name: Translation.tr("Previous track")
                                onClicked: media.previous()
                            }
                            GlyphButton {
                                glyph: media.effectiveIsPlaying ? "pause" : "play_arrow"
                                glyphSize: 36 * root.d
                                implicitWidth: 52 * root.d
                                enabled: root.hasMedia
                                Accessible.name: media.effectiveIsPlaying ? Translation.tr("Pause") : Translation.tr("Play")
                                onClicked: media.togglePlaying()
                            }
                            GlyphButton {
                                glyph: "fast_forward"
                                glyphSize: 26 * root.d
                                implicitWidth: 44 * root.d
                                enabled: media.effectiveCanGoNext
                                Accessible.name: Translation.tr("Next track")
                                onClicked: media.next()
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }

                    // Live activities
                    Page {
                        id: activityPage
                        name: "activity"
                        spacing: 12 * root.d

                        RowLayout {
                            Layout.fillWidth: true
                            visible: root.recording
                            spacing: 12 * root.d
                            Item {
                                Layout.preferredWidth: 40 * root.d
                                Layout.preferredHeight: 40 * root.d
                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: ColorUtils.applyAlpha(IrisStyle.danger, 0.16)
                                }
                                RecordDot { anchors.centerIn: parent; width: 14 * root.d; height: width }
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
                            Tabular {
                                text: root.clockText(RecorderStatus.elapsedSeconds)
                                color: IrisStyle.danger
                                font.pixelSize: 22 * IrisStyle.typeScale
                                font.weight: Font.DemiBold
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
                            visible: root.recording && root.timerKind.length > 0
                            implicitHeight: 1
                            color: ColorUtils.applyAlpha(IrisStyle.text, 0.1)
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: root.timerKind.length > 0
                            spacing: 12 * root.d
                            Item {
                                Layout.preferredWidth: 40 * root.d
                                Layout.preferredHeight: 40 * root.d
                                ProgressRing {
                                    anchors.fill: parent
                                    visible: root.timerKind !== "stopwatch"
                                    tint: IrisStyle.secondaryAccent
                                    stroke: 3 * root.d
                                    progress: root.timerProgress
                                }
                                Glyph {
                                    anchors.centerIn: parent
                                    text: root.timerGlyph
                                    iconSize: 18 * root.d
                                    color: IrisStyle.secondaryAccent
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                IrisText {
                                    text: root.timerLabel
                                    font.pixelSize: 14 * IrisStyle.typeScale
                                    font.weight: Font.DemiBold
                                }
                                IrisText {
                                    text: root.timerPaused ? Translation.tr("Paused")
                                        : root.timerKind === "pomodoro"
                                            ? Translation.tr("Cycle %1 of %2").arg(TimerService.pomodoroCycle + 1).arg(TimerService.cyclesBeforeLongBreak)
                                        : Translation.tr("Running")
                                    role: IrisText.Meta
                                }
                            }
                            Tabular {
                                text: root.clockText(root.timerSeconds)
                                color: root.timerPaused ? IrisStyle.subtext : IrisStyle.secondaryAccent
                                font.pixelSize: 22 * IrisStyle.typeScale
                                font.weight: Font.DemiBold
                            }
                            GlyphButton {
                                glyph: root.timerPaused ? "play_arrow" : "pause"
                                colBackground: ColorUtils.applyAlpha(IrisStyle.secondaryAccent, 0.18)
                                colBackgroundHover: ColorUtils.applyAlpha(IrisStyle.secondaryAccent, 0.28)
                                glyphColor: IrisStyle.secondaryAccent
                                Accessible.name: root.timerPaused ? Translation.tr("Resume") : Translation.tr("Pause")
                                onClicked: {
                                    if (root.timerKind === "pomodoro") TimerService.togglePomodoro()
                                    else if (root.timerKind === "countdown") TimerService.toggleCountdown()
                                    else TimerService.toggleStopwatch()
                                }
                            }
                            GlyphButton {
                                glyph: "close"
                                colBackground: ColorUtils.applyAlpha(IrisStyle.text, 0.1)
                                colBackgroundHover: ColorUtils.applyAlpha(IrisStyle.text, 0.18)
                                glyphSize: 18 * root.d
                                Accessible.name: Translation.tr("Stop timer")
                                onClicked: {
                                    if (root.timerKind === "pomodoro") TimerService.stopPomodoro()
                                    else if (root.timerKind === "countdown") TimerService.stopCountdown()
                                    else TimerService.stopStopwatch()
                                }
                            }
                        }
                    }

                    // Desktop: a glanceable dashboard — time and weather, this
                    // output's workspaces, the focused app, system status and
                    // any custom modules configured for the bar.
                    Page {
                        id: desktopPage
                        name: "desktop"
                        spacing: 14 * root.d

                        readonly property var workspaces: CompositorService.isNiri
                            ? (NiriService.allWorkspaces ?? []).filter(ws => ws.output === root.targetScreen?.name) : []
                        readonly property var activeWorkspace: desktopPage.workspaces.find(ws => ws.is_active) ?? null
                        // A pinned Island holds keyboard focus, so read the workspace's
                        // own active window instead of the compositor's focused one.
                        readonly property var focusedWindow: {
                            const ws = desktopPage.activeWorkspace
                            if (!ws) return null
                            const onWorkspace = (NiriService.windows ?? []).filter(w => w.workspace_id === ws.id)
                            const stamp = w => (w.focus_timestamp?.secs ?? 0) * 1e9 + (w.focus_timestamp?.nanos ?? 0)
                            return onWorkspace.find(w => w.id === ws.active_window_id)
                                ?? onWorkspace.slice().sort((a, b) => stamp(b) - stamp(a))[0] ?? null
                        }
                        readonly property var customModules: ["left", "center", "right"]
                            .reduce((all, slot) => all.concat(root.options?.[slot + "Modules"] ?? []), [])
                            .filter(id => String(id).startsWith("custom:"))
                        readonly property bool weatherReady: Weather.enabled && !String(Weather.data?.temp ?? "--").startsWith("--")

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12 * root.d
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: -2 * root.d
                                Tabular {
                                    text: DateTime.timeDisplay
                                    font.family: IrisStyle.fontTitle
                                    font.pixelSize: 36 * IrisStyle.typeScale
                                    font.weight: Font.DemiBold
                                }
                                IrisText {
                                    text: Qt.locale().toString(DateTime.clock.date, "dddd, d MMMM")
                                    color: ColorUtils.applyAlpha(IrisStyle.text, 0.6)
                                    font.pixelSize: 13 * IrisStyle.typeScale
                                }
                            }
                            ColumnLayout {
                                visible: desktopPage.weatherReady
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 0
                                RowLayout {
                                    Layout.alignment: Qt.AlignRight
                                    spacing: 6 * root.d
                                    Glyph {
                                        text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
                                        iconSize: 22 * root.d
                                    }
                                    Tabular {
                                        text: String(Weather.data?.temp ?? "")
                                        font.pixelSize: 22 * IrisStyle.typeScale
                                        font.weight: Font.Medium
                                    }
                                }
                                IrisText {
                                    Layout.alignment: Qt.AlignRight
                                    Layout.maximumWidth: 150 * root.d
                                    text: String(Weather.data?.description ?? "")
                                    color: ColorUtils.applyAlpha(IrisStyle.text, 0.6)
                                    font.pixelSize: 12 * IrisStyle.typeScale
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // Workspaces as page dots: the active one is a wide capsule,
                        // occupied ones brighter than empty ones.
                        RowLayout {
                            Layout.fillWidth: true
                            visible: desktopPage.workspaces.length > 1
                            spacing: 10 * root.d
                            IrisText {
                                Layout.fillWidth: true
                                text: desktopPage.activeWorkspace
                                    ? (String(desktopPage.activeWorkspace.name ?? "").length > 0
                                        ? desktopPage.activeWorkspace.name
                                        : Translation.tr("Workspace %1").arg(desktopPage.activeWorkspace.idx))
                                    : ""
                                color: ColorUtils.applyAlpha(IrisStyle.text, 0.6)
                                font.pixelSize: 12 * IrisStyle.typeScale
                                font.weight: Font.Medium
                            }
                            Row {
                                spacing: 6 * root.d
                                Repeater {
                                    model: desktopPage.workspaces
                                    MouseArea {
                                        id: dot
                                        required property var modelData
                                        readonly property bool active: dot.modelData.is_active
                                        readonly property bool occupied: (NiriService.windows ?? []).some(w => w.workspace_id === dot.modelData.id)
                                        width: indicator.width + 4 * root.d
                                        height: 16 * root.d
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        Accessible.role: Accessible.Button
                                        Accessible.name: Translation.tr("Workspace %1").arg(dot.modelData.idx)
                                        onClicked: NiriService.switchToWorkspaceById(dot.modelData.id)
                                        Rectangle {
                                            id: indicator
                                            anchors.centerIn: parent
                                            width: dot.active ? 24 * root.d : 8 * root.d
                                            height: 8 * root.d
                                            radius: height / 2
                                            color: ColorUtils.applyAlpha(IrisStyle.text,
                                                dot.active ? 1 : dot.containsMouse ? 0.7 : dot.occupied ? 0.45 : 0.2)
                                            Behavior on width { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
                                            Behavior on color { ColorAnimation { duration: IrisStyle.duration(120) } }
                                        }
                                    }
                                }
                            }
                        }

                        // Focused app on this workspace.
                        Rectangle {
                            Layout.fillWidth: true
                            visible: desktopPage.focusedWindow !== null
                            implicitHeight: 52 * root.d
                            radius: 16 * root.d
                            color: ColorUtils.applyAlpha(IrisStyle.text, 0.07)
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12 * root.d
                                anchors.rightMargin: 14 * root.d
                                spacing: 11 * root.d
                                SmartAppIcon {
                                    readonly property var entry: AppSearch.lookupDesktopEntry(desktopPage.focusedWindow?.app_id ?? "")
                                    icon: entry?.icon ?? (desktopPage.focusedWindow?.app_id ?? "")
                                    fallback: "application-x-executable"
                                    iconSize: Math.round(28 * root.d)
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    IrisText {
                                        Layout.fillWidth: true
                                        text: String(desktopPage.focusedWindow?.title ?? "")
                                        font.pixelSize: 13 * IrisStyle.typeScale
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                    IrisText {
                                        Layout.fillWidth: true
                                        text: AppSearch.lookupDesktopEntry(desktopPage.focusedWindow?.app_id ?? "")?.name ?? String(desktopPage.focusedWindow?.app_id ?? "")
                                        color: ColorUtils.applyAlpha(IrisStyle.text, 0.55)
                                        font.pixelSize: 11.5 * IrisStyle.typeScale
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        // System status; any tile opens Control Center.
                        GridLayout {
                            Layout.fillWidth: true
                            columns: Battery.available ? 4 : 3
                            columnSpacing: 8 * root.d

                            component StatusTile: MouseArea {
                                id: tile
                                property string glyph: ""
                                property string label: ""
                                property string value: ""
                                property bool active: true
                                Layout.fillWidth: true
                                implicitHeight: 58 * root.d
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                Accessible.role: Accessible.Button
                                Accessible.name: tile.label
                                onClicked: { root.expanded = false; GlobalStates.controlPanelOpen = true }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 16 * root.d
                                    color: ColorUtils.applyAlpha(IrisStyle.text, tile.containsMouse ? 0.12 : 0.07)
                                    scale: tile.pressed ? 0.97 : 1
                                    Behavior on color { ColorAnimation { duration: IrisStyle.duration(110) } }
                                    Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration } }
                                }
                                ColumnLayout {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 11 * root.d
                                    anchors.rightMargin: 8 * root.d
                                    spacing: 3 * root.d
                                    Glyph {
                                        text: tile.glyph
                                        iconSize: 18 * root.d
                                        color: tile.active ? IrisStyle.text : ColorUtils.applyAlpha(IrisStyle.text, 0.45)
                                    }
                                    IrisText {
                                        Layout.fillWidth: true
                                        text: tile.value
                                        color: tile.active ? IrisStyle.text : ColorUtils.applyAlpha(IrisStyle.text, 0.55)
                                        font.pixelSize: 11.5 * IrisStyle.typeScale
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            StatusTile {
                                glyph: Network.ethernet ? "lan" : Network.wifiEnabled && Network.networkName.length > 0 ? "wifi" : "wifi_off"
                                label: Translation.tr("Network")
                                active: Network.ethernet || Network.networkName.length > 0
                                value: Network.ethernet ? Translation.tr("Ethernet")
                                    : Network.networkName.length > 0 ? Network.networkName : Translation.tr("Offline")
                            }
                            StatusTile {
                                glyph: (Audio.sink?.audio?.muted ?? false) ? "volume_off" : "volume_up"
                                label: Translation.tr("Sound")
                                active: !(Audio.sink?.audio?.muted ?? false)
                                value: (Audio.sink?.audio?.muted ?? false) ? Translation.tr("Muted") : Math.round((Audio.value ?? 0) * 100) + "%"
                            }
                            StatusTile {
                                glyph: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                                label: Translation.tr("Bluetooth")
                                active: BluetoothStatus.enabled
                                value: BluetoothStatus.firstActiveDevice?.name ?? (BluetoothStatus.enabled ? Translation.tr("On") : Translation.tr("Off"))
                            }
                            StatusTile {
                                visible: Battery.available
                                glyph: Battery.isCharging ? "battery_charging_full" : "battery_full"
                                label: Translation.tr("Battery")
                                value: Math.round(Battery.percentage * 100) + "%"
                            }
                        }

                        // User extensions from the bar slots keep a place here.
                        Flow {
                            Layout.fillWidth: true
                            visible: desktopPage.customModules.length > 0
                            spacing: 6 * root.d
                            Repeater {
                                model: desktopPage.customModules
                                IrisBarModule {
                                    required property string modelData
                                    moduleId: modelData
                                    targetScreen: root.targetScreen
                                    slot: "island.desktop"
                                }
                            }
                        }
                    }
                }

                // Page navigation shared by every expanded presentation.
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4 * root.d

                    component NavButton: IrisButton {
                        id: nav
                        property string glyph: ""
                        property string target: ""
                        selected: nav.target.length > 0 && root.effectivePage === nav.target
                        quiet: !nav.selected
                        implicitWidth: Math.round(44 * root.d)
                        implicitHeight: Math.round(30 * root.d)
                        buttonRadius: height / 2
                        buttonRadiusPressed: height / 2
                        colBackgroundToggled: ColorUtils.applyAlpha(IrisStyle.text, 0.14)
                        colBackgroundToggledHover: ColorUtils.applyAlpha(IrisStyle.text, 0.2)
                        colBackgroundHover: ColorUtils.applyAlpha(IrisStyle.text, 0.08)
                        onClicked: if (nav.target.length > 0) root.page = nav.target
                        Glyph {
                            anchors.centerIn: parent
                            text: nav.glyph
                            fill: nav.selected ? 1 : 0
                            iconSize: 18 * root.d
                            color: nav.selected ? IrisStyle.text : ColorUtils.applyAlpha(IrisStyle.text, 0.6)
                        }
                    }

                    NavButton {
                        visible: root.hasMedia
                        glyph: "music_note"
                        target: "media"
                        Accessible.name: Translation.tr("Now playing")
                    }
                    NavButton {
                        visible: root.hasSystemActivity
                        glyph: root.recording ? "radio_button_checked" : root.timerGlyph
                        target: "activity"
                        Accessible.name: Translation.tr("Live activities")
                    }
                    NavButton {
                        glyph: "space_dashboard"
                        target: "desktop"
                        Accessible.name: Translation.tr("Desktop")
                    }
                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 14 * root.d
                        Layout.leftMargin: 4 * root.d
                        Layout.rightMargin: 4 * root.d
                        color: ColorUtils.applyAlpha(IrisStyle.text, 0.14)
                    }
                    NavButton {
                        glyph: "tune"
                        Accessible.name: Translation.tr("Quick controls")
                        onClicked: { root.expanded = false; GlobalStates.controlPanelOpen = true }
                    }
                    NavButton {
                        glyph: "settings"
                        Accessible.name: Translation.tr("Settings")
                        onClicked: { root.expanded = false; GlobalStates.openSettings() }
                    }
                }
            }
        }
    }
}
