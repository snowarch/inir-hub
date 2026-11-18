pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// NiHiL's bar: no bar at all, only its pieces floating over the wallpaper's edge, in three groups (the desk's own
// keys at the left, Start, search and the apps in the middle, the tray and the status at the right).
Scope {
    id: root

    readonly property var options: Config.options?.nihil?.bar ?? ({})
    readonly property bool bottom: root.options.bottom ?? true
    readonly property bool autoHide: root.options.autoHide ?? false

    Variants {
        model: {
            const screens = Quickshell.screens
            const list = root.options.screenList ?? []
            if (!list || list.length === 0)
                return screens
            const matched = screens.filter(screen => list.includes(screen?.name ?? ""))
            return matched.length > 0 ? matched : screens
        }
        delegate: LazyLoader {
            id: loader
            required property var modelData
            activeAsync: GlobalStates.barOpen

            component: PanelWindow {
                id: window
                screen: loader.modelData
                color: "transparent"
                exclusionMode: root.autoHide ? ExclusionMode.Ignore : ExclusionMode.Normal
                exclusiveZone: root.autoHide ? 0 : NihilStyle.barZone
                implicitHeight: NihilStyle.barZone
                WlrLayershell.namespace: "quickshell:bar"
                WlrLayershell.layer: WlrLayer.Top
                anchors { left: true; right: true; bottom: root.bottom; top: !root.bottom }
                // Only the pieces take the pointer; the wallpaper between them stays the desktop's.
                mask: Region {
                    Region { item: content.tucked ? edgeStrip : content.groupLeft }
                    Region { item: content.tucked ? null : content.groupCenter }
                    Region { item: content.tucked ? null : content.groupRight }
                }

                Item {
                    id: edgeStrip
                    width: parent.width
                    height: 2
                    y: root.bottom ? parent.height - height : 0
                }

                BarContent {
                    id: content
                    anchors.fill: parent
                    screen: window.screen
                    atBottom: root.bottom
                    tucked: root.autoHide && !content.revealed
                    property bool revealed: hover.hovered || NihilState.anyOpen
                    HoverHandler { id: hover }
                }
            }
        }
    }
}
