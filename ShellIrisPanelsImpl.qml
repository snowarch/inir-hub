pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.palette
import qs.modules.iris.control
import qs.modules.iris.notificationPopup
import qs.modules.iris.onScreenDisplay
import qs.modules.iris.session
import qs.modules.iris.polkit
import qs.modules.iris.style
import qs.modules.iris.dock
import qs.modules.background
import qs.modules.lock

Item {
    id: root

    component PanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        readonly property bool enabledPanel: Config.ready
            && (Config.options?.enabledPanels ?? []).includes(identifier)
            && extraCondition
        loading: enabledPanel
        activeAsync: enabledPanel
    }

    component DeferredPanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        readonly property bool enabledPanel: Config.ready
            && (Config.options?.enabledPanels ?? []).includes(identifier)
            && extraCondition
        loading: enabledPanel && GlobalStates.shellEntryReady
        activeAsync: enabledPanel && GlobalStates.deferredPanelsReady
    }

    component OnDemandPanelLoader: LazyLoader {
        id: loader
        required property string identifier
        required property bool open
        property bool extraCondition: true
        property bool requireEnabledPanel: true
        property int closeGraceMs: 140
        property bool resident: open
        property Timer closeGrace: Timer {
            interval: loader.closeGraceMs
            onTriggered: loader.resident = loader.open
        }
        readonly property bool enabledPanel: Config.ready
            && (!requireEnabledPanel || (Config.options?.enabledPanels ?? []).includes(identifier))
            && extraCondition

        onOpenChanged: {
            if (open) {
                closeGrace.stop()
                resident = true
            } else {
                closeGrace.restart()
            }
        }

        loading: enabledPanel && resident
        activeAsync: enabledPanel && GlobalStates.deferredPanelsReady && resident
    }

    OnDemandPanelLoader {
        identifier: "irisNotificationPopup"
        open: (Notifications.popupList?.length ?? 0) > 0
        extraCondition: Config.options?.iris?.modules?.notificationPopup ?? true
        component: IrisNotificationPopup {}
    }

    LazyLoader {
        activeAsync: Config.ready && GlobalStates.deferredPanelsReady
            && (Config.options?.iris?.dock?.enable ?? true)
        component: IrisDock {}
    }

    LazyLoader {
        activeAsync: Config.ready && GlobalStates.deferredPanelsReady
            && (Config.options?.enabledPanels ?? []).includes("irisBackground")
            && (Config.options?.iris?.modules?.desktopWidgets ?? true)
        component: Background {}
    }

    PanelLoader {
        identifier: "irisOnScreenDisplay"
        extraCondition: (Config.options?.iris?.modules?.osd ?? true)
            && (!IrisStyle.island || !GlobalStates.barOpen
                || !(Config.options?.enabledPanels ?? []).includes("irisBar")
                || ((Config.options?.iris?.bar?.screenList ?? []).length > 0
                    && !(Config.options.iris.bar.screenList).includes(GlobalStates.focusedScreen?.name ?? "")))
        component: IrisOSD {}
    }

    OnDemandPanelLoader {
        identifier: "irisPalette"
        open: GlobalStates.searchOpen
        extraCondition: Config.options?.iris?.modules?.palette ?? true
        component: IrisPalette {}
    }

    OnDemandPanelLoader {
        identifier: "irisControlCenter"
        open: GlobalStates.controlPanelOpen
        extraCondition: Config.options?.iris?.modules?.controlCenter ?? true
        component: IrisControlCenter {}
    }

    OnDemandPanelLoader {
        identifier: "irisSessionScreen"
        open: GlobalStates.sessionOpen
        extraCondition: Config.options?.iris?.modules?.sessionScreen ?? true
        component: IrisSessionScreen {}
    }

    DeferredPanelLoader {
        identifier: "irisLock"
        extraCondition: Config.options?.iris?.modules?.lock ?? true
        component: Lock {}
    }

    DeferredPanelLoader {
        identifier: "irisPolkit"
        extraCondition: Config.options?.iris?.modules?.polkit ?? true
        component: IrisPolkit {}
    }

    OnDemandPanelLoader {
        identifier: "irisCheatsheet"
        open: GlobalStates.cheatsheetOpen
        requireEnabledPanel: false
        source: "../cheatsheet/Cheatsheet.qml"
    }

    OnDemandPanelLoader {
        identifier: "irisOnScreenKeyboard"
        open: GlobalStates.oskOpen
        requireEnabledPanel: false
        source: "../onScreenKeyboard/OnScreenKeyboard.qml"
    }

    OnDemandPanelLoader {
        identifier: "irisRegionSelector"
        open: GlobalStates.regionSelectorOpen
        requireEnabledPanel: false
        source: "../regionSelector/RegionSelector.qml"
    }

    OnDemandPanelLoader {
        identifier: "irisWallpaperSelector"
        open: GlobalStates.wallpaperSelectorOpen
        requireEnabledPanel: false
        source: "../wallpaperSelector/WallpaperSelector.qml"
    }

    OnDemandPanelLoader {
        identifier: "irisWallpaperLauncher"
        open: GlobalStates.wallpaperLauncherOpen
        requireEnabledPanel: false
        source: "../wallpaperLauncher/WallpaperLauncher.qml"
    }

    OnDemandPanelLoader {
        identifier: "irisCoverflowSelector"
        open: GlobalStates.coverflowSelectorOpen
        requireEnabledPanel: false
        source: "../wallpaperSelector/WallpaperCoverflow.qml"
    }

    OnDemandPanelLoader {
        identifier: "irisRecordingOsd"
        open: RecorderStatus.isRecording
        requireEnabledPanel: false
        source: "../recordingOsd/RecordingOsd.qml"
    }

    OnDemandPanelLoader {
        identifier: "irisTilingOverlay"
        open: GlobalStates.tilingOverlayPickerOpen || GlobalStates.tilingOverlayOsdOpen
        requireEnabledPanel: false
        source: "../tilingOverlay/TilingOverlay.qml"
    }
}
