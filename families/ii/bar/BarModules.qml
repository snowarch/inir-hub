pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common
import qs.services

/**
 * The bar's module catalogue and every move of a module, for both layouts.
 *
 * Classic, islands, scenic and frame bars keep five zones in material.bar.layout.<zone>;
 * the M3 bar keeps three in material.bar.m3.layouts.<zone>Layout. One owner reads them, names
 * the modules and writes the moves, so the Settings editor and the in-place edit marks cannot
 * drift apart. Writes go through Config.setNestedValues per leaf (never a whole JsonObject).
 *
 * Index contract: move() and add() take the insert slot in the list as it is BEFORE the move,
 * so a caret drawn between two modules maps straight onto it.
 */
Singleton {
    id: root

    readonly property string variant: (Config.options?.material?.bar?.appearanceStyle ?? "classic") === "m3" ? "m3" : "classic"
    readonly property bool isM3: root.variant === "m3"
    // Room an empty module keeps on the bar in edit mode, so it can still be carried.
    readonly property real standInWidth: 80

    // ─── Classic (five zones) ───────────────────────────────────────────
    readonly property var classicZones: ["left", "centerLeft", "center", "centerRight", "right"]
    readonly property var classicDefaults: ({
        left: ["leftSidebarButton", "activeWindow"],
        centerLeft: ["resources", "media"],
        center: ["workspaces"],
        centerRight: ["clock", "utilButtons", "battery"],
        right: ["rightSidebarButton", "tray", "timer", "shellUpdate", "spacer", "weather"],
    })
    readonly property var classicKnownIds: [
        "leftSidebarButton", "activeWindow", "resources", "media", "workspaces",
        "clock", "utilButtons", "battery", "rightSidebarButton", "tray", "timer", "shellUpdate", "spacer", "weather"
    ]
    readonly property bool classicMigrated: Config.options?.material?.bar?.layout?.migrated === true

    function classicIcon(id) {
        if (id === "activeWindow" && (Config.options?.material?.bar?.modules?.taskbar ?? false))
            return "dock_to_bottom"
        return ({ leftSidebarButton: "side_navigation", activeWindow: "window",
            resources: "memory", media: "music_note", workspaces: "workspaces", clock: "schedule",
            utilButtons: "build", battery: "battery_full", rightSidebarButton: "call_to_action",
            tray: "shelf_auto_hide", timer: "timer", shellUpdate: "system_update", spacer: "space_bar",
            weather: "cloud" })[id] || "widgets"
    }
    function classicLabel(id) {
        if (id === "activeWindow" && (Config.options?.material?.bar?.modules?.taskbar ?? false))
            return Translation.tr("Taskbar")
        return ({ leftSidebarButton: Translation.tr("Left sidebar"), activeWindow: Translation.tr("Active window"),
            resources: Translation.tr("Resources"), media: Translation.tr("Media"),
            workspaces: Translation.tr("Workspaces"), clock: Translation.tr("Clock"), utilButtons: Translation.tr("Utility buttons"),
            battery: Translation.tr("Battery"), rightSidebarButton: Translation.tr("Right sidebar"), tray: Translation.tr("System tray"),
            timer: Translation.tr("Timer"), shellUpdate: Translation.tr("Shell update"), spacer: Translation.tr("Flexible spacer"),
            weather: Translation.tr("Weather") })[id] || id
    }
    function classicZoneLabel(z) {
        return ({ left: Translation.tr("Left edge"), centerLeft: Translation.tr("Center left"),
            center: Translation.tr("Center"), centerRight: Translation.tr("Center right"),
            right: Translation.tr("Right edge") })[z] || z
    }
    function classicZoneIcon(z) {
        return ({ left: "first_page", centerLeft: "align_horizontal_left", center: "align_horizontal_center",
            centerRight: "align_horizontal_right", right: "last_page" })[z] || "widgets"
    }
    function classicIds(zone) {
        if (!root.classicMigrated) return Array.from(root.classicDefaults[zone] ?? [])
        const a = Config.options?.material?.bar?.layout?.[zone]
        const ids = (a && a.length >= 0) ? Array.from(a) : Array.from(root.classicDefaults[zone] ?? [])
        const hasActiveWindow = root.classicZones.some(name =>
            (Config.options?.material?.bar?.layout?.[name] ?? []).includes("activeWindow"))
        // A lone legacy "taskbar" id is the activeWindow slot; beside a real one it is a ghost.
        return ids
            .map(id => id === "taskbar" && !hasActiveWindow ? "activeWindow" : id)
            .filter(id => id !== "taskbar")
    }

    // ─── M3 (three zones) ───────────────────────────────────────────────
    readonly property var m3Zones: ["left", "middle", "right"]
    readonly property var m3Multiple: ["visualizer", "divisor"]
    readonly property var m3Widgets: [
        { id: "leftSidebarButton", name: Translation.tr("Left Sidebar Button"), icon: "left_panel_open",
            description: Translation.tr("Click: Left Sidebar") },
        { id: "rightSidebarButton", name: Translation.tr("Right Sidebar Button"), icon: "right_panel_open",
            description: Translation.tr("Click: Right Sidebar") },
        { id: "workspaces", name: Translation.tr("Workspaces"), icon: "steppers" },
        { id: "weatherBar", name: Translation.tr("Weather"), icon: "flare" },
        { id: "media", name: Translation.tr("Media"), icon: "music_note" },
        { id: "resources", name: Translation.tr("Resources"), icon: "monitoring" },
        { id: "systemIcons", name: Translation.tr("System Icons"), icon: "info" },
        { id: "networkSpeed", name: Translation.tr("Network Speed"), icon: "network_check" },
        { id: "clockWidget", name: Translation.tr("Clock"), icon: "schedule" },
        { id: "utilButtons", name: Translation.tr("Utility Buttons"), icon: "toggle_on" },
        { id: "sysTray", name: Translation.tr("Tray"), icon: "inbox" },
        { id: "batteryIndicator", name: Translation.tr("Battery"), icon: "battery_android_frame_full" },
        { id: "activeWindow", name: Translation.tr("Active Window"), icon: "subtitles" },
        { id: "powerButton", name: Translation.tr("Power Button"), icon: "power_settings_new" },
        { id: "updatesCount", name: Translation.tr("Updates"), icon: "deployed_code_update" },
        { id: "docktoPanel", name: Translation.tr("Dock to Panel"), icon: "apps" },
        { id: "visualizer", name: Translation.tr("Visualizer"), icon: "graphic_eq" },
        { id: "hyprlandXkbIndicator", name: Translation.tr("Keyboard Layout"), icon: "keyboard" },
        { id: "divisor", name: Translation.tr("Divider"), icon: "horizontal_distribute" },
        { id: "notificationUnreadCount", name: Translation.tr("Unread Notifications"), icon: "notifications",
            description: Translation.tr("Click: Right Sidebar") }
    ]
    function m3Ids(zone) {
        return Array.from(Config.options?.material?.bar?.m3?.layouts?.[zone + "Layout"] ?? [])
    }
    function m3ZoneLabel(z) {
        return ({ left: Translation.tr("Left"), middle: Translation.tr("Center"), right: Translation.tr("Right") })[z] || z
    }

    // ─── Reading, both variants ─────────────────────────────────────────
    // Every function takes an optional variant ("classic" | "m3"); without it the bar in use answers.
    function _m3(variant) { return (variant ?? root.variant) === "m3" }
    function zones(variant) { return root._m3(variant) ? root.m3Zones : root.classicZones }
    function zoneLabel(zone, variant) { return root._m3(variant) ? root.m3ZoneLabel(zone) : root.classicZoneLabel(zone) }
    function ids(zone, variant) { return root._m3(variant) ? root.m3Ids(zone) : root.classicIds(zone) }
    function catalogueIds(variant) { return root._m3(variant) ? root.m3Widgets.map(w => w.id) : root.classicKnownIds }
    function multipleAllowed(id, variant) { return root._m3(variant) ? root.m3Multiple.includes(id) : id === "spacer" }
    function info(id, variant) {
        if (root._m3(variant)) {
            const w = root.m3Widgets.find(widget => widget.id === id)
            return { name: w?.name ?? id, icon: w?.icon ?? "widgets", description: w?.description ?? "" }
        }
        return { name: root.classicLabel(id), icon: root.classicIcon(id), description: "" }
    }
    function placed(variant) {
        let all = []
        const z = root.zones(variant)
        for (let i = 0; i < z.length; i++) all = all.concat(root.ids(z[i], variant))
        return all
    }
    // Catalogue ids that are not on the bar (reusable ones are always offered).
    function available(variant) {
        const on = root.placed(variant)
        return root.catalogueIds(variant).filter(id => root.multipleAllowed(id, variant) || !on.includes(id))
    }

    // ─── Writing ────────────────────────────────────────────────────────
    // next: { zone: ids } for the zones that changed.
    function _commit(next, variant) {
        const u = {}
        if (root._m3(variant)) {
            // A manual change makes the layout custom and mirrors it, as the Settings editor does.
            u["material.bar.m3.layoutMode"] = "custom"
            u["material.bar.m3.customLayoutSaved"] = true
            for (const z of root.m3Zones) {
                const list = next[z] ?? root.m3Ids(z)
                u["material.bar.m3.layouts." + z + "Layout"] = list
                u["material.bar.m3.customLayouts." + z + "Layout"] = list
            }
        } else {
            if (!root.classicMigrated) {
                for (const z of root.classicZones)
                    u["material.bar.layout." + z] = Array.from(root.classicDefaults[z])
                u["material.bar.layout.migrated"] = true
            }
            for (const z of Object.keys(next))
                u["material.bar.layout." + z] = next[z]
        }
        Config.setNestedValues(u)
    }
    function resetClassic() {
        const u = { "material.bar.layout.migrated": true }
        for (const z of root.classicZones)
            u["material.bar.layout." + z] = Array.from(root.classicDefaults[z])
        Config.setNestedValues(u)
    }

    // Replace one zone's list as it is (the Settings list editors hand over whole lists).
    function setIds(zone, list, variant) {
        const next = {}
        next[zone] = Array.from(list ?? [])
        root._commit(next, variant)
    }
    function move(fromZone, fromIndex, toZone, toIndex, variant) {
        const src = root.ids(fromZone, variant)
        if (!root.zones(variant).includes(toZone) || fromIndex < 0 || fromIndex >= src.length)
            return false
        const moved = src.splice(fromIndex, 1)[0]
        const same = fromZone === toZone
        const dst = same ? src : root.ids(toZone, variant)
        let at = toIndex
        if (same && at > fromIndex) at--
        at = Math.max(0, Math.min(at, dst.length))
        if (same && at === fromIndex) return false
        dst.splice(at, 0, moved)
        const next = {}
        next[fromZone] = src
        next[toZone] = dst
        root._commit(next, variant)
        return true
    }
    function remove(zone, index, variant) {
        const list = root.ids(zone, variant)
        if (index < 0 || index >= list.length) return false
        list.splice(index, 1)
        const next = {}
        next[zone] = list
        root._commit(next, variant)
        return true
    }
    function add(id, zone, index, variant) {
        if (!root.zones(variant).includes(zone) || !root.catalogueIds(variant).includes(id)) return false
        if (!root.multipleAllowed(id, variant) && root.placed(variant).includes(id)) return false
        const list = root.ids(zone, variant)
        const at = (index === undefined || index < 0) ? list.length : Math.max(0, Math.min(index, list.length))
        list.splice(at, 0, id)
        const next = {}
        next[zone] = list
        root._commit(next, variant)
        return true
    }

    // Rect of an item in screen coordinates. A layer-shell window does not know where it sits, but a
    // bar is full width on its edge, so the origin follows from the window and the screen.
    function screenRect(item, win, screen, bottom) {
        if (!item || !win) return ({ x: 0, y: 0, width: 0, height: 0 })
        const outW = screen?.width > 0 ? screen.width : win.width
        const outH = screen?.height > 0 ? screen.height : win.height
        const originX = win.width >= outW - 2 ? 0 : (outW - win.width) / 2
        const originY = bottom ? outH - win.height : 0
        const p = item.mapToItem(null, 0, 0)
        return { x: originX + p.x, y: originY + p.y, width: item.width, height: item.height }
    }
}
