pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.shared.background
import qs.modules.nihil.stage as NihilStageModule
import qs.modules.nihil.overview as NihilOverviewModule
import qs.modules.nihil.state

// NiHiL's first frame: the bar and the dashboard, the desktop, the overview and its commands.
Item {
    id: root

    NihilVerbs {}

    /// NiHiL's surfaces: `overview`, `search`, the dashboard's pages (`apps`, `control`, `today`, `media`, `focus`,
    /// `clipboard`, `wallpapers`), `dashboard` (the last page) and `power`.
    ///
    /// ```kdl
    /// Mod+A { spawn "inir" "nihil" "toggle" "apps"; }
    /// ```
    IpcHandler {
        target: "nihil"
        /// Open or close one of NiHiL's surfaces by name (`overview`, `search`, `apps`, `control`, `today`, `media`, `focus`, `clipboard`, `wallpapers`, `dashboard`, `power`)
        function toggle(panel: string): void { NihilState.toggle(panel) }
        /// Close every NiHiL surface
        function close(): void { NihilState.closeAll() }
        /// The overview key: one press and two quick presses do what Settings says
        function superKey(): void { NihilState.pressSuper() }
        /// Apply a desktop profile (`vertical`, `horizontal`, `corner`, `dock`)
        function profile(id: string): void { NihilState.applyProfile(id) }
    }

    component CriticalPanelLoader: LazyLoader {
        required property string identifier
        active: Config.ready && (Config.options?.enabledPanels ?? []).includes(identifier)
    }

    // The stage carries the bar and the dashboard with every page, so it stands whichever of them are switched on.
    LazyLoader {
        active: Config.ready
        component: NihilStageModule.NihilStage {}
    }
    CriticalPanelLoader {
        identifier: "nBackground"
        component: Background { family: "nihil" }
    }
    CriticalPanelLoader {
        identifier: "nOverview"
        component: NihilOverviewModule.NihilOverview {}
    }
}
