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
    readonly property int outerMargin: IrisStyle.island && (root.options?.notch ?? false) ? 0 : Math.max(0, Math.round(Number(root.options?.margin ?? 8) * IrisStyle.density))
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

            component: Scope {
            // Outside clicks on a pinned Island land on this transparent layer.
            // The bar itself never changes anchors: a surface anchored to both
            // opposite edges loses its exclusive zone and every tiled window
            // would resize underneath it.
            // Mapped before the bar and kept mapped with input masked off while
            // idle, so it always stacks below the bar without a layer switch
            // (which would recreate the bar surface mid-expansion).
            PanelWindow {
                screen: windowLoader.modelData
                visible: true
                mask: barWindow.pinned ? dismissAll : dismissNone
                Region { id: dismissNone }
                Region { id: dismissAll; width: 100000; height: 100000 }
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.namespace: "quickshell:iris-bar-dismiss"
                WlrLayershell.layer: WlrLayer.Top
                anchors { left: true; right: true; top: true; bottom: true }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    onPressed: islandLoader.item.expanded = false
                }
            }

            PanelWindow {
                id: barWindow
                readonly property bool expanded: islandLoader.item?.expanded ?? false
                readonly property bool pinned: islandLoader.item?.pinned ?? false
                screen: windowLoader.modelData
                visible: true
                color: "transparent"
                exclusionMode: (root.options?.reserveSpace ?? true) ? ExclusionMode.Normal : ExclusionMode.Ignore
                exclusiveZone: (root.options?.reserveSpace ?? true) ? root.barHeight + root.outerMargin * 2 : 0
                WlrLayershell.namespace: "quickshell:iris-bar"
                // Top layer sits under fullscreen windows; while one covers the
                // output the Island moves to Overlay so its HUD can still appear.
                WlrLayershell.layer: IrisStyle.island && (islandLoader.item?.fullscreenCovered ?? false)
                    ? WlrLayer.Overlay : WlrLayer.Top
                WlrLayershell.keyboardFocus: pinned ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                anchors {
                    left: true
                    right: true
                    top: !root.bottom
                    bottom: root.bottom
                }
                // The Island morphs inside a stable canvas that already fits its
                // expanded size. Resizing the layer surface per animation frame
                // lags the Wayland configure round-trip and visibly clips the
                // chassis to a rectangle mid-morph; input stays limited by mask.
                readonly property real islandCanvasHeight: Math.min(barWindow.screen?.height ?? 1080,
                    Math.max(islandLoader.height + root.outerMargin * 2, Math.round(560 * IrisStyle.density)))
                implicitHeight: IrisStyle.island ? barWindow.islandCanvasHeight : root.barHeight + root.outerMargin * 2
                mask: IrisStyle.island && (islandLoader.item?.suppressed ?? false) ? emptyRegion : contentRegion
                Region { id: emptyRegion }
                Region { id: contentRegion; item: IrisStyle.island ? islandLoader : classicLoader }

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
                    anchors.margins: (root.options?.notch ?? false) ? 0 : root.outerMargin
                    width: item?.implicitWidth ?? 240
                    height: item?.implicitHeight ?? root.barHeight
                    sourceComponent: IrisIsland {
                        id: island
                        targetScreen: barWindow.screen
                        availableWidth: barWindow.width - root.outerMargin * 2
                        compactHeight: root.barHeight
                        screenOffsetY: root.bottom ? (barWindow.screen?.height ?? barWindow.height) - barWindow.height : 0
                        Connections {
                            target: root
                            function onIslandRequested(open: bool): void {
                                if (!open || barWindow.screen?.name === GlobalStates.focusedScreen?.name) {
                                    island.pinned = open
                                    island.expanded = open
                                }
                            }
                        }
                    }
                }
            }
            }
        }
    }
}
