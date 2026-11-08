pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Dialogs
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.shared.mediaControls.components
import qs.modules.iris.style
import qs.modules.iris.widgets as IrisFaces
import "island/NoticeSamples.js" as NoticeSamples
import qs.modules.iris.components
import qs.modules.iris.frame
import qs.modules.iris.pieces
import qs.modules.iris.bar.island
import qs.modules.iris.control
import qs.modules.iris.edit
import qs.modules.iris.stage
import qs.modules.iris.state

Item {
    id: root

    property var targetScreen
    property real availableWidth: 800
    property real availableAcross: 800
    property real compactHeight: 42
    // Spotlight opened as the Island is drawn by the same field: the Island hands it its face and folds its satellites.
    // Only Spotlight opened as the Island takes its place; a floating one leaves the Island as it is.
    // A Place that opens as the Island (Spotlight, Orbit) is given the Island's face while it is up.
    property real spotlightYield: (String(Config.options?.iris?.palette?.opens ?? "floating") === "island"
            && (IrisFrame.placeBodies["spotlight"]?.screen ?? "") === (root.targetScreen?.name ?? "-"))
        || (String(Config.options?.iris?.orbit?.opens ?? "island") === "island"
            && (IrisFrame.placeBodies["orbit"]?.screen ?? "") === (root.targetScreen?.name ?? "-")) ? 1 : 0
    Behavior on spotlightYield { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
    property bool expanded: false
    property bool pinned: false
    property string page: ""

    readonly property real d: IrisStyle.density
    readonly property var options: Config.options?.iris?.bar ?? ({})
    readonly property real clockScale: Math.max(0.8, Math.min(1.5, Number(root.options?.clockScale ?? 100) / 100))
    readonly property real breathing: Math.max(0.5, Math.min(2.5, Number(root.options?.padding ?? 100) / 100))
    readonly property color clockAccent: IrisStyle.clockAccent
    readonly property real satelliteScale: Math.max(0.7, Math.min(1, Number(root.options?.satelliteScale ?? 100) / 100))

    readonly property var desktopBlockKinds: ["profile", "context", "workspaces", "forecast", "agenda", "vitals", "modules"]
    readonly property var desktopBlocks: Array.from(root.options?.desktopBlocks ?? root.desktopBlockKinds)
        .filter(kind => root.desktopBlockKinds.includes(kind))
    function desktopBlockLabel(kind: string): string {
        return ({ profile: Translation.tr("Profile"), context: Translation.tr("Current app"), workspaces: Translation.tr("Workspaces"),
            forecast: Translation.tr("Forecast"), agenda: Translation.tr("Up next"),
            vitals: Translation.tr("Vitals"), modules: Translation.tr("Modules") })[kind] ?? kind
    }
    function setDesktopBlock(kind: string, on: bool): void {
        const next = root.desktopBlocks.filter(entry => entry !== kind)
        if (on) next.push(kind)
        Config.setNestedValue("iris.bar.desktopBlocks", next)
    }
    function desktopBlockGlyph(kind: string): string {
        return ({ profile: "account_circle", context: "select_window", workspaces: "view_carousel", forecast: "partly_cloudy_day",
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
    readonly property bool studio: IrisState.arrange && root.focusedOutput && root.visualExpanded
        && root.effectivePage === "desktop"
    Connections {
        target: root
        function onVisualExpandedChanged(): void { if (!root.visualExpanded && root.focusedOutput) IrisState.arrange = false }
    }
    readonly property bool notch: root.options?.notch ?? false
    // A Design draws the Island's faces and its page nav itself (DESIGNS.md › Island); the engine keeps the modes,
    // events, pages, pieces and geometry. A Design whose pages "hang" (AIRISU) opens them as a second body under the
    // strip, welded to it: the page grows out of the strip's foot, one body.
    // Three designs of the Island (10-25): the engine's own (Halo), Ledger and Tiles, which skin its face, its page
    // buttons and its desktop page. A shell Design (AIRISU) that skins a part keeps it.
    readonly property string design: String(root.options?.design ?? "halo") in IrisStyle.islandDesignParts ? String(root.options.design) : "halo"
    // What each design draws of its own; the engine draws the rest (Dial, Marquee and Duo keep Halo's pages).
    readonly property var designParts: IrisStyle.islandDesignParts
    function skinOf(own: string, file: string): string {
        return own.length > 0 || !(root.designParts[root.design] ?? []).includes(file) ? own : Qt.resolvedUrl("island/designs/" + root.design + "/" + file)
    }
    readonly property string faceUrl: root.vertical ? "" : root.skinOf(IrisDesign.skin("islandFace"), "Face.qml")
    readonly property string navUrl: root.skinOf(IrisDesign.skin("islandNav"), "Nav.qml")
    // A face may take only some modes (`modes`); the engine draws the others. A song is the one activity that does not
    // take the Island's face (Unified, Corner, Shelf, Pods, Menu bar): it rides at the face's sides as Apple's compact
    // Dynamic Island does, its cover leading and its music moving at the trailing end, and a tap still opens the
    // player. Halo's face is the engine's resting row, so it wears the same wings (haloWings).
    readonly property bool faceWings: root.faceUrl.length > 0 && !root.vertical && root.compactMode === "media"
        && Array.isArray(designFace.item?.modes) && !designFace.item.modes.includes("media")
    readonly property bool haloWings: root.faceUrl.length === 0 && !root.vertical && root.compactMode === "media"
    readonly property bool songWings: root.faceWings || root.haloWings
    readonly property bool faceTakes: root.faceUrl.length > 0 && (root.faceWings || !designFace.item?.modes || designFace.item.modes.includes(root.compactMode))
    // Apple's measures, as shares of the pill's height: the cover 0.63, the music 0.4 tall, a quarter in from the ends.
    readonly property real wingCoverSize: Math.round(root.compactHeight * 0.63)
    readonly property real wingBox: Math.max(root.wingCoverSize, root.nothingLook ? root.stripWidth(4) : wingVisualizer.implicitWidth)
    // Each side's share of the Island the song takes (its inset, the wing and a step clear of it); the face keeps the
    // middle with its own breathing, so the song stands as far from the face as from the Island's ends.
    readonly property real wingSlot: root.songWings ? root.wingLead + root.wingBox + Math.round(6 * root.d) : 0
    readonly property real wingLead: Math.round(Math.max((root.compactHeight - root.wingCoverSize) / 2,
        Math.min(14.5 * root.d * root.breathing, root.compactHeight / 4)))
    readonly property bool pagesHang: IrisDesign.trait("pages") === "hang" && !root.fullWidth && !root.vertical
    readonly property real seam: 0
    readonly property string pagePlate: {
        const value = String(root.options?.navFrame ?? "auto")
        return ["none", "veil", "glass", "solid"].includes(value) ? value : IrisStyle.controlPlate
    }
    // The corner of a body that is always melted into its edge (the menu bar's heart, the utility island): a capsule on Auto.
    readonly property real meltedCorner: IrisStyle.profileRadius(IrisStyle.bodyProfile(IrisStyle.barShape, true), root.compactHeight)
    readonly property alias notchness: notchSpring.value
    IrisSpring { id: notchSpring; surface: "island"; intent: "move"; to: root.notch ? 1 : 0; minimum: 0 }
    property string edge: "top"
    readonly property bool bottomEdge: root.edge === "bottom"
    readonly property bool rightEdge: root.edge === "right"
    readonly property bool vertical: root.edge === "left" || root.rightEdge

    readonly property var player: MprisController.activePlayer
    readonly property bool hasMedia: root.player !== null && root.player !== undefined
        && String(MprisController.titleOf(root.player) ?? "").length > 0
    readonly property bool ytMusic: root.hasMedia && MprisController._isYtMusicMpv(root.player)
    readonly property string title: root.ytMusic ? YtMusic.currentTitle : String(MprisController.titleOf(root.player) ?? "")
    readonly property bool playing: root.hasMedia && (root.ytMusic ? YtMusic.isPlaying : (root.player?.isPlaying ?? false))
    readonly property real effectivePosition: root.ytMusic ? YtMusic.currentPosition : MprisController.positionOf(root.player)
    readonly property real effectiveLength: root.ytMusic ? YtMusic.currentDuration : MprisController.lengthOf(root.player)
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

    // Jobs newest first by when they began (not by update, or two running jobs would swap every tick).
    readonly property var tasks: LiveActivities.active.slice().sort((a, b) => b.started - a.started)
    readonly property var task: root.tasks[0] ?? null
    readonly property color taskTint: root.nothingLook ? IrisStyle.text : IrisStyle.identityColor(String(root.task?.tint ?? "lavender"))
    // Priority, as Live Activities, in the person's order (factory: what records you, then what counts down, then
    // jobs, the camera, a call, the song). The first is the compact Island; the second detaches as the minimal bubble;
    // the expanded page lists them all. Each kind takes the Island only while its switch is on (Settings › Island ›
    // Live activities); the privacy dot shows either way. A video call with the camera tile off shows as a call.
    readonly property var acts: root.options?.activities ?? ({})
    readonly property bool cameraTile: Privacy.cameraActive && root.acts.camera !== false
    readonly property var activityOrder: IrisStyle.islandActivityOrder(root.acts.order)
    readonly property var activities: {
        const list = []
        for (const kind of root.activityOrder) {
            if (root.acts[kind] === false) continue
            if (kind === "record" && root.recording) list.push("record")
            else if (kind === "timer" && root.timerKind.length > 0) list.push("timer")
            else if (kind === "task") for (const job of root.tasks.slice(0, 2)) list.push("task")
            else if (kind === "camera" && root.cameraTile) list.push("camera")
            else if (kind === "call" && Privacy.micActive && !root.cameraTile) list.push("mic")
            else if (kind === "media" && root.hasMedia) list.push("media")
        }
        return list
    }
    readonly property string primary: root.activities[0] ?? "idle"
    readonly property string secondary: root.activities[1] ?? ""
    readonly property var secondaryTask: root.primary === "task" ? (root.tasks[1] ?? null) : root.task
    readonly property bool privacyLive: Privacy.anyActive
    // A Cluster Island is the clock with the song beside it; a live activity (recording, a timer, a job) takes the
    // Island itself, as on a phone, and what comes after it detaches into the left bubble.
    // The song never takes a Cluster Island: the first activity that is not it does, wherever the song stands.
    readonly property int islandActivityAt: IrisStyle.cluster ? root.activities.findIndex(kind => kind !== "media") : -1
    readonly property string islandActivity: root.islandActivityAt >= 0 ? root.activities[root.islandActivityAt] : ""
    readonly property string leftKind: root.islandActivityAt >= 0 ? (root.activities.find((kind, at) => at !== root.islandActivityAt) ?? "")
        : root.primary === "idle" ? "" : root.primary
    // Where a tap on the Island goes: what it shows, who is using the mic or screen, else the desktop page.
    readonly property string tapPage: IrisStyle.cluster
        ? (root.islandActivity.length > 0 || root.privacyLive ? "activity" : "desktop") : root.pageFor(root.primary)
    readonly property bool hasSystemActivity: root.recording || root.timerKind.length > 0 || root.task !== null || root.privacyLive

    // A job without a percentage shows how long it has run; this ticks only while one does.
    property real now: Date.now()
    Timer {
        interval: 1000
        repeat: true
        running: root.tasks.some(job => Number(job.progress ?? -1) < 0)
        onTriggered: root.now = Date.now()
        onRunningChanged: root.now = Date.now()
    }
    // A call, as a phone shows one: since when something has been listening through the microphone.
    property real micSince: 0
    readonly property bool micLive: Privacy.micActive
    onMicLiveChanged: root.micSince = root.micLive ? Date.now() : 0
    Timer {
        interval: 1000
        repeat: true
        running: root.micLive && (root.compactMode === "mic" || root.compactMode === "camera")
        onTriggered: root.now = Date.now()
        onRunningChanged: root.now = Date.now()
    }
    readonly property string micElapsed: root.micSince > 0 ? root.clockText(Math.max(0, Math.floor((root.now - root.micSince) / 1000))) : "0:00"
    readonly property string micApp: String((Privacy.micApps ?? [])[0] ?? "")
    function elapsedOf(job): string {
        return root.clockText(Math.max(0, Math.floor((root.now - Number(job?.started ?? root.now)) / 1000)))
    }
    function percentOf(job): string { return String(Math.round(Math.max(0, Number(job?.progress ?? 0)) * 100)) }

    function pageFor(kind: string): string {
        if (kind === "idle" || kind === "") return root.privacyLive ? "activity" : "desktop"
        return kind === "media" ? "media" : "activity"
    }
    readonly property string effectivePage: {
        const requested = root.page.length > 0 ? root.page : root.pageFor(root.primary)
        if (requested === "media" && !root.hasMedia) return root.pageFor(root.primary)
        if (requested === "activity" && !root.hasSystemActivity) return root.pageFor(root.primary)
        return requested
    }

    readonly property var navKinds: ["media", "activity", "desktop", "shelf", "weather", "calendar", "vitals", "tray", "tools", "focus", "today", "controls", "settings"]
    // Cards that are pages of the Island too (10-25: more to open than the desktop and the tray).
    readonly property var cardPages: ["weather", "calendar", "vitals"]
    readonly property var navItems: {
        const saved = Array.from(IrisStyle.structuralValue("bar.navItems", root.navKinds))
        // The factory lists from before the card pages and the Shelf count as the factory list.
        const chosen = (["media,activity,desktop,tray,tools,focus,today,controls,settings",
                "media,activity,desktop,weather,calendar,vitals,tray,tools,focus,today,controls,settings"].includes(saved.join())
            ? root.navKinds : saved)
            .filter(kind => root.navKinds.includes(kind))
        return chosen.length > 0 ? chosen : root.navKinds
    }
    function navAvailable(kind: string): bool {
        if (kind === "media") return root.hasMedia
        if (kind === "activity") return root.hasSystemActivity
        if (kind === "focus") return Config.options?.iris?.sidebars?.left?.enable ?? true
        if (kind === "today") return Config.options?.iris?.sidebars?.right?.enable ?? true
        if (kind === "weather") return Weather.enabled
        if (kind === "shelf") return Config.options?.shelf?.enable ?? true
        return true
    }
    function navPageOf(kind: string): string {
        if (kind === "controls") return root.controlsInIsland ? "controls" : ""
        return ["media", "activity", "desktop", "shelf", "tray", "tools"].concat(root.cardPages).includes(kind) ? kind : ""
    }
    readonly property var navEntries: {
        const glyphs = { media: "music_note", activity: root.recording ? "radio_button_checked"
                : root.timerKind.length > 0 ? root.timerGlyph : root.task ? String(root.task.glyph ?? "bolt")
                : Privacy.micActive ? "mic" : Privacy.cameraActive ? "videocam" : Privacy.screenSharing ? "screen_share" : "bolt",
            desktop: "space_dashboard", shelf: "inventory_2", weather: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "partly_cloudy_day",
            calendar: "calendar_month", vitals: "monitor_heart", tray: "apps", tools: "timer", focus: "left_panel_open",
            today: "right_panel_open", controls: "tune", settings: "settings" }
        const labels = { media: "Now playing", activity: "Live activities", desktop: "Desktop", shelf: "Shelf", weather: "Weather",
            calendar: "Calendar", vitals: "Vitals", tray: "Tray",
            tools: "Timers", focus: "Focus panel", today: "Today panel", controls: "Quick controls", settings: "Settings" }
        const visible = root.navItems.filter(kind => root.navAvailable(kind))
        const out = []
        let pages = true
        for (const kind of visible) {
            const page = root.navPageOf(kind)
            if (pages && page.length === 0 && out.length > 0) out.push({ kind: "|" })
            if (page.length === 0) pages = false
            out.push({ kind: kind, page: page, glyph: glyphs[kind], label: labels[kind] })
        }
        return out
    }
    readonly property var pageCycle: root.navEntries.filter(entry => (entry.page ?? "").length > 0).map(entry => entry.page)
    function activateNav(kind: string): void {
        const page = root.navPageOf(kind)
        if (kind === "controls") {
            if (!root.controlsInIsland) root.openControlCenterFrom(chassis)
            else if (root.focusedOutput) GlobalStates.controlPanelOpen = true
            return
        }
        if (page.length > 0) { root.page = page; root.pinned = true; return }
        if (kind === "focus") { root.expanded = false; GlobalStates.openSidebarLeft(root.targetScreen?.name ?? "") }
        else if (kind === "today") { root.expanded = false; GlobalStates.openSidebarRight(root.targetScreen?.name ?? "") }
        else if (kind === "settings") root.openSettingsFrom(chassis)
    }
    // A nav entry under the pointer warms its page, and the Settings entry warms Settings.
    function hoverNav(kind: string, page: string, on: bool): void {
        if (page.length > 0) {
            if (on) { pageIntentExpiry.stop(); root.pageIntent = page }
            else if (root.pageIntent === page) pageIntentExpiry.restart()
        }
    }
    function stepPage(steps: int): bool {
        const cycle = root.pageCycle
        if (cycle.length === 0 || steps === 0) return false
        const at = Math.max(0, cycle.indexOf(root.effectivePage))
        const next = cycle[Math.max(0, Math.min(cycle.length - 1, at + steps))]
        if (!root.expanded) { root.openPage(next, true, null); return true }
        if (next === root.effectivePage) return false
        if (next === "controls" && root.focusedOutput) GlobalStates.controlPanelOpen = true
        else root.page = next
        root.pinned = true
        return true
    }
    property real pageWheel: 0
    function wheelPages(event, vertical: bool): void {
        const dx = event.angleDelta.x !== 0 ? event.angleDelta.x : event.pixelDelta.x * 4
        const dy = event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y * 4
        const across = Math.abs(dx) > Math.abs(dy)
        if (!across && !vertical) return
        event.accepted = true
        root.pageWheel += across ? -dx : -dy
        const steps = Math.trunc(root.pageWheel / 120)
        if (steps === 0) return
        root.pageWheel -= steps * 120
        root.stepPage(steps)
    }

    function openPage(nextPage: string, pin: bool, origin): void {
        root.page = nextPage
        root.pageOrigin = origin ?? null
        if (origin) { root.pageOriginX = -1; root.pageOriginY = -1 }
        if (pin) root.pinned = true
        root.expanded = true
    }
    property real pageOriginX: -1
    property real pageOriginY: -1

    property real screenOffsetY: 0
    // Geometry is read in the window's own space (QsWindow.window.contentItem), never the scene: the edit card and the
    // arrival transform that item, and a scene point kept their scale once they dropped (11-02: after edit mode the Island
    // and its bubbles stayed drawn where the card had them). Not QsWindow.contentItem: on qs-rs that is the Qt root above
    // the transform, so a shape read during the card was scaled twice (11-07: a bubble welded into the Island's side).
    function chassisBody(): var {
        const p = chassis.mapToItem(root.QsWindow.window?.contentItem, chassis.leftInset, chassis.topInset)
        return { x: p.x, y: p.y, width: root.vertical ? chassis.across : chassis.width,
            height: root.vertical ? chassis.height : chassis.bodyHeight }
    }
    function partRect(part): var {
        if (part === chassis) return root.chassisBody()
        const p = part.mapToItem(root.QsWindow.window?.contentItem, 0, 0)
        return { x: p.x, y: p.y, width: part.width * part.scale, height: part.height * part.scale }
    }
    function publishOrigin(part): void {
        if (root.targetScreen?.name !== GlobalStates.focusedScreen?.name) return
        if (root.suppressed || !part?.visible) { IrisState.morphOrigin = null; return }
        const isChassis = part === chassis
        const r = root.partRect(part)
        IrisState.morphOrigin = {
            x: r.x, y: r.y + root.screenOffsetY,
            width: r.width, height: r.height,
            radius: isChassis ? chassis.radius : IrisStyle.pieceRadius(Math.min(r.width, r.height)),
            screen: root.targetScreen?.name ?? ""
        }
    }

    // A Place that the Island collapses for (the gallery, Spotlight, Settings) grows out of where the Island
    // comes to rest, not out of the page it is leaving: the page is gone by the time the Place starts.
    function publishRestOrigin(): void {
        if (root.targetScreen?.name !== GlobalStates.focusedScreen?.name) return
        const rest = IrisState.islandGeometry?.[root.targetScreen?.name ?? ""] ?? null
        if (!root.expanded || !rest || !(rest.width > 0) || root.suppressed) { root.publishOrigin(chassis); return }
        IrisState.morphOrigin = { x: rest.x, y: rest.y, width: rest.width, height: rest.height,
            radius: Math.min(rest.width, rest.height) / 2, screen: root.targetScreen?.name ?? "" }
    }
    property Item controlMorphPart: null
    property Item settingsMorphPart: null
    property bool controlOriginPrepared: false
    property bool settingsOriginPrepared: false
    property string pageIntent: ""

    // A Design that brings its own Control Center opens it as its own body, never as an Island page.
    readonly property bool controlsInIsland: !IrisDesign.has("controlCenter") && String(Config.options?.iris?.controlCenter?.opens ?? "island") === "island"
    function openControlCenterFrom(part): void {
        if (root.controlsInIsland) {
            root.openPage("controls", true, part ?? null)
            if (root.focusedOutput) GlobalStates.controlPanelOpen = true
            return
        }
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

    // Compact figures: the Dot voice at its smallest size, grown with the clock scale.
    readonly property int dotFigure: Math.round(28 * IrisStyle.typeScale * Math.max(1, root.clockScale))
    // Nothing is worn here only when the person puts it on the Island; Apple keeps its own faces.
    readonly property string irisPlace: "island"
    readonly property bool nothingLook: IrisStyle.nothingAt("island")
    readonly property real figureSize: root.nothingLook ? root.dotFigure : IrisStyle.typeHeadline * root.clockScale
    function stripWidth(count: int): real {
        const dot = Math.max(3, Math.round(4 * IrisStyle.density)), gap = Math.max(2, Math.round(3 * IrisStyle.density))
        return count * dot + (count - 1) * gap
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
    property bool wheelHold: false
    readonly property bool feedback: (feedbackTimer.running || root.wheelHold) && !root.expanded && !root.fullscreenCovered
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

    readonly property var osdPrefs: Config.options?.iris?.osd
    readonly property string osdGameRule: GameMode.active ? String(root.osdPrefs?.fullscreen ?? "show") : "show"
    readonly property string osdMediaMode: String(root.osdPrefs?.media ?? "yours")
    readonly property string levelStyle: String(root.osdPrefs?.style ?? "capsule")
    readonly property bool levelFigure: root.osdPrefs?.figure ?? true
    readonly property bool osdKeyboard: (root.osdPrefs?.keyboard ?? true) && root.osdGameRule === "show"
    function showFeedback(kind: string, requested = false): void {
        if (Date.now() < IrisState.levelQuietUntil) return
        if (!(Config.options?.iris?.modules?.osd ?? true) || root.expanded || root.fullscreenCovered
            || root.osdGameRule === "hide" || root.targetScreen?.name !== GlobalStates.focusedScreen?.name) return
        const mode = String(root.osdPrefs?.levels ?? "yours")
        const touched = kind === "brightness" ? Brightness.lastUserChange : Audio.lastUserChange
        if (!requested && (mode === "off" || (mode === "yours" && Date.now() - touched > 1200))) return
        root.feedbackKind = kind
        feedbackTimer.restart()
    }

    readonly property bool eventsEnabled: root.options?.events ?? true
    // iris.bar.notices: which moments the Island says by itself, for how long, and how large.
    readonly property var notices: root.options?.notices ?? ({})
    function noticeOn(kind: string): bool { return root.eventsEnabled && root.notices?.[kind] !== false }
    readonly property int noticeMs: Math.round(1000 * Math.max(1.5, Math.min(8, Number(root.notices?.seconds ?? 2.5))))
    // Large: the Island grows into a card, as a phone's alerts do; a full bar hangs the card under its strip. A side
    // edge keeps the line (a card does not stand upright).
    readonly property bool noticeSized: String(root.notices?.style ?? "compact") === "large" && !root.vertical
    readonly property bool noticeLarge: root.noticeSized && root.eventShown && !root.feedback && !root.dropHover
    // The floating Island's own body grows; on a bar the hanging body does.
    readonly property bool noticeGrows: root.noticeLarge && !root.anchored
    IrisSpring { id: noticeSpring; surface: "island"; intent: "move"; to: root.noticeGrows ? 1 : 0; minimum: 0; epsilon: 0.002 }
    readonly property real noticeOpen: noticeSpring.value
    // The card owns its measure (IslandNoticeCard): the bodies only grow to it.
    readonly property real noticeHeight: noticeCard.cardHeight
    readonly property real noticeRadius: noticeCard.cardRadius
    readonly property real noticeWidth: noticeCard.cardWidth
    property var event: ({ icon: "", tint: IrisStyle.text, title: "", detail: "", value: -1, kind: "", failed: false })
    readonly property bool eventShown: eventTimer.running && !root.expanded && !root.feedback
    // A battery notice draws the battery itself, filled to its level, instead of a font glyph.
    // Material's "lan" is a network diagram; a cable reads as the ethernet port, as the Network bubble shows it.
    readonly property string eventGlyph: root.event.icon === "lan" ? "settings_ethernet" : root.event.icon
    readonly property color eventInk: root.event.failed || (root.nothingLook && Qt.colorEqual(root.event.tint, IrisStyle.danger))
        ? IrisStyle.signalInk : root.nothingLook ? IrisStyle.text : root.event.tint
    readonly property bool eventIsBattery: String(root.event.icon).startsWith("battery") && root.event.value >= 0
    property string eventImage: ""
    function showEvent(icon: string, tint: color, title: string, detail: string, value: real, kind = ""): void {
        if (!root.eventsEnabled || !eventsWarm.ready || root.expanded || root.fullscreenCovered
            || root.targetScreen?.name !== GlobalStates.focusedScreen?.name) return
        root.event = { icon: icon, tint: tint, title: title, detail: detail, value: value, kind: kind, failed: false, image: root.eventImage }
        root.eventImage = ""
        eventTimer.restart()
    }
    // A job that ends says so in the compact Island: its strip fills and a pulse runs through it, or it fails in signal.
    function showDone(activity): void {
        if (!root.eventsEnabled || !eventsWarm.ready || root.expanded || root.fullscreenCovered
            || root.targetScreen?.name !== GlobalStates.focusedScreen?.name) return
        const failed = Boolean(activity?.failed)
        root.event = { icon: failed ? "close" : "check", tint: failed ? IrisStyle.signal : root.nothingLook ? IrisStyle.text : IrisStyle.success,
            title: String(activity?.title ?? ""), kind: "done", failed: failed, value: failed ? -1 : 1,
            detail: String(activity?.detail ?? "").length > 0 ? String(activity.detail) : failed ? Translation.tr("Failed") : Translation.tr("Done") }
        eventTimer.restart()
    }
    Timer { id: eventTimer; interval: root.noticeMs; onTriggered: root.clearOsdRequests() }
    // A sample asked for by Settings (or `inir irisDev notice KIND`): shown whatever is switched off, so a person sees
    // the size and the time they chose. Each kind uses the words a real one says.
    Connections {
        target: IrisState
        function onNoticeSampleChanged(): void {
            const kind = String(IrisState.noticeSample?.kind ?? "")
            if (kind.length === 0 || !root.focusedOutput || root.expanded || root.fullscreenCovered) return
            const screen = root.targetScreen?.name ?? ""
            root.event = NoticeSamples.of(kind, Translation, IrisStyle, root.nothingLook,
                Wallpapers.stillUrlFor(Wallpapers.internalPreviewFor(screen, Wallpapers.desktopWallpaperPath(screen))))
            eventTimer.restart()
        }
    }
    // The Island answers these requests, so it owns clearing them: a flag left
    // set is never seen again by the OSD fallback on another output.
    function clearOsdRequests(): void {
        GlobalStates.osdVolumeOpen = false
        GlobalStates.osdBrightnessOpen = false
        GlobalStates.osdMicOpen = false
        GlobalStates.osdMediaOpen = false
        GlobalStates.osdKeyboardLayoutOpen = false
    }
    Connections {
        target: root.noticeOn("gameMode") ? GameMode : null
        function onManuallyActivatedChanged(): void {
            root.showEvent("sports_esports", GameMode.manuallyActivated ? IrisStyle.identity.green : IrisStyle.textSecondary,
                GameMode.manuallyActivated ? Translation.tr("Game mode on") : Translation.tr("Game mode off"),
                GameMode.manuallyActivated ? Translation.tr("Effects and notifications held back") : Translation.tr("Everything is back"), -1)
        }
    }
    property bool niriConfigBroken: false
    Connections {
        target: CompositorService.isNiri ? NiriService : null
        function onConfigLoadFinished(ok: bool, error: string): void {
            if (!root.noticeOn("niri")) { root.niriConfigBroken = !ok; return }
            if (!ok) {
                const line = String(error ?? "").split("\n").map(part => part.trim()).find(part => part.length > 0) ?? ""
                root.showEvent("error", IrisStyle.danger, Translation.tr("Niri config has an error"),
                    line.length > 0 ? line : Translation.tr("The previous config is still in use"), -1)
            } else if (root.niriConfigBroken) {
                root.showEvent("check_circle", IrisStyle.success, Translation.tr("Niri config loaded"),
                    Translation.tr("The error is fixed"), -1)
            }
            root.niriConfigBroken = !ok
        }
    }
    Connections {
        target: root.noticeOn("jobs") ? LiveActivities : null
        function onFinished(activity: var): void { root.showDone(activity) }
    }
    property var badge: ({ icon: "", tint: IrisStyle.text, text: "" })
    function showBadge(icon: string, tint: color, text: string): void {
        if (!root.eventsEnabled || !eventsWarm.ready || root.fullscreenCovered
            || root.targetScreen?.name !== GlobalStates.focusedScreen?.name) return
        root.badge = { icon: icon, tint: tint, text: text }
        badgeTimer.restart()
    }
    Timer { id: badgeTimer; interval: 1600; onTriggered: root.clearOsdRequests() }
    Timer { id: eventsWarm; property bool ready: false; interval: 4000; running: true; onTriggered: ready = true }
    Connections {
        target: root.noticeOn("battery") && Battery.available ? Battery : null
        function onIsLowAndNotChargingChanged(): void {
            if (Battery.isLowAndNotCharging)
                root.showEvent("battery_alert", IrisStyle.danger, Translation.tr("Low battery"), Translation.tr("Plug in soon"), Battery.percentage)
        }
    }
    Connections {
        target: root.eventsEnabled ? DeviceEvents : null
        function onHappened(event: var): void {
            const tint = event.tone === "warn" ? IrisStyle.identity.orange
                : event.tone === "off" ? IrisStyle.subtext
                : ({ network: IrisStyle.identity.blue, internet: IrisStyle.identity.teal, bluetooth: IrisStyle.identity.blue, usb: IrisStyle.identity.sky,
                     power: IrisStyle.success, audio: IrisStyle.accent, displays: IrisStyle.identity.indigo,
                     drives: IrisStyle.identity.orange })[event.kind] ?? IrisStyle.accent
            root.showEvent(event.icon, tint, event.title, event.detail, event.value >= 0 ? event.value / 100 : -1,
                event.kind === "power" && event.tone === "on" ? "charge" : event.kind === "bluetooth" && event.tone === "on" ? "accessory" : "")
        }
    }
    Connections {
        target: root.noticeOn("focus") ? Notifications : null
        function onSilentChanged(): void {
            root.showEvent(Notifications.silent ? "do_not_disturb_on" : "notifications_active",
                Notifications.silent ? IrisStyle.identity.indigo : IrisStyle.textSecondary, Translation.tr("Do not disturb"),
                Notifications.silent ? Translation.tr("On") : Translation.tr("Off"), -1, "status")
        }
    }
    Connections {
        target: root.noticeOn("timers") ? TimerService : null
        function onCountdownRunningChanged(): void {
            if (!TimerService.countdownRunning && TimerService.countdownSecondsLeft <= 0)
                root.showEvent("alarm", IrisStyle.identity.orange, Translation.tr("Time's up"),
                    Translation.tr("%1 timer").arg(root.durationText(TimerService.countdownDuration)), -1)
        }
        function onPomodoroBreakChanged(): void {
            if (!TimerService.pomodoroRunning) return
            root.showEvent(TimerService.pomodoroBreak ? "coffee" : "self_improvement", IrisStyle.identity.orange,
                TimerService.pomodoroBreak ? (TimerService.pomodoroLongBreak ? Translation.tr("Long break") : Translation.tr("Break"))
                    : Translation.tr("Focus"),
                root.durationText(TimerService.pomodoroLapDuration), -1)
        }
    }
    // Unlocked: a face drawn in green, as a phone's Face ID says it knew you.
    Connections {
        target: root.noticeOn("unlock") ? GlobalStates : null
        function onScreenLockedChanged(): void {
            if (!GlobalStates.screenLocked) unlockLater.restart()
        }
    }
    Timer { id: unlockLater; interval: 450; onTriggered: root.showEvent("face", IrisStyle.identity.green, Translation.tr("Unlocked"), "", -1, "unlock") }
    // An event about to start, as a phone's calendar activity: its name, how soon, a ring closing on the start.
    // Said at the lead chosen (10, 5 or 1 minute) and at each shorter mark, once each.
    property string eventSaid: ""
    readonly property int upcomingLead: [10, 5, 1].includes(Number(root.notices?.upcomingLead)) ? Number(root.notices.upcomingLead) : 10
    Timer {
        interval: 30000
        repeat: true
        running: root.noticeOn("upcoming") && root.focusedOutput
        onTriggered: {
            const entry = IrisFaces.IrisFaceData.nextEntry(Date.now(), 11)
            if (entry.running || entry.title.length === 0 || entry.start <= 0) return
            const mark = [10, 5, 1].filter(at => at <= root.upcomingLead).find(at => entry.left <= at && entry.left > at - 1)
            const key = entry.start + ":" + mark
            if (mark === undefined || root.eventSaid === key) return
            root.eventSaid = key
            root.showEvent("event", IrisStyle.danger, entry.title,
                entry.left <= 1 ? Translation.tr("Starting now") : Translation.tr("In %1 min").arg(entry.left), 1 - entry.left / root.upcomingLead, "soon")
        }
    }
    // Rain on its way (Apple Weather's next hour): the first wet slot after a dry now, said once per slot.
    property string rainSaid: ""
    readonly property var wetGlyphs: ["rainy", "thunderstorm", "weather_hail", "weather_snowy", "cloudy_snowing", "rainy_light", "rainy_heavy"]
    Connections {
        target: root.noticeOn("rain") && Weather.enabled ? Weather : null
        function onDataChanged(): void {
            const glyphOf = code => Icons.getWeatherIcon(code, false) ?? ""
            if (root.wetGlyphs.includes(glyphOf(Weather.data?.wCode))) return
            const slots = Array.from(Weather.data?.hourly ?? []).slice(1, 4)
            const wet = slots.find(slot => root.wetGlyphs.includes(glyphOf(slot.code)))
            if (!wet || root.rainSaid === String(wet.label)) return
            root.rainSaid = String(wet.label)
            const snow = /snow/.test(glyphOf(wet.code))
            root.showEvent(glyphOf(wet.code), IrisStyle.identity.sky, snow ? Translation.tr("Snow soon") : Translation.tr("Rain soon"),
                Translation.tr("Around %1").arg(String(wet.label).slice(0, 5)), -1)
        }
    }
    // The sound muted from anywhere: the red Silent pill.
    readonly property bool sinkMuted: Audio.sink?.audio?.muted ?? false
    onSinkMutedChanged: if (root.sinkMuted && !root.feedback && root.noticeOn("silent")) root.showEvent("notifications_off", IrisStyle.danger, Translation.tr("Silent"), "", -1, "silent")
    // A screenshot just taken: its picture as a card at the end; a tap opens it.
    readonly property var latestShot: Shelf.items.find(item => item.origin === "shot") ?? null
    property string shownShot: ""
    onLatestShotChanged: {
        const shot = root.latestShot
        if (!shot || shot.path === root.shownShot) return
        const fresh = Date.now() - Number(shot.at ?? 0) < 15000
        const first = root.shownShot.length === 0
        root.shownShot = shot.path
        if (!fresh || first && !eventsWarm.ready || !root.noticeOn("screenshot")) return
        root.eventImage = "file://" + shot.path
        root.showEvent("screenshot_region", IrisStyle.identity.blue, Translation.tr("Screenshot saved"), String(shot.name ?? ""), -1, "shot")
    }
    property int lastRecordingSeconds: 0
    onRecordingChanged: {
        if (root.recording) root.lastRecordingSeconds = 0
        else if (root.noticeOn("recording") && root.lastRecordingSeconds > 0)
            root.showEvent("stop_circle", IrisStyle.danger, Translation.tr("Recording saved"), root.clockText(root.lastRecordingSeconds), -1)
    }
    Connections {
        target: root.recording ? RecorderStatus : null
        function onElapsedSecondsChanged(): void {
            if (RecorderStatus.elapsedSeconds > 0) root.lastRecordingSeconds = RecorderStatus.elapsedSeconds
        }
    }
    Connections {
        target: root.noticeOn("soundGuard") ? Audio : null
        function onSinkProtectionTriggered(reason: string): void {
            root.showEvent("volume_off", IrisStyle.danger, Translation.tr("Volume held back"), reason, -1)
        }
    }
    Connections {
        target: root.eventsEnabled ? GlobalStates : null
        function onOsdMediaActionTriggered(action: string): void {
            if (root.osdMediaMode !== "off") root.showTrack(action)
        }
    }
    Connections {
        target: root.eventsEnabled && root.osdMediaMode === "every" ? MprisController : null
        function onTrackChanged(reverse: bool): void {
            if (root.eventShown || root.title.length === 0) return
            root.showTrack("")
        }
    }
    function showTrack(action: string): void {
        if (!root.hasMedia || root.primary === "media" || root.osdGameRule !== "show") return
        const title = StringUtils.cleanMusicTitle(root.title)
        root.showEvent(action === "next" ? "skip_next" : action === "previous" ? "skip_previous"
            : action === "pause" ? "pause" : action === "play" ? "play_arrow" : "music_note", IrisStyle.accent,
            title.length > 0 ? title : Translation.tr("Now playing"),
            root.ytMusic ? YtMusic.currentArtist : String(MprisController.artistOf(root.player) ?? ""), -1)
    }
    Connections {
        target: root.eventsEnabled ? KeyboardIndicators : null
        function onPopupSequenceChanged(): void {
            if (!KeyboardIndicators.ready || !root.osdKeyboard) return
            const kind = KeyboardIndicators.popupKind
            const active = KeyboardIndicators.popupActive
            root.showBadge(KeyboardIndicators.popupMaterialIcon,
                kind === "layout" ? IrisStyle.accent : active ? IrisStyle.secondaryAccent : IrisStyle.subtext,
                kind === "layout"
                    ? (KeyboardIndicators.currentLayoutCodeInline || KeyboardIndicators.popupText)
                    : KeyboardIndicators.popupText)
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
    readonly property color artTint: IrisStyle.artTintOf(tintQuantizer.colors)
    // Whether the record is laid under the media page, so a Design's page sets its inks on it.
    readonly property bool artBehind: artBackdrop.active

    readonly property bool visualExpanded: root.expanded && details.status === Loader.Ready
    readonly property real bubble: root.compactHeight
    readonly property real satelliteGap: Math.round(Math.max(0, Math.min(24, Number(Config.options?.iris?.bar?.satelliteGap ?? 6))) * root.d)
    readonly property real satelliteOffset: root.satelliteGap + Math.round(IrisStyle.fuseEdge / 4 * root.notchness)
    readonly property real fillet: Math.round(chassis.radius * 0.62 * root.notchness)
    readonly property real expandedRoom: root.vertical ? root.availableAcross : root.availableWidth - 2 * (root.bubble + root.satelliteGap)
    readonly property real pageBodyWidth: root.effectivePage === "controls" ? (Math.max(340, Number(Config.options?.iris?.controlCenter?.width ?? 360))
            + (IrisState.controlEdit ? IrisControlOptions.editorExtra : 0)) * root.d + 2 * root.padding
            : (root.effectivePage === "activity" ? root.pageWidth * 384 / 440 : root.pageWidth) * root.d
    readonly property int navButtons: root.navEntries.filter(entry => entry.kind !== "|").length
    readonly property int navDividers: root.navEntries.length - root.navButtons
    readonly property real navFixed: root.navDividers * Math.round(9 * root.d) + Math.max(0, root.navEntries.length - 1) * 4 * root.d
        + 2 * (["veil", "glass", "solid"].includes(root.pagePlate) ? Math.round(4 * root.d) : 0)
    readonly property real navSlot: Math.max(Math.round(30 * root.d), Math.min(Math.round(36 * root.d),
        Math.floor((Math.min(root.expandedRoom, root.pageBodyWidth) - 2 * root.padding - root.navFixed) / Math.max(1, root.navButtons))))
    readonly property real navWidth: root.navFixed + root.navButtons * root.navSlot
    // A moment the Island says by itself (a notice, an event, a level, a held drop) grows it for seconds: it is open,
    // never its resting shape, so the plates and lines that take the Island's measure keep theirs (islandGeometry).
    readonly property bool momentShown: !root.expanded && ["drop", "feedback", "event", "notice"].includes(root.compactMode)
    // Once per open or moment, so the bubbles on its row can step aside (IrisStage.stepAside).
    readonly property real openWidth: root.vertical || root.spanning ? 0
        : root.expanded ? root.expandedWidth : root.momentShown ? root.compactTargetWidth : 0
    onOpenWidthChanged: {
        const name = root.targetScreen?.name ?? ""
        if (name.length === 0) return
        const widths = Object.assign({}, IrisState.islandOpenWidth ?? {})
        widths[name] = root.openWidth
        IrisState.islandOpenWidth = widths
    }
    readonly property real expandedWidth: Math.min(root.expandedRoom, Math.max(root.pageBodyWidth, root.navWidth + 2 * root.padding))
    readonly property real pageWidth: Math.max(360, Math.min(600, Number(root.options?.pageWidth ?? 440)))
    readonly property real padding: Math.round(20 * root.d)
    readonly property bool editingDesktop: GlobalStates.widgetEditMode
        && root.targetScreen?.name === GlobalStates.focusedScreen?.name
    // A file held over the Island (AirDrop's radar): what it carries, and the Shelf it lands on if it waits there.
    property bool dropHover: false
    property int dropCount: 0
    property bool dropFiles: true
    Timer {
        id: dropSpring
        interval: 1100
        onTriggered: if (root.dropHover) { root.dropHover = false; root.openPage("shelf", true) }
    }
    Connections {
        target: IrisState
        function onDropRehearsalChanged(): void {
            const sim = IrisState.dropRehearsal
            if (!sim || !root.focusedOutput || root.expanded) return
            root.dropFiles = true
            root.dropCount = sim.count
            root.dropHover = true
            dropRehearsalEnd.restart()
        }
    }
    Timer {
        id: dropRehearsalEnd
        interval: 1600
        onTriggered: {
            root.dropHover = false
            const sim = IrisState.dropRehearsal
            if (sim?.keep && root.noticeOn("shelf")) root.showEvent("check", IrisStyle.accent, Translation.tr("On the Shelf"),
                sim.count === 1 ? Translation.tr("1 file") : Translation.tr("%1 files").arg(sim.count), 1, "kept")
        }
    }
    readonly property string compactMode: root.dropHover && !root.anchored && !root.expanded ? "drop"
        : root.feedback && !root.anchored ? "feedback"
        : root.eventShown && !root.anchored ? (root.noticeGrows ? "notice" : "event")
        : IrisStyle.cluster && !root.zoned ? (root.islandActivity.length > 0 ? root.islandActivity : "clock") : root.primary
    readonly property string layout: String(root.options?.layout ?? "island")
    // Menu bar: a thin strip across the edge with the heart hanging from its middle as a notch.
    readonly property bool menubar: root.layout === "menubar" && !root.vertical
    // Pods: the spanning bar without a strip: its start, the Island and its end are three bodies on one line, melting
    // into each other only where they come close (a wide activity).
    readonly property bool pods: root.layout === "pods" && !root.vertical
    readonly property bool fullWidth: root.layout === "full" || root.menubar || root.pods
    // Corner: Left or Right across an edge, docked in that corner and filleted into both walls when welded. Its
    // bubbles rest on the inner side; the room the item keeps on the wall side is handed back (IrisBar places it).
    readonly property string cornerSide: !root.vertical && (root.layout === "left" || root.layout === "right") ? root.layout : ""
    readonly property real wallSlack: root.cornerSide.length > 0 ? Math.max(root.sideReserve, root.fillet) * Math.min(1, root.notchness) : 0
    // A clear menu bar leaves its items on the wallpaper (macOS): the notch is the only body on the edge.
    readonly property bool clearStrip: root.menubar && String(root.options?.strip ?? "clear") === "clear"
    readonly property bool fromHeart: root.zoned && root.heartShown && root.extensionRole === "page"
        && !(root.extensionOrigin?.visible ?? false)
    // Shelf (the full layout): how far the Island rises out of the shelf's middle (Settings › Island › Island rise).
    readonly property real heartSwell: Math.round(({ none: 0, low: 10, deep: 20 })[String(root.options?.rise ?? "deep")] ?? 20) * root.d
    // A page from a bar's heart is the Island growing: one body from the screen edge over the heart, its own
    // corners past the edge, so one material and one light run from the edge down; the heart row fades under it.
    readonly property bool grownPage: root.zoned && root.fromHeart
    readonly property real grownInset: root.grownPage ? Math.ceil(extension.targetRadius) : 0
    readonly property real heartUncovered: root.grownPage ? Math.max(0, 1 - 2.5 * extension.presentation) : 1
    // The heart's lip is the notch gesture: a bar with the notch off keeps one straight edge.
    readonly property bool swellsHeart: root.layout === "full" && !root.vertical && root.heartShown && root.heartSwell > 0
    // A bar melted into the frame reads as one body from the screen edge down: its lanes centre in that whole
    // body, band included, not in the part below the band.
    readonly property real bandLift: root.zoned && !root.vertical && IrisFrame.framed
        ? IrisFrame.band * Math.min(1, Math.max(0, root.notchness)) / 2 : 0
    readonly property real stripHeight: root.menubar ? Math.max(Math.round(24 * root.d), Math.round(root.compactHeight * 0.72)) : root.compactHeight
    readonly property real notchX: chassis.x + barZones.heartAlong
    readonly property rect notchArea: root.menubar && root.heartShown
        ? Qt.rect(root.notchX, root.bottomEdge ? root.height - root.compactHeight : 0, root.heartLength, root.compactHeight)
        : Qt.rect(0, 0, 0, 0)
    function zoneArea(rect: rect): rect {
        void (root.x + root.y + chassis.x + chassis.y + barZones.x + barZones.y)
        if (!root.menubar || rect.width <= 0 || rect.height <= 0) return Qt.rect(0, 0, 0, 0)
        const at = barZones.mapToItem(root, rect.x, rect.y)
        return Qt.rect(at.x, at.y, rect.width, rect.height)
    }
    readonly property rect menuStartArea: root.zoneArea(barZones.startArea)
    readonly property rect menuEndArea: root.zoneArea(barZones.endArea)
    readonly property bool zoned: root.fullWidth
    readonly property bool heartShown: !root.zoned || root.compactMode !== "idle" || !barZones.hasTime
    readonly property real heartTarget: !root.heartShown ? 0
        : Math.max(root.compactFloor, Math.min(root.compactCeiling, root.compactContentWidth + Math.round(29 * root.d * root.breathing)))
    readonly property alias heartLength: heartSpring.value
    IrisSpring { id: heartSpring; surface: "island"; intent: "move"; to: root.heartTarget; minimum: 0; epsilon: 0.25 }
    readonly property real fullChassisWidth: Math.max(0,
        root.availableWidth - 2 * Math.max(root.sideReserveTarget, root.fillet))
    readonly property bool anchored: root.fullWidth || root.vertical
    // A page is the Island itself growing, on every edge; only a full bar hangs its page beside the strip. On a
    // side edge compact activities (a level, an event) still ride beside the upright capsule.
    readonly property bool inlinePages: !root.fullWidth && !root.pagesHang
    // The page is built synchronously (~90 ms): starting the shape before it is
    // ready spends the first frames of the morph inside that build.
    readonly property bool pageReady: !root.expanded || details.status === Loader.Ready
    readonly property bool inlineExpanded: root.visualExpanded && root.inlinePages && root.pageReady
    readonly property bool compactSizeClass: ["feedback", "event", "notice", "drop"].includes(root.compactMode)
    readonly property bool spanning: root.fullWidth
    readonly property var compactRows: ({ idle: idleRow, media: idleRow, record: recordRow,
        timer: timerRow, task: taskRow, mic: micRow, camera: cameraRow, clock: clockRow, event: eventRow, feedback: feedbackRow,
        drop: dropRow })
    readonly property real compactContentWidth: root.vertical ? compactColumn.implicitHeight
        : root.faceTakes ? (designFace.item?.contentWidth ?? 0) + 2 * root.wingSlot
        : (root.compactRows[root.compactMode]?.implicitWidth ?? 0) + 2 * root.wingSlot
    readonly property real compactFloor: root.compactHeight * 2.1
    // A larger clock (Settings › Island › Size) takes a wider resting Island with it, so a face keeps its extras.
    readonly property real idleCeiling: Math.round(320 * root.d * Math.max(1, root.clockScale))
    readonly property real compactCeiling: Math.min(root.availableWidth, root.songWings ? root.idleCeiling + 2 * root.wingSlot
        : root.compactMode === "event" || root.compactMode === "drop" ? 340 * root.d : root.idleCeiling)
    // The room a Design's face has at rest: the idle ceiling, less the Island's breathing and the pieces it carries.
    // A face that would pass it gives up its extras first (designs/*/Face.qml), so the Island never cuts it.
    readonly property real faceRoom: Math.max(0, Math.min(root.idleCeiling, root.availableWidth - root.barPieceReserve - 2 * root.wingSlot)
        - Math.round(29 * root.d * root.breathing))
    // The ceiling holds the Island's own content; the pieces it carries come on top of it, or they would be
    // squeezed over the clock.
    readonly property real compactTargetWidth: root.spanning ? root.fullChassisWidth
        : root.compactMode === "notice" ? root.noticeWidth
        : Math.max(root.compactFloor, Math.min(root.availableWidth, Math.min(root.compactCeiling,
            root.compactContentWidth + Math.round(29 * root.d * root.breathing)) + root.barPieceReserve))
    readonly property real chassisTargetWidth: root.inlineExpanded ? root.expandedWidth : root.compactTargetWidth
    readonly property string clockStyle: {
        const style = String(IrisStyle.structuralValue("bar.clockStyle", "dateTime"))
        // A bar that already carries the calendar or the weather piece does not say it twice beside the time.
        if (root.zoned && style === "dateTime" && barZones.itemFor("calendar")) return "time"
        if (root.zoned && style === "weather" && barZones.itemFor("weather")) return "time"
        return style === "weather" && !(Weather.enabled && !String(Weather.data?.temp ?? "--").startsWith("--")) ? "time" : style
    }
    readonly property string trailing: String(IrisStyle.structuralValue("bar.trailing", "controls"))
    readonly property string trailingKind: root.trailing === "notifications" && (Notifications.list?.length ?? 0) === 0 ? "none" : root.trailing
    readonly property bool leftSatelliteShown: root.leftSatelliteRest && !root.inlineExpanded
    readonly property bool leftSatelliteRest: IrisStyle.cluster && !root.zoned
        && !root.floatingSlots.includes("left")
        && root.leftKind.length > 0
    readonly property bool rightSatelliteShown: root.rightSatelliteRest && !root.inlineExpanded
    function floatsAlone(kind: string): bool { return IrisPieces.floats(Config.options?.iris?.bubbles, kind) }
    readonly property bool rightSatelliteRest: !root.zoned
        && !root.floatingSlots.includes("right") && !(IrisStyle.cluster && root.floatsAlone(root.trailingKind))
        && (IrisStyle.cluster ? root.trailingKind !== "none" : root.secondary.length > 0)

    readonly property var trayItems: SystemTray.items.values.filter(item => item && item.id
        && (!(Config.options?.iris?.tray?.hidePassive ?? false) || item.status !== Status.Passive))
    readonly property string auxiliary: String(IrisStyle.structuralValue("bar.auxiliary", "tray"))
    readonly property int auxiliarySlot: (IrisStyle.cluster ? root.trailingKind !== "none" && !root.floatsAlone(root.trailingKind) : root.secondary.length > 0)
        && !root.floatingSlots.includes("right") ? 2 : 1
    readonly property bool auxiliaryShown: root.auxiliaryRest && !root.inlineExpanded
    readonly property bool auxiliaryRest: !root.zoned && root.auxiliary !== "none"
        && !root.floatsAlone(root.auxiliary)
        && !root.floatingSlots.includes("utility")
        && (root.auxiliary !== "tray" || (root.trayItems.length > 0 && !root.trayAppsFace))
    readonly property bool trayAppsFace: String(Config.options?.iris?.tray?.face ?? "apps") === "apps"
    readonly property string trayMenuToward: root.edge === "bottom" ? "up" : root.edge === "left" ? "right"
        : root.edge === "right" ? "left" : "down"
    readonly property var absorbed: IrisState.absorbed?.[root.targetScreen?.name ?? ""] ?? ({})
    readonly property var absorbedPieces: Array.from(root.absorbed?.island ?? [])
    readonly property var absorbedStart: Array.from(root.absorbed?.islandStart ?? [])
    function pieceTaken(kind: string): bool {
        if (root.absorbedPieces.includes(kind)) return false
        if (root.floatsAlone(kind)) return true
        if (root.auxiliaryRest && root.auxiliary === kind) return true
        if (root.rightSatelliteRest && IrisStyle.cluster && root.trailingKind === kind) return true
        return root.leftSatelliteRest && kind === "media" && root.leftKind === "media"
    }
    readonly property var barPieces: {
        const carried = IrisPieces.carriedBy(Config.options?.iris?.bubbles, IrisStyle.structuralValue("bar.pieces", []))
        for (const kind of root.absorbedPieces) if (!carried.includes(kind)) carried.push(kind)
        if (root.auxiliary === "tray" && root.trayAppsFace && !root.floatsAlone("tray")
                && !root.floatingSlots.includes("utility") && !carried.includes("tray"))
            carried.push("tray")
        return carried.filter(kind => IrisPieces.extraIds.includes(kind) && IrisPieces.available(kind) && !root.pieceTaken(kind))
    }
    readonly property real barPieceSize: Math.round(root.compactHeight - 10 * root.d)
    readonly property real barPieceGap: Math.round(6 * root.d)
    readonly property bool piecesAtStart: String(root.options?.piecesSide ?? "end") === "start"
    readonly property real trayStripGap: Math.round(4 * root.d)
    function barPieceAlong(kind: string): real {
        if (kind !== "tray" || !root.trayAppsFace) return root.barPieceSize
        const count = Math.max(1, root.trayItems.length)
        return count * root.barPieceSize + (count - 1) * root.trayStripGap
    }
    readonly property real barPieceReserve: root.zoned || root.barPieces.length === 0 ? 0
        : root.barPieces.reduce((sum, kind) => sum + root.barPieceAlong(kind), 0)
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
    readonly property bool extensionOpen: root.wantedRole.length > 0 && (root.anchored
        ? !(root.inlinePages && root.wantedRole === "page") : root.pagesHang && root.wantedRole === "page")
    readonly property real joinFillet: Math.round(root.compactHeight * 0.6)
    readonly property real floatGap: Math.round(6 * root.d)
    readonly property Item extensionOrigin: root.extensionRole === "page" ? root.pageOrigin
        : root.extensionRole === "feedback"
            ? root.pieceItem(root.feedbackKind === "mic" ? "mic" : root.feedbackKind === "brightness" ? "tools" : "sound")
        : null
    readonly property real originWidth: root.pagesHang ? extension.targetWidth
        : root.extensionOrigin?.visible
        ? (root.vertical ? root.extensionOrigin.height : root.extensionOrigin.width)
        : root.fromHeart && root.heartLength > 1 ? root.heartLength
        : Math.round(40 * root.d)
    readonly property real originCenterX: {
        const part = root.extensionOrigin
        if (part && part.visible) return part.mapToItem(root, part.width / 2, 0).x
        if (!root.zoned && root.extensionRole === "page" && root.pageOriginX >= 0) return root.pageOriginX
        if (root.zoned && root.heartShown) return chassis.x + barZones.heartAlong + root.heartLength / 2
        return chassis.x + chassis.width / 2
    }
    function extensionX(width: real): real {
        const inset = chassis.radius + root.joinFillet
        const min = chassis.x + inset
        const max = chassis.x + chassis.width - inset - width
        return Math.round(Math.max(min, Math.min(max, root.originCenterX - width / 2)))
    }
    readonly property real originCenterY: {
        const part = root.extensionOrigin
        if (part && part.visible) return part.mapToItem(root, 0, part.height / 2).y
        if (!root.zoned && root.extensionRole === "page" && root.pageOriginY >= 0) return root.pageOriginY
        if (root.zoned && root.heartShown) return chassis.y + barZones.heartAlong + root.heartLength / 2
        return chassis.y + chassis.height / 2
    }
    function extensionY(height: real): real {
        if (root.fullWidth) {
            const inset = chassis.radius + root.joinFillet
            return Math.round(Math.max(chassis.y + inset, Math.min(chassis.y + chassis.height - inset - height, root.originCenterY - height / 2)))
        }
        const sceneY = root.parent?.y ?? 0
        const screenH = root.Window.window?.height ?? root.targetScreen?.height ?? 1080
        const min = IrisFrame.safeInset("top") + Math.round(8 * root.d) - sceneY
        const max = screenH - IrisFrame.safeInset("bottom") - Math.round(8 * root.d) - sceneY - height
        return Math.round(Math.max(min, Math.min(max, root.originCenterY - height / 2)))
    }

    implicitWidth: root.vertical ? chassis.across + (extension.anchoredShape ? extension.reach : 0)
        : Math.max(chassis.width + 2 * Math.max(root.sideReserve, root.fillet), root.pagesHang ? extension.width : 0)
    implicitHeight: root.vertical ? chassis.height + 2 * Math.max(root.sideReserve, root.fillet)
        : chassis.bodyHeight + (root.anchored || root.pagesHang ? extension.reach + root.seam * extension.presentation : 0)
    readonly property rect extensionArea: (root.anchored || root.pagesHang) && extension.reach > 0.5
        ? Qt.rect(extension.x, extension.y, extension.width, extension.height)
        : Qt.rect(0, 0, 0, 0)
    // The input region is a Wayland commit: while a shape is under way it only
    // grows, so a collapsing Island does not hand the compositor a region a frame.
    readonly property bool morphing: (chassis.presentation > 0.002 && chassis.presentation < 0.998)
        || (extension.presentation > 0.002 && extension.presentation < 0.998)
        || (root.noticeOpen > 0.002 && root.noticeOpen < 0.998)
    readonly property real inputWidthLive: root.vertical ? Math.max(root.implicitWidth, root.inlineExpanded ? root.expandedWidth : 0)
        : Math.max(root.implicitWidth, root.chassisTargetWidth + 2 * Math.max(root.sideReserveTarget, root.fillet))
    readonly property real inputHeightLive: root.vertical ? Math.max(root.implicitHeight,
        (root.inlineExpanded ? chassis.openHeightTarget : root.compactTargetWidth) + 2 * Math.max(root.sideReserveTarget, root.fillet))
        : Math.max(chassis.bodyHeight, chassis.bodyHeightTarget)
    property real inputWidthHeld: 0
    property real inputHeightHeld: 0
    function holdInput(): void {
        root.inputWidthHeld = root.morphing ? Math.max(root.inputWidthHeld, root.inputWidthLive) : root.inputWidthLive
        root.inputHeightHeld = root.morphing ? Math.max(root.inputHeightHeld, root.inputHeightLive) : root.inputHeightLive
    }
    onInputWidthLiveChanged: root.holdInput()
    onInputHeightLiveChanged: root.holdInput()
    onMorphingChanged: { root.holdInput(); if (!root.morphing) geometrySettle.restart() }
    readonly property real inputWidth: Math.max(root.inputWidthLive, root.inputWidthHeld)
    readonly property real inputHeight: Math.max(root.inputHeightLive, root.inputHeightHeld)

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
    readonly property bool suppressed: root.fullscreenCovered && !root.feedback && !root.expanded
    opacity: root.suppressed ? 0 : 1
    // Opacity only, on the whole Island: toggling visible or animating the chassis opacity leaves it unpainted.
    Behavior on opacity {
        NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing }
    }

    property point pointerScene: Qt.point(-1000, -1000)
    function trackDwell(position: point): void {
        root.pointerScene = position
        if (root.feedback || root.editingDesktop || wheelQuiet.running) { hoverDelay.stop(); return }
        if (Math.abs(position.x - root.dwellAnchor.x) + Math.abs(position.y - root.dwellAnchor.y) < 4) return
        root.dwellAnchor = position
        if ((root.options?.hoverExpand ?? true) && root.hoverArmed && !root.fullWidth && !root.expanded
                && root.pointerOnIsland && !root.pieceHovered)
            hoverDelay.restart()
    }

    // Pieces carried on the Island answer to taps and to being carried away. Peeking
    // on hover would move them out from under the pointer before either can happen.
    property int hoveredPieces: 0
    readonly property bool pieceHovered: root.hoveredPieces > 0 || leftSatellite.hovered
        || rightSatellite.hovered || auxiliarySatellite.hovered

    property bool hoverArmed: true
    onPointerOnIslandChanged: {
        if (root.pointerOnIsland) {
            leaveDelay.stop()
        } else {
            root.hoverArmed = true
            hoverDelay.stop()
            if (root.wheelHold) { root.wheelHold = false; feedbackTimer.restart() }
            if (root.expanded && !root.pinned && !root.pointerHeld) leaveDelay.restart()
        }
    }
    Timer {
        id: hoverDelay
        interval: Math.max(120, Number(root.options?.hoverDelay ?? 300))
        onTriggered: {
            if (!root.hoverArmed || !root.pointerOnIsland || root.expanded || root.feedback || root.editingDesktop || wheelQuiet.running) return
            if (root.pieceHovered) return
            if (root.tapPage === "desktop") root.openPage("desktop", false, null)
        }
    }
    Timer { id: wheelQuiet; interval: 900 }
    Timer { id: leaveDelay; interval: 450; onTriggered: { if (!root.pointerOnIsland && !root.pointerHeld && !root.pinned) root.expanded = false } }
    Timer { id: pageIntentExpiry; interval: 1800; onTriggered: root.pageIntent = "" }


    property real wheelAccumulator: 0
    function wheelSteps(event): int {
        root.wheelAccumulator += event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y * 4
        const steps = Math.trunc(root.wheelAccumulator / 120)
        root.wheelAccumulator -= steps * 120
        return steps
    }
    function stepLevel(level: string, steps: int): void {
        if (level === "brightness") {
            if (root.brightnessMonitor)
                root.brightnessMonitor.setBrightness(Math.max(0, Math.min(1, root.brightnessMonitor.brightness + steps * 0.05)))
        } else if (level === "mic") {
            Audio.setSourceVolume(Math.max(0, Math.min(1, (Audio.micVolume ?? 0) + steps * 0.05)))
        } else {
            Audio.setSinkVolume(Math.max(0, Math.min(Math.max(1, Audio.ceiling), (Audio.value ?? 0) + steps * 0.05)))
        }
    }
    function applyWheel(event): void {
        if (root.expanded) { root.wheelPages(event, false); return }
        const action = String(root.options?.scrollAction ?? "volume")
        if (action === "none") return
        hoverDelay.stop()
        wheelQuiet.restart()
        root.dwellAnchor = root.pointerScene
        const steps = root.wheelSteps(event)
        if (steps === 0) return
        const level = event.modifiers & Qt.ControlModifier ? "mic"
            : (action === "brightness") !== Boolean(event.modifiers & Qt.ShiftModifier) ? "brightness" : "volume"
        root.wheelHold = root.pointerOnIsland
        root.stepLevel(level, steps)
    }
    function applySatelliteWheel(event, satellite): void {
        hoverDelay.stop()
        wheelQuiet.restart()
        const steps = root.wheelSteps(event)
        if (steps === 0) return
        const level = satellite.kind === "mic" || (satellite.kind !== "sound" && (event.modifiers & Qt.ControlModifier)) ? "mic" : "sound"
        satellite.showLevel(level)
        IrisState.quietLevels()
        root.stepLevel(level === "mic" ? "mic" : "volume", steps)
    }
    readonly property var cardKinds: IrisPieces.cardIds
    readonly property bool opensCards: String(Config.options?.iris?.bubbles?.opens ?? "card") === "card"
    function toggleBubbleCard(kind: string, part, source: string): void {
        if (IrisState.bubbleCard?.source === source) { IrisState.bubbleCard = null; return }
        const isChassis = part === chassis
        const r = root.partRect(part)
        const band = root.chassisBody()
        IrisState.bubbleCard = {
            kind: kind, source: source, screen: root.targetScreen?.name ?? "", edge: root.edge,
            x: r.x, y: r.y + root.screenOffsetY,
            width: r.width, height: r.height,
            radius: isChassis ? chassis.radius : IrisStyle.pieceRadius(Math.min(r.width, r.height)),
            bandX: band.x, bandWidth: band.width,
            bandY: band.y + root.screenOffsetY, bandHeight: band.height
        }
    }
    Connections {
        target: IrisState
        function onBubbleCardRequestChanged(): void {
            if (IrisState.bubbleCardRequest.length === 0 || !root.focusedOutput) return
            Qt.callLater(() => {
                const kind = IrisState.bubbleCardRequest
                if (kind.length === 0) return
                IrisState.bubbleCardRequest = ""
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
        if (root.zoned) return barZones.itemFor(kind)
        if (!root.barPieces.includes(kind)) return null
        const row = barPieceRow.children
        for (let i = 0; i < row.length; i++) {
            if (row[i] && row[i].visible && String(row[i].modelData ?? "") === kind) return row[i]
        }
        return null
    }
    // Customize selects a carried piece by its mark inside the Island, under the same id as a floating one.
    readonly property var carriedShapes: {
        if (!IrisState.edit) return []
        void (root.x + root.y + chassis.x + chassis.width + (root.parent?.x ?? 0) + (root.parent?.y ?? 0) + root.heartLength)
        const out = []
        const kinds = root.zoned ? [].concat(...barZones.entries) : root.barPieces
        for (const kind of kinds) {
            if (!IrisPieces.extraIds.includes(String(kind))) continue
            const item = root.pieceItem(String(kind))
            if (!item || !item.visible || item.width <= 0) continue
            const at = item.mapToItem(root.QsWindow.window?.contentItem, 0, 0)
            const size = Math.min(item.width, item.height)
            out.push({ id: "piece:extra-" + kind, x: at.x + (item.width - size) / 2, y: at.y + (item.height - size) / 2,
                width: size, height: size, radius: IrisStyle.pieceRadius(size) })
        }
        return out
    }
    // A piece the Island carries is still the stage's piece: what it opens, and where
    // that body grows from, is the same as when it floats.
    signal pieceActivated(string slot, string kind, var rect)
    function pieceOpen(kind: string, part): bool {
        const card = IrisState.bubbleCard
        if (card && card.source === "island-piece-" + kind && card.screen === (root.targetScreen?.name ?? "")) return true
        if (part && root.expanded && root.pageOrigin === part) return true
        return kind === "controls" && root.focusedOutput && GlobalStates.controlPanelOpen && !root.expanded
    }
    function activatePiece(kind: string, part): void {
        if (IrisPieces.act(kind, root.targetScreen?.name ?? "")) return
        if (root.opensCards && root.cardKinds.includes(kind) && part) {
            root.toggleBubbleCard(kind, part, "island-piece-" + kind)
            return
        }
        const r = part ? root.partRect(part) : root.chassisBody()
        root.pieceActivated("extra-" + kind, kind, { x: r.x, y: r.y + root.screenOffsetY,
            size: Math.min(r.width, r.height), source: "island-piece-" + kind })
    }
    function activateBubble(kind: string, part): void {
        if (IrisPieces.act(kind, root.targetScreen?.name ?? "")) return
        if (root.opensCards && root.cardKinds.includes(kind) && part) root.toggleBubbleCard(kind, part, "island-" + part.slot)
        else if (kind === "sound") Audio.toggleMute()
        else if (kind === "mic") Audio.toggleMicMute()
        else if (kind === "notifications" || kind === "calendar") GlobalStates.openSidebarRight(root.targetScreen?.name ?? "")
        else if (kind === "focus") Notifications.silent = !Notifications.silent
        else if (kind === "weather" || kind === "clock") root.openPage("desktop", true, part)
        else if (kind === "tray" || kind === "tools") root.openPage(kind, true, part)
        else root.openControlCenterFrom(part)
    }

    onPageChanged: if (root.controlsInIsland && root.page !== "controls" && root.focusedOutput
        && GlobalStates.controlPanelOpen && IrisState.morphOwner !== "stage") GlobalStates.controlPanelOpen = false
    onExpandedChanged: {
        if (!root.expanded && root.page === "controls" && root.focusedOutput && IrisState.morphOwner !== "stage")
            GlobalStates.controlPanelOpen = false
        if (!root.expanded) {
            root.pinned = false
            root.pageIntent = ""
            pageIntentExpiry.stop()
            if (root.pointerOnIsland) root.hoverArmed = false
        }
        else root.wheelHold = false
        if (root.expanded && root.focusedOutput) IrisState.bubbleCard = null
    }
    onVisualExpandedChanged: root.flyParts()
    readonly property real heroDecodeWidth: Math.round(Math.min(root.availableWidth - 2 * (root.bubble + root.satelliteGap), root.pageWidth * root.d) * 1.5)
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
    readonly property Item restingCover: IrisStyle.cluster && leftSatellite.shown
        ? (root.primary === "media" ? leftSatellite.artwork : null)
        : (root.compactMode === "media" && !root.vertical ? wingCover : null)
    readonly property Item restingClock: root.vertical ? null : root.compactMode === "clock" ? clusterClock
        : root.compactMode === "idle" || root.haloWings ? idleClock : null
    function flyParts(): void {
        // Only the arrival flies: closing, the part rides the shape home, and a
        // copy crossing a page that is still opaque read as a second design.
        if (!root.visualExpanded) { coverFlight.stop(); clockFlight.stop(); return }
        const cover = root.effectivePage === "media" ? root.pageCover : null
        const clock = root.effectivePage === "desktop" ? root.heroClock : null
        if (cover && root.restingCover) coverFlight.launch(root.restingCover, cover)
        else coverFlight.stop()
        if (clock && root.restingClock) clockFlight.launch(root.restingClock, clock)
        else clockFlight.stop()
    }
    onEffectivePageChanged: if (root.visualExpanded) { coverFlight.stop(); clockFlight.stop() }
    Binding {
        target: IrisState
        property: "islandShape"
        value: root.expanded ? "expanded" : root.compactMode
        when: root.targetScreen?.name === GlobalStates.focusedScreen?.name
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: IrisState
        property: "islandExpanded"
        value: root.expanded
        when: root.targetScreen?.name === GlobalStates.focusedScreen?.name
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: IrisState
        property: "islandPage"
        value: root.expanded ? root.effectivePage : ""
        when: root.targetScreen?.name === GlobalStates.focusedScreen?.name
        restoreMode: Binding.RestoreNone
    }

    Timer {
        id: feedbackTimer
        interval: Math.max(800, Math.min(5000, Number(root.osdPrefs?.duration ?? 1500))) + 300
        onTriggered: root.clearOsdRequests()
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
        function onOsdVolumeOpenChanged(): void { if (GlobalStates.osdVolumeOpen) root.showFeedback("volume", true) }
        function onOsdBrightnessOpenChanged(): void { if (GlobalStates.osdBrightnessOpen) root.showFeedback("brightness", true) }
        function onOsdMicOpenChanged(): void { if (GlobalStates.osdMicOpen) root.showFeedback("mic", true) }
        function onOsdKeyboardLayoutOpenChanged(): void {
            if (!GlobalStates.osdKeyboardLayoutOpen || !root.osdKeyboard) return
            root.showBadge("language", IrisStyle.accent,
                KeyboardIndicators.currentLayoutCodeInline || KeyboardIndicators.currentLayoutName)
        }
        function onWallpaperSelectorOpenChanged(): void {
            root.publishRestOrigin()
            if (GlobalStates.wallpaperSelectorOpen) root.expanded = false
        }
        function onSearchOpenChanged(): void {
            root.publishRestOrigin()
            if (GlobalStates.searchOpen) root.expanded = false
        }
        function onControlPanelOpenChanged(): void {
            if (IrisState.morphOwner === "stage") return
            if (root.controlsInIsland) {
                if (!root.focusedOutput) return
                if (GlobalStates.controlPanelOpen && !(root.expanded && root.page === "controls")) root.openPage("controls", true, null)
                else if (!GlobalStates.controlPanelOpen && root.expanded && root.page === "controls") root.expanded = false
                return
            }
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
            if (IrisState.morphOwner === "control" && !GlobalStates.settingsOverlayOpen) {
                IrisState.morphOwner = ""
                root.settingsMorphPart = chassis
            } else if (IrisState.morphOwner !== "") { root.settingsOriginPrepared = false; return }
            if (GlobalStates.settingsOverlayOpen) {
                if (!root.settingsOriginPrepared) {
                    root.settingsMorphPart = chassis
                    root.publishRestOrigin()
                    root.expanded = false
                }
                root.settingsOriginPrepared = false
                return
            }
            const part = root.settingsMorphPart && root.settingsMorphPart.visible ? root.settingsMorphPart : chassis
            root.publishOrigin(part)
        }
    }
    Connections {
        target: IrisState
        function onOrbitOpenChanged(): void {
            root.publishRestOrigin()
            if (IrisState.orbitOpen) root.expanded = false
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
        // How much the source and the target are scaled by what holds them (a page still settling in).
        property real fromScale: 1
        property real toScale: 1
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
        // The target moves while its page settles in: read where it is each frame, so the copy lands on it and the
        // real one shows exactly there.
        function track(): void {
            if (!flight.to) return
            const target = flight.rectOf(flight.to)
            flight.toRect = target
            flight.toScale = target.width / Math.max(1, flight.to.width)
        }
        onTChanged: if (flight.flying) flight.track()
        function launch(source: Item, target: Item): void {
            if (!source || !target || IrisStyle.duration(240) <= 0) { flight.stop(); return }
            const midway = flight.flying
            const mix = (a, b) => a + (b - a) * flight.t
            flight.fromRect = midway ? Qt.rect(flight.x, flight.y, flight.width, flight.height) : flight.rectOf(source)
            flight.fromRadius = midway ? mix(flight.fromRadius, flight.to?.radius ?? flight.fromRadius) : (source.radius ?? 0)
            flight.fromPixelSize = midway ? mix(flight.fromPixelSize, flight.to?.pixelSize ?? flight.fromPixelSize) : (source.pixelSize ?? 0)
            flight.fromScale = midway ? mix(flight.fromScale, flight.toScale) : flight.fromRect.width / Math.max(1, source.width)
            flight.from = source
            flight.active = true
            flight.to = target
            flight.track()
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
        property bool resting: false
        property bool leftSide: false
        property int slotIndex: 1
        property var task: root.task
        readonly property alias hovered: satelliteHover.hovered
        readonly property alias artwork: face.artwork
        signal activated()
        property string levelKind: ""
        function showLevel(level: string): void {
            if (satellite.kind === "sound" || satellite.kind === "mic") return
            satellite.levelKind = level
            levelLinger.restart()
        }
        Timer { id: levelLinger; interval: 1400; onTriggered: satellite.levelKind = "" }

        // Open, the Island carries its bubbles on its sides (10-25, he: folded into it they were gone behind every page).
        readonly property real emerge: emergeSpring.value * (1 - root.spotlightYield)
        IrisSpring {
            id: emergeSpring
            surface: "island"
            intent: "move"
            to: satellite.resting ? 1 : 0
            minimum: 0
        }

        width: Math.round((root.bubble - Math.round(8 * root.d) * root.notchness) * root.satelliteScale)
        height: width
        z: -1
        readonly property real acrossCentre: root.rightEdge ? chassis.x + root.compactHeight / 2
            : chassis.x + chassis.leftInset + root.compactHeight / 2
        y: root.vertical ? (satellite.leftSide
                ? chassis.y + (-root.satelliteOffset - height) * satellite.emerge
                : chassis.y + chassis.height - height + (root.satelliteOffset + height) * satellite.slotIndex * satellite.emerge)
            : root.bottomEdge ? root.height - (root.bubble + height) / 2 : (root.bubble - height) / 2
        x: root.vertical ? Math.round(satellite.acrossCentre - width / 2)
            : satellite.leftSide
            ? chassis.x + (-root.satelliteOffset - width) * satellite.slotIndex * satellite.emerge
            : chassis.x + chassis.width - width + (root.satelliteOffset + width) * satellite.slotIndex * satellite.emerge
        // Kept in the scene while the Island is open: a satellite's face carries
        // Shapes, and dropping their nodes on every open meant re-triangulating
        // them on the frame that starts the close (measured: one 88 ms frame).
        visible: satellite.emerge > 0.01 || root.expanded || chassis.presentation > 0.002
        readonly property bool lifted: root.draggedSlot === satellite.slot
        opacity: satellite.lifted ? 0 : 1
        scale: 0.86 + 0.14 * satellite.emerge

        IrisBubbleFace {
            id: face
            bodyless: true
            screenName: root.targetScreen?.name ?? ""
            opacity: Math.max(0, Math.min(1, (satellite.emerge - 0.45) / 0.4))
            anchors.fill: parent
            kind: satellite.levelKind.length > 0 ? satellite.levelKind : satellite.kind
            task: satellite.task
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
            onWheel: event => root.applySatelliteWheel(event, satellite)
        }
        IrisBubbleGrip {
            id: bubblePointer
            anchors.fill: parent
            slot: satellite.slot
            kind: satellite.kind
            screenName: root.targetScreen?.name ?? ""
            screenOffsetY: root.screenOffsetY
            holdLifts: !IrisState.edit
            pullDistance: IrisState.edit ? 6 * root.d : 0
            onTapped: {
                if (IrisState.edit) {
                    IrisState.editTarget = ""
                    IrisState.editSelection = IrisState.editSelection === satellite.slot ? "" : satellite.slot
                    return
                }
                satellite.activated()
            }
        }
        Accessible.role: Accessible.Button
        Accessible.name: face.Accessible.name
    }

    Satellite {
        id: leftSatellite
        slot: "left"
        leftSide: root.cornerSide !== "left"
        slotIndex: root.cornerSide !== "left" ? 1 : (root.auxiliaryRest ? root.auxiliarySlot : rightSatellite.resting ? 1 : 0) + 1
        kind: root.leftKind
        task: root.islandActivity.length > 0 ? root.secondaryTask : root.task
        shown: root.leftSatelliteShown
        resting: root.leftSatelliteRest
        onActivated: {
            if (root.mediaBubbleCard) root.toggleBubbleCard("media", leftSatellite, "island-left")
            else root.openPage(root.pageFor(root.leftKind), true, leftSatellite)
        }
    }
    readonly property bool mediaBubbleCard: IrisStyle.cluster && root.leftKind === "media"
        && String(Config.options?.iris?.player?.bubbleOpens ?? "card") === "card"
    readonly property bool focusedOutput: root.targetScreen?.name === GlobalStates.focusedScreen?.name
    Connections {
        target: IrisState
        function onIslandPageRequestChanged(): void {
            const page = IrisState.islandPageRequest
            if (page.length === 0 || !root.focusedOutput) return
            IrisState.islandPageRequest = ""
            if (page === "collapse") { root.expanded = false; return }
            root.openPage(page, true, null)
        }
    }
    readonly property var bubbleKinds: ({
        left: IrisStyle.cluster ? root.leftKind : "",
        right: IrisStyle.cluster ? (root.trailingKind !== "none" && !root.floatsAlone(root.trailingKind) ? root.trailingKind : "") : root.secondary,
        utility: root.auxiliary !== "none" && !root.floatsAlone(root.auxiliary)
            && (root.auxiliary !== "tray" || root.trayItems.length > 0) ? root.auxiliary : ""
    })
    // Every moving part notifies on its own, about eleven times a frame in a morph, and each rebuilt the whole chassis
    // chain. The table is rebuilt once per frame instead: before the chassis takes its blur (`flushShapes` from its
    // polish) or, failing that, after the animations and before the field syncs. Same frame, never a turn later.
    readonly property string shapeKey: [root.x, root.y, root.parent?.x ?? 0, root.parent?.y ?? 0,
        chassis.x, chassis.width, chassis.bodyHeight, chassis.radius,
        extension.x, extension.y, extension.width, extension.height,
        leftSatellite.x, rightSatellite.x, auxiliarySatellite.x, leftSatellite.width,
        badgePill.x, badgePill.y, badgePill.bodyWidth, badgePill.visible,
        compactColumn.y, compactColumn.height].join()
    property bool shapesDirty: false
    property int shapeRevision: 0
    // A change with nothing animating and no blur to take (the edit card turns the blur off) asked for no frame, so the
    // old shapes stayed drawn until something moved (his 11-07: an Island setting changed from the shelf left a ghost
    // bubble). A frame is asked for now, and the flush runs in it.
    onShapeKeyChanged: {
        root.shapesDirty = true
        root.Window.window?.update()
    }
    function flushShapes(): void {
        if (!root.shapesDirty) return
        root.shapesDirty = false
        root.shapeRevision++
    }
    Connections {
        target: root.Window.window
        function onAfterAnimating(): void { root.flushShapes() }
    }
    readonly property var fieldShapes: {
        void root.shapeRevision
        const out = []
        if (root.suppressed || root.opacity <= 0.01) return out
        const melt = Math.min(1, Math.max(0, root.notchness))
        if ((melt > 0.01 || root.clearStrip) && !IrisFrame.framed) {
            const window = root.Window.window
            const wide = (window?.width ?? 0) + 4 * IrisStyle.fuseDeep
            const deep = Math.max(8, IrisStyle.fuseDeep * 2)
            const top = root.bottomEdge ? (window?.height ?? 0) + 1 : -deep - 1
            const tall = (window?.height ?? 0) + 4 * IrisStyle.fuseDeep
            out.push(root.vertical
                ? { x: root.rightEdge ? (window?.width ?? 0) + 1 : -deep - 1, y: -2 * IrisStyle.fuseDeep, width: deep, height: tall,
                    radius: 0, paints: true, fuse: IrisStyle.fuseDeep, id: "edge" }
                : { x: -2 * IrisStyle.fuseDeep, y: top, width: wide, height: deep,
                    radius: 0, paints: true, fuse: IrisStyle.fuseDeep, id: "edge" })
            // A corner Island melts into its side wall too: the fillet under it is this wall's.
            if (root.cornerSide.length > 0)
                out.push({ x: root.cornerSide === "right" ? (window?.width ?? 0) + 1 : -deep - 1, y: -2 * IrisStyle.fuseDeep,
                    width: deep, height: tall, radius: 0, paints: true, fuse: IrisStyle.fuseDeep, id: "edgeSide" })
        }
        const body = root.chassisBody()
        const strip = root.menubar ? root.stripHeight : body.height
        const across = root.fullWidth && !root.vertical ? root.Window.window?.width ?? body.x + body.width : 0
        const bandInset = IrisFrame.framed ? IrisFrame.band : 0
        const edgeJoin = IrisFrame.framed ? "frame" : "edge"
        // A bar melted into its edge runs frame to frame; one that floats keeps its gap on every side and rounds its ends.
        const spanX = across > 0 ? bandInset + (body.x - bandInset) * (1 - melt) : body.x
        const spanW = across > 0 ? (across - bandInset * 2) + (body.width - (across - bandInset * 2)) * (1 - melt) : body.width
        // Welded into a corner, the body runs on past the side wall so only its inner corners round.
        const pastSide = root.cornerSide.length > 0 ? Math.ceil(chassis.radius * melt) : 0
        if (root.pods) {
            // Pods: the shelf's start and end become the frame's corners and its heart the Island's notch. Welded, an outer
            // pod runs from the side wall (off the screen without a frame), so the frame's corner turns into it and only
            // its inner end rounds, with the notch's shoulders; floating, the three are bodies on one line.
            const r = chassis.radius
            const outer = r * (1 - melt)
            const fuse = IrisStyle.fuse + (IrisStyle.fuseEdge - IrisStyle.fuse) * melt
            const welded = melt <= 0.01 ? [] : [edgeJoin]
            const span = root.Window.window?.width ?? body.x + body.width
            const wall = IrisFrame.framed ? bandInset : -Math.ceil(r)
            const air = Math.round(29 * root.d * root.breathing / 2)
            // The corners on the welded edge are hidden in it; `far` is the one corner left round on a pod.
            const corners = (far) => root.bottomEdge
                ? { tl: far === "left" ? r : outer, tr: far === "right" ? r : outer, bl: outer, br: outer }
                : { tl: outer, tr: outer, bl: far === "left" ? r : outer, br: far === "right" ? r : outer }
            for (const [id, area, start] of [["podStart", barZones.startArea, true], ["podEnd", barZones.endArea, false]]) {
                if (area.width < 1) continue
                const at = barZones.mapToItem(root.QsWindow.window?.contentItem, area.x, 0)
                const left = start ? at.x - air + (wall - at.x + air) * melt : at.x - air
                const right = start ? at.x + area.width + air : at.x + area.width + air + (span - wall - at.x - area.width - air) * melt
                out.push({ x: left, y: body.y, width: right - left, height: body.height, radius: r,
                    corners: melt > 0.01 ? corners(start ? "right" : "left") : null,
                    paints: true, fuse: fuse, id: id, joins: welded.concat(["island"]) })
            }
            if (root.heartShown && root.heartLength > 1) {
                const at = chassis.mapToItem(root.QsWindow.window?.contentItem, barZones.heartAlong, 0)
                out.push({ x: at.x, y: body.y, width: root.heartLength, height: body.height, radius: r,
                    corners: melt > 0.01 ? (root.bottomEdge ? { tl: r, tr: r, bl: outer, br: outer } : { tl: outer, tr: outer, bl: r, br: r }) : null,
                    paints: true, fuse: fuse, id: "island", joins: welded })
            }
        }
        if (!root.clearStrip && !root.pods) out.push({ x: spanX - (root.cornerSide === "left" ? pastSide : 0),
            y: root.menubar && root.bottomEdge ? body.y + body.height - strip : body.y,
            width: spanW + pastSide, height: strip,
            radius: across > 0 ? Math.min(strip / 2, chassis.radius) * (1 - melt) : root.menubar ? strip / 2 : chassis.radius, paints: true,
            fuse: across > 0 ? Math.round(16 * root.d) : IrisStyle.fuse + (IrisStyle.fuseEdge - IrisStyle.fuse) * melt, id: "island",
            joins: melt <= 0.01 ? "" : IrisFrame.framed ? "frame" : pastSide > 0 ? ["edge", "edgeSide"] : "edge" })
        // On its side, the heart of a full bar swells inward out of the bar: the same gesture as a menu bar's notch.
        if (root.vertical && root.zoned && root.notch && root.heartShown && compactColumn.height > 1) {
            const at = compactColumn.mapToItem(root.QsWindow.window?.contentItem, 0, 0)
            const wide = body.width + root.heartSwell
            out.push({ x: root.rightEdge ? body.x - root.heartSwell : body.x, y: at.y, width: wide, height: compactColumn.height,
                radius: wide / 2, paints: true, fuse: IrisStyle.fuseEdge, id: "islandheart", joins: "island" })
        }
        // Across the top or bottom the heart of a full bar swells out of it the same way.
        if (root.swellsHeart && root.heartLength > 1) {
            const at = chassis.mapToItem(root.QsWindow.window?.contentItem, barZones.heartAlong, 0)
            const tall = body.height + root.heartSwell
            // Its far corners round like the Island it is; the shoulders where it leaves the shelf are concave, as wide as
            // the rise is deep, so shelf and Island read as one piece.
            out.push({ x: at.x, y: root.bottomEdge ? body.y - root.heartSwell : body.y, width: root.heartLength, height: tall,
                radius: Math.min(root.heartLength / 2, Math.round(tall * 0.4)),
                paints: true, fuse: Math.round(root.heartSwell * 1.1 + 6 * root.d), id: "islandheart", joins: "island" })
        }
        if (root.menubar && root.heartShown && root.heartLength > 1) {
            const at = chassis.mapToItem(root.QsWindow.window?.contentItem, barZones.heartAlong, 0)
            out.push({ x: at.x, y: body.y, width: root.heartLength, height: body.height, radius: root.meltedCorner,
                paints: true, fuse: root.clearStrip ? IrisStyle.fuseEdge : Math.round(32 * root.d), id: "islandnotch",
                joins: root.clearStrip ? edgeJoin : "island" })
        }
        if (extension.visible && extension.width > 1 && extension.height > 1) {
            const page = extension.mapToItem(root.QsWindow.window?.contentItem, 0, 0)
            const floating = root.zoned && !root.vertical && !root.fromHeart
            const grown = root.grownPage
            const sink = grown ? 0 : root.fullWidth && !floating ? Math.min(extension.radius, root.compactHeight) : 0
            out.push({ x: page.x - (root.vertical && !root.rightEdge ? sink : 0), y: page.y - (!root.vertical && !root.bottomEdge ? sink : 0),
                width: extension.width + (root.vertical ? sink : 0), height: extension.height + (root.vertical ? 0 : sink),
                radius: extension.radius, paints: true, id: "islandPage",
                // The player's cover is this body's material (IrisField's art lane): it fills the shoulders and melts
                // into the strip or the band it is welded to.
                art: artBackdrop.item && artBackdrop.opacity > 0 ? artBackdrop : null, artShow: artBackdrop.opacity,
                artRise: Math.round(44 * root.d),
                fuse: grown ? IrisStyle.fuseEdge : IrisStyle.fuseDeep,
                // Inline, the page is the chassis rectangle itself: a smooth union of two equal shapes swells the contour by fuse / 4.
                joins: root.pagesHang && !floating ? (root.clearStrip ? "islandnotch" : "island")
                    : !extension.anchoredShape || floating ? "" : grown && root.clearStrip ? (IrisFrame.framed ? "frame" : "edge")
                    : root.clearStrip ? "islandnotch" : "island" })
        }
        if (badgePill.visible) {
            const at = badgePill.mapToItem(root.QsWindow.window?.contentItem, (badgePill.width - badgePill.bodyWidth) / 2, 0)
            out.push({ x: at.x, y: at.y, width: badgePill.bodyWidth, height: badgePill.height, radius: badgePill.height / 2,
                paints: false, id: "badge", joins: "island", fuse: IrisStyle.fuseDeep * (1 - badgePill.reveal) })
        }
        for (const satellite of [leftSatellite, rightSatellite, auxiliarySatellite]) {
            if (!satellite.visible || satellite.emerge <= 0.01) continue
            const size = satellite.width * satellite.scale
            const centre = satellite.mapToItem(root.QsWindow.window?.contentItem, satellite.width / 2, satellite.height / 2)
            // A drop that pinches off the Island on its way out and stands apart at rest: melted in for good it read
            // as a belly on the Island (10-25).
            const joined = IrisStyle.fuse * (1 - IrisStyle.ramp(satellite.emerge, 0.45, 0.5))
            out.push({ x: centre.x - size / 2, y: centre.y - size / 2, width: size, height: size,
                radius: IrisStyle.pieceRadius(size), paints: true, fuse: joined, satellite: true, id: "satellite:" + satellite.slot,
                joins: "island" })
        }
        return out
    }
    readonly property var islandGeometry: {
        void (root.x + (root.parent?.x ?? 0) + (root.parent?.y ?? 0) + chassis.x + chassis.y + chassis.width + chassis.height + chassis.bodyHeight)
        const p = root.chassisBody()
        return {
            x: p.x, y: p.y + root.screenOffsetY, width: p.width, height: p.height,
            bubble: leftSatellite.width, gap: root.satelliteOffset, bottomEdge: root.bottomEdge,
            edge: root.edge, vertical: root.vertical,
            auxiliarySlot: root.auxiliarySlot, resting: !root.expanded,
            fullWidth: root.spanning, radius: chassis.radius,
            // Welded to its edge (a notch): which edge, and the fillet of the join.
            joins: root.notchness > 0.5 ? root.edge : "",
            fuse: Math.round(IrisStyle.fuse + (IrisStyle.fuseEdge - IrisStyle.fuse) * Math.min(1, Math.max(0, root.notchness))),
            // The bubbles beside it at rest, by place along the Island: -1 before it, 1.. after it.
            satellites: [leftSatellite.resting && leftSatellite.kind.length > 0 ? -1 : 0,
                rightSatellite.resting && rightSatellite.kind.length > 0 ? 1 : 0,
                root.auxiliaryRest && root.auxiliary.length > 0 ? root.auxiliarySlot : 0].filter(i => i !== 0)
        }
    }
    function publishBubbleKinds(): void {
        const name = root.targetScreen?.name ?? ""
        if (name.length === 0) return
        const kinds = Object.assign({}, IrisState.bubbleKinds ?? {})
        kinds[name] = root.bubbleKinds
        IrisState.bubbleKinds = kinds
    }
    property string publishedGeometry: ""
    function publishIslandGeometry(): void {
        const name = root.targetScreen?.name ?? ""
        // Only the resting shape fans out: it feeds every piece, card and mask,
        // so a collapsing chassis must not publish a new one every frame — and a
        // shape that came back to where it was must not publish at all. Writing
        // this map rebuilds every piece, plate, hit rect and field shape on the
        // output: measured at one 87 ms frame, right as the Island settled.
        if (name.length === 0 || root.expanded || root.momentShown || root.morphing) return
        const next = root.islandGeometry
        const key = JSON.stringify(next)
        if (key === root.publishedGeometry) return
        root.publishedGeometry = key
        const geometry = Object.assign({}, IrisState.islandGeometry ?? {})
        geometry[name] = next
        IrisState.islandGeometry = geometry
    }
    onBubbleKindsChanged: root.publishBubbleKinds()
    onIslandGeometryChanged: geometrySettle.restart()
    onMomentShownChanged: if (!root.momentShown) geometrySettle.restart()
    // Resting reshapes (width, notch, placement) change the geometry every frame; one fan-out per frame drops the output to ~14 fps.
    Timer { id: geometrySettle; interval: 60; onTriggered: root.publishIslandGeometry() }
    Component.onCompleted: { root.publishBubbleKinds(); root.publishIslandGeometry() }
    readonly property var floatingSlots: ["left", "right", "utility"]
        .filter(slot => String(Config.options?.iris?.bubbles?.[slot]?.place ?? "island") !== "island"
            && !(root.absorbed?.islandSlots ?? []).includes(slot))
    readonly property string draggedSlot: IrisState.bubbleDrag && IrisState.bubbleDrag.screen === (root.targetScreen?.name ?? "")
        ? String(IrisState.bubbleDrag.slot) : ""
    Satellite {
        id: rightSatellite
        leftSide: root.cornerSide === "right"
        slotIndex: root.cornerSide === "right" && leftSatellite.resting ? 2 : 1
        slot: "right"
        kind: IrisStyle.cluster ? root.trailingKind : root.secondary
        task: root.secondaryTask
        shown: root.rightSatelliteShown
        resting: root.rightSatelliteRest
        onActivated: {
            if (!IrisStyle.cluster) root.openPage(root.pageFor(root.secondary), true, rightSatellite)
            else root.activateBubble(root.trailingKind, rightSatellite)
        }
    }

    Satellite {
        id: auxiliarySatellite
        slot: "utility"
        kind: root.auxiliary
        leftSide: root.cornerSide === "right"
        slotIndex: root.auxiliarySlot
        shown: root.auxiliaryShown
        resting: root.auxiliaryRest
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
            // Sizes as drawn; the face is set once at the larger one and only scaled while it flies.
            readonly property real fromSize: Math.max(1, clockFlight.fromPixelSize * clockFlight.fromScale)
            readonly property real toSize: Math.max(1, (clockFlight.to?.pixelSize ?? clockFlight.fromPixelSize) * clockFlight.toScale)
            pixelSize: Math.max(1, clockFlight.fromPixelSize, clockFlight.to?.pixelSize ?? 0)
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
        x: !root.vertical ? (root.width - width) / 2
            : root.rightEdge ? chassis.x - (width + gap) * badgePill.reveal + width * (1 - badgePill.reveal)
            : chassis.x + chassis.width - width + (width + gap) * badgePill.reveal
        y: root.vertical ? Math.round(chassis.y + (chassis.height - height) / 2)
            : root.bottomEdge ? -(height + gap) * badgePill.reveal + height * (1 - badgePill.reveal)
            : chassis.bodyHeight - height + (height + gap) * badgePill.reveal
        z: -2
        visible: badgePill.reveal > 0.01
        // The body is the field's (a drop out of the Island that stretches into the pill); only the words live here.
        readonly property real bodyWidth: badgePill.height + (badgePill.width - badgePill.height) * badgePill.reveal
        Row {
            id: badgeRow
            anchors.centerIn: parent
            opacity: IrisStyle.contentAt(badgePill.reveal)
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
                font.pixelSize: IrisStyle.typeMeta
                font.weight: IrisStyle.weight(Font.DemiBold)
            }
        }
    }

    // `inir iris motion island`: one sample per frame of the chassis window, the body as it is drawn.
    Connections {
        target: root.Window.window
        enabled: IrisMotionMeter.watching("island") && root.focusedOutput
        function onAfterAnimating(): void {
            const at = chassis.mapToItem(root.QsWindow.window?.contentItem, 0, 0)
            const source = { settles: true, presentation: chassis.presentation, open: root.inlineExpanded }
            IrisMotionMeter.sample({ source: source, presentation: chassis.presentation,
                rect: { x: at.x, y: at.y, width: chassis.width, height: chassis.height },
                opacity: 1, wantsBlur: false, blurred: false, sameWindow: true, above: false, island: null })
        }
    }

    ClippingRectangle {
        id: chassis
        // ClippingRectangle does not re-mask when per-corner radii change live.
        readonly property real restWidth: root.compactTargetWidth
        // A large notice grows the resting body into its card on the same scalar: height, corners and content.
        readonly property real restHeight: root.compactHeight + (root.noticeHeight - root.compactHeight) * root.noticeOpen
        readonly property real compactRadius: IrisStyle.profileRadius(IrisStyle.bodyProfile(IrisStyle.barShape, root.notch), root.compactHeight)
        readonly property real restRadius: chassis.compactRadius + (root.noticeRadius - chassis.compactRadius) * root.noticeOpen
        readonly property real openWidthTarget: root.expandedWidth
        readonly property real openHeightLive: (details.item?.implicitHeight ?? 0) + root.padding * 2
        property real openHeightHeld: 0
        onOpenHeightLiveChanged: if (root.inlineExpanded && chassis.openHeightLive > root.padding * 2)
            chassis.openHeightHeld = chassis.openHeightLive
        readonly property real openHeightTarget: root.inlineExpanded || chassis.openHeightHeld <= 0
            ? chassis.openHeightLive : chassis.openHeightHeld
        readonly property real openRadius: IrisStyle.openedRadius(IrisStyle.barShape, IrisStyle.radiusPanel)
        readonly property alias restW: restWidthSpring.value
        readonly property alias openW: openWidthSpring.value
        readonly property alias openH: openHeightSpring.value
        IrisSpring { id: restWidthSpring; surface: "island"; to: chassis.restWidth; intent: "move"; epsilon: 0.25 }
        IrisSpring { id: openWidthSpring; surface: "island"; to: chassis.openWidthTarget; intent: "move"; epsilon: 0.25; animate: chassis.presentation > 0.01 }
        IrisSpring { id: openHeightSpring; surface: "island"; to: chassis.openHeightTarget; intent: "move"; epsilon: 0.25; animate: chassis.presentation > 0.01 }
        readonly property alias presentation: chassisSpring.value
        IrisSpring { id: chassisSpring; surface: "island"; to: root.inlineExpanded ? 1 : 0; minimum: 0 }
        function lerp(a: real, b: real): real { return a + (b - a) * chassis.presentation }
        readonly property real bodyHeightTarget: root.inlineExpanded ? chassis.openHeightTarget
            : root.noticeGrows ? root.noticeHeight : chassis.restHeight
        readonly property real bodyHeight: Math.round(chassis.lerp(chassis.restHeight, chassis.openH))
        // Whole pixels: the chassis draws its content through a texture and a half-pixel offset softens it.
        readonly property real edgeInset: Math.ceil(chassis.radius * root.notchness)
        readonly property real topInset: root.edge === "top" ? chassis.edgeInset : 0
        readonly property real bottomInset: root.bottomEdge ? chassis.edgeInset : 0
        readonly property real leftInset: root.edge === "left" ? chassis.edgeInset : 0
        readonly property real rightInset: root.rightEdge ? chassis.edgeInset : 0
        // A full bar's heart swells out of the bar as its own field body; the clip reaches it too, so the heart's
        // row can centre in the heart instead of in the bar. The clip is all but transparent (bodyClip).
        readonly property real swellInset: root.swellsHeart ? root.heartSwell : 0
        // Upright on a side edge it grows out of its band like it grows down from the top: across, from the
        // capsule's thickness to the page's width, and along, from the capsule's length to the page's height.
        readonly property real across: Math.round(chassis.lerp(root.compactHeight, chassis.openW))
        x: !root.vertical ? Math.round((root.width - width) / 2)
            : root.rightEdge ? root.width - chassis.across : -chassis.leftInset
        y: root.vertical ? Math.round((root.height - chassis.height) / 2)
            : root.bottomEdge ? root.height - chassis.bodyHeight - chassis.swellInset : -chassis.topInset
        width: root.vertical ? chassis.across + chassis.leftInset + chassis.rightInset
            : Math.round(chassis.lerp(chassis.restW, chassis.openW))
        height: root.vertical ? Math.round(chassis.lerp(chassis.restW, chassis.openH)) : chassis.bodyHeight + chassis.topInset + chassis.bottomInset + chassis.swellInset
        // Opaque: a transparent ClippingRectangle past the screen edge stops painting its children.
        color: IrisStyle.bodyClip
        radius: Math.min((root.vertical ? Math.min(chassis.across, chassis.height) : chassis.width) / 2, chassis.restRadius
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
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => root.applyWheel(event)
        }
        // A file or some text dragged over the Island opens the Shelf; let go and it stays there.
        DropArea {
            anchors.fill: parent
            enabled: Config.options?.shelf?.enable ?? true
            // Only what the shelf keeps (local files, words): anything else passes on untouched.
            onEntered: drag => {
                const urls = drag.hasUrls ? drag.urls.filter(url => String(url).startsWith("file://")) : []
                if (urls.length === 0 && !(drag.hasText && drag.text.trim().length > 0)) { drag.accepted = false; return }
                drag.accept(Qt.CopyAction)
                root.dropFiles = urls.length > 0
                root.dropCount = Math.max(1, urls.length)
                if (root.expanded) return
                root.dropHover = true
                dropSpring.restart()
            }
            onExited: { root.dropHover = false; dropSpring.stop() }
            onDropped: drop => {
                root.dropHover = false
                dropSpring.stop()
                // A link from a browser carries no file: its words are kept instead.
                const kept = (drop.hasUrls ? Shelf.keepUrls(drop.urls) : 0) || (drop.hasText && Shelf.keepText(drop.text) ? 1 : 0)
                if (kept > 0) {
                    drop.accept(Qt.CopyAction)
                    if (!root.expanded && root.noticeOn("shelf"))
                        root.showEvent("check", IrisStyle.accent, Translation.tr("On the Shelf"),
                            root.dropFiles ? (kept === 1 ? Translation.tr("1 file") : Translation.tr("%1 files").arg(kept)) : Translation.tr("Text"), 1, "kept")
                } else drop.accepted = false
            }
        }

        Item {
            id: islandResize
            z: 20
            visible: IrisState.edit && !root.expanded
            width: Math.round((root.vertical ? 14 : 44) * root.d)
            height: Math.round((root.vertical ? 44 : 14) * root.d)
            x: !root.vertical ? Math.round((chassis.width - width) / 2) : root.rightEdge ? 0 : chassis.width - width
            y: root.vertical ? Math.round((chassis.height - height) / 2) : root.bottomEdge ? 0 : chassis.height - height
            Rectangle {
                anchors.centerIn: parent
                width: root.vertical ? Math.max(2, Math.round(3 * root.d)) : Math.round(24 * root.d)
                height: root.vertical ? Math.round(24 * root.d) : Math.max(2, Math.round(3 * root.d))
                radius: Math.min(width, height) / 2
                color: resizeHover.hovered || resizeDrag.active ? IrisStyle.accent : IrisStyle.textTertiary
            }
            HoverHandler { id: resizeHover; cursorShape: root.vertical ? Qt.SizeHorCursor : Qt.SizeVerCursor }
            DragHandler {
                id: resizeDrag
                target: null
                xAxis.enabled: root.vertical
                yAxis.enabled: !root.vertical
                property real startHeight: 42
                property IrisConfigDrag write: IrisConfigDrag { path: "iris.bar.height" }
                onActiveChanged: {
                    if (active) resizeDrag.startHeight = Number(Config.options?.iris?.bar?.height ?? 42)
                    else resizeDrag.write.flush()
                }
                onTranslationChanged: {
                    if (!active) return
                    const outward = root.vertical ? (root.rightEdge ? -translation.x : translation.x)
                        : (root.bottomEdge ? -translation.y : translation.y)
                    const delta = outward / Math.max(0.01, root.d)
                    resizeDrag.write.push(Math.round(Math.max(32, Math.min(64, resizeDrag.startHeight + delta))))
                }
            }
        }

        // Halo: the sun as light inside the Island's foot (his 11-02 14:05: the bead read as a dot nobody understood, a
        // bar under it as a smudge). It lives in the body's own clip, so its only edge is the Island's: the foot glows
        // where the sun stands, from one end at sunrise to the other at sunset, warm near the ends of the day, whitest
        // at noon. Weather's minute moves it, never between; night leaves the time alone.
        Item {
            id: sunLight
            readonly property real t: Math.max(0, Math.min(1, Weather.sunProgress))
            readonly property real corner: Math.min(chassis.radius, chassis.width / 2)
            // How high the sun is: 0 at the horizon, 1 at noon.
            readonly property real height_: Math.sin(Math.PI * sunLight.t)
            // iris-literal: the low sun's amber, tinted into the clock colour toward the ends of the day.
            readonly property color lamp: Qt.tint(Qt.tint(root.clockAccent, Qt.rgba(1, 1, 1, 0.38 * sunLight.height_)), // iris-literal: sunlight itself, not a surface of the look
                Qt.rgba(1, 0.66, 0.35, 0.5 * (1 - sunLight.height_))) // iris-literal: the low sun is amber on every look
            visible: root.design === "halo" && (Config.options?.iris?.bar?.sunLight ?? true) && Weather.sunState === "day" && !root.vertical && !root.zoned
                && clusterClock.width > 0 && opacity > 0.01
            opacity: compactLayer.opacity * clockRow.opacity
            // A small core under a wide blur: a bloom with no flat top, so no end of it can be read as a shape.
            width: Math.round(16 * root.d)
            height: 0
            // Along the straight of the foot: the corners never carry it.
            x: Math.round(sunLight.corner * 0.7 + (chassis.width - 1.4 * sunLight.corner) * sunLight.t - width / 2)
            y: root.bottomEdge ? 0 : chassis.height
            RectangularShadow {
                anchors.centerIn: parent
                width: parent.width
                height: Math.round(6 * root.d)
                radius: height / 2
                blur: Math.round(30 * root.d)
                color: Qt.alpha(sunLight.lamp, 0.7 + 0.2 * sunLight.height_)
                cached: true
            }
        }

        Item {
            id: compactLayer
            x: root.vertical ? (root.rightEdge ? chassis.width - chassis.rightInset - width : chassis.leftInset) : 0
            y: root.vertical ? Math.round((chassis.height - height) / 2)
                : root.bottomEdge ? chassis.height - chassis.bottomInset - height : chassis.topInset
            width: root.vertical ? root.compactHeight : chassis.width
            height: root.vertical ? Math.round(chassis.restW) : root.compactHeight
            readonly property real fall: Math.min(1, chassis.presentation / Math.max(0.02, IrisStyle.contentFall))
            opacity: root.paintNudge * Math.max(0, 1 - compactLayer.fall) * IrisStyle.recompose * (1 - root.spotlightYield)
            transform: Scale {
                origin.x: compactLayer.width / 2
                origin.y: compactLayer.height / 2
                xScale: IrisStyle.revealFades ? 1 : (1 - 0.1 * compactLayer.fall) * (0.96 + 0.04 * IrisStyle.recompose)
                yScale: IrisStyle.revealFades ? 1 : (1 - 0.1 * compactLayer.fall) * (0.96 + 0.04 * IrisStyle.recompose)
            }
            // Never transform the ClippingRectangle live: it can stop painting.
            scale: compactPress.pressed && !root.zoned ? IrisStyle.pressScale(0.93) : 1
            Behavior on scale { NumberAnimation { duration: IrisStyle.duration(compactPress.pressed ? 80 : 200); easing.type: IrisStyle.feedbackEasing } }
            // Kept in the scene across a morph: its rows carry the clock, glyphs and
            // figures, and rebuilding their nodes as the shape came back cost one
            // 95 ms frame near the end of every close.
            visible: opacity > 0 || root.expanded || chassis.presentation > 0.002

            component CompactRow: RowLayout {
                id: compactRow
                property string mode: ""
                property real lead: 0
                readonly property bool current: root.compactMode === compactRow.mode || (compactRow.mode === "idle" && root.haloWings)
                readonly property real wing: compactRow.mode === "idle" ? root.wingSlot : 0
                property real laidWidth: 0
                // Laid at the width of its own size class: relaying the row out per
                // frame so it rides the shape measured 2.4x the cost of every morph.
                Binding on laidWidth { when: compactRow.current; value: root.zoned ? root.heartTarget : root.compactTargetWidth; restoreMode: Binding.RestoreNone }
                readonly property real leadMargin: compactRow.lead > 0
                    ? Math.round((root.compactHeight - compactRow.lead) / 2) : 14 * root.d
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                // Centred in the heart, which swells out of the bar, not in the bar it swells from.
                readonly property real swellShift: Math.round(chassis.swellInset / 2 - root.bandLift) * (root.bottomEdge ? -1 : 1)
                anchors.topMargin: compactRow.swellShift
                anchors.bottomMargin: -compactRow.swellShift
                x: (root.zoned ? Math.round(barZones.heartAlong + (root.heartLength - compactRow.laidWidth) / 2)
                    : Math.round((parent.width - compactRow.laidWidth) / 2)) + compactRow.leadMargin + compactRow.wing
                    + (root.piecesAtStart ? root.barPieceReserve : 0)
                width: Math.max(0, compactRow.laidWidth - compactRow.leadMargin - 15 * root.d - root.barPieceReserve - 2 * compactRow.wing)
                spacing: 9 * root.d
                opacity: (compactRow.current && root.heartShown && !root.vertical && !root.faceTakes ? 1 : 0) * root.heartUncovered
                scale: root.zoned && compactPress.pressed ? IrisStyle.pressScale(0.93) : 1
                Behavior on scale { NumberAnimation { duration: IrisStyle.duration(compactPress.pressed ? 80 : 200); easing.type: IrisStyle.feedbackEasing } }
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
                    font.pixelSize: IrisStyle.typeMeta
                    font.weight: IrisStyle.weight(Font.Medium)
                }
                DateMark {
                    visible: root.clockStyle === "dateTime"
                    Layout.alignment: Qt.AlignVCenter
                    pixelSize: IrisStyle.typeMeta * root.clockScale
                    dayColor: root.clockAccent
                }
                Item { Layout.fillWidth: true }
                IrisClock {
                    id: idleClock
                    Layout.alignment: Qt.AlignVCenter
                    family: root.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(pixelSize)
                    minorFamily: root.nothingLook ? IrisStyle.fontLabel : family
                    pixelSize: root.figureSize
                    separatorColor: root.clockAccent
                    opacity: clockFlight.hides(idleClock) ? 0 : 1
                }
                PrivacyMarks { Layout.alignment: Qt.AlignVCenter; spelled: true }
            }

            CompactRow {
                id: recordRow
                mode: "record"
                RecordDot { Layout.alignment: Qt.AlignVCenter; color: root.nothingLook ? IrisStyle.signal : IrisStyle.danger }
                IrisLabel {
                    visible: root.nothingLook
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: Translation.tr("Rec")
                    color: IrisStyle.text
                }
                IrisText {
                    visible: !root.nothingLook
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: Translation.tr("Recording")
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeLabel
                    font.weight: IrisStyle.weight(Font.Medium)
                    elide: Text.ElideRight
                }
                // While something runs, its figure is what the row says (DI49j): the word steps back.
                IrisDotText {
                    visible: root.nothingLook
                    Layout.alignment: Qt.AlignVCenter
                    text: root.clockText(RecorderStatus.elapsedSeconds)
                    pixelSize: root.figureSize
                    color: IrisStyle.text
                }
                IrisVisualizer {
                    visible: !root.nothingLook && RecorderStatus.effectiveAudioMode !== "none"
                    Layout.alignment: Qt.AlignVCenter
                    running: visible && root.compactMode === "record" && !root.visualExpanded
                    tint: IrisStyle.danger
                    barHeight: 14 * root.d
                }
                IrisNumber {
                    visible: !root.nothingLook
                    Layout.alignment: Qt.AlignVCenter
                    text: root.clockText(RecorderStatus.elapsedSeconds)
                    color: IrisStyle.danger
                    pixelSize: IrisStyle.typeHeadline * root.clockScale
                    weight: IrisStyle.figureWeight
                }
                PrivacyMarks { Layout.alignment: Qt.AlignVCenter; spelled: false }
            }

            CompactRow {
                id: timerRow
                mode: "timer"
                // A running timer is live: its dot is the signal. Paused, the dot gives way to the pause bars.
                // Apple's timer: a ring that empties as the time runs, the pause bars inside it once paused.
                Item {
                    visible: !root.nothingLook
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: Math.round(22 * root.d)
                    implicitHeight: implicitWidth
                    ProgressRing {
                        anchors.fill: parent
                        stroke: Math.max(2.5, 3 * root.d)
                        tint: root.timerPaused ? IrisStyle.textSecondary : IrisStyle.identity.orange
                        progress: root.timerKind === "stopwatch" ? 1 : Math.max(0, 1 - root.timerProgress)
                        Behavior on progress { NumberAnimation { duration: IrisStyle.duration(900); easing.type: Easing.Linear } }
                    }
                    Glyph {
                        anchors.centerIn: parent
                        visible: root.timerPaused || root.timerKind === "stopwatch"
                        text: root.timerPaused ? "pause" : root.timerGlyph
                        iconSize: 11 * root.d
                        color: root.timerPaused ? IrisStyle.textSecondary : IrisStyle.identity.orange
                    }
                }
                Item {
                    visible: root.nothingLook
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: Math.round(16 * root.d)
                    implicitHeight: implicitWidth
                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.round(7 * root.d)
                        height: width
                        radius: width / 2
                        color: IrisStyle.signal
                        opacity: root.timerPaused ? 0 : 1
                        scale: root.timerPaused ? 0.4 : 1
                        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
                        Behavior on scale { NumberAnimation { duration: IrisStyle.duration(200); easing.type: Easing.OutCubic } }
                    }
                    Glyph {
                        anchors.centerIn: parent
                        text: "pause"
                        iconSize: 16 * root.d
                        color: IrisStyle.textSecondary
                        opacity: root.timerPaused ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
                    }
                }
                IrisLabel {
                    visible: root.nothingLook
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: root.timerPaused ? Translation.tr("Paused") : root.timerLabel
                    color: IrisStyle.text
                }
                IrisText {
                    visible: !root.nothingLook
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: root.timerPaused ? Translation.tr("Paused") : root.timerLabel
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeLabel
                    font.weight: IrisStyle.weight(Font.Medium)
                    elide: Text.ElideRight
                }
                IrisDotText {
                    visible: root.nothingLook
                    Layout.alignment: Qt.AlignVCenter
                    text: root.clockText(root.timerSeconds)
                    direction: root.timerKind === "stopwatch" ? 1 : -1
                    pixelSize: root.figureSize
                    color: root.timerPaused ? IrisStyle.textSecondary : IrisStyle.text
                }
                IrisNumber {
                    visible: !root.nothingLook
                    Layout.alignment: Qt.AlignVCenter
                    text: root.clockText(root.timerSeconds)
                    countDown: root.timerKind !== "stopwatch"
                    color: root.timerPaused ? IrisStyle.textSecondary : IrisStyle.identity.orange
                    pixelSize: IrisStyle.typeHeadline * root.clockScale
                    weight: IrisStyle.figureWeight
                }
                PrivacyMarks { Layout.alignment: Qt.AlignVCenter; spelled: false }
            }

            CompactRow {
                id: taskRow
                mode: "task"
                readonly property real progress: Number(root.task?.progress ?? -1)
                Glyph {
                    Layout.alignment: Qt.AlignVCenter
                    text: String(root.task?.glyph ?? "bolt")
                    iconSize: 17 * root.d
                    color: root.taskTint
                }
                IrisText {
                    Layout.fillWidth: true
                    Layout.maximumWidth: Math.round(170 * root.d)
                    Layout.alignment: Qt.AlignVCenter
                    text: String(root.task?.title ?? "")
                    // Under Apple the figure is what the row says and the name steps back.
                    color: !root.nothingLook && taskRow.progress >= 0 ? IrisStyle.textSecondary : IrisStyle.text
                    font.pixelSize: IrisStyle.typeLabel
                    font.weight: IrisStyle.weight(!root.nothingLook && taskRow.progress >= 0 ? Font.Medium : Font.DemiBold)
                    elide: Text.ElideRight
                }
                IrisDotStrip {
                    visible: root.nothingLook && taskRow.progress >= 0
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: root.stripWidth(6)
                    count: 6
                    value: Math.max(0, taskRow.progress)
                }
                // The percentage when the job knows it, how long it has run when it does not.
                IrisDotText {
                    visible: root.nothingLook
                    Layout.alignment: Qt.AlignVCenter
                    text: taskRow.progress >= 0 ? root.percentOf(root.task) : root.elapsedOf(root.task)
                    pixelSize: root.figureSize
                    color: IrisStyle.text
                }
                IrisNumber {
                    visible: !root.nothingLook
                    Layout.alignment: Qt.AlignVCenter
                    text: taskRow.progress >= 0 ? root.percentOf(root.task) + "%" : root.elapsedOf(root.task)
                    color: root.taskTint
                    pixelSize: IrisStyle.typeHeadline * root.clockScale
                    weight: IrisStyle.figureWeight
                }
                // How far it is, as Apple's AirDrop ring beside the figure.
                ProgressRing {
                    visible: !root.nothingLook && taskRow.progress >= 0
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Math.round(20 * root.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    stroke: Math.max(2.5, 3 * root.d)
                    tint: root.taskTint
                    progress: Math.max(0, taskRow.progress)
                    Behavior on progress { NumberAnimation { duration: IrisStyle.duration(320); easing.type: Easing.OutCubic } }
                }
                PrivacyMarks { Layout.alignment: Qt.AlignVCenter; spelled: false }
            }

            // A call: the green handset and how long it has run at the start, the sound moving in green at the end.
            CompactRow {
                id: micRow
                mode: "mic"
                Glyph {
                    Layout.alignment: Qt.AlignVCenter
                    text: /discord|zoom|teams|meet|skype|telegram|whatsapp|signal|slack|call/i.test(root.micApp) ? "call" : "mic"
                    iconSize: 17 * root.d
                    color: IrisStyle.identity.green
                }
                Tabular {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.micElapsed
                    color: IrisStyle.identity.green
                    font.pixelSize: IrisStyle.typeBody * root.clockScale
                    font.weight: IrisStyle.weight(Font.DemiBold)
                }
                IrisText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: root.micApp
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeLabel
                    font.weight: IrisStyle.weight(Font.Medium)
                    elide: Text.ElideRight
                }
                IrisVisualizer {
                    Layout.alignment: Qt.AlignVCenter
                    running: visible && root.compactMode === "mic" && !root.visualExpanded
                    tint: IrisStyle.identity.green
                    barHeight: 15 * root.d
                }
            }

            // The camera on: FaceTime's green tile with the camera, the app, how long it has been on.
            CompactRow {
                id: cameraRow
                mode: "camera"
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: root.compactHeight - Math.round(14 * root.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: Math.round(width * 0.28)
                    color: IrisStyle.identity.green
                    Glyph { anchors.centerIn: parent; text: "videocam"; iconSize: 16 * root.d; color: IrisStyle.onTintFor(IrisStyle.identity.green) }
                }
                IrisText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: String((Privacy.cameraApps ?? [])[0] ?? Translation.tr("Camera"))
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeLabel
                    font.weight: IrisStyle.weight(Font.Medium)
                    elide: Text.ElideRight
                }
                Tabular {
                    visible: root.micLive
                    Layout.alignment: Qt.AlignVCenter
                    text: root.micElapsed
                    color: IrisStyle.identity.green
                    font.pixelSize: IrisStyle.typeBody * root.clockScale
                    font.weight: IrisStyle.weight(Font.DemiBold)
                }
                RecordDot { Layout.alignment: Qt.AlignVCenter; color: IrisStyle.identity.green }
            }

            CompactRow {
                id: clockRow
                mode: "clock"
                Item { Layout.fillWidth: true }
                DateMark {
                    visible: root.clockStyle === "dateTime"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: 2 * root.d
                    pixelSize: IrisStyle.typeMeta * root.clockScale
                    dayColor: root.clockAccent
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
                    font.pixelSize: IrisStyle.typeMeta
                    font.weight: IrisStyle.weight(Font.Medium)
                }
                IrisClock {
                    id: clusterClock
                    Layout.alignment: Qt.AlignVCenter
                    family: root.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(pixelSize)
                    minorFamily: root.nothingLook ? IrisStyle.fontLabel : family
                    pixelSize: root.figureSize
                    separatorColor: root.clockAccent
                    opacity: clockFlight.hides(clusterClock) ? 0 : 1
                }
                PrivacyMarks { Layout.alignment: Qt.AlignVCenter; spelled: true }
                Item { Layout.fillWidth: true }
            }

            CompactRow {
                id: eventRow
                mode: "event"
                anchors.leftMargin: 6 * root.d
                // Face ID: corner brackets, two eyes and a smile drawn in green, sprung in.
                Item {
                    visible: root.event.kind === "unlock"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: root.compactHeight - Math.round(12 * root.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    FaceMark { anchors.fill: parent; tint: IrisStyle.identity.green; live: root.eventShown && root.event.kind === "unlock" }
                }
                // Silent: Apple's red capsule with the struck bell.
                Rectangle {
                    visible: root.event.kind === "silent"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Math.round(46 * root.d)
                    Layout.preferredHeight: root.compactHeight - Math.round(14 * root.d)
                    radius: height / 2
                    color: IrisStyle.danger
                    Glyph { anchors.centerIn: parent; text: "notifications_off"; iconSize: 16 * root.d; color: IrisStyle.onTintFor(IrisStyle.danger) }
                }
                // Charging: the battery stood upright, filled to its level, the bolt inside.
                Rectangle {
                    visible: root.event.kind === "charge"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 6 * root.d
                    Layout.rightMargin: 4 * root.d
                    Layout.preferredWidth: Math.round(15 * root.d)
                    Layout.preferredHeight: root.compactHeight - Math.round(14 * root.d)
                    radius: Math.round(4 * root.d) // iris-literal: the battery drawn as the device, its own corners
                    color: IrisStyle.trackOf(IrisStyle.identity.green)
                    clip: true
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: parent.height * Math.max(0.12, root.event.value)
                        radius: parent.radius
                        color: IrisStyle.identity.green
                        Behavior on height { NumberAnimation { duration: IrisStyle.duration(700); easing.type: Easing.OutCubic } }
                    }
                    Glyph { anchors.centerIn: parent; text: "bolt"; iconSize: 12 * root.d; color: IrisStyle.onTintFor(IrisStyle.identity.green) }
                }
                // An accessory stands as itself, large and bare, as AirPods do on a phone.
                Glyph {
                    visible: root.event.kind === "accessory"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 2 * root.d
                    text: root.eventGlyph
                    iconSize: Math.round(root.compactHeight * 0.56)
                    color: IrisStyle.text
                }
                // Kept: the radar it was dropped on, still.
                DropRadar {
                    visible: root.event.kind === "kept"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: root.compactHeight - Math.round(12 * root.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    tint: root.eventInk
                    live: false
                }
                Rectangle {
                    visible: !["unlock", "silent", "charge", "accessory", "kept"].includes(root.event.kind)
                    Layout.preferredWidth: root.compactHeight - Math.round(12 * root.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: IrisStyle.capsule(width)
                    color: root.nothingLook ? IrisStyle.fill : IrisStyle.tintFill(root.event.tint)
                    Glyph {
                        visible: !root.eventIsBattery
                        anchors.centerIn: parent
                        text: root.eventGlyph
                        iconSize: 16 * root.d
                        color: root.eventInk
                    }
                    IrisBatteryMark {
                        visible: root.eventIsBattery
                        anchors.centerIn: parent
                        markHeight: Math.round(9 * root.d)
                        level: Math.max(0, root.event.value)
                        tint: root.eventInk
                        frame: IrisStyle.trackOf(root.eventInk)
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: -1 * root.d
                    IrisText {
                        Layout.fillWidth: true
                        visible: root.event.kind === "accessory" && root.event.detail.length > 0
                        text: root.event.detail
                        color: IrisStyle.muted
                        font.pixelSize: IrisStyle.typeFootnote
                        elide: Text.ElideRight
                    }
                    IrisText {
                        Layout.fillWidth: true
                        visible: root.event.kind !== "silent"
                        text: root.event.title
                        font.pixelSize: IrisStyle.typeLabel
                        font.weight: IrisStyle.weight(Font.DemiBold)
                        elide: Text.ElideRight
                    }
                    IrisText {
                        Layout.fillWidth: true
                        visible: text.length > 0 && root.event.kind !== "status" && root.event.kind !== "accessory"
                        text: root.event.detail
                        color: IrisStyle.muted
                        font.pixelSize: IrisStyle.typeFootnote
                        elide: Text.ElideRight
                    }
                }
                IrisText {
                    visible: root.event.kind === "silent"
                    Layout.alignment: Qt.AlignVCenter
                    text: root.event.title
                    color: IrisStyle.danger
                    font.pixelSize: IrisStyle.typeBody
                    font.weight: IrisStyle.weight(Font.DemiBold)
                }
                // The picture itself as a card at the end (Apple's "Recording saved").
                ClippingRectangle {
                    id: shotCard
                    visible: root.event.kind === "shot" && String(root.event.image ?? "").length > 0
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: root.compactHeight - Math.round(10 * root.d)
                    Layout.preferredWidth: Math.round(Layout.preferredHeight * 1.5)
                    radius: IrisStyle.radiusChip
                    color: IrisStyle.fill
                    IrisImage {
                        anchors.fill: parent
                        decodeWidth: Math.round(shotCard.width * 2)
                        decodeHeight: Math.round(shotCard.height * 2)
                        source: shotCard.visible ? String(root.event.image ?? "") : ""
                        fillMode: Image.PreserveAspectCrop
                    }
                }
                // A switch says its state at the end in its colour (Apple's "Do Not Disturb  On").
                IrisText {
                    visible: root.event.kind === "status"
                    Layout.alignment: Qt.AlignVCenter
                    text: root.event.detail
                    color: root.eventInk
                    font.pixelSize: IrisStyle.typeBody
                    font.weight: IrisStyle.weight(Font.DemiBold)
                }
                // A battery shows its level and itself at the end ("Low Battery  20% ▭").
                IrisBatteryMark {
                    visible: !root.nothingLook && root.eventIsBattery && root.event.kind !== "charge"
                    Layout.alignment: Qt.AlignVCenter
                    markHeight: Math.round(13 * root.d)
                    level: Math.max(0, root.event.value)
                    tint: root.eventInk
                    frame: IrisStyle.trackOf(root.eventInk)
                }
                // A level as dots; a job that ends fills them and sends one pulse through (S6).
                Metric {
                    visible: !root.nothingLook && root.event.value >= 0 && !["done", "accessory", "kept", "soon"].includes(root.event.kind)
                    Layout.alignment: Qt.AlignVCenter
                    value: Math.round(root.event.value * 100)
                    unit: "%"
                    pixelSize: IrisStyle.typeBody
                    weight: IrisStyle.figureWeight
                    color: root.eventInk
                }
                ProgressRing {
                    visible: !root.nothingLook && root.event.value >= 0 && !root.eventIsBattery && !["accessory", "kept"].includes(root.event.kind)
                    Layout.preferredWidth: Math.round(20 * root.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    progress: Math.max(0, root.event.value)
                    tint: root.eventInk
                }
                // The accessory's charge as Apple rings it: green, its figure inside; red when low. The kept drop
                // closes its ring around a tick.
                Item {
                    visible: !root.nothingLook && root.event.value >= 0 && ["accessory", "kept"].includes(root.event.kind)
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: root.compactHeight - Math.round(12 * root.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    readonly property color ink: root.event.kind === "kept" ? root.eventInk
                        : root.event.value <= 0.2 ? IrisStyle.danger : IrisStyle.success
                    ProgressRing {
                        id: endRing
                        anchors.fill: parent
                        stroke: Math.max(2.5, 3 * root.d)
                        tint: parent.ink
                        progress: 0
                        Binding on progress { when: root.eventShown; value: Math.max(0, root.event.value) }
                        Behavior on progress { NumberAnimation { duration: IrisStyle.duration(520); easing.type: Easing.OutCubic } }
                    }
                    Tabular {
                        visible: root.event.kind === "accessory"
                        anchors.centerIn: parent
                        text: Math.round(root.event.value * 100)
                        color: IrisStyle.text
                        font.pixelSize: Math.round(parent.height * 0.36)
                        font.weight: IrisStyle.weight(Font.DemiBold)
                    }
                    Glyph {
                        visible: root.event.kind === "kept"
                        anchors.centerIn: parent
                        text: "check"
                        iconSize: Math.round(parent.height * 0.62)
                        color: parent.ink
                        scale: endRing.progress >= 0.98 ? 1 : 0.4
                        opacity: endRing.progress >= 0.98 ? 1 : 0
                        Behavior on scale { NumberAnimation { duration: IrisStyle.duration(260); easing.type: Easing.OutBack } }
                        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
                    }
                }
                IrisDotStrip {
                    id: eventStrip
                    visible: root.nothingLook && root.event.value >= 0 && !root.eventIsBattery
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: root.stripWidth(8)
                    count: 8
                    value: Math.max(0, root.event.value)
                    indeterminate: donePulse.running
                    fillColor: root.eventInk
                }
                IrisLabel {
                    visible: root.nothingLook && root.event.value >= 0 && !["done", "soon"].includes(root.event.kind)
                    Layout.alignment: Qt.AlignVCenter
                    text: Math.round(root.event.value * 100) + "%"
                    color: IrisStyle.text
                }
                Timer { id: donePulse; interval: IrisStyle.duration(620) }
                Connections {
                    target: root
                    function onEventChanged(): void { if (root.event.kind === "done" && !root.event.failed) donePulse.restart() }
                }
            }

            // AirDrop's radar: rings run out from what you hold, the Shelf named as where it lands, an empty ring
            // waiting at the end. Held there a moment, the Shelf opens under it.
            CompactRow {
                id: dropRow
                mode: "drop"
                anchors.leftMargin: 6 * root.d
                DropRadar {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: root.compactHeight - Math.round(8 * root.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    tint: root.nothingLook ? IrisStyle.text : IrisStyle.accent
                    live: root.compactMode === "drop"
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: -1 * root.d
                    IrisText {
                        Layout.fillWidth: true
                        text: Translation.tr("Shelf")
                        font.pixelSize: IrisStyle.typeLabel
                        font.weight: IrisStyle.weight(Font.DemiBold)
                        elide: Text.ElideRight
                    }
                    IrisText {
                        Layout.fillWidth: true
                        text: !root.dropFiles ? Translation.tr("Let go to keep the text")
                            : root.dropCount === 1 ? Translation.tr("Let go to keep 1 file") : Translation.tr("Let go to keep %1 files").arg(root.dropCount)
                        color: IrisStyle.muted
                        font.pixelSize: IrisStyle.typeFootnote
                        elide: Text.ElideRight
                    }
                }
                ProgressRing {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: root.compactHeight - Math.round(14 * root.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    stroke: Math.max(2.5, 3 * root.d)
                    tint: root.nothingLook ? IrisStyle.text : IrisStyle.accent
                    progress: 0.22
                    RotationAnimation on rotation {
                        running: root.compactMode === "drop" && IrisStyle.motionEnabled
                        from: 0; to: 360; duration: 2400; loops: Animation.Infinite
                    }
                }
            }

            CompactRow {
                id: feedbackRow
                mode: "feedback"
                LevelFace {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    glyph: root.feedbackIcon
                    value: root.feedbackValue
                    muted: root.feedbackMuted
                    style: root.levelStyle
                    showValue: root.levelFigure
                }
            }

            Loader {
                id: designFace
                active: root.faceUrl.length > 0
                source: root.faceUrl
                readonly property real laidWidth: root.zoned ? root.heartTarget : root.compactTargetWidth
                readonly property real swellShift: Math.round(chassis.swellInset / 2 - root.bandLift) * (root.bottomEdge ? -1 : 1)
                // The face's box in the heart; a face that draws on the body's edge (`edge`, Aura) keeps all of it
                // under the song's wings, any other is laid between them.
                readonly property real boxX: (root.zoned ? Math.round(barZones.heartAlong + (root.heartLength - designFace.laidWidth) / 2)
                    : Math.round((parent.width - designFace.laidWidth) / 2)) + (root.piecesAtStart ? root.barPieceReserve : 0)
                readonly property real boxWidth: Math.max(0, designFace.laidWidth - root.barPieceReserve)
                readonly property real inset: designFace.item?.edge === true ? 0 : root.wingSlot
                x: designFace.boxX + designFace.inset
                y: designFace.swellShift
                width: Math.max(0, designFace.boxWidth - 2 * designFace.inset)
                height: parent.height
                opacity: root.heartShown && root.faceTakes ? root.heartUncovered : 0
                visible: opacity > 0
                onLoaded: item.island = root
            }
            // The song at a face's sides (songWings): its cover, then its visualizer, or under Nothing where it is.
            IrisArtwork {
                id: wingCover
                x: designFace.boxX + root.wingLead
                y: Math.round((parent.height - height) / 2) + designFace.swellShift
                width: root.wingCoverSize
                height: root.wingCoverSize
                source: root.songWings ? MediaArtwork.displaySource : ""
                circular: Config.options?.iris?.player?.roundCover ?? false
                radius: circular ? width / 2 : Math.round(width * 0.2)
                opacity: (root.songWings && root.heartShown ? (root.playing ? 1 : 0.6) : 0) * root.heartUncovered * (coverFlight.hides(wingCover) ? 0 : 1)
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
            }
            Item {
                id: wingTrail
                x: designFace.boxX + designFace.boxWidth - root.wingLead - root.wingBox
                y: designFace.swellShift
                width: root.wingBox
                height: parent.height
                opacity: (root.songWings && root.heartShown ? 1 : 0) * root.heartUncovered
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
                IrisVisualizer {
                    id: wingVisualizer
                    anchors.centerIn: parent
                    visible: !root.nothingLook
                    running: wingTrail.visible && visible && root.playing && !root.visualExpanded
                    tint: IrisStyle.visualizerTint(root.artTint)
                    barHeight: Math.round(root.compactHeight * 0.4)
                }
                IrisDotStrip {
                    anchors.centerIn: parent
                    visible: root.nothingLook
                    width: root.stripWidth(4)
                    count: 4
                    value: root.trackProgress
                    fillColor: root.playing ? IrisStyle.text : IrisStyle.textSecondary
                }
            }

            Grid {
                id: barPieceRow
                z: 1
                columns: root.vertical ? 1 : Math.max(1, root.barPieces.length)
                x: root.vertical ? Math.round((parent.width - width) / 2)
                    : root.piecesAtStart ? Math.round(12 * root.d) : parent.width - width - Math.round(12 * root.d)
                y: !root.vertical ? Math.round((parent.height - height) / 2)
                    : root.piecesAtStart ? Math.round(12 * root.d) : parent.height - height - Math.round(12 * root.d)
                spacing: root.barPieceGap
                // The pieces step aside while a large notice holds the body.
                opacity: 1 - IrisStyle.contentAt(root.noticeOpen)
                visible: root.barPieces.length > 0 && !root.inlineExpanded && !root.zoned && opacity > 0.002
                Repeater {
                    model: root.barPieces
                    delegate: Item {
                        id: barPiece
                        required property string modelData
                        readonly property bool strip: barPiece.modelData === "tray" && root.trayAppsFace
                        width: barPiece.strip && !root.vertical ? traySlot.width : root.barPieceSize
                        height: barPiece.strip && root.vertical ? traySlot.height : root.barPieceSize
                        readonly property bool lifted: root.draggedSlot === "extra-" + barPiece.modelData
                        opacity: barPiece.lifted ? 0 : 1
                        IrisTrayStrip {
                            id: traySlot
                            visible: barPiece.strip
                            cellSize: root.barPieceSize
                            spacing: root.trayStripGap
                            vertical: root.vertical
                            screenName: root.targetScreen?.name ?? ""
                            screenOffsetY: root.screenOffsetY
                            menuToward: root.trayMenuToward
                            draggable: true
                            onCellHover: on => root.hoveredPieces += on ? 1 : -1
                        }
                        IrisBubbleFace {
                            visible: !barPiece.strip
                            anchors.fill: parent
                            screenName: root.targetScreen?.name ?? ""
                            kind: barPiece.modelData
                            plated: true
                            hovered: pieceHover.hovered
                            pressed: pieceGrip.pressed
                        }
                        HoverHandler {
                            id: pieceHover
                            enabled: !barPiece.strip
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: root.hoveredPieces += pieceHover.hovered ? 1 : -1
                        }
                        Component.onDestruction: if (pieceHover.hovered) root.hoveredPieces -= 1
                        IrisBubbleGrip {
                            id: pieceGrip
                            anchors.fill: parent
                            visible: !barPiece.strip
                            slot: "extra-" + barPiece.modelData
                            kind: barPiece.modelData
                            screenName: root.targetScreen?.name ?? ""
                            screenOffsetY: root.screenOffsetY
                            holdLifts: !IrisState.edit
                            pullDistance: IrisState.edit ? 6 * root.d : 0
                            onTapped: {
                                if (IrisState.edit) {
                                    IrisState.editSelection = ""
                                    IrisState.editTarget = "pieces"
                                    return
                                }
                                root.activatePiece(barPiece.modelData, barPiece)
                            }
                        }
                        WheelHandler {
                            enabled: barPiece.modelData === "sound" || barPiece.modelData === "mic"
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: event => {
                                const steps = root.wheelSteps(event)
                                if (steps === 0) return
                                IrisState.quietLevels()
                                root.stepLevel(barPiece.modelData === "mic" ? "mic" : "volume", steps)
                            }
                        }
                    }
                }
            }

            IslandCompactColumn {
                id: compactColumn
                opacity: root.heartUncovered
                visible: root.vertical && root.heartShown
                island: root
                mode: root.compactMode
                thickness: root.compactHeight
                clockScale: root.clockScale
                clockAccent: root.clockAccent
                clockStyle: root.clockStyle
                x: root.zoned && root.notch ? (root.rightEdge ? -root.heartSwell / 2 : root.heartSwell / 2) : 0
                width: parent.width
                height: root.zoned ? Math.round(root.heartLength) : parent.height - root.barPieceReserve
                y: root.zoned ? Math.round(barZones.heartAlong) : root.piecesAtStart ? root.barPieceReserve : 0
            }

            IslandBarZones {
                id: barZones
                anchors.fill: parent
                visible: root.zoned
                vertical: root.vertical
                island: root
                thickness: root.stripHeight
                // A clear strip has no body of its own: its items share the notch's line, as a status bar shares the island's.
                laneTop: root.menubar && root.bottomEdge && !root.clearStrip ? root.compactHeight - root.stripHeight : 0
                lane: root.clearStrip ? root.compactHeight : root.stripHeight
                clear: root.clearStrip
                shelf: root.layout === "full"
                menuBar: root.menubar || root.pods
                bottomEdge: root.bottomEdge
                lift: root.bandLift
                heartLength: root.heartLength
                start: root.zoned ? Array.from(IrisStyle.structuralValue("bar.fullStart", ["workspaces", "window"])).concat(root.absorbedStart.length > 0 ? ["|"] : [], root.absorbedStart) : []
                center: root.zoned ? IrisStyle.structuralValue("bar.fullCenter", ["island"]) : []
                end: root.zoned ? Array.from(IrisStyle.structuralValue("bar.fullEnd", ["tray", "notifications", "sound", "controls"]))
                    .concat(IrisPieces.carriedBy(Config.options?.iris?.bubbles, IrisStyle.structuralValue("bar.pieces", [])).filter(kind => kind !== "media"))
                    .concat(root.absorbedPieces.some(kind => !root.absorbedStart.includes(kind)) ? ["|"] : [],
                        root.absorbedPieces.filter(kind => !root.absorbedStart.includes(kind))) : []
                absorbed: root.absorbedPieces
                screenName: root.targetScreen?.name ?? ""
                clockStyle: root.clockStyle
                clockScale: root.clockScale
                clockAccent: root.clockAccent
            }

            MouseArea {
                id: compactPress
                // A large notice is taller than the resting line: the whole card answers a tap.
                readonly property real noticeReach: root.vertical ? 0 : Math.max(0, chassis.bodyHeight - root.compactHeight)
                x: root.zoned && !root.vertical ? Math.round(barZones.heartAlong) : 0
                y: root.zoned && root.vertical ? Math.round(barZones.heartAlong) : root.bottomEdge ? -compactPress.noticeReach : 0
                width: root.zoned && !root.vertical ? Math.round(root.heartLength) : parent.width
                height: root.zoned && root.vertical ? Math.round(root.heartLength) : parent.height + compactPress.noticeReach
                enabled: !root.inlineExpanded && (!root.zoned || root.heartShown)
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                cursorShape: islandGrip.carrying ? Qt.ClosedHandCursor
                    : IrisState.edit ? Qt.OpenHandCursor : Qt.PointingHandCursor
                preventStealing: true
                Accessible.role: Accessible.Button
                Accessible.name: IrisState.edit ? Translation.tr("Edit Dynamic Island")
                    : root.expanded ? Translation.tr("Collapse island") : Translation.tr("Expand island")
                pressAndHoldInterval: 380
                QtObject {
                    id: islandGrip
                    property bool carrying: false
                    property point pressAt: Qt.point(0, 0)
                    function publish(mouse, released: bool): void {
                        const p = compactPress.mapToItem(root.QsWindow.window?.contentItem, mouse.x, mouse.y)
                        IrisState.bubbleDrag = {
                            slot: "island", kind: "island", screen: root.targetScreen?.name ?? "",
                            x: p.x, y: p.y + root.screenOffsetY,
                            size: root.compactHeight, width: chassis.width, released: released
                        }
                    }
                }
                onPressed: mouse => { islandGrip.pressAt = Qt.point(mouse.x, mouse.y) }
                onPressAndHold: mouse => {
                    if (mouse.button !== Qt.LeftButton) return
                    islandGrip.carrying = true
                    islandGrip.publish(mouse, false)
                }
                onPositionChanged: mouse => {
                    if (!islandGrip.carrying && IrisState.edit && (mouse.buttons & Qt.LeftButton)
                            && Math.hypot(mouse.x - islandGrip.pressAt.x, mouse.y - islandGrip.pressAt.y) > 6 * root.d) {
                        islandGrip.carrying = true
                    }
                    if (islandGrip.carrying) islandGrip.publish(mouse, false)
                }
                onReleased: mouse => {
                    if (!islandGrip.carrying) return
                    islandGrip.publish(mouse, true)
                    Qt.callLater(() => islandGrip.carrying = false)
                }
                onCanceled: {
                    if (islandGrip.carrying && IrisState.bubbleDrag) {
                        IrisState.bubbleDrag = Object.assign({}, IrisState.bubbleDrag, { released: true })
                    }
                    islandGrip.carrying = false
                }
                onClicked: mouse => {
                    if (islandGrip.carrying) return
                    if (mouse.button === Qt.MiddleButton) {
                        if (root.hasMedia) MprisController.togglePlaying()
                        return
                    }
                    if (IrisState.edit) {
                        IrisState.editSelection = ""
                        IrisState.editTarget = "island"
                        return
                    }
                    if (root.eventShown && root.event.kind === "shot" && String(root.event.image ?? "").length > 0) {
                        Qt.openUrlExternally(root.event.image)
                        return
                    }
                    if (root.pinned) root.expanded = false
                    else {
                        const at = compactPress.mapToItem(root, mouse.x, mouse.y)
                        root.pageOriginX = at.x
                        root.pageOriginY = at.y
                        root.openPage(root.tapPage, true, null)
                    }
                }
            }
        }

        IslandNoticeCard {
            id: noticeCard
            event: root.event
            reveal: root.noticeOpen
            live: root.noticeLarge
            band: root.compactHeight
            notch: root.notch
            maxWidth: root.availableWidth
            nothingLook: root.nothingLook
            dim: root.paintNudge * (1 - root.spotlightYield)
            x: 0
            y: root.bottomEdge ? chassis.height - chassis.bottomInset - height : chassis.topInset
            width: chassis.width
            height: chassis.bodyHeight
        }

    }

    ClippingRectangle {
        id: extension
        readonly property bool carded: root.extensionRole === "event" && root.noticeSized
        readonly property real targetWidth: root.extensionRole === "page" ? root.expandedWidth
            : extension.carded ? root.noticeWidth : Math.round(320 * root.d)
        readonly property real targetHeight: root.extensionRole === "page"
            ? (details.item?.implicitHeight ?? 0) + root.padding * 2
            : extension.carded ? root.noticeHeight : root.compactHeight
        readonly property real targetRadius: root.extensionRole === "page"
            ? IrisStyle.openedRadius(IrisStyle.barShape, IrisStyle.radiusPanel)
            : extension.carded ? root.noticeRadius : root.meltedCorner
        readonly property alias presentation: extensionSpring.value
        IrisSpring { id: extensionSpring; surface: "island"; to: root.extensionOpen ? 1 : 0; minimum: 0 }
        readonly property real reach: Math.round((root.vertical ? extension.targetWidth : extension.targetHeight) * extension.presentation)
        readonly property real liveWidth: Math.round(root.originWidth
            + ((root.vertical ? extension.targetHeight : extension.targetWidth) - root.originWidth) * extension.presentation)
        x: !extension.anchoredShape ? chassis.x
            : root.pagesHang ? Math.round((root.width - extension.width) / 2)
            : root.grownPage && root.vertical ? (root.rightEdge ? root.width - extension.reach : -root.grownInset)
            : root.vertical ? (root.rightEdge ? chassis.x - extension.reach : chassis.x + chassis.width)
            : root.extensionX(root.originWidth) + (root.extensionX(extension.targetWidth)
                - root.extensionX(root.originWidth)) * extension.presentation
        y: !extension.anchoredShape ? chassis.y
            : root.vertical ? root.extensionY(root.originWidth) + (root.extensionY(extension.targetHeight)
                - root.extensionY(root.originWidth)) * extension.presentation
            : root.zoned && !root.vertical && !root.fromHeart
                ? (root.bottomEdge ? root.height - root.stripHeight - root.floatGap - extension.reach : root.stripHeight + root.floatGap)
            : root.grownPage ? (root.bottomEdge ? root.height - extension.reach : -root.grownInset)
            : root.bottomEdge ? root.height - chassis.bodyHeight - root.seam - extension.reach : chassis.bodyHeight + root.seam
        width: !extension.anchoredShape ? chassis.width : root.vertical ? extension.reach + root.grownInset : extension.liveWidth
        height: !extension.anchoredShape ? chassis.height : root.vertical ? extension.liveWidth : extension.reach + root.grownInset
        radius: root.pagesHang ? IrisStyle.corner(extension.targetRadius)
            : extension.anchoredShape
            ? root.originWidth / 2 + (extension.targetRadius - root.originWidth / 2) * extension.presentation
            : chassis.radius
        color: IrisStyle.bodyClip
        readonly property bool anchoredShape: (root.anchored || root.pagesHang) && !(root.inlinePages && root.extensionRole === "page")
        HoverHandler { id: extensionHover }
        WheelHandler {
            enabled: root.expanded
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => root.wheelPages(event, false)
        }
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
                && (Config.options?.iris?.player?.artworkBackground ?? true) && !IrisStyle.glassy
                && MediaArtwork.displaySource.length > 0
            opacity: details.opacity * artBackdrop.shown
            // Never drawn here: the field paints it as the page body's material, so the cover follows the silhouette.
            visible: false
            layer.enabled: true
            layer.smooth: true
            // A Design may lay the record under its page its own way (`islandArtBackdrop`); the setting still decides whether.
            readonly property string designUrl: IrisDesign.skin("islandArtBackdrop")
            source: artBackdrop.designUrl
            sourceComponent: artBackdrop.designUrl.length > 0 ? null : engineArtBackdrop
            onLoaded: if (artBackdrop.designUrl.length > 0 && "island" in item) item.island = root
            Component {
                id: engineArtBackdrop
                IrisMediaBackdrop { source: MediaArtwork.displaySource; strength: 0.9 }
            }
        }
        Loader {
            id: details
            // Upright, the page is revealed from its middle as the body grows along the edge.
            y: extension.anchoredShape ? root.padding + (root.vertical || root.bottomEdge ? 0 : root.grownInset)
                : root.vertical ? root.padding - Math.round((chassis.openH - chassis.height) / 2)
                : root.padding + chassis.topInset - (root.bottomEdge ? 0 : Math.round(Math.max(0, chassis.openH - chassis.bodyHeight)))
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: root.vertical && !extension.anchoredShape ? (chassis.leftInset - chassis.rightInset) / 2
                : root.vertical && root.grownPage ? (root.rightEdge ? -root.grownInset / 2 : root.grownInset / 2) : 0
            width: Math.max(0, root.expandedWidth - root.padding * 2)
            // Incubated: the chassis spring still waits for Loader.Ready, so nothing moves before the page exists.
            active: root.expanded || details.opacity > 0.004 || details.warm
            asynchronous: true
            property bool warm: false
            Timer { id: pageWarmth; interval: 20000; onTriggered: details.warm = false }
            // The first expansion after the shell starts paid for building the page types (≈60 ms on the GUI thread, in
            // the middle of the spring). They are built once here instead, at rest a few seconds after start, and the
            // warmth then runs out as usual; later expansions find the types ready.
            Timer {
                interval: 6000
                running: true
                onTriggered: if (!root.expanded) { details.warm = true; pageWarmth.restart() }
            }
            Connections {
                target: root
                function onPointerOnIslandChanged(): void {
                    if (!root.pointerOnIsland) return
                    details.warm = true
                    pageWarmth.stop()
                }
                function onExpandedChanged(): void {
                    if (root.expanded) { details.warm = true; pageWarmth.stop() }
                    else pageWarmth.restart()
                }
            }
            onActiveChanged: { if (!active) root.page = "" }
            readonly property real presentation: extension.anchoredShape ? extension.presentation : chassis.presentation
            opacity: (root.anchored && root.extensionRole !== "page" ? 0 : 1) * IrisStyle.recompose * (IrisStyle.revealDrops
                ? IrisStyle.ramp(details.presentation, IrisStyle.dropRise, IrisStyle.dropSpan)
                : IrisStyle.contentAt(details.presentation))
            scale: IrisStyle.revealInflates
                ? Math.max(0.35, Math.min(1, (extension.anchoredShape ? extension.height : root.vertical ? chassis.height : chassis.bodyHeight)
                    / Math.max(1, extension.anchoredShape ? extension.targetHeight : chassis.openH)))
                : IrisStyle.revealFades ? 1 : 0.96 + 0.04 * details.opacity
            transformOrigin: root.bottomEdge ? Item.Bottom : Item.Top
            // Kept in the scene while warm: hiding it drops its render nodes, and
            // the first frame of the next open pays for building them all again.
            visible: opacity > 0 || details.warm
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
                    readonly property bool resident: pageItem.current || pageItem.opacity > 0.004
                        || root.pageIntent === pageItem.name
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
                    implicitHeight: root.effectivePage === "controls" ? controlsPage.implicitHeight
                        : root.effectivePage === "media" ? mediaPage.implicitHeight
                        : root.effectivePage === "activity" ? activityPage.implicitHeight
                        : root.effectivePage === "tray" ? trayPage.implicitHeight
                        : root.effectivePage === "tools" ? toolsPage.implicitHeight
                        : root.effectivePage === "shelf" ? shelfPage.implicitHeight
                        : root.cardPages.includes(root.effectivePage) ? cardPage.implicitHeight
                        : desktopPage.implicitHeight

                    Page {
                        id: shelfPage
                        name: "shelf"
                        Loader {
                            id: shelfLoader
                            Layout.fillWidth: true
                            Layout.preferredHeight: item?.implicitHeight ?? 0
                            active: shelfPage.resident
                            asynchronous: !shelfPage.current
                            sourceComponent: IslandShelfPage { width: shelfLoader.width; island: root }
                        }
                    }

                    Page {
                        id: trayPage
                        name: "tray"
                        Loader {
                            id: trayLoader
                            Layout.fillWidth: true
                            Layout.preferredHeight: item?.implicitHeight ?? 0
                            active: trayPage.resident
                            asynchronous: !trayPage.current
                            sourceComponent: Flickable {
                                id: trayView
                                width: trayLoader.width
                                implicitHeight: Math.min(300 * root.d, trayContent.implicitHeight)
                                contentHeight: trayContent.implicitHeight
                                clip: true
                                IrisTray { id: trayContent; width: parent.width; bottomEdge: root.bottomEdge; items: root.trayItems }
                            }
                        }
                    }
                    // Weather, Calendar and Vitals: the bubble's card, grown inside the Island.
                    Page {
                        id: cardPage
                        name: root.cardPages.includes(root.effectivePage) ? root.effectivePage : root.cardPages[0]
                        Loader {
                            id: cardLoader
                            Layout.fillWidth: true
                            Layout.preferredHeight: item?.implicitHeight ?? 0
                            active: cardPage.resident
                            asynchronous: !cardPage.current
                            sourceComponent: Flickable {
                                width: cardLoader.width
                                implicitHeight: Math.min(Math.round(520 * root.d), cardContent.implicitHeight)
                                contentHeight: cardContent.implicitHeight
                                clip: true
                                IrisCardContent {
                                    id: cardContent
                                    width: parent.width
                                    kind: cardPage.name
                                    screenName: root.targetScreen?.name ?? ""
                                    contentActive: cardPage.current && root.visualExpanded
                                    bodyRadius: chassis.openRadius
                                    bodyInset: root.padding
                                    onNavigate: root.expanded = false
                                }
                            }
                        }
                    }
                    Page {
                        id: controlsPage
                        name: "controls"
                        Loader {
                            id: controlsLoader
                            // Built once at idle (or on first use) and kept: building it on every open was the
                            // Control Center's whole opening cost.
                            property bool kept: false
                            property Timer warm: Timer {
                                running: GlobalStates.deferredPanelsReady && root.focusedOutput && !controlsLoader.kept
                                interval: 4000
                                onTriggered: controlsLoader.kept = true
                            }
                            onLoaded: controlsLoader.kept = true
                            Layout.fillWidth: true
                            Layout.preferredHeight: item?.implicitHeight ?? 0
                            active: controlsPage.resident || controlsLoader.kept
                            asynchronous: !controlsPage.current
                            visible: active
                            sourceComponent: IrisQuickPanel { width: controlsLoader.width; targetScreen: root.targetScreen; bodyRadius: chassis.openRadius; bodyInset: root.padding }
                        }
                    }
                    Page {
                        id: toolsPage
                        name: "tools"
                        Loader {
                            id: toolsLoader
                            Layout.fillWidth: true
                            Layout.preferredHeight: item?.implicitHeight ?? 0
                            active: toolsPage.resident
                            asynchronous: !toolsPage.current
                            sourceComponent: IrisTools {
                                width: toolsLoader.width
                                onActivityRequested: root.page = "activity"
                            }
                        }
                    }

                    Page {
                        id: mediaPage
                        name: "media"
                        spacing: 14 * root.d
                        Loader {
                            id: mediaLoader
                            Layout.fillWidth: true
                            Layout.preferredHeight: item?.implicitHeight ?? 0
                            active: mediaPage.resident
                            asynchronous: !mediaPage.current
                            // A Design may set the record its own way (`islandMedia`, which keeps every block the engine's page has).
                            readonly property string designUrl: IrisDesign.skin("islandMedia")
                            source: mediaLoader.designUrl
                            sourceComponent: mediaLoader.designUrl.length > 0 ? null : engineMediaPage
                            onLoaded: if (mediaLoader.designUrl.length > 0) item.island = root
                            Component {
                                id: engineMediaPage
                                IslandMediaPage { width: mediaLoader.width; island: root }
                            }
                        }
                    }

                    Page {
                        id: activityPage
                        name: "activity"
                        spacing: 12 * root.d
                        Loader {
                            id: activityLoader
                            Layout.fillWidth: true
                            Layout.preferredHeight: item?.implicitHeight ?? 0
                            active: activityPage.resident
                            asynchronous: !activityPage.current
                            // A Design may set the running jobs its own way (`islandActivity`, on the same services).
                            readonly property string designUrl: IrisDesign.skin("islandActivity")
                            source: activityLoader.designUrl
                            sourceComponent: activityLoader.designUrl.length > 0 ? null : engineActivityPage
                            onLoaded: if (activityLoader.designUrl.length > 0) item.island = root
                        }
                        Component {
                            id: engineActivityPage
                            IslandActivityPage { width: activityLoader.width; island: root }
                        }
                    }

                    Page {
                        id: desktopPage
                        name: "desktop"
                        bleeds: desktopLoader.item?.showBanner ?? false
                        spacing: 14 * root.d
                        Loader {
                            id: desktopLoader
                            Layout.fillWidth: true
                            Layout.preferredHeight: item?.implicitHeight ?? 0
                            active: desktopPage.resident
                            asynchronous: !desktopPage.current
                            // A Design may print the page its own way (`islandDesktop`, on the same blocks in the same
                            // order); while the blocks are being arranged the engine's page stands in to be arranged.
                            readonly property string designUrl: root.studio ? "" : root.skinOf(IrisDesign.skin("islandDesktop"), "Desktop.qml")
                            source: desktopLoader.designUrl
                            sourceComponent: desktopLoader.designUrl.length > 0 ? null : engineDesktopPage
                            onLoaded: if (desktopLoader.designUrl.length > 0) item.island = root
                        }
                        Component {
                            id: engineDesktopPage
                            IslandDesktopPage {
                                width: desktopLoader.width
                                island: root
                                bodyRadius: chassis.openRadius
                                bodyInset: root.padding
                                navOffset: (root.navUrl.length > 0 ? designNav.height : navFrame.height) + expandedContent.rowSpacing
                            }
                        }
                    }
                }

                Loader {
                    id: designNav
                    Layout.row: root.bottomEdge ? 1 : 0
                    Layout.fillWidth: true
                    active: root.navUrl.length > 0
                    visible: designNav.active
                    source: root.navUrl
                    onLoaded: item.island = root
                }

                IrisControlPlate {
                    id: navFrame
                    Layout.row: root.bottomEdge ? 1 : 0
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.navUrl.length === 0
                    material: root.pagePlate

                    RowLayout {
                        id: navRow
                        spacing: 4 * root.d

                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: event => root.wheelPages(event, true)
                        }

                        Repeater {
                            model: root.navEntries
                            delegate: Item {
                                id: navSlot
                                required property var modelData
                                implicitWidth: navSlot.modelData.kind === "|" ? Math.round(9 * root.d) : navButton.implicitWidth
                                implicitHeight: navButton.implicitHeight
                                Rectangle {
                                    visible: navSlot.modelData.kind === "|"
                                    anchors.centerIn: parent
                                    width: 1
                                    height: Math.round(14 * root.d)
                                    color: IrisStyle.fill
                                }
                                IrisButton {
                                    id: navButton
                                    visible: navSlot.modelData.kind !== "|"
                                    readonly property string target: navSlot.modelData.page ?? ""
                                    selected: navButton.target.length > 0 && root.effectivePage === navButton.target
                                    quiet: !navButton.selected
                                    implicitWidth: root.navSlot
                                    implicitHeight: Math.round(30 * root.d)
                                    buttonRadius: navFrame.controlRadius
                                    buttonRadiusPressed: navFrame.controlRadius
                                    colBackgroundHover: IrisStyle.fillHover
                                    Accessible.name: Translation.tr(navSlot.modelData.label ?? "")
                                    onHoveredChanged: root.hoverNav(navSlot.modelData.kind, navButton.target, navButton.hovered)
                                    onClicked: root.activateNav(navSlot.modelData.kind)
                                    Glyph {
                                        anchors.centerIn: parent
                                        text: navSlot.modelData.glyph ?? ""
                                        fill: navButton.selected ? 1 : 0
                                        iconSize: 18 * root.d
                                        // Chosen is inverted (S1): the glyph takes the plate's label ink, not the accent it sits on.
                                        color: navButton.selected ? IrisStyle.selectionLabel
                                            : navButton.hovered ? IrisStyle.text : IrisStyle.textSecondary
                                    }
                                }
                            }
                        }
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

            LevelFace {
                Layout.fillWidth: true
                Layout.fillHeight: true
                glyph: root.feedbackIcon
                value: root.feedbackValue
                muted: root.feedbackMuted
                style: root.levelStyle
                showValue: root.levelFigure
                barFill: IrisStyle.text
            }
        }
        // A notice hung under the strip: the card when Large, else the line.
        IslandNoticeCard {
            anchors.fill: parent
            event: root.event
            reveal: extension.anchoredShape && root.extensionRole === "event" ? extension.presentation : 0
            live: root.noticeLarge
            compact: !extension.carded
            band: root.compactHeight
            notch: root.notch
            maxWidth: root.availableWidth
            nothingLook: root.nothingLook
            dim: root.paintNudge
        }
    }
}
