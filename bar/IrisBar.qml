pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.iris.style

Scope {
    id: root

    readonly property var options: Config.options?.iris?.bar ?? ({})
    readonly property bool bottom: String(root.options?.position ?? "top") === "bottom"
    readonly property int barHeight: Math.max(32, Math.round(Number(root.options?.height ?? 42) * IrisStyle.density))
    readonly property int outerMargin: (root.options?.notch ?? false) ? 0 : Math.max(0, Math.round(Number(root.options?.margin ?? 8) * IrisStyle.density))
    signal islandRequested(bool expanded, string page)

    IpcHandler {
        target: "iris"
        function open(): void { GlobalStates.barOpen = true; root.islandRequested(true, "") }
        function page(name: string): void {
            if (name !== "media" && name !== "activity" && name !== "desktop" && name !== "tray" && name !== "tools") return
            GlobalStates.barOpen = true
            root.islandRequested(true, name)
        }
        function close(): void { root.islandRequested(false, "") }
        function toggle(): void {
            if (GlobalStates.irisIslandExpanded) root.islandRequested(false, "")
            else { GlobalStates.barOpen = true; root.islandRequested(true, "") }
        }
        function card(action: string): void {
            if (action === "pin") {
                Config.setNestedValue("iris.player.cardPinned", !(Config.options?.iris?.player?.cardPinned ?? false))
                return
            }
            GlobalStates.irisMediaCardOpen = action === "open" ? true : action === "close" ? false : !GlobalStates.irisMediaCardOpen
        }
        // Open iRiS Settings on a section (bar, player, bubbles, dock, appearance,
        // desktop, sidebars, surfaces, system).
        function settings(section: string): void { GlobalStates.openSettingsPage(28, section) }
        // Place a bubble: an Island slot (`left`, `right`, `utility`) or an extra
        // bubble (`weather`, `notifications`, `controls`, `sound`, `mic`, `tools`,
        // `media`, `tray`) at `island` (slots) / `off` (extras), a zone (`top-left`,
        // `top-right`, `left`, `right`, `bottom-left`, `bottom-right`) or `x,y`
        // as fractions of the output.
        function bubble(slot: string, place: string): string {
            const extras = ["weather", "notifications", "controls", "sound", "mic", "tools", "media", "tray"]
            const extra = extras.includes(slot)
            if (!extra && !["left", "right", "utility"].includes(slot)) return "Unknown bubble"
            const zones = ["top-left", "top-right", "left", "right", "bottom-left", "bottom-right"]
            const path = extra ? "iris.bubbles.extras." + slot : "iris.bubbles." + slot
            const updates = {}
            if ((extra && place === "off") || (!extra && place === "island")) {
                updates[path + (extra ? ".enable" : ".place")] = extra ? false : "island"
            } else if (zones.includes(place)) {
                updates[path + ".place"] = place
            } else {
                const m = String(place).match(/^(\d*\.?\d+),(\d*\.?\d+)$/)
                if (!m) return "Unknown place: a zone, x,y fractions, or island/off"
                updates[path + ".fx"] = Math.min(1, Number(m[1]))
                updates[path + ".fy"] = Math.min(1, Number(m[2]))
                updates[path + ".place"] = "free"
            }
            if (extra && place !== "off") updates[path + ".enable"] = true
            Config.setNestedValues(updates)
            return place
        }
        function dock(action: string): void {
            GlobalStates.irisDockShown = action === "reveal" ? true : action === "hide" ? false : !GlobalStates.irisDockShown
        }
        function pin(side: string): void {
            if (side !== "left" && side !== "right") return
            const path = "iris.sidebars." + side + ".pinned"
            Config.setNestedValue(path, !(Config.getNestedValue(path, false)))
        }
        function accent(name: string): string {
            if (!["blue", "mint", "rose", "lilac", "wallpaper"].includes(name)) return "Unknown accent"
            Config.setNestedValue("iris.appearance.accent", name)
            return String(Config.options.iris.appearance.accent)
        }
        function utility(name: string): string {
            if (!["tray", "tools", "sound", "mic", "none"].includes(name)) return "Unknown utility"
            Config.setNestedValue("iris.bar.auxiliary", name)
            return String(Config.options.iris.bar.auxiliary)
        }
        function status(): string {
            return JSON.stringify({
                islandExpanded: GlobalStates.irisIslandExpanded,
                accent: Config.options?.iris?.appearance?.accent ?? "blue",
                utility: Config.options?.iris?.bar?.auxiliary ?? "tray",
                trayItems: SystemTray.items.values.length,
                dockShown: GlobalStates.irisDockShown,
                controlCenter: GlobalStates.controlPanelOpen,
                spotlight: GlobalStates.searchOpen,
                focus: { open: GlobalStates.sidebarLeftOpen, pinned: Config.options?.iris?.sidebars?.left?.pinned ?? false },
                today: { open: GlobalStates.sidebarRightOpen, pinned: Config.options?.iris?.sidebars?.right?.pinned ?? false }
            })
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
            // Anchors never flip on a live surface (the chassis was left floating
            // mid-screen with stale geometry): tear the bar down and map it again
            // on the new edge in a later turn, like the Dock.
            property bool loadedBottom: false
            Component.onCompleted: windowLoader.loadedBottom = root.bottom
            property bool recycling: false
            readonly property bool requestedBottom: root.bottom
            onRequestedBottomChanged: {
                windowLoader.recycling = true
                Qt.callLater(() => {
                    windowLoader.loadedBottom = windowLoader.requestedBottom
                    windowLoader.recycling = false
                })
            }
            activeAsync: GlobalStates.barOpen && !windowLoader.recycling

            component: Scope {
            // Outside clicks on a pinned Island land on this transparent layer.
            // The bar itself never changes anchors: a surface anchored to both
            // opposite edges loses its exclusive zone and every tiled window
            // would resize underneath it.
            // Mapped before the bar and kept mapped with input masked off while
            // idle, so it always stacks below the bar without a layer switch
            // (which would recreate the bar surface mid-expansion).
            PanelWindow {
                id: dismissWindow
                screen: windowLoader.modelData
                visible: true
                Item { id: dismissNoneItem; width: 0; height: 0 }
                mask: barWindow.pinned ? dismissAll : dismissNone
                Region { id: dismissNone; item: dismissNoneItem }
                // Mapping order is not a stacking guarantee (niri has been seen to
                // map this layer above the bar), so the Island is cut out of the
                // catch-all: pointer and hover over it always reach the Island.
                Region {
                    id: dismissAll
                    Region { width: 100000; height: 100000 }
                    Region {
                        intersection: Intersection.Subtract
                        x: islandInput.x
                        y: islandInput.y + (windowLoader.loadedBottom ? dismissWindow.height - barWindow.height : 0)
                        width: islandInput.width
                        height: islandInput.height
                    }
                }
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
                // Top layer sits under fullscreen windows; the Island moves to
                // Overlay only while it presents something over one (HUD or an
                // explicit open). A resting, invisible canvas mapped above a
                // fullscreen game still forces Niri to composite every frame.
                WlrLayershell.layer: (islandLoader.item?.fullscreenCovered ?? false)
                    && !(islandLoader.item?.suppressed ?? true)
                    ? WlrLayer.Overlay : WlrLayer.Top
                WlrLayershell.keyboardFocus: pinned ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                anchors {
                    left: true
                    right: true
                    top: !windowLoader.loadedBottom
                    bottom: windowLoader.loadedBottom
                }
                // The Island morphs inside a stable canvas that already fits its
                // expanded size. Resizing the layer surface per animation frame
                // lags the Wayland configure round-trip and visibly clips the
                // chassis to a rectangle mid-morph; input stays limited by mask.
                readonly property real islandCanvasHeight: Math.min(barWindow.screen?.height ?? 1080,
                    Math.max(islandLoader.height + root.outerMargin * 2, Math.round(560 * IrisStyle.density)))
                implicitHeight: barWindow.islandCanvasHeight
                mask: (islandLoader.item?.suppressed ?? false) ? emptyRegion : contentRegion
                Region { id: emptyRegion }
                Region { id: contentRegion; item: islandInput }
                // Input is the Island's shape, now or becoming, plus whatever it
                // covered while the pointer rested on it: a resize away from a
                // still pointer must not read as leaving (Wayland sends leave and
                // nothing re-enters until the pointer moves). The next real motion
                // drops the held area, and only then does leaving count.
                Item {
                    id: islandInput
                    readonly property real liveWidth: Math.max(islandLoader.width, islandLoader.item?.inputWidth ?? 0)
                    readonly property real liveHeight: Math.max(islandLoader.height, islandLoader.item?.inputHeight ?? 0)
                    property real heldWidth: 0
                    property real heldHeight: 0
                    readonly property bool holding: canvasHover.hovered
                        && (heldWidth > liveWidth + 1 || heldHeight > liveHeight + 1)
                    function release(): void { heldWidth = liveWidth; heldHeight = liveHeight }
                    onLiveWidthChanged: heldWidth = canvasHover.hovered ? Math.max(heldWidth, liveWidth) : liveWidth
                    onLiveHeightChanged: heldHeight = canvasHover.hovered ? Math.max(heldHeight, liveHeight) : liveHeight
                    width: Math.max(liveWidth, heldWidth)
                    height: Math.max(liveHeight, heldHeight)
                    x: islandLoader.x + (islandLoader.width - width) / 2
                    y: windowLoader.loadedBottom ? islandLoader.y + islandLoader.height - height : islandLoader.y
                }
                HoverHandler {
                    id: canvasHover
                    property point last: Qt.point(-1, -1)
                    onHoveredChanged: if (!hovered) islandInput.release()
                    // Items moving under a still pointer re-deliver the same point;
                    // only a real move releases the held area.
                    onPointChanged: {
                        const p = point.position
                        if (Math.abs(p.x - last.x) + Math.abs(p.y - last.y) > 2) {
                            last = p
                            islandInput.release()
                        }
                    }
                }

                Shortcut {
                    sequence: "Escape"
                    enabled: barWindow.expanded
                    onActivated: islandLoader.item.expanded = false
                }

                Loader {
                    id: islandLoader
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: windowLoader.loadedBottom ? undefined : parent.top
                    anchors.bottom: windowLoader.loadedBottom ? parent.bottom : undefined
                    anchors.margins: (root.options?.notch ?? false) ? 0 : root.outerMargin
                    width: item?.implicitWidth ?? 240
                    height: item?.implicitHeight ?? root.barHeight
                    sourceComponent: IrisIsland {
                        id: island
                        targetScreen: barWindow.screen
                        pointerHeld: islandInput.holding
                        availableWidth: barWindow.width - root.outerMargin * 2
                        compactHeight: root.barHeight
                        bottomEdge: windowLoader.loadedBottom
                        screenOffsetY: windowLoader.loadedBottom ? (barWindow.screen?.height ?? barWindow.height) - barWindow.height : 0
                        Connections {
                            target: root
                            function onIslandRequested(open: bool, page: string): void {
                                if (!open || barWindow.screen?.name === GlobalStates.focusedScreen?.name) {
                                    if (open) island.page = page
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
