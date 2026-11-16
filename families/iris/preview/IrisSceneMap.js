.pragma library

// Which scene shows a Settings group: "area/Group" first, then the area's own. One owner for every host that asks
// before it draws (Prism decides which cards carry a picture from it, IrisGroupPreview loads it).
function sceneFor(section, group) {
    if (group.length === 0)
        return ({ dock: "dock", player: "player", desktop: "widgets", widgets: "widgets", sidebars: "panels", controlCenter: "controlCenter", spotlight: "spotlight", bubbles: "bubbles",
            bar: "islandEdge", appearance: "fusion", colour: "palette", wallpaper: "gallery", login: "login", motion: "motion", lock: "lock", notifications: "feedback",
            windows: "windows", orbit: "orbit", general: "general", capture: "capture", sound: "sound", display: "display",
            keyboard: "keyboard", pointer: "pointer", battery: "battery", gaming: "gaming", anime: "anime", sources: "sources", system: "hub" })[section] ?? ""
    const key = section + "/" + group
    return ({
        "sidebars/Focus": "panels", "sidebars/Today": "panels", "sidebars/Panel look": "panels",
        "bar/Visibility": "islandReserve", "bar/Interaction": "islandInteraction",
        "bar/Shape": "islandEdge", "bar/Layout": "islandEdge", "bar/Bar": "barZones",
        "appearance/Light": "light", "appearance/Shape": "shapes", "appearance/Glass": "glass", "appearance/Edges": "glass",
        "appearance/Menus": "menus", "general/Settings window": "settings",
        "appearance/Texture": "texture", "appearance/Material": "material", "appearance/Design": "fusion",
        "appearance/Adaptive": "fusion",
        "appearance/Faces": "typography", "appearance/Text": "typography", "appearance/Frame": "frame",
        "colour/Colour theme": "palette", "colour/Scheme": "palette", "colour/Accent": "palette", "colour/Highlight": "highlight",
        "colour/App colours": "palette", "colour/Dark look": "palette", "colour/Ink look": "palette", "colour/Light look": "palette",
        "colour/Wallpaper tint": "palette",
        "appearance/App colours": "palette", "windows/Layout": "windows", "windows/Glass behind apps": "windows",
        "login/Login Screen": "login",
        "desktop/Desktop menu": "menus",
        "motion/Motion": "motion", "motion/Curve": "motion", "motion/Timing": "motion",
        "motion/Touch": "motion",
        "player/Frame music": "frame", "player/Frame response": "frame", "player/Frame finish": "frame",
        "lock/Scene": "lock", "lock/Type": "lock", "lock/Clock": "lock", "lock/At a glance": "lock",
        "lock/Now playing": "lock", "lock/Activity": "lock", "lock/Sign in": "lock", "lock/Status": "lock",
        "bar/Desktop page": "islandPage", "bar/Pages": "islandPage", "bar/Player page": "islandPage",
        "bubbles/Behaviour": "bubbles", "bubbles/Floating": "bubbles", "bubbles/On the contour": "bubbles", "bubbles/Size": "bubbles",
        "bubbles/Cards": "cards", "bubbles/Card contents": "cards", "bubbles/Joining": "joining", "bubbles/Tray": "tray",
        "dock/Visibility": "dock", "dock/Icons": "dock", "dock/Look": "dock",
        "desktop/Widgets": "widgets", "wallpaper/Overview backdrop": "backdrop", "wallpaper/Wallpaper gallery": "gallery",
        "spotlight/Spotlight": "spotlight", "controlCenter/Control Center": "controlCenter",
        "sidebars/Panel look": "panels",
        "notifications/Banners": "feedback", "sound/Feedback": "feedback",
        "player/Player": "player", "player/Bubble": "player",
        "display/Night Light": "display", "display/Comfort": "display",
    })[key] ?? ""
}

// Whether a page's own scene may stand in for a group with none of its own. Display's draws Night Light and bright
// flashes: the Screen card draws the screens themselves in its rows, and a warm window there misread as the screen.
function standsIn(section) {
    return section !== "display"
}
