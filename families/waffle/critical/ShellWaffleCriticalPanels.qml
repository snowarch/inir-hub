pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.waffle.background as WaffleBackgroundModule
import qs.modules.waffle.bar as WaffleBarModule
import qs.modules.waffle.backdrop as WaffleBackdropModule
import qs.modules.waffle.state

Item {
    id: root

    WaffleVerbs {}

    // Here and not in the deferred panels, so the commands answer from the first frame.
    /// Waffle action center (quick settings).
    IpcHandler {
        target: "wactionCenter"
        /// Open/close action center
        function toggle(): void { WaffleState.actionCenterOpen = !WaffleState.actionCenterOpen }
        /// Close action center
        function close(): void { WaffleState.actionCenterOpen = false }
        /// Open action center
        function open(): void { WaffleState.actionCenterOpen = true }
    }

    /// Waffle notification center.
    IpcHandler {
        target: "wnotificationCenter"
        /// Open/close notification center
        function toggle(): void { WaffleState.notificationCenterOpen = !WaffleState.notificationCenterOpen }
        /// Close notification center
        function close(): void { WaffleState.notificationCenterOpen = false }
        /// Open notification center
        function open(): void { WaffleState.notificationCenterOpen = true }
    }

    /// Waffle widgets panel.
    IpcHandler {
        target: "wwidgets"
        /// Open/close widgets
        function toggle(): void { WaffleState.widgetsOpen = !WaffleState.widgetsOpen }
        /// Close widgets
        function close(): void { WaffleState.widgetsOpen = false }
        /// Open widgets
        function open(): void { WaffleState.widgetsOpen = true }
    }

    component CriticalPanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready
            && (Config.options?.enabledPanels ?? []).includes(identifier)
            && extraCondition
    }

    CriticalPanelLoader {
        identifier: "wBar"
        component: WaffleBarModule.WaffleBar {}
    }

    CriticalPanelLoader {
        identifier: "wBackground"
        component: WaffleBackgroundModule.WaffleBackground {}
    }

    CriticalPanelLoader {
        identifier: "wBackdrop"
        extraCondition: Config.options?.waffles?.background?.backdrop?.enable ?? true
        component: WaffleBackdropModule.WaffleBackdrop {}
    }
}
