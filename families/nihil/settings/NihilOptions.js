.pragma library

// Every option NiHiL offers, page by page. Settings draws its rows from this list and nothing else, so an option exists
// for people the moment it is written here. Keys are relative to `nihil.`.

function toggle(key, label, note) {
    return { type: "switch", key: key, label: label, note: note || "" }
}

function choice(key, label, options, note) {
    return { type: "choice", key: key, label: label, note: note || "",
             options: options.map(function (option) { return { value: option[0], label: option[1] } }) }
}

// `unit`: "percent", "px", "ms", "times" or "". `extra` may hold `fit` (the value that means automatic) and `fitLabel`.
function level(key, label, from, to, step, unit, note, extra) {
    var row = { type: "level", key: key, label: label, note: note || "", from: from, to: to, step: step, unit: unit || "" }
    if (extra) {
        row.fit = extra.fit
        row.fitLabel = extra.fitLabel
    }
    return row
}

// A setting of the compositor itself (a row of CompositorRows), written to Niri's or Umbriel's own config.
function compositor(comp, key, label, kind, note, range) {
    var row = { type: "compositor", comp: comp, key: key, label: label, note: note || "", kind: kind, options: [] }
    if (range) {
        row.from = range[0]; row.to = range[1]; row.step = range[2]; row.unit = range[3] || ""
    }
    return row
}

function screens(key, label, note) {
    return { type: "screens", key: key, label: label, note: note || "" }
}

// A setting of the shell itself, kept at its full path in the config (not under `nihil.`); `fallback` is how iNiR
// ships it. `more` may hold `note`, `options` as [value, label] pairs, `from`, `to`, `step`, `unit`, `fit`/`fitLabel`,
// `placeholder`, `source` (choices read live: "languages", "iconThemes", "screens", "families") and `when` (a path that
// must be on, "!path" off, or "path=value").
function system(path, label, kind, fallback, more) {
    var row = { type: kind, base: true, key: path, label: label, note: "", fallback: fallback, options: [] }
    for (var name in (more || {}))
        row[name] = more[name]
    row.options = row.options.map(function (option) { return { value: option[0], label: option[1] } })
    return row
}

// One thing to do instead of a value: `act` names it for Settings (see NihilSettingsApp.act).
function action(act, label, note, button) {
    return { type: "action", act: act, label: label, note: note || "", button: button }
}

// A whole group of the compositor's own settings (CompositorRows), as Niri or Umbriel can do them right now.
function compositorGroup(title, group) {
    return { title: title, group: group, rows: [] }
}

var idleTimes = [[0, "Never"], [60, "1 min"], [120, "2 min"], [300, "5 min"], [600, "10 min"], [900, "15 min"],
                 [1800, "30 min"], [3600, "1 hour"]]

var fitted = { fit: 0, fitLabel: "Fit" }
var fittedLow = { fit: -1, fitLabel: "Fit" }
var hiddenAtZero = { fit: 0, fitLabel: "Hidden" }

var edges = [["left", "Left"], ["right", "Right"], ["top", "Top"], ["bottom", "Bottom"], ["hidden", "Hidden"]]
var arrivals = [["default", "Default"], ["none", "None"], ["left", "From the left"], ["right", "From the right"],
                ["up", "From above"], ["down", "From below"]]
var corners = [["topLeft", "Top left"], ["top", "Top"], ["topRight", "Top right"], ["bottomLeft", "Bottom left"],
               ["bottom", "Bottom"], ["bottomRight", "Bottom right"]]
var superActions = [["none", "Nothing"], ["follow", "Open or close the overview"], ["windows", "Windows"], ["apps", "App grid"],
                    ["staticWindows", "Windows in place"], ["staticWorkspace", "Workspace in place"],
                    ["searchWindows", "Search windows"], ["recentFiles", "Recent files"]]
var windowActions = [["none", "Nothing"], ["activate", "Focus it"], ["close", "Close it"], ["minimize", "Minimize it"],
                     ["next", "Send to next workspace"], ["search", "Search its title"], ["thumbnail", "Pin as thumbnail"]]

var pages = [
    {
        id: "profiles", summary: "Start from a whole desktop layout", title: "Profiles", glyph: "dashboard_customize", view: "profiles"
    },
    {
        id: "layout", summary: "Where the rail, the dash and the workspaces sit", title: "Layout", glyph: "desktop",
        sections: [
            { title: "Rail", rows: [
                choice("panel.position", "Edge", [["left", "Left"], ["right", "Right"], ["top", "Top"], ["bottom", "Bottom"]]),
                choice("panel.style", "Style", [["float", "Floating"], ["edge", "Against the edge"]]),
                level("panel.thickness", "Thickness", 40, 72, 1, "px"),
                level("panel.margin", "Space from the edge", 0, 32, 1, "px", "Only while it floats"),
                choice("panel.visibility", "Shown", [["always", "Always"], ["desktop", "On an empty desktop"],
                                                     ["overview", "In the overview"], ["hidden", "Never"]]),
                choice("panel.overviewStyle", "In the overview", [["same", "Keep the glass"], ["transparent", "Transparent"]]),
                toggle("panel.windows", "Open windows", "The workspace's windows as icons; middle click closes one"),
                level("panel.windowsMax", "Windows shown", 1, 16, 1, ""),
                toggle("panel.tray", "Tray"),
                screens("panel.screenList", "Screens", "With none marked it shows on all of them")
            ] },
            { title: "Deck", rows: [
                choice("deck.sidebar", "Side", [["full", "Names and marks"], ["icons", "Marks only"]]),
                level("deck.dim", "Dim the desktop behind", 0, 0.6, 0.01, "percent"),
                toggle("modules.media", "Media page"),
                toggle("modules.focus", "Focus page", "Tasks, a timer and a note")
            ] },
            { title: "Dash", rows: [
                choice("dash.position", "Position", edges),
                level("dash.adjust", "Shift along the edge", -1, 1, 0.05),
                toggle("dash.centerToWorkspaces", "Centre on the workspace preview"),
                level("dash.iconSize", "Icon size", 16, 96, 1, "px", "", fitted),
                choice("dash.showApps", "App grid key", [["start", "First"], ["end", "Last"], ["hidden", "Hidden"]]),
                toggle("dash.runningDots", "Mark running apps"),
                choice("dash.runningStyle", "Running mark", [["dot", "Dot"], ["line", "Line"]]),
                choice("dash.tone", "Tone", [["default", "Palette"], ["light", "Light"], ["dark", "Dark"]]),
                level("dash.opacity", "Glass opacity", 0, 1, 0.05, "percent"),
                level("dash.radius", "Corner radius", 0, 48, 1, "px")
            ] },
            { title: "Dock", rows: [
                choice("dock.position", "Position", [["bottom", "Bottom"], ["left", "Left"], ["right", "Right"]]),
                choice("dock.visibility", "Shown", [["always", "Always"], ["desktop", "On an empty desktop"],
                                                    ["hover", "Only at the pointer"]],
                       "Away, it comes back when the pointer reaches the edge"),
                level("dock.iconSize", "Icon size", 16, 96, 1, "px"),
                choice("dock.tone", "Tone", [["default", "Palette"], ["light", "Light"], ["dark", "Dark"]]),
                level("dock.opacity", "Glass opacity", 0, 1, 0.05, "percent"),
                level("dock.radius", "Corner radius", 0, 48, 1, "px"),
                level("dock.margin", "Space from the edge", 0, 48, 1, "px"),
                screens("dock.screenList", "Screens", "With none marked it shows on all of them")
            ] },
            { title: "Workspace strip", rows: [
                choice("thumbnails.position", "Position", edges),
                level("thumbnails.adjust", "Shift along the edge", -1, 1, 0.05),
                level("thumbnails.scale", "Size", 0.05, 0.3, 0.01, "percent"),
                toggle("thumbnails.fullLength", "Glass along the whole edge"),
                toggle("thumbnails.background", "Glass behind the strip"),
                choice("thumbnails.labels", "Labels", [["none", "None"], ["index", "Number"], ["indexApp", "Number and app"],
                                                       ["app", "App"], ["name", "Workspace name"], ["windowTitle", "Window title"]]),
                toggle("thumbnails.labelsOnHover", "Labels only under the pointer"),
                choice("thumbnails.closeButton", "Close workspace key", [["hidden", "Hidden"], ["click", "One click"],
                                                                         ["doubleClick", "Double click"], ["ctrlClick", "Ctrl and click"]])
            ] },
            { title: "Other screens", rows: [
                choice("thumbnails.secondaryPosition", "Strip position", [["same", "Same as the main screen"], ["start", "Start"],
                                                                          ["end", "End"], ["hidden", "Hidden"]]),
                level("thumbnails.secondaryScale", "Strip size", 0.05, 0.3, 0.01, "percent"),
                level("thumbnails.secondaryAdjust", "Strip shift", -1, 1, 0.05),
                level("stage.secondaryScale", "Workspace size", 0.5, 1, 0.01, "percent"),
                toggle("stage.secondaryShift", "Leave room for the strip")
            ] },
            { title: "Workspace preview", rows: [
                level("stage.scale", "Size", 0.5, 1, 0.01, "percent"),
                level("stage.radius", "Corner radius", 0, 60, 1, "px"),
                level("stage.spacing", "Space between workspaces", 0, 120, 1, "px"),
                toggle("stage.adjacent", "Show the workspaces beside it"),
                toggle("stage.background", "Wallpaper on each workspace")
            ] },
            { title: "Search", rows: [
                toggle("search.showEntry", "Always show the search field"),
                toggle("search.center", "Centre the field"),
                level("search.width", "Width", 0.5, 2, 0.05, "times"),
                level("search.maxRows", "Rows for each kind of result", 1, 20, 1)
            ] },
            { title: "Workspace switcher", rows: [
                choice("switcher.popup", "Popup", [["off", "Off"], ["current", "Focused screen"], ["all", "Every screen"]]),
                choice("switcher.popupScope", "Popup draws", [["all", "Every workspace"], ["active", "Only the one reached"]]),
                choice("switcher.mode", "Movement", [["default", "Spring"], ["static", "Jump"]]),
                choice("switcher.animation", "Popup arrives", arrivals),
                toggle("switcher.wrap", "Wrap around at the ends"),
                toggle("switcher.ignoreLast", "Skip the empty last workspace"),
                level("switcher.horizontal", "Horizontal position", 0, 1, 0.01, "percent"),
                level("switcher.vertical", "Vertical position", 0, 1, 0.01, "percent"),
                level("switcher.timeout", "Stays for", 100, 3000, 50, "ms")
            ] }
        ]
    },
    {
        id: "appearance", summary: "Colour, glass, shape and type", title: "Appearance", glyph: "palette",
        sections: [
            { title: "Colour", rows: [
                choice("look.scheme", "Scheme", [["dark", "Dark"], ["light", "Light"]]),
                choice("look.palette", "Accent", [["pearl", "Pearl"], ["glacier", "Glacier"], ["sage", "Sage"], ["coral", "Coral"], ["gold", "Gold"], ["wallpaper", "From the wallpaper"]], "What is chosen wears it: the page, the workspace, the key that is on")
            ] },
            { title: "Glass", rows: [
                choice("look.material", "Material", [["smoke", "Smoked"], ["frost", "Frosted"], ["fluted", "Fluted"], ["prism", "Prism"]]),
                level("look.ribs", "Rib width", 6, 32, 1, "px", "How wide each reed of fluted glass is"),
                level("look.glass", "Opacity", 0, 1, 0.01, "percent"),
                toggle("look.blur", "Blur what is behind"),
                level("look.grain", "Grain", 0, 1, 0.01, "percent"),
                level("look.rim", "Rim light", 0, 1, 0.01, "percent"),
                level("look.flare", "Rim flare", 0, 1, 0.01, "percent", "The light caught along the glass's edge")
            ] },
            { title: "Shape and type", rows: [
                level("look.corners", "Roundness", 0, 2, 0.05, "times"),
                level("look.scale", "Interface size", 0.75, 1.5, 0.01, "times"),
                choice("look.display", "Titles", [["geist", "Geist"], ["system", "System"]]),
                choice("look.font", "Text", [["geist", "Geist"], ["system", "System"]])
            ] },
            { title: "Field", rows: [
                choice("field.form", "Form", [[0, "Beam"], [1, "Fluted streaks"], [2, "Haze"], [3, "Void"]]),
                level("field.seed", "Variation", 0, 1, 0.01),
                level("field.glow", "Glow", 0, 2, 0.05, "times")
            ] },
            { title: "Overview stage", rows: [
                choice("overview.engine", "Overview", [["compositor", "The compositor's own"], ["shell", "Drawn by NiHiL"]],
                       "The compositor's moves live windows with no lag; NiHiL's own works anywhere"),
                choice("overview.poster", "Backdrop", [["wallpaper", "Blurred wallpaper"], ["field", "Field"], ["off", "Plain"]]),
                level("overview.posterWallpaper", "Wallpaper strength", 0, 1, 0.01, "percent"),
                compositor("layout", "overview.zoom", "Workspace size", "range", "How big the compositor draws each workspace", [0.2, 0.75, 0.05, "percent"]),
                compositor("glass", "overview", "Blur behind the overview", "switch")
            ] },
            { title: "Overview background", rows: [
                choice("overview.background", "Behind the overview", [["desktop", "Sharp wallpaper"], ["transparent", "Nothing"],
                                                                      ["blurFast", "Fast blur"], ["blurSmooth", "Smooth blur"]]),
                level("overview.backgroundBlur", "Blur", 0, 1, 0.01, "percent"),
                level("overview.backgroundBrightness", "Brightness with windows", 0, 1, 0.01, "percent"),
                toggle("overview.smoothAnimation", "Blur grows with the opening")
            ] },
            { title: "Desktop widgets", rows: [
                choice("widgets.design", "Design", [["nihil", "NiHiL"], ["material", "Material"], ["instrument", "iNstrument"], ["readout", "Readout"]])
            ] }
        ]
    },
    {
        id: "behavior", summary: "How the overview, search and keys respond", title: "Behavior", glyph: "tune",
        sections: [
            { title: "Overview", rows: [
                choice("overview.mode", "Windows", [["default", "Spread out"], ["static", "Stay in place"], ["hover", "Spread under the pointer"]]),
                choice("overview.startup", "When the session starts", [["desktop", "Desktop"], ["overview", "Overview"], ["apps", "App grid"]]),
                toggle("overview.closeOnEmptyClick", "A click on nothing closes it"),
                choice("overview.escapeKey", "Escape", [["default", "One view back"], ["close", "Close at once"]]),
                choice("overview.sortWindows", "Window order", [["position", "As laid out"], ["recent", "Last used first"], ["stable", "Oldest first"]]),
                choice("overview.selectWindow", "Selected on opening", [["pointer", "None"], ["first", "The first"], ["focused", "The focused one"],
                                                                        ["previous", "The previous one"]]),
                toggle("overview.alwaysActivateSelected", "Leaving focuses the selected window"),
                choice("overview.highlight", "Matches in results", [["bold", "Bold"], ["underline", "Underlined"], ["none", "Unmarked"]]),
                toggle("overview.pageShortcuts", "Page keys switch workspaces")
            ] },
            { title: "Super key", rows: [
                choice("overview.superKey", "One press", superActions),
                choice("overview.superKeyDouble", "Two presses", superActions)
            ] },
            { title: "Hot corner", rows: [
                choice("overview.hotCorner", "Place", [["none", "Off"], ["topLeft", "Top left"], ["topRight", "Top right"], ["bottomLeft", "Bottom left"],
                                                       ["bottomRight", "Bottom right"], ["topEdge", "Top edge"], ["bottomEdge", "Bottom edge"]]),
                choice("overview.hotCornerAction", "Opens", [["none", "Nothing"], ["windows", "Windows"], ["apps", "App grid"], ["searchWindows", "Search windows"]]),
                toggle("overview.hotCornerFullscreen", "Works over a fullscreen window"),
                toggle("overview.hotCornerRipples", "Ripple of light where it is hit")
            ] },
            { title: "Windows in the overview", rows: [
                choice("windows.iconSize", "App icon", [[64, "Large"], [48, "Medium"], [32, "Small"], [22, "Tiny"], [0, "None"]]),
                choice("windows.titlePosition", "Title", [["below", "Below, under the pointer"], ["inside", "Inside, under the pointer"], ["insideAlways", "Inside, always"],
                                                          ["top", "Above, under the pointer"], ["topAlways", "Above, always"]]),
                choice("windows.closeButton", "Close key", [["selected", "Under the pointer"], ["all", "On every window"], ["hidden", "Hidden"]]),
                level("windows.heightCompensation", "Room for the title", 0, 64, 1, "px"),
                choice("windows.iconClick", "Click on the icon", [["none", "Nothing"], ["activate", "Focus it"], ["search", "Search its title"], ["thumbnail", "Pin as thumbnail"]]),
                choice("windows.middleClick", "Middle click", windowActions),
                choice("windows.rightClick", "Right click", windowActions)
            ] },
            { title: "Dash", rows: [
                choice("dash.click", "Click on an app", [["activate", "Focus or open"], ["workspaceFirst", "Go to its workspace"],
                                                         ["newWindow", "Open a new window"], ["preferCurrent", "Prefer one on this workspace"]]),
                choice("dash.scroll", "Scroll over an app", [["none", "Nothing"], ["workspace", "Switch workspace"], ["cycleWindows", "Its windows here"],
                                                             ["cycleWindowsAll", "Its windows everywhere"]]),
                toggle("dash.isolateWorkspace", "Only apps on this workspace"),
                toggle("dash.windowSearchScroll", "Scroll moves through window results"),
                toggle("dash.menuForceQuit", "Menu offers force quit"),
                toggle("dash.menuCloseOnWorkspace", "Menu offers closing on this workspace"),
                toggle("dash.menuMoveApp", "Menu offers moving the app here"),
                toggle("dash.menuThumbnail", "Menu offers a floating thumbnail")
            ] },
            { title: "Motion", rows: [
                level("look.motion", "Amount of movement", 0, 2, 0.05, "times", "At zero nothing animates"),
                level("motion.speed", "Animation length", 0.25, 3, 0.05, "times", "Under one is faster"),
                choice("motion.workspaces", "Live workspaces", [["none", "None"], ["activeOnly", "Only the active one"], ["all", "All of them"]])
            ] },
            { title: "Windows asking for attention", rows: [
                choice("attention.mode", "When one asks", [["show", "Notify"], ["focus", "Go to it"], ["hide", "Ignore it"]]),
                toggle("attention.favoritesNotify", "Notify only for pinned apps")
            ] }
        ]
    },
    {
        id: "apps", summary: "How the app grid is laid out and sorted", title: "App grid", glyph: "apps",
        sections: [
            { title: "Pages", rows: [
                choice("apps.orientation", "Pages turn", [["workspaces", "Like the workspaces"], ["horizontal", "Sideways"], ["vertical", "Up and down"]]),
                level("apps.pageWidth", "Page width", 0.3, 1, 0.01, "percent"),
                level("apps.pageHeight", "Page height", 0.3, 1, 0.01, "percent"),
                toggle("apps.center", "Centre the icons on the page"),
                toggle("apps.pageArrows", "Page arrows"),
                toggle("apps.pageIndicators", "Page indicators"),
                toggle("apps.rememberPage", "Open on the last page used"),
                toggle("apps.incompletePages", "Keep emptied places empty"),
                choice("apps.animation", "Page turn", arrivals),
                toggle("apps.performance", "Lighter drawing for slow machines")
            ] },
            { title: "Icons", rows: [
                level("apps.iconSize", "Size", 32, 256, 1, "px", "", fittedLow),
                level("apps.columns", "Columns", 1, 16, 1, "", "", fitted),
                level("apps.rows", "Rows", 1, 12, 1, "", "", fitted),
                level("apps.spacing", "Space between icons", 0, 96, 1, "px"),
                choice("apps.names", "Names", [["ellipsized", "Shortened"], ["expanded", "Whole"], ["hidden", "Only the selected"]]),
                toggle("apps.packageBadge", "Mark Flatpak, Snap and AppImage apps")
            ] },
            { title: "What it holds", rows: [
                choice("apps.order", "Order", [["custom", "Arranged by hand"], ["name", "By name"], ["foldersFirst", "Folders first"],
                                               ["foldersLast", "Folders last"], ["usage", "Most used first"]]),
                choice("apps.content", "Apps shown", [["all", "All"], ["favoritesFirst", "Favorites and running first"], ["noFavorites", "Without favorites"],
                                                      ["noRunning", "Without running apps"], ["noFavoritesNoRunning", "Without either"]])
            ] },
            { title: "Folders", rows: [
                choice("folders.order", "Order inside", [["custom", "Arranged by hand"], ["name", "By name"], ["usage", "Most used first"]]),
                level("folders.iconSize", "Icon size", 32, 128, 1, "px", "", fittedLow),
                level("folders.columns", "Columns", 1, 8, 1, "", "", fitted),
                level("folders.rows", "Rows", 1, 8, 1, "", "", fitted),
                level("folders.spacing", "Space between icons", 0, 48, 1, "px"),
                toggle("folders.center", "Open in the centre"),
                choice("folders.previewGrid", "Preview", [[2, "Two by two"], [3, "Three by three"], [4, "Four by four"]]),
                toggle("folders.activePreview", "Preview icons open their apps"),
                choice("folders.removeButton", "Remove key", [["hidden", "Hidden"], ["click", "One click"], ["doubleClick", "Two clicks"]]),
                toggle("folders.closeButton", "Close key")
            ] },
            { title: "Search results", rows: [
                choice("results.appsMode", "Results appear", [["view", "As a list"], ["filter", "Narrowing the app grid"]]),
                toggle("results.fuzzy", "Match loosely"),
                toggle("results.includeSettings", "Include system settings"),
                toggle("results.includeWindows", "Include open windows"),
                choice("results.windowsOrder", "Open windows rank", [["first", "First"], ["last", "Last"]]),
                choice("results.activateSettings", "Choosing a window", [["default", "Focus it"], ["switch", "Go to its workspace"], ["bring", "Bring it here"]]),
                level("results.iconSize", "Larger rows", 0, 48, 1, "px")
            ] }
        ]
    },
    {
        id: "modules", summary: "Turn each part of NiHiL on or off", title: "Modules", glyph: "widgets",
        sections: [
            { title: "Surfaces", rows: [
                toggle("modules.panel", "Panel"),
                toggle("modules.dash", "Dash"),
                toggle("modules.dock", "Dock on the desktop"),
                toggle("modules.thumbnails", "Workspace strip"),
                toggle("modules.search", "Search"),
                toggle("modules.appGrid", "App grid"),
                toggle("modules.switcher", "Workspace switcher"),
                toggle("modules.hotCorner", "Hot corner"),
                toggle("modules.osd", "Volume and brightness popup"),
                toggle("modules.notifications", "Notification popups")
            ] },
            { title: "Volume and brightness popup", rows: [
                choice("osd.position", "Position", [["off", "Off"], ["center", "Centre"]].concat(corners)),
                level("osd.holdMs", "Stays for", 400, 5000, 100, "ms")
            ] },
            { title: "Notifications", rows: [
                choice("notifications.position", "Position", corners),
                level("notifications.maxVisible", "Shown at once", 1, 8, 1)
            ] },
            { title: "Lock screen", rows: [
                toggle("lock.blur", "Blur the wallpaper"),
                toggle("lock.showBattery", "Show the battery")
            ] }
        ]
    },
    {
        id: "screens", heading: "This computer", summary: "Resolution, refresh, rotation, colour and Night Light", title: "Screens", glyph: "desktop",
        sections: [
            { title: "Screen", screenPicker: true, group: "Screen", rows: [] },
            compositorGroup("Colour", "Colour"),
            { title: "Night Light", rows: [
                system("light.night.automatic", "On a schedule", "switch", false),
                system("light.night.from", "From", "text", "19:00", { when: "light.night.automatic", placeholder: "19:00" }),
                system("light.night.to", "Until", "text", "06:30", { when: "light.night.automatic", placeholder: "06:30" }),
                system("light.night.enabled", "Night Light now", "switch", false, { when: "!light.night.automatic" }),
                system("light.night.colorTemperature", "Warmth", "level", 6000, { from: 2500, to: 6500, step: 100, unit: "K" }),
                system("light.antiFlashbang.enable", "Soften bright flashes", "switch", false,
                       { note: "A white page opening in the dark comes in dimmed" })
            ] },
            { title: "Several screens", rows: [
                system("display.primaryMonitor", "Main screen for the shell", "choice", "", { source: "screens", when: "#screens" })
            ] }
        ]
    },
    {
        id: "windows", summary: "Layout, borders, corners, tabs and motion", title: "Windows", glyph: "windows",
        sections: [
            compositorGroup("Layout", "Layout"),
            compositorGroup("Borders", "Borders"),
            compositorGroup("Shape", "Shape"),
            compositorGroup("Tabs", "Tabs"),
            compositorGroup("Title bars", "Title bars"),
            compositorGroup("Glass behind apps", "Glass behind apps"),
            compositorGroup("Movement", "Movement"),
            compositorGroup("Hot corners", "Hot corners"),
            { title: "Closing", rows: [
                system("closeConfirm.enabled", "Confirm before closing windows", "switch", false)
            ] }
        ]
    },
    {
        id: "input", summary: "Keyboard layout, mouse, trackpad and pointer", title: "Keyboard and mouse", glyph: "keyboard",
        sections: [
            compositorGroup("Keyboard", "Keyboard"),
            compositorGroup("Mouse", "Mouse"),
            compositorGroup("Trackpad", "Trackpad"),
            compositorGroup("Pointer", "Pointer"),
            compositorGroup("Tablet", "Tablet"),
            compositorGroup("Touch screen", "Touch screen")
        ]
    },
    {
        id: "sound", summary: "Do Not Disturb, alerts and ear protection", title: "Sound and alerts", glyph: "bell",
        sections: [
            { title: "Notifications", rows: [
                system("notifications.silent", "Do Not Disturb", "switch", false),
                system("notifications.quietHours.enable", "Quiet hours", "switch", false, { note: "Do Not Disturb by itself, every day" }),
                system("notifications.quietHours.start", "From", "text", "22:00", { when: "notifications.quietHours.enable", placeholder: "22:00" }),
                system("notifications.quietHours.end", "Until", "text", "08:00", { when: "notifications.quietHours.enable", placeholder: "08:00" }),
                system("notifications.ignoreAppTimeout", "Ignore how long apps ask", "switch", false),
                system("notifications.timeoutCritical", "Urgent banners stay", "level", 0,
                       { from: 0, to: 60000, step: 5000, unit: "s", fit: 0, fitLabel: "Until dismissed" }),
                system("notifications.maxPopupLifetime", "Longest a banner stays", "level", 30000,
                       { from: 0, to: 120000, step: 5000, unit: "s", fit: 0, fitLabel: "No limit" })
            ] },
            { title: "Sounds", rows: [
                system("sounds.notifications", "Play a sound for notifications", "switch", true),
                system("sounds.volume", "Alert volume", "level", 0.5, { from: 0, to: 1, step: 0.05, unit: "percent" }),
                system("sounds.timer", "Timers", "switch", false),
                system("sounds.pomodoro", "Focus sessions", "switch", false),
                system("sounds.battery", "Battery warnings", "switch", false)
            ] },
            { title: "Ear protection", rows: [
                system("audio.protection.enable", "Ear protection", "switch", true, { note: "Holds back sudden jumps in volume" }),
                system("audio.protection.maxAllowedIncrease", "Largest jump", "level", 10, { from: 2, to: 50, step: 2, unit: "share", when: "audio.protection.enable" }),
                system("audio.protection.maxAllowed", "Volume limit", "level", 100, { from: 50, to: 154, step: 2, unit: "share", when: "audio.protection.enable" })
            ] }
        ]
    },
    {
        id: "power", summary: "Battery, sleep, lock and game mode", title: "Power and lock", glyph: "power",
        sections: [
            { title: "Battery", rows: [
                system("battery.low", "Low battery", "level", 20, { from: 5, to: 50, step: 5, unit: "share" }),
                system("battery.critical", "Critical battery", "level", 5, { from: 1, to: 20, step: 1, unit: "share" }),
                system("battery.full", "Charged notice", "choice", 101, { options: [[101, "Never"], [80, "80%"], [90, "90%"], [100, "Full"]] }),
                system("battery.automaticSuspend", "Suspend when almost empty", "switch", false),
                system("battery.suspend", "At", "level", 3, { from: 1, to: 10, step: 1, unit: "share", when: "battery.automaticSuspend" }),
                system("battery.chargeLimit.enable", "Limit charging", "switch", false, { note: "Keeps the battery healthy on a laptop that stays plugged in" }),
                system("battery.chargeLimit.threshold", "Stop at", "level", 80, { from: 50, to: 100, step: 5, unit: "share", when: "battery.chargeLimit.enable" }),
                system("performance.lowPower", "Low power", "switch", false, { note: "Fewer effects and slower updates" })
            ] },
            { title: "When idle", rows: [
                system("idle.screenOffTimeout", "Turn the screen off after", "choice", 300, { options: idleTimes }),
                system("idle.lockTimeout", "Lock after", "choice", 600, { options: idleTimes }),
                system("idle.suspendTimeout", "Suspend after", "choice", 0, { options: idleTimes }),
                system("idle.lockBeforeSleep", "Lock before sleeping", "switch", true),
                system("idle.onBattery.enable", "Shorter times on battery", "switch", false),
                system("idle.onBattery.screenOffTimeout", "On battery, screen off after", "choice", 120, { options: idleTimes, when: "idle.onBattery.enable" }),
                system("idle.onBattery.lockTimeout", "On battery, lock after", "choice", 300, { options: idleTimes, when: "idle.onBattery.enable" }),
                system("idle.onBattery.suspendTimeout", "On battery, suspend after", "choice", 600, { options: idleTimes, when: "idle.onBattery.enable" })
            ] },
            { title: "Lock", rows: [
                system("lock.launchOnStartup", "Lock when the session starts", "switch", false),
                system("lock.security.unlockKeyring", "Unlock the keyring", "switch", true, { note: "Your password also opens the keyring" }),
                system("lock.enableAnimation", "Play live wallpapers on the lock screen", "switch", false),
                system("lock.useHyprlock", "Lock with Hyprlock", "switch", false)
            ] },
            { title: "Game mode", rows: [
                system("gameMode.autoDetect", "Turn on for fullscreen apps", "switch", true),
                system("gameMode.disableAnimations", "Stop shell animations", "switch", false),
                system("gameMode.disableEffects", "Stop glass and blur", "switch", false),
                system("gameMode.disableNiriAnimations", "Stop window animations", "switch", false),
                system("gameMode.suppressNotifications", "Hold notifications", "switch", true),
                system("gameMode.disableVisualizers", "Stop audio visualizers", "switch", true),
                system("gameMode.disableReloadToasts", "Hide reload notices", "switch", true)
            ] }
        ]
    },
    {
        id: "wallpaper", summary: "The picture, how it changes and which apps take its colours", title: "Wallpaper and themes", glyph: "image",
        sections: [
            { title: "Wallpaper", rows: [
                action("wallpapers", "Choose a wallpaper", "", "Open"),
                action("nextWallpaper", "Next wallpaper", "From the same folder", "Next"),
                system("wallpapers.directory", "Wallpapers folder", "text", "", { placeholder: "~/Pictures/Wallpapers" }),
                system("background.fillMode", "Scaling", "choice", "fill", { options: [["fill", "Fill"], ["fit", "Fit"], ["stretch", "Stretch"], ["tile", "Tile"]] }),
                system("background.parallax.enable", "Parallax", "switch", false, { when: "background.fillMode=fill", note: "It drifts a little as you change workspace" }),
                system("background.multiMonitor.enable", "A wallpaper per screen", "switch", false, { when: "#screens" })
            ] },
            { title: "Shuffle", rows: [
                system("background.autoWallpaper.enable", "Shuffle wallpapers", "switch", false),
                system("background.autoWallpaper.intervalMinutes", "Every", "level", 30, { from: 1, to: 240, step: 1, unit: "min", when: "background.autoWallpaper.enable" }),
                system("background.autoWallpaper.folder", "From the folder", "text", "", { placeholder: "~/Pictures/Wallpapers", when: "background.autoWallpaper.enable" }),
                system("background.autoWallpaper.generateColors", "Colours follow", "switch", true, { when: "background.autoWallpaper.enable" })
            ] },
            { title: "Change", rows: [
                system("background.transition.enable", "Animate the change", "switch", true),
                system("background.transition.type", "Style", "choice", "random", { when: "background.transition.enable", options: [
                    ["none", "None"], ["crossfade", "Fade"], ["simple", "Simple"], ["left", "From left"], ["right", "From right"],
                    ["top", "From top"], ["bottom", "From bottom"], ["wipe", "Wipe"], ["wave", "Wave"], ["grow", "Grow"],
                    ["center", "Center"], ["any", "Any"], ["outer", "Outer"], ["random", "Random"], ["circleSelect", "Circle shader"],
                    ["circlePit", "Circle pit"], ["magic", "Magic"], ["Doom", "Doom"], ["Peel", "Peel"], ["transition", "Shader fade"],
                    ["pixelate", "Pixelate"], ["stripes", "Stripes"], ["crt", "CRT"], ["dissolve", "Dissolve"], ["glitch", "Glitch"],
                    ["ripple", "Ripple"], ["shatter", "Shatter"], ["inirMelt", "iNiR Melt"], ["inirVeil", "Chromatic Veil"],
                    ["inirFracture", "Glass Fracture"], ["inirInk", "Sumi Wash"], ["inirPrism", "Prism Slices"],
                    ["shaderRandom", "Random shader"]] }),
                system("background.transition.duration", "Duration", "level", 800, { from: 200, to: 3000, step: 100, unit: "ms", when: "background.transition.enable" })
            ] },
            { title: "Effects", rows: [
                system("background.effects.enableBlur", "Blur the wallpaper", "switch", true),
                system("background.effects.blurRadius", "Blur", "level", 22, { from: 4, to: 80, step: 2, unit: "px", when: "background.effects.enableBlur" }),
                system("background.effects.dim", "Always dim", "level", 0, { from: 0, to: 60, step: 5, unit: "share" }),
                system("background.effects.dynamicDim", "Dim with windows open", "level", 0, { from: 0, to: 60, step: 5, unit: "share" }),
                system("background.enableAnimation", "Play live wallpapers", "switch", true),
                system("background.videoPause", "Pause live wallpapers", "choice", "covered", { options: [["never", "Never"], ["fullscreen", "Behind fullscreen"], ["covered", "When covered"]] }),
                system("background.pauseAnimationOnBattery", "Pause on battery", "switch", true)
            ] },
            { title: "Apps take the colours", rows: [
                system("appearance.wallpaperTheming.enableAppsAndShell", "GTK and KDE apps", "switch", true),
                system("appearance.wallpaperTheming.enableQtApps", "Qt apps", "switch", true, { when: "appearance.wallpaperTheming.enableAppsAndShell" }),
                system("appearance.wallpaperTheming.enableTerminal", "Terminals", "switch", true),
                system("appearance.wallpaperTheming.enableFirefox", "Firefox", "switch", true),
                system("appearance.wallpaperTheming.enableChrome", "Chrome and Chromium", "switch", true),
                system("appearance.wallpaperTheming.enableVSCode", "VS Code", "switch", true),
                system("appearance.wallpaperTheming.enableZed", "Zed", "switch", true),
                system("appearance.wallpaperTheming.enableVesktop", "Discord (Vesktop)", "switch", true),
                system("appearance.wallpaperTheming.enableSpicetify", "Spotify (Spicetify)", "switch", true),
                system("appearance.wallpaperTheming.enablePearDesktop", "YouTube Music (Pear Desktop)", "switch", true),
                system("appearance.wallpaperTheming.enableSteam", "Steam", "switch", true),
                system("appearance.wallpaperTheming.enableNeovim", "Neovim", "switch", false),
                system("appearance.wallpaperTheming.enableCava", "Cava", "switch", true)
            ] },
            { title: "Icons and fonts", rows: [
                system("appearance.iconTheme", "Icons", "choice", "", { source: "iconThemes" }),
                system("appearance.typography.syncWithSystem", "Apps use the shell's font", "switch", true)
            ] }
        ]
    },
    {
        id: "system", summary: "Language, clock, apps, weather and updates", title: "System", glyph: "settings",
        sections: [
            { title: "Language and time", rows: [
                system("language.ui", "Language", "choice", "auto", { source: "languages" }),
                system("time.format", "Clock", "choice", "hh:mm", { options: [["hh:mm", "24-hour"], ["h:mm ap", "12-hour"], ["h:mm AP", "12-hour AM/PM"]] }),
                system("time.secondPrecision", "Exact seconds", "switch", false)
            ] },
            { title: "Apps", rows: [
                system("apps.terminal", "Terminal", "text", "kitty", { placeholder: "kitty" })
            ] },
            { title: "Desktop", rows: [
                system("panelFamily", "Family", "choice", "nihil", { source: "families", note: "The whole desktop changes to it" }),
                system("familyTransitionAnimation", "Animate the switch", "switch", true),
                toggle("settings.overlay", "Settings over the desktop", "Opens inside the shell, with the desktop in sight, instead of in a window")
            ] },
            { title: "Weather", rows: [
                system("weather.enable", "Weather", "switch", true),
                system("weather.city", "Place", "text", "", { when: "weather.enable", placeholder: "Buenos Aires" }),
                system("weather.enableGPS", "Use GPS when there is one", "switch", false, { when: "weather.enable" }),
                system("weather.useUSCS", "Fahrenheit", "switch", false, { when: "weather.enable" }),
                system("weather.fetchInterval", "Check every", "level", 10, { from: 5, to: 60, step: 5, unit: "min", when: "weather.enable" })
            ] },
            { title: "Updates", rows: [
                system("shellUpdates.enabled", "Watch for new iNiR versions", "switch", true),
                system("shellUpdates.checkIntervalMinutes", "Check every", "level", 360, { from: 60, to: 1440, step: 60, unit: "min", when: "shellUpdates.enabled" }),
                system("shellUpdates.openTerminalOnUpdate", "Update in a terminal", "switch", true, { when: "shellUpdates.enabled" })
            ] }
        ]
    },
    {
        id: "about", summary: "The family and its defaults", title: "About", glyph: "info", view: "about"
    }
]

// Every row of every page, each knowing the page it lives on.
function allRows() {
    var rows = []
    pages.forEach(function (page) {
        (page.sections || []).forEach(function (section) {
            section.rows.forEach(function (row) {
                rows.push(Object.assign({ page: page.title, section: section.title }, row))
            })
        })
    })
    return rows
}
