pragma ComponentBehavior: Bound

import qs.modules.shared.lock
import qs.modules.shared.mascot
import qs.modules.shared.polkit
import qs.modules.shared.regionSelector
import qs.modules.shared.screenCorners
import qs.modules.shared.overlay
import qs.modules.shared.workspaceStrip
import qs.modules.shared.clipboard as ClipboardModule

import qs.modules.waffle.altSwitcher as WaffleAltSwitcherModule
import qs.modules.waffle.background as WaffleBackgroundModule
import qs.modules.waffle.clipboard as WaffleClipboardModule
import qs.modules.waffle.onScreenDisplay as WaffleOSDModule
import qs.modules.waffle.notificationPopup as WaffleNotificationPopupModule

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.services
import qs.services.deferred
import qs.modules.waffle.state

Item {
    id: root

    readonly property var waffleAltSwitcherOptions:
        Config.options?.waffles?.altSwitcher ?? ({})
    readonly property string waffleAltSwitcherPreset:
        root.waffleAltSwitcherOptions.preset ?? "thumbnails"
    readonly property bool waffleAltSwitcherVisual:
        root.waffleAltSwitcherPreset !== "none"
        && !((root.waffleAltSwitcherOptions.noVisualUi ?? false)
            && root.waffleAltSwitcherPreset !== "skew")

    // Immediate panels — visible at first frame or must catch early events
    component PanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && (Config.options?.enabledPanels ?? []).includes(identifier) && extraCondition
    }

    // Deferred panels — loaded asynchronously after first frame to reduce boot contention
    component DeferredPanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        loading: Config.ready && GlobalStates.shellEntryReady
            && (Config.options?.enabledPanels ?? []).includes(identifier) && extraCondition
        activeAsync: Config.ready && GlobalStates.deferredPanelsReady && (Config.options?.enabledPanels ?? []).includes(identifier) && extraCondition
    }

    component OnDemandPanelLoader: LazyLoader {
        id: onDemandLoader
        required property string identifier
        required property bool open
        property bool retainAfterUse: false
        property bool used: false
        property int closeGraceMs: 250
        property int retainIdleMs: 5 * 60 * 1000
        property bool resident: open
        // A surface every family has (the rest screen) is no panel of the family's list.
        property bool requireEnabledPanel: true
        property Timer closeGrace: Timer {
            interval: onDemandLoader.closeGraceMs
            onTriggered: onDemandLoader.resident = onDemandLoader.open
        }
        property Timer retainIdle: Timer {
            interval: onDemandLoader.retainIdleMs
            onTriggered: onDemandLoader.resident = onDemandLoader.open
        }
        readonly property bool enabledPanel: Config.ready
            && (!requireEnabledPanel || (Config.options?.enabledPanels ?? []).includes(identifier))
        onOpenChanged: {
            if (open) {
                used = true
                closeGrace.stop()
                retainIdle.stop()
                resident = true
            } else if (retainAfterUse && used) {
                retainIdle.restart()
            } else {
                closeGrace.restart()
            }
        }
        loading: enabledPanel && resident
        activeAsync: enabledPanel && GlobalStates.deferredPanelsReady && resident
    }

    // === Immediate feedback panels within the deferred host ===
    // Core Waffle surfaces (bar/background/backdrop) are owned by the critical
    // startup host so they are not delayed by the rest of this module.
    PanelLoader { identifier: "wNotificationPopup"; component: WaffleNotificationPopupModule.WaffleNotificationPopup {} }
    PanelLoader { identifier: "wOnScreenDisplay"; component: WaffleOSDModule.WaffleOSD {} }

    // === Deferred panels ===
    OnDemandPanelLoader { identifier: "wStartMenu"; open: GlobalStates.searchOpen; retainAfterUse: true; source: "./startMenu/WaffleStartMenu.qml" }
    OnDemandPanelLoader { identifier: "wActionCenter"; open: WaffleState.actionCenterOpen; retainAfterUse: true; source: "./actionCenter/WaffleActionCenter.qml" }
    OnDemandPanelLoader { identifier: "wNotificationCenter"; open: WaffleState.notificationCenterOpen; source: "./notificationCenter/WaffleNotificationCenter.qml" }
    OnDemandPanelLoader { identifier: "wWidgets"; open: WaffleState.widgetsOpen && (Config.options?.waffles?.modules?.widgets ?? true); source: "./widgets/WaffleWidgets.qml" }
    DeferredPanelLoader { identifier: "wLock"; component: Lock {} }
    DeferredPanelLoader { identifier: "wPolkit"; component: Polkit {} }
    OnDemandPanelLoader { identifier: "wSessionScreen"; open: GlobalStates.sessionOpen; source: "./session/WaffleSessionScreen.qml" }
    OnDemandPanelLoader { identifier: "wTaskView"; open: WaffleState.taskViewOpen; source: "./taskview/WaffleTaskView.qml" }

    // Shared modules that work with waffle
    // Shown once at login when enabled (off by default): loaded only while open, then gone with its wallpaper.
    DeferredPanelLoader { identifier: "iiBootGreeting"; extraCondition: GlobalStates.bootGreetingOpen; source: "./screens/WaffleGreeting.qml" }
    // The rest screen (Idle shows it): built when it shows, let go once it has faded.
    OnDemandPanelLoader { identifier: "wRest"; requireEnabledPanel: false; open: GlobalStates.restOpen; source: "./screens/WaffleRest.qml" }
    OnDemandPanelLoader { identifier: "iiCheatsheet"; open: GlobalStates.cheatsheetOpen; source: Plugins.baseUrl("modules/shared/cheatsheet/Cheatsheet.qml") }
    OnDemandPanelLoader { identifier: "iiOnScreenKeyboard"; open: GlobalStates.oskOpen; source: Plugins.baseUrl("modules/shared/onScreenKeyboard/OnScreenKeyboard.qml") }
    OnDemandPanelLoader { identifier: "iiOverlay"; open: OverlayContext.wanted ?? (GlobalStates.overlayOpen || OverlayContext.hasPinnedWidgets || OverlayContext.nativeDialogOpen); source: Plugins.baseUrl("modules/shared/overlay/Overlay.qml") }
    OnDemandPanelLoader { identifier: "iiOverview"; open: GlobalStates.overviewOpen; retainAfterUse: true; closeGraceMs: 300; source: Plugins.baseUrl("modules/shared/overview/Overview.qml") }

    DeferredPanelLoader { identifier: "iiRegionSelector"; component: RegionSelector {} }
    DeferredPanelLoader { identifier: "iiScreenCorners"; component: ScreenCorners {} }

    OnDemandPanelLoader { identifier: "iiWallpaperSelector"; open: GlobalStates.wallpaperSelectorOpen; retainAfterUse: true; closeGraceMs: 250; source: Plugins.baseUrl("modules/shared/wallpaperSelector/WallpaperSelector.qml") }
    OnDemandPanelLoader { identifier: "iiWallpaperLauncher"; open: GlobalStates.wallpaperLauncherOpen; retainAfterUse: true; closeGraceMs: 250; source: Plugins.baseUrl("modules/shared/wallpaperLauncher/WallpaperLauncher.qml") }
    OnDemandPanelLoader { identifier: "iiCoverflowSelector"; open: GlobalStates.coverflowSelectorOpen; retainAfterUse: true; closeGraceMs: 300; source: Plugins.baseUrl("modules/shared/wallpaperSelector/WallpaperCoverflow.qml") }
    DeferredPanelLoader { identifier: "iiClipboard"; extraCondition: Config.options?.panelFamily !== "waffle"; component: ClipboardModule.ClipboardPanel {} }
    OnDemandPanelLoader { identifier: "iiRecordingOsd"; open: RecorderStatus.isRecording; closeGraceMs: 250; source: Plugins.baseUrl("modules/shared/recordingOsd/RecordingOsd.qml") }
    OnDemandPanelLoader { identifier: "iiShellUpdate"; open: ShellUpdates.overlayOpen; closeGraceMs: 250; source: Plugins.baseUrl("modules/shared/shellUpdate/ShellUpdateOverlay.qml") }

    OnDemandPanelLoader {
        identifier: "iiTilingOverlay"
        open: GlobalStates.tilingOverlayPickerOpen || GlobalStates.tilingOverlayOsdOpen
        closeGraceMs: 250
        source: Plugins.baseUrl("modules/shared/tilingOverlay/TilingOverlay.qml")
    }
    DeferredPanelLoader { identifier: "iiWorkspaceStrip"; component: WorkspaceStrip {} }
    DeferredPanelLoader { identifier: "iiMascotCompanion"; extraCondition: (Config.options?.mascot?.enable ?? false) && (Config.options?.mascot?.companion?.enable ?? true); component: MascotCompanion {} }

    LazyLoader {
        loading: Config.ready && GlobalStates.shellEntryReady
            && Config.options?.panelFamily === "waffle"
        activeAsync: Config.ready && GlobalStates.deferredPanelsReady && Config.options?.panelFamily === "waffle"
        component: WaffleClipboardModule.WaffleClipboard {}
    }

    LazyLoader {
        loading: Config.ready && GlobalStates.shellEntryReady
            && Config.options?.panelFamily === "waffle"
            && root.waffleAltSwitcherVisual
        activeAsync: Config.ready && GlobalStates.deferredPanelsReady
            && Config.options?.panelFamily === "waffle"
            && root.waffleAltSwitcherVisual
        component: WaffleAltSwitcherModule.WaffleAltSwitcher {}
    }

    WaffleBackgroundModule.WaffleShellEditHud {}
}
