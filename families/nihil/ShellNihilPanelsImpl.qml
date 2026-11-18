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
import qs.modules.nihil.dock

// NiHiL's panels after the first frame, each loaded while it is open, and the shared tools it wears as they are.
Item {
    id: root

    component PanelLoader: LazyLoader {
        required property string identifier
        active: Config.ready && (Config.options?.enabledPanels ?? []).includes(identifier)
    }

    component DeferredPanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        readonly property bool wanted: Config.ready && (Config.options?.enabledPanels ?? []).includes(identifier) && extraCondition
        loading: wanted && GlobalStates.shellEntryReady
        activeAsync: wanted && GlobalStates.deferredPanelsReady
    }

    component OnDemandPanelLoader: LazyLoader {
        id: onDemandLoader
        required property string identifier
        required property bool open
        property int closeGraceMs: 400
        property bool resident: open
        property Timer closeGrace: Timer {
            interval: onDemandLoader.closeGraceMs
            onTriggered: onDemandLoader.resident = onDemandLoader.open
        }
        readonly property bool enabledPanel: Config.ready && (Config.options?.enabledPanels ?? []).includes(identifier)
        onOpenChanged: {
            if (open) { closeGrace.stop(); resident = true }
            else closeGrace.restart()
        }
        loading: enabledPanel && resident
        activeAsync: enabledPanel && GlobalStates.deferredPanelsReady && resident
    }

    PanelLoader { identifier: "nNotificationPopup"; source: "./notifications/NihilNotificationPopup.qml" }
    PanelLoader { identifier: "nOsd"; source: "./osd/NihilOsd.qml" }

    OnDemandPanelLoader { identifier: "nControl"; open: NihilState.controlOpen; source: "./control/NihilControl.qml" }
    OnDemandPanelLoader { identifier: "nToday"; open: NihilState.todayOpen; source: "./today/NihilToday.qml" }
    OnDemandPanelLoader { identifier: "nPower"; open: GlobalStates.sessionOpen; source: "./power/NihilPower.qml" }
    OnDemandPanelLoader { identifier: "nClipboard"; open: NihilState.clipboardOpen; closeGraceMs: 250; source: "./clipboard/NihilClipboard.qml" }
    OnDemandPanelLoader { identifier: "nWallpapers"; open: NihilState.wallpapersOpen; closeGraceMs: 250; source: "./wallpapers/NihilWallpapers.qml" }
    // The dock answers to its own switch in Settings, so a NiHiL set up before it existed gets it too.
    LazyLoader {
        readonly property bool wanted: Config.ready && (Config.options?.nihil?.modules?.dock ?? true)
        loading: wanted && GlobalStates.shellEntryReady
        activeAsync: wanted && GlobalStates.deferredPanelsReady
        component: NihilDock {}
    }
    DeferredPanelLoader { identifier: "nPolkit"; component: NihilPolkit {} }
    DeferredPanelLoader { identifier: "nLock"; component: Lock {} }

    DeferredPanelLoader { identifier: "iiBootGreeting"; extraCondition: GlobalStates.bootGreetingOpen; component: BootGreeting {} }
    OnDemandPanelLoader { identifier: "iiCheatsheet"; open: GlobalStates.cheatsheetOpen; source: Plugins.baseUrl("modules/shared/cheatsheet/Cheatsheet.qml") }
    OnDemandPanelLoader { identifier: "iiOnScreenKeyboard"; open: GlobalStates.oskOpen; source: Plugins.baseUrl("modules/shared/onScreenKeyboard/OnScreenKeyboard.qml") }
    OnDemandPanelLoader { identifier: "iiOverlay"; open: OverlayContext.wanted ?? (GlobalStates.overlayOpen || OverlayContext.hasPinnedWidgets || OverlayContext.nativeDialogOpen); source: Plugins.baseUrl("modules/shared/overlay/Overlay.qml") }
    DeferredPanelLoader { identifier: "iiRegionSelector"; component: RegionSelector {} }
    OnDemandPanelLoader { identifier: "iiRecordingOsd"; open: RecorderStatus.isRecording; closeGraceMs: 250; source: Plugins.baseUrl("modules/shared/recordingOsd/RecordingOsd.qml") }
    OnDemandPanelLoader { identifier: "iiShellUpdate"; open: ShellUpdates.overlayOpen; closeGraceMs: 250; source: Plugins.baseUrl("modules/shared/shellUpdate/ShellUpdateOverlay.qml") }
    DeferredPanelLoader { identifier: "iiMascotCompanion"; extraCondition: (Config.options?.mascot?.enable ?? false) && (Config.options?.mascot?.companion?.enable ?? true); component: MascotCompanion {} }
}
