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
import qs.modules.nihil.polkit
import qs.modules.nihil.dock

// What NiHiL loads after the first frame: the dock, Polkit, the lock and the shared tools it wears as they are. The bar and
// its pages live on the sheet (stage/).
Item {
    id: root

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
