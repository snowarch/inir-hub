pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// New notifications stacked in the chosen corner; only the stack itself takes the pointer.
Scope {
    id: root

    readonly property string position: Config.options?.nihil?.notifications?.position ?? "top"
    readonly property int most: Config.options?.nihil?.notifications?.maxVisible ?? 4
    readonly property bool atTop: root.position.startsWith("top")
    readonly property bool atLeft: root.position.endsWith("Left")
    readonly property bool atRight: root.position.endsWith("Right")

    Component.onCompleted: Notifications.ensureInitialized()

    LazyLoader {
        active: Notifications.popupList.length > 0
        component: PanelWindow {
            id: window

            screen: GlobalStates.focusedScreen ?? Quickshell.screens[0]
            visible: !GlobalStates.screenLocked && !(GameMode.active && GameMode.suppressNotifications)
            color: "transparent"
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:nihilNotifications"
            WlrLayershell.layer: WlrLayer.Overlay
            anchors { top: root.atTop; bottom: !root.atTop; right: root.atRight; left: root.atLeft }
            margins {
                top: root.atTop ? NihilStyle.edge : 0
                bottom: root.atTop ? 0 : NihilStyle.edge
                right: root.atRight ? NihilStyle.edge : 0
                left: root.atLeft ? NihilStyle.edge : 0
            }
            implicitWidth: NihilStyle.s(380)
            implicitHeight: Math.min(stack.implicitHeight, (screen?.height ?? 800) * 0.7)
            mask: Region { item: stack }
            BackgroundEffect.blurRegion: CompositorService.blurRegions && NihilStyle.blur ? glassZone : null

            Region {
                id: glassZone
                regions: stack.children.filter(card => card.region !== undefined).map(card => card.region)
            }

            Column {
                id: stack
                width: parent.width
                spacing: NihilStyle.gap

                Repeater {
                    model: Notifications.popupList.slice(0, root.most)
                    delegate: NotificationCard {
                        required property var modelData
                        width: stack.width
                        notification: modelData
                    }
                }
            }
        }
    }
}
