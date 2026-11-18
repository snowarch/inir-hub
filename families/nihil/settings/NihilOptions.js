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

function screens(key, label, note) {
    return { type: "screens", key: key, label: label, note: note || "" }
}

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
        id: "profiles", title: "Profiles", glyph: "dashboard_customize", view: "profiles"
    },
    {
        id: "layout", title: "Layout", glyph: "desktop",
        sections: [
            { title: "Panel", rows: [
                choice("panel.position", "Position", [["top", "Top"], ["bottom", "Bottom"]]),
                choice("panel.visibility", "Shown", [["always", "Always"], ["desktop", "On an empty desktop"],
                                                     ["overview", "In the overview"], ["hidden", "Never"]]),
                choice("panel.overviewStyle", "In the overview", [["same", "Keep the glass"], ["transparent", "Transparent"]]),
                screens("panel.screenList", "Screens", "With none marked it shows on all of them")
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
            { title: "Workspace strip", rows: [
                choice("thumbnails.position", "Position", edges),
                level("thumbnails.adjust", "Shift along the edge", -1, 1, 0.05),
                level("thumbnails.scale", "Size", 0.05, 0.3, 0.01, "percent"),
                level("thumbnails.scaleInApps", "Size in the app grid", 0, 0.3, 0.01, "percent", "", hiddenAtZero),
                level("thumbnails.scaleInSearch", "Size in search", 0, 0.3, 0.01, "percent", "", hiddenAtZero),
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
        id: "appearance", title: "Appearance", glyph: "palette",
        sections: [
            { title: "Colour", rows: [
                choice("look.palette", "Palette", [["obsidian", "Obsidian"], ["amber", "Amber"], ["azure", "Azure"], ["ember", "Ember"],
                                                   ["ultramarine", "Ultramarine"], ["wallpaper", "From the wallpaper"]])
            ] },
            { title: "Glass", rows: [
                level("look.glass", "Opacity", 0, 1, 0.01, "percent"),
                toggle("look.blur", "Blur what is behind"),
                level("look.grain", "Grain", 0, 1, 0.01, "percent"),
                level("look.rim", "Rim light", 0, 1, 0.01, "percent"),
                level("look.flare", "Flare", 0, 1, 0.01, "percent")
            ] },
            { title: "Shape and type", rows: [
                level("look.corners", "Roundness", 0, 2, 0.05, "times"),
                level("look.scale", "Interface size", 0.75, 1.5, 0.01, "times"),
                choice("look.font", "Typeface", [["grotesk", "Hanken Grotesk"], ["system", "System"]])
            ] },
            { title: "Field", rows: [
                choice("field.form", "Form", [[0, "Drift"], [1, "Eclipse"], [2, "Fluted"], [3, "Stippled ridge"]]),
                level("field.seed", "Variation", 0, 1, 0.01),
                level("field.glow", "Glow", 0, 2, 0.05, "times")
            ] },
            { title: "Overview background", rows: [
                choice("overview.background", "Behind the overview", [["desktop", "Sharp wallpaper"], ["transparent", "Nothing"],
                                                                      ["blurFast", "Fast blur"], ["blurSmooth", "Smooth blur"]]),
                level("overview.backgroundBlur", "Blur", 0, 1, 0.01, "percent"),
                level("overview.backgroundBrightness", "Brightness with windows", 0, 1, 0.01, "percent"),
                level("overview.appsBrightness", "Brightness in the app grid", 0, 1, 0.01, "percent"),
                level("overview.searchBrightness", "Brightness in search", 0, 1, 0.01, "percent"),
                toggle("overview.smoothAnimation", "Blur grows with the opening")
            ] },
            { title: "Desktop widgets", rows: [
                choice("widgets.design", "Design", [["nihil", "NiHiL"], ["material", "Material"], ["instrument", "iNstrument"], ["readout", "Readout"]])
            ] }
        ]
    },
    {
        id: "behavior", title: "Behavior", glyph: "tune",
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
        id: "apps", title: "App grid", glyph: "apps",
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
                level("results.iconSize", "Larger rows", 0, 48, 1, "px"),
                choice("results.background", "Background", [["transparent", "Glass"], ["dark", "Dark"]]),
                choice("results.animation", "Results arrive", arrivals)
            ] }
        ]
    },
    {
        id: "modules", title: "Modules", glyph: "widgets",
        sections: [
            { title: "Surfaces", rows: [
                toggle("modules.panel", "Panel"),
                toggle("modules.dash", "Dash"),
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
        id: "about", title: "About", glyph: "info", view: "about"
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
