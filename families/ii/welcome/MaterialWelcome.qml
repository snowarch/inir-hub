import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.welcome

// Material's part of the first-run wizard: its starting profiles, style presets, where its bar and dock go and how
// its sidebars open. The wizard draws the steps and writes what a profile or preset answers.
Item {
    id: root

    // The starting point runs before Appearance and Layout: a profile writes
    // composition keys wholesale and would overwrite anything refined earlier.
    readonly property var steps: [
        {
            icon: "tune", title: Translation.tr("Starting point"),
            headline: Translation.tr("Choose your starting setup"),
            subtitle: Translation.tr("Start simple, balanced or with more tools. You can change every module later.")
        },
        {
            icon: "palette", title: Translation.tr("Appearance"),
            headline: Translation.tr("Make it yours"),
            subtitle: Translation.tr("Wallpaper sets the colors. Style sets the shape and feel.")
        },
        {
            icon: "dashboard", title: Translation.tr("Layout"),
            headline: Translation.tr("Arrange the desktop"),
            subtitle: Translation.tr("Choose where the bar and dock go.")
        }
    ]
    // Where its bar and dock go.
    readonly property var placementRows: [
        { label: Translation.tr("Bar position"), key: "material.bar.bottom", fallback: false, options: [
            { displayName: Translation.tr("Top"), icon: "vertical_align_top", value: false },
            { displayName: Translation.tr("Bottom"), icon: "vertical_align_bottom", value: true }] },
        { label: Translation.tr("Dock position"), key: "material.dock.position", fallback: "bottom", options: [
            { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: "bottom" },
            { displayName: Translation.tr("Left"), icon: "arrow_back", value: "left" },
            { displayName: Translation.tr("Right"), icon: "arrow_forward", value: "right" }] }
    ]

    readonly property Component layoutExtra: Component { MaterialWelcomeSidebars {} }

    // Starting profiles: the wizard writes what `profileValues` answers for the one picked.
    readonly property var profileChoices: [
        { id: "minimum", name: Translation.tr("Minimum"), icon: "filter_1",
            detail: Translation.tr("Core controls with no desktop widgets."),
            description: Translation.tr("Core bar, sidebars and local controls. No desktop widgets.") },
        { id: "balanced", name: Translation.tr("Balanced"), icon: "tune", badge: Translation.tr("Recommended"),
            detail: Translation.tr("Sidebars, daily toggles and a desktop clock."),
            description: Translation.tr("Useful sidebars, eight everyday toggles and one desktop clock.") },
        { id: "full", name: Translation.tr("Full"), icon: "auto_awesome",
            detail: Translation.tr("More local tools, fuller sidebars and a system monitor."),
            description: Translation.tr("More local tools, richer sidebars and a small system monitor.") }
    ]

    function profileValues(profile: string): var {
        return Object.assign({}, root.profileEssentials, root.profileComposition(profile), {
            "material.sidebar.left.tabOrder": root.profileTabOrder
        })
    }

    // Style presets: the wizard sets `globalStyle` through ThemeService, then writes what `styleValues` answers.
    function styleValues(id: string, profile: string): var {
        const preset = root.stylePresets.find(entry => entry.id === id)
        return Object.assign({}, preset?.values ?? {}, id === "material" ? root.flowM3Layout(profile) : {})
    }

    readonly property var stylePresets: [
        {
            id: "material", name: Translation.tr("Flow"), icon: "category",
            globalStyle: "material",
            description: Translation.tr("Clean Material surfaces with the M3 bar and dock."),
            values: {
                "material.style.iiMotionProfile": "contextual",
                "material.bar.appearanceStyle": "m3",
                "material.bar.m3.borderless": "pills",
                "material.bar.m3.showBackground": true,
                "material.bar.showBackground": true,
                "material.bar.opacity": 1.0,
                "material.dock.style": "m3",
                "material.dock.showBackground": true,
                "material.sidebar.style": "panel"
            }
        },
        {
            id: "cookie", name: Translation.tr("Expressive"), icon: "interests",
            globalStyle: "cookie",
            description: Translation.tr("Playful shapes, joined controls and a pill dock."),
            values: {
                "material.style.iiMotionProfile": "contextual",
                "material.bar.appearanceStyle": "pill",
                "material.bar.pill.barMode": false,
                "material.bar.pill.musicViz": false,
                "material.bar.pill.soul.enable": true,
                "material.bar.pill.soul.style": "orb",
                "material.bar.showBackground": true,
                "material.bar.opacity": 1.0,
                "material.dock.style": "pill",
                "material.dock.showBackground": true,
                "material.sidebar.style": "panel"
            }
        },
        {
            id: "aurora", name: Translation.tr("Glass"), icon: "blur_on",
            globalStyle: "aurora",
            description: Translation.tr("Translucent islands for the bar, dock and sidebars."),
            values: {
                "material.style.iiMotionProfile": "contextual",
                "material.bar.appearanceStyle": "islands",
                "material.bar.showBackground": true,
                "material.bar.opacity": 1.0,
                "material.dock.style": "island",
                "material.dock.showBackground": true,
                "material.sidebar.style": "island"
            }
        },
        {
            id: "inir", name: "iNiR", icon: "terminal",
            globalStyle: "inir",
            description: Translation.tr("Sharp framed surfaces with a denser, technical feel."),
            values: {
                "material.style.iiMotionProfile": "classic",
                "material.bar.appearanceStyle": "frame",
                "material.bar.showBackground": true,
                "material.bar.opacity": 1.0,
                "material.dock.style": "panel",
                "material.dock.showBackground": true,
                "material.sidebar.style": "panel"
            }
        },
        {
            id: "cards", name: Translation.tr("Cards"), icon: "branding_watermark",
            globalStyle: "cards",
            description: Translation.tr("Soft rounded cards with familiar desktop structure."),
            values: {
                "material.style.iiMotionProfile": "contextual",
                "material.bar.appearanceStyle": "classic",
                "material.bar.showBackground": true,
                "material.bar.opacity": 1.0,
                "material.dock.style": "panel",
                "material.dock.showBackground": true,
                "material.sidebar.style": "panel"
            }
        },
        {
            id: "angel", name: Translation.tr("Angel"), icon: "raven",
            globalStyle: "angel",
            description: Translation.tr("Scenic glass, strong accents and a pill dock."),
            values: {
                "material.style.iiMotionProfile": "contextual",
                "material.style.angelSubStyle": "frost",
                "material.bar.appearanceStyle": "scenic",
                "material.bar.showBackground": true,
                "material.bar.opacity": 1.0,
                "material.dock.style": "pill",
                "material.dock.showBackground": true,
                "material.sidebar.style": "panel"
            }
        },
        {
            id: "regalia", name: Translation.tr("Regalia"), icon: "event_seat",
            globalStyle: "regalia",
            description: Translation.tr("Structured surfaces, a classic bar and a macOS-style dock."),
            values: {
                "material.style.iiMotionProfile": "classic",
                "material.bar.appearanceStyle": "classic",
                "material.bar.showBackground": true,
                "material.bar.opacity": 1.0,
                "material.dock.style": "macos",
                "material.dock.showBackground": true,
                "material.sidebar.style": "panel"
            }
        },
        {
            id: "zzz", name: "ZZZ", icon: "bolt",
            globalStyle: "zzz",
            description: Translation.tr("Poster-like surfaces with bold graphic contrast."),
            values: {
                "material.style.iiMotionProfile": "classic",
                "material.bar.appearanceStyle": "classic",
                "material.bar.showBackground": true,
                "material.bar.opacity": 1.0,
                "material.dock.style": "panel",
                "material.dock.showBackground": true,
                "material.sidebar.style": "panel"
            }
        },
        {
            id: "editorial", name: Translation.tr("Editorial"), icon: "auto_stories",
            globalStyle: "editorial",
            description: Translation.tr("Quiet paper-like surfaces led by typography."),
            values: {
                "material.style.iiMotionProfile": "contextual",
                "material.bar.appearanceStyle": "classic",
                "material.bar.showBackground": true,
                "material.bar.opacity": 1.0,
                "material.dock.style": "panel",
                "material.dock.showBackground": true,
                "material.sidebar.style": "panel"
            }
        }
    ]

    function flowM3Layout(profile: string): var {
        if (profile === "minimum")
            return {
                "material.bar.m3.layoutMode": "custom",
                "material.bar.m3.layouts.leftLayout": ["leftSidebarButton", "workspaces"],
                "material.bar.m3.layouts.middleLayout": ["docktoPanel"],
                "material.bar.m3.layouts.rightLayout": ["clockWidget", "systemIcons", "rightSidebarButton"]
            }
        return {
            "material.bar.m3.layoutMode": "compact",
            "material.bar.m3.layouts.leftLayout": ["leftSidebarButton", "media", "workspaces"],
            "material.bar.m3.layouts.middleLayout": ["docktoPanel"],
            "material.bar.m3.layouts.rightLayout": ["utilButtons", "weatherBar", "clockWidget", "systemIcons", "rightSidebarButton"]
        }
    }

    // Every starting profile prepares shared services and Material's own pieces; the other families' sections are
    // left alone.
    readonly property var profileEssentials: ({
        "material.dock.enable": true,
        "material.dock.hoverToReveal": false,
        "material.dock.pinnedOnStartup": true,
        "material.dashboard.enable": true,
        "weather.enable": true,
        "material.bar.modules.weather": true,
        "material.bar.modules.battery": true,
        "material.bar.modules.sysTray": true,
        "material.bar.modules.clock": true,
        "material.bar.modules.workspaces": true,
        "material.bar.modules.activeWindow": true,
        "material.bar.modules.leftSidebarButton": true,
        "material.bar.modules.rightSidebarButton": true,
        "sounds.notifications": true,
        "gameMode.autoDetect": true,
        "audio.protection.enable": true,
        "material.sidebar.collapseEmptyNotifications": false,
        "material.sidebar.collapseWidgetsTab": false,
        "material.sidebar.right.headerBanner": "wallpaper",
        "material.sidebar.right.sectionOrder": ["system", "sliders", "toggles", "notifications", "widgets"],
        "material.sidebar.quickToggles.style": "android",
        "material.sidebar.quickToggles.android.columns": 4,
        // Material II's embedded bar taskbar duplicates the Material II dock.
        // Waffle owns a separate taskbar under `waffles.bar.*` and is unaffected.
        "material.bar.modules.taskbar": false
    })

    // Ordering only; no profile enables a provider-backed tab.
    readonly property var profileTabOrder: [
        "widgets", "wallhaven", "news", "tools", "software",
        "ai", "translator", "anime", "animeSchedule", "ytmusic"
    ]

    // Desktop widgets all default to the same corner and "leastBusy" cannot see
    // a sibling, so a profile composing more than one must place them by hand.
    function profileComposition(profile: string): var {
        if (profile === "minimum")
            return {
                "material.bar.modules.resources": false,
                "material.bar.modules.utilButtons": false,
                "material.bar.modules.media": false,
                "material.bar.m3.layoutMode": "custom",
                "material.bar.m3.layouts.leftLayout": ["leftSidebarButton", "workspaces"],
                "material.bar.m3.layouts.middleLayout": ["docktoPanel"],
                "material.bar.m3.layouts.rightLayout": ["clockWidget", "systemIcons", "rightSidebarButton"],
                "news.enable": false,
                "wallhaven.enable": false,
                "ytmusic.enable": false,
                "material.sidebar.tools.enable": false,
                "material.sidebar.software.enable": false,
                "material.sidebar.widgets.context": true,
                "material.sidebar.widgets.week": true,
                "material.sidebar.widgets.media": true,
                "material.sidebar.widgets.controls": false,
                "material.sidebar.widgets.status": false,
                "material.sidebar.widgets.wallpaper": true,
                "material.sidebar.widgets.note": false,
                "material.sidebar.widgets.launch": false,
                "material.sidebar.widgets.worldClock": false,
                "material.sidebar.right.enabledWidgets": ["calendar", "todo"],
                "material.sidebar.quickToggles.android.toggles": [
                    { "size": 1, "type": "network" },
                    { "size": 1, "type": "bluetooth" },
                    { "size": 1, "type": "audio" },
                    { "size": 1, "type": "mic" }
                ],
                "background.widgets.clock.enable": false,
                "background.widgets.clock.quote.enable": false,
                "background.widgets.visualizer.enable": false,
                "background.widgets.systemMonitor.enable": false,
                "background.widgets.weather.enable": false,
                "background.widgets.battery.enable": false,
                "background.widgets.mediaControls.enable": false,
                "background.widgets.calendarUpcoming.enable": false,
                "mascot.enable": false
            }
        if (profile === "full")
            return {
                "material.bar.modules.resources": true,
                "material.bar.modules.utilButtons": true,
                "material.bar.modules.media": true,
                "material.bar.m3.layoutMode": "compact",
                "material.bar.m3.layouts.leftLayout": ["leftSidebarButton", "media", "workspaces"],
                "material.bar.m3.layouts.middleLayout": ["docktoPanel"],
                "material.bar.m3.layouts.rightLayout": ["utilButtons", "weatherBar", "clockWidget", "systemIcons", "rightSidebarButton"],
                "news.enable": true,
                "wallhaven.enable": true,
                "ytmusic.enable": true,
                "material.sidebar.tools.enable": true,
                "material.sidebar.software.enable": true,
                "material.sidebar.widgets.context": true,
                "material.sidebar.widgets.week": true,
                "material.sidebar.widgets.media": true,
                "material.sidebar.widgets.controls": true,
                "material.sidebar.widgets.status": true,
                "material.sidebar.widgets.wallpaper": true,
                "material.sidebar.widgets.note": true,
                "material.sidebar.widgets.launch": true,
                "material.sidebar.widgets.worldClock": true,
                "material.sidebar.right.enabledWidgets": [
                    "calendar", "events", "todo", "notepad",
                    "calculator", "sysmon", "weather", "timer"
                ],
                "material.sidebar.quickToggles.android.toggles": [
                    { "size": 1, "type": "network" },
                    { "size": 1, "type": "bluetooth" },
                    { "size": 1, "type": "audio" },
                    { "size": 1, "type": "mic" },
                    { "size": 1, "type": "nightLight" },
                    { "size": 1, "type": "screenSnip" },
                    { "size": 1, "type": "colorPicker" },
                    { "size": 1, "type": "idleInhibitor" }
                ],
                "background.widgets.clock.enable": true,
                "background.widgets.clock.placementStrategy": "topRight",
                "background.widgets.clock.quote.enable": false,
                "background.widgets.visualizer.enable": false,
                "background.widgets.clock.backgroundOpacity": 0,
                "background.widgets.clock.borderOpacity": 0.08,
                "background.widgets.systemMonitor.enable": true,
                "background.widgets.systemMonitor.placementStrategy": "bottomRight",
                "background.widgets.weather.enable": false,
                "background.widgets.battery.enable": false,
                "background.widgets.mediaControls.enable": false,
                "background.widgets.calendarUpcoming.enable": false,
                "mascot.enable": false
            }
        return {
            "material.bar.modules.resources": true,
            "material.bar.modules.utilButtons": true,
            "material.bar.modules.media": true,
            "material.bar.m3.layoutMode": "compact",
            "material.bar.m3.layouts.leftLayout": ["leftSidebarButton", "media", "workspaces"],
            "material.bar.m3.layouts.middleLayout": ["docktoPanel"],
            "material.bar.m3.layouts.rightLayout": ["utilButtons", "weatherBar", "clockWidget", "systemIcons", "rightSidebarButton"],
            "news.enable": true,
            "wallhaven.enable": true,
            "ytmusic.enable": false,
            "material.sidebar.tools.enable": false,
            "material.sidebar.software.enable": false,
            "material.sidebar.widgets.context": true,
            "material.sidebar.widgets.week": true,
            "material.sidebar.widgets.media": true,
            "material.sidebar.widgets.controls": true,
            "material.sidebar.widgets.status": true,
            "material.sidebar.widgets.wallpaper": true,
            "material.sidebar.widgets.note": false,
            "material.sidebar.widgets.launch": false,
            "material.sidebar.widgets.worldClock": false,
            "material.sidebar.right.enabledWidgets": [
                "calendar", "events", "todo", "notepad", "weather"
            ],
            "material.sidebar.quickToggles.android.toggles": [
                { "size": 1, "type": "network" },
                { "size": 1, "type": "bluetooth" },
                { "size": 1, "type": "audio" },
                { "size": 1, "type": "mic" },
                { "size": 1, "type": "nightLight" },
                { "size": 1, "type": "screenSnip" },
                { "size": 1, "type": "colorPicker" },
                { "size": 1, "type": "idleInhibitor" }
            ],
            // One widget is enough for a fresh desktop, and a named zone keeps
            // the placement deterministic across common output sizes.
            "background.widgets.clock.enable": true,
            "background.widgets.clock.placementStrategy": "topRight",
            "background.widgets.clock.quote.enable": false,
            "background.widgets.clock.backgroundOpacity": 0,
            "background.widgets.clock.borderOpacity": 0.08,
            "background.widgets.visualizer.enable": false,
            "background.widgets.systemMonitor.enable": false,
            "background.widgets.weather.enable": false,
            "background.widgets.battery.enable": false,
            "background.widgets.mediaControls.enable": false,
            "background.widgets.calendarUpcoming.enable": false,
            "mascot.enable": false
        }
    }
}
