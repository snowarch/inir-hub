pragma ComponentBehavior: Bound

import qs.modules.shared.bootGreeting
import qs.modules.shared.lock
import qs.modules.shared.mascot
import qs.modules.shared.regionSelector
import qs.modules.shared.overlay

import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.services
import qs.services.deferred
import qs.modules.nihil.state
import qs.modules.nihil.polkit

// NiHiL's panels after the first frame: its own (Start, quick controls, Today, power, menu, tray, OSD, notifications,
// wallpapers, clipboard, the password asks) loaded while open, and the shared tools it wears as they are.
Item {
    id: root

    component PanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && (Config.options?.enabledPanels ?? []).includes(identifier) && extraCondition
    }

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
        property int closeGraceMs: 400
        property int retainIdleMs: 5 * 60 * 1000
        property bool resident: open
        property Timer closeGrace: Timer {
            interval: onDemandLoader.closeGraceMs
            onTriggered: onDemandLoader.resident = onDemandLoader.open
        }
        property Timer retainIdle: Timer {
            interval: onDemandLoader.retainIdleMs
            onTriggered: onDemandLoader.resident = onDemandLoader.open
        }
        readonly property bool enabledPanel: Config.ready
            && (Config.options?.enabledPanels ?? []).includes(identifier)
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

    PanelLoader { identifier: "nNotificationPopup"; source: "./notifications/NihilNotificationPopup.qml" }
    PanelLoader { identifier: "nOsd"; source: "./osd/NihilOsd.qml" }

    OnDemandPanelLoader { identifier: "nStart"; open: GlobalStates.searchOpen; retainAfterUse: true; source: "./start/NihilStart.qml" }
    OnDemandPanelLoader { identifier: "nControl"; open: NihilState.controlOpen; retainAfterUse: true; source: "./control/NihilControl.qml" }
    OnDemandPanelLoader { identifier: "nTray"; open: NihilState.trayOpen; source: "./control/NihilTray.qml" }
    OnDemandPanelLoader { identifier: "nPower"; open: GlobalStates.sessionOpen; source: "./power/NihilPower.qml" }
    OnDemandPanelLoader { identifier: "nMenu"; open: NihilState.menuOpen; source: "./menu/NihilMenu.qml" }
    OnDemandPanelLoader { identifier: "nToday"; open: NihilState.todayOpen; retainAfterUse: true; source: "./today/NihilToday.qml" }
    OnDemandPanelLoader { identifier: "nWallpapers"; open: NihilState.wallpapersOpen; retainAfterUse: true; closeGraceMs: 250; source: "./wallpapers/NihilWallpapers.qml" }
    OnDemandPanelLoader { identifier: "nClipboard"; open: NihilState.clipboardOpen; closeGraceMs: 250; source: "./clipboard/NihilClipboard.qml" }
    DeferredPanelLoader { identifier: "nLock"; component: Lock {} }
    DeferredPanelLoader { identifier: "nPolkit"; component: NihilPolkit {} }

    DeferredPanelLoader { identifier: "iiBootGreeting"; extraCondition: GlobalStates.bootGreetingOpen; component: BootGreeting {} }
    OnDemandPanelLoader { identifier: "iiCheatsheet"; open: GlobalStates.cheatsheetOpen; source: Plugins.baseUrl("modules/shared/cheatsheet/Cheatsheet.qml") }
    OnDemandPanelLoader { identifier: "iiOnScreenKeyboard"; open: GlobalStates.oskOpen; source: Plugins.baseUrl("modules/shared/onScreenKeyboard/OnScreenKeyboard.qml") }
    OnDemandPanelLoader { identifier: "iiOverlay"; open: OverlayContext.wanted ?? (GlobalStates.overlayOpen || OverlayContext.hasPinnedWidgets || OverlayContext.nativeDialogOpen); source: Plugins.baseUrl("modules/shared/overlay/Overlay.qml") }
    OnDemandPanelLoader { identifier: "iiOverview"; open: GlobalStates.overviewOpen; retainAfterUse: true; closeGraceMs: 300; source: Plugins.baseUrl("modules/shared/overview/Overview.qml") }
    DeferredPanelLoader { identifier: "iiRegionSelector"; component: RegionSelector {} }
    OnDemandPanelLoader { identifier: "iiRecordingOsd"; open: RecorderStatus.isRecording; closeGraceMs: 250; source: Plugins.baseUrl("modules/shared/recordingOsd/RecordingOsd.qml") }
    OnDemandPanelLoader { identifier: "iiShellUpdate"; open: ShellUpdates.overlayOpen; closeGraceMs: 250; source: Plugins.baseUrl("modules/shared/shellUpdate/ShellUpdateOverlay.qml") }
    DeferredPanelLoader { identifier: "iiMascotCompanion"; extraCondition: (Config.options?.mascot?.enable ?? false) && (Config.options?.mascot?.companion?.enable ?? true); component: MascotCompanion {} }
}
