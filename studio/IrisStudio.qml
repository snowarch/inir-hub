pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.frame
import qs.modules.iris.components
import qs.modules.iris.settings
import qs.modules.iris.style

PanelWindow {
    id: root
    readonly property real d: IrisStyle.density
    property string target: "material"

    readonly property var targets: [
        { id: "material", label: "Material", glyph: "layers" },
        { id: "colour", label: "Colour", glyph: "palette" },
        { id: "type", label: "Type", glyph: "text_fields" },
        { id: "motion", label: "Motion", glyph: "animation" },
        { id: "island", label: "Island", glyph: "pill" },
        { id: "pieces", label: "Pieces", glyph: "bubble_chart" },
        { id: "bodies", label: "Bodies", glyph: "web_asset" },
        { id: "places", label: "Places", glyph: "space_dashboard" },
        { id: "transients", label: "Feedback", glyph: "notifications" },
        { id: "dock", label: "Dock", glyph: "dock_to_bottom" },
        { id: "desktop", label: "Desktop", glyph: "widgets" },
        { id: "themes", label: "Themes", glyph: "style" }
    ]
    readonly property var presetOrder: ["iris", "soft", "crisp", "contrast"]

    readonly property var specifications: [
        { target: "material", group: "Material", label: "Material", description: "What every surface is made of. Raised steps, fills and the frame follow it.", path: "iris.appearance.theme.surface", kind: "choice", fallback: "black", choices: [{label:"Black",value:"black",swatch:IrisStyle.materialSwatch("black")},{label:"Graphite",value:"graphite",swatch:IrisStyle.materialSwatch("graphite")},{label:"Midnight",value:"midnight",swatch:IrisStyle.materialSwatch("midnight")},{label:"Wallpaper",value:"wallpaper",swatch:IrisStyle.materialSwatch("wallpaper")}] },
        { target: "material", group: "Material", label: "Fills", description: "Groups, tracks, hovered and pressed controls.", path: "iris.appearance.theme.fill", kind: "range", fallback: 100, min: 30, max: 200, step: 5, unit: " %" },
        { target: "material", group: "Material", label: "Lines", description: "Hairlines and borders. 0 removes them.", path: "iris.appearance.theme.lines", kind: "range", fallback: 100, min: 0, max: 200, step: 5, unit: " %" },
        { target: "material", group: "Material", label: "Shadows", description: "Under bodies floating over windows.", path: "iris.appearance.theme.shadow", kind: "range", fallback: 100, min: 0, max: 160, step: 5, unit: " %" },
        { target: "material", group: "Material", label: "Outline", description: "A hairline around every silhouette, so black holds over dark windows.", path: "iris.appearance.theme.rim", kind: "switch", fallback: true },
        { target: "material", group: "Shape", label: "Corners", description: "Every radius in the family; nested corners keep stepping down.", path: "iris.appearance.theme.shape", kind: "range", fallback: 100, min: 30, max: 160, step: 5, unit: " %" },
        { target: "material", group: "Shape", label: "Fusion", description: "How deeply shapes melt where they meet. 0 keeps crisp joins.", path: "iris.appearance.theme.melt", kind: "range", fallback: 0, min: 0, max: 200, step: 5, unit: " %" },
        { target: "material", group: "Shape", label: "Spacing", description: "Padding, gaps and control sizes.", path: "iris.appearance.density", kind: "range", fallback: 1, min: 0.8, max: 1.35, step: 0.05, unit: "×" },
        { target: "material", group: "Frame", label: "Close the shell around the screen", description: "One black band on every edge, with the screen's corners turned inward. Windows and the Island sit inside it.", path: "iris.surround.enable", kind: "switch", fallback: false },
        { target: "material", group: "Frame", label: "Band", description: "How thick the edge is.", path: "iris.surround.thickness", visibleWhen: "iris.surround.enable", kind: "range", fallback: 10, min: 2, max: 40, unit: " px" },
        { target: "material", group: "Frame", label: "Inner corners", description: "How far the corners turn inward.", path: "iris.surround.radius", visibleWhen: "iris.surround.enable", kind: "range", fallback: 22, min: 0, max: 64, unit: " px" },
        { target: "colour", group: "Accent", label: "System accent", description: "Selection and controls across iRiS. Activity colours keep their identity.", path: "iris.appearance.accent", kind: "choice", fallback: "blue", choices: [{label:"Blue",value:"blue",swatch:IrisStyle.accents.blue},{label:"Mint",value:"mint",swatch:IrisStyle.accents.mint},{label:"Rose",value:"rose",swatch:IrisStyle.accents.rose},{label:"Lilac",value:"lilac",swatch:IrisStyle.accents.lilac},{label:"Wallpaper",value:"wallpaper"},{label:"Custom",value:"custom"}] },
        { target: "colour", group: "Accent", label: "Accent hue", visibleWhen: "iris.appearance.accent=custom", path: "iris.appearance.theme.accentHue", kind: "hue", fallback: 212 },
        { target: "colour", group: "Highlight", label: "Highlight", description: "The glanced detail: clock separator, day number, timers.", path: "iris.appearance.highlight", kind: "choice", fallback: "orange", choices: [{label:"Orange",value:"orange",swatch:IrisStyle.highlights.orange},{label:"Yellow",value:"yellow",swatch:IrisStyle.highlights.yellow},{label:"Red",value:"red",swatch:IrisStyle.highlights.red},{label:"Pink",value:"pink",swatch:IrisStyle.highlights.pink},{label:"Green",value:"green",swatch:IrisStyle.highlights.green},{label:"Accent",value:"accent"},{label:"Wallpaper",value:"wallpaper"},{label:"Custom",value:"custom"}] },
        { target: "colour", group: "Highlight", label: "Highlight hue", visibleWhen: "iris.appearance.highlight=custom", path: "iris.appearance.theme.highlightHue", kind: "hue", fallback: 32 },
        { target: "colour", group: "Badges", label: "Unread counts", description: "The family's red, your accent, the highlight, or a quiet neutral.", path: "iris.appearance.theme.badge", kind: "choice", fallback: "alert", choices: [{label:"Alert",value:"alert",swatch:IrisStyle.identity.red},{label:"Accent",value:"accent"},{label:"Highlight",value:"highlight",swatch:IrisStyle.secondaryAccent},{label:"Neutral",value:"neutral",swatch:IrisStyle.surfaceHighestOpaque}] },
        { target: "colour", group: "Light", label: "Light", description: "What an open card or panel is lit by: its own colour — the sky for weather, the highlight for timers — or the wallpaper's. It pours in from where the body grew.", path: "iris.appearance.aura", kind: "choice", fallback: "subtle", choices: [{label:"Off",value:"off",glyph:"light_off"},{label:"Subtle",value:"subtle",glyph:"light_mode"},{label:"Vivid",value:"vivid",glyph:"wb_sunny"}] },
        { target: "colour", group: "Light", label: "Reach", description: "How far the light goes into a body: just its head, or deeper.", path: "iris.appearance.theme.lightReach", kind: "range", fallback: 100, min: 50, max: 300, step: 5, unit: " %" },
        { target: "colour", group: "Wallpaper", label: "Wallpaper tint", description: "How much of the wallpaper the black carries. The Island stays black; raised surfaces and fills take the trace.", path: "iris.appearance.tint", kind: "range", fallback: 0, min: 0, max: 100, step: 5, unit: "%" },
        { target: "type", group: "Text", label: "Size", description: "Text across iRiS, on top of the system scale.", path: "iris.appearance.theme.text", kind: "range", fallback: 100, min: 85, max: 125, step: 5, unit: " %" },
        { target: "type", group: "Text", label: "Contrast", description: "Secondary and quiet text.", path: "iris.appearance.theme.contrast", kind: "range", fallback: 100, min: 60, max: 150, step: 5, unit: " %" },
        { target: "type", group: "Faces", label: "Text", path: "iris.appearance.fontFamily", kind: "choice", previewFont: true, fallback: "", choices: [{label:"Noto Sans",value:""},{label:"Rubik",value:"Rubik"},{label:"Readex Pro",value:"Readex Pro"},{label:"Roboto Flex",value:"Roboto Flex"}] },
        { target: "type", group: "Faces", label: "Titles", path: "iris.appearance.titleFontFamily", kind: "choice", previewFont: true, fallback: "", choices: [{label:"Readex Pro",value:""},{label:"Noto Sans",value:"Noto Sans"},{label:"Gabarito",value:"Gabarito"},{label:"Space Grotesk",value:"Space Grotesk"}] },
        { target: "type", group: "Faces", label: "Figures", description: "Clocks, timers and levels.", path: "iris.appearance.numbersFontFamily", kind: "choice", previewFont: true, fallback: "", choices: [{label:"Rubik",value:""},{label:"Readex Pro",value:"Readex Pro"},{label:"Noto Sans",value:"Noto Sans"},{label:"Space Grotesk",value:"Space Grotesk"}] },
        { target: "type", group: "Faces", label: "Figure weight", path: "iris.appearance.figureWeight", kind: "choice", fallback: "bold", choices: [{label:"Light",value:"light"},{label:"Regular",value:"regular"},{label:"Bold",value:"bold"}] },
        { target: "motion", group: "Motion", label: "Movement", description: "How every shape iRiS grows moves. Direct is the iRiS motion: fast out, settles without bouncing. Liquid and Elastic are springs with a settle or a bounce, Glide is slow and even, Snap is terse.", path: "iris.appearance.morph", kind: "choice", fallback: "direct", choices: [{label:"Direct",value:"direct",glyph:"north_east"},{label:"Liquid",value:"liquid",glyph:"water_drop"},{label:"Glide",value:"glide",glyph:"swipe_right_alt"},{label:"Snap",value:"snap",glyph:"bolt"},{label:"Elastic",value:"elastic",glyph:"airwave"}] },
        { target: "motion", group: "Curve", label: "Curve", visibleWhen: "iris.appearance.motion", description: "The path every Direct morph follows. Expressive leaves fast and lands softly; Standard is even; Gentle eases in and out; Swift is short and sharp.", path: "iris.appearance.theme.curve", kind: "choice", fallback: "expressive", choices: [{label:"Expressive",value:"expressive",glyph:"north_east"},{label:"Standard",value:"standard",glyph:"trending_up"},{label:"Gentle",value:"gentle",glyph:"moving"},{label:"Swift",value:"swift",glyph:"bolt"},{label:"Custom",value:"custom",glyph:"draw"}] },
        { target: "motion", group: "Curve", label: "Shape", visibleWhen: "iris.appearance.motion", description: "Drag the two handles. The curve becomes Custom.", path: "iris.appearance.theme.curvePoints", kind: "curve", fallback: [0.16, 1, 0.3, 1] },
        { target: "motion", group: "Timing", label: "Open and close", visibleWhen: "iris.appearance.motion", description: "How long a shape takes to grow out of what opened it and fold back.", path: "iris.appearance.theme.openTime", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Timing", label: "Adjusting", visibleWhen: "iris.appearance.motion", description: "How long an open shape takes to change size, like switching pages.", path: "iris.appearance.theme.moveTime", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Timing", label: "Content arrives", visibleWhen: "iris.appearance.motion", description: "Lower shows what is inside while the shape is still growing; higher waits until it has formed.", path: "iris.appearance.theme.contentTiming", kind: "range", fallback: 100, min: 30, max: 170, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Island", visibleWhen: "iris.appearance.motion", description: "Speed of this surface's morph. 100 % follows the timing above.", path: "iris.appearance.surfaces.island.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Cards", visibleWhen: "iris.appearance.motion", path: "iris.appearance.surfaces.cards.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Control Center", visibleWhen: "iris.appearance.motion", path: "iris.appearance.surfaces.controlCenter.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Side panels", visibleWhen: "iris.appearance.motion", path: "iris.appearance.surfaces.panels.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Spotlight", visibleWhen: "iris.appearance.motion", path: "iris.appearance.surfaces.spotlight.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Settings and Studio", visibleWhen: "iris.appearance.motion", path: "iris.appearance.surfaces.settings.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Menus", visibleWhen: "iris.appearance.motion", path: "iris.appearance.surfaces.menus.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Per surface", label: "Wallpaper gallery", visibleWhen: "iris.appearance.motion", path: "iris.appearance.surfaces.gallery.speed", kind: "range", fallback: 100, min: 40, max: 250, step: 5, unit: " %" },
        { target: "motion", group: "Touch", label: "Press depth", description: "How far buttons, bubbles and the Island dip under a press. 0 keeps them still.", path: "iris.appearance.theme.press", kind: "range", fallback: 100, min: 0, max: 200, step: 10, unit: " %" },
        { target: "motion", group: "Motion", label: "Duration", visibleWhen: "iris.appearance.motion", description: "How long a shape takes to grow out of what opened it.", path: "iris.appearance.motionDuration", kind: "range", fallback:220,min:100,max:400,step:10,unit:" ms" },
        { target: "motion", group: "Motion", label: "Bounce", visibleWhen: "iris.appearance.motion", description: "How far arrivals and moves pass their place before settling, as a share of the style's own. 0 never bounces; leaving never does.", path: "iris.appearance.theme.bounce", kind: "range", fallback: 100, min: 0, max: 200, step: 10, unit: " %" },
        { target: "island", group: "Shape", label: "Island layout", description: "Hug its content in the middle, hug one end, or span the whole edge as a bar.", path: "iris.bar.layout", kind: "choice", fallback: "island", choices: [{label:"Island",value:"island",glyph:"pill"},{label:"Left",value:"left",glyph:"align_horizontal_left"},{label:"Right",value:"right",glyph:"align_horizontal_right"},{label:"Full width",value:"full",glyph:"width_full"}] },
        { target: "island", group: "Shape", label: "Screen edge", path: "iris.bar.position", kind: "choice", fallback: "top", choices: [{label:"Top",value:"top",glyph:"vertical_align_top"},{label:"Bottom",value:"bottom",glyph:"vertical_align_bottom"}] },
        { target: "island", group: "Shape", label: "Attach as a notch", description: "Melts the Island into the screen edge.", path: "iris.bar.notch", kind: "switch", fallback: false },
        { target: "island", group: "Shape", label: "Notch curve", visibleWhen: "iris.bar.notch", description: "How wide the shoulders are where the Island turns into its edge.", path: "iris.bar.notchCurve", kind: "range", fallback: 100, min: 20, max: 200, step: 5, unit: " %" },
        { target: "island", group: "Shape", label: "Bubble gap", description: "How far the bubbles beside the Island rest from it.", path: "iris.bar.satelliteGap", kind: "range", fallback: 6, min: 0, max: 24, unit: " px" },
        { target: "island", group: "Shape", label: "Height", path: "iris.bar.height", kind: "range", fallback:42,min:32,max:64,unit:" px" },
        { target: "island", group: "Shape", label: "Gap from the edge", path: "iris.bar.margin", kind: "range", fallback:8,min:0,max:24,unit:" px" },
        { target: "island", group: "Shape", label: "Expanded corners", path: "iris.appearance.expandedRadius", kind: "range", fallback:28,min:16,max:40,unit:" px" },
        { target: "island", group: "At rest", label: "Clock", description: "What the resting Island shows beside the time.", path: "iris.bar.clockStyle", kind: "choice", fallback: "dateTime", choices: [{label:"Time",value:"time"},{label:"Date",value:"dateTime"},{label:"Weather",value:"weather"}] },
        { target: "island", group: "At rest", label: "Utility island", description: "Emerges beside the Island; the tray hides when no apps are present.", path: "iris.bar.auxiliary", kind: "choice", fallback: "tray", choices: [{label:"Tray",value:"tray"},{label:"Timers",value:"tools"},{label:"Sound",value:"sound"},{label:"Microphone",value:"mic"},{label:"None",value:"none"}] },
        { target: "island", group: "Desktop page", label: "Header", description: "What sits behind the time when the Island shows your desktop.", path: "iris.bar.desktopBanner", kind: "choice", fallback: "wallpaper", choices: [{label:"Wallpaper",value:"wallpaper"},{label:"None",value:"none"}] },
        { target: "island", group: "Desktop page", label: "Blocks", description: "What sits under the time, in the order you switch them on. You can also arrange them on the Island itself: open its desktop page and tap the pencil.", path: "iris.bar.desktopBlocks", kind: "pieces", fallback: ["profile", "context", "vitals", "modules"], choices: [{label:"Profile",value:"profile"},{label:"Current app",value:"context"},{label:"Forecast",value:"forecast"},{label:"Up next",value:"agenda"},{label:"Vitals",value:"vitals"},{label:"Modules",value:"modules"}] },
        { target: "island", group: "Player page", label: "Blocks", description: "What the player page shows, in the order you switch them on.", path: "iris.bar.mediaBlocks", kind: "pieces", fallback: ["player", "timeline", "transport", "players", "levels"], choices: [{label:"Now playing",value:"player"},{label:"Timeline",value:"timeline"},{label:"Controls",value:"transport"},{label:"Other players",value:"players"},{label:"App volume",value:"levels"}] },
        { target: "pieces", group: "Size", label: "Bubble size", description: "Bubbles off the Island, as a share of the Island's height.", path: "iris.bubbles.scale", kind: "range", fallback: 100, min: 60, max: 140, step: 5, unit: " %" },
        { target: "pieces", group: "On the contour", label: "Group into a bar", description: "Bubbles resting in the same place share one plate and read as a small bar; off, each one floats as its own disc.", path: "iris.bubbles.cluster", kind: "switch", fallback: true },
        { target: "pieces", group: "On the contour", label: "Keep them on the frame", description: "Bubbles in a corner or on an edge sit on the shell's own edge, where they read as a swelling of it, instead of floating over your windows.", path: "iris.bubbles.attach", kind: "switch", fallback: true },
        { target: "bodies", group: "Cards", label: "Corners", description: "Auto keeps the family's shape for cards.", path: "iris.appearance.surfaces.cards.radius", kind: "range", fallback: 0, min: 0, max: 44, unit: " px", zeroLabel: "Auto" },
        { target: "bodies", group: "Joining", label: "Opens", description: "Where a card or the Control Center grows from a bubble: away from the edge it sits on, or along it.", path: "iris.appearance.theme.placement", kind: "choice", fallback: "auto", choices: [{label:"Away from the edge",value:"auto",glyph:"open_in_new"},{label:"Along the edge",value:"along",glyph:"swap_vert"}] },
        { target: "bodies", group: "Joining", label: "Air", description: "The space between what opened and the bar or bubble it came from.", path: "iris.appearance.theme.air", kind: "range", fallback: 8, min: 0, max: 40, unit: " px" },
        { target: "bodies", group: "Joining", label: "Join width", description: "How wide the bridge to the bubble is, as a share of the bubble.", path: "iris.appearance.theme.neck", kind: "range", fallback: 62, min: 20, max: 100, step: 2, unit: " %" },
        { target: "bodies", group: "Joining", label: "Fusion", description: "How deeply bodies melt where they touch. 0 keeps joins crisp; the join to a bubble and the notch keep their own shape.", path: "iris.appearance.theme.melt", kind: "range", fallback: 0, min: 0, max: 200, step: 5, unit: " %" },
        { target: "bodies", group: "Cards", label: "Width", description: "Auto keeps the family's width.", path: "iris.appearance.surfaces.cards.width", kind: "range", fallback: 0, min: 0, max: 560, step: 10, unit: " px", zeroLabel: "Auto" },
        { target: "bodies", group: "Cards", label: "Light", description: "Its own colour, the wallpaper's, or plain black.", path: "iris.appearance.surfaces.cards.light", kind: "choice", fallback: "inherit", choices: [{label:"Own",value:"inherit",glyph:"auto_awesome"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Off",value:"off",glyph:"light_off"}] },
        { target: "bodies", group: "Card contents", label: "Header", description: "The glyph, name and figure at the top of the sound and microphone cards.", path: "iris.appearance.surfaces.cards.header", kind: "switch", fallback: true },
        { target: "bodies", group: "Card contents", label: "Devices", description: "Pick the output or input right inside the card.", path: "iris.appearance.surfaces.cards.devices", kind: "switch", fallback: true },
        { target: "bodies", group: "Card contents", label: "App volumes", description: "Each app's level under the sound card.", path: "iris.appearance.surfaces.cards.mixer", kind: "switch", fallback: true },
        { target: "bodies", group: "Control Center", label: "Corners", description: "Auto keeps the family's shape for the panel.", path: "iris.appearance.surfaces.controlCenter.radius", kind: "range", fallback: 0, min: 0, max: 44, unit: " px", zeroLabel: "Auto" },
        { target: "bodies", group: "Control Center", label: "Light", description: "Its own colour, the wallpaper's, or plain black.", path: "iris.appearance.surfaces.controlCenter.light", kind: "choice", fallback: "inherit", choices: [{label:"Own",value:"inherit",glyph:"auto_awesome"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Off",value:"off",glyph:"light_off"}] },
        { target: "bodies", group: "Control Center", label: "Sections", description: "What the panel shows, in the order you switch them on. Connectivity and music share a row, and so do shortcuts and levels.", path: "iris.controlCenter.sections", kind: "pieces", fallback: ["connectivity", "media", "shortcuts", "levels", "notifications"], choices: [{label:"Connectivity",value:"connectivity"},{label:"Music",value:"media"},{label:"Shortcuts",value:"shortcuts"},{label:"Levels",value:"levels"},{label:"Notifications",value:"notifications"}] },
        { target: "bodies", group: "Control Center", label: "Quick actions", description: "Tiles are wide glyph plates on the panel; Round makes them the same body as the connectivity toggles.", path: "iris.controlCenter.controls", kind: "choice", fallback: "tiles", choices: [{label:"Tiles",value:"tiles",glyph:"grid_view"},{label:"Round",value:"round",glyph:"radio_button_checked"}] },
        { target: "bodies", group: "Control Center", label: "Width", path: "iris.controlCenter.width", kind: "range", fallback:360,min:320,max:540,step:10,unit:" px" },
        { target: "bodies", group: "Player", label: "Round album cover", path: "iris.player.roundCover", kind: "switch", fallback:true },
        { target: "bodies", group: "Player", label: "Blurred album background", description: "Tints the expanded Island and media cards with the cover.", path: "iris.player.artworkBackground", kind: "switch", fallback:true },
        { target: "places", group: "Side panels", label: "Corners", description: "Auto keeps the family's shape for side panels.", path: "iris.appearance.surfaces.panels.radius", kind: "range", fallback: 0, min: 0, max: 44, unit: " px", zeroLabel: "Auto" },
        { target: "places", group: "Side panels", label: "Light", description: "Its own colour, the wallpaper's, or plain black.", path: "iris.appearance.surfaces.panels.light", kind: "choice", fallback: "inherit", choices: [{label:"Own",value:"inherit",glyph:"auto_awesome"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Off",value:"off",glyph:"light_off"}] },
        { target: "places", group: "Spotlight", label: "Corners", description: "Auto keeps the family's shape for Spotlight.", path: "iris.appearance.surfaces.spotlight.radius", kind: "range", fallback: 0, min: 0, max: 44, unit: " px", zeroLabel: "Auto" },
        { target: "places", group: "Spotlight", label: "Light", description: "Its own colour, the wallpaper's, or plain black.", path: "iris.appearance.surfaces.spotlight.light", kind: "choice", fallback: "inherit", choices: [{label:"Own",value:"inherit",glyph:"auto_awesome"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Off",value:"off",glyph:"light_off"}] },
        { target: "places", group: "Spotlight", label: "Width", path: "iris.palette.width", kind: "range", fallback:640,min:420,max:900,step:10,unit:" px" },
        { target: "places", group: "Wallpaper gallery", label: "Corners", description: "Auto keeps the family's shape for the gallery.", path: "iris.appearance.surfaces.gallery.radius", kind: "range", fallback: 0, min: 0, max: 44, unit: " px", zeroLabel: "Auto" },
        { target: "places", group: "Wallpaper gallery", label: "Light", description: "Its own colour, the wallpaper's, or plain black.", path: "iris.appearance.surfaces.gallery.light", kind: "choice", fallback: "inherit", choices: [{label:"Own",value:"inherit",glyph:"auto_awesome"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Off",value:"off",glyph:"light_off"}] },
        { target: "places", group: "Wallpaper gallery", label: "Gallery width", path: "iris.wallpaper.width", kind: "range", fallback:960,min:640,max:1400,step:40,unit:" px" },
        { target: "places", group: "Wallpaper gallery", label: "Preview size", path: "iris.wallpaper.thumbnailSize", kind: "range", fallback:228,min:160,max:320,step:8,unit:" px" },
        { target: "places", group: "Settings", label: "Corners", description: "Auto keeps the family's shape for Settings.", path: "iris.appearance.surfaces.settings.radius", kind: "range", fallback: 0, min: 0, max: 44, unit: " px", zeroLabel: "Auto" },
        { target: "places", group: "Settings", label: "Light", description: "Its own colour, the wallpaper's, or plain black.", path: "iris.appearance.surfaces.settings.light", kind: "choice", fallback: "inherit", choices: [{label:"Own",value:"inherit",glyph:"auto_awesome"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Off",value:"off",glyph:"light_off"}] },
        { target: "places", group: "Menus", label: "Corners", description: "Auto keeps the family's shape for menus.", path: "iris.appearance.surfaces.menus.radius", kind: "range", fallback: 0, min: 0, max: 44, unit: " px", zeroLabel: "Auto" },
        { target: "places", group: "Menus", label: "Light", description: "Its own colour, the wallpaper's, or plain black.", path: "iris.appearance.surfaces.menus.light", kind: "choice", fallback: "inherit", choices: [{label:"Own",value:"inherit",glyph:"auto_awesome"},{label:"Wallpaper",value:"wallpaper",glyph:"wallpaper"},{label:"Off",value:"off",glyph:"light_off"}] },
        { target: "transients", group: "Notifications", label: "Width", path: "iris.notifications.width", visibleWhen: "iris.modules.notificationPopup", kind: "range", fallback: 380, min: 340, max: 560, step: 10, unit: " px" },
        { target: "dock", group: "Look", label: "Attach as a notch", path: "iris.dock.notch", kind: "switch", fallback:false },
        { target: "dock", group: "Look", label: "Compositor blur", description: "Translucent material when the compositor provides blur.", path: "iris.dock.blur", kind: "switch", fallback:false },
        { target: "dock", group: "Icons", label: "Icon size", path: "iris.dock.iconSize", kind: "range", fallback:40,min:28,max:64,unit:" px" },
        { target: "dock", group: "Icons", label: "Magnify on hover", path: "iris.dock.magnification", kind: "switch", fallback:true },
        { target: "dock", group: "Icons", label: "Applications button", description: "Opens Spotlight from the start of the Dock.", path: "iris.dock.launcher", kind: "switch", fallback:true },
        { target: "desktop", group: "Widgets", label: "Widget corners", description: "Individual widget overrides take priority.", path: "iris.widgets.radius", kind: "range", fallback:22,min:0,max:40,unit:" px" },
        { target: "desktop", group: "Widgets", label: "Colour", description: "Wallpaper lifts its hues so they read on black; iRiS follows your system accent.", path: "iris.widgets.tint", kind: "choice", fallback: "wallpaper", choices: [{label:"Wallpaper",value:"wallpaper"},{label:"iRiS",value:"system"}] },
        { target: "desktop", group: "Widgets", label: "Plate", description: "Tinted adds a trace of the chosen widget accent to the black material.", path: "iris.widgets.material", kind: "choice", fallback: "solid", choices: [{label:"Solid",value:"solid"},{label:"Tinted",value:"tinted"}] },
        { target: "desktop", group: "Widgets", label: "Titles and figures", path: "iris.widgets.weight", kind: "choice", fallback: "regular", choices: [{label:"Light",value:"light"},{label:"Regular",value:"regular"},{label:"Bold",value:"bold"}] },
        { target: "desktop", group: "Widgets", label: "Surface opacity", path: "iris.widgets.opacity", kind: "range", fallback:100,min:20,max:100,step:5,unit:" %" }
    ]
    function shown(spec: var): bool {
        const when = String(spec.visibleWhen ?? "")
        if (when.length === 0) return true
        if (when.includes("=")) return String(Config.getNestedValue(when.split("=")[0], "")) === when.split("=")[1]
        const negated = when.startsWith("!")
        const on = Boolean(Config.getNestedValue(negated ? when.slice(1) : when, false))
        return negated ? !on : on
    }
    readonly property var groups: {
        Config.revision
        const out = []
        for (const spec of root.specifications) {
            if (spec.target !== root.target || !root.shown(spec)) continue
            if (out.length === 0 || out[out.length - 1].title !== spec.group) out.push({ title: spec.group, rows: [] })
            out[out.length - 1].rows.push(spec)
        }
        return out
    }

    readonly property var themeTargets: ["material", "colour", "type", "motion"]
    readonly property var themePaths: ["iris.appearance.preset"].concat(root.specifications
        .filter(spec => String(spec.path).startsWith("iris.")
            && (root.themeTargets.includes(spec.target) || String(spec.path).startsWith("iris.appearance.surfaces.")))
        .map(spec => spec.path))
    function fallbackOf(path: string): var {
        if (path === "iris.appearance.preset") return "iris"
        return root.specifications.find(spec => spec.path === path)?.fallback
    }
    function currentValues(): var {
        const values = {}
        for (const path of root.themePaths) values[path] = Config.getNestedValue(path, root.fallbackOf(path))
        return values
    }
    function applyValues(values: var): void {
        const updates = {}
        for (const path of root.themePaths) {
            updates[path] = Object.prototype.hasOwnProperty.call(values ?? {}, path) ? values[path] : root.fallbackOf(path)
        }
        Config.setNestedValues(updates)
    }
    readonly property var looks: [
        { name: "iRiS", description: "Black, direct, lit by what things are.", material: "black", accent: IrisStyle.accents.blue, values: {} },
        { name: "Obsidian", description: "Sharper, quieter, no light. Everything snaps.", material: "black", accent: IrisStyle.accents.lilac,
            values: { "iris.appearance.preset": "crisp", "iris.appearance.theme.lines": 60, "iris.appearance.theme.shadow": 140,
                "iris.appearance.aura": "off", "iris.appearance.morph": "snap", "iris.appearance.accent": "lilac" } },
        { name: "Aurora", description: "The wallpaper's own colour and vivid, far-reaching light.", material: "wallpaper", accent: IrisStyle.wallpaperLight,
            values: { "iris.appearance.theme.surface": "wallpaper", "iris.appearance.aura": "vivid", "iris.appearance.theme.lightReach": 200,
                "iris.appearance.accent": "wallpaper",
                "iris.appearance.highlight": "wallpaper", "iris.appearance.tint": 40 } },
        { name: "Paper", description: "Soft and round, no lines, barely a shadow.", material: "graphite", accent: IrisStyle.accents.mint,
            values: { "iris.appearance.preset": "soft", "iris.appearance.theme.surface": "graphite", "iris.appearance.theme.lines": 0,
                "iris.appearance.theme.shadow": 40, "iris.appearance.theme.shape": 130, "iris.appearance.theme.fill": 80,
                "iris.appearance.accent": "mint" } },
        { name: "Midnight", description: "Deep blue material, violet highlight.", material: "midnight", accent: Qt.hsla(0.64, 0.7, 0.78, 1), // iris-literal: look swatch
            values: { "iris.appearance.theme.surface": "midnight", "iris.appearance.accent": "custom", "iris.appearance.theme.accentHue": 230,
                "iris.appearance.highlight": "custom", "iris.appearance.theme.highlightHue": 280, "iris.appearance.theme.contrast": 110 } },
        { name: "Signal", description: "High contrast, larger text, crisp joins.", material: "black", accent: IrisStyle.highlights.yellow,
            values: { "iris.appearance.preset": "contrast", "iris.appearance.theme.fill": 130, "iris.appearance.theme.text": 108,
                "iris.appearance.aura": "off", "iris.appearance.morph": "snap",
                "iris.appearance.highlight": "yellow", "iris.appearance.accent": "custom", "iris.appearance.theme.accentHue": 52 } }
    ]
    readonly property var saved: Array.from(Config.options?.iris?.appearance?.saved ?? [])
    property string notice: ""
    Timer { id: noticeTimer; interval: 2400; onTriggered: root.notice = "" }
    function say(text: string): void { root.notice = text; noticeTimer.restart() }
    function saveCurrent(name: string): void {
        const clean = name.trim().length > 0 ? name.trim() : Translation.tr("My look %1").arg(root.saved.length + 1)
        const next = root.saved.filter(entry => entry.name !== clean)
        next.push({ name: clean, values: root.currentValues() })
        Config.setNestedValue("iris.appearance.saved", next)
        root.say(Translation.tr("Saved “%1”").arg(clean))
    }
    function removeSaved(name: string): void {
        Config.setNestedValue("iris.appearance.saved", root.saved.filter(entry => entry.name !== name))
    }
    function exportLook(entry: var): void {
        Quickshell.clipboardText = JSON.stringify({ iris: "look", name: entry.name, values: entry.values }, null, 2)
        root.say(Translation.tr("Copied “%1” — paste it anywhere to share it").arg(entry.name))
    }
    function importLook(): void {
        try {
            const data = JSON.parse(String(Quickshell.clipboardText ?? ""))
            if (data?.iris !== "look" || typeof data.values !== "object") throw new Error()
            const values = {}
            for (const path of root.themePaths) if (Object.prototype.hasOwnProperty.call(data.values, path)) values[path] = data.values[path]
            const name = String(data.name ?? Translation.tr("Imported look"))
            const next = root.saved.filter(entry => entry.name !== name)
            next.push({ name: name, values: values })
            Config.setNestedValue("iris.appearance.saved", next)
            root.say(Translation.tr("Imported “%1”").arg(name))
        } catch (error) {
            root.say(Translation.tr("The clipboard does not hold an iRiS look"))
        }
    }

    function preview(id: string, on: bool): void {
        switch (id) {
        case "island":
            if (on) GlobalStates.irisIslandPageRequest = "desktop"
            else GlobalStates.irisArrange = false
            break
        case "bodies":
            GlobalStates.controlPanelOpen = on
            break
        case "places":
            if (on) GlobalStates.openSidebarRight("")
            else GlobalStates.sidebarRightOpen = false
            break
        case "dock":
            GlobalStates.irisDockShown = on
            break
        }
    }
    function select(id: string): void {
        if (id === root.target) return
        root.preview(root.target, false)
        root.target = id
        root.preview(id, true)
        flick.contentY = 0
    }
    function takeRequest(): void {
        const wanted = GlobalStates.irisStudioTarget
        if (wanted.length === 0) return
        GlobalStates.irisStudioTarget = ""
        if (root.targets.some(entry => entry.id === wanted)) root.select(wanted)
    }
    Component.onCompleted: root.takeRequest()
    Connections {
        target: GlobalStates
        function onIrisStudioTargetChanged(): void { root.takeRequest() }
        function onIrisStudioOpenChanged(): void {
            if (GlobalStates.irisStudioOpen) root.preview(root.target, true)
            else root.preview(root.target, false)
        }
    }
    function resetTarget(): void {
        const updates = {}
        for (const spec of root.specifications) {
            if (spec.target === root.target && String(spec.path).startsWith("iris.")) updates[spec.path] = spec.fallback
        }
        Config.setNestedValues(updates)
    }

    readonly property var presentedRect: GlobalStates.irisStudioOpen && frame.armed
        ? { screen: root.screen?.name ?? "", x: frame.x, y: frame.y, width: frame.width, height: frame.height } : null
    onPresentedRectChanged: GlobalStates.irisStudioRect = root.presentedRect
    Component.onDestruction: GlobalStates.irisStudioRect = null

    visible: GlobalStates.irisStudioOpen || frame.progress > 0
    IrisOutputHold {
        id: outputHold
        wanted: GlobalStates.focusedScreen
        live: root.visible
    }
    screen: outputHold.output
    color: "transparent"
    anchors { left: true; top: true; bottom: true }
    implicitWidth: frame.width + Math.round(24 * root.d) + IrisFrame.band
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:iris-studio"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: GlobalStates.irisStudioOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { item: frame }

    Shortcut { sequence: "Escape"; enabled: GlobalStates.irisStudioOpen; onActivated: GlobalStates.irisStudioOpen = false }

    IrisMorphSurface {
        id: frame
        open: GlobalStates.irisStudioOpen
        motionSurface: "settings"
        radius: IrisStyle.surfaceRadius("settings", IrisStyle.radiusPanel)
        light: IrisStyle.surfaceLight("settings", IrisStyle.wallpaperLight)
        x: Math.round(12 * root.d) + IrisFrame.band
        y: (parent.height - height) / 2
        width: Math.round(396 * root.d)
        height: Math.min(parent.height - Math.round(24 * root.d) - IrisFrame.band * 2, Math.round(900 * root.d))
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(18 * root.d)
            spacing: Math.round(14 * root.d)

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(10 * root.d)
                IrisMark { implicitSize: Math.round(26 * root.d) }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    IrisText {
                        text: Translation.tr("Studio")
                        font.family: IrisStyle.fontTitle
                        font.pixelSize: 21 * IrisStyle.typeScale
                        font.weight: Font.Bold
                    }
                    IrisText {
                        Layout.fillWidth: true
                        text: root.notice.length > 0 ? root.notice : Translation.tr("Everything you change is the shell itself")
                        color: root.notice.length > 0 ? IrisStyle.accent : IrisStyle.muted
                        font.pixelSize: 12 * IrisStyle.typeScale
                        elide: Text.ElideRight
                    }
                }
                IrisIconButton {
                    materialIcon: "close"
                    Accessible.name: Translation.tr("Close Studio")
                    onClicked: GlobalStates.irisStudioOpen = false
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * root.d)
                Repeater {
                    model: root.presetOrder
                    PresetTile {
                        required property string modelData
                        Layout.fillWidth: true
                        name: modelData
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: Math.round(6 * root.d)
                columnSpacing: Math.round(6 * root.d)
                Repeater {
                    model: root.targets
                    TargetTile {
                        required property var modelData
                        Layout.fillWidth: true
                        entry: modelData
                    }
                }
            }

            IrisMotionLab {
                Layout.fillWidth: true
                visible: ["motion", "bodies", "island", "pieces"].includes(root.target)
                mode: root.target === "island" ? "island" : "card"
            }

            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: rows.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                ColumnLayout {
                    id: rows
                    width: flick.width
                    spacing: Math.round(16 * root.d)

                    Repeater {
                        model: root.target === "themes" ? [] : root.groups
                        GroupCard {
                            id: groupCard
                            required property var modelData
                            Layout.fillWidth: true
                            title: groupCard.modelData.title
                            Repeater {
                                model: groupCard.modelData.rows
                                IrisSetting {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    spec: modelData
                                    last: index === groupCard.modelData.rows.length - 1
                                }
                            }
                        }
                    }

                    GroupCard {
                        Layout.fillWidth: true
                        visible: root.target === "themes"
                        title: Translation.tr("Looks")
                        plain: true
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: Math.round(8 * root.d)
                            columnSpacing: Math.round(8 * root.d)
                            Repeater {
                                model: root.target === "themes" ? root.looks : []
                                LookTile {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    look: modelData
                                }
                            }
                        }
                    }
                    GroupCard {
                        Layout.fillWidth: true
                        visible: root.target === "themes"
                        title: Translation.tr("Yours")
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.margins: Math.round(12 * root.d)
                            spacing: Math.round(8 * root.d)
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: Math.round(32 * root.d)
                                radius: height / 2
                                color: nameField.activeFocus ? IrisStyle.fill : IrisStyle.fillQuiet
                                TextInput {
                                    id: nameField
                                    anchors.fill: parent
                                    anchors.leftMargin: Math.round(14 * root.d)
                                    anchors.rightMargin: Math.round(14 * root.d)
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: IrisStyle.text
                                    selectionColor: IrisStyle.accentContainer
                                    font.family: IrisStyle.fontMain
                                    font.pixelSize: 13 * IrisStyle.typeScale
                                    clip: true
                                    onAccepted: { root.saveCurrent(text); text = "" }
                                    IrisText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: nameField.text.length === 0
                                        text: Translation.tr("Name this look")
                                        color: IrisStyle.muted
                                        font.pixelSize: nameField.font.pixelSize
                                    }
                                }
                            }
                            IrisButton {
                                emphasized: true
                                text: Translation.tr("Save")
                                buttonRadius: height / 2
                                onClicked: { root.saveCurrent(nameField.text); nameField.text = "" }
                            }
                        }
                        Repeater {
                            model: root.target === "themes" ? root.saved : []
                            SavedRow {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                entry: modelData
                            }
                        }
                        IrisText {
                            Layout.fillWidth: true
                            Layout.leftMargin: Math.round(14 * root.d)
                            Layout.rightMargin: Math.round(14 * root.d)
                            Layout.bottomMargin: Math.round(12 * root.d)
                            visible: root.saved.length === 0
                            text: Translation.tr("Saved looks keep every value you set here, and can be shared as text.")
                            color: IrisStyle.muted
                            font.pixelSize: 11.5 * IrisStyle.typeScale
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * root.d)
                IrisButton {
                    visible: root.target !== "themes"
                    quiet: true
                    text: Translation.tr("Reset")
                    buttonRadius: height / 2
                    onClicked: root.resetTarget()
                }
                IrisButton {
                    visible: root.target === "themes"
                    quiet: true
                    text: Translation.tr("Paste a look")
                    buttonRadius: height / 2
                    onClicked: root.importLook()
                }
                Item { Layout.fillWidth: true }
                IrisButton {
                    visible: root.target === "island"
                    selected: GlobalStates.irisArrange
                    text: GlobalStates.irisArrange ? Translation.tr("Arranging") : Translation.tr("Arrange blocks")
                    buttonRadius: height / 2
                    onClicked: {
                        if (!GlobalStates.irisArrange) GlobalStates.irisIslandPageRequest = "desktop"
                        GlobalStates.irisArrange = !GlobalStates.irisArrange
                    }
                }
                IrisButton {
                    visible: root.target === "bodies"
                    text: Translation.tr("Show a card")
                    buttonRadius: height / 2
                    onClicked: { GlobalStates.controlPanelOpen = false; GlobalStates.irisBubbleCardRequest = "weather" }
                }
                IrisButton {
                    visible: root.target === "transients"
                    text: Translation.tr("Show a level")
                    buttonRadius: height / 2
                    onClicked: GlobalStates.osdVolumeOpen = true
                }
                IrisButton {
                    quiet: true
                    text: Translation.tr("All settings")
                    buttonRadius: height / 2
                    onClicked: { GlobalStates.irisStudioOpen = false; GlobalStates.openSettings() }
                }
            }
        }
    }

    component GroupCard: ColumnLayout {
        id: card
        property string title: ""
        property bool plain: false
        default property alias rows: body.data
        spacing: Math.round(6 * root.d)
        IrisText {
            Layout.leftMargin: Math.round(14 * root.d)
            text: Translation.tr(card.title)
            color: IrisStyle.muted
            font.pixelSize: 12 * IrisStyle.typeScale
            font.weight: Font.DemiBold
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: body.implicitHeight
            radius: IrisStyle.radiusTile
            color: card.plain ? "transparent" : IrisStyle.surfaceHigh
            ColumnLayout {
                id: body
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0
            }
        }
    }

    component PresetTile: MouseArea {
        id: tile
        required property string name
        readonly property var values: IrisStyle.presets[tile.name] ?? IrisStyle.presets.iris
        readonly property bool selected: IrisStyle.presetName === tile.name
        implicitHeight: Math.round(74 * root.d)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.RadioButton
        Accessible.name: tile.name
        Accessible.checked: tile.selected
        onClicked: Config.setNestedValue("iris.appearance.preset", tile.name)
        Rectangle {
            id: miniature
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.round(52 * root.d)
            radius: Math.round(14 * tile.values.shape * root.d)
            color: IrisStyle.surfaceOpaque
            border.width: tile.selected ? 2 : 1
            border.color: tile.selected ? IrisStyle.accent : (tile.containsMouse ? IrisStyle.borderStrong : IrisStyle.border)
            Behavior on border.color { ColorAnimation { duration: IrisStyle.duration(110) } }
            Column {
                anchors.fill: parent
                anchors.margins: Math.round(8 * root.d)
                spacing: Math.round(4 * root.d)
                Rectangle {
                    width: parent.width
                    height: Math.round(16 * root.d)
                    radius: Math.round(7 * tile.values.shape * root.d)
                    color: Qt.alpha(IrisStyle.text, Math.min(0.5, 0.12 * tile.values.fill))
                }
                Row {
                    spacing: Math.round(4 * root.d)
                    Rectangle { width: Math.round(18 * root.d); height: Math.round(9 * root.d); radius: height / 2; color: IrisStyle.accent }
                    Rectangle { width: Math.round(26 * root.d); height: Math.round(9 * root.d); radius: height / 2; color: Qt.alpha(IrisStyle.text, tile.values.textTertiary) }
                }
            }
        }
        IrisText {
            anchors.top: miniature.bottom
            anchors.topMargin: Math.round(4 * root.d)
            anchors.horizontalCenter: parent.horizontalCenter
            text: Translation.tr(tile.name.charAt(0).toUpperCase() + tile.name.slice(1))
            color: tile.selected ? IrisStyle.text : IrisStyle.subtext
            font.pixelSize: 11.5 * IrisStyle.typeScale
            font.weight: tile.selected ? Font.DemiBold : Font.Normal
        }
    }

    component TargetTile: MouseArea {
        id: targetTile
        required property var entry
        readonly property bool selected: root.target === targetTile.entry.id
        implicitHeight: Math.round(50 * root.d)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.RadioButton
        Accessible.name: Translation.tr(targetTile.entry.label)
        Accessible.checked: targetTile.selected
        onClicked: root.select(targetTile.entry.id)
        Rectangle {
            anchors.fill: parent
            radius: IrisStyle.radiusTile
            color: targetTile.selected ? IrisStyle.tintFill(IrisStyle.accent)
                : targetTile.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet
            Behavior on color { ColorAnimation { duration: IrisStyle.duration(110) } }
        }
        Column {
            anchors.centerIn: parent
            spacing: Math.round(1 * root.d)
            MaterialSymbol {
                anchors.horizontalCenter: parent.horizontalCenter
                text: targetTile.entry.glyph
                iconSize: Math.round(19 * root.d)
                fill: targetTile.selected ? 1 : 0
                color: targetTile.selected ? IrisStyle.accent : IrisStyle.textSecondary
            }
            IrisText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Translation.tr(targetTile.entry.label)
                color: targetTile.selected ? IrisStyle.text : IrisStyle.subtext
                font.pixelSize: 10.5 * IrisStyle.typeScale
            }
        }
    }

    component LookTile: MouseArea {
        id: lookTile
        required property var look
        implicitHeight: Math.round(92 * root.d)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: lookTile.look.name
        onClicked: { root.applyValues(lookTile.look.values); root.say(Translation.tr("Applied %1").arg(lookTile.look.name)) }
        Rectangle {
            anchors.fill: parent
            radius: IrisStyle.radiusTile
            color: IrisStyle.materialSwatch(lookTile.look.material)
            border.width: 1
            border.color: lookTile.containsMouse ? IrisStyle.borderStrong : IrisStyle.border
            Behavior on border.color { ColorAnimation { duration: IrisStyle.duration(110) } }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Math.round(10 * root.d)
                spacing: Math.round(3 * root.d)
                RowLayout {
                    spacing: Math.round(6 * root.d)
                    Rectangle { implicitWidth: Math.round(10 * root.d); implicitHeight: implicitWidth; radius: width / 2; color: lookTile.look.accent }
                    IrisText { text: lookTile.look.name; font.weight: Font.DemiBold; font.pixelSize: 13 * IrisStyle.typeScale }
                }
                IrisText {
                    Layout.fillWidth: true
                    text: Translation.tr(lookTile.look.description)
                    color: IrisStyle.textSecondary
                    font.pixelSize: 11 * IrisStyle.typeScale
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }
        }
    }

    component SavedRow: Item {
        id: savedRow
        required property var entry
        implicitHeight: Math.round(46 * root.d)
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Math.round(16 * root.d)
            height: 1
            color: IrisStyle.hairline
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round(16 * root.d)
            anchors.rightMargin: Math.round(8 * root.d)
            spacing: Math.round(4 * root.d)
            IrisText {
                Layout.fillWidth: true
                text: String(savedRow.entry?.name ?? "")
                font.pixelSize: 13.5 * IrisStyle.typeScale
                elide: Text.ElideRight
            }
            IrisButton {
                text: Translation.tr("Apply")
                buttonRadius: height / 2
                onClicked: { root.applyValues(savedRow.entry.values); root.say(Translation.tr("Applied %1").arg(savedRow.entry.name)) }
            }
            IrisIconButton { materialIcon: "ios_share"; Accessible.name: Translation.tr("Copy to share"); onClicked: root.exportLook(savedRow.entry) }
            IrisIconButton { materialIcon: "delete"; Accessible.name: Translation.tr("Delete"); onClicked: root.removeSaved(savedRow.entry.name) }
        }
    }
}
