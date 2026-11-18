import QtQuick
import Quickshell.Io

// NiHiL's part of the shell config (`nihil.*`). `look` is the material; the rest is the desktop's structure.
JsonObject {
    // "custom" once anything is changed by hand; otherwise the profile last applied.
    property string profile: "vertical"

    property JsonObject look: JsonObject {
        // The accent and the light at the glass's edge: "aurora", "ice", "ember", "moss", "mono" or "wallpaper".
        property string palette: "aurora"
        // "smoke", "frost", "fluted" or "prism".
        property string material: "smoke"
        // Reeds across fluted glass.
        property int ribs: 14
        property real glass: 0.62
        property bool blur: true
        property real grain: 0.25
        property real rim: 0.7
        // The light rising from the bottom edge of the glass.
        property real flare: 0.5
        property real corners: 1
        property real scale: 1
        // Multiplies every animation; 0 turns movement off.
        property real motion: 1
        // Body text: "geist" or "system".
        property string font: "geist"
        // Titles: "geist" or "system".
        property string display: "geist"
    }
    property JsonObject field: JsonObject {
        // 0 beam, 1 fluted streaks, 2 haze, 3 void.
        property int form: 0
        property real seed: 0.37
        property real glow: 1
    }
    property JsonObject panel: JsonObject {
        // "top" or "bottom".
        property string position: "top"
        // "always", "desktop" (while no window is open on the workspace, and in the overview), "overview" or "hidden".
        property string visibility: "always"
        // In the overview: "same" keeps the glass, "transparent" drops it.
        property string overviewStyle: "same"
        property list<string> screenList: []
        property bool windowTitle: true
        property bool statusWords: true
    }
    property JsonObject modules: JsonObject {
        // Turn a whole surface off.
        property bool panel: true
        property bool dash: true
        // The dash on the desktop, outside the overview.
        property bool dock: true
        property bool thumbnails: true
        property bool search: true
        property bool appGrid: true
        property bool switcher: true
        property bool hotCorner: true
        property bool osd: true
        property bool notifications: true
    }
    property JsonObject overview: JsonObject {
        // "compositor" puts NiHiL's parts over Niri's or Umbriel's own overview; "shell" draws the whole overview.
        property string engine: "compositor"
        // What the compositor's overview stands on: "wallpaper" (blurred), "field" or "off".
        property string poster: "wallpaper"
        property real posterWallpaper: 0.6
        // "default" spreads the windows, "static" leaves them in place, "hover" spreads them under the pointer.
        property string mode: "default"
        // "desktop", "overview" or "apps": where the session starts.
        property string startup: "desktop"
        // "desktop" (sharp wallpaper), "transparent" (nothing behind), "blurFast" or "blurSmooth".
        property string background: "blurSmooth"
        property real backgroundBlur: 1
        // How bright the wallpaper stays in each view, 0 to 1.
        property real backgroundBrightness: 0.5
        property real appsBrightness: 0.5
        property real searchBrightness: 0.4
        property bool closeOnEmptyClick: true
        // "default" steps back one view at a time, "close" leaves the overview at once.
        property string escapeKey: "default"
        // "position" (as laid out), "recent" (last used first) or "stable" (oldest first).
        property string sortWindows: "position"
        // On opening, which window is selected: "pointer" (none), "first", "focused" or "previous".
        property string selectWindow: "pointer"
        // Leaving the overview focuses the selected window.
        property bool alwaysActivateSelected: false
        // How matches are marked in results: "bold", "underline" or "none".
        property string highlight: "bold"
        // What `inir nihil superKey` does on one press and on two: "none", "follow" (open or close the overview),
        // "windows", "apps", "staticWindows", "staticWorkspace", "searchWindows" or "recentFiles".
        property string superKey: "follow"
        property string superKeyDouble: "apps"
        // "none", "topLeft", "topRight", "bottomLeft", "bottomRight", "topEdge" or "bottomEdge".
        property string hotCorner: "topLeft"
        // "none", "windows", "apps" or "searchWindows".
        property string hotCornerAction: "windows"
        // Also works over a fullscreen window.
        property bool hotCornerFullscreen: false
        // A ripple of light where the corner was hit.
        property bool hotCornerRipples: true
        // The blur grows with the opening instead of being there from the start.
        property bool smoothAnimation: true
        // Page Up and Page Down switch workspaces.
        property bool pageShortcuts: true
    }
    property JsonObject dash: JsonObject {
        // "left", "right", "top", "bottom" or "hidden".
        property string position: "left"
        // -1 to 1 along its edge.
        property real adjust: 0
        // Follow the workspace preview's centre instead of the screen's.
        property bool centerToWorkspaces: false
        // Pixels; 0 fits the icons to the room there is.
        property int iconSize: 48
        // "start", "end" or "hidden".
        property string showApps: "end"
        property bool runningDots: true
        // "dot" or "line".
        property string runningStyle: "dot"
        // "default" (the palette's glass), "light" or "dark".
        property string tone: "default"
        property real opacity: 0.2
        property int radius: 20
        property bool isolateWorkspace: false
        // "activate", "workspaceFirst" (go to its workspace), "newWindow" or "preferCurrent" (a window here, if any).
        property string click: "activate"
        // "none", "workspace", "cycleWindows" (the app's windows here) or "cycleWindowsAll" (on every workspace).
        property string scroll: "workspace"
        // What the right-click menu offers.
        property bool menuForceQuit: true
        property bool menuCloseOnWorkspace: true
        property bool menuMoveApp: true
        property bool menuThumbnail: true
        // Scrolling over the search's window list moves through it.
        property bool windowSearchScroll: true
    }
    // The desktop dock wears the dash's apps, icons, clicks and menu.
    property JsonObject dock: JsonObject {
        // "bottom", "left" or "right".
        property string position: "bottom"
        // "always" (keeps its room), "desktop" (on an empty workspace and at the pointer) or "hover" (at the pointer).
        property string visibility: "desktop"
        // Pixels from the screen's edge.
        property int margin: 8
        property list<string> screenList: []
    }
    property JsonObject thumbnails: JsonObject {
        // "left", "right", "top", "bottom" or "hidden".
        property string position: "right"
        property real adjust: 0
        // Share of the screen's width, 0.05 to 0.3.
        property real scale: 0.13
        // The same in the app grid and in search; 0 hides the strip there.
        property real scaleInApps: 0
        property real scaleInSearch: 0
        // The strip's glass runs the whole edge.
        property bool fullLength: false
        // Glass behind the strip.
        property bool background: false
        // On other screens: "same", "start", "end" or "hidden".
        property string secondaryPosition: "same"
        property real secondaryScale: 0.1
        property real secondaryAdjust: 0
        // "none", "index", "indexApp", "app", "name" (the workspace's) or "windowTitle".
        property string labels: "indexApp"
        property bool labelsOnHover: true
        // The key that closes a workspace's windows: "hidden", "click", "doubleClick" or "ctrlClick".
        property string closeButton: "doubleClick"
    }
    property JsonObject stage: JsonObject {
        property real scale: 0.95
        // On other screens.
        property real secondaryScale: 0.95
        // Other screens leave room for their strip instead of centring on the screen.
        property bool secondaryShift: true
        property int radius: 30
        property int spacing: 30
        property bool adjacent: true
        // The wallpaper on each workspace's page.
        property bool background: true
    }
    property JsonObject windows: JsonObject {
        // Pixels: 64, 48, 32, 22, or 0 for none.
        property int iconSize: 48
        // "below", "inside", "insideAlways", "top" or "topAlways": the bare ones show under the pointer only.
        property string titlePosition: "below"
        // What a click on the icon does: "none", "activate", "search" or "thumbnail".
        property string iconClick: "activate"
        // "selected" (under the pointer), "all" or "hidden".
        property string closeButton: "selected"
        // Extra room in pixels kept under each row for the icon and title.
        property int heightCompensation: 0
        // "none", "activate", "close", "minimize", "next" (next workspace), "search" or "thumbnail".
        property string middleClick: "close"
        property string rightClick: "next"
    }
    property JsonObject search: JsonObject {
        property bool showEntry: true
        property bool center: true
        property real width: 1
        property int maxRows: 5
    }
    property JsonObject switcher: JsonObject {
        // "off", "all" (every screen) or "current" (the focused one).
        property string popup: "current"
        // "all" draws every workspace, "active" only the one reached.
        property string popupScope: "all"
        // "default" springs between workspaces, "static" jumps.
        property string mode: "default"
        // How the popup arrives: "default", "none", "left", "right", "up" or "down".
        property string animation: "default"
        // Going past the last workspace comes back to the first.
        property bool wrap: false
        // Leaves the empty last workspace out of the cycle.
        property bool ignoreLast: false
        property real horizontal: 0.5
        property real vertical: 0.95
        property int timeout: 900
    }
    property JsonObject motion: JsonObject {
        // Multiplies how long every animation lasts: under 1 is faster.
        property real speed: 1
        // Which workspaces stay live in the overview: "none", "activeOnly" or "all".
        property string workspaces: "activeOnly"
    }
    property JsonObject attention: JsonObject {
        // A window asking for attention: "show" (notify), "hide" (nothing) or "focus" (take it there).
        property string mode: "show"
        // Notify only for apps pinned on the dash.
        property bool favoritesNotify: false
    }
    // Profiles saved over the four presets: { id: { "dash.position": value, ... } }.
    property var savedProfiles: ({})
    property JsonObject widgets: JsonObject {
        property string design: "nihil"
    }
    property JsonObject apps: JsonObject {
        // "workspaces" follows the way workspaces stack, or "horizontal", "vertical".
        property string orientation: "workspaces"
        // -1 fits the page; otherwise pixels, 32 to 256.
        property int iconSize: -1
        // 0 fits the page.
        property int columns: 0
        property int rows: 0
        property int spacing: 30
        property real pageWidth: 0.85
        property real pageHeight: 0.9
        property bool center: false
        // "custom", "name", "foldersFirst", "foldersLast" or "usage" (usage shows no folders).
        property string order: "custom"
        // "all", "favoritesFirst", "noFavorites", "noRunning" or "noFavoritesNoRunning".
        property string content: "noFavorites"
        // "ellipsized" (the selected one expands), "expanded" or "hidden" (only the selected one shows).
        property string names: "ellipsized"
        // A place emptied by hand stays empty instead of pulling the next apps forward.
        property bool incompletePages: false
        property bool rememberPage: false
        property int lastPage: 0
        property bool pageArrows: true
        property bool pageIndicators: true
        // Mark launchers that come from Flatpak, Snap or an AppImage.
        property bool packageBadge: true
        // "default", "none", "left", "right", "up" or "down".
        property string animation: "default"
        // Lighter drawing for slow machines: no icon shadows, no page fade.
        property bool performance: false
        // Desktop ids in the order they were arranged by hand.
        property list<string> customOrder: []
        // [{ id, name, apps: [desktop ids] }]
        property list<var> folders: []
        // Desktop id to times opened.
        property var usage: ({})
    }
    property JsonObject folders: JsonObject {
        // "custom", "name" or "usage".
        property string order: "custom"
        property int iconSize: -1
        property int columns: 0
        property int rows: 0
        property int spacing: 12
        property bool center: true
        // 2: a 2x2 preview; 3: 3x3 from five apps; 4: 3x3 from nine apps.
        property int previewGrid: 2
        // The icons in a folder's preview open their apps directly.
        property bool activePreview: false
        // "hidden", "click" or "doubleClick".
        property string removeButton: "click"
        property bool closeButton: true
    }
    property JsonObject results: JsonObject {
        // "view" lists results, "filter" narrows the app grid in place.
        property string appsMode: "view"
        property bool fuzzy: false
        property bool includeSettings: true
        property bool includeWindows: true
        // Where open windows rank: "first" or "last".
        property string windowsOrder: "last"
        property int iconSize: 0
        // "transparent" or "dark".
        property string background: "transparent"
        // "default", "none", "left", "right", "up" or "down".
        property string animation: "default"
        // "default", "switch" (jump to the window's workspace) or "bring" (move it here).
        property string activateSettings: "switch"
    }
    property JsonObject lock: JsonObject {
        property bool blur: true
        property bool showBattery: true
    }
    property JsonObject osd: JsonObject {
        // "off", "topLeft", "top", "topRight", "center", "bottomLeft", "bottom" or "bottomRight".
        property string position: "bottom"
        property int holdMs: 1400
    }
    property JsonObject notifications: JsonObject {
        // "topLeft", "top", "topRight", "bottomLeft", "bottom" or "bottomRight".
        property string position: "top"
        property int maxVisible: 4
    }
}
