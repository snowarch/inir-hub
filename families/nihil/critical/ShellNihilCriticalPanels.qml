pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.shared.background
import qs.modules.nihil.bar as NihilBarModule
import qs.modules.nihil.state

// NiHiL's first frame: the bar, the desktop (the shared background in NiHiL's faces) and its commands.
Item {
    id: root

    /// NiHiL's panels: `control`, `start`, `power`, `menu`, `tray`.
    ///
    /// ```kdl
    /// Mod+A { spawn "inir" "nihil" "toggle" "control"; }
    /// ```
    IpcHandler {
        target: "nihil"
        /// Open or close one of NiHiL's panels by name (`control`, `start`, `power`, `menu`, `tray`)
        function toggle(panel: string): void { NihilState.toggle(panel) }
        /// Close every NiHiL panel
        function close(): void { NihilState.closeAll() }
    }

    component CriticalPanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready
            && (Config.options?.enabledPanels ?? []).includes(identifier)
            && extraCondition
    }

    CriticalPanelLoader {
        identifier: "nBar"
        component: NihilBarModule.NihilBar {}
    }

    CriticalPanelLoader {
        identifier: "nBackground"
        component: Background { family: "nihil" }
    }
}
