pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

Scope {
    id: root
    // The Applications button can be left out entirely.
    readonly property bool showLauncher: Config.options?.iris?.dock?.launcher ?? true
    readonly property var options: Config.options?.iris?.dock ?? ({})
    readonly property real d: IrisStyle.density
    readonly property real iconSize: Math.max(28, Math.min(64, Number(root.options?.iconSize ?? 40))) * root.d
    readonly property bool top: (Config.options?.iris?.bar?.position ?? "top") === "bottom"
    readonly property bool notch: root.options?.notch ?? false
    readonly property bool autoHide: root.options?.autoHide ?? true
    readonly property bool magnify: (root.options?.magnification ?? true) && IrisStyle.motionEnabled
    readonly property bool badges: root.options?.badges ?? true
    readonly property bool revealOnEmpty: root.options?.revealOnEmpty ?? true
    readonly property var apps: TaskbarApps.apps
    // Drop a leading/trailing separator: it only means "pinned vs running"
    // when both groups are present.
    readonly property var entries: {
        const list = root.apps.slice()
        while (list.length > 0 && list[0].appId === "SEPARATOR") list.shift()
        while (list.length > 0 && list[list.length - 1].appId === "SEPARATOR") list.pop()
        return list
    }
    // TaskbarApps rebuilds every entry object on any window event (focus,
    // title). Delegates are keyed by appId so they survive those rebuilds —
    // recreating them flashed every icon and dropped clicks mid-press — and
    // read live window state from this map instead of their first snapshot.
    readonly property var liveApps: {
        const map = {}
        for (const app of root.entries) map[app.appId] = app
        return map
    }
    // Unread notifications per sender, normalised like the notification service.
    // Counted from the whole list, not just live banners, so a badge outlives the
    // banner; it clears once the notifications are seen, without dismissing
    // anything: the app in focus shows none (what arrives while you are in it is
    // seen), leaving it marks everything up to then as seen, and so does opening
    // a surface that lists them (Today, Control Center). What was already in the
    // list when the shell started counts as seen, so restarts never pile badges up.
    readonly property var notificationTimes: {
        const times = {}
        if (!root.badges) return times
        for (const notification of Notifications.list ?? []) {
            const key = Notifications._normalizeAppKey(notification?.appName)
            if (key.length > 0) (times[key] = times[key] ?? []).push(Number(notification?.time ?? 0))
        }
        return times
    }
    property var seenAt: ({})
    property real seenAllAt: Date.now()
    function identifiersFor(app): var {
        const entry = app?.appId ? AppSearch.lookupDesktopEntry(app.appId) : null
        return [app?.appId ?? "", entry?.name ?? "", String(entry?.id ?? "").replace(/\.desktop$/, "")]
    }
    function keysFor(identifiers): var {
        return identifiers.map(id => Notifications._normalizeAppKey(id)).filter(key => key.length > 0)
    }
    function markSeen(identifiers): void {
        const next = Object.assign({}, root.seenAt)
        const now = Date.now()
        for (const key of root.keysFor(identifiers)) next[key] = now
        root.seenAt = next
    }
    function badgeCount(identifiers): int {
        const keys = root.keysFor(identifiers)
        if (keys.some(key => root.focusedKeys.includes(key))) return 0
        const seen = Math.max(root.seenAllAt, ...keys.map(key => root.seenAt[key] ?? 0))
        for (const key of keys) {
            const count = (root.notificationTimes[key] ?? []).filter(time => time > seen).length
            if (count) return count
        }
        return 0
    }
    // The app in focus, from the Dock or anywhere else, and every name its
    // notifications may use (app id, desktop entry name and id).
    readonly property string focusedAppId: String(NiriService.activeWindow?.app_id ?? "")
    readonly property var focusedKeys: {
        if (root.focusedAppId.length === 0) return []
        const app = root.entries.find(entry => entry.appId === root.focusedAppId
            || Notifications._normalizeAppKey(entry.appId) === Notifications._normalizeAppKey(root.focusedAppId))
        return root.keysFor(app ? root.identifiersFor(app) : [root.focusedAppId])
    }
    // Leaving an app: what arrived while it had focus has been seen.
    property var previousFocusedKeys: []
    onFocusedKeysChanged: {
        if (root.previousFocusedKeys.length > 0) root.markSeen(root.previousFocusedKeys)
        root.previousFocusedKeys = root.focusedKeys
    }
    Connections {
        target: GlobalStates
        function onSidebarRightOpenChanged(): void { if (GlobalStates.sidebarRightOpen) root.seenAllAt = Date.now() }
        function onControlPanelOpenChanged(): void { if (GlobalStates.controlPanelOpen) root.seenAllAt = Date.now() }
    }
    readonly property real slotWidth: root.iconSize + 10 * root.d
    readonly property real separatorWidth: 13 * root.d
    readonly property real slotSpacing: 2 * root.d
    readonly property real magnifyGain: 0.5
    // Icons rasterise once at their magnified size and scale down at rest;
    // resizing a theme icon per frame re-renders (and briefly blanks) it.
    readonly property real iconOversample: root.magnify ? 1 + root.magnifyGain : 1
    Component.onCompleted: CompositorService.setSortingConsumer("irisDock", true)
    Component.onDestruction: CompositorService.setSortingConsumer("irisDock", false)

    // Niri marks windows that ask for attention; the Dock shows it on the app.
    readonly property var urgentWindowIds: (NiriService.windows ?? []).filter(w => w.is_urgent).map(w => w.id)
    function appUrgent(app): bool {
        return (app?.toplevels ?? []).some(t => t.niriWindowId !== undefined && root.urgentWindowIds.includes(t.niriWindowId))
    }

    function activate(app): bool {
        const windows = app.toplevels ?? []
        if (MinimizedWindows.countMinimizedForApp(app.appId) > 0) {
            MinimizedWindows.restoreLatestForApp(app.appId)
        } else if (windows.length > 0) {
            const current = CompositorService.isNiri
                ? windows.findIndex(window => window.niriWindowId !== undefined
                    && window.niriWindowId === (NiriService.activeWindow?.id ?? -1))
                : windows.findIndex(window => window.activated)
            const next = windows[(current + 1) % windows.length]
            if (CompositorService.isNiri && next.niriWindowId !== undefined)
                NiriService.focusWindow(next.niriWindowId)
            else next.activate()
        } else {
            const entry = AppSearch.lookupDesktopEntry(app.appId)
            if (entry) AppSearch.launchEntry(entry)
            return true
        }
        return false
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyLoader {
            id: dockLoader
            required property var modelData
            property bool loadedTop: false
            Component.onCompleted: dockLoader.loadedTop = root.top
            readonly property bool requestedTop: root.top
            active: true
            // Anchors never flip on a live surface: tear the dock down and map it
            // again on the new edge. (A Timer declared here would be taken as the
            // loader's component and never exist.)
            onRequestedTopChanged: {
                dockLoader.active = false
                Qt.callLater(() => {
                    dockLoader.loadedTop = dockLoader.requestedTop
                    dockLoader.active = true
                })
            }
            component: Scope {
        id: screenScope
        readonly property var modelData: dockLoader.modelData
        readonly property bool atTop: dockLoader.loadedTop

        // Catches outside clicks while a context menu is open. Mapped before the
        // dock and kept mapped (input masked off when idle) so it always stacks
        // below it; switching the dock's layer instead would recreate its
        // surface and flash the menu.
        PanelWindow {
            id: dismissWindow
            screen: screenScope.modelData
            visible: !GlobalStates.screenLocked
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:iris-dock-dismiss"
            WlrLayershell.layer: WlrLayer.Top
            anchors { left: true; right: true; top: true; bottom: true }
            Item { id: dismissNoneItem; width: 0; height: 0 }
            mask: window.menuOpen ? dismissAll : dismissNone
            Region { id: dismissNone; item: dismissNoneItem }
            // Stacking by mapping order is not guaranteed: the dock and its menu
            // are cut out of the catch-all so they always receive the pointer.
            readonly property real dockOffsetY: screenScope.atTop ? 0 : dismissWindow.height - window.height
            Region {
                id: dismissAll
                Region { width: 100000; height: 100000 }
                Region {
                    intersection: Intersection.Subtract
                    x: hitArea.x; y: hitArea.y + dismissWindow.dockOffsetY
                    width: hitArea.width; height: hitArea.height
                }
                Region {
                    intersection: Intersection.Subtract
                    x: menu.x; y: menu.y + dismissWindow.dockOffsetY
                    width: menu.width; height: menu.height
                }
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onPressed: window.menuApp = null
            }
        }

        PanelWindow {
            id: window
            readonly property var modelData: screenScope.modelData
            property var menuApp: null
            // "menu" (right click) or "windows" (an app with several windows: its
            // windows as live previews growing out of the icon).
            property string menuMode: "menu"
            // Icon centre and edge-side top at the moment the menu opened;
            // magnification is frozen, so this stays true while it is open.
            property point menuAnchor: Qt.point(0, 0)
            property var menuOriginRect: null
            function captureMenuAnchor(icon: Item): void {
                // Both corners are mapped: icons are scaled, so width/height are
                // their raster size, not what is on screen.
                const topLeft = icon.mapToItem(window.contentItem, 0, 0)
                const bottomRight = icon.mapToItem(window.contentItem, icon.width, icon.height)
                const center = icon.mapToItem(window.contentItem, icon.width / 2, screenScope.atTop ? icon.height : 0)
                window.menuAnchor = Qt.point(Math.round(center.x), Math.round(center.y))
                const w = Math.round(bottomRight.x - topLeft.x), h = Math.round(bottomRight.y - topLeft.y)
                window.menuOriginRect = {
                    x: Math.round(topLeft.x), y: Math.round(topLeft.y),
                    width: w, height: h,
                    radius: Math.round(Math.min(w, h) * 0.25)
                }
            }
            readonly property bool menuOpen: window.menuApp !== null
            readonly property real dockHeight: root.iconSize + 18 * root.d
            readonly property real edgeGap: root.notch ? 0 : 10 * root.d
            readonly property real headroom: root.magnify ? root.iconSize * root.magnifyGain + 30 * root.d : 30 * root.d
            readonly property bool blurRequested: root.options?.blur ?? false
            readonly property bool nativeBlurActive: blurRequested && Appearance.compositorBlurActive
            readonly property real reservedZone: root.autoHide ? 0 : window.dockHeight + window.edgeGap * 2

            // Reveal by intent: the edge must be held briefly, so crossing it on
            // the way to a window's own controls does not throw the dock up.
            property bool edgeIntent: false
            // Icons accept hover and block handlers on sibling items, so the
            // pointer is tracked once on the window content (their ancestor);
            // the input mask decides where that counts.
            readonly property bool pointerOnDock: windowHover.hovered
            HoverHandler { id: windowHover }
            // Auto-hide has nothing to make room for on an empty workspace.
            readonly property bool workspaceEmpty: {
                if (!root.revealOnEmpty || !CompositorService.isNiri) return false
                const active = (NiriService.allWorkspaces ?? []).find(ws => ws.output === window.modelData?.name && ws.is_active)
                return active !== undefined && !(NiriService.windows ?? []).some(w => w.workspace_id === active.id)
            }
            readonly property bool revealed: !root.autoHide || window.edgeIntent || window.menuOpen || GlobalStates.irisDockShown
                || GlobalStates.searchOpen || window.workspaceEmpty
            onPointerOnDockChanged: {
                if (window.pointerOnDock) {
                    hideDelay.stop()
                    if (!window.edgeIntent) revealDwell.restart()
                } else {
                    revealDwell.stop()
                    if (!window.menuOpen) hideDelay.restart()
                }
            }
            Timer { id: revealDwell; interval: 110; onTriggered: window.edgeIntent = true }
            Timer { id: hideDelay; interval: 420; onTriggered: if (!window.pointerOnDock && !window.menuOpen) window.edgeIntent = false }
            onMenuOpenChanged: {
                if (window.menuOpen) return
                if (!window.pointerOnDock) hideDelay.restart()
            }

            screen: modelData
            visible: !GlobalStates.screenLocked && !GlobalStates.widgetEditMode
            color: "transparent"
            exclusionMode: root.autoHide ? ExclusionMode.Ignore : ExclusionMode.Normal
            exclusiveZone: window.reservedZone
            WlrLayershell.namespace: "quickshell:iris-dock"
            WlrLayershell.keyboardFocus: window.menuOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            // Anchors never change: a surface anchored to opposite edges loses
            // its exclusive zone and tiled windows would slide under the dock.
            anchors { left: true; right: true; top: screenScope.atTop; bottom: !screenScope.atTop }
            // Stable canvas: dock, magnified icons, name label and the context
            // menu all fit, so nothing resizes the layer surface.
            readonly property real menuReserve: Math.round(Math.min((window.screen?.height ?? 1080) * 0.55, 460 * root.d))
            implicitHeight: window.dockHeight + window.edgeGap + window.headroom + window.menuReserve
            mask: window.menuOpen ? menuRegion : hitRegion
            Region { id: hitRegion; item: hitArea }
            Region {
                id: menuRegion
                item: hitArea
                Region { item: menu }
            }

            BackgroundEffect.blurRegion: Region {
                item: window.nativeBlurActive ? dock : null
                radius: dock.radius
            }

            Shortcut { sequence: "Escape"; enabled: window.menuOpen; onActivated: window.menuApp = null }

            // Offset of the dock from its edge; negative hides it past the edge.
            // Anchored, so a window resize (menu) never replays the reveal.
            property real edgeOffset: window.revealed ? window.edgeGap : -(window.dockHeight + 6 * root.d)
            Behavior on edgeOffset { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }

            // Input region: the dock plus the gap down to the screen edge while
            // shown (no dead band between edge and dock), a thin strip when hidden.
            Item {
                id: hitArea
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: screenScope.atTop ? parent.top : undefined
                anchors.bottom: screenScope.atTop ? undefined : parent.bottom
                width: dock.width + (window.revealed ? 0 : 40 * root.d)
                // While hovered, magnified icons rise above the dock; they stay
                // inside the input region so the pointer never falls off them.
                height: !window.revealed ? 2
                    : Math.max(2, window.dockHeight + window.edgeOffset
                        + (root.magnify && window.pointerOnDock && !window.menuOpen ? root.iconSize * root.magnifyGain + 4 * root.d : 0))
            }

            // Pointer x in the dock's unmagnified layout, or null.
            // Magnification freezes where it was when a menu opens, so the icon the
            // menu grew out of (and the menu itself) stays put.
            property var frozenSlotX: null
            readonly property var pointerSlotX: {
                if (window.menuOpen) return window.frozenSlotX
                if (!root.magnify || !window.pointerOnDock || !window.revealed) return null
                // Measured against the resting (centred) layout only, so the
                // magnified width never feeds back into what it is computed from.
                const x = windowHover.point.position.x - (window.width - dock.baseWidth) / 2
                if (x < -root.slotWidth || x > dock.baseWidth + root.slotWidth) return null
                return x - dock.padding
            }
            readonly property var baseCenters: {
                const centers = []
                let x = 0
                const all = (root.showLauncher ? [{ appId: "__launcher" }] : []).concat(root.entries)
                for (let i = 0; i < all.length; i++) {
                    const w = all[i].appId === "SEPARATOR" ? root.separatorWidth : root.slotWidth
                    centers.push(x + w / 2)
                    x += w + root.slotSpacing
                }
                return centers
            }
            function magnification(index: int): real {
                if (window.pointerSlotX === null) return 0
                const distance = Math.abs((window.baseCenters[index] ?? 0) - window.pointerSlotX)
                const range = root.slotWidth * 2.6
                if (distance >= range) return 0
                return (Math.cos(Math.PI * distance / range) + 1) / 2
            }

            IrisSurface {
                id: dock
                readonly property real padding: 8 * root.d
                readonly property real baseWidth: (window.baseCenters.length > 0
                    ? window.baseCenters[window.baseCenters.length - 1] + root.slotWidth / 2 : 0) + dock.padding * 2
                width: Math.min(window.width - 32, appRow.implicitWidth + dock.padding * 2)
                height: window.dockHeight
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: screenScope.atTop ? parent.top : undefined
                anchors.bottom: screenScope.atTop ? undefined : parent.bottom
                anchors.topMargin: window.edgeOffset
                anchors.bottomMargin: window.edgeOffset
                radius: Math.min(IrisStyle.radius, height / 2)
                notchTop: root.notch && screenScope.atTop
                notchBottom: root.notch && !screenScope.atTop
                quiet: window.nativeBlurActive
                opacity: window.revealed || window.edgeOffset > -window.dockHeight ? 1 : 0

                Rectangle {
                    anchors.fill: parent
                    z: -1
                    visible: window.nativeBlurActive
                    radius: dock.radius
                    topLeftRadius: dock.notchTop ? 0 : radius
                    topRightRadius: dock.notchTop ? 0 : radius
                    bottomLeftRadius: dock.notchBottom ? 0 : radius
                    bottomRightRadius: dock.notchBottom ? 0 : radius
                    color: ColorUtils.applyAlpha(IrisStyle.surfaceHigh, 0.68)
                }

                // A hairline just inside the edge gives the black plate a defined
                // silhouette over dark wallpapers; the attached edge stays open.
                Rectangle {
                    anchors.fill: parent
                    visible: !root.notch && !window.nativeBlurActive
                    radius: dock.radius
                    color: "transparent"
                    border.width: 1
                    border.color: ColorUtils.applyAlpha(IrisStyle.text, 0.13)
                }

                Row {
                    id: appRow
                    anchors.left: parent.left
                    anchors.leftMargin: dock.padding
                    anchors.top: screenScope.atTop ? parent.top : undefined
                    anchors.bottom: screenScope.atTop ? undefined : parent.bottom
                    height: root.iconSize + 10 * root.d
                    anchors.topMargin: 4 * root.d
                    anchors.bottomMargin: 4 * root.d
                    spacing: root.slotSpacing

                    component Slot: Item {
                        id: slot
                        required property int slotIndex
                        readonly property real mag: window.magnification(slot.slotIndex)
                        property real grow: slot.mag
                        Behavior on grow { NumberAnimation { duration: IrisStyle.duration(70); easing.type: Easing.OutQuad } }
                        readonly property real iconScale: 1 + root.magnifyGain * slot.grow
                        width: root.slotWidth + root.iconSize * root.magnifyGain * slot.grow
                        height: appRow.height
                    }

                    Slot {
                        id: launcherSlot
                        visible: root.showLauncher
                        slotIndex: 0
                        MouseArea {
                            id: launcherArea
                            anchors.fill: parent
                            anchors.topMargin: screenScope.atTop ? 0 : -root.iconSize * root.magnifyGain * launcherSlot.grow
                            anchors.bottomMargin: screenScope.atTop ? -root.iconSize * root.magnifyGain * launcherSlot.grow : 0
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            Accessible.role: Accessible.Button
                            Accessible.name: Translation.tr("Applications")
                            onClicked: GlobalStates.searchOpen = !GlobalStates.searchOpen
                            onContainsMouseChanged: nameLabel.present(containsMouse ? launcherSlot : null, Translation.tr("Applications"))
                            // Same footprint, anchoring and magnification as an app icon, but
                            // no tile: a quiet grid of dots on the Dock's own black, which
                            // closes into a cross while Spotlight is open.
                            Item {
                                id: launcherGlyph
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: screenScope.atTop ? undefined : parent.bottom
                                anchors.top: screenScope.atTop ? parent.top : undefined
                                anchors.bottomMargin: 7 * root.d
                                anchors.topMargin: 7 * root.d
                                width: Math.round(root.iconSize * 0.9 * launcherSlot.iconScale * (launcherArea.pressed ? 0.92 : 1))
                                height: width
                                Grid {
                                    id: launcherDots
                                    anchors.centerIn: parent
                                    visible: !GlobalStates.searchOpen
                                    readonly property real dot: Math.max(3, Math.round(launcherGlyph.width * 0.11))
                                    columns: 3
                                    spacing: Math.round(launcherGlyph.width * 0.1)
                                    Repeater {
                                        model: 9
                                        Rectangle {
                                            width: launcherDots.dot
                                            height: width
                                            radius: width / 2
                                            color: ColorUtils.applyAlpha(IrisStyle.text, launcherArea.containsMouse ? 1 : 0.82)
                                            Behavior on color { ColorAnimation { duration: IrisStyle.duration(120) } }
                                        }
                                    }
                                }
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    visible: GlobalStates.searchOpen
                                    text: "close"
                                    iconSize: launcherGlyph.width * 0.5
                                    color: IrisStyle.text
                                }
                            }
                        }
                    }

                    Repeater {
                        model: ScriptModel {
                            objectProp: "appId"
                            values: root.entries
                        }
                        Item {
                            id: entry
                            required property var modelData
                            required property int index
                            readonly property var app: root.liveApps[entry.modelData.appId] ?? entry.modelData
                            readonly property bool separator: entry.modelData.appId === "SEPARATOR"
                            width: entry.separator ? root.separatorWidth : appSlot.width
                            height: appRow.height

                            Rectangle {
                                visible: entry.separator
                                anchors.centerIn: parent
                                width: 1
                                height: root.iconSize * 0.7
                                color: ColorUtils.applyAlpha(IrisStyle.text, 0.18)
                            }

                            Slot {
                                id: appSlot
                                visible: !entry.separator
                                slotIndex: entry.index + (root.showLauncher ? 1 : 0)
                                readonly property var desktopEntry: entry.separator ? null : AppSearch.lookupDesktopEntry(entry.modelData.appId)
                                readonly property string appName: appSlot.desktopEntry?.name ?? entry.modelData.appId
                                readonly property bool running: (entry.app.toplevels?.length ?? 0) > 0
                                // Niri's focused window is authoritative; the Wayland handle's
                                // activated flag lagged behind (no capsule on the focused app).
                                readonly property bool focused: (entry.app.toplevels ?? []).some(t => CompositorService.isNiri
                                    ? t.niriWindowId !== undefined && t.niriWindowId === (NiriService.activeWindow?.id ?? -1)
                                    : t.activated)
                                property real lift: 0

                                SequentialAnimation {
                                    id: launchBounce
                                    loops: 2
                                    NumberAnimation { target: appSlot; property: "lift"; to: 14 * root.d; duration: 220; easing.type: Easing.OutQuad }
                                    NumberAnimation { target: appSlot; property: "lift"; to: 0; duration: 260; easing.type: Easing.OutBounce }
                                }

                                IrisButton {
                                    id: appButton
                                    anchors.fill: parent
                                    // The magnified icon rises past the slot; so does its hit area.
                                    anchors.topMargin: screenScope.atTop ? 0 : -root.iconSize * root.magnifyGain * appSlot.grow
                                    anchors.bottomMargin: screenScope.atTop ? -root.iconSize * root.magnifyGain * appSlot.grow : 0
                                    pressScaleEnabled: false
                                    quiet: true
                                    colBackgroundHover: "transparent"
                                    Accessible.name: appSlot.appName
                                    onHoveredChanged: nameLabel.present(hovered ? appSlot : null, appSlot.appName, entry.app.toplevels?.length ?? 0)
                                    onClicked: {
                                        // Several windows: show them instead of guessing which one.
                                        if ((entry.app.toplevels?.length ?? 0) > 1 && MinimizedWindows.countMinimizedForApp(entry.app.appId) === 0) {
                                            if (window.menuOpen && window.menuApp === entry.app) { window.menuApp = null; return }
                                            window.frozenSlotX = window.pointerSlotX
                                            window.captureMenuAnchor(appIcon)
                                            window.menuMode = "windows"
                                            window.menuApp = entry.app
                                            nameLabel.present(null, "")
                                            return
                                        }
                                        GlobalStates.irisDockShown = false
                                        if (root.activate(entry.app) && IrisStyle.motionEnabled) launchBounce.restart()
                                    }
                                    middleClickAction: () => {
                                        const e = AppSearch.lookupDesktopEntry(entry.modelData.appId)
                                        if (e) AppSearch.launchEntry(e)
                                        if (IrisStyle.motionEnabled) launchBounce.restart()
                                    }
                                    altAction: () => {
                                        window.frozenSlotX = window.pointerSlotX
                                        window.captureMenuAnchor(appIcon)
                                        window.menuMode = "menu"
                                        window.menuApp = entry.app
                                        nameLabel.present(null, "")
                                    }
                                    WheelHandler {
                                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                        property real accumulated: 0
                                        onWheel: wheel => {
                                            const windows = entry.app.toplevels ?? []
                                            if (windows.length < 2) return
                                            accumulated += wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y * 4
                                            while (Math.abs(accumulated) >= 120) {
                                                const direction = accumulated > 0 ? -1 : 1
                                                accumulated += direction * 120
                                                const current = Math.max(0, windows.findIndex(t => t.activated))
                                                const next = windows[(current + direction + windows.length) % windows.length]
                                                if (CompositorService.isNiri && next.niriWindowId !== undefined) NiriService.focusWindow(next.niriWindowId)
                                                else next.activate()
                                            }
                                        }
                                    }
                                    // Without magnification, hover is a quiet platter and a
                                    // small lift, so the pointer still lands somewhere.
                                    Rectangle {
                                        visible: !root.magnify
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.verticalCenter: appIcon.verticalCenter
                                        width: root.iconSize + 8 * root.d
                                        height: width
                                        radius: Math.round(width * 0.28)
                                        color: ColorUtils.applyAlpha(IrisStyle.text, appButton.hovered || appButton.down ? 0.1 : 0)
                                        Behavior on color { ColorAnimation { duration: IrisStyle.duration(120) } }
                                    }
                                    SmartAppIcon {
                                        id: appIcon
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: screenScope.atTop ? undefined : parent.bottom
                                        anchors.top: screenScope.atTop ? parent.top : undefined
                                        property real hoverLift: !root.magnify && appButton.hovered ? 2 * root.d : 0
                                        Behavior on hoverLift { NumberAnimation { duration: IrisStyle.duration(120); easing.type: Easing.OutCubic } }
                                        anchors.bottomMargin: 7 * root.d + appSlot.lift + hoverLift
                                        anchors.topMargin: 7 * root.d + appSlot.lift + hoverLift
                                        transformOrigin: screenScope.atTop ? Item.Top : Item.Bottom
                                        icon: entry.separator ? "" : (appSlot.desktopEntry?.icon ?? entry.modelData.appId)
                                        fallback: "application-x-executable"
                                        // Fixed raster at the largest size; magnification and press
                                        // only scale it, mipmapped so the resting size stays crisp.
                                        iconSize: Math.round(root.iconSize * root.iconOversample)
                                        scale: appSlot.iconScale * (appButton.down ? 0.92 : 1) / root.iconOversample
                                        layer.enabled: root.magnify
                                        layer.smooth: true
                                        layer.mipmap: true
                                    }
                                }
                                // Unread notifications, pinned to the icon's top-right corner.
                                Rectangle {
                                    readonly property int count: root.badgeCount([entry.modelData.appId, appSlot.appName,
                                        String(appSlot.desktopEntry?.id ?? "").replace(/\.desktop$/, "")])
                                    visible: count > 0
                                    parent: appIcon
                                    x: appIcon.width - width * 0.7
                                    y: -height * 0.3
                                    // Lives inside the oversampled icon, so sizes are oversampled too.
                                    height: Math.round(18 * root.d * root.iconOversample)
                                    width: Math.max(height, badgeText.implicitWidth + 10 * root.d * root.iconOversample)
                                    radius: height / 2
                                    color: IrisStyle.danger
                                    border.width: Math.max(1, Math.round(1.5 * root.d * root.iconOversample))
                                    border.color: IrisStyle.surface
                                    IrisText {
                                        id: badgeText
                                        anchors.centerIn: parent
                                        text: parent.count > 99 ? "99+" : parent.count
                                        color: "#ffffff"
                                        font.pixelSize: 10.5 * IrisStyle.typeScale * root.iconOversample
                                        font.weight: Font.Bold
                                    }
                                }
                                // State under the icon, in one vocabulary: a dot per open window
                                // (up to three) in the app's window order, the focused window's dot
                                // stretched into a capsule, windows that are all minimised a hollow
                                // ring, attention in orange. Neutral like the icon, not the accent.
                                Row {
                                    id: indicators
                                    readonly property int windows: Math.min(3, entry.app.toplevels?.length ?? 0)
                                    readonly property int focusedIndex: {
                                        if (!appSlot.focused) return -1
                                        const id = NiriService.activeWindow?.id ?? -1
                                        const index = (entry.app.toplevels ?? []).findIndex(t => CompositorService.isNiri ? t.niriWindowId === id : t.activated)
                                        return Math.min(indicators.windows - 1, Math.max(0, index))
                                    }
                                    readonly property bool minimizedOnly: appSlot.running
                                        && MinimizedWindows.countMinimizedForApp(entry.modelData.appId) >= (entry.app.toplevels?.length ?? 0)
                                    readonly property bool urgent: root.appUrgent(entry.app)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: screenScope.atTop ? undefined : parent.bottom
                                    anchors.top: screenScope.atTop ? parent.top : undefined
                                    anchors.bottomMargin: 0
                                    anchors.topMargin: 0
                                    spacing: 3 * root.d
                                    visible: windows > 0
                                    Repeater {
                                        model: indicators.windows
                                        Rectangle {
                                            id: indicator
                                            required property int index
                                            readonly property bool lead: indicator.index === indicators.focusedIndex
                                            height: Math.round(5 * root.d)
                                            width: indicator.lead ? Math.round(14 * root.d) : height
                                            radius: height / 2
                                            color: indicators.minimizedOnly ? "transparent"
                                                : indicators.urgent ? IrisStyle.secondaryAccent
                                                : indicator.lead ? IrisStyle.text : ColorUtils.applyAlpha(IrisStyle.text, appSlot.focused ? 0.55 : 0.42)
                                            border.width: indicators.minimizedOnly ? Math.max(1, Math.round(1.2 * root.d)) : 0
                                            border.color: ColorUtils.applyAlpha(IrisStyle.text, 0.55)
                                            Behavior on width { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
                                            Behavior on color { ColorAnimation { duration: IrisStyle.duration(140) } }
                                            SequentialAnimation on opacity {
                                                running: indicators.urgent && IrisStyle.motionEnabled && indicator.visible
                                                loops: Animation.Infinite
                                                NumberAnimation { to: 0.35; duration: 650; easing.type: Easing.InOutSine }
                                                NumberAnimation { to: 1; duration: 650; easing.type: Easing.InOutSine }
                                                onRunningChanged: if (!running) indicator.opacity = 1
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Concave fillets melt a notch-mode dock into its screen edge.
            Repeater {
                model: root.notch ? 2 : 0
                RoundCorner {
                    required property int index
                    readonly property real size: Math.round(12 * root.d)
                    implicitSize: size
                    color: window.nativeBlurActive ? ColorUtils.applyAlpha(IrisStyle.surfaceHigh, 0.68) : IrisStyle.surface
                    visible: window.edgeOffset >= -0.5
                    x: index === 0 ? dock.x - size : dock.x + dock.width
                    y: screenScope.atTop ? 0 : window.height - size
                    corner: index === 0
                        ? (screenScope.atTop ? RoundCorner.CornerEnum.TopRight : RoundCorner.CornerEnum.BottomRight)
                        : (screenScope.atTop ? RoundCorner.CornerEnum.TopLeft : RoundCorner.CornerEnum.BottomLeft)
                }
            }

            // App name bubble over the hovered icon, shown after a short dwell.
            IrisSurface {
                id: nameLabel
                property Item target: null
                property string label: ""
                property bool shown: false
                function present(item, text, count): void {
                    if (item) { nameLabel.target = item; nameLabel.label = text; nameLabel.windowCount = count ?? 0; labelDelay.restart() }
                    else if (nameLabel.target) { labelDelay.stop(); nameLabel.shown = false }
                }
                Timer { id: labelDelay; interval: 380; onTriggered: nameLabel.shown = true }
                readonly property point anchorPoint: nameLabel.target
                    ? nameLabel.target.mapToItem(window.contentItem, nameLabel.target.width / 2 + 0 * (dock.width + nameLabel.target.width), 0)
                    : Qt.point(0, 0)
                visible: opacity > 0.01
                opacity: nameLabel.shown && !window.menuOpen && window.revealed ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120); easing.type: Easing.OutCubic } }
                width: labelText.implicitWidth + 22 * root.d
                height: Math.round(28 * root.d)
                radius: height / 2
                x: Math.max(8, Math.min(window.width - width - 8, nameLabel.anchorPoint.x - width / 2))
                // Rides just above the hovered icon, including its magnification.
                readonly property real targetLift: root.iconSize * root.magnifyGain * (nameLabel.target?.grow ?? 0)
                y: screenScope.atTop
                    ? dock.y + dock.height + 8 * root.d + nameLabel.targetLift
                    : dock.y - height - 8 * root.d - nameLabel.targetLift
                property int windowCount: 0
                Row {
                    id: labelText
                    anchors.centerIn: parent
                    spacing: 6 * root.d
                    IrisText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: nameLabel.label
                        font.pixelSize: 12.5 * IrisStyle.typeScale
                        font.weight: Font.DemiBold
                    }
                    IrisText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: nameLabel.windowCount > 1
                        text: nameLabel.windowCount
                        color: IrisStyle.secondaryAccent
                        font.pixelSize: 11.5 * IrisStyle.typeScale
                        font.weight: Font.Bold
                        font.family: IrisStyle.fontNumbers
                        font.features: ({ "tnum": 1 })
                    }
                }
            }

            // Context menu grows out of the icon that was right-clicked.
            IrisMorphSurface {
                id: menu
                open: window.menuOpen
                origin: window.menuOriginRect
                readonly property Item activeContent: menu.mode === "windows" ? windowsContent : menuContent
                contentReady: menu.activeContent.implicitHeight > 0
                radius: Math.round((menu.mode === "windows" ? 20 : 14) * root.d)
                color: IrisStyle.surface
                contentScaleFrom: 1
                contentFadeStart: 0.08
                contentFadeSpan: 0.34
                animationDuration: IrisStyle.morphDuration
                width: menu.mode === "windows"
                    ? Math.round(Math.min(window.width - 24, windowsContent.implicitWidth + 20 * root.d))
                    : Math.round(Math.min(Math.max(200 * root.d, menuContent.implicitWidth + 12 * root.d), 260 * root.d))
                height: Math.round(menu.activeContent.implicitHeight + (menu.mode === "windows" ? 20 : 12) * root.d)
                // Snap the whole surface to device pixels; fractional layer-surface
                // translation softens every glyph even when the text itself is crisp.
                x: Math.round(Math.max(12, Math.min(window.width - width - 12, window.menuAnchor.x - width / 2)))
                y: Math.round(screenScope.atTop ? window.menuAnchor.y + 8 * root.d : window.menuAnchor.y - height - 8 * root.d)
                visible: progress > 0
                onClosed: {
                    if (!window.menuOpen) {
                        menu.app = null
                        menu.windows = []
                        window.menuOriginRect = null
                        window.frozenSlotX = null
                    }
                }
                // Keep the last app while collapsing so the content does not blank.
                property var app: null
                property var windows: []
                property string mode: "menu"
                Connections {
                    target: window
                    function onMenuAppChanged(): void {
                        if (!window.menuApp) return
                        menu.app = window.menuApp
                        menu.mode = window.menuMode
                        menu.windows = (window.menuApp.toplevels ?? []).slice()
                    }
                }
                MouseArea { anchors.fill: parent }

                // Windows: one live preview per window of the app, the focused one
                // ringed, each with its title and a close button on hover.
                ColumnLayout {
                    id: windowsContent
                    visible: menu.mode === "windows"
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 10 * root.d
                    spacing: 8 * root.d
                    readonly property real cardWidth: Math.round(208 * root.d)
                    readonly property real cardHeight: Math.round(130 * root.d)
                    readonly property int columns: Math.max(1, Math.min(4, menu.windows.length))

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 6 * root.d
                        Layout.rightMargin: 2 * root.d
                        spacing: 8 * root.d
                        SmartAppIcon {
                            icon: AppSearch.lookupDesktopEntry(menu.app?.appId ?? "")?.icon ?? (menu.app?.appId ?? "")
                            fallback: "application-x-executable"
                            iconSize: Math.round(18 * root.d)
                        }
                        IrisText {
                            Layout.fillWidth: true
                            text: AppSearch.lookupDesktopEntry(menu.app?.appId ?? "")?.name ?? (menu.app?.appId ?? "")
                            elide: Text.ElideRight
                            font.pixelSize: 13 * IrisStyle.typeScale
                            font.weight: Font.DemiBold
                        }
                        IrisText {
                            text: Translation.tr("%1 windows").arg(menu.windows.length)
                            color: IrisStyle.muted
                            font.pixelSize: 11.5 * IrisStyle.typeScale
                        }
                        IrisIconButton {
                            materialIcon: "add"
                            Accessible.name: Translation.tr("New window")
                            onClicked: {
                                const e = AppSearch.lookupDesktopEntry(menu.app?.appId ?? "")
                                if (e) AppSearch.launchEntry(e)
                                window.menuApp = null
                            }
                        }
                    }

                    Grid {
                        columns: windowsContent.columns
                        spacing: 8 * root.d
                        Repeater {
                            model: menu.windows
                            MouseArea {
                                id: card
                                required property var modelData
                                readonly property bool focusedWindow: CompositorService.isNiri
                                    ? card.modelData?.niriWindowId !== undefined && card.modelData.niriWindowId === (NiriService.activeWindow?.id ?? -1)
                                    : (card.modelData?.activated ?? false)
                                width: windowsContent.cardWidth
                                height: windowsContent.cardHeight + titleText.implicitHeight + 6 * root.d
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                Accessible.role: Accessible.Button
                                Accessible.name: String(card.modelData?.title ?? "")
                                onClicked: {
                                    if (CompositorService.isNiri && card.modelData?.niriWindowId !== undefined) NiriService.focusWindow(card.modelData.niriWindowId)
                                    else card.modelData?.activate()
                                    GlobalStates.irisDockShown = false
                                    window.menuApp = null
                                }

                                // Concentric ring on the focused window.
                                Rectangle {
                                    width: windowsContent.cardWidth
                                    height: windowsContent.cardHeight
                                    radius: Math.round(12 * root.d)
                                    color: "transparent"
                                    border.width: Math.max(2, Math.round(2 * root.d))
                                    border.color: ColorUtils.applyAlpha(IrisStyle.text, card.focusedWindow ? 0.9 : card.containsMouse ? 0.35 : 0)
                                    Behavior on border.color { ColorAnimation { duration: IrisStyle.duration(120) } }
                                }
                                ClippingRectangle {
                                    id: previewPlate
                                    x: Math.round(4 * root.d)
                                    y: Math.round(4 * root.d)
                                    width: windowsContent.cardWidth - Math.round(8 * root.d)
                                    height: windowsContent.cardHeight - Math.round(8 * root.d)
                                    radius: Math.round(8 * root.d)
                                    color: IrisStyle.surfaceHigh
                                    scale: card.pressed ? 0.97 : 1
                                    Behavior on scale { NumberAnimation { duration: IrisStyle.duration(110); easing.type: Easing.OutCubic } }
                                    // Niri exposes no per-window capture, so there a window is its
                                    // app, where it lives and a glimpse of its state; compositors that
                                    // can capture a toplevel show it live instead.
                                    Loader {
                                        anchors.fill: parent
                                        active: !CompositorService.isNiri && window.menuOpen && menu.mode === "windows" && !GameMode.active
                                        sourceComponent: ScreencopyView {
                                            captureSource: card.modelData
                                            live: !RecorderStatus.isRecording
                                        }
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        visible: CompositorService.isNiri
                                        gradient: Gradient {
                                            GradientStop { position: 0; color: ColorUtils.applyAlpha(IrisStyle.text, card.focusedWindow ? 0.14 : 0.09) }
                                            GradientStop { position: 1; color: ColorUtils.applyAlpha(IrisStyle.text, 0.03) }
                                        }
                                        SmartAppIcon {
                                            anchors.centerIn: parent
                                            anchors.verticalCenterOffset: -8 * root.d
                                            icon: AppSearch.lookupDesktopEntry(menu.app?.appId ?? "")?.icon ?? (menu.app?.appId ?? "")
                                            fallback: "application-x-executable"
                                            iconSize: Math.round(46 * root.d)
                                            opacity: card.focusedWindow || card.containsMouse ? 1 : 0.82
                                        }
                                        // Where the window lives, quiet in the plate's lower edge.
                                        Rectangle {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 8 * root.d
                                            readonly property var workspace: (NiriService.allWorkspaces ?? []).find(ws => ws.id === card.modelData?.niriWorkspaceId) ?? null
                                            visible: workspace !== null
                                            implicitHeight: Math.round(20 * root.d)
                                            implicitWidth: workspaceLabel.implicitWidth + Math.round(16 * root.d)
                                            radius: height / 2
                                            color: ColorUtils.applyAlpha(IrisStyle.surface, 0.55)
                                            IrisText {
                                                id: workspaceLabel
                                                anchors.centerIn: parent
                                                text: parent.workspace ? (parent.workspace.name || Translation.tr("Workspace %1").arg(parent.workspace.idx)) : ""
                                                color: IrisStyle.subtext
                                                font.pixelSize: 10.5 * IrisStyle.typeScale
                                                font.weight: Font.Medium
                                            }
                                        }
                                    }
                                }
                                IrisText {
                                    id: titleText
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: 4 * root.d
                                    anchors.rightMargin: 4 * root.d
                                    text: String(card.modelData?.title ?? "")
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                    color: card.focusedWindow ? IrisStyle.text : IrisStyle.subtext
                                    font.pixelSize: 11.5 * IrisStyle.typeScale
                                    font.weight: card.focusedWindow ? Font.DemiBold : Font.Medium
                                }
                                // Close, on the preview's corner while hovered.
                                Rectangle {
                                    x: previewPlate.x + previewPlate.width - width - 6 * root.d
                                    y: previewPlate.y + 6 * root.d
                                    width: Math.round(22 * root.d)
                                    height: width
                                    radius: width / 2
                                    color: closeHover.hovered ? IrisStyle.danger : ColorUtils.applyAlpha(IrisStyle.surface, 0.72)
                                    opacity: card.containsMouse && CompositorService.isNiri ? 1 : 0
                                    visible: opacity > 0
                                    Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120) } }
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "close"
                                        iconSize: Math.round(13 * root.d)
                                        color: IrisStyle.text
                                    }
                                    HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: {
                                            if (card.modelData?.niriWindowId !== undefined) NiriService.closeWindow(card.modelData.niriWindowId)
                                            menu.windows = menu.windows.filter(t => t !== card.modelData)
                                            if (menu.windows.length === 0) window.menuApp = null
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: menuContent
                    visible: menu.mode === "menu"
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 6 * root.d
                    spacing: 0

                    component MenuRow: IrisButton {
                        id: menuRow
                        property string glyph: ""
                        property string label: ""
                        Layout.fillWidth: true
                        quiet: true
                        implicitHeight: Math.round(30 * root.d)
                        implicitWidth: menuRowLabel.implicitWidth + 52 * root.d
                        buttonRadius: Math.round(8 * root.d)
                        pressScaleEnabled: false
                        colBackgroundHover: ColorUtils.applyAlpha(IrisStyle.accent, 0.22)
                        Accessible.name: menuRow.label
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8 * root.d
                            anchors.rightMargin: 10 * root.d
                            spacing: 8 * root.d
                            MaterialSymbol {
                                text: menuRow.glyph
                                iconSize: Math.round(15 * root.d)
                                color: menuRow.danger ? IrisStyle.danger : IrisStyle.subtext
                            }
                            IrisText {
                                id: menuRowLabel
                                Layout.fillWidth: true
                                text: menuRow.label
                                elide: Text.ElideRight
                                color: menuRow.danger ? IrisStyle.danger : IrisStyle.text
                                font.pixelSize: 12.5 * IrisStyle.typeScale
                            }
                        }
                    }

                    // Header: app name, window count on the right.
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 10 * root.d
                        Layout.rightMargin: 10 * root.d
                        Layout.topMargin: 4 * root.d
                        Layout.bottomMargin: 4 * root.d
                        spacing: 12 * root.d
                        IrisText {
                            Layout.fillWidth: true
                            text: AppSearch.lookupDesktopEntry(menu.app?.appId ?? "")?.name ?? (menu.app?.appId ?? "")
                            elide: Text.ElideRight
                            font.pixelSize: 13 * IrisStyle.typeScale
                            font.weight: Font.DemiBold
                        }
                        IrisText {
                            text: (menu.windows?.length ?? 0) === 0 ? Translation.tr("Not running")
                                : (menu.windows.length === 1 ? Translation.tr("1 window") : Translation.tr("%1 windows").arg(menu.windows.length))
                            color: IrisStyle.muted
                            font.pixelSize: 11.5 * IrisStyle.typeScale
                        }
                    }
                    Repeater {
                        model: menu.windows
                        MenuRow {
                            required property var modelData
                            glyph: modelData.activated ? "radio_button_checked" : "select_window"
                            label: String(modelData.title ?? "")
                            onClicked: {
                                if (CompositorService.isNiri && modelData.niriWindowId !== undefined) NiriService.focusWindow(modelData.niriWindowId)
                                else modelData.activate()
                                window.menuApp = null
                            }
                        }
                    }
                    Rectangle { Layout.fillWidth: true; Layout.leftMargin: 10 * root.d; Layout.rightMargin: 10 * root.d; Layout.topMargin: 4 * root.d; Layout.bottomMargin: 4 * root.d; implicitHeight: 1; color: IrisStyle.hairlineStrong }
                    MenuRow {
                        glyph: "open_in_new"
                        label: Translation.tr("New window")
                        onClicked: {
                            const e = AppSearch.lookupDesktopEntry(menu.app?.appId ?? "")
                            if (e) AppSearch.launchEntry(e)
                            window.menuApp = null
                        }
                    }
                    MenuRow {
                        glyph: menu.app?.pinned ? "keep_off" : "keep"
                        label: menu.app?.pinned ? Translation.tr("Unpin from dock") : Translation.tr("Keep in dock")
                        onClicked: { TaskbarApps.togglePin(menu.app.appId); window.menuApp = null }
                    }
                    MenuRow {
                        visible: CompositorService.isNiri && (menu.windows?.length ?? 0) > 0
                        glyph: "close"
                        danger: true
                        label: (menu.windows?.length ?? 0) > 1 ? Translation.tr("Close all windows") : Translation.tr("Close window")
                        onClicked: {
                            (menu.windows ?? []).forEach(t => { if (t.niriWindowId !== undefined) NiriService.closeWindow(t.niriWindowId) })
                            window.menuApp = null
                        }
                    }
                }
            }
        }
            }
        }
    }
}
