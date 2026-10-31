pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.modules.shared.background
import qs.modules.ii.dock
import qs.modules.common

Item {
    id: root

    readonly property bool barVertical: Config.options?.material?.bar?.vertical ?? false
    readonly property bool barPill: (Config.options?.material?.bar?.appearanceStyle ?? "classic") === "pill"
    readonly property bool barM3: (Config.options?.material?.bar?.appearanceStyle ?? "classic") === "m3"
    readonly property bool barStock: !root.barPill && !root.barM3

    component CriticalPanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready
            && (Config.options?.enabledPanels ?? []).includes(identifier)
            && extraCondition
    }

    CriticalPanelLoader { identifier: "iiBackground"; component: Background { family: "ii" } }
    CriticalPanelLoader { identifier: "iiBar"; extraCondition: !root.barVertical && root.barStock; source: "../bar/Bar.qml" }
    CriticalPanelLoader { identifier: "iiBar"; extraCondition: !root.barVertical && root.barPill && !GlobalStates.widgetEditMode; source: "../pill/PillBar.qml" }
    CriticalPanelLoader { identifier: "iiBar"; extraCondition: !root.barVertical && root.barM3 && !GlobalStates.widgetEditMode; source: "../barM3/M3Bar.qml" }
    CriticalPanelLoader { identifier: "iiVerticalBar"; extraCondition: root.barVertical; source: "../verticalBar/VerticalBar.qml" }
    CriticalPanelLoader { identifier: "iiDock"; extraCondition: Config.options?.material?.dock?.enable ?? true; component: Dock {} }
}
