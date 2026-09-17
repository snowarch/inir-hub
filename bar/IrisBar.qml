pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.iris.control
import qs.modules.iris.field
import qs.modules.iris.frame
import qs.modules.iris.stage
import qs.modules.iris.notificationPopup
import qs.modules.iris.style
import qs.modules.iris.components as IrisParts
import qs.modules.iris.pieces

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
            const open = GlobalStates.irisBubbleCard?.kind === "media"
            if (action === "close" || (open && action !== "open")) { GlobalStates.irisBubbleCard = null; return }
            if (open) return
            GlobalStates.irisBubbleCardRequest = ""
            GlobalStates.irisBubbleCardRequest = "media"
        }
        function settings(section: string): void { GlobalStates.openSettingsPage(28, section) }
        function bubble(slot: string, place: string): string {
            const extra = IrisPieces.extraIds.includes(slot)
            if (!extra && !IrisPieces.slotIds.includes(slot)) return "Unknown bubble"
            const zones = IrisPieces.zones
            const path = IrisPieces.configPath(slot)
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
        function dockApp(appId: string, mode: string): string {
            if (mode === "close") { GlobalStates.irisDockMenuRequest = { appId: "", mode: "close" }; GlobalStates.irisDockShown = false; return "closed" }
            if (mode !== "windows" && mode !== "menu") return "Unknown mode: windows, menu or close"
            GlobalStates.irisDockMenuRequest = { appId: appId, mode: mode }
            return appId
        }
        function appBubble(appId: string, place: string): string {
            if (appId.length === 0) return "Unknown app"
            if (place === "dock" || place === "off") { IrisPieces.removeApp(appId); return "docked" }
            if (IrisPieces.zones.includes(place)) { IrisPieces.placeApp(appId, place, 0.5, 0.5); return place }
            const m = String(place).match(/^(\d*\.?\d+),(\d*\.?\d+)$/)
            if (!m) return "Unknown place: a zone, x,y fractions, or dock"
            IrisPieces.placeApp(appId, "free", Math.min(1, Number(m[1])), Math.min(1, Number(m[2])))
            return place
        }
        function pin(side: string): void {
            if (side !== "left" && side !== "right") return
            const path = "iris.sidebars." + side + ".pinned"
            Config.setNestedValue(path, !(Config.getNestedValue(path, false)))
        }
        function layout(name: string): string {
            if (!["island", "left", "right", "full"].includes(name)) return "Unknown layout: island, left, right or full"
            Config.setNestedValue("iris.bar.layout", name)
            return name
        }
        function barPiece(kind: string, action: string): string {
            if (!IrisPieces.extraIds.includes(kind)) return "Unknown piece"
            const current = Array.from(Config.options?.iris?.bar?.pieces ?? [])
            const on = current.includes(kind)
            const wanted = action === "on" ? true : action === "off" ? false : !on
            if (wanted === on) return on ? "on" : "off"
            const next = current.filter(entry => entry !== kind)
            if (wanted) next.push(kind)
            Config.setNestedValue("iris.bar.pieces", next)
            return wanted ? "on" : "off"
        }
        function arrange(action: string): string {
            const wanted = action === "on" ? true : action === "off" ? false : !GlobalStates.irisArrange
            if (wanted) GlobalStates.irisIslandPageRequest = "desktop"
            GlobalStates.irisArrange = wanted
            return wanted ? "on" : "off"
        }
        function studio(action: string): string {
            if (!["on", "off", "toggle"].includes(action)) {
                GlobalStates.irisStudioTarget = action
                GlobalStates.irisStudioOpen = true
                return action
            }
            const wanted = action === "on" ? true : action === "off" ? false : !GlobalStates.irisStudioOpen
            GlobalStates.irisStudioOpen = wanted
            return wanted ? "on" : "off"
        }
        function notch(action: string): string {
            const on = Config.options?.iris?.bar?.notch ?? false
            const wanted = action === "on" ? true : action === "off" ? false : !on
            Config.setNestedValue("iris.bar.notch", wanted)
            return wanted ? "on" : "off"
        }
        function surround(action: string): string {
            const on = Config.options?.iris?.surround?.enable ?? false
            const wanted = action === "on" ? true : action === "off" ? false : !on
            Config.setNestedValue("iris.surround.enable", wanted)
            return wanted ? "on" : "off"
        }
        function accent(name: string): string {
            if (!["blue", "mint", "rose", "lilac", "wallpaper"].includes(name)) return "Unknown accent"
            Config.setNestedValue("iris.appearance.accent", name)
            return String(Config.options.iris.appearance.accent)
        }
        function spotlight(query: string): void {
            GlobalStates.irisSpotlightQuery = query
            GlobalStates.searchOpen = true
        }
        function bubbleCard(kind: string): string {
            if (kind === "close") { GlobalStates.irisBubbleCard = null; return "closed" }
            if (!IrisPieces.cardIds.includes(kind)) return "Unknown card"
            GlobalStates.irisBubbleCardRequest = ""
            GlobalStates.irisBubbleCardRequest = kind
            return kind
        }
        function bubbleMenu(kind: string): string {
            if (kind.length === 0) return "Which bubble?"
            GlobalStates.irisBubbleMenuRequest = ""
            GlobalStates.irisBubbleMenuRequest = kind
            return kind
        }
        function morph(name: string): string {
            if (!Object.keys(IrisStyle.morphStyles).includes(name)) return "Unknown morph style"
            Config.setNestedValue("iris.appearance.morph", name)
            return name
        }
        function preset(name: string): string {
            if (!Object.keys(IrisStyle.presets).includes(name)) return "Unknown preset"
            Config.setNestedValue("iris.appearance.preset", name)
            return String(Config.options.iris.appearance.preset)
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
                preset: IrisStyle.presetName,
                bubbleCard: GlobalStates.irisBubbleCard?.kind ?? "",
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

    function islandAllowed(screen: var): bool {
        const list = root.options?.screenList ?? []
        if (!list || list.length === 0) return true
        const matched = Quickshell.screens.filter(s => list.includes(s?.name ?? ""))
        return matched.length === 0 || list.includes(screen?.name ?? "")
    }

    Variants {
        model: Quickshell.screens

        delegate: LazyLoader {
            id: windowLoader
            required property var modelData
            property bool loadedBottom: false
            Component.onCompleted: windowLoader.loadedBottom = root.bottom
            property bool recycling: false
            readonly property bool requestedBottom: root.bottom
            onRequestedBottomChanged: windowLoader.recycle()
            // Rebuilt on shape changes: a ClippingRectangle does not re-mask when its corner structure changes.
            readonly property string shapeKey: String(Config.options?.iris?.surround?.enable ?? false)
                + "|" + String(Config.options?.iris?.bar?.notch ?? false)
                + "|" + String(Config.options?.iris?.bar?.layout ?? "island")
            onShapeKeyChanged: windowLoader.recycle()
            function recycle(): void {
                windowLoader.recycling = true
                Qt.callLater(() => {
                    windowLoader.loadedBottom = windowLoader.requestedBottom
                    windowLoader.recycling = false
                })
            }
            activeAsync: !windowLoader.recycling

            component: Scope {
            PanelWindow {
                id: barWindow
                readonly property bool expanded: islandLoader.item?.expanded ?? false
                readonly property bool pinned: islandLoader.item?.pinned ?? false
                screen: windowLoader.modelData
                visible: true
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: 0
                WlrLayershell.namespace: "quickshell:iris-chassis"
                readonly property bool presenting: !barWindow.suppressed
                    && (barWindow.pinned || stage.cardPresent || (controlCentreLoader.item?.present ?? false))
                WlrLayershell.layer: (islandLoader.item?.fullscreenCovered ?? false)
                    && (barWindow.presenting || !(islandLoader.item?.suppressed ?? true))
                    ? WlrLayer.Overlay : WlrLayer.Top
                WlrLayershell.keyboardFocus: barWindow.pinned || stage.cardOpen || (controlCentreLoader.item?.morphOpen ?? false)
                    ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                anchors { left: true; right: true; top: true; bottom: true }
                readonly property bool suppressed: islandLoader.active
                    ? (islandLoader.item?.suppressed ?? false) : false
                mask: barWindow.suppressed ? emptyRegion
                    : barWindow.pinned || stage.cardArmed || (controlCentreLoader.item?.armed ?? false)
                        ? (GlobalStates.irisStudioRect ? chassisStudioMask : null) : chassisRegion
                Region { id: emptyRegion }
                IrisParts.IrisStudioMask {
                    id: chassisStudioMask
                    canvasWidth: barWindow.width
                    canvasHeight: barWindow.height
                    screenName: barWindow.screen?.name ?? ""
                }
                component PieceRegion: Region {
                    required property int index
                    readonly property var rect: stage.hitRects[index] ?? null
                    x: rect ? rect.x : 0
                    y: rect ? rect.y : 0
                    width: rect ? rect.width : 0
                    height: rect ? rect.height : 0
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: barWindow.pinned
                    acceptedButtons: Qt.AllButtons
                    onPressed: islandLoader.item.expanded = false
                }
                Region {
                    id: chassisRegion
                    item: islandInput
                    Region { item: extensionInput }
                    Region {
                        readonly property var panel: (controlCentreLoader.item?.present ?? false)
                            ? controlCentreLoader.item.body : null
                        x: panel ? controlCentreLoader.x + panel.x : 0
                        y: panel ? controlCentreLoader.y + panel.y : 0
                        width: panel ? panel.width : 0
                        height: panel ? panel.height : 0
                    }
                    Region {
                        x: banners.hitRect?.x ?? 0
                        y: banners.hitRect?.y ?? 0
                        width: banners.hitRect?.width ?? 0
                        height: banners.hitRect?.height ?? 0
                    }
                    PieceRegion { index: 0 }
                    PieceRegion { index: 1 }
                    PieceRegion { index: 2 }
                    PieceRegion { index: 3 }
                    PieceRegion { index: 4 }
                    PieceRegion { index: 5 }
                    PieceRegion { index: 6 }
                    PieceRegion { index: 7 }
                    PieceRegion { index: 8 }
                    PieceRegion { index: 9 }
                    PieceRegion { index: 10 }
                    PieceRegion { index: 11 }
                    PieceRegion { index: 12 }
                    PieceRegion { index: 13 }
                    PieceRegion { index: 14 }
                    PieceRegion { index: 15 }
                    PieceRegion { index: 16 }
                    PieceRegion { index: 17 }
                    PieceRegion { index: 18 }
                    PieceRegion { index: 19 }
                    PieceRegion { index: 20 }
                    PieceRegion { index: 21 }
                    PieceRegion { index: 22 }
                    PieceRegion { index: 23 }
                }
                // Keep the area under a still pointer: Wayland sends no re-enter after a resize.
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
                Item {
                    id: extensionInput
                    readonly property rect area: islandLoader.item?.extensionArea ?? Qt.rect(0, 0, 0, 0)
                    x: islandLoader.x + extensionInput.area.x
                    y: islandLoader.y + extensionInput.area.y
                    width: extensionInput.area.width
                    height: extensionInput.area.height
                }
                HoverHandler {
                    id: canvasHover
                    property point last: Qt.point(-1, -1)
                    onHoveredChanged: if (!hovered) islandInput.release()
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

                readonly property var fieldShapes: {
                    const hung = (controlCentreLoader.item?.fieldShapes ?? [])
                        .concat(stage.fieldShapes)
                    const bodies = hung.filter(shape => shape.joins === "island")
                    const island = (islandLoader.item?.fieldShapes ?? []).map(shape => {
                        if (!shape.satellite) return shape
                        const reach = IrisStyle.fuse
                        const body = bodies.find(b => shape.x < b.x + b.width + reach && shape.x + shape.width > b.x - reach
                            && shape.y < b.y + b.height + reach && shape.y + shape.height > b.y - reach)
                        return body ? Object.assign({}, shape, { joins: [body.id].concat(Array.isArray(shape.joins) ? shape.joins.slice(1) : []), fuse: IrisStyle.fuse }) : shape
                    })
                    const all = island.concat(hung)
                    if (all.length <= chassisField.capacity) return all
                    return all.filter(shape => !shape.paints)
                        .concat(all.filter(shape => shape.paints))
                        .slice(0, chassisField.capacity)
                }

                IrisField {
                    id: chassisField
                    anchors.fill: parent
                    shapes: barWindow.fieldShapes
                    opacity: (islandLoader.item?.fullscreenCovered ?? false) ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
                }

                Loader {
                    id: islandLoader
                    z: 3
                    active: GlobalStates.barOpen && root.islandAllowed(barWindow.screen)
                    readonly property string layout: String(root.options?.layout ?? "island")
                    anchors.horizontalCenter: islandLoader.layout === "left" || islandLoader.layout === "right"
                        ? undefined : parent.horizontalCenter
                    anchors.left: islandLoader.layout === "left" ? parent.left : undefined
                    anchors.right: islandLoader.layout === "right" ? parent.right : undefined
                    anchors.top: windowLoader.loadedBottom ? undefined : parent.top
                    anchors.bottom: windowLoader.loadedBottom ? parent.bottom : undefined
                    anchors.margins: IrisFrame.band + root.outerMargin
                    width: item?.implicitWidth ?? 240
                    height: item?.implicitHeight ?? root.barHeight
                    sourceComponent: IrisIsland {
                        id: island
                        targetScreen: barWindow.screen
                        pointerHeld: islandInput.holding
                        availableWidth: barWindow.width - (IrisFrame.band + root.outerMargin) * 2
                        compactHeight: root.barHeight
                        bottomEdge: windowLoader.loadedBottom
                        screenOffsetY: 0
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

                IrisBanners {
                    id: banners
                    z: 2
                    anchors.fill: parent
                    screenData: barWindow.screen
                }

                IrisStage {
                    id: stage
                    z: 2
                    anchors.fill: parent
                    modelData: barWindow.screen
                    suppressed: barWindow.suppressed
                }

                Loader {
                    id: controlCentreLoader
                    z: 1
                    anchors.fill: parent
                    property bool wanted: GlobalStates.controlPanelOpen || GlobalStates.irisControlsWarm
                    // Latched: an `active` that reads its own `status` is a binding loop.
                    property bool kept: false
                    onWantedChanged: if (controlCentreLoader.wanted) controlCentreLoader.kept = true
                    Component.onCompleted: if (controlCentreLoader.wanted) controlCentreLoader.kept = true
                    active: (Config.options?.iris?.modules?.controlCenter ?? true) && controlCentreLoader.kept
                    asynchronous: true
                    sourceComponent: IrisControlCenter { screenData: barWindow.screen }
                }
            }
            }
        }
    }
}
