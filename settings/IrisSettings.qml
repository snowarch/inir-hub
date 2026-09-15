pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.settings
import qs.modules.iris.components
import qs.modules.iris.style
import qs.modules.iris.sidebar

PanelWindow {
    id: root
    property string section: "bar"
    property int advancedPage: -1
    property string query: ""
    property string requestedSection: ""
    readonly property real d: IrisStyle.density
    // Section badges follow the grouped-settings convention: one quiet tint per
    // category so the sidebar scans by colour as well as by label.
    readonly property var sections: [
        { id: "bar", title: "Island", subtitle: "Composition, size and how the Island responds", icon: "pill", tint: "#0a84ff", tip: "Rest on the Island to peek, click to keep it, scroll for volume." },
        { id: "player", title: "Now Playing", subtitle: "Music in the Island and on the lock screen", icon: "music_note", tint: "#ff375f", tip: "Middle-click the Island to play or pause." },
        { id: "bubbles", title: "Bubbles", subtitle: "Where the Island's bubbles rest and how they float", icon: "bubble_chart", tint: "#64d2ff", tip: "Hold a bubble to carry it; drop it beside the Island to bring it back." },
        { id: "dock", title: "Dock", subtitle: "Visibility, material and app icons", icon: "dock_to_bottom", tint: "#5e5ce6", tip: "Right-click an icon for its windows; middle-click opens a new one." },
        { id: "appearance", title: "Appearance", subtitle: "Shape and motion of every iRiS surface", icon: "palette", tint: "#bf5af2", tip: "Shorter morphs feel snappier; the settle stays liquid." },
        { id: "desktop", title: "Desktop", subtitle: "Widgets on the wallpaper and the overview backdrop", icon: "widgets", tint: "#30b0c7", tip: "Right-click the desktop to edit widgets." },
        { id: "sidebars", title: "Side Panels", subtitle: "Focus and Today, arranged around your workflow", icon: "dock_to_right", tint: "#34c759", tip: "Ctrl+E customizes a panel; Keep open makes room beside windows." },
        { id: "surfaces", title: "Spotlight & Panels", subtitle: "Search, Control Center and system feedback", icon: "space_dashboard", tint: "#ff9f0a", tip: "Spotlight prefixes: ; clipboard, = calculator, / actions." },
        { id: "system", title: "All Settings", subtitle: "Every iNiR page", icon: "settings", tint: "#8e8e93", tip: "Search finds iRiS options across every section." }
    ]
    readonly property var specifications: [
        { section: "bar", group: "Layout", label: "Composition", description: "Cluster splits media and controls into bubbles beside the clock.", path: "iris.bar.composition", kind: "choice", fallback: "unified", choices: [{label:"Unified",value:"unified"},{label:"Cluster",value:"cluster"}] },
        { section: "bar", group: "Layout", label: "Screen edge", path: "iris.bar.position", kind: "choice", fallback: "top", choices: [{label:"Top",value:"top"},{label:"Bottom",value:"bottom"}] },
        { section: "bar", group: "Layout", label: "Attach as a notch", description: "Melts the Island into the screen edge.", path: "iris.bar.notch", kind: "switch", fallback: false },
        { section: "bar", group: "Size", label: "Height", path: "iris.bar.height", kind: "range", fallback:42,min:32,max:64,unit:" px" },
        { section: "bar", group: "Size", label: "Gap from the edge", path: "iris.bar.margin", kind: "range", fallback:8,min:0,max:24,unit:" px" },
        { section: "bar", group: "Size", label: "Reserve space for windows", path: "iris.bar.reserveSpace", kind: "switch", fallback:true },
        { section: "bar", group: "Interaction", label: "System events", description: "Charger, Bluetooth devices, Do Not Disturb, Caps Lock and finished timers or recordings appear in the Island for a moment.", path: "iris.bar.events", kind: "switch", fallback: true },
        { section: "bar", group: "Interaction", label: "Expand on hover", description: "The pointer has to rest on the Island; passing over it does nothing.", path: "iris.bar.hoverExpand", kind: "switch", fallback:true },
        { section: "bar", group: "Interaction", label: "Hover delay", path: "iris.bar.hoverDelay", kind: "range", fallback:160,min:60,max:400,step:10,unit:" ms" },
        { section: "bar", group: "Interaction", label: "Scroll on the Island", description: "Shift swaps volume and brightness; Ctrl adjusts the microphone.", path: "iris.bar.scrollAction", kind: "choice", fallback: "volume", choices: [{label:"Volume",value:"volume"},{label:"Brightness",value:"brightness"},{label:"Off",value:"none"}] },
        { section: "bar", group: "Interaction", label: "Scroll on bubbles", description: "Also adjust over the media, controls and tray bubbles. Sound and Microphone bubbles always adjust their level.", path: "iris.bar.scrollBubbles", kind: "switch", fallback: true },
        { section: "bar", group: "Resting Island", label: "Clock", description: "What the resting Island shows beside the time.", path: "iris.bar.clockStyle", kind: "choice", fallback: "dateTime", choices: [{label:"Time",value:"time"},{label:"Date",value:"dateTime"},{label:"Weather",value:"weather"}] },
        { section: "bar", group: "Resting Island", label: "Utility island", description: "Emerges beside the Island; the tray hides when no apps are present.", path: "iris.bar.auxiliary", kind: "choice", fallback: "tray", choices: [{label:"Tray",value:"tray"},{label:"Timers",value:"tools"},{label:"Sound",value:"sound"},{label:"Microphone",value:"mic"},{label:"None",value:"none"}] },
        { section: "bar", group: "Resting Island", label: "Trailing bubble", description: "Cluster only. Sound and Microphone show their level: scroll to adjust, click to mute.", path: "iris.bar.trailing", kind: "choice", fallback: "controls", choices: [{label:"Controls",value:"controls"},{label:"Notifications",value:"notifications"},{label:"Weather",value:"weather"},{label:"Sound",value:"sound"},{label:"Microphone",value:"mic"},{label:"None",value:"none"}] },
        { section: "bar", group: "Desktop page", label: "Header", description: "What sits behind the time when the Island shows your desktop.", path: "iris.bar.desktopBanner", kind: "choice", fallback: "wallpaper", choices: [{label:"Wallpaper",value:"wallpaper"},{label:"None",value:"none"}] },
        { section: "bar", group: "Desktop page", label: "Profile", description: "Your picture and account. Click the picture to change it.", path: "iris.bar.desktopProfile", kind: "switch", fallback: true },
        { section: "player", group: "Artwork", label: "Round album cover", path: "iris.player.roundCover", kind: "switch", fallback:true },
        { section: "player", group: "Artwork", label: "Blurred album background", description: "Tints the expanded Island and media cards with the cover.", path: "iris.player.artworkBackground", kind: "switch", fallback:true },
        { section: "player", group: "Bubble", label: "Media bubble opens", description: "A card that floats out of the bubble, or the Island's player page. Cluster composition only.", path: "iris.player.bubbleOpens", kind: "choice", fallback: "card", choices: [{label:"Card",value:"card"},{label:"Island",value:"island"}] },
        { section: "player", group: "Bubble", label: "Keep the card open", description: "The card stays beside the Island while a player is active.", path: "iris.player.cardPinned", kind: "switch", fallback: false },
        { section: "bubbles", group: "Placement", label: "Activity bubble", description: "Media, a timer or a recording beside the clock (Cluster).", path: "iris.bubbles.left.place", kind: "choice", fallback: "island", choices: [{label:"Island",value:"island"},{label:"Top left",value:"top-left"},{label:"Top right",value:"top-right"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Bottom left",value:"bottom-left"},{label:"Bottom right",value:"bottom-right"},{label:"Free",value:"free"}] },
        { section: "bubbles", group: "Placement", label: "Trailing bubble", description: "Controls, notifications, weather or a level after the clock.", path: "iris.bubbles.right.place", kind: "choice", fallback: "island", choices: [{label:"Island",value:"island"},{label:"Top left",value:"top-left"},{label:"Top right",value:"top-right"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Bottom left",value:"bottom-left"},{label:"Bottom right",value:"bottom-right"},{label:"Free",value:"free"}] },
        { section: "bubbles", group: "Placement", label: "Utility bubble", description: "Tray, timers, sound or microphone at the end of the Island.", path: "iris.bubbles.utility.place", kind: "choice", fallback: "island", choices: [{label:"Island",value:"island"},{label:"Top left",value:"top-left"},{label:"Top right",value:"top-right"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Bottom left",value:"bottom-left"},{label:"Bottom right",value:"bottom-right"},{label:"Free",value:"free"}] },
        { section: "bubbles", group: "Extra bubbles", label: "Weather", description: "The sky now; opens your desktop page.", path: "iris.bubbles.extras.weather.enable", kind: "switch", fallback: false },
        { section: "bubbles", group: "Extra bubbles", label: "Weather bubble rests", path: "iris.bubbles.extras.weather.place", visibleWhen: "iris.bubbles.extras.weather.enable", kind: "choice", fallback: "right", choices: [{label:"Top left",value:"top-left"},{label:"Top right",value:"top-right"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Bottom left",value:"bottom-left"},{label:"Bottom right",value:"bottom-right"},{label:"Free",value:"free"}] },
        { section: "bubbles", group: "Extra bubbles", label: "Notifications", description: "A count of unread notifications; opens Today.", path: "iris.bubbles.extras.notifications.enable", kind: "switch", fallback: false },
        { section: "bubbles", group: "Extra bubbles", label: "Notifications bubble rests", path: "iris.bubbles.extras.notifications.place", visibleWhen: "iris.bubbles.extras.notifications.enable", kind: "choice", fallback: "right", choices: [{label:"Top left",value:"top-left"},{label:"Top right",value:"top-right"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Bottom left",value:"bottom-left"},{label:"Bottom right",value:"bottom-right"},{label:"Free",value:"free"}] },
        { section: "bubbles", group: "Extra bubbles", label: "Controls", description: "Opens the Control Center out of the bubble.", path: "iris.bubbles.extras.controls.enable", kind: "switch", fallback: false },
        { section: "bubbles", group: "Extra bubbles", label: "Controls bubble rests", path: "iris.bubbles.extras.controls.place", visibleWhen: "iris.bubbles.extras.controls.enable", kind: "choice", fallback: "right", choices: [{label:"Top left",value:"top-left"},{label:"Top right",value:"top-right"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Bottom left",value:"bottom-left"},{label:"Bottom right",value:"bottom-right"},{label:"Free",value:"free"}] },
        { section: "bubbles", group: "Extra bubbles", label: "Sound", description: "Output level as a ring; scroll to change it, click to mute.", path: "iris.bubbles.extras.sound.enable", kind: "switch", fallback: false },
        { section: "bubbles", group: "Extra bubbles", label: "Sound bubble rests", path: "iris.bubbles.extras.sound.place", visibleWhen: "iris.bubbles.extras.sound.enable", kind: "choice", fallback: "right", choices: [{label:"Top left",value:"top-left"},{label:"Top right",value:"top-right"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Bottom left",value:"bottom-left"},{label:"Bottom right",value:"bottom-right"},{label:"Free",value:"free"}] },
        { section: "bubbles", group: "Extra bubbles", label: "Microphone", description: "Input level as a ring; scroll to change it, click to mute.", path: "iris.bubbles.extras.mic.enable", kind: "switch", fallback: false },
        { section: "bubbles", group: "Extra bubbles", label: "Microphone bubble rests", path: "iris.bubbles.extras.mic.place", visibleWhen: "iris.bubbles.extras.mic.enable", kind: "choice", fallback: "right", choices: [{label:"Top left",value:"top-left"},{label:"Top right",value:"top-right"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Bottom left",value:"bottom-left"},{label:"Bottom right",value:"bottom-right"},{label:"Free",value:"free"}] },
        { section: "bubbles", group: "Extra bubbles", label: "Timers", description: "Opens the timer dials.", path: "iris.bubbles.extras.tools.enable", kind: "switch", fallback: false },
        { section: "bubbles", group: "Extra bubbles", label: "Timers bubble rests", path: "iris.bubbles.extras.tools.place", visibleWhen: "iris.bubbles.extras.tools.enable", kind: "choice", fallback: "right", choices: [{label:"Top left",value:"top-left"},{label:"Top right",value:"top-right"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Bottom left",value:"bottom-left"},{label:"Bottom right",value:"bottom-right"},{label:"Free",value:"free"}] },
        { section: "bubbles", group: "Extra bubbles", label: "Now playing", description: "The cover while something plays; opens its card.", path: "iris.bubbles.extras.media.enable", kind: "switch", fallback: false },
        { section: "bubbles", group: "Extra bubbles", label: "Now playing bubble rests", path: "iris.bubbles.extras.media.place", visibleWhen: "iris.bubbles.extras.media.enable", kind: "choice", fallback: "right", choices: [{label:"Top left",value:"top-left"},{label:"Top right",value:"top-right"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Bottom left",value:"bottom-left"},{label:"Bottom right",value:"bottom-right"},{label:"Free",value:"free"}] },
        { section: "bubbles", group: "Extra bubbles", label: "Tray", description: "How many tray apps are running; opens them.", path: "iris.bubbles.extras.tray.enable", kind: "switch", fallback: false },
        { section: "bubbles", group: "Extra bubbles", label: "Tray bubble rests", path: "iris.bubbles.extras.tray.place", visibleWhen: "iris.bubbles.extras.tray.enable", kind: "choice", fallback: "right", choices: [{label:"Top left",value:"top-left"},{label:"Top right",value:"top-right"},{label:"Left",value:"left"},{label:"Right",value:"right"},{label:"Bottom left",value:"bottom-left"},{label:"Bottom right",value:"bottom-right"},{label:"Free",value:"free"}] },
        { section: "bubbles", group: "Floating", label: "Space from the screen edges", description: "How far floating bubbles rest from the edges; the top row also keeps clear of the Island.", path: "iris.bubbles.edgeGap", kind: "range", fallback: 20, min: 0, max: 64, unit: " px" },
        { section: "bubbles", group: "Floating", label: "Snap to corners and edges", description: "Dropped near one, a bubble settles there; off, it stays where you let go.", path: "iris.bubbles.snap", kind: "switch", fallback: true },
        { section: "dock", group: "Visibility", label: "Show dock", path: "iris.dock.enable", kind: "switch", fallback:true },
        { section: "dock", group: "Visibility", label: "Automatically hide", description: "Rest the pointer at the screen edge to reveal it.", path: "iris.dock.autoHide", kind: "switch", fallback:true },
        { section: "dock", group: "Visibility", label: "Stay visible on empty workspaces", path: "iris.dock.revealOnEmpty", kind: "switch", fallback:true },
        { section: "dock", group: "Look", label: "Attach as a notch", path: "iris.dock.notch", kind: "switch", fallback:false },
        { section: "dock", group: "Look", label: "Compositor blur", description: "Translucent material when the compositor provides blur.", path: "iris.dock.blur", kind: "switch", fallback:false },
        { section: "dock", group: "Icons", label: "Icon size", path: "iris.dock.iconSize", kind: "range", fallback:40,min:28,max:64,unit:" px" },
        { section: "dock", group: "Icons", label: "Magnify on hover", path: "iris.dock.magnification", kind: "switch", fallback:true },
        { section: "dock", group: "Icons", label: "Applications button", description: "Opens Spotlight from the start of the Dock.", path: "iris.dock.launcher", kind: "switch", fallback:true },
        { section: "dock", group: "Icons", label: "Notification badges", path: "iris.dock.badges", kind: "switch", fallback:true },
        { section: "appearance", group: "Colour", label: "System accent", description: "Selection and controls across iRiS. Activity colours keep their identity.", path: "iris.appearance.accent", kind: "choice", fallback: "blue", choices: [{label:"Blue",value:"blue",swatch:"#a8c7fa"},{label:"Mint",value:"mint",swatch:"#8de0bd"},{label:"Rose",value:"rose",swatch:"#ffb2c4"},{label:"Lilac",value:"lilac",swatch:"#d2baff"},{label:"Wallpaper",value:"wallpaper"}] },
        { section: "appearance", group: "Colour", label: "Highlight", description: "The glanced detail: clock separator, day number, timers.", path: "iris.appearance.highlight", kind: "choice", fallback: "orange", choices: [{label:"Orange",value:"orange",swatch:"#ff9f0a"},{label:"Yellow",value:"yellow",swatch:"#ffd60a"},{label:"Red",value:"red",swatch:"#ff6961"},{label:"Pink",value:"pink",swatch:"#ff6482"},{label:"Green",value:"green",swatch:"#30d158"},{label:"Accent",value:"accent"}] },
        { section: "appearance", group: "Typography", label: "Text", path: "iris.appearance.fontFamily", kind: "choice", previewFont: true, fallback: "", choices: [{label:"Noto Sans",value:""},{label:"Rubik",value:"Rubik"},{label:"Readex Pro",value:"Readex Pro"},{label:"Roboto Flex",value:"Roboto Flex"}] },
        { section: "appearance", group: "Typography", label: "Titles", path: "iris.appearance.titleFontFamily", kind: "choice", previewFont: true, fallback: "", choices: [{label:"Readex Pro",value:""},{label:"Noto Sans",value:"Noto Sans"},{label:"Gabarito",value:"Gabarito"},{label:"Space Grotesk",value:"Space Grotesk"}] },
        { section: "appearance", group: "Typography", label: "Figures", description: "Clocks, timers and levels.", path: "iris.appearance.numbersFontFamily", kind: "choice", previewFont: true, fallback: "", choices: [{label:"Rubik",value:""},{label:"Readex Pro",value:"Readex Pro"},{label:"Noto Sans",value:"Noto Sans"},{label:"Space Grotesk",value:"Space Grotesk"}] },
        { section: "appearance", group: "Typography", label: "Figure weight", path: "iris.appearance.figureWeight", kind: "choice", fallback: "bold", choices: [{label:"Light",value:"light"},{label:"Regular",value:"regular"},{label:"Bold",value:"bold"}] },
        { section: "appearance", group: "Shape", label: "Expanded corners", path: "iris.appearance.expandedRadius", kind: "range", fallback:28,min:16,max:40,unit:" px" },
        { section: "appearance", group: "Motion", label: "Animations", path: "iris.appearance.motion", kind: "switch", fallback:true },
        { section: "appearance", group: "Motion", label: "Morph duration", description: "How long surfaces take to grow out of the Island.", path: "iris.appearance.motionDuration", kind: "range", fallback:220,min:100,max:400,step:10,unit:" ms" },
        { section: "desktop", group: "Widgets", label: "Desktop widgets", description: "Turning this off also unloads their data providers.", path: "iris.modules.desktopWidgets", kind: "switch", fallback:true },
        { section: "desktop", group: "Widgets", label: "Widget corners", description: "Individual widget overrides take priority.", path: "iris.widgets.radius", kind: "range", fallback:22,min:0,max:40,unit:" px" },
        { section: "desktop", group: "Widgets", label: "Colour", description: "Wallpaper lifts its hues so they read on black; iRiS follows your system accent.", path: "iris.widgets.tint", kind: "choice", fallback: "wallpaper", choices: [{label:"Wallpaper",value:"wallpaper"},{label:"iRiS",value:"system"}] },
        { section: "desktop", group: "Widgets", label: "Plate", description: "Tinted adds a trace of the chosen widget accent to the black material.", path: "iris.widgets.material", kind: "choice", fallback: "solid", choices: [{label:"Solid",value:"solid"},{label:"Tinted",value:"tinted"}] },
        { section: "desktop", group: "Widgets", label: "Titles and figures", path: "iris.widgets.weight", kind: "choice", fallback: "regular", choices: [{label:"Light",value:"light"},{label:"Regular",value:"regular"},{label:"Bold",value:"bold"}] },
        { section: "desktop", group: "Widgets", label: "Surface opacity", path: "iris.widgets.opacity", kind: "range", fallback:100,min:20,max:100,step:5,unit:" %" },
        { section: "desktop", group: "Overview backdrop", label: "Wallpaper behind the overview", description: "Shown around workspaces when Niri's overview is open.", path: "background.backdrop.enable", kind: "switch", fallback:true },
        { section: "desktop", group: "Overview backdrop", label: "Blur", path: "background.backdrop.blurRadius", kind: "range", fallback:40,min:0,max:100,unit:" px" },
        { section: "desktop", group: "Overview backdrop", label: "Dim", path: "background.backdrop.dim", kind: "range", fallback:40,min:0,max:100,unit:" %" },
        { section: "desktop", group: "Overview backdrop", label: "Vignette", path: "background.backdrop.vignetteEnabled", kind: "switch", fallback:false },
        { section: "surfaces", group: "Spotlight", label: "Spotlight", path: "iris.modules.palette", kind: "switch", fallback:true },
        { section: "surfaces", group: "Spotlight", label: "Width", path: "iris.palette.width", kind: "range", fallback:640,min:420,max:900,step:10,unit:" px" },
        { section: "surfaces", group: "Spotlight", label: "Maximum results", path: "iris.palette.maxResults", kind: "range", fallback:8,min:3,max:14 },
        { section: "surfaces", group: "Spotlight", label: "Search mode shortcuts", description: "Clipboard, calculator, actions and more under the suggestions.", path: "iris.palette.showHints", kind: "switch", fallback:true },
        { section: "surfaces", group: "Control Center", label: "Control Center", path: "iris.modules.controlCenter", kind: "switch", fallback:true },
        { section: "surfaces", group: "Control Center", label: "Width", path: "iris.controlCenter.width", kind: "range", fallback:360,min:320,max:540,step:10,unit:" px" },
        { section: "surfaces", group: "Tray", label: "App names", path: "iris.tray.labels", kind: "switch", fallback:true },
        { section: "surfaces", group: "Tray", label: "Hide passive apps", path: "iris.tray.hidePassive", kind: "switch", fallback:false },
        { section: "surfaces", group: "Tray", label: "Columns", path: "iris.tray.columns", kind: "range", fallback:4,min:2,max:6 },
        { section: "desktop", group: "Wallpaper gallery", label: "Gallery width", path: "iris.wallpaper.width", kind: "range", fallback:960,min:640,max:1400,step:40,unit:" px" },
        { section: "desktop", group: "Wallpaper gallery", label: "Preview size", path: "iris.wallpaper.thumbnailSize", kind: "range", fallback:228,min:160,max:320,step:8,unit:" px" },
        { section: "surfaces", group: "Feedback", label: "Notifications", path: "iris.modules.notificationPopup", kind: "switch", fallback:true },
        { section: "surfaces", group: "Feedback", label: "Banner duration", description: "How long a notification stays when the app does not choose. Hovering keeps it.", path: "iris.notifications.duration", kind: "range", fallback:4000,min:2000,max:12000,step:500,unit:" ms" },
        { section: "surfaces", group: "Feedback", label: "Volume and brightness feedback", path: "iris.modules.osd", kind: "switch", fallback:true },
        { section: "surfaces", group: "Windows", label: "Confirm before closing windows", description: "Asks before the close-window shortcut closes an app.", path: "closeConfirm.enabled", kind: "switch", fallback:false }
    ].concat(...["left", "right"].map(side => [
        { section: "sidebars", group: side === "left" ? "Focus · left" : "Today · right", label: "Enable panel", path: "iris.sidebars." + side + ".enable", kind: "switch", fallback:true },
        { section: "sidebars", group: side === "left" ? "Focus · left" : "Today · right", label: "Width", path: "iris.sidebars." + side + ".width", kind: "range", fallback:380,min:300,max:600,step:10,unit:" px" },
        { section: "sidebars", group: side === "left" ? "Focus · left" : "Today · right", label: "Maximum height", description: "Panels hug their sections and grow up to this.", path: "iris.sidebars." + side + ".height", kind: "range", fallback:88,min:45,max:100,unit:" %" },
        { section: "sidebars", group: side === "left" ? "Focus · left" : "Today · right", label: "Alignment", path: "iris.sidebars." + side + ".alignment", kind: "choice", fallback:"center", choices:[{label:"Top",value:"top"},{label:"Center",value:"center"},{label:"Bottom",value:"bottom"}] },
        { section: "sidebars", group: side === "left" ? "Focus · left" : "Today · right", label: "Attach to the screen edge", description: "Melts the panel into its edge, like a notch.", path: "iris.sidebars." + side + ".notch", kind: "switch", fallback:false },
        { section: "sidebars", group: side === "left" ? "Focus · left" : "Today · right", label: "Reveal on hover", description: side === "left" ? "Rest the pointer at the left edge to peek; click inside to keep it." : "Rest the pointer at the right edge to peek; click inside to keep it.", path: "iris.sidebars." + side + ".hoverReveal", kind: "switch", fallback:false },
        { section: "sidebars", group: side === "left" ? "Focus · left" : "Today · right", label: "Keep open", description: "Stay visible while working in other windows.", path: "iris.sidebars." + side + ".pinned", kind: "switch", fallback:false }
    ]))
    readonly property var currentSection: root.sections.find(s => s.id === root.section) ?? root.sections[0]
    // A row with `visibleWhen` (a switch's path) shows only while that switch is on.
    readonly property var entries: {
        Config.revision
        return specifications.filter(spec => !spec.visibleWhen || Config.getNestedValue(spec.visibleWhen, false))
            .filter(spec => query.length > 0
                ? (Translation.tr(spec.label) + " " + Translation.tr(spec.group)).toLowerCase().includes(query.toLowerCase())
                : spec.section === section)
    }
    // Consecutive rows of one group share a card; search groups by section.
    readonly property var groups: {
        const out = []
        for (const spec of root.entries) {
            const title = root.query.length > 0
                ? Translation.tr(root.sections.find(s => s.id === spec.section)?.title ?? "")
                : Translation.tr(spec.group ?? "")
            if (out.length === 0 || out[out.length - 1].title !== title) out.push({ title: title, rows: [] })
            out[out.length - 1].rows.push(spec)
        }
        return out
    }
    readonly property var pages: SettingsPageRegistry.pages.map(page => Object.assign({}, page, { component: Quickshell.shellPath(page.component) }))

    function applyRequest(): void {
        root.requestedSection = GlobalStates.settingsOverlayRequestedSection
        GlobalStates.settingsOverlayRequestedSection = ""
        const page = GlobalStates.settingsOverlayRequestedPage
        if (page >= 0) {
            root.advancedPage = page === 28 ? -1 : page
            root.section = page === 28 ? "bar" : "system"
            if (page === 28 && root.sections.some(s => s.id === root.requestedSection))
                root.section = root.requestedSection
            GlobalStates.settingsOverlayCurrentPage = page
            GlobalStates.settingsOverlayRequestedPage = -1
        }
    }
    function selectSection(id: string): void {
        root.section = id
        root.advancedPage = -1
        searchField.text = ""
    }
    Component.onCompleted: if (GlobalStates.settingsOverlayOpen) root.applyRequest()
    Connections {
        target: GlobalStates
        function onSettingsOverlayRequestedPageChanged(): void { root.applyRequest() }
        function onSettingsOverlayOpenChanged(): void { if (GlobalStates.settingsOverlayOpen) root.applyRequest() }
    }
    // Content slides in a few pixels whenever the page changes.
    onSectionChanged: pageEnter.restart()
    onAdvancedPageChanged: pageEnter.restart()

    // May be preloaded hidden while the Island is expanded; the layer surface
    // only exists while open or while the morph is still collapsing.
    visible: GlobalStates.settingsOverlayOpen || frame.progress > 0
    screen: GlobalStates.focusedScreen
    color: "transparent"
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:iris-settings"
    WlrLayershell.layer: GlobalStates.settingsNativeDialogOpen ? WlrLayer.Bottom : WlrLayer.Overlay
    WlrLayershell.keyboardFocus: GlobalStates.settingsNativeDialogOpen ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
    // Outside clicks are caught only while the window is really presented;
    // while it loads or collapses, input outside the frame passes through.
    mask: GlobalStates.settingsOverlayOpen && frame.armed ? null : frameRegion
    Region { id: frameRegion; item: frame }
    // Escape steps back: search, then an advanced page, then closes.
    Shortcut {
        sequence: "Escape"
        enabled: GlobalStates.settingsOverlayOpen
        onActivated: {
            if (root.query.length > 0) searchField.text = ""
            else if (root.advancedPage >= 0) root.advancedPage = -1
            else GlobalStates.settingsOverlayOpen = false
        }
    }
    Shortcut { sequence: "Ctrl+F"; enabled: GlobalStates.settingsOverlayOpen; onActivated: searchField.forceActiveFocus() }
    MouseArea { anchors.fill: parent; onClicked: GlobalStates.settingsOverlayOpen = false }

    IrisMorphSurface {
        id: frame
        open: GlobalStates.settingsOverlayOpen
        radius: Math.round(30 * root.d)
        onClosed: GlobalStates.irisMorphOwner = ""
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: Math.min(parent.width - 32, 980 * root.d)
        height: Math.min(parent.height - 48, 700 * root.d)
        MouseArea { anchors.fill: parent }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── Sidebar ────────────────────────────────────────────────────
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: Math.min(236 * root.d, frame.width * 0.3)
                color: IrisStyle.surfaceHigh
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12 * root.d
                    anchors.topMargin: 16 * root.d
                    spacing: 2 * root.d

                    // Search capsule.
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 10 * root.d
                        implicitHeight: Math.round(32 * root.d)
                        radius: height / 2
                        color: ColorUtils.applyAlpha(IrisStyle.text, searchField.activeFocus ? 0.12 : 0.08)
                        border.width: searchField.activeFocus ? 1 : 0
                        border.color: ColorUtils.applyAlpha(IrisStyle.accent, 0.6)
                        MaterialSymbol {
                            id: searchGlyph
                            anchors.left: parent.left
                            anchors.leftMargin: 10 * root.d
                            anchors.verticalCenter: parent.verticalCenter
                            text: "search"
                            iconSize: Math.round(16 * root.d)
                            color: IrisStyle.muted
                        }
                        TextInput {
                            id: searchField
                            anchors.left: searchGlyph.right
                            anchors.leftMargin: 6 * root.d
                            anchors.right: parent.right
                            anchors.rightMargin: 12 * root.d
                            anchors.verticalCenter: parent.verticalCenter
                            color: IrisStyle.text
                            selectionColor: IrisStyle.accentContainer
                            font.family: IrisStyle.fontMain
                            font.pixelSize: 13 * IrisStyle.typeScale
                            clip: true
                            onTextChanged: { root.query = text; if (text.length > 0) root.advancedPage = -1 }
                            IrisText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: searchField.text.length === 0
                                text: Translation.tr("Search")
                                color: IrisStyle.muted
                                font.pixelSize: searchField.font.pixelSize
                            }
                        }
                    }

                    Repeater {
                        model: root.sections
                        MouseArea {
                            id: sectionRow
                            required property var modelData
                            readonly property bool selected: root.query.length === 0 && root.section === sectionRow.modelData.id
                            Layout.fillWidth: true
                            implicitHeight: Math.round(36 * root.d)
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            Accessible.role: Accessible.Button
                            Accessible.name: Translation.tr(sectionRow.modelData.title)
                            onClicked: root.selectSection(sectionRow.modelData.id)
                            Rectangle {
                                anchors.fill: parent
                                radius: Math.round(10 * root.d)
                                color: sectionRow.selected ? ColorUtils.applyAlpha(IrisStyle.accent, 0.22)
                                    : sectionRow.containsMouse ? ColorUtils.applyAlpha(IrisStyle.text, 0.06) : "transparent"
                                Behavior on color { ColorAnimation { duration: IrisStyle.duration(110) } }
                            }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8 * root.d
                                anchors.rightMargin: 8 * root.d
                                spacing: 10 * root.d
                                Rectangle {
                                    implicitWidth: Math.round(24 * root.d)
                                    implicitHeight: implicitWidth
                                    radius: Math.round(7 * root.d)
                                    color: sectionRow.modelData.tint
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: sectionRow.modelData.icon
                                        iconSize: Math.round(15 * root.d)
                                        fill: 1
                                        color: "#ffffff"
                                    }
                                }
                                IrisText {
                                    Layout.fillWidth: true
                                    text: Translation.tr(sectionRow.modelData.title)
                                    font.pixelSize: 13 * IrisStyle.typeScale
                                    font.weight: sectionRow.selected ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8 * root.d
                        Layout.bottomMargin: 4 * root.d
                        spacing: 8 * root.d
                        IrisMark { implicitSize: Math.round(22 * root.d) }
                        ColumnLayout {
                            spacing: 0
                            IrisText { text: "iRiS"; font.pixelSize: 13 * IrisStyle.typeScale; font.weight: Font.DemiBold }
                            IrisText {
                                text: Translation.tr("Island family")
                                color: IrisStyle.muted
                                font.pixelSize: 11 * IrisStyle.typeScale
                            }
                        }
                    }
                }
            }

            // ── Content ────────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 28 * root.d
                    Layout.rightMargin: 14 * root.d
                    Layout.topMargin: 14 * root.d
                    Layout.preferredHeight: Math.round(56 * root.d)
                    spacing: 8 * root.d
                    IrisIconButton {
                        visible: root.advancedPage >= 0
                        materialIcon: "chevron_left"
                        onClicked: root.advancedPage = -1
                        Accessible.name: Translation.tr("Back")
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        IrisText {
                            Layout.fillWidth: true
                            text: root.query.length > 0 ? Translation.tr("Results for “%1”").arg(root.query)
                                : root.advancedPage >= 0 ? String(root.pages[root.advancedPage]?.name ?? root.pages[root.advancedPage]?.title ?? "")
                                : Translation.tr(root.currentSection.title)
                            font.family: IrisStyle.fontTitle
                            font.pixelSize: 21 * IrisStyle.typeScale
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                        IrisText {
                            Layout.fillWidth: true
                            visible: root.query.length === 0 && root.advancedPage < 0
                            text: Translation.tr(root.currentSection.subtitle)
                            color: IrisStyle.muted
                            font.pixelSize: 12 * IrisStyle.typeScale
                            elide: Text.ElideRight
                        }
                    }
                    // Every row carries its iRiS default; this puts the section back
                    // on them. Shared iNiR preferences shown here are left alone.
                    IrisButton {
                        readonly property var resettable: root.specifications
                            .filter(spec => spec.section === root.section && String(spec.path).startsWith("iris."))
                        readonly property bool modified: {
                            Config.revision
                            return resettable.some(spec => JSON.stringify(Config.getNestedValue(spec.path, spec.fallback)) !== JSON.stringify(spec.fallback))
                        }
                        visible: root.query.length === 0 && root.advancedPage < 0 && modified
                        quiet: true
                        text: Translation.tr("Restore defaults")
                        buttonRadius: height / 2
                        onClicked: resettable.forEach(spec => Config.setNestedValue(spec.path, spec.fallback))
                    }
                    IrisIconButton {
                        materialIcon: "close"
                        onClicked: GlobalStates.settingsOverlayOpen = false
                        Accessible.name: Translation.tr("Close settings")
                    }
                }

                Item {
                    id: pageArea
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ParallelAnimation {
                        id: pageEnter
                        NumberAnimation { target: pageArea; property: "opacity"; from: 0.35; to: 1; duration: IrisStyle.duration(160); easing.type: Easing.OutCubic }
                        NumberAnimation { target: pageShift; property: "y"; from: 10 * root.d; to: 0; duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve }
                    }
                    transform: Translate { id: pageShift }

                    Flickable {
                        id: settingsFlick
                        anchors.fill: parent
                        visible: root.advancedPage < 0
                        contentHeight: settingsRows.implicitHeight + 28 * root.d
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        NumberAnimation on contentY { id: scrollTo; running: false; duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve }

                        ColumnLayout {
                            id: settingsRows
                            x: 28 * root.d
                            y: 8 * root.d
                            width: settingsFlick.width - 56 * root.d
                            spacing: 20 * root.d

                            // Guide: the section's badge beside a jump list of its groups,
                            // and one thing worth knowing. The title and subtitle above
                            // already say what the section is; the guide never repeats it.
                            Rectangle {
                                id: guide
                                Layout.fillWidth: true
                                visible: root.query.length === 0 && root.advancedPage < 0
                                implicitHeight: guideContent.implicitHeight + 24 * root.d
                                radius: Math.round(18 * root.d)
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: ColorUtils.mix(IrisStyle.surfaceHigh, root.currentSection.tint, 0.84) }
                                    GradientStop { position: 0.6; color: IrisStyle.surfaceHigh }
                                }
                                ColumnLayout {
                                    id: guideContent
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 12 * root.d
                                    anchors.rightMargin: 14 * root.d
                                    spacing: 8 * root.d
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 12 * root.d
                                        Rectangle {
                                            Layout.alignment: Qt.AlignTop
                                            implicitWidth: Math.round(34 * root.d)
                                            implicitHeight: implicitWidth
                                            radius: Math.round(width * 0.26)
                                            gradient: Gradient {
                                                GradientStop { position: 0; color: Qt.lighter(root.currentSection.tint, 1.2) }
                                                GradientStop { position: 1; color: root.currentSection.tint }
                                            }
                                            MaterialSymbol { anchors.centerIn: parent; text: root.currentSection.icon; fill: 1; iconSize: Math.round(20 * root.d); color: "#ffffff" }
                                        }
                                        Flow {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            spacing: 6 * root.d
                                            Repeater {
                                                model: root.query.length === 0 && root.groups.length > 1 ? root.groups : []
                                                MouseArea {
                                                    id: jump
                                                    required property var modelData
                                                    required property int index
                                                    implicitWidth: jumpLabel.implicitWidth + 24 * root.d
                                                    implicitHeight: Math.round(28 * root.d)
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    Accessible.role: Accessible.Button
                                                    Accessible.name: jump.modelData.title
                                                    onClicked: {
                                                        const target = groupRepeater.itemAt(jump.index)
                                                        if (!target) return
                                                        scrollTo.to = Math.max(0, Math.min(settingsFlick.contentHeight - settingsFlick.height, target.y + settingsRows.y - 8 * root.d))
                                                        scrollTo.restart()
                                                    }
                                                    Rectangle {
                                                        anchors.fill: parent
                                                        radius: height / 2
                                                        color: ColorUtils.applyAlpha(IrisStyle.text, jump.containsMouse ? 0.16 : 0.08)
                                                        Behavior on color { ColorAnimation { duration: IrisStyle.duration(110) } }
                                                    }
                                                    IrisText {
                                                        id: jumpLabel
                                                        anchors.centerIn: parent
                                                        text: jump.modelData.title
                                                        font.pixelSize: 12 * IrisStyle.typeScale
                                                        font.weight: Font.Medium
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 46 * root.d
                                        visible: String(root.currentSection.tip ?? "").length > 0
                                        spacing: 6 * root.d
                                        MaterialSymbol { text: "lightbulb"; fill: 1; iconSize: Math.round(14 * root.d); color: IrisStyle.secondaryAccent }
                                        IrisText {
                                            Layout.fillWidth: true
                                            text: Translation.tr(root.currentSection.tip ?? "")
                                            elide: Text.ElideRight
                                            color: IrisStyle.subtext
                                            font.pixelSize: 12 * IrisStyle.typeScale
                                        }
                                    }
                                }
                            }

                            Loader {
                                Layout.fillWidth: true
                                active: root.section === "bar" && root.query.length === 0
                                visible: active
                                sourceComponent: IslandPreview {}
                            }

                            IrisText {
                                visible: root.query.length > 0 && root.entries.length === 0
                                Layout.topMargin: 24 * root.d
                                Layout.alignment: Qt.AlignHCenter
                                text: Translation.tr("No matching settings")
                                color: IrisStyle.muted
                            }

                            Repeater {
                                id: groupRepeater
                                model: root.groups
                                ColumnLayout {
                                    id: group
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 6 * root.d
                                    IrisText {
                                        Layout.leftMargin: 16 * root.d
                                        text: group.modelData.title
                                        color: IrisStyle.muted
                                        font.pixelSize: 12 * IrisStyle.typeScale
                                        font.weight: Font.DemiBold
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: groupRows.implicitHeight
                                        radius: Math.round(14 * root.d)
                                        color: IrisStyle.surfaceHigh
                                        ColumnLayout {
                                            id: groupRows
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            spacing: 0
                                            Repeater {
                                                model: group.modelData.rows
                                                IrisSetting {
                                                    required property var modelData
                                                    required property int index
                                                    Layout.fillWidth: true
                                                    spec: modelData
                                                    last: index === group.modelData.rows.length - 1
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            LinkCard {
                                visible: root.section === "sidebars" && root.query.length === 0
                                links: [
                                    { label: Translation.tr("Open Focus"), icon: "dock_to_left", action: () => { GlobalStates.settingsOverlayOpen = false; GlobalStates.openSidebarLeft("") } },
                                    { label: Translation.tr("Open Today"), icon: "dock_to_right", action: () => { GlobalStates.settingsOverlayOpen = false; GlobalStates.openSidebarRight("") } }
                                ]
                            }

                            Repeater {
                                model: root.section === "sidebars" && root.query.length === 0 ? ["left", "right"] : []
                                ColumnLayout {
                                    id: panelEditor
                                    required property string modelData
                                    Layout.fillWidth: true
                                    spacing: 8 * root.d
                                    IrisText { text: panelEditor.modelData === "left" ? Translation.tr("Focus sections") : Translation.tr("Today sections"); color: IrisStyle.muted }
                                    IrisSidebarEditor { Layout.fillWidth: true; side: panelEditor.modelData }
                                }
                            }

                            LinkCard {
                                visible: root.section === "desktop" && root.query.length === 0
                                links: [{ label: Translation.tr("Edit desktop widgets"), icon: "edit", action: () => { GlobalStates.settingsOverlayOpen = false; GlobalStates.setWidgetEditMode(true) } }]
                            }

                            LinkCard {
                                visible: root.section === "system" && root.query.length === 0
                                links: root.pages.filter(page => !page.panelFamily || page.panelFamily === "iris").map(page => ({
                                    label: String(page.name ?? page.title ?? page.key),
                                    icon: page.icon ?? "chevron_right",
                                    action: () => root.advancedPage = root.pages.findIndex(candidate => candidate.key === page.key)
                                }))
                            }
                        }
                    }

                    SettingsPageHost {
                        id: pageHost
                        anchors.fill: parent
                        anchors.leftMargin: 12 * root.d
                        anchors.rightMargin: 12 * root.d
                        onCurrentItemChanged: {
                            if (currentItem && root.requestedSection.length > 0
                                && SettingsSearchRegistry.activatePageSection(currentItem, root.requestedSection))
                                root.requestedSection = ""
                        }
                        onCurrentIndexChanged: {
                            if (currentIndex >= 0) GlobalStates.settingsOverlayCurrentPage = currentIndex
                        }
                        visible: root.advancedPage >= 0
                        pages: root.pages
                        requestedIndex: root.advancedPage
                        loadEnabled: visible
                        directNavigation: true
                    }
                }
            }
        }
    }

    component Morph: NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve }

    // A grouped card of navigation rows with chevrons.
    component LinkCard: Rectangle {
        id: card
        property var links: []
        Layout.fillWidth: true
        implicitHeight: linkColumn.implicitHeight
        radius: Math.round(14 * root.d)
        color: IrisStyle.surfaceHigh
        ColumnLayout {
            id: linkColumn
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0
            Repeater {
                model: card.links
                MouseArea {
                    id: link
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: Math.round(44 * root.d)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: link.modelData.label
                    onClicked: link.modelData.action()
                    Rectangle {
                        anchors.fill: parent
                        radius: card.radius
                        color: ColorUtils.applyAlpha(IrisStyle.text, link.containsMouse ? 0.05 : 0)
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * root.d
                        anchors.rightMargin: 12 * root.d
                        spacing: 12 * root.d
                        MaterialSymbol {
                            text: link.modelData.icon
                            iconSize: Math.round(18 * root.d)
                            color: IrisStyle.subtext
                        }
                        IrisText {
                            Layout.fillWidth: true
                            text: link.modelData.label
                            font.pixelSize: 13.5 * IrisStyle.typeScale
                            font.weight: Font.Normal
                            elide: Text.ElideRight
                        }
                        MaterialSymbol {
                            text: "chevron_right"
                            iconSize: Math.round(18 * root.d)
                            color: IrisStyle.muted
                        }
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 46 * root.d
                        height: 1
                        visible: link.index < card.links.length - 1
                        color: IrisStyle.hairline
                    }
                }
            }
        }
    }

    // Live miniature of the Island on a wallpaper strip; follows the options
    // above it with the same morph curve.
    component IslandPreview: ClippingRectangle {
        id: preview
        readonly property var bar: Config.options?.iris?.bar ?? ({})
        readonly property bool cluster: String(preview.bar?.composition ?? "unified") === "cluster"
        readonly property bool atBottom: String(preview.bar?.position ?? "top") === "bottom"
        readonly property bool notch: preview.bar?.notch ?? false
        readonly property real unit: 0.42
        readonly property real pillHeight: Math.max(14, Number(preview.bar?.height ?? 42) * preview.unit)
        readonly property real gap: preview.notch ? 0 : Number(preview.bar?.margin ?? 8) * preview.unit
        implicitHeight: Math.round(132 * root.d)
        radius: Math.round(14 * root.d)
        color: IrisStyle.surfaceHigh
        // The strip is this output's own wallpaper, dimmed so the black shapes
        // read the way they do on the desktop.
        Image {
            anchors.fill: parent
            source: WallpaperListener.wallpaperUrlForScreen(root.screen)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: Math.round(parent.width * 1.5)
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(180); easing.type: Easing.OutCubic } }
        }
        Rectangle { anchors.fill: parent; color: ColorUtils.applyAlpha(IrisStyle.surface, 0.22) }

        // Island chassis.
        Rectangle {
            id: chassis
            width: preview.cluster ? 54 : 118
            height: preview.pillHeight + (preview.notch ? radius : 0)
            radius: preview.pillHeight / 2
            x: (preview.width - width) / 2
            y: preview.atBottom ? preview.height - preview.pillHeight - preview.gap - (preview.notch ? 0 : 6) : (preview.notch ? -radius : preview.gap + 6)
            color: "#000000"
            Behavior on width { Morph {} }
            Behavior on y { Morph {} }
            IrisText {
                anchors.horizontalCenter: parent.horizontalCenter
                y: (preview.notch && !preview.atBottom ? chassis.radius : 0) + (preview.pillHeight - height) / 2
                text: DateTime.timeDisplay
                color: "#ffffff"
                font.pixelSize: Math.max(8, preview.pillHeight * 0.36)
                font.weight: Font.DemiBold
            }
        }
        Repeater {
            model: 3
            Rectangle {
                required property int index
                readonly property bool auxiliary: index === 2
                readonly property bool shown: auxiliary ? (preview.bar?.auxiliary ?? "tray") !== "none" : preview.cluster
                width: preview.pillHeight - (preview.notch ? 3 : 0)
                height: width
                radius: width / 2
                color: "#000000"
                y: preview.atBottom ? preview.height - preview.pillHeight - preview.gap - (preview.notch ? 0 : 6) + (preview.pillHeight - height) / 2
                    : (preview.notch ? 0 : preview.gap + 6) + (preview.pillHeight - height) / 2
                x: shown
                    ? (index === 0 ? chassis.x - width - 3 : chassis.x + chassis.width + 3 + (auxiliary && preview.cluster ? width + 3 : 0))
                    : chassis.x + (chassis.width - width) / 2
                opacity: shown ? 1 : 0
                IrisText {
                    anchors.centerIn: parent
                    visible: parent.auxiliary
                    text: (preview.bar?.auxiliary ?? "tray") === "tray" ? "3" : "•"
                    color: IrisStyle.accent
                    font.pixelSize: 9
                }
                Behavior on x { Morph {} }
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120) } }
            }
        }
        // Dock, opposite the Island.
        Rectangle {
            readonly property bool dockNotch: Config.options?.iris?.dock?.notch ?? false
            visible: Config.options?.iris?.dock?.enable ?? true
            width: 150
            height: 20
            radius: dockNotch ? 6 : 8
            x: (preview.width - width) / 2
            y: preview.atBottom ? (dockNotch ? -6 : 8) : preview.height - height - (dockNotch ? -6 : 8)
            color: "#000000"
            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: parent.dockNotch ? (preview.atBottom ? 3 : -3) : 0
                spacing: 5
                Repeater {
                    model: 7
                    Rectangle { width: 11; height: 11; radius: 3; color: Qt.rgba(1, 1, 1, 0.22 + (index % 3) * 0.12); required property int index }
                }
            }
        }
    }
}
