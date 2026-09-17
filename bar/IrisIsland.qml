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
import qs.modules.iris.bar.island

Item {
    id: root

    property var targetScreen
    property real availableWidth: 800
    property real compactHeight: 42
    property bool expanded: false
    property bool pinned: false
    property string page: ""

    readonly property real d: IrisStyle.density
    readonly property var options: Config.options?.iris?.bar ?? ({})

    readonly property var desktopBlockKinds: ["profile", "context", "forecast", "agenda", "vitals", "modules"]
    readonly property var desktopBlocks: Array.from(root.options?.desktopBlocks ?? root.desktopBlockKinds)
        .filter(kind => root.desktopBlockKinds.includes(kind))
    function desktopBlockLabel(kind: string): string {
        return ({ profile: Translation.tr("Profile"), context: Translation.tr("Current app"),
            forecast: Translation.tr("Forecast"), agenda: Translation.tr("Up next"),
            vitals: Translation.tr("Vitals"), modules: Translation.tr("Modules") })[kind] ?? kind
    }
    function setDesktopBlock(kind: string, on: bool): void {
        const next = root.desktopBlocks.filter(entry => entry !== kind)
        if (on) next.push(kind)
        Config.setNestedValue("iris.bar.desktopBlocks", next)
    }
    function desktopBlockGlyph(kind: string): string {
        return ({ profile: "account_circle", context: "select_window", forecast: "partly_cloudy_day",
            agenda: "event_upcoming", vitals: "monitor_heart", modules: "widgets" })[kind] ?? "add"
    }
    function moveDesktopBlock(kind: string, step: int): void {
        const next = root.desktopBlocks.slice()
        const from = next.indexOf(kind)
        const to = Math.max(0, Math.min(next.length - 1, from + step))
        if (from < 0 || to === from) return
        next.splice(to, 0, next.splice(from, 1)[0])
        Config.setNestedValue("iris.bar.desktopBlocks", next)
    }
    readonly property real studioHandlesWidth: Math.round(40 * root.d)
    property string arrangeKind: ""
    property real arrangeTravel: 0
    property int arrangeSteps: 0
    property real arrangeSpan: 0
    readonly property bool studio: GlobalStates.irisArrange && root.focusedOutput && root.visualExpanded
        && root.effectivePage === "desktop"
    Connections {
        target: root
        function onVisualExpandedChanged(): void { if (!root.visualExpanded && root.focusedOutput) GlobalStates.irisArrange = false }
    }
    readonly property bool notch: root.options?.notch ?? false
    property bool bottomEdge: String(root.options?.position ?? "top") === "bottom"

    readonly property var player: MprisController.activePlayer
    readonly property bool hasMedia: root.player !== null && root.player !== undefined
        && String(root.player.trackTitle ?? "").length > 0
    readonly property bool ytMusic: root.hasMedia && MprisController._isYtMusicMpv(root.player)
    readonly property string title: root.ytMusic ? YtMusic.currentTitle : String(root.player?.trackTitle ?? "")
    readonly property bool playing: root.hasMedia && (root.ytMusic ? YtMusic.isPlaying : (root.player?.isPlaying ?? false))
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

    function openPage(nextPage: string, pin: bool, origin): void {
        root.page = nextPage
        root.pageOrigin = origin ?? null
        if (origin) root.pageOriginX = -1
        if (pin) root.pinned = true
        root.expanded = true
    }
    property real pageOriginX: -1

    property real screenOffsetY: 0
    function publishOrigin(part): void {
        if (root.targetScreen?.name !== GlobalStates.focusedScreen?.name) return
        if (root.suppressed || !part?.visible) { GlobalStates.irisMorphOrigin = null; return }
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
        if (bubbleWheel.running) return
        if (!(Config.options?.iris?.modules?.osd ?? true) || root.expanded
            || root.targetScreen?.name !== GlobalStates.focusedScreen?.name) return
        root.feedbackKind = kind
        feedbackTimer.restart()
    }

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
            root.showEvent("bluetooth_connected", IrisStyle.identity.blue, String(device.name ?? Translation.tr("Device")), Translation.tr("Connected"),
                device.batteryAvailable ? device.battery : -1)
        else if (root.lastBluetoothCount > root.bluetoothCount)
            root.showEvent("bluetooth_disabled", IrisStyle.subtext, Translation.tr("Bluetooth"), Translation.tr("Device disconnected"), -1)
        root.lastBluetoothCount = root.bluetoothCount
    }
    Connections {
        target: root.eventsEnabled ? Notifications : null
        function onSilentChanged(): void {
            root.showEvent(Notifications.silent ? "do_not_disturb_on" : "notifications_active",
                Notifications.silent ? IrisStyle.identity.lavender : IrisStyle.text, Translation.tr("Do not disturb"),
                Notifications.silent ? Translation.tr("On") : Translation.tr("Off"), -1)
        }
    }
    Connections {
        target: root.eventsEnabled ? TimerService : null
        function onCountdownRunningChanged(): void {
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

    readonly property bool visualExpanded: root.expanded && details.status === Loader.Ready
    readonly property real bubble: root.compactHeight
    readonly property real satelliteGap: Math.round(Math.max(0, Math.min(24, Number(Config.options?.iris?.bar?.satelliteGap ?? 6))) * root.d)
    readonly property real satelliteOffset: root.satelliteGap + (root.notch ? Math.round(IrisStyle.fuseEdge / 4) : 0)
    readonly property real fillet: root.notch ? Math.round(chassis.radius * 0.62) : 0
    readonly property real expandedWidth: Math.min(root.availableWidth - 2 * (root.bubble + root.satelliteGap),
        (root.effectivePage === "activity" ? 384 : 440) * root.d)
    readonly property real padding: Math.round(20 * root.d)
    readonly property bool editingDesktop: GlobalStates.widgetEditMode
        && root.targetScreen?.name === GlobalStates.focusedScreen?.name
    readonly property string compactMode: root.feedback && !root.anchored ? "feedback"
        : root.eventShown && !root.anchored ? "event"
        : root.editingDesktop ? "edit"
        : IrisStyle.cluster ? "clock" : root.primary
    readonly property string layout: String(root.options?.layout ?? "island")
    readonly property bool fullWidth: root.layout === "full"
    readonly property real fullChassisWidth: Math.max(0,
        root.availableWidth - 2 * Math.max(root.sideReserveTarget, root.fillet))
    readonly property bool anchored: root.fullWidth
    readonly property bool inlineExpanded: root.visualExpanded && !root.anchored
    readonly property bool compactSizeClass: root.compactMode === "feedback" || root.compactMode === "event"
    readonly property bool spanning: root.anchored || (root.fullWidth && !root.compactSizeClass && !root.visualExpanded)
    readonly property var compactRows: ({ idle: idleRow, media: mediaRow, record: recordRow,
        timer: timerRow, clock: clockRow, edit: editRow, event: eventRow, feedback: feedbackRow })
    readonly property real compactContentWidth: root.compactRows[root.compactMode]?.implicitWidth ?? 0
    readonly property real compactFloor: root.compactHeight * 2.1
    readonly property real compactCeiling: Math.min(root.availableWidth,
        (root.compactMode === "media" ? 380 : root.compactMode === "event" ? 330 : 320) * root.d)
    readonly property real compactTargetWidth: root.spanning ? root.fullChassisWidth
        : Math.max(root.compactFloor, Math.min(root.compactCeiling,
            root.compactContentWidth + Math.round(29 * root.d) + root.barPieceReserve))
    readonly property real chassisTargetWidth: root.inlineExpanded ? root.expandedWidth : root.compactTargetWidth
    readonly property string clockStyle: {
        const style = String(root.options?.clockStyle ?? "dateTime")
        return style === "weather" && !(Weather.enabled && !String(Weather.data?.temp ?? "--").startsWith("--")) ? "time" : style
    }
    readonly property string trailing: String(root.options?.trailing ?? "controls")
    readonly property string trailingKind: root.trailing === "notifications" && (Notifications.list?.length ?? 0) === 0 ? "none" : root.trailing
    readonly property bool leftSatelliteShown: IrisStyle.cluster && !root.inlineExpanded && !root.feedback && !root.eventShown
        && !root.floatingSlots.includes("left")
        && root.primary !== "idle"
    readonly property bool rightSatelliteShown: !root.inlineExpanded && !root.feedback && !root.eventShown
        && !root.floatingSlots.includes("right")
        && (IrisStyle.cluster ? root.trailingKind !== "none" : root.secondary.length > 0)

    readonly property var trayItems: SystemTray.items.values.filter(item => item && item.id
        && (!(Config.options?.iris?.tray?.hidePassive ?? false) || item.status !== Status.Passive))
    readonly property string auxiliary: String(root.options?.auxiliary ?? "tray")
    readonly property int auxiliarySlot: (IrisStyle.cluster ? root.trailingKind !== "none" : root.secondary.length > 0)
        && !root.floatingSlots.includes("right") ? 2 : 1
    readonly property bool auxiliaryShown: !root.inlineExpanded && !root.feedback && !root.eventShown && root.auxiliary !== "none"
        && !root.floatingSlots.includes("utility")
        && (root.auxiliary !== "tray" || root.trayItems.length > 0)
    function pieceTaken(kind: string): bool {
        if (Config.options?.iris?.bubbles?.extras?.[kind]?.enable ?? false) return true
        if (root.auxiliaryShown && root.auxiliary === kind) return true
        if (root.rightSatelliteShown && IrisStyle.cluster && root.trailingKind === kind) return true
        return root.leftSatelliteShown && kind === "media"
    }
    readonly property var barPieces: Array.from(root.options?.pieces ?? [])
        .filter(kind => IrisPieces.extraIds.includes(kind) && IrisPieces.available(kind) && !root.pieceTaken(kind))
    readonly property real barPieceSize: Math.round(root.compactHeight - 10 * root.d)
    readonly property real barPieceGap: Math.round(6 * root.d)
    readonly property real barPieceReserve: root.barPieces.length === 0 ? 0
        : root.barPieces.length * root.barPieceSize
            + (root.barPieces.length - 1) * root.barPieceGap + Math.round(13 * root.d)

    readonly property real sideReserveTarget: root.auxiliaryShown
        ? root.auxiliarySlot * (root.bubble + root.satelliteOffset)
        : root.leftSatelliteShown || root.rightSatelliteShown ? root.bubble + root.satelliteOffset : root.fillet
    property real sideReserve: root.sideReserveTarget
    Behavior on sideReserve { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.moveCurve } }

    property Item pageOrigin: null
    property string extensionRole: "page"
    readonly property string wantedRole: root.visualExpanded ? "page"
        : root.feedback ? "feedback"
        : root.eventShown ? "event" : ""
    onWantedRoleChanged: if (root.wantedRole.length > 0) root.extensionRole = root.wantedRole
    readonly property bool extensionOpen: root.anchored && root.wantedRole.length > 0
    readonly property real joinFillet: Math.round(root.compactHeight * 0.6)
    readonly property Item extensionOrigin: root.extensionRole === "page" ? root.pageOrigin
        : root.extensionRole === "feedback"
            ? root.pieceItem(root.feedbackKind === "mic" ? "mic" : root.feedbackKind === "brightness" ? "tools" : "sound")
        : null
    readonly property real originWidth: root.extensionOrigin?.visible
        ? root.extensionOrigin.width : Math.round(40 * root.d)
    readonly property real originCenterX: {
        const part = root.extensionOrigin
        if (part && part.visible) return part.mapToItem(root, part.width / 2, 0).x
        if (root.extensionRole === "page" && root.pageOriginX >= 0) return root.pageOriginX
        return chassis.x + chassis.width / 2
    }
    function extensionX(width: real): real {
        const inset = chassis.radius + root.joinFillet
        const min = chassis.x + inset
        const max = chassis.x + chassis.width - inset - width
        return Math.round(Math.max(min, Math.min(max, root.originCenterX - width / 2)))
    }

    implicitWidth: chassis.width + 2 * Math.max(root.sideReserve, root.fillet)
    implicitHeight: chassis.bodyHeight + (root.anchored ? extension.reach : 0)
    readonly property rect extensionArea: root.anchored && extension.reach > 0.5
        ? Qt.rect(extension.x, extension.y, extension.width, extension.height)
        : Qt.rect(0, 0, 0, 0)
    readonly property real inputWidth: Math.max(root.implicitWidth,
        root.chassisTargetWidth + 2 * Math.max(root.sideReserveTarget, root.fillet))
    readonly property real inputHeight: Math.max(chassis.bodyHeight, chassis.bodyHeightTarget)

    Accessible.role: Accessible.Grouping
    Accessible.name: Translation.tr("Dynamic Island")

    property real paintNudge: 1
    Timer {
        interval: 420
        running: true
        onTriggered: { root.paintNudge = 0.999; nudgeBack.restart() }
    }
    Timer { id: nudgeBack; interval: 40; onTriggered: root.paintNudge = 1 }

    readonly property bool pointerOnIsland: chassisHover.hovered || extensionHover.hovered
        || leftSatellite.hovered || rightSatellite.hovered || auxiliarySatellite.hovered
    property point dwellAnchor: Qt.point(-1000, -1000)
    property bool pointerHeld: false
    onPointerHeldChanged: if (!root.pointerHeld && !root.pointerOnIsland && root.expanded && !root.pinned) leaveDelay.restart()

    readonly property bool fullscreenCovered: CompositorService.isNiri
        && GameMode.hasFullscreenOnOutput(root.targetScreen?.name ?? "")
        && !NiriService.inOverview
    readonly property bool suppressed: root.fullscreenCovered && !feedbackTimer.running && !root.expanded
    opacity: root.suppressed ? 0 : 1
    // Opacity only, on the whole Island: toggling visible or animating the chassis opacity leaves it unpainted.
    Behavior on opacity {
        NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing }
    }

    function trackDwell(position: point): void {
        if (root.feedback || root.editingDesktop || wheelQuiet.running) { hoverDelay.stop(); return }
        if (Math.abs(position.x - root.dwellAnchor.x) + Math.abs(position.y - root.dwellAnchor.y) < 6) return
        root.dwellAnchor = position
        if ((root.options?.hoverExpand ?? true) && !root.fullWidth && !root.expanded && root.pointerOnIsland) hoverDelay.restart()
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
            const page = rightSatellite.hovered ? root.pageFor(root.secondary)
                : leftSatellite.hovered ? root.pageFor(root.primary)
                : IrisStyle.cluster ? "desktop" : root.pageFor(root.primary)
            if (page === "desktop") root.openPage(page, false,
                rightSatellite.hovered ? rightSatellite : leftSatellite.hovered ? leftSatellite : null)
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

    property real wheelAccumulator: 0
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
    readonly property var cardKinds: ["weather", "notifications", "sound", "mic", "tools", "tray", "media"]
    readonly property bool opensCards: String(Config.options?.iris?.bubbles?.opens ?? "card") === "card"
    function toggleBubbleCard(kind: string, part, source: string): void {
        if (GlobalStates.irisBubbleCard?.source === source) { GlobalStates.irisBubbleCard = null; return }
        const isChassis = part === chassis
        const p = part.mapToItem(null, 0, isChassis ? chassis.topInset : 0)
        const band = chassis.mapToItem(null, 0, chassis.topInset)
        GlobalStates.irisBubbleCard = {
            kind: kind, source: source, screen: root.targetScreen?.name ?? "",
            x: p.x, y: p.y + root.screenOffsetY,
            width: part.width * part.scale, height: isChassis ? chassis.bodyHeight : part.height * part.scale,
            radius: isChassis ? chassis.radius : part.width / 2,
            bandY: band.y + root.screenOffsetY, bandHeight: chassis.bodyHeight
        }
    }
    Connections {
        target: GlobalStates
        function onIrisBubbleCardRequestChanged(): void {
            if (GlobalStates.irisBubbleCardRequest.length === 0 || !root.focusedOutput) return
            Qt.callLater(() => {
                const kind = GlobalStates.irisBubbleCardRequest
                if (kind.length === 0) return
                GlobalStates.irisBubbleCardRequest = ""
                if (!root.cardKinds.includes(kind)) return
                root.expanded = false
                const piece = root.pieceItem(kind)
                if (piece) { root.toggleBubbleCard(kind, piece, "island-piece-" + kind); return }
                const part = [leftSatellite, rightSatellite, auxiliarySatellite].find(s => s.visible && s.kind === kind)
                root.toggleBubbleCard(kind, part ?? chassis, part ? "island-" + part.slot : "island-chassis")
            })
        }
    }
    function pieceItem(kind: string): var {
        if (!root.barPieces.includes(kind)) return null
        const row = barPieceRow.children
        for (let i = 0; i < row.length; i++) {
            if (row[i] && row[i].visible && String(row[i].modelData ?? "") === kind) return row[i]
        }
        return null
    }
    function activatePiece(kind: string, part): void {
        if (root.opensCards && root.cardKinds.includes(kind) && part) {
            root.toggleBubbleCard(kind, part, "island-piece-" + kind)
            return
        }
        if (kind === "sound") Audio.toggleMute()
        else if (kind === "mic") Audio.toggleMicMute()
        else root.activateBubble(kind, null)
    }
    function activateBubble(kind: string, part): void {
        if (root.opensCards && root.cardKinds.includes(kind) && part) root.toggleBubbleCard(kind, part, "island-" + part.slot)
        else if (kind === "sound") Audio.toggleMute()
        else if (kind === "mic") Audio.toggleMicMute()
        else if (kind === "notifications") GlobalStates.openSidebarRight(root.targetScreen?.name ?? "")
        else if (kind === "weather") root.openPage("desktop", true, part)
        else if (kind === "tray" || kind === "tools") root.openPage(kind, true, part)
        else root.openControlCenterFrom(part)
    }

    onExpandedChanged: {
        if (!root.expanded) root.pinned = false
        else if (root.focusedOutput) GlobalStates.irisBubbleCard = null
    }
    onVisualExpandedChanged: root.flyParts()
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
    property Item pageCover: null
    readonly property Item coverFlightItem: coverFlight
    readonly property Item clockFlightItem: clockFlight
    readonly property Item chassisItem: chassis
    readonly property Item extensionItem: extension
    readonly property Item heroPreloadItem: heroPreload
    property Item heroClock: null
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
    onEffectivePageChanged: if (root.visualExpanded) { coverFlight.stop(); clockFlight.stop() }
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
        function onControlPanelOpenChanged(): void {
            if (GlobalStates.irisMorphOwner === "stage") return
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
            if (GlobalStates.irisMorphOwner === "control" && !GlobalStates.settingsOverlayOpen) {
                GlobalStates.irisMorphOwner = ""
                root.settingsMorphPart = chassis
            } else if (GlobalStates.irisMorphOwner !== "") { root.settingsOriginPrepared = false; return }
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
            duration: IrisStyle.settleDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: IrisStyle.emergeCurve
            onStopped: if (flight.t >= 1) { flight.active = false; flight.from = null; flight.to = null }
        }
        FrameAnimation {
            running: flight.flying
            onTriggered: if (flight.to) flight.toRect = flight.rectOf(flight.to)
        }
    }

    component Satellite: Item {
        id: satellite
        property string kind: ""
        property string slot: ""
        property bool shown: false
        property bool leftSide: false
        property int slotIndex: 1
        readonly property alias hovered: satelliteHover.hovered
        readonly property alias artwork: face.artwork
        signal activated()

        readonly property alias emerge: emergeSpring.value
        IrisSpring {
            id: emergeSpring
            surface: "island"
            to: satellite.shown && chassis.presentation < IrisStyle.contentFall ? 1 : 0
            minimum: 0
        }

        width: root.notch ? root.bubble - Math.round(8 * root.d) : root.bubble
        height: width
        z: -1
        y: root.bottomEdge ? root.height - (root.bubble + height) / 2 : (root.bubble - height) / 2
        x: satellite.leftSide
            ? chassis.x + (-root.satelliteOffset - width) * satellite.emerge
            : chassis.x + chassis.width - width + (root.satelliteOffset + width) * satellite.slotIndex * satellite.emerge
        visible: satellite.emerge > 0.01
        readonly property bool lifted: root.draggedSlot === satellite.slot
        opacity: satellite.lifted ? 0 : 1
        scale: 0.86 + 0.14 * satellite.emerge

        IrisBubbleFace {
            id: face
            bodyless: true
            opacity: Math.max(0, Math.min(1, (satellite.emerge - 0.45) / 0.4))
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
        WheelHandler {
            enabled: satellite.kind === "sound" || satellite.kind === "mic" || (root.options?.scrollBubbles ?? true)
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => root.applyWheel(event, satellite.kind === "sound" || satellite.kind === "mic" ? satellite.kind : "")
        }
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

    Satellite {
        id: leftSatellite
        slot: "left"
        leftSide: true
        kind: root.primary
        shown: root.leftSatelliteShown
        onActivated: {
            if (root.mediaBubbleCard) root.toggleBubbleCard("media", leftSatellite, "island-left")
            else root.openPage(root.pageFor(root.primary), true, leftSatellite)
        }
    }
    readonly property bool mediaBubbleCard: IrisStyle.cluster && root.primary === "media"
        && String(Config.options?.iris?.player?.bubbleOpens ?? "card") === "card"
    readonly property bool focusedOutput: root.targetScreen?.name === GlobalStates.focusedScreen?.name
    Binding {
        target: GlobalStates
        property: "irisMediaBubble"
        when: root.focusedOutput && root.mediaBubbleCard && leftSatellite.emerge >= 1 && !root.suppressed
            && !root.floatingSlots.includes("left")
        value: {
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
            root.openPage(page, true, null)
        }
    }
    readonly property var bubbleKinds: ({
        left: IrisStyle.cluster && root.primary !== "idle" ? root.primary : "",
        right: IrisStyle.cluster ? (root.trailingKind !== "none" ? root.trailingKind : "") : root.secondary,
        utility: root.auxiliary !== "none" && (root.auxiliary !== "tray" || root.trayItems.length > 0) ? root.auxiliary : ""
    })
    readonly property var fieldShapes: {
        void (root.x + root.y + (root.parent?.x ?? 0) + (root.parent?.y ?? 0)
            + chassis.x + chassis.width + chassis.bodyHeight + chassis.radius
            + extension.x + extension.y + extension.width + extension.height
            + leftSatellite.x + rightSatellite.x + auxiliarySatellite.x + leftSatellite.width)
        const out = []
        if (root.suppressed || root.opacity <= 0.01) return out
        if (root.notch && !IrisFrame.framed) {
            const window = root.Window.window
            const wide = (window?.width ?? 0) + 4 * IrisStyle.fuseDeep
            const deep = Math.max(8, IrisStyle.fuseDeep * 2)
            const top = root.bottomEdge ? (window?.height ?? 0) + 1 : -deep - 1
            out.push({ x: -2 * IrisStyle.fuseDeep, y: top, width: wide, height: deep,
                radius: 0, paints: true, fuse: IrisStyle.fuseDeep, id: "edge" })
        }
        const body = chassis.mapToItem(null, 0, chassis.topInset)
        out.push({ x: body.x, y: body.y, width: chassis.width, height: chassis.bodyHeight,
            radius: chassis.radius, paints: true,
            fuse: root.notch ? IrisStyle.fuseEdge : IrisStyle.fuse, id: "island",
            joins: !root.notch ? "" : IrisFrame.framed ? "frame" : "edge" })
        if (extension.visible && extension.width > 1 && extension.height > 1) {
            const page = extension.mapToItem(null, 0, 0)
            out.push({ x: page.x, y: page.y, width: extension.width, height: extension.height,
                radius: extension.radius, paints: true, fuse: IrisStyle.fuseDeep, joins: "island" })
        }
        for (const satellite of [leftSatellite, rightSatellite, auxiliarySatellite]) {
            if (!satellite.visible || satellite.emerge <= 0.01) continue
            const size = satellite.width * satellite.scale
            const centre = satellite.mapToItem(null, satellite.width / 2, satellite.height / 2)
            const resting = IrisStyle.fuse
            const joined = resting + (IrisStyle.fuseEdge - resting) * Math.max(0, 1 - satellite.emerge)
            out.push({ x: centre.x - size / 2, y: centre.y - size / 2, width: size, height: size,
                radius: size / 2, paints: true, fuse: joined, satellite: true, id: "satellite:" + satellite.slot,
                joins: "island" })
        }
        return out
    }
    readonly property var islandGeometry: {
        void (root.x + (root.parent?.x ?? 0) + (root.parent?.y ?? 0) + chassis.x + chassis.width + chassis.bodyHeight)
        const p = chassis.mapToItem(null, 0, chassis.topInset)
        return {
            x: p.x, y: p.y + root.screenOffsetY, width: chassis.width, height: chassis.bodyHeight,
            bubble: leftSatellite.width, gap: root.satelliteOffset, bottomEdge: root.bottomEdge,
            auxiliarySlot: root.auxiliarySlot, resting: !root.expanded,
            fullWidth: root.spanning
        }
    }
    function publishBubbleState(): void {
        const name = root.targetScreen?.name ?? ""
        if (name.length === 0) return
        const kinds = Object.assign({}, GlobalStates.irisBubbleKinds ?? {})
        kinds[name] = root.bubbleKinds
        GlobalStates.irisBubbleKinds = kinds
        if (root.expanded) return
        const geometry = Object.assign({}, GlobalStates.irisIslandGeometry ?? {})
        geometry[name] = root.islandGeometry
        GlobalStates.irisIslandGeometry = geometry
    }
    onBubbleKindsChanged: root.publishBubbleState()
    onIslandGeometryChanged: root.publishBubbleState()
    Component.onCompleted: root.publishBubbleState()
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
            if (!IrisStyle.cluster) root.openPage(root.pageFor(root.secondary), true, rightSatellite)
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
            decodeSize: Math.ceil(68 * root.d * 2)
            circular: false
            radius: coverFlight.fromRadius + ((coverFlight.to?.radius ?? coverFlight.fromRadius) - coverFlight.fromRadius) * coverFlight.t
        }
    }
    Flight {
        id: clockFlight
        IrisClock {
            readonly property real fromSize: Math.max(1, clockFlight.fromPixelSize)
            readonly property real toSize: Math.max(1, clockFlight.to?.pixelSize ?? clockFlight.fromPixelSize)
            pixelSize: Math.max(fromSize, toSize)
            transformOrigin: Item.TopLeft
            scale: (fromSize + (toSize - fromSize) * clockFlight.t) / pixelSize
        }
    }

    Item {
        id: badgePill
        readonly property bool shown: badgeTimer.running
        property real reveal: badgePill.shown ? 1 : 0
        Behavior on reveal { NumberAnimation { duration: IrisStyle.emergeDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.emergeCurve } }
        readonly property real gap: Math.round(8 * root.d)
        width: badgeRow.implicitWidth + Math.round(22 * root.d)
        height: Math.round(28 * root.d)
        x: (root.width - width) / 2
        y: root.bottomEdge ? -(height + gap) * badgePill.reveal + height * (1 - badgePill.reveal)
            : chassis.bodyHeight - height + (height + gap) * badgePill.reveal
        z: -2
        visible: badgePill.reveal > 0.01
        opacity: Math.min(1, badgePill.reveal * 1.5)
        scale: 0.7 + 0.3 * badgePill.reveal
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: IrisStyle.bodySurface
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

    ClippingRectangle {
        id: chassis
        // ClippingRectangle does not re-mask when per-corner radii change live.
        readonly property real restWidth: root.compactTargetWidth
        readonly property real restHeight: root.compactHeight
        readonly property real restRadius: root.compactHeight / 2
        readonly property real openWidthTarget: root.expandedWidth
        readonly property real openHeightTarget: (details.item?.implicitHeight ?? 0) + root.padding * 2
        readonly property real openRadius: Math.max(IrisStyle.radius, 30 * root.d)
        readonly property alias restW: restWidthSpring.value
        readonly property alias openW: openWidthSpring.value
        readonly property alias openH: openHeightSpring.value
        IrisSpring { id: restWidthSpring; surface: "island"; to: chassis.restWidth; intent: "move"; epsilon: 0.25 }
        IrisSpring { id: openWidthSpring; surface: "island"; to: chassis.openWidthTarget; intent: "move"; epsilon: 0.25; animate: chassis.presentation > 0.01 }
        IrisSpring { id: openHeightSpring; surface: "island"; to: chassis.openHeightTarget; intent: "move"; epsilon: 0.25; animate: chassis.presentation > 0.01 }
        readonly property alias presentation: chassisSpring.value
        IrisSpring { id: chassisSpring; surface: "island"; to: root.inlineExpanded ? 1 : 0; minimum: 0; }
        function lerp(a: real, b: real): real { return a + (b - a) * chassis.presentation }
        readonly property real bodyHeightTarget: root.inlineExpanded ? chassis.openHeightTarget : chassis.restHeight
        readonly property real bodyHeight: Math.round(chassis.lerp(chassis.restHeight, chassis.openH))
        readonly property real topInset: root.notch && !root.bottomEdge ? chassis.radius : 0
        readonly property real bottomInset: root.notch && root.bottomEdge ? chassis.radius : 0
        x: Math.round((root.width - width) / 2)
        y: root.bottomEdge ? root.height - chassis.height : -chassis.topInset
        width: Math.round(chassis.lerp(chassis.restW, chassis.openW))
        height: chassis.bodyHeight + chassis.topInset + chassis.bottomInset
        // Opaque: a transparent ClippingRectangle past the screen edge stops painting its children.
        color: IrisStyle.bodySurface
        radius: Math.min(chassis.width / 2, chassis.restRadius
            + (chassis.openRadius - chassis.restRadius) * Math.min(1, chassis.presentation))

        HoverHandler {
            id: chassisHover
            onPointChanged: root.trackDwell(point.scenePosition)
        }
        PointHandler {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onActiveChanged: if (active && root.expanded) root.pinned = true
        }
        WheelHandler {
            enabled: !root.visualExpanded || !root.pinned
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => root.applyWheel(event)
        }

        Item {
            id: compactLayer
            anchors.left: parent.left
            anchors.right: parent.right
            y: root.bottomEdge ? chassis.height - chassis.bottomInset - height : chassis.topInset
            height: root.compactHeight
            readonly property real fall: Math.min(1, chassis.presentation / Math.max(0.02, IrisStyle.contentFall))
            opacity: root.paintNudge * Math.max(0, 1 - compactLayer.fall)
            transform: Scale {
                origin.x: compactLayer.width / 2
                origin.y: compactLayer.height / 2
                xScale: IrisStyle.revealFades ? 1 : 1 - 0.1 * compactLayer.fall
                yScale: IrisStyle.revealFades ? 1 : 1 - 0.1 * compactLayer.fall
            }
            // Never transform the ClippingRectangle live: it can stop painting.
            scale: compactPress.pressed ? IrisStyle.pressScale(0.93) : 1
            Behavior on scale { NumberAnimation { duration: IrisStyle.duration(compactPress.pressed ? 80 : 200); easing.type: IrisStyle.feedbackEasing } }
            visible: opacity > 0

            component CompactRow: RowLayout {
                id: compactRow
                property string mode: ""
                property real lead: 0
                anchors.fill: parent
                anchors.leftMargin: compactRow.lead > 0
                    ? Math.round((root.compactHeight - compactRow.lead) / 2) : 14 * root.d
                anchors.rightMargin: 15 * root.d + root.barPieceReserve
                spacing: 9 * root.d
                opacity: root.compactMode === compactRow.mode ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
            }

            CompactRow {
                id: idleRow
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
                id: mediaRow
                mode: "media"
                lead: 24 * root.d
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
                        font.pixelSize: 13 * IrisStyle.typeScale
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        visible: root.effectiveLength > 0
                        implicitHeight: 2.5 * root.d
                        radius: height / 2
                        color: IrisStyle.fillHover
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
                id: recordRow
                mode: "record"
                RecordDot { Layout.alignment: Qt.AlignVCenter }
                IrisText {
                    Layout.fillWidth: true
                    text: Translation.tr("Recording")
                    font.pixelSize: 13 * IrisStyle.typeScale
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
                id: timerRow
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
                id: clockRow
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

            CompactRow {
                id: editRow
                mode: "edit"
                anchors.rightMargin: 5 * root.d
                Rectangle {
                    Layout.preferredWidth: Math.round(26 * root.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: width / 2
                    color: IrisStyle.tintFill(IrisStyle.accent)
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

            CompactRow {
                id: eventRow
                mode: "event"
                anchors.leftMargin: 6 * root.d
                Rectangle {
                    Layout.preferredWidth: root.compactHeight - Math.round(12 * root.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: width / 2
                    color: IrisStyle.tintFill(root.event.tint)
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

            CompactRow {
                id: feedbackRow
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
                    Behavior on value { NumberAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
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

            Row {
                id: barPieceRow
                z: 1
                anchors.right: parent.right
                anchors.rightMargin: Math.round(12 * root.d)
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.barPieceGap
                visible: root.barPieces.length > 0 && !root.inlineExpanded
                Repeater {
                    model: root.barPieces
                    delegate: Item {
                        id: barPiece
                        required property string modelData
                        width: root.barPieceSize
                        height: root.barPieceSize
                        IrisBubbleFace {
                            anchors.fill: parent
                            kind: barPiece.modelData
                            plated: true
                            hovered: pieceHover.hovered
                            pressed: pieceTap.pressed
                        }
                        HoverHandler { id: pieceHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            id: pieceTap
                            onTapped: root.activatePiece(barPiece.modelData, barPiece)
                        }
                        WheelHandler {
                            enabled: barPiece.modelData === "sound" || barPiece.modelData === "mic"
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: event => {
                                const step = (event.angleDelta.y || event.pixelDelta.y * 4) > 0 ? 0.05 : -0.05
                                if (barPiece.modelData === "mic") Audio.setSourceVolume((Audio.micVolume ?? 0) + step)
                                else Audio.setSinkVolume((Audio.value ?? 0) + step)
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: compactPress
                anchors.fill: parent
                enabled: !root.inlineExpanded
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                hoverEnabled: root.compactMode === "edit"
                cursorShape: islandGrip.carrying ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                preventStealing: true
                Accessible.role: Accessible.Button
                Accessible.name: root.expanded ? Translation.tr("Collapse island") : Translation.tr("Expand island")
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
                    else {
                        root.pageOriginX = compactPress.mapToItem(root, mouse.x, 0).x
                        root.openPage(IrisStyle.cluster ? "desktop" : root.pageFor(root.primary), true, null)
                    }
                }
            }
        }

    }

    ClippingRectangle {
        id: extension
        readonly property real targetWidth: root.extensionRole === "page" ? root.expandedWidth
            : Math.round(320 * root.d)
        readonly property real targetHeight: root.extensionRole === "page"
            ? (details.item?.implicitHeight ?? 0) + root.padding * 2
            : root.compactHeight
        readonly property real targetRadius: root.extensionRole === "page"
            ? Math.max(IrisStyle.radius, 30 * root.d) : root.compactHeight / 2
        readonly property alias presentation: extensionSpring.value
        IrisSpring { id: extensionSpring; surface: "island"; to: root.extensionOpen ? 1 : 0; minimum: 0 }
        readonly property real reach: Math.round(extension.targetHeight * extension.presentation)
        readonly property real liveWidth: Math.round(root.originWidth
            + (extension.targetWidth - root.originWidth) * extension.presentation)
        x: extension.anchoredShape
            ? root.extensionX(root.originWidth) + (root.extensionX(extension.targetWidth)
                - root.extensionX(root.originWidth)) * extension.presentation
            : chassis.x
        y: extension.anchoredShape
            ? (root.bottomEdge ? root.height - chassis.bodyHeight - extension.reach : chassis.bodyHeight)
            : chassis.y
        width: extension.anchoredShape ? extension.liveWidth : chassis.width
        height: extension.anchoredShape ? extension.reach : chassis.height
        radius: extension.anchoredShape
            ? root.originWidth / 2 + (extension.targetRadius - root.originWidth / 2) * extension.presentation
            : chassis.radius
        color: IrisStyle.bodySurface
        readonly property bool anchoredShape: root.anchored
        HoverHandler { id: extensionHover }
        PointHandler {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onActiveChanged: if (active && root.expanded) root.pinned = true
        }
        visible: extension.anchoredShape ? extension.presentation > 0
            : (details.opacity > 0 || artBackdrop.opacity > 0)

        Loader {
            id: artBackdrop
            anchors.fill: parent
            property real shown: root.effectivePage === "media" ? 1 : 0
            Behavior on shown {
                enabled: root.visualExpanded && details.opacity >= 1
                NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.moveCurve }
            }
            active: details.active && (root.effectivePage === "media" || artBackdrop.shown > 0)
                && (Config.options?.iris?.player?.artworkBackground ?? true)
                && MediaArtwork.displaySource.length > 0
            opacity: details.opacity * artBackdrop.shown
            layer.enabled: true
            sourceComponent: IrisMediaBackdrop {
                source: MediaArtwork.displaySource
                edgeTop: !root.anchored && chassis.topInset > 0 ? (chassis.topInset + root.fillet + 4 * root.d) / 0.45 : 0
                edgeBottom: !root.anchored && chassis.bottomInset > 0 ? (chassis.bottomInset + root.fillet + 4 * root.d) / 0.45 : 0
            }
        }
        Loader {
            id: details
            anchors.top: parent.top
            anchors.topMargin: root.padding + (root.anchored ? 0 : chassis.topInset)
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(0, root.expandedWidth - root.padding * 2)
            active: root.expanded || opacity > 0
            onActiveChanged: if (!active) root.page = ""
            opacity: {
                const t = root.anchored ? extension.presentation : chassis.presentation
                return root.visualExpanded ? IrisStyle.contentAt(t) : IrisStyle.contentLeaving(t)
            }
            scale: IrisStyle.revealInflates
                ? Math.max(0.35, Math.min(1, (root.anchored ? extension.height : chassis.bodyHeight)
                    / Math.max(1, root.anchored ? extension.targetHeight : chassis.openH)))
                : IrisStyle.revealFades ? 1 : 0.96 + 0.04 * details.opacity
            transformOrigin: root.bottomEdge ? Item.Bottom : Item.Top
            visible: opacity > 0
            enabled: root.expanded

            sourceComponent: GridLayout {
                id: expandedContent
                columns: 1
                rowSpacing: 14 * root.d

                component Page: ColumnLayout {
                    id: pageItem
                    property string name: ""
                    property bool bleeds: false
                    readonly property bool current: root.effectivePage === pageItem.name
                    readonly property bool switching: root.visualExpanded && details.opacity >= 1
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    opacity: pageItem.current ? 1 : 0
                    scale: pageItem.current || pageItem.bleeds ? 1 : 0.97
                    transformOrigin: root.bottomEdge ? Item.Bottom : Item.Top
                    visible: opacity > 0
                    enabled: pageItem.current
                    Behavior on opacity {
                        id: pageFade
                        enabled: pageItem.switching
                        SequentialAnimation {
                            PauseAnimation { duration: pageFade.targetValue > 0 ? IrisStyle.duration(50) : 0 }
                            NumberAnimation {
                                duration: IrisStyle.duration(pageFade.targetValue > 0 ? 170 : 80)
                                easing.type: IrisStyle.feedbackEasing
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

                    Page {
                        id: mediaPage
                        name: "media"
                        spacing: 14 * root.d
                        IslandMediaPage {
                            Layout.fillWidth: true
                            island: root
                        }
                    }

                    Page {
                        id: activityPage
                        name: "activity"
                        spacing: 12 * root.d
                        IslandActivityPage {
                            Layout.fillWidth: true
                            island: root
                        }
                    }

                    Page {
                        id: desktopPage
                        name: "desktop"
                        bleeds: desktopContent.showBanner
                        spacing: 14 * root.d
                        IslandDesktopPage {
                            id: desktopContent
                            Layout.fillWidth: true
                            island: root
                            navOffset: navRow.height + expandedContent.rowSpacing
                        }
                    }
                }

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
                        colBackgroundHover: IrisStyle.fillHover
                        onClicked: if (nav.target.length > 0) root.page = nav.target
                        Glyph {
                            anchors.centerIn: parent
                            text: nav.glyph
                            fill: nav.selected ? 1 : 0
                            iconSize: 18 * root.d
                            color: nav.selected ? IrisStyle.accent : IrisStyle.textSecondary
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
                        color: IrisStyle.fill
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
        RowLayout {
            id: hudRow
            anchors.fill: parent
            anchors.leftMargin: 16 * root.d
            anchors.rightMargin: 17 * root.d
            spacing: 11 * root.d
            opacity: extension.anchoredShape && root.extensionRole === "feedback" && root.extensionOpen ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }

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
                Behavior on value { NumberAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
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
    }
}
