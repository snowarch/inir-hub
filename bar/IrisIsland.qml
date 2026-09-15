pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
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
    // Edge the owning bar window is mapped on (not the live option: the bar
    // recycles its surface when the edge changes).
    property bool bottomEdge: String(root.options?.position ?? "top") === "bottom"

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
    property Item controlMorphPart: null
    property Item settingsMorphPart: null
    property bool controlOriginPrepared: false
    property bool settingsOriginPrepared: false

    function openControlCenterFrom(part): void {
        root.controlMorphPart = part ?? chassis
        root.publishOrigin(root.controlMorphPart)
        root.controlOriginPrepared = true
        root.expanded = false
        GlobalStates.controlPanelOpen = true
    }

    function openSettingsFrom(part): void {
        root.settingsMorphPart = part ?? chassis
        root.publishOrigin(root.settingsMorphPart)
        root.settingsOriginPrepared = true
        root.expanded = false
        GlobalStates.openSettings()
    }
    readonly property bool handingOff: GlobalStates.irisMorphHandoff && GlobalStates.irisMorphOwner === ""
        && root.targetScreen?.name === GlobalStates.focusedScreen?.name

    // Profile picture: the picker lives outside the expanded content so it
    // survives the collapse that makes room for the native dialog.
    function chooseAvatar(): void {
        root.expanded = false
        avatarDialog.open()
    }
    FileDialog {
        id: avatarDialog
        title: Translation.tr("Profile picture")
        fileMode: FileDialog.OpenFile
        nameFilters: [Translation.tr("Images") + " (*.png *.jpg *.jpeg *.webp *.bmp *.avif)"]
        onAccepted: {
            setAvatar.command = [Quickshell.shellPath("scripts/accounts/set-avatar.sh"), FileUtils.trimFileProtocol(String(selectedFile))]
            setAvatar.running = true
        }
    }
    Process {
        id: setAvatar
        onExited: exitCode => { if (exitCode === 0) Directories.userAvatarRevision++ }
    }

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
        // A level bubble being scrolled is its own feedback; the HUD would
        // retire the bubble from under the pointer.
        if (bubbleWheel.running) return
        if (!(Config.options?.iris?.modules?.osd ?? true) || root.expanded
            || root.targetScreen?.name !== GlobalStates.focusedScreen?.name) return
        root.feedbackKind = kind
        feedbackTimer.restart()
    }

    // ── System events ────────────────────────────────────────────────────
    // Things that just happened (charger, a Bluetooth device, Do Not Disturb,
    // Caps Lock, keyboard layout) take the resting shape for a moment and leave
    // on their own, like the level HUD: glyph in its identity colour, what
    // happened, and a level when one matters. Quiet during the first seconds
    // after load so restoring state never reads as news.
    readonly property bool eventsEnabled: root.options?.events ?? true
    property var event: ({ icon: "", tint: IrisStyle.text, title: "", detail: "", value: -1 })
    readonly property bool eventShown: eventTimer.running && !root.expanded && !root.feedback
    function showEvent(icon: string, tint: color, title: string, detail: string, value: real): void {
        if (!root.eventsEnabled || !eventsWarm.ready || root.expanded || root.fullscreenCovered
            || root.targetScreen?.name !== GlobalStates.focusedScreen?.name) return
        root.event = { icon: icon, tint: tint, title: title, detail: detail, value: value }
        eventTimer.restart()
    }
    Timer { id: eventTimer; interval: 2600 }
    // Minor state (Caps Lock, keyboard layout) never takes the Island over: a
    // small pill drops out of it, centred, and goes back in.
    property var badge: ({ icon: "", tint: IrisStyle.text, text: "" })
    function showBadge(icon: string, tint: color, text: string): void {
        if (!root.eventsEnabled || !eventsWarm.ready || root.fullscreenCovered
            || root.targetScreen?.name !== GlobalStates.focusedScreen?.name) return
        root.badge = { icon: icon, tint: tint, text: text }
        badgeTimer.restart()
    }
    Timer { id: badgeTimer; interval: 1600 }
    Timer { id: eventsWarm; property bool ready: false; interval: 4000; running: true; onTriggered: ready = true }
    Connections {
        target: root.eventsEnabled && Battery.available ? Battery : null
        function onIsPluggedInChanged(): void {
            root.showEvent(Battery.isPluggedIn ? "battery_charging_full" : "battery_6_bar",
                Battery.isPluggedIn ? IrisStyle.success : IrisStyle.text,
                Battery.isPluggedIn ? Translation.tr("Charging") : Translation.tr("On battery"),
                Battery.isPluggedIn && Battery.timeToFull > 0 ? Translation.tr("Full in %1").arg(root.durationText(Battery.timeToFull))
                    : !Battery.isPluggedIn && Battery.timeToEmpty > 0 ? Translation.tr("%1 left").arg(root.durationText(Battery.timeToEmpty)) : "",
                Battery.percentage)
        }
        function onIsLowAndNotChargingChanged(): void {
            if (Battery.isLowAndNotCharging)
                root.showEvent("battery_alert", IrisStyle.danger, Translation.tr("Low battery"), Translation.tr("Plug in soon"), Battery.percentage)
        }
    }
    readonly property int bluetoothCount: root.eventsEnabled ? BluetoothStatus.activeDeviceCount : 0
    property int lastBluetoothCount: -1
    onBluetoothCountChanged: {
        const device = BluetoothStatus.firstActiveDevice
        if (root.lastBluetoothCount >= 0 && root.bluetoothCount > root.lastBluetoothCount && device)
            root.showEvent("bluetooth_connected", "#64a8ff", String(device.name ?? Translation.tr("Device")), Translation.tr("Connected"),
                device.batteryAvailable ? device.battery : -1)
        else if (root.lastBluetoothCount > root.bluetoothCount)
            root.showEvent("bluetooth_disabled", IrisStyle.subtext, Translation.tr("Bluetooth"), Translation.tr("Device disconnected"), -1)
        root.lastBluetoothCount = root.bluetoothCount
    }
    Connections {
        target: root.eventsEnabled ? Notifications : null
        function onSilentChanged(): void {
            root.showEvent(Notifications.silent ? "do_not_disturb_on" : "notifications_active",
                Notifications.silent ? "#b4a0ff" : IrisStyle.text, Translation.tr("Do not disturb"),
                Notifications.silent ? Translation.tr("On") : Translation.tr("Off"), -1)
        }
    }
    // An activity that ends takes the resting shape for a moment instead of
    // vanishing: the Island says what finished before the clock returns.
    Connections {
        target: root.eventsEnabled ? TimerService : null
        function onCountdownRunningChanged(): void {
            // Reset/stop restores the full duration; only a real finish reaches zero.
            if (!TimerService.countdownRunning && TimerService.countdownSecondsLeft <= 0)
                root.showEvent("alarm", IrisStyle.secondaryAccent, Translation.tr("Time's up"),
                    Translation.tr("%1 timer").arg(root.durationText(TimerService.countdownDuration)), -1)
        }
        function onPomodoroBreakChanged(): void {
            if (!TimerService.pomodoroRunning) return
            root.showEvent(TimerService.pomodoroBreak ? "coffee" : "self_improvement", IrisStyle.secondaryAccent,
                TimerService.pomodoroBreak ? (TimerService.pomodoroLongBreak ? Translation.tr("Long break") : Translation.tr("Break"))
                    : Translation.tr("Focus"),
                root.durationText(TimerService.pomodoroLapDuration), -1)
        }
    }
    // The recorder clears its elapsed time as it stops, so the length is kept.
    property int lastRecordingSeconds: 0
    onRecordingChanged: {
        if (root.recording) root.lastRecordingSeconds = 0
        else if (root.eventsEnabled && root.lastRecordingSeconds > 0)
            root.showEvent("stop_circle", IrisStyle.danger, Translation.tr("Recording saved"), root.clockText(root.lastRecordingSeconds), -1)
    }
    Connections {
        target: root.recording ? RecorderStatus : null
        function onElapsedSecondsChanged(): void {
            if (RecorderStatus.elapsedSeconds > 0) root.lastRecordingSeconds = RecorderStatus.elapsedSeconds
        }
    }
    // Only referenced while events are on, so the keyboard state daemon is not
    // started for iRiS otherwise.
    Connections {
        target: root.eventsEnabled && (Config.options?.keyboardIndicators?.showPopup ?? true) ? KeyboardIndicators : null
        function onCapsLockChanged(): void {
            if (!KeyboardIndicators.ready || !KeyboardIndicators.showCapsPopup) return
            root.showBadge("keyboard_capslock", KeyboardIndicators.capsLock ? IrisStyle.secondaryAccent : IrisStyle.subtext,
                KeyboardIndicators.capsLock ? Translation.tr("Caps Lock") : Translation.tr("Caps Lock off"))
        }
        function onCurrentLayoutNameChanged(): void {
            if (!KeyboardIndicators.showLayoutPopup || !KeyboardIndicators.hasMultipleLayouts) return
            root.showBadge("keyboard", IrisStyle.accent, KeyboardIndicators.currentLayoutCodeInline || KeyboardIndicators.currentLayoutName)
        }
    }
    function durationText(seconds: real): string {
        const m = Math.round(seconds / 60)
        return m >= 60 ? Math.floor(m / 60) + " h " + (m % 60) + " min" : m + " min"
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
    // The fillet follows the chassis radius as it morphs, so the join to the
    // screen edge grows with the shape instead of snapping between sizes.
    readonly property real fillet: root.notch ? Math.round(chassis.radius * 0.62) : 0
    readonly property real expandedWidth: Math.min(root.availableWidth - 2 * (root.bubble + root.satelliteGap),
        (root.effectivePage === "activity" ? 384 : 440) * root.d)
    readonly property real padding: Math.round(20 * root.d)
    // Desktop editing is modal, so it takes the resting shape over the clock
    // and activities: the Island says what mode the desktop is in and ends it.
    readonly property bool editingDesktop: GlobalStates.widgetEditMode
        && root.targetScreen?.name === GlobalStates.focusedScreen?.name
    readonly property string compactMode: root.feedback ? "feedback"
        : root.eventShown ? "event"
        : root.editingDesktop ? "edit"
        : IrisStyle.cluster ? "clock" : root.primary
    readonly property real chassisTargetWidth: root.visualExpanded ? root.expandedWidth
        : Math.min(root.availableWidth, (root.compactMode === "feedback" ? 280
            : root.compactMode === "event" ? 300
            : root.compactMode === "clock" ? (root.clockStyle === "time" ? 96 : 156)
            : root.compactMode === "idle" && root.clockStyle === "time" ? 110
            : root.compactMode === "media" ? 320
            : root.compactMode === "edit" ? 250
            : root.compactMode === "idle" ? 180 : 236) * root.d)
    // What the resting clock shows, and what the Cluster's trailing bubble is.
    readonly property string clockStyle: {
        const style = String(root.options?.clockStyle ?? "dateTime")
        return style === "weather" && !(Weather.enabled && !String(Weather.data?.temp ?? "--").startsWith("--")) ? "time" : style
    }
    readonly property string trailing: String(root.options?.trailing ?? "controls")
    readonly property string trailingKind: root.trailing === "notifications" && (Notifications.list?.length ?? 0) === 0 ? "none" : root.trailing
    readonly property bool leftSatelliteShown: IrisStyle.cluster && !root.visualExpanded && !root.feedback && !root.eventShown
        && !root.floatingSlots.includes("left")
        && root.primary !== "idle"
    readonly property bool rightSatelliteShown: !root.visualExpanded && !root.feedback && !root.eventShown
        && !root.floatingSlots.includes("right")
        && (IrisStyle.cluster ? root.trailingKind !== "none" : root.secondary.length > 0)

    readonly property var trayItems: SystemTray.items.values.filter(item => item && item.id
        && (!(Config.options?.iris?.tray?.hidePassive ?? false) || item.status !== Status.Passive))
    readonly property string auxiliary: String(root.options?.auxiliary ?? "tray")
    readonly property int auxiliarySlot: (IrisStyle.cluster ? root.trailingKind !== "none" : root.secondary.length > 0)
        && !root.floatingSlots.includes("right") ? 2 : 1
    readonly property bool auxiliaryShown: !root.visualExpanded && !root.feedback && !root.eventShown && root.auxiliary !== "none"
        && !root.floatingSlots.includes("utility")
        && (root.auxiliary !== "tray" || root.trayItems.length > 0)
    readonly property real sideReserveTarget: root.auxiliaryShown
        ? root.auxiliarySlot * (root.bubble + root.satelliteGap)
        : root.leftSatelliteShown || root.rightSatelliteShown ? root.bubble + root.satelliteGap : root.fillet
    property real sideReserve: root.sideReserveTarget
    Behavior on sideReserve { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.OutCubic } }

    implicitWidth: chassis.width + 2 * Math.max(root.sideReserve, root.fillet)
    implicitHeight: chassis.bodyHeight
    // Input covers both the shape on screen and the shape it is becoming. A
    // morph under a still pointer must never push it out of the input region:
    // Wayland sends leave, no enter follows until the pointer moves, and the
    // hover-opened Island would collapse while the pointer is visibly on it.
    readonly property real inputWidth: Math.max(root.implicitWidth,
        root.chassisTargetWidth + 2 * Math.max(root.sideReserveTarget, root.fillet))
    readonly property real inputHeight: Math.max(root.implicitHeight, chassis.bodyHeightTarget)

    Accessible.role: Accessible.Grouping
    Accessible.name: Translation.tr("Dynamic Island")

    // ── Behaviour ────────────────────────────────────────────────────────
    // Intent, not contact: the Island only opens once the pointer settles on a
    // real part of it (chassis or satellite). Sweeping across the screen edge
    // keeps restarting the dwell, and panels are never opened by hover alone.
    readonly property bool pointerOnIsland: chassisHover.hovered || leftSatellite.hovered || rightSatellite.hovered || auxiliarySatellite.hovered
    property point dwellAnchor: Qt.point(-1000, -1000)
    // Set by the bar while the pointer rests where the Island was before a
    // resize moved it away; that is not leaving until the pointer moves.
    property bool pointerHeld: false
    onPointerHeldChanged: if (!root.pointerHeld && !root.pointerOnIsland && root.expanded && !root.pinned) leaveDelay.restart()

    // Fullscreen windows own the output: the resting Island steps aside and
    // only transient feedback or an explicitly opened Island is presented.
    readonly property bool fullscreenCovered: CompositorService.isNiri
        && GameMode.hasFullscreenOnOutput(root.targetScreen?.name ?? "")
        && !NiriService.inOverview
    readonly property bool suppressed: root.fullscreenCovered && !feedbackTimer.running && !root.expanded
    opacity: root.suppressed || (root.handingOff && root.handoffPart === chassis) ? 0 : 1
    // Hidden by opacity only (input is already masked off while suppressed).
    // Cycling visible on every fullscreen or hand-off left the clipping chassis
    // and the notch path unpainted when it came back, while satellites drew.
    // Hand-off hides on the same frame and returns with a short fade. It fades
    // the whole Island, never the chassis itself: an animated opacity on the
    // ClippingRectangle left it (and the notch) unpainted after hand-offs.
    Behavior on opacity {
        enabled: !root.handingOff
        NumberAnimation { duration: IrisStyle.duration(160); easing.type: Easing.OutCubic }
    }

    function trackDwell(position: point): void {
        // Scrolling reshapes the Island under a still pointer (HUD, satellites
        // merging); that must never read as intent to expand.
        // A resting shape that is itself an action (desktop editing's Done)
        // must stay clickable: hover never expands it out from under the pointer.
        if (root.feedback || root.editingDesktop || wheelQuiet.running) { hoverDelay.stop(); return }
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
            if (root.expanded && !root.pinned && !root.pointerHeld) leaveDelay.restart()
        }
    }
    Timer {
        id: hoverDelay
        interval: Math.max(60, Number(root.options?.hoverDelay ?? 160))
        onTriggered: {
            if (!root.pointerOnIsland || root.expanded || root.feedback || root.editingDesktop || wheelQuiet.running) return
            if (auxiliarySatellite.hovered || (rightSatellite.hovered && IrisStyle.cluster)) return
            // The player and live activities open on click only: they are what
            // the wheel adjusts, and a page opening under it would take the scroll.
            const page = rightSatellite.hovered ? root.pageFor(root.secondary)
                : leftSatellite.hovered ? root.pageFor(root.primary)
                : IrisStyle.cluster ? "desktop" : root.pageFor(root.primary)
            if (page === "desktop") root.openPage(page, false)
        }
    }
    Timer { id: wheelQuiet; interval: 900 }
    Timer { id: bubbleWheel; interval: 600 }
    Timer { id: leaveDelay; interval: 320; onTriggered: { if (!root.pointerOnIsland && !root.pointerHeld && !root.pinned) root.expanded = false } }

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
    // `target` forces a level (a Sound or Microphone bubble); otherwise the
    // scroll action applies, Shift swaps volume and brightness and Ctrl adjusts
    // the microphone. An Island only peeking by hover folds back into the level
    // HUD, so scrolling over it always does what scrolling over it promises.
    function applyWheel(event, target): void {
        const action = target || String(root.options?.scrollAction ?? "volume")
        if (action === "none") return
        hoverDelay.stop()
        wheelQuiet.restart()
        if (root.expanded && !root.pinned) root.expanded = false
        if (target) bubbleWheel.restart()
        const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y * 4
        root.wheelAccumulator += delta
        const steps = Math.trunc(root.wheelAccumulator / 120)
        if (steps === 0) return
        root.wheelAccumulator -= steps * 120
        const level = target === "mic" || (!target && (event.modifiers & Qt.ControlModifier)) ? "mic"
            : target === "sound" ? "volume"
            : (action === "brightness") !== Boolean(event.modifiers & Qt.ShiftModifier) ? "brightness" : "volume"
        if (level === "brightness") {
            if (root.brightnessMonitor)
                root.brightnessMonitor.setBrightness(Math.max(0, Math.min(1, root.brightnessMonitor.brightness + steps * 0.05)))
        } else if (level === "mic") {
            Audio.setSourceVolume(Math.max(0, Math.min(1, (Audio.micVolume ?? 0) + steps * 0.05)))
        } else {
            Audio.setSinkVolume(Math.max(0, Math.min(1, (Audio.value ?? 0) + steps * 0.05)))
        }
    }
    // What a bubble does when clicked; the level bubbles mute instead of opening.
    function activateBubble(kind: string, part): void {
        if (kind === "sound") Audio.toggleMute()
        else if (kind === "mic") Audio.toggleMicMute()
        else if (kind === "notifications") GlobalStates.openSidebarRight(root.targetScreen?.name ?? "")
        else if (kind === "weather") root.openPage("desktop", true)
        else if (kind === "tray" || kind === "tools") root.openPage(kind, true)
        else root.openControlCenterFrom(part)
    }

    onExpandedChanged: {
        if (!root.expanded) root.pinned = false
        // A transient media card gives way to the Island it came from.
        else if (root.focusedOutput) GlobalStates.irisMediaCardOpen = false
    }
    // True once an expansion has settled: later size changes are hops between
    // open shapes. Cleared the moment the Island starts to close.
    property bool hopping: false
    onVisualExpandedChanged: {
        root.hopping = false
        if (root.visualExpanded) hopSettle.restart()
        else hopSettle.stop()
        root.flyParts()
    }
    // The Desktop page's wallpaper hero, kept decoded while the Island lives so
    // the page (recreated on every open) paints it on its first frame.
    readonly property real heroDecodeWidth: Math.round(Math.min(root.availableWidth - 2 * (root.bubble + root.satelliteGap), 440 * root.d) * 1.5)
    Image {
        id: heroPreload
        visible: false
        source: String(root.options?.desktopBanner ?? "wallpaper") === "wallpaper"
            ? WallpaperListener.wallpaperUrlForScreen(root.targetScreen) : ""
        asynchronous: true
        cache: true
        sourceSize.width: root.heroDecodeWidth
    }
    // Parts registered by the expanded pages (they live inside the loader).
    property Item pageCover: null
    property Item heroClock: null
    // The compact counterpart of the cover and clock in the resting shape.
    readonly property Item restingCover: IrisStyle.cluster
        ? (root.primary === "media" ? leftSatellite.artwork : null)
        : (root.compactMode === "media" ? compactCover : null)
    readonly property Item restingClock: root.compactMode === "clock" ? clusterClock
        : root.compactMode === "idle" ? idleClock : null
    function flyParts(): void {
        const opening = root.visualExpanded
        const cover = root.effectivePage === "media" ? root.pageCover : null
        const clock = root.effectivePage === "desktop" ? root.heroClock : null
        if (cover && root.restingCover) coverFlight.launch(opening ? root.restingCover : cover, opening ? cover : root.restingCover)
        else coverFlight.stop()
        if (clock && root.restingClock) clockFlight.launch(opening ? root.restingClock : clock, opening ? clock : root.restingClock)
        else clockFlight.stop()
    }
    // Page switches are content replaces, not journeys. A closing Island
    // drops its page once faded; that is not a switch.
    onEffectivePageChanged: if (root.visualExpanded) { coverFlight.stop(); clockFlight.stop() }
    Timer { id: hopSettle; interval: Math.max(1, IrisStyle.settleDuration); onTriggered: root.hopping = root.visualExpanded }
    // How long compact content and satellites wait while a closing chassis is
    // still wider than its resting shape, so they never draw over or beside
    // the expanded silhouette.
    readonly property int collapseHold: Math.round(IrisStyle.settleDuration * 0.3)
    Binding {
        target: GlobalStates
        property: "irisIslandExpanded"
        value: root.expanded
        when: root.targetScreen?.name === GlobalStates.focusedScreen?.name
        restoreMode: Binding.RestoreNone
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
        function onWallpaperSelectorOpenChanged(): void {
            root.publishOrigin(chassis)
            if (GlobalStates.wallpaperSelectorOpen) root.expanded = false
        }
        function onSearchOpenChanged(): void {
            root.publishOrigin(chassis)
            if (GlobalStates.searchOpen) root.expanded = false
        }
        // Opening and closing both publish: the surface grows out of the shape
        // that opened it and collapses into whatever the Island looks like now.
        function onControlPanelOpenChanged(): void {
            if (GlobalStates.controlPanelOpen) {
                if (!root.controlOriginPrepared) {
                    root.controlMorphPart = IrisStyle.cluster && rightSatellite.shown ? rightSatellite : chassis
                    root.publishOrigin(root.controlMorphPart)
                    root.expanded = false
                }
                root.controlOriginPrepared = false
                return
            }
            const part = root.controlMorphPart && root.controlMorphPart.visible ? root.controlMorphPart : chassis
            root.publishOrigin(part)
        }
        function onSettingsOverlayOpenChanged(): void {
            // Opened from somewhere else (a side panel button): that owner
            // publishes where Settings grows from and collapses into.
            if (GlobalStates.irisMorphOwner !== "") { root.settingsOriginPrepared = false; return }
            if (GlobalStates.settingsOverlayOpen) {
                if (!root.settingsOriginPrepared) {
                    root.settingsMorphPart = chassis
                    root.publishOrigin(chassis)
                    root.expanded = false
                }
                root.settingsOriginPrepared = false
                return
            }
            const part = root.settingsMorphPart && root.settingsMorphPart.visible ? root.settingsMorphPart : chassis
            root.publishOrigin(part)
        }
    }

    // ── Inline parts ─────────────────────────────────────────────────────
    component Tabular: IrisText {
        font.family: IrisStyle.fontNumbers
        font.features: ({ "tnum": 1 })
    }

    // Weekday quiet, day number carrying the accent: the glance reads "14"
    // and the weekday only confirms it.
    component DateMark: Row {
        id: dateMark
        property real pixelSize: 12 * IrisStyle.typeScale
        property color dayColor: IrisStyle.secondaryAccent
        spacing: Math.round(dateMark.pixelSize * 0.3)
        IrisText {
            id: weekdayText
            text: Qt.locale().toString(DateTime.clock.date, "ddd").replace(/\.$/, "")
            color: IrisStyle.muted
            font.pixelSize: dateMark.pixelSize * 0.92
            font.weight: Font.Medium
        }
        IrisText {
            anchors.baseline: weekdayText.baseline
            text: Qt.locale().toString(DateTime.clock.date, "d")
            color: dateMark.dayColor
            font.pixelSize: dateMark.pixelSize
            font.family: IrisStyle.fontNumbers
            font.weight: Font.Bold
            font.features: ({ "tnum": 1 })
        }
    }

    // A figure with its unit set small and quiet ("50" + "%", "12" + "°C").
    component Metric: Row {
        id: metric
        property string value: ""
        property string unit: ""
        property real pixelSize: 15 * IrisStyle.typeScale
        property int weight: Font.DemiBold
        property color color: IrisStyle.text
        IrisText {
            id: metricValue
            text: metric.value
            color: metric.color
            font.pixelSize: metric.pixelSize
            font.family: IrisStyle.fontNumbers
            font.weight: metric.weight
            font.features: ({ "tnum": 1 })
            font.letterSpacing: -metric.pixelSize * 0.015
        }
        IrisText {
            visible: metric.unit.length > 0
            anchors.baseline: metricValue.baseline
            leftPadding: metric.pixelSize * 0.06
            text: metric.unit
            color: ColorUtils.applyAlpha(metric.color, 0.55)
            font.pixelSize: Math.max(9, metric.pixelSize * 0.6)
            font.weight: Font.DemiBold
        }
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

    // Shared element: while the Island opens or closes, a live copy of one part
    // (cover, clock) travels from its compact place to the place it takes in
    // the other shape on the chassis curve, so the part itself grows instead
    // of fading out and reappearing. Both real parts hide while it flies; the
    // destination is followed every frame because it rides the morph too.
    component Flight: Item {
        id: flight
        property Item from: null
        property Item to: null
        property real t: 1
        property rect fromRect: Qt.rect(0, 0, 0, 0)
        property rect toRect: Qt.rect(0, 0, 0, 0)
        // Read at launch: a closing page is unloaded before the copy lands.
        property real fromRadius: 0
        property real fromPixelSize: 0
        property bool active: false
        readonly property bool flying: flight.active && flight.t < 1
        z: 10
        visible: flight.flying
        x: flight.fromRect.x + (flight.toRect.x - flight.fromRect.x) * flight.t
        y: flight.fromRect.y + (flight.toRect.y - flight.fromRect.y) * flight.t
        width: flight.fromRect.width + (flight.toRect.width - flight.fromRect.width) * flight.t
        height: flight.fromRect.height + (flight.toRect.height - flight.fromRect.height) * flight.t

        function rectOf(item: Item): rect {
            if (!item) return Qt.rect(0, 0, 0, 0)
            const a = item.mapToItem(root, 0, 0)
            const b = item.mapToItem(root, item.width, item.height)
            return Qt.rect(a.x, a.y, b.x - a.x, b.y - a.y)
        }
        function hides(item: Item): bool {
            return flight.flying && (item === flight.from || item === flight.to)
        }
        function launch(source: Item, target: Item): void {
            if (!source || !target || IrisStyle.duration(240) <= 0) { flight.stop(); return }
            // Reversing mid-flight starts from where the copy is, not from the part.
            const midway = flight.flying
            const mix = (a, b) => a + (b - a) * flight.t
            flight.fromRect = midway ? Qt.rect(flight.x, flight.y, flight.width, flight.height) : flight.rectOf(source)
            flight.fromRadius = midway ? mix(flight.fromRadius, flight.to?.radius ?? flight.fromRadius) : (source.radius ?? 0)
            flight.fromPixelSize = midway ? mix(flight.fromPixelSize, flight.to?.pixelSize ?? flight.fromPixelSize) : (source.pixelSize ?? 0)
            flight.from = source
            flight.active = true
            flight.to = target
            flight.toRect = flight.rectOf(target)
            travel.restart()
        }
        function stop(): void {
            travel.stop()
            flight.t = 1
            flight.active = false
            flight.from = null
            flight.to = null
        }

        NumberAnimation {
            id: travel
            target: flight
            property: "t"
            from: 0
            to: 1
            // Lands as the page finishes arriving (70 ms hold + 170 ms fade), not on
            // the chassis' liquid tail: a copy still growing over a visible page
            // reads as the Island moving twice.
            duration: IrisStyle.duration(240)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: IrisStyle.morphCurve
            onStopped: if (flight.t >= 1) { flight.active = false; flight.from = null; flight.to = null }
        }
        FrameAnimation {
            running: flight.flying
            onTriggered: if (flight.to) flight.toRect = flight.rectOf(flight.to)
        }
    }

    // Detached minimal presentation. Emerges from behind the chassis edge so
    // splitting and merging read as the same material separating.
    component Satellite: Item {
        id: satellite
        property string kind: ""
        // Which bubble this is ("left", "right", "utility"): what dragging moves.
        property string slot: ""
        property bool shown: false
        property bool leftSide: false
        property int slotIndex: 1
        readonly property alias hovered: satelliteHover.hovered
        readonly property alias artwork: face.artwork
        signal activated()

        property real emerge: satellite.shown ? 1 : 0
        Behavior on emerge {
            id: emergeMotion
            SequentialAnimation {
                PauseAnimation { duration: emergeMotion.targetValue > 0 && chassis.bodyHeight > root.compactHeight + 1 ? root.collapseHold : 0 }
                NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve }
            }
        }

        // A notch chassis hangs from the edge; its satellite floats free of it.
        width: root.notch ? root.bubble - Math.round(8 * root.d) : root.bubble
        height: width
        z: -1
        y: root.bottomEdge ? root.height - (root.bubble + height) / 2 : (root.bubble - height) / 2
        x: satellite.leftSide
            ? chassis.x + (-root.satelliteGap - width) * satellite.emerge
            : chassis.x + chassis.width - width + (root.satelliteGap + width) * satellite.slotIndex * satellite.emerge
        visible: satellite.emerge > 0.01
        // The media bubble is the card while the card is on screen; a lifted
        // bubble is drawn by the bubble layer under the pointer.
        readonly property bool becameCard: satellite.kind === "media" && GlobalStates.irisMediaCardShown && root.focusedOutput
            && !(GlobalStates.irisMediaBubble?.floating ?? false)
        readonly property bool lifted: root.draggedSlot === satellite.slot
        opacity: (root.handingOff && root.handoffPart === satellite) || satellite.becameCard || satellite.lifted
            ? 0 : Math.min(1, satellite.emerge * 1.6)
        scale: 0.72 + 0.28 * satellite.emerge

        IrisBubbleFace {
            id: face
            anchors.fill: parent
            kind: satellite.kind
            tint: root.artTint
            playing: root.playing
            mediaProgress: root.trackProgress
            trayCount: root.trayItems.length
            coverHidden: coverFlight.hides(face.artwork)
            pressed: bubblePointer.pressed && !bubblePointer.lifting
            hovered: satelliteHover.hovered
        }
        HoverHandler {
            id: satelliteHover
            cursorShape: Qt.PointingHandCursor
            onPointChanged: root.trackDwell(point.scenePosition)
        }
        // Level bubbles always take the wheel; the others only when the user
        // wants scrolling on every bubble.
        WheelHandler {
            enabled: satellite.kind === "sound" || satellite.kind === "mic" || (root.options?.scrollBubbles ?? true)
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => root.applyWheel(event, satellite.kind === "sound" || satellite.kind === "mic" ? satellite.kind : "")
        }
        // A click activates; holding lifts the bubble so it can be carried
        // somewhere else (see IrisBubbleLayer), and releasing drops it there.
        IrisBubbleGrip {
            id: bubblePointer
            anchors.fill: parent
            slot: satellite.slot
            kind: satellite.kind
            screenName: root.targetScreen?.name ?? ""
            screenOffsetY: root.screenOffsetY
            onTapped: satellite.activated()
        }
        Accessible.role: Accessible.Button
        Accessible.name: face.Accessible.name
    }

    // ── Satellites ───────────────────────────────────────────────────────
    Satellite {
        id: leftSatellite
        slot: "left"
        leftSide: true
        kind: root.primary
        shown: root.leftSatelliteShown
        // The media bubble floats out as a card when that is how it opens.
        onActivated: {
            if (root.mediaBubbleCard) GlobalStates.irisMediaCardOpen = !GlobalStates.irisMediaCardOpen
            else root.openPage(root.pageFor(root.primary), true)
        }
    }
    readonly property bool mediaBubbleCard: IrisStyle.cluster && root.primary === "media"
        && String(Config.options?.iris?.player?.bubbleOpens ?? "card") === "card"
    readonly property bool focusedOutput: root.targetScreen?.name === GlobalStates.focusedScreen?.name
    // The bubble's screen-local rect, for the card to grow out of and rest beside.
    // Published only while the bubble has fully emerged, so a card keeps its
    // place while the Island expands and the bubble tucks away.
    Binding {
        target: GlobalStates
        property: "irisMediaBubble"
        when: root.focusedOutput && root.mediaBubbleCard && leftSatellite.emerge >= 1 && !root.suppressed
            && !root.floatingSlots.includes("left")
        value: {
            // The Island is centred by its loader: its position is part of the rect.
            void (root.x + root.y + (root.parent?.x ?? 0) + (root.parent?.y ?? 0) + root.width + chassis.x + leftSatellite.x + leftSatellite.width)
            const p = leftSatellite.mapToItem(null, 0, 0)
            return {
                x: p.x, y: p.y + root.screenOffsetY,
                width: leftSatellite.width, height: leftSatellite.height,
                radius: leftSatellite.width / 2, screen: root.targetScreen?.name ?? ""
            }
        }
        restoreMode: Binding.RestoreNone
    }
    Connections {
        target: GlobalStates
        function onIrisIslandPageRequestChanged(): void {
            const page = GlobalStates.irisIslandPageRequest
            if (page.length === 0 || !root.focusedOutput) return
            GlobalStates.irisIslandPageRequest = ""
            root.openPage(page, true)
        }
    }
    // What each bubble slot shows on this output and where the Island rests, for
    // the bubble layer: floating bubbles take their kind from here, and a bubble
    // carried back re-attaches where its slot emerges.
    readonly property var bubbleKinds: ({
        left: IrisStyle.cluster && root.primary !== "idle" ? root.primary : "",
        right: IrisStyle.cluster ? (root.trailingKind !== "none" ? root.trailingKind : "") : root.secondary,
        utility: root.auxiliary !== "none" && (root.auxiliary !== "tray" || root.trayItems.length > 0) ? root.auxiliary : ""
    })
    readonly property var islandGeometry: {
        void (root.x + (root.parent?.x ?? 0) + (root.parent?.y ?? 0) + chassis.x + chassis.width + chassis.bodyHeight)
        const p = chassis.mapToItem(null, 0, chassis.topInset)
        return {
            x: p.x, y: p.y + root.screenOffsetY, width: chassis.width, height: chassis.bodyHeight,
            bubble: leftSatellite.width, gap: root.satelliteGap, bottomEdge: root.bottomEdge,
            auxiliarySlot: root.auxiliarySlot, resting: !root.expanded
        }
    }
    function publishBubbleState(): void {
        const name = root.targetScreen?.name ?? ""
        if (name.length === 0) return
        const kinds = Object.assign({}, GlobalStates.irisBubbleKinds ?? {})
        kinds[name] = root.bubbleKinds
        GlobalStates.irisBubbleKinds = kinds
        // Geometry is only meaningful at rest: a re-attach aims at the resting shape.
        if (root.expanded) return
        const geometry = Object.assign({}, GlobalStates.irisIslandGeometry ?? {})
        geometry[name] = root.islandGeometry
        GlobalStates.irisIslandGeometry = geometry
    }
    onBubbleKindsChanged: root.publishBubbleState()
    onIslandGeometryChanged: root.publishBubbleState()
    Component.onCompleted: root.publishBubbleState()
    // Bubbles carried off the Island live in the bubble layer; the Island keeps
    // their room free of them and hides the one being carried right now.
    readonly property var floatingSlots: ["left", "right", "utility"]
        .filter(slot => String(Config.options?.iris?.bubbles?.[slot]?.place ?? "island") !== "island")
    readonly property string draggedSlot: GlobalStates.irisBubbleDrag && GlobalStates.irisBubbleDrag.screen === (root.targetScreen?.name ?? "")
        ? String(GlobalStates.irisBubbleDrag.slot) : ""
    Satellite {
        id: rightSatellite
        slot: "right"
        kind: IrisStyle.cluster ? root.trailingKind : root.secondary
        shown: root.rightSatelliteShown
        onActivated: {
            if (!IrisStyle.cluster) root.openPage(root.pageFor(root.secondary), true)
            else root.activateBubble(root.trailingKind, rightSatellite)
        }
    }

    Satellite {
        id: auxiliarySatellite
        slot: "utility"
        kind: root.auxiliary
        slotIndex: root.auxiliarySlot
        shown: root.auxiliaryShown
        onActivated: root.activateBubble(root.auxiliary, auxiliarySatellite)
    }

    Flight {
        id: coverFlight
        IrisArtwork {
            anchors.fill: parent
            source: MediaArtwork.displaySource
            // The page cover's own decode size, so the copy it becomes is the same image.
            decodeSize: Math.ceil(68 * root.d * 2)
            circular: false
            radius: coverFlight.fromRadius + ((coverFlight.to?.radius ?? coverFlight.fromRadius) - coverFlight.fromRadius) * coverFlight.t
        }
    }
    Flight {
        id: clockFlight
        IrisClock {
            pixelSize: Math.max(1, clockFlight.fromPixelSize + ((clockFlight.to?.pixelSize ?? clockFlight.fromPixelSize) - clockFlight.fromPixelSize) * clockFlight.t)
        }
    }

    Item {
        id: badgePill
        readonly property bool shown: badgeTimer.running
        property real reveal: badgePill.shown ? 1 : 0
        Behavior on reveal { NumberAnimation { duration: IrisStyle.settleDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
        readonly property real gap: Math.round(8 * root.d)
        width: badgeRow.implicitWidth + Math.round(22 * root.d)
        height: Math.round(28 * root.d)
        x: (root.width - width) / 2
        // Drops out from behind the Island's far edge.
        y: root.bottomEdge ? -(height + gap) * badgePill.reveal + height * (1 - badgePill.reveal)
            : chassis.bodyHeight - height + (height + gap) * badgePill.reveal
        z: -2
        visible: badgePill.reveal > 0.01
        opacity: Math.min(1, badgePill.reveal * 1.5)
        scale: 0.7 + 0.3 * badgePill.reveal
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: IrisStyle.surface
        }
        Row {
            id: badgeRow
            anchors.centerIn: parent
            spacing: 6 * root.d
            Glyph {
                anchors.verticalCenter: parent.verticalCenter
                text: root.badge.icon
                iconSize: 15 * root.d
                color: root.badge.tint
            }
            IrisText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.badge.text
                font.pixelSize: 11.5 * IrisStyle.typeScale
                font.weight: Font.DemiBold
            }
        }
    }

    // Notch silhouette: body and concave fillets are one path with one fill,
    // so the join to the screen edge is the same material as the chassis (two
    // separately antialiased pieces read as a different component). The
    // clipping chassis above paints the same black over the body.
    Shape {
        id: silhouette
        visible: root.notch
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        readonly property bool flip: root.bottomEdge
        readonly property real f: Math.min(root.fillet, Math.max(0, chassis.bodyHeight - chassis.radius))
        readonly property real r: Math.min(chassis.radius, chassis.bodyHeight, chassis.width / 2)
        readonly property real edgeL: chassis.x
        readonly property real edgeR: chassis.x + chassis.width
        readonly property real far: chassis.bodyHeight
        function ey(v: real): real { return silhouette.flip ? root.height - v : v }
        readonly property int outward: silhouette.flip ? PathArc.Counterclockwise : PathArc.Clockwise
        readonly property int inward: silhouette.flip ? PathArc.Clockwise : PathArc.Counterclockwise
        ShapePath {
            strokeWidth: -1
            fillColor: IrisStyle.surface
            startX: silhouette.edgeL - silhouette.f
            startY: silhouette.ey(0)
            PathArc {
                x: silhouette.edgeL; y: silhouette.ey(silhouette.f)
                radiusX: silhouette.f; radiusY: silhouette.f
                direction: silhouette.outward
            }
            PathLine { x: silhouette.edgeL; y: silhouette.ey(silhouette.far - silhouette.r) }
            PathArc {
                x: silhouette.edgeL + silhouette.r; y: silhouette.ey(silhouette.far)
                radiusX: silhouette.r; radiusY: silhouette.r
                direction: silhouette.inward
            }
            PathLine { x: silhouette.edgeR - silhouette.r; y: silhouette.ey(silhouette.far) }
            PathArc {
                x: silhouette.edgeR; y: silhouette.ey(silhouette.far - silhouette.r)
                radiusX: silhouette.r; radiusY: silhouette.r
                direction: silhouette.inward
            }
            PathLine { x: silhouette.edgeR; y: silhouette.ey(silhouette.f) }
            PathArc {
                x: silhouette.edgeR + silhouette.f; y: silhouette.ey(0)
                radiusX: silhouette.f; radiusY: silhouette.f
                direction: silhouette.outward
            }
            PathLine { x: silhouette.edgeL - silhouette.f; y: silhouette.ey(0) }
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
        readonly property real bodyHeightTarget: root.visualExpanded ? (details.item?.implicitHeight ?? 0) + root.padding * 2 : root.compactHeight
        property real bodyHeight: chassis.bodyHeightTarget
        readonly property real topInset: root.notch && !root.bottomEdge ? chassis.radius : 0
        readonly property real bottomInset: root.notch && root.bottomEdge ? chassis.radius : 0
        // Whole pixels: the clipping chassis draws through a texture that goes
        // soft when resampled at a half-pixel offset.
        x: Math.round((root.width - width) / 2)
        y: -chassis.topInset
        width: root.chassisTargetWidth
        height: chassis.bodyHeight + chassis.topInset + chassis.bottomInset
        // Opaque even over the notch silhouette: a transparent ClippingRectangle
        // hanging past the top edge stopped painting its children. Black on the
        // same black leaves no seam.
        color: IrisStyle.surface
        radius: root.visualExpanded ? Math.max(IrisStyle.radius, 30 * root.d) : root.compactHeight / 2

        // One object morphing: width, height and radius chase the same liquid
        // curve, so the island reads as a single shape changing.
        // Opening and closing settle with a liquid tail; hopping between shapes
        // that are already open (pages, feedback, activities) stays quick.
        readonly property int morphTime: root.hopping ? IrisStyle.morphDuration : IrisStyle.settleDuration
        Behavior on width { NumberAnimation { duration: chassis.morphTime; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
        Behavior on bodyHeight { NumberAnimation { duration: chassis.morphTime; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
        Behavior on radius { NumberAnimation { duration: chassis.morphTime; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }

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
            enabled: !root.visualExpanded || !root.pinned
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => root.applyWheel(event)
        }

        // Artwork vibrancy: the blurred cover tints the whole expanded chassis
        // (not an inset card) and is released as soon as the page closes.
        Loader {
            id: artBackdrop
            anchors.fill: parent
            // Fades with the page switch instead of popping, and stays loaded
            // until it has faded out.
            property real shown: root.effectivePage === "media" ? 1 : 0
            Behavior on shown {
                enabled: root.visualExpanded && details.opacity >= 1
                NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.OutCubic }
            }
            active: details.active && (root.effectivePage === "media" || artBackdrop.shown > 0)
                && (Config.options?.iris?.player?.artworkBackground ?? true)
                && MediaArtwork.displaySource.length > 0
            opacity: details.opacity * artBackdrop.shown
            layer.enabled: artBackdrop.opacity > 0 && artBackdrop.opacity < 1
            sourceComponent: IrisMediaBackdrop {
                source: MediaArtwork.displaySource
                // The solid part of the band must cover the off-screen overflow and
                // the fillet height, or the vibrancy meets black fillets at a seam.
                edgeTop: chassis.topInset > 0 ? (chassis.topInset + root.fillet + 4 * root.d) / 0.45 : 0
                edgeBottom: chassis.bottomInset > 0 ? (chassis.bottomInset + root.fillet + 4 * root.d) / 0.45 : 0
            }
        }

        // ── Compact presentations ────────────────────────────────────────
        Item {
            id: compactLayer
            anchors.left: parent.left
            anchors.right: parent.right
            y: root.bottomEdge ? chassis.height - chassis.bottomInset - height : chassis.topInset
            height: root.compactHeight
            opacity: root.visualExpanded ? 0 : 1
            // Press feedback lives on the content, never on the clipping chassis:
            // transforming a ClippingRectangle live can leave it unpainted.
            scale: compactPress.pressed ? 0.93 : 1
            Behavior on scale { NumberAnimation { duration: IrisStyle.duration(compactPress.pressed ? 80 : 200); easing.type: Easing.OutCubic } }
            visible: opacity > 0
            // Out before the page arrives; back only once the chassis has
            // nearly reached its resting shape. The two layers never overlap.
            Behavior on opacity {
                id: compactFade
                SequentialAnimation {
                    PauseAnimation { duration: compactFade.targetValue > 0 ? root.collapseHold : 0 }
                    NumberAnimation {
                        duration: IrisStyle.duration(compactFade.targetValue > 0 ? 150 : 70)
                        easing.type: compactFade.targetValue > 0 ? Easing.OutCubic : Easing.OutQuad
                    }
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
                Glyph {
                    visible: root.clockStyle === "weather"
                    text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
                    iconSize: 16 * root.d
                    color: IrisStyle.subtext
                }
                IrisText {
                    visible: root.clockStyle === "weather"
                    text: String(Weather.data?.temp ?? "").replace(/[CF]$/, "")
                    role: IrisText.Meta
                    font.pixelSize: 12 * IrisStyle.typeScale
                    font.weight: Font.Medium
                }
                DateMark {
                    visible: root.clockStyle === "dateTime"
                    Layout.alignment: Qt.AlignVCenter
                }
                Item { Layout.fillWidth: true }
                IrisClock {
                    id: idleClock
                    Layout.alignment: Qt.AlignVCenter
                    pixelSize: 15 * IrisStyle.typeScale
                    opacity: clockFlight.hides(idleClock) ? 0 : 1
                }
            }

            CompactRow {
                mode: "media"
                IrisArtwork {
                    id: compactCover
                    opacity: coverFlight.hides(compactCover) ? 0 : 1
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
                            color: root.artTint
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
                IrisNumber {
                    text: root.clockText(RecorderStatus.elapsedSeconds)
                    color: IrisStyle.danger
                    pixelSize: 13 * IrisStyle.typeScale
                    weight: Font.DemiBold
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
                IrisNumber {
                    text: root.clockText(root.timerSeconds)
                    countDown: root.timerKind !== "stopwatch"
                    color: root.timerPaused ? IrisStyle.subtext : IrisStyle.secondaryAccent
                    pixelSize: 13 * IrisStyle.typeScale
                    weight: Font.DemiBold
                }
            }

            CompactRow {
                mode: "clock"
                Item { Layout.fillWidth: true }
                DateMark {
                    visible: root.clockStyle === "dateTime"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: 2 * root.d
                }
                Glyph {
                    visible: root.clockStyle === "weather"
                    text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
                    iconSize: 16 * root.d
                    color: IrisStyle.subtext
                }
                Tabular {
                    visible: root.clockStyle === "weather"
                    text: String(Weather.data?.temp ?? "").replace(/[CF]$/, "")
                    color: IrisStyle.subtext
                    font.pixelSize: 12 * IrisStyle.typeScale
                    font.weight: Font.Medium
                }
                IrisClock {
                    id: clusterClock
                    Layout.alignment: Qt.AlignVCenter
                    pixelSize: 15 * IrisStyle.typeScale
                    opacity: clockFlight.hides(clusterClock) ? 0 : 1
                }
                Item { Layout.fillWidth: true }
            }

            // Editing the desktop: accent pencil, what is happening, and the one
            // action that ends it (the whole resting shape is that action).
            CompactRow {
                mode: "edit"
                anchors.rightMargin: 5 * root.d
                Rectangle {
                    Layout.preferredWidth: Math.round(26 * root.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: width / 2
                    color: ColorUtils.applyAlpha(IrisStyle.accent, 0.18)
                    Glyph {
                        anchors.centerIn: parent
                        text: "edit"
                        iconSize: 15 * root.d
                        color: IrisStyle.accent
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: -1 * root.d
                    IrisText {
                        Layout.fillWidth: true
                        text: Translation.tr("Editing desktop")
                        font.pixelSize: 12.5 * IrisStyle.typeScale
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    IrisText {
                        Layout.fillWidth: true
                        text: Translation.tr("Drag widgets to arrange")
                        color: IrisStyle.muted
                        font.pixelSize: 10.5 * IrisStyle.typeScale
                        elide: Text.ElideRight
                    }
                }
                Rectangle {
                    Layout.preferredHeight: root.compactHeight - Math.round(10 * root.d)
                    Layout.preferredWidth: doneLabel.implicitWidth + Math.round(24 * root.d)
                    radius: height / 2
                    color: compactPress.containsMouse ? Qt.lighter(IrisStyle.accent, 1.08) : IrisStyle.accent
                    Behavior on color { ColorAnimation { duration: IrisStyle.duration(110) } }
                    IrisText {
                        id: doneLabel
                        anchors.centerIn: parent
                        text: Translation.tr("Done")
                        color: IrisStyle.onAccent
                        font.pixelSize: 12.5 * IrisStyle.typeScale
                        font.weight: Font.Bold
                    }
                }
            }

            // System event: identity-coloured glyph disc, what happened, and a
            // level ring with its figure when the event carries one.
            CompactRow {
                mode: "event"
                anchors.leftMargin: 6 * root.d
                Rectangle {
                    Layout.preferredWidth: root.compactHeight - Math.round(12 * root.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: width / 2
                    color: ColorUtils.applyAlpha(root.event.tint, 0.18)
                    Glyph {
                        anchors.centerIn: parent
                        text: root.event.icon
                        iconSize: 16 * root.d
                        color: root.event.tint
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: -1 * root.d
                    IrisText {
                        Layout.fillWidth: true
                        text: root.event.title
                        font.pixelSize: 12.5 * IrisStyle.typeScale
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    IrisText {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: root.event.detail
                        color: IrisStyle.muted
                        font.pixelSize: 10.5 * IrisStyle.typeScale
                        elide: Text.ElideRight
                    }
                }
                Metric {
                    visible: root.event.value >= 0
                    Layout.alignment: Qt.AlignVCenter
                    value: Math.round(root.event.value * 100)
                    unit: "%"
                    pixelSize: 14 * IrisStyle.typeScale
                    weight: Font.Bold
                    color: root.event.tint
                }
                ProgressRing {
                    visible: root.event.value >= 0
                    Layout.preferredWidth: Math.round(20 * root.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    progress: Math.max(0, root.event.value)
                    tint: root.event.tint
                }
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
                Item {
                    Layout.preferredWidth: 38 * root.d
                    Layout.fillHeight: true
                    Metric {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        value: Math.round(root.feedbackValue * 100)
                        unit: "%"
                        pixelSize: 14 * IrisStyle.typeScale
                        weight: Font.Bold
                        color: root.feedbackMuted ? IrisStyle.subtext : IrisStyle.text
                    }
                }
            }

            MouseArea {
                id: compactPress
                anchors.fill: parent
                enabled: !root.visualExpanded
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                hoverEnabled: root.compactMode === "edit"
                cursorShape: islandGrip.carrying ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                preventStealing: true
                Accessible.role: Accessible.Button
                Accessible.name: root.expanded ? Translation.tr("Collapse island") : Translation.tr("Expand island")
                // Holding the resting Island lifts it: carried to the other half of
                // the screen it moves the Island (and its Dock) to that edge.
                pressAndHoldInterval: 380
                QtObject {
                    id: islandGrip
                    property bool carrying: false
                    function publish(mouse, released: bool): void {
                        const p = compactPress.mapToItem(null, mouse.x, mouse.y)
                        GlobalStates.irisBubbleDrag = {
                            slot: "island", kind: "island", screen: root.targetScreen?.name ?? "",
                            x: p.x, y: p.y + root.screenOffsetY,
                            size: root.compactHeight, width: chassis.width, released: released
                        }
                    }
                }
                onPressAndHold: mouse => {
                    if (mouse.button !== Qt.LeftButton || root.compactMode === "edit") return
                    islandGrip.carrying = true
                    islandGrip.publish(mouse, false)
                }
                onPositionChanged: mouse => { if (islandGrip.carrying) islandGrip.publish(mouse, false) }
                onReleased: mouse => {
                    if (!islandGrip.carrying) return
                    islandGrip.publish(mouse, true)
                    Qt.callLater(() => islandGrip.carrying = false)
                }
                onCanceled: {
                    if (islandGrip.carrying && GlobalStates.irisBubbleDrag) {
                        GlobalStates.irisBubbleDrag = Object.assign({}, GlobalStates.irisBubbleDrag, { released: true })
                    }
                    islandGrip.carrying = false
                }
                onClicked: mouse => {
                    if (islandGrip.carrying) return
                    if (mouse.button === Qt.MiddleButton) {
                        if (root.hasMedia) MprisController.togglePlaying()
                        return
                    }
                    if (root.compactMode === "edit") { GlobalStates.setWidgetEditMode(false); return }
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
            // Opening, the page appears where it rests and the chassis grows around
            // it: scaling it in as well moved every part again after it had
            // arrived, a second travel on the settle tail. Closing may shrink it.
            scale: root.visualExpanded ? 1 : 0.96
            transformOrigin: root.bottomEdge ? Item.Bottom : Item.Top
            visible: opacity > 0
            enabled: root.expanded
            Behavior on opacity {
                id: detailsFade
                SequentialAnimation {
                    PauseAnimation { duration: detailsFade.targetValue > 0 ? IrisStyle.duration(70) : 0 }
                    NumberAnimation {
                        duration: IrisStyle.duration(detailsFade.targetValue > 0 ? 170 : 90)
                        easing.type: detailsFade.targetValue > 0 ? Easing.OutCubic : Easing.OutQuad
                    }
                }
            }
            Behavior on scale {
                enabled: !root.visualExpanded
                NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve }
            }

            // Navigation sits on the attached edge: pages grow and shrink away
            // from it, so switching pages never slides the row (and the next
            // click) out from under the pointer.
            sourceComponent: GridLayout {
                id: expandedContent
                columns: 1
                rowSpacing: 14 * root.d

                // Content replace: the chassis morphs to the next page's size while
                // the old content clears and the new one settles in from a
                // slightly smaller scale. A page whose material bleeds to the
                // chassis edges (wallpaper hero) only fades, so no edge shows.
                component Page: ColumnLayout {
                    id: pageItem
                    property string name: ""
                    property bool bleeds: false
                    readonly property bool current: root.effectivePage === pageItem.name
                    // Opening and closing the Island are the chassis' motion alone.
                    readonly property bool switching: root.visualExpanded && details.opacity >= 1
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    opacity: pageItem.current ? 1 : 0
                    scale: pageItem.current || pageItem.bleeds ? 1 : 0.97
                    transformOrigin: root.bottomEdge ? Item.Bottom : Item.Top
                    visible: opacity > 0
                    enabled: pageItem.current
                    // The new page waits for the old one to clear: two layouts never
                    // show through each other.
                    // Timing reads the Behavior's target: `current` may not have
                    // re-evaluated in these bindings yet when the fade starts.
                    Behavior on opacity {
                        id: pageFade
                        enabled: pageItem.switching
                        SequentialAnimation {
                            PauseAnimation { duration: pageFade.targetValue > 0 ? IrisStyle.duration(50) : 0 }
                            NumberAnimation {
                                duration: IrisStyle.duration(pageFade.targetValue > 0 ? 170 : 80)
                                easing.type: pageFade.targetValue > 0 ? Easing.OutCubic : Easing.OutQuad
                            }
                        }
                    }
                    Behavior on scale {
                        enabled: pageItem.switching
                        NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve }
                    }
                }

                Item {
                    id: pageStack
                    Layout.row: root.bottomEdge ? 0 : 1
                    Layout.fillWidth: true
                    implicitHeight: root.effectivePage === "media" ? mediaPage.implicitHeight
                        : root.effectivePage === "activity" ? activityPage.implicitHeight
                        : root.effectivePage === "tray" ? trayPage.implicitHeight
                        : root.effectivePage === "tools" ? toolsPage.implicitHeight
                        : desktopPage.implicitHeight

                    Page {
                        id: trayPage
                        name: "tray"
                        Flickable {
                            Layout.fillWidth: true
                            implicitHeight: Math.min(300 * root.d, trayContent.implicitHeight)
                            contentHeight: trayContent.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            IrisTray { id: trayContent; width: parent.width; bottomEdge: root.bottomEdge; items: root.trayItems }
                        }
                    }
                    Page {
                        id: toolsPage
                        name: "tools"
                        IrisTools {
                            Layout.fillWidth: true
                            onActivityRequested: root.page = "activity"
                        }
                    }

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
                                id: pageCover
                                opacity: coverFlight.hides(pageCover) ? 0 : 1
                                Component.onCompleted: root.pageCover = pageCover
                                Layout.preferredWidth: 68 * root.d
                                Layout.preferredHeight: 68 * root.d
                                source: MediaArtwork.displaySource
                                circular: Config.options?.iris?.player?.roundCover ?? true
                                radius: circular ? width / 2 : 16 * root.d
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2 * root.d
                                // Long titles take a second line before they elide.
                                IrisText {
                                    Layout.fillWidth: true
                                    text: media.effectiveTitle
                                    font.pixelSize: 15 * IrisStyle.typeScale
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
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
                                // The activity's own colour: progress wears the artwork tint
                                // like the waveform (plain text for greyscale covers).
                                fillColor: root.artTint
                                trackColor: ColorUtils.applyAlpha(root.artTint, 0.2)
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

                        // Everything else that makes sound: other players (paused ones
                        // included) to take over the page, and each app's own level.
                        readonly property var otherPlayers: (MprisController.displayPlayers ?? []).filter(p => p && p !== root.player)
                        // One row per app: a browser with several tabs playing is one level.
                        readonly property var streams: {
                            const groups = []
                            for (const node of (Audio.outputAppNodes ?? [])) {
                                if (!node?.audio) continue
                                const name = Audio.appNodeDisplayName(node)
                                const group = groups.find(g => g.name === name)
                                if (group) group.nodes.push(node)
                                else groups.push({ name: name, nodes: [node] })
                            }
                            return groups
                        }
                        Rectangle {
                            visible: mediaPage.otherPlayers.length > 0 || mediaPage.streams.length > 0
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: IrisStyle.hairline
                        }
                        Flow {
                            visible: mediaPage.otherPlayers.length > 0
                            Layout.fillWidth: true
                            spacing: 6 * root.d
                            Repeater {
                                model: mediaPage.otherPlayers
                                IrisButton {
                                    id: playerChip
                                    required property var modelData
                                    implicitHeight: Math.round(32 * root.d)
                                    implicitWidth: chipRow.implicitWidth + Math.round(20 * root.d)
                                    buttonRadius: height / 2
                                    buttonRadiusPressed: height / 2
                                    colBackground: ColorUtils.applyAlpha(IrisStyle.text, 0.08)
                                    colBackgroundHover: ColorUtils.applyAlpha(IrisStyle.text, 0.16)
                                    Accessible.name: Translation.tr("Control %1").arg(playerChip.modelData?.identity ?? "")
                                    onClicked: MprisController.setActivePlayer(playerChip.modelData)
                                    RowLayout {
                                        id: chipRow
                                        anchors.centerIn: parent
                                        spacing: 6 * root.d
                                        IrisArtwork {
                                            Layout.preferredWidth: Math.round(20 * root.d)
                                            Layout.preferredHeight: Layout.preferredWidth
                                            source: String(playerChip.modelData?.trackArtUrl ?? "")
                                        }
                                        IrisText {
                                            text: String(playerChip.modelData?.trackTitle || playerChip.modelData?.identity || "")
                                            font.pixelSize: 11.5 * IrisStyle.typeScale
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                            Layout.maximumWidth: Math.round(150 * root.d)
                                        }
                                        Glyph {
                                            text: playerChip.modelData?.isPlaying ? "graphic_eq" : "pause"
                                            iconSize: 14 * root.d
                                            color: playerChip.modelData?.isPlaying ? root.artTint : IrisStyle.muted
                                        }
                                    }
                                }
                            }
                        }
                        Repeater {
                            model: mediaPage.streams.slice(0, 4)
                            RowLayout {
                                id: appLevel
                                required property var modelData
                                readonly property var nodes: appLevel.modelData.nodes
                                readonly property bool muted: appLevel.nodes.every(node => node?.audio?.muted)
                                Layout.fillWidth: true
                                spacing: 10 * root.d
                                Image {
                                    Layout.preferredWidth: Math.round(22 * root.d)
                                    Layout.preferredHeight: Layout.preferredWidth
                                    sourceSize: Qt.size(Math.round(44 * root.d), Math.round(44 * root.d))
                                    source: Quickshell.iconPath(MprisController.streamIconName(appLevel.nodes[0]), "audio-x-generic")
                                    opacity: appLevel.muted ? 0.45 : 1
                                }
                                IrisText {
                                    Layout.preferredWidth: Math.round(110 * root.d)
                                    text: appLevel.nodes.length > 1 ? appLevel.modelData.name + " · " + appLevel.nodes.length : appLevel.modelData.name
                                    color: ColorUtils.applyAlpha(IrisStyle.text, appLevel.muted ? 0.45 : 0.8)
                                    font.pixelSize: 12 * IrisStyle.typeScale
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                                IrisScrubber {
                                    Layout.fillWidth: true
                                    fillColor: appLevel.muted ? IrisStyle.muted : IrisStyle.text
                                    value: Math.min(1, Math.max(...appLevel.nodes.map(node => node?.audio?.volume ?? 0)))
                                    onMoved: next => appLevel.nodes.forEach(node => { if (node?.audio) node.audio.volume = next })
                                }
                                GlyphButton {
                                    glyph: appLevel.muted ? "volume_off" : "volume_up"
                                    glyphSize: 17 * root.d
                                    implicitWidth: Math.round(30 * root.d)
                                    glyphColor: appLevel.muted ? IrisStyle.danger : IrisStyle.text
                                    Accessible.name: appLevel.muted ? Translation.tr("Unmute") : Translation.tr("Mute")
                                    onClicked: {
                                        const mute = !appLevel.muted
                                        appLevel.nodes.forEach(node => { if (node?.audio) node.audio.muted = mute })
                                    }
                                }
                            }
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
                            IrisNumber {
                                text: root.clockText(RecorderStatus.elapsedSeconds)
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
                            IrisNumber {
                                text: root.clockText(root.timerSeconds)
                                countDown: root.timerKind !== "stopwatch"
                                color: root.timerPaused ? IrisStyle.subtext : IrisStyle.secondaryAccent
                                pixelSize: 28 * IrisStyle.typeScale
                                weight: Font.Bold
                                letterSpacing: -0.6
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
                        bleeds: desktopPage.showBanner
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
                        readonly property string bannerSource: String(root.options?.desktopBanner ?? "wallpaper") === "wallpaper"
                            ? WallpaperListener.wallpaperUrlForScreen(root.targetScreen) : ""
                        readonly property bool showBanner: desktopPage.bannerSource.length > 0
                        readonly property bool showProfile: root.options?.desktopProfile ?? true

                        // Hero: time and weather over this output's wallpaper. The image
                        // bleeds to the chassis edges (the chassis clips it) and melts
                        // into the black body, so it reads as the Island's own material
                        // rather than a card inside it.
                        Item {
                            id: hero
                            Layout.fillWidth: true
                            implicitHeight: desktopPage.showBanner
                                ? Math.max(Math.round(112 * root.d), heroRow.implicitHeight + Math.round(26 * root.d))
                                : heroRow.implicitHeight

                            Item {
                                id: heroBleed
                                visible: desktopPage.showBanner
                                // The navigation above a top Island's pages sits on the
                                // melt, which stays dark enough behind its glyphs.
                                readonly property real navBand: root.bottomEdge ? 0 : navRow.height + expandedContent.rowSpacing
                                readonly property real topBleed: root.padding + chassis.topInset + heroBleed.navBand
                                // Fades as one picture: faded separately, the image shows
                                // through the black scrim and the band reads as a vignette.
                                layer.enabled: desktopPage.opacity > 0 && desktopPage.opacity < 1
                                // Image and scrim arrive together: the vignette never shows
                                // over an empty chassis while the picture loads.
                                opacity: heroImage.status === Image.Ready ? 1 : 0
                                x: -root.padding
                                y: -heroBleed.topBleed
                                width: hero.width + root.padding * 2
                                height: hero.height + heroBleed.topBleed + Math.round(12 * root.d)

                                Image {
                                    id: heroImage
                                    anchors.fill: parent
                                    source: desktopPage.showBanner ? desktopPage.bannerSource : ""
                                    fillMode: Image.PreserveAspectCrop
                                    // Decoded ahead by heroPreload (same source and size), so
                                    // this reads the cache on the page's first frame instead of
                                    // showing the scrim alone while it decodes.
                                    asynchronous: heroPreload.status !== Image.Ready
                                    cache: true
                                    smooth: true
                                    sourceSize.width: root.heroDecodeWidth
                                }
                                // A notch hangs from the screen edge: the image starts in black
                                // so the concave fillets beside it stay continuous.
                                Rectangle {
                                    id: heroScrim
                                    anchors.fill: parent
                                    readonly property bool hangs: (root.notch && !root.bottomEdge) || heroBleed.navBand > 0
                                    readonly property real solidTop: (root.notch && !root.bottomEdge ? chassis.topInset : 0)
                                        + (heroBleed.navBand > 0 ? root.padding + heroBleed.navBand * 0.5 : 0)
                                    readonly property real edge: hangs ? solidTop / Math.max(1, height) : 0
                                    readonly property real topFade: hangs ? (solidTop + 30 * root.d + heroBleed.navBand * 0.5) / Math.max(1, height) : 0.001
                                    gradient: Gradient {
                                        GradientStop { position: 0; color: ColorUtils.applyAlpha(IrisStyle.surface, heroScrim.hangs ? 1 : 0.12) }
                                        GradientStop { position: heroScrim.edge; color: ColorUtils.applyAlpha(IrisStyle.surface, heroScrim.hangs ? 1 : 0.12) }
                                        GradientStop { position: heroScrim.topFade; color: ColorUtils.applyAlpha(IrisStyle.surface, 0.12) }
                                        GradientStop { position: 0.42; color: ColorUtils.applyAlpha(IrisStyle.surface, 0.2) }
                                        GradientStop { position: 1; color: IrisStyle.surface }
                                    }
                                }
                            }

                            // The wallpaper shown here is also the way to change it.
                            GlyphButton {
                                visible: desktopPage.showBanner
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.topMargin: -Math.round(6 * root.d)
                                glyph: "wallpaper"
                                glyphSize: 17 * root.d
                                implicitWidth: Math.round(32 * root.d)
                                colBackground: ColorUtils.applyAlpha(IrisStyle.surface, 0.42)
                                colBackgroundHover: ColorUtils.applyAlpha(IrisStyle.surface, 0.62)
                                Accessible.name: Translation.tr("Change wallpaper")
                                onClicked: {
                                    GlobalStates.wallpaperSelectorTargetMonitor = root.targetScreen?.name ?? ""
                                    GlobalStates.wallpaperSelectorOpen = true
                                }
                            }

                            RowLayout {
                                id: heroRow
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                spacing: 12 * root.d
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignBottom
                                    spacing: -2 * root.d
                                    IrisText {
                                        // Weekday carries the accent above the figure, like a
                                        // calendar leaf; the rest of the date stays quiet.
                                        textFormat: Text.StyledText
                                        text: "<font color='" + IrisStyle.secondaryAccent + "'><b>"
                                            + Qt.locale().toString(DateTime.clock.date, "dddd") + "</b></font> "
                                            + Qt.locale().toString(DateTime.clock.date, "d MMMM")
                                        color: ColorUtils.applyAlpha(IrisStyle.text, desktopPage.showBanner ? 0.82 : 0.62)
                                        font.pixelSize: 13 * IrisStyle.typeScale
                                        font.weight: Font.Medium
                                    }
                                    IrisClock {
                                        id: heroClock
                                        pixelSize: 46 * IrisStyle.typeScale
                                        opacity: clockFlight.hides(heroClock) ? 0 : 1
                                        Component.onCompleted: root.heroClock = heroClock
                                    }
                                }
                                ColumnLayout {
                                    visible: desktopPage.weatherReady
                                    Layout.alignment: Qt.AlignBottom
                                    spacing: 0
                                    RowLayout {
                                        Layout.alignment: Qt.AlignRight
                                        spacing: 6 * root.d
                                        Glyph {
                                            text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
                                            iconSize: 22 * root.d
                                        }
                                        Metric {
                                            readonly property string raw: String(Weather.data?.temp ?? "")
                                            value: raw.replace(/°?[CF]$/, "")
                                            unit: raw.length > value.length ? raw.slice(value.length) : ""
                                            pixelSize: 26 * IrisStyle.typeScale
                                            weight: Font.DemiBold
                                        }
                                    }
                                    IrisText {
                                        Layout.alignment: Qt.AlignRight
                                        Layout.maximumWidth: 150 * root.d
                                        text: String(Weather.data?.description ?? "")
                                        color: ColorUtils.applyAlpha(IrisStyle.text, desktopPage.showBanner ? 0.78 : 0.6)
                                        font.pixelSize: 12 * IrisStyle.typeScale
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        // Who is signed in. The avatar is the editor: click to choose a
                        // picture (AccountsService, same path as Material's Settings).
                        RowLayout {
                            Layout.fillWidth: true
                            visible: desktopPage.showProfile
                            spacing: 11 * root.d

                            Item {
                                id: avatar
                                Layout.preferredWidth: Math.round(40 * root.d)
                                Layout.preferredHeight: Layout.preferredWidth
                                property int sourceIndex: 0
                                readonly property string primarySource: Directories.userAvatarSourcePrimary
                                onPrimarySourceChanged: avatar.sourceIndex = 0
                                Accessible.role: Accessible.Button
                                Accessible.name: Translation.tr("Change profile picture")

                                HoverHandler { id: avatarHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { gesturePolicy: TapHandler.WithinBounds; onTapped: root.chooseAvatar() }

                                ClippingRectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: ColorUtils.applyAlpha(IrisStyle.text, 0.12)
                                    scale: avatarHover.hovered ? 1.05 : 1
                                    Behavior on scale { NumberAnimation { duration: IrisStyle.duration(120); easing.type: Easing.OutCubic } }

                                    Image {
                                        id: avatarImage
                                        anchors.fill: parent
                                        source: Directories.avatarSourceAt(avatar.sourceIndex)
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        smooth: true
                                        sourceSize.width: avatar.width * 2
                                        sourceSize.height: avatar.height * 2
                                        onStatusChanged: {
                                            if (status === Image.Error && avatar.sourceIndex + 1 < Directories.userAvatarPaths.length)
                                                Qt.callLater(() => avatar.sourceIndex++)
                                        }
                                    }
                                    IrisText {
                                        anchors.centerIn: parent
                                        visible: avatarImage.status !== Image.Ready
                                        text: (SystemInfo.displayName || SystemInfo.username || "?").charAt(0).toUpperCase()
                                        font.pixelSize: 17 * IrisStyle.typeScale
                                        font.weight: Font.DemiBold
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        color: ColorUtils.applyAlpha(IrisStyle.surface, avatarHover.hovered ? 0.5 : 0)
                                        Behavior on color { ColorAnimation { duration: IrisStyle.duration(120) } }
                                        Glyph {
                                            anchors.centerIn: parent
                                            text: "edit"
                                            iconSize: 17 * root.d
                                            opacity: avatarHover.hovered ? 1 : 0
                                            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120) } }
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                IrisText {
                                    Layout.fillWidth: true
                                    text: SystemInfo.displayName || SystemInfo.username || "user"
                                    font.pixelSize: 13.5 * IrisStyle.typeScale
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                IrisText {
                                    Layout.fillWidth: true
                                    readonly property string distro: String(SystemInfo.distroId ?? "").trim()
                                    text: (SystemInfo.username || "user")
                                        + (distro.length > 0 && distro !== "unknown" ? "@" + distro : "")
                                        + " · " + Translation.tr("Up %1").arg(DateTime.uptime)
                                    color: ColorUtils.applyAlpha(IrisStyle.text, 0.55)
                                    font.pixelSize: 11.5 * IrisStyle.typeScale
                                    elide: Text.ElideRight
                                }
                            }

                            GlyphButton {
                                glyph: "lock"
                                glyphSize: 18 * root.d
                                implicitWidth: Math.round(34 * root.d)
                                colBackground: ColorUtils.applyAlpha(IrisStyle.text, 0.08)
                                colBackgroundHover: ColorUtils.applyAlpha(IrisStyle.text, 0.16)
                                Accessible.name: Translation.tr("Lock")
                                onClicked: {
                                    root.expanded = false
                                    Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "lock", "activate"])
                                }
                            }
                            GlyphButton {
                                glyph: "power_settings_new"
                                glyphSize: 18 * root.d
                                implicitWidth: Math.round(34 * root.d)
                                colBackground: ColorUtils.applyAlpha(IrisStyle.text, 0.08)
                                colBackgroundHover: ColorUtils.applyAlpha(IrisStyle.danger, 0.22)
                                Accessible.name: Translation.tr("Session")
                                onClicked: { root.expanded = false; GlobalStates.sessionOpen = true }
                            }
                        }

                        // Where you are: the workspace's active app, its workspace, and the
                        // output's workspaces as page dots (active one in the accent).
                        RowLayout {
                            id: contextRow
                            Layout.fillWidth: true
                            visible: desktopPage.focusedWindow !== null || desktopPage.workspaces.length > 1
                            spacing: 11 * root.d

                            readonly property string workspaceName: desktopPage.activeWorkspace
                                ? (String(desktopPage.activeWorkspace.name ?? "").length > 0
                                    ? desktopPage.activeWorkspace.name
                                    : Translation.tr("Workspace %1").arg(desktopPage.activeWorkspace.idx))
                                : ""
                            readonly property var entry: AppSearch.lookupDesktopEntry(desktopPage.focusedWindow?.app_id ?? "")

                            // Same slot as the avatar above, so both text columns share an edge.
                            Item {
                                visible: desktopPage.focusedWindow !== null
                                Layout.preferredWidth: Math.round(40 * root.d)
                                Layout.preferredHeight: Math.round(30 * root.d)
                                SmartAppIcon {
                                    anchors.centerIn: parent
                                    icon: contextRow.entry?.icon ?? (desktopPage.focusedWindow?.app_id ?? "")
                                    fallback: "application-x-executable"
                                    iconSize: Math.round(28 * root.d)
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                IrisText {
                                    Layout.fillWidth: true
                                    text: desktopPage.focusedWindow ? String(desktopPage.focusedWindow.title ?? "") : contextRow.workspaceName
                                    font.pixelSize: 13 * IrisStyle.typeScale
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                IrisText {
                                    Layout.fillWidth: true
                                    readonly property string app: contextRow.entry?.name ?? String(desktopPage.focusedWindow?.app_id ?? "")
                                    text: desktopPage.focusedWindow
                                        ? app + (contextRow.workspaceName.length > 0 ? " · " + contextRow.workspaceName : "")
                                        : Translation.tr("No windows")
                                    color: ColorUtils.applyAlpha(IrisStyle.text, 0.55)
                                    font.pixelSize: 11.5 * IrisStyle.typeScale
                                    elide: Text.ElideRight
                                }
                            }
                            Row {
                                visible: desktopPage.workspaces.length > 1
                                spacing: 2 * root.d
                                Repeater {
                                    model: desktopPage.workspaces
                                    MouseArea {
                                        id: dot
                                        required property var modelData
                                        readonly property bool active: dot.modelData.is_active
                                        readonly property bool occupied: (NiriService.windows ?? []).some(w => w.workspace_id === dot.modelData.id)
                                        width: indicator.width + 6 * root.d
                                        height: 20 * root.d
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        Accessible.role: Accessible.Button
                                        Accessible.name: Translation.tr("Workspace %1").arg(dot.modelData.idx)
                                        onClicked: NiriService.switchToWorkspaceById(dot.modelData.id)
                                        Rectangle {
                                            id: indicator
                                            anchors.centerIn: parent
                                            width: dot.active ? 20 * root.d : 7 * root.d
                                            height: 7 * root.d
                                            radius: height / 2
                                            color: dot.active ? IrisStyle.accent
                                                : ColorUtils.applyAlpha(IrisStyle.text, dot.containsMouse ? 0.7 : dot.occupied ? 0.45 : 0.2)
                                            Behavior on width { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
                                            Behavior on color { ColorAnimation { duration: IrisStyle.duration(120) } }
                                        }
                                    }
                                }
                            }
                        }

                        // Vitals: how the machine is doing, the one thing Control Center
                        // does not show. Rings turn red past their warning level.
                        Rectangle {
                            id: vitals
                            Layout.fillWidth: true
                            implicitHeight: Math.round(44 * root.d)
                            radius: 14 * root.d
                            color: ColorUtils.applyAlpha(IrisStyle.text, 0.07)
                            // Sensors poll only while this page is on screen.
                            readonly property bool polling: desktopPage.current && root.visualExpanded
                            property bool holdingSensors: false
                            onPollingChanged: {
                                if (polling && !holdingSensors) { ResourceUsage.keepAlive(); holdingSensors = true }
                                else if (!polling && holdingSensors) { ResourceUsage.releaseKeepAlive(); holdingSensors = false }
                            }
                            Component.onDestruction: if (holdingSensors) ResourceUsage.releaseKeepAlive()

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Math.round(10 * root.d)
                                anchors.rightMargin: Math.round(10 * root.d)
                                spacing: 6 * root.d
                                Repeater {
                                    model: [
                                        { label: Translation.tr("CPU"), glyph: "memory", level: ResourceUsage.cpuUsage, value: Math.round(ResourceUsage.cpuUsage * 100), unit: "%", warn: 0.85 },
                                        { label: Translation.tr("Memory"), glyph: "memory_alt", level: ResourceUsage.memoryUsedPercentage, value: Math.round(ResourceUsage.memoryUsedPercentage * 100), unit: "%", warn: 0.85 },
                                        { label: Translation.tr("Heat"), glyph: "device_thermostat", level: ResourceUsage.tempPercentage, value: ResourceUsage.maxTemp, unit: "°", warn: ResourceUsage.tempWarningThreshold / 100 },
                                        { label: Translation.tr("Disk"), glyph: "hard_drive", level: ResourceUsage.diskUsedPercentage, value: Math.round(ResourceUsage.diskUsedPercentage * 100), unit: "%", warn: 0.9 }
                                    ]
                                    RowLayout {
                                        id: vital
                                        required property var modelData
                                        readonly property real level: Math.max(0, Math.min(1, Number(vital.modelData.level) || 0))
                                        readonly property color tint: vital.level >= vital.modelData.warn ? IrisStyle.danger : IrisStyle.accent
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        spacing: 6 * root.d
                                        Accessible.name: vital.modelData.label + ", " + vital.modelData.value + vital.modelData.unit
                                        Item {
                                            Layout.preferredWidth: Math.round(26 * root.d)
                                            Layout.preferredHeight: Layout.preferredWidth
                                            ProgressRing {
                                                anchors.fill: parent
                                                stroke: Math.max(2, 2.2 * root.d)
                                                tint: vital.tint
                                                progress: vital.level
                                                Behavior on progress { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.OutCubic } }
                                            }
                                            Glyph {
                                                anchors.centerIn: parent
                                                text: vital.modelData.glyph
                                                iconSize: 12 * root.d
                                                color: vital.tint
                                            }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: -2 * root.d
                                            IrisText {
                                                Layout.fillWidth: true
                                                text: vital.modelData.label
                                                color: IrisStyle.muted
                                                font.pixelSize: 9.5 * IrisStyle.typeScale
                                                font.weight: Font.Medium
                                                elide: Text.ElideRight
                                            }
                                            Metric {
                                                value: vital.modelData.value
                                                unit: vital.modelData.unit
                                                pixelSize: 12.5 * IrisStyle.typeScale
                                                weight: Font.Bold
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // User extensions from the bar slots keep a place here.
                        Flow {
                            Layout.fillWidth: true
                            visible: desktopPage.customModules.length > 0
                            spacing: 6 * root.d
                            Repeater {
                                model: desktopPage.customModules
                                IrisCustomModule {
                                    required property string modelData
                                    widgetId: modelData.slice("custom:".length)
                                    targetScreen: root.targetScreen
                                    slot: "island.desktop"
                                }
                            }
                        }
                    }
                }

                // Page navigation shared by every expanded presentation.
                RowLayout {
                    id: navRow
                    Layout.row: root.bottomEdge ? 1 : 0
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4 * root.d

                    component NavButton: IrisButton {
                        id: nav
                        property string glyph: ""
                        property string target: ""
                        selected: nav.target.length > 0 && root.effectivePage === nav.target
                        quiet: !nav.selected
                        implicitWidth: Math.round(36 * root.d)
                        implicitHeight: Math.round(30 * root.d)
                        buttonRadius: height / 2
                        buttonRadiusPressed: height / 2
                        colBackgroundHover: ColorUtils.applyAlpha(IrisStyle.text, 0.13)
                        onClicked: if (nav.target.length > 0) root.page = nav.target
                        Glyph {
                            anchors.centerIn: parent
                            text: nav.glyph
                            fill: nav.selected ? 1 : 0
                            iconSize: 18 * root.d
                            color: nav.selected ? IrisStyle.accent : ColorUtils.applyAlpha(IrisStyle.text, 0.6)
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
                    NavButton { glyph: "apps"; target: "tray"; Accessible.name: Translation.tr("Tray") }
                    NavButton { glyph: "timer"; target: "tools"; Accessible.name: Translation.tr("Timers") }
                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 14 * root.d
                        Layout.leftMargin: 4 * root.d
                        Layout.rightMargin: 4 * root.d
                        color: ColorUtils.applyAlpha(IrisStyle.text, 0.14)
                    }
                    NavButton {
                        visible: Config.options?.iris?.sidebars?.left?.enable ?? true
                        glyph: "left_panel_open"
                        Accessible.name: Translation.tr("Focus panel")
                        onClicked: { root.expanded = false; GlobalStates.openSidebarLeft(root.targetScreen?.name ?? "") }
                    }
                    NavButton {
                        visible: Config.options?.iris?.sidebars?.right?.enable ?? true
                        glyph: "right_panel_open"
                        Accessible.name: Translation.tr("Today panel")
                        onClicked: { root.expanded = false; GlobalStates.openSidebarRight(root.targetScreen?.name ?? "") }
                    }
                    NavButton {
                        glyph: "tune"
                        Accessible.name: Translation.tr("Quick controls")
                        onClicked: root.openControlCenterFrom(chassis)
                    }
                    NavButton {
                        glyph: "settings"
                        Accessible.name: Translation.tr("Settings")
                        onClicked: root.openSettingsFrom(chassis)
                    }
                }
            }
        }
    }
}
