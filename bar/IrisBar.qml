pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.iris.style

Scope {
    id: root

    readonly property var options: Config.options?.iris?.bar ?? ({})
    readonly property bool bottom: String(root.options?.position ?? "top") === "bottom"
    readonly property int barHeight: Math.max(32, Math.round(Number(root.options?.height ?? 42) * IrisStyle.density))
    readonly property int outerMargin: Math.max(0, Math.round(Number(root.options?.margin ?? 8) * IrisStyle.density))
    signal islandRequested(bool expanded)

    IpcHandler {
        target: "iris"
        function open(): void { GlobalStates.barOpen = true; root.islandRequested(true) }
        function close(): void { root.islandRequested(false) }
        function design(name: string): void {
            if (name === "classic" || name === "island") Config.setNestedValue("iris.appearance.design", name)
        }
    }

    Variants {
        model: {
            const screens = Quickshell.screens
            const list = root.options?.screenList ?? []
            if (!list || list.length === 0) return screens
            const matched = screens.filter(screen => list.includes(screen?.name ?? ""))
            return matched.length > 0 ? matched : screens
        }

        delegate: LazyLoader {
            id: windowLoader
            required property var modelData
            activeAsync: GlobalStates.barOpen

            component: PanelWindow {
                id: barWindow
                readonly property bool expanded: islandLoader.item?.expanded ?? false
                screen: windowLoader.modelData
                visible: true
                color: "transparent"
                exclusionMode: (root.options?.reserveSpace ?? true) ? ExclusionMode.Normal : ExclusionMode.Ignore
                exclusiveZone: (root.options?.reserveSpace ?? true) ? root.barHeight + root.outerMargin * 2 : 0
                WlrLayershell.namespace: "quickshell:iris-bar"
                WlrLayershell.keyboardFocus: expanded ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                anchors {
                    left: true
                    right: true
                    top: !root.bottom || barWindow.expanded
                    bottom: root.bottom || barWindow.expanded
                }
                implicitHeight: IrisStyle.island ? islandLoader.height + root.outerMargin * 2 : root.barHeight + root.outerMargin * 2
                mask: barWindow.expanded ? outsideRegion : contentRegion
                Region { id: outsideRegion; width: barWindow.width; height: barWindow.height }
                Region { id: contentRegion; item: IrisStyle.island ? islandLoader : classicLoader }

                MouseArea {
                    anchors.fill: parent
                    visible: barWindow.expanded
                    onClicked: islandLoader.item.expanded = false
                }
                Shortcut {
                    sequence: "Escape"
                    enabled: barWindow.expanded
                    onActivated: islandLoader.item.expanded = false
                }

                Loader {
                    id: classicLoader
                    active: !IrisStyle.island
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: root.bottom ? undefined : parent.top
                    anchors.bottom: root.bottom ? parent.bottom : undefined
                    anchors.leftMargin: root.outerMargin
                    anchors.rightMargin: root.outerMargin
                    anchors.topMargin: root.bottom ? 0 : root.outerMargin
                    anchors.bottomMargin: root.bottom ? root.outerMargin : 0
                    height: root.barHeight
                    sourceComponent: IrisBarContent { targetScreen: barWindow.screen }
                }

                Loader {
                    id: islandLoader
                    active: IrisStyle.island
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: root.bottom ? undefined : parent.top
                    anchors.bottom: root.bottom ? parent.bottom : undefined
                    anchors.margins: root.outerMargin
                    width: item?.implicitWidth ?? 240
                    height: item?.implicitHeight ?? root.barHeight
                    sourceComponent: IrisIsland {
                        id: island
                        targetScreen: barWindow.screen
                        availableWidth: barWindow.width - root.outerMargin * 2
                        compactHeight: root.barHeight
                        Connections {
                            target: root
                            function onIslandRequested(open: bool): void {
                                if (!open || barWindow.screen?.name === GlobalStates.focusedScreen?.name)
                                    island.expanded = open
                            }
                        }
                    }
                }
            }
        }
    }
}
