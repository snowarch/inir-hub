import QtQuick
import Quickshell.Io

// Material's part of the shell config (`material.*` in config.json): Config holds it in its `material` slot once
// this plugin is installed (plugin.json `configKey`). Only what Material draws lives here; behaviour every family
// shares stays in the shell's sections.
JsonObject {
    property JsonObject bar: JsonObject {
        // Options for bar.appearanceStyle === "pill": the morphing centre
        // island that replaces the bar and grows on hover.
        property JsonObject pill: JsonObject {
            property bool barMode: false // Rest expanded: the hover row stays out as a persistent bar
            property bool floatOverWindows: false // Keep the visible Pill over normal windows instead of reserving the top edge
            property real scale: 1 // UI scale multiplier on top of the screen-height ratio
            property real topGap: 1 // Distance from the top edge, in 8px units
            property real appGap: 1 // How much reserved band the pill keeps below itself
            property bool showGlyphs: true // 時 kanji instead of a clock icon at rest
            property bool clockSeconds: false
            property bool time12h: false
            property bool musicViz: false // Draw live spectrum wings outside the pill
            property bool toasts: true // Notification toasts take over the resting pill
            property bool osd: true // Volume/brightness/mic/workspace changes flash on the pill
            property bool compactAnnounces: false // Keep toast/OSD faces at the resting pill size
            property real rowSpacing: 24 // Air between the hover row's groups (workspaces | clock | status), px
            property real iconSpacing: 14 // Air between the status icons, px
            property real iconSize: 19 // Icon size of the pill's furniture, px
            property string batteryDisplay: "both" // "icon" | "percentage" | "both"
            property string mediaAccess: "row" // "bud" | "row"
            property string superSpaceLauncher: "overview" // "overview" | "pill"
            property int mixerAppRows: 5
            property int restWidth: 176
            property int restHeight: 44
            property int expandedHeight: 66
            // The soul bead that glides between hover targets.
            property JsonObject soul: JsonObject {
                property bool enable: true
                property real size: 1 // Bead size multiplier
                property string style: "orb" // "orb" (living swirl) | "ember" (plain dot) | "ring" (hollow outline)
            }
            // Per-surface glyph overrides; empty string = stock kanji.
            property JsonObject glyphs: JsonObject {
                property string clock: ""
                property string media: ""
                property string mediaPaused: ""
                property string link: ""
                property string notify: ""
                property string clear: ""
                property string dnd: ""
                property string sysmon: ""
                property string glance: ""
                property string clipboard: ""
                property string clipboardSearch: ""
                property string recorder: ""
                property string power: ""
                property string battery: ""
                property string calendar: ""
                property string mixer: ""
                property string launcher: ""
                property string workspaces: ""
                property string settings: ""
            }
            // Hover-row furniture: every module in the expanded row can be
            // switched off (surface-bound icons follow surfaces.* instead).
            property JsonObject modules: JsonObject {
                property bool workspaces: true
                property bool weather: true
                property bool tray: true
                property bool wifi: true
                property bool battery: true
                property bool inbox: true
                property bool mixer: true
                property bool sidebars: true // The two shortcuts into iNiR's own sidebars
                property bool power: true
            }
            // Optional hover-row surfaces; the stock ones are always available.
            property JsonObject surfaces: JsonObject {
                property bool sysmon: true // 系 SYSTEM vitals surface + its monitor icon
                property bool clipboard: true // 控 clipboard history surface + its icon
                property bool glance: true // 今 TODAY surface (weather + agenda + tasks) + its icon
                property bool launcher: true // 探 app launcher surface + its icon
                property bool recorder: false // 録 screen recorder surface + its icon (surface stays reachable over IPC)
            }
        }

        // Options for bar.appearanceStyle === "islands": floating Ricelin
        // capsules per bar section.
        property JsonObject islands: JsonObject {
            property int inset: 4 // Vertical breathing room around each island, px
            property int padding: 12 // Horizontal capsule padding around edge-section content, px
        }

        // Options for the separate M3 implementation under modules/ii/barM3/. It
        // keeps its own layout/appearance contract instead of reusing
        // bar.layout/bar.modules/bar.borderless, because its grouping
        // model (three flat layouts of widget names, string grouping
        // style, per-position pill radii) is incompatible with iNiR's
        // five-zone registry. Nothing here changes any other bar.
        property JsonObject m3: JsonObject {
            // 0: Hug | 1: Float | 2: Plain rectangle | 3: Material 3
            property int cornerStyle: 3
            // "pills" (adjacent groups join into one continuous shape)
            // | "separated" (every group is its own capsule)
            // | "transparent" (no group surface at all)
            property string borderless: "pills"
            property bool showBackground: true
            property bool verbose: true
            property JsonObject clock: JsonObject {
                property string timeFontFamily: ""
                property int timePixelSize: 0
                property string dateFontFamily: ""
                property int datePixelSize: 0
            }
            property int gapsOut: 5 // Outer gap the float/M3 styles detach by
            // Widget names resolve to modules/ii/barM3/<Name>.qml. Available:
            // media, workspaces, activeWindow, leftSidebarButton, rightSidebarButton, docktoPanel,
            // visualizer, divisor, resources, sysTray, systemIcons, utilButtons,
            // networkSpeed, updatesCount, batteryIndicator, weatherBar,
            // clockWidget, notificationUnreadCount, powerButton.
            // Fresh installs start on the compact Flow composition so the
            // feature/system sidebars have discoverable entry points. The
            // showcase remains an explicit preset with mirrored visualizers.
            // The active layout is kept separate from the user's custom
            // layout. Presets may replace the active lists, but must never
            // destroy the last custom arrangement.
            property string layoutMode: "compact" // "auto" | "compact" | "showcase" | "information" | "custom"
            property bool customLayoutSaved: false
            property JsonObject layouts: JsonObject {
                property list<string> leftLayout: ["leftSidebarButton", "media", "workspaces"]
                property list<string> middleLayout: ["docktoPanel"]
                property list<string> rightLayout: ["utilButtons", "weatherBar", "clockWidget", "systemIcons", "rightSidebarButton"]
            }
            property JsonObject customLayouts: JsonObject {
                property list<string> leftLayout: []
                property list<string> middleLayout: []
                property list<string> rightLayout: []
            }
            property JsonObject divider: JsonObject {
                property string style: "rect" // "rect" | "dot" | "space"
                property int spacing: 20
            }
            property JsonObject tooltips: JsonObject {
                property bool clickToShow: false
            }
            property JsonObject indicators: JsonObject {
                property JsonObject notifications: JsonObject {
                    property bool showUnreadCount: false
                }
            }
            property JsonObject media: JsonObject {
                property string preferredPlayer: ""
                property bool alwaysVisible: false
                property bool onlyTitle: false
                property int maxWidth: 280
                property int minWidth: 100
            }
            property JsonObject resources: JsonObject {
                property string style: "filled"
                property bool showValue: false
                property bool alwaysShowSwap: false
                property bool alwaysShowCpu: true
                property bool alwaysShowCpuTemp: false
                property bool alwaysShowDisk: false
                property bool alwaysShowRam: true
                property int memoryWarningThreshold: 95
                property int swapWarningThreshold: 85
                property int cpuWarningThreshold: 90
            }
            property JsonObject tray: JsonObject {
                // M3 tray icons follow the semantic pill foreground by default.
                // Users can opt out to keep each application's original colors.
                property bool monochromeIcons: true
            }
            property JsonObject workspaces: JsonObject {
                property bool monochromeIcons: true
                property bool showAppIcons: true
                property string indicatorStyle: "dot" // "dot" | "icon"
                property bool alwaysShowNumbers: false
                property list<string> numberMap: ["1", "2"]
                property bool useNerdFont: false
            }
            property JsonObject utilButtons: JsonObject {
                property bool showScreenSnip: true
                property bool showColorPicker: false
                property bool showMicToggle: false
                property bool showKeyboardToggle: true
                property bool showWallpaperToggle: false
                property bool showDarkModeToggle: true
                property bool showPerformanceProfileToggle: false
                property bool showScreenRecord: false
            }
            // The dock rendered inside the bar.
            // iconSize/buttonSize at 0 scale with the bar height; set a
            // px value to pin them regardless of how tall the bar is.
            property JsonObject dockToPanel: JsonObject {
                property real iconSize: 0
                property real buttonSize: 0
                property real buttonSpacing: 2
            }
        }

        property JsonObject activeWindow: JsonObject {
            property bool showTitle: true // Show window title under the app name in the bar's active window indicator
        }
        property JsonObject autoHide: JsonObject {
            property bool enable: false
            property int hoverRegionWidth: 2
            property bool pushWindows: false
            property JsonObject showWhenPressingSuper: JsonObject {
                property bool enable: true
                property int delay: 140
            }
        }
        property bool bottom: false // Instead of top
        property int height: 40 // Bar content height in px (pre-scale). 0 keeps the theme default (40). Range: 24–80.
        property real opacity: 1.0 // Background opacity (0–1). Lets you make the bar translucent without changing global style.
        property int cornerStyle: 1 // 0: Hug | 1: Float | 2: Plain rectangle
        property string appearanceStyle: "m3" // "classic" | "islands" (separate floating groups; works in both horizontal and vertical bar) | "scenic" (gradient scrim) | "frame" (outlined floating frame) | "m3" (no bar surface; each section is a colLayer0 capsule and each module wears a Material 3 tonal container) | "pill" (morphing centre island, see bar.pill). Horizontal bar only, except islands.
        property int customRounding: -1 // -1: use global theme rounding | 0+: override bar rounding (px)
        property bool floatStyleShadow: true // Show shadow behind bar when cornerStyle == 1 (Float)
        property bool borderless: true // true for no grouping of items
        property string topLeftIcon: "distro" // Options: "distro", "avatar" or any icon name in ~/.config/quickshell/inir/assets/icons
        property bool showBackground: true
        property bool showScrollHints: true // Show brightness/volume scroll hints on hover
        property string leftScrollAction: "brightness" // "brightness", "volume", "workspace", "none"
        property string rightScrollAction: "volume" // "brightness", "volume", "workspace", "none"
        property JsonObject blurBackground: JsonObject {
            property bool enabled: false
            property real overlayOpacity: 0.3
        }
        // Audio spectrum painted into the bar surface. Only runs while
        // something is actually playing.
        property JsonObject visualizer: JsonObject {
            property bool enable: false
            property string multiMonitorMode: "primary" // "primary" | "all"
            property string type: "bars" // "bars" | "wave" | "organic"
            property real height: 0.6 // Share of the bar height the spectrum may fill (0.1–1)
            property real opacity: 0.35 // Spectrum opacity over the bar surface (0–1)
            property string barsOrigin: "bottom" // "bottom" | "top" | "center" | "mirror"
            property int density: 12 // Horizontal pixels allocated to each rendered bar
            property int gap: 2 // Gap between rendered bars, px
            property int smoothing: 2 // Frequency smoothing radius
            property string waveMode: "fill" // "fill" | "line" | "ribbon"
            property real lineWidth: 2 // Wave edge width, px
            property int edgeInset: 6 // Horizontal inset from each surface edge, px
            property int edgeSoftness: 36 // Curvature-aware peak headroom, 0-100
            property string frequencyProfile: "flat" // "flat" | "bass" | "warm" | "vocal" | "treble" | "smile"
            property int accentStrength: 70 // Frequency profile strength, 0-100
            property string organicFit: "auto" // "auto" | "contained" | "aura"
            property int organicSensitivity: 42 // Organic deformation gain, 0-100
            property int organicPulse: 55 // Beat response, 0-100
            property int organicMotionSpeed: 80 // Motion speed, 25-150
            property int organicIdleMotion: 0 // Idle deformation while signal is quiet, 0-100
            property int organicGlow: 25 // Organic glow amount, 0-100
            property int organicBaseRadius: 36 // Base contour roundness, 0-100
            property string pillWingMode: "bounded" // "bounded" | "screen" | "bleed"
            property int pillWingLength: 180 // Spectrum length on each side of the pill, px
            property int pillWingGap: 12 // Air between the pill and each spectrum wing, px
            property int pillScreenPadding: 24 // Air between screen edges and screen-spanning wings, px
            property int pillUnderlap: 28 // Spectrum overlap behind the pill in bleed mode, px
            property int pillEdgeFade: 92 // Fade toward screen edges, 0-100
        }
        property bool verbose: true
        property JsonObject media: JsonObject {
            property int maxWidth: 220
        }
        property bool vertical: false
        property JsonObject clock: JsonObject {
            property string timeFontFamily: ""
            property int timePixelSize: 0
            property string dateFontFamily: ""
            property int datePixelSize: 0
        }
        property JsonObject vignette: JsonObject {
            property bool enabled: false
            property real intensity: 0.6
            property real radius: 0.5
        }
        property JsonObject modules: JsonObject {
            property bool leftSidebarButton: true
            property bool activeWindow: true
            property bool resources: false
            property bool media: true
            property bool workspaces: true
            property bool clock: true
            property bool utilButtons: false
            property bool battery: true
            property bool rightSidebarButton: true
            property bool sysTray: true
            property bool weather: true
            property bool taskbar: false
        }
        property JsonObject modulesPlacement: JsonObject {
            property string resources: "start"
            property string media: "start"
            property string workspaces: "center"
            property string clock: "end"
            property string utilButtons: "end"
            property string battery: "end"
        }
        // Deprecated: kept so old config.json loads without error until
        // migration 028 removes them. Not consumed by the bar.
        property JsonObject modulesLayout: JsonObject {
            property list<string> order: ["resources", "media", "workspaces", "clock", "utilButtons", "battery"]
        }
        property JsonObject edgeModulesLayout: JsonObject {
            property list<string> leftOrder: ["leftSidebarButton", "activeWindow"]
            property list<string> rightOrder: ["rightSidebarButton", "sysTray", "weather"]
        }
        // Modular bar layout — widget ids per structural zone.
        // Zones map 1:1 to the bar's real sections so workspaces stays
        // screen-centered and pill surfaces / scroll areas are preserved:
        //   left        → left edge section (scroll=brightness, click=left sidebar)
        //   centerLeft  → left central pill group
        //   center      → the centered pivot group (normally workspaces)
        //   centerRight → right central pill group (scroll, triple-tap fx)
        //   right       → right edge section (click=right sidebar)
        // Known ids: leftSidebarButton, activeWindow, resources, media,
        //   workspaces, clock, utilButtons, battery, weather, tray,
        //   rightSidebarButton, timer, shellUpdate and spacer. Legacy
        //   persisted `taskbar` ids are normalized to the activeWindow slot.
        property JsonObject layout: JsonObject {
            property list<string> left: ["leftSidebarButton", "activeWindow"]
            property list<string> centerLeft: ["resources", "media"]
            property list<string> center: ["workspaces"]
            property list<string> centerRight: ["clock", "utilButtons", "battery"]
            property list<string> right: ["rightSidebarButton", "tray", "timer", "shellUpdate", "spacer", "weather"]
            property int spacerWidth: 0 // Minimum width for each flexible spacer, in px. 0 keeps it pure flex.
            property string spacerMode: "auto" // "auto": elastic in edge zones, fixed gap in centre pills; "fill": always elastic; "fixed": always spacerWidth
            // Set true once the old fixed layout has been translated into
            // the arrays above (handled by a migration). Until then the
            // bar falls back to its classic hardcoded layout so existing
            // users are never affected.
            property bool migrated: false
        }
        property JsonObject resources: JsonObject {
            property bool showMemoryIndicator: true
            property bool showSwapIndicator: true
            property bool showTempIndicator: true
            property bool showCpuIndicator: true
            property bool showGpuIndicator: true
            property bool alwaysShowSwap: true
            property bool alwaysShowTemp: true
            property bool alwaysShowCpu: true
            property bool alwaysShowGpu: true
        }
        property list<string> screenList: [] // List of names, like "eDP-1", find out with 'hyprctl monitors' command
        property JsonObject utilButtons: JsonObject {
            property bool showScreenSnip: true
            property bool showScreenRecord: true
            property bool showColorPicker: false
            property bool showMicToggle: false
            property bool showKeyboardToggle: true
            property bool showKeyboardLayoutSwitch: false
            property bool showDarkModeToggle: true
            property bool showPerformanceProfileToggle: false
            property bool showScreenCast: false
            property string screenCastOutput: "HDMI-A-1"
            property bool showNotepad: true
        }
        property JsonObject tray: JsonObject {
            property bool monochromeIcons: true
            property bool showItemId: false
            property bool invertPinnedItems: true // Makes the below a whitelist for the tray and blacklist for the pinned area
            property list<string> pinnedItems: []
            property bool filterPassive: true
        }
        property JsonObject workspaces: JsonObject {
            property string scrollBehavior: "workspace" // "workspace" or "column"
            property bool monochromeIcons: true
            property bool dynamicCount: true // Auto-detect workspace count (Niri)
            property int shown: 10 // Only used when dynamicCount is false
            property bool wrapAround: true // Cycle from last to first and vice versa
            property int scrollSteps: 3 // Wheel steps required to switch
            property bool showAppIcons: true
            property bool alwaysShowNumbers: false
            property int showNumberDelay: 300 // milliseconds
            property list<string> numberMap: ["1", "2"] // Characters to show instead of numbers on workspace indicator
            property bool useNerdFont: false
            property bool perMonitor: true // Each bar shows workspaces for its own monitor (Niri)
            property bool automaticIndicatorColor: true // Derive active workspace indicator color from the current theme
            property string indicatorColor: "" // Manual active workspace indicator color when automaticIndicatorColor is false
        }
        property JsonObject indicators: JsonObject {
            property JsonObject notifications: JsonObject {
                property bool showUnreadCount: false
            }
        }
    }
    property JsonObject sidebar: JsonObject {
        property string style: "panel" // "panel" | "island" (Ricelin gradient card face)
        property bool cardStyle: false
        property list<string> screenList: []
        property string layout: "default" // "default" | "compact"
        property bool keepRightSidebarLoaded: true
        property bool keepLeftSidebarLoaded: true
        property bool instantOpen: false
        property string animationType: "slide" // "slide" | "fade" | "pop" | "reveal" | "swing" | "drop" | "elastic"
        property bool collapseEmptyNotifications: false // Shrink right sidebar when there are no notifications (default layout)
        property bool collapseWidgetsTab: false // Shrink left sidebar to its content on tabs with finite height (Widgets)
        property JsonObject shellLayout: JsonObject {
            property JsonObject feature: JsonObject {
                property string slot: "left" // "left" | "right"
                property string sizeMode: "full" // "full" | "fit" | "custom"
                property int customHeight: 720
                property int width: 460
            }
            property JsonObject system: JsonObject {
                property string slot: "right" // "left" | "right"
                property string sizeMode: "full" // "full" | "fit" | "custom"
                property int customHeight: 720
                property int width: 460
            }
        }
        property bool openFolderOnDownload: false // Open file manager after wallpaper download
        property JsonObject ai: JsonObject {
            property bool textFadeIn: false
        }
        // Tools tab - Niri debug options and quick actions
        property JsonObject tools: JsonObject {
            property bool enable: false
        }
        // Software catalog tab - curated app install/remove
        property JsonObject software: JsonObject {
            property bool enable: false
        }
        // Web Apps / Plugins tab - embedded webapps in sidebar
        property JsonObject plugins: JsonObject {
            property bool enable: false
            property string lastActivePlugin: ""
        }
        // Widgets tab in left sidebar
        property JsonObject widgets: JsonObject {
            property bool enable: true
            // Widget visibility
            property bool media: true
            property bool week: true
            property bool context: true
            property bool note: false
            property bool launch: false
            property bool controls: true
            property bool status: true
            property bool crypto: false
            property bool wallpaper: false
            property bool worldClock: false
            // ContextCard specific
            property bool contextShowWeather: true
            // Widget order (drag to reorder)
            property list<string> widgetOrder: ["context", "week", "media", "note", "launch", "controls", "status", "crypto", "wallpaper", "worldclock"]
            // Spacing between widgets (px)
            property int spacing: 8

            // GlanceHeader behavior
            property JsonObject glance: JsonObject {
                property bool showVolume: true
                property bool showGameMode: true
                property bool showDnd: true
            }

            // StatusRings behavior
            property JsonObject statusRings: JsonObject {
                property bool showCpu: true
                property bool showRam: true
                property bool showDisk: true
                property bool showTemp: true
                property bool showBattery: true
            }

            // ControlsCard behavior
            property JsonObject controlsCard: JsonObject {
                property bool showDarkMode: true
                property bool showDnd: true
                property bool showNightLight: true
                property bool showGameMode: true
                property bool showNetwork: true
                property bool showBluetooth: true
                property bool showSettings: true
                property bool showLock: true
            }

            // CryptoWidget behavior
            property JsonObject crypto_settings: JsonObject {
                property int refreshInterval: 60
                property list<string> coins: ["bitcoin", "ethereum"]
            }

            // WorldClockWidget behavior
            property JsonObject worldClock_settings: JsonObject {
                // IANA timezones to display, e.g. "Europe/London". Empty = auto-suggest by region.
                property list<string> timezones: []
                property bool showSeconds: false
                property bool use24Hour: true
                property bool showDate: true
                property bool highlightLocal: true
            }

            // QuickLaunch shortcuts
            property list<var> quickLaunch: [
                {
                    "icon": "folder",
                    "name": "Files",
                    "cmd": "/usr/bin/nautilus"
                },
                {
                    "icon": "terminal",
                    "name": "Terminal",
                    "cmd": "/usr/bin/kitty"
                },
                {
                    "icon": "web",
                    "name": "Browser",
                    "cmd": "/usr/bin/firefox"
                },
                {
                    "icon": "code",
                    "name": "Code",
                    "cmd": "/usr/bin/code"
                }
            ]

            // QuickWallpaper settings
            property JsonObject quickWallpaper: JsonObject {
                property int itemSize: 72
                property bool showHeader: true
            }
        }
        property JsonObject edgeOpen: JsonObject {
            property bool enable: false
            property int regionWidth: 2
        }

        property JsonObject quickToggles: JsonObject {
            property string style: "android" // Options: classic, android
            property JsonObject android: JsonObject {
                property int columns: 4
                property list<var> toggles: [
                    {
                        "size": 1,
                        "type": "network"
                    },
                    {
                        "size": 1,
                        "type": "bluetooth"
                    },
                    {
                        "size": 1,
                        "type": "audio"
                    },
                    {
                        "size": 1,
                        "type": "mic"
                    }
                ]
            }
        }

        property JsonObject quickSliders: JsonObject {
            property bool enable: true
            property bool showMic: true
            property bool showVolume: true
            property bool showBrightness: true
        }

        property JsonObject left: JsonObject {
            // Stable ids keep disabled tabs in their chosen position so
            // re-enabling a feature restores it where the user placed it.
            property list<string> tabOrder: ["widgets", "ai", "translator", "anime", "animeSchedule", "wallhaven", "news", "ytmusic", "tools", "software"]
        }

        // Right sidebar widget toggles
        property JsonObject right: JsonObject {
            property list<string> enabledWidgets: ["calendar", "events", "todo", "calculator", "sysmon", "weather"]
            // Controls section order for compact layout (drag to reorder)
            property list<string> controlsSectionOrder: ["sliders", "toggles", "devices", "media", "quickActions"]
            // Section order for the default layout (modular sidebar).
            // Known ids: system, sliders, toggles, notifications, widgets.
            // Unknown ids are ignored; missing ids append in default order.
            property list<string> sectionOrder: ["system", "sliders", "toggles", "notifications", "widgets"]
            // Look of the "system" section. "profile" = wallpaper
            // banner + avatar + user@host card; "classic" = the flat
            // uptime pill next to the button pill.
            property string headerStyle: "profile"
            // Banner media of the profile header: "wallpaper" (the
            // monitor's live wallpaper), "custom" (headerBannerPath),
            // "solid" (flat token plate), or "none" (collapse it).
            property string headerBanner: "wallpaper"
            property string headerBannerPath: ""
            // Relative allocation of the two elastic zones. Values are
            // normalized together by the live resize handle.
            property JsonObject sectionWeights: JsonObject {
                property real notifications: 1
                property real widgets: 1
            }
        }

    }
    property JsonObject dock: JsonObject {
        property string style: "m3" // "panel" | "pill" | "macos" | "island" | "m3"
        property bool cardStyle: false
        property bool enable: true
        property bool monochromeIcons: true
        property string position: "bottom" // "top", "bottom", "left", "right"
        property real height: 60
        property real iconSize: 35
        property real hoverRegionHeight: 2
        property bool pinnedOnStartup: true
        property bool hoverToReveal: false // When false, only reveals on empty workspace
        property bool showOnDesktop: true // Show dock when no window is focused (desktop visible)
        property bool showBackground: true
        property bool minimizeUnfocused: false // Show dot for unfocused apps
        property bool enableBlurGlass: true
        property bool separatePinnedFromRunning: true // Waffle-style: pinned-only apps on left, running on right
        property bool notificationBadge: true // Count of pending notifications on the app icon
        property list<string> screenList: [] // List of screen names to show dock on (e.g. ["DP-2"]). Empty = all screens
        // Smart indicator settings
        property bool smartIndicator: true // Show which window is focused
        property bool showAllWindowDots: true // Show dots for all windows (even inactive apps)
        property int maxIndicatorDots: 5 // Maximum dots to show
        // Window preview on hover
        property bool hoverPreview: true // Show window preview popup on hover
        property int hoverPreviewDelay: 400 // Delay before showing preview (ms)
        property bool keepPreviewOnClick: false // Keep preview open when clicking a window thumbnail
        // Drag & drop reordering
        property bool enableDragReorder: true // Allow drag to reorder pinned apps
    }
    property JsonObject controlPanel: JsonObject {
        // "panel" (stock per-style card) | "island" (Ricelin card)
        property string style: "panel"
        property bool keepLoaded: false
        property bool compactMode: true
        property bool showMediaSection: true
        property bool showWeatherSection: true
        property bool showWallpaperSection: true
        property bool showSystemSection: true
        property bool showSlidersSection: true
        property bool showQuickActionsSection: true
        property bool showWallpaperSchemeChips: false
    }
    // Dashboard hub panel (ii family). Widget ids per column:
    //   welcome, clock, weather, calendar, agenda, media, notifications,
    //   todo, system, github. Columns collapse when empty.
    property JsonObject dashboard: JsonObject {
        property bool enable: true
        property bool keepLoaded: false
        property bool showHeader: true
        property bool showPowerButtons: true
        property JsonObject appearance: JsonObject {
            property string density: "comfortable" // "comfortable" | "compact"
            property real cardOpacity: 1.0 // Card surface opacity (0.3–1); content stays opaque
            property bool showCardTitles: true
        }
        property string subtitle: "" // Custom phrase under the welcome greeting
        property real widthRatio: 0.62 // Panel width as fraction of screen width (0.4–0.9)
        property JsonObject layout: JsonObject {
            property list<string> left: ["welcome", "clock", "system", "github"]
            property list<string> center: ["notifications", "todo"]
            property list<string> right: ["media", "weather", "calendar"]
        }
        property JsonObject github: JsonObject {
            property string username: "" // GitHub user for the contributions widget. Empty disables fetching.
        }
    }
    property JsonObject settingsUi: JsonObject {
        property bool overlayMode: true // true = layer shell overlay (live preview), false = separate window
        property bool easyMode: false   // false = full Settings UI; Easy mode remains an explicit opt-in
        // JSON-encoded [{label, pages:[int]}] — custom nav arrangement; "" = registry defaults.
        // String on purpose: property var inside JsonObject crashes the VME.
        property string categories: ""
        property JsonObject overlayAppearance: JsonObject {
            property int scrimDim: 35           // % dim of the backdrop scrim behind the settings panel (0-100)
            // Opacity of the settings panel background (0.6-1.0). The
            // floor is a legibility contract, not a taste call: the panel
            // is a single surface and the cards on it carry the reading
            // contrast, so below it the solid styles put a sharp wallpaper
            // behind the text and aurora thins to a bare 64 px blur. Both
            // settings hosts clamp on read.
            property real backgroundOpacity: 1.0
            // Blur radius (%) of the backdrop behind the settings overlay,
            // painted by the same shared GlassBackground the rest of the
            // shell uses. 0 keeps the surface out of the tree entirely.
            property int backdropBlur: 0
        }
    }
    property JsonObject style: JsonObject {
        property string globalStyle: "material" // "material" | "cards" | "aurora" | "inir" | "angel" | "regalia" | "zzz" | "cookie" | "editorial"
        // Shared skin for every island surface (islands bar, island dock,
        // island sidebars, island search). Consumed by IslandPanel.
        property JsonObject island: JsonObject {
        property bool glass: true // Blurred wallpaper behind translucent island cards (needs opacity < 100%)
        property real glassBlur: 1 // Blur intensity of the glass backdrop (0.2–1)
            property int radius: 18 // Corner radius where the surface doesn't set its own
            property real opacity: 1 // Gradient fill opacity (0–1)
            property bool shadow: true // Soft drop shadow behind the card
            property bool sheen: true // 1px lit top edge
        }
        property JsonObject regalia: JsonObject {
            property bool glass: true
            property real glassBlur: 0.72
            property real glassTintTransparency: 0.52
            property real glassSurfaceOpacity: 0.60
            property real glassSaturation: 0.12
            property real radiusScale: 1.0
        }
        property JsonObject aurora: JsonObject {
            property JsonObject transparency: JsonObject {
                property real overlay: 0.38       // Main panels
                property real subSurface: 0.52    // Cards/groups
                property real popup: 0.42         // Popups/menus
                property real tooltip: 0.35       // Tooltips
                property real layer: 0.40         // General layer glass (colLayer1/2/3)
            }
            // How much of the wallpaper's colour the glass lets through (0 grey, 1 as it is).
            property real wallpaperColor: 0.55
            property string customPreset: ""
        }
        property string angelSubStyle: "frost" // "frost" | "neon" | "void"
        // Editorial is an independent composition layer. It is kept
        // separate from the desktop Editorial widget's instance data.
        property JsonObject editorial: JsonObject {
            property bool paperStack: false
            property real paperDepth: 3
            property bool glass: false
            property real glassOpacity: 0.72
            property real glassBlur: 0.85
            property bool sidebarGlassBackground: true
            property string paperMode: "theme"
            property string paperTone: "neutral"
            property real paperTint: 0.35
            property string paperColor: "#b8c4b0"
            property string accentRole: "primary"
            property string accentColor: "#b5a0c8"
            property int labelWeight: 600
            property real metadataTracking: 0.8
            property int titleWeight: 650
            property real titleTracking: -0.6
            property string typography: "poster" // "poster" sans titles | "reading" Source Serif 4
            property real titleScale: 1.0
            property real warmth: 0.55
            property real accentStrength: 0.55
            property real spacing: 1.0
            property real radiusScale: 1.0
            property bool ornaments: true
            property real motionScale: 1.0
        }
        // ZZZ personality axis: silhouette variant. "square" = sharp
        // console plates with cut-corner chamfers (classic ZZZ). "round" =
        // softer anime UI — pills for controls, rounded panels, no chamfer.
        property JsonObject zzz: JsonObject {
            property string shape: "square" // "square" | "round"
            property bool glass: true // subtle wallpaper-blur behind the grid (gated by effectsEnabled)
            // Master switches for the ZZZ panel backdrop layers. Each ANDs with
            // the per-panel intent, so turning one off hides that layer shell-wide.
            property JsonObject backdrop: JsonObject {
                property bool burst: true      // diagonal accent slashes (dashboard triad, etc.)
                property bool ghost: true      // large ghost wordmark behind content (panel name)
                property bool grid: true       // faint technical engineering grid
                property bool ticks: true      // scan ticks (used on the session screen)
                property real burstSize: 1.0   // size multiplier for the diagonal burst
            }
        }
        property JsonObject angel: JsonObject {
            property JsonObject blur: JsonObject {
                property real intensity: 0.25
                property real saturation: 0.15
                property real overlayOpacity: 0.35
                property real noiseOpacity: 0.15
                property real vignetteStrength: 0.4
            }
            property JsonObject transparency: JsonObject {
                property real panel: 0.35
                property real card: 0.50
                property real popup: 0.35
                property real tooltip: 0.25
            }
            property JsonObject escalonado: JsonObject {
                property int offsetX: 2
                property int offsetY: 2
                property int hoverOffsetX: 7
                property int hoverOffsetY: 7
                property real opacity: 0.40
                property real borderOpacity: 0.60
                property real hoverOpacity: 0.60
            }
            property JsonObject escalonadoShadow: JsonObject {
                property int offsetX: 4
                property int offsetY: 4
                property int hoverOffsetX: 10
                property int hoverOffsetY: 10
                property real opacity: 0.30
                property real borderOpacity: 0.50
                property real hoverOpacity: 0.50
                property bool glass: true
                property real glassBlur: 0.15
                property real glassOverlay: 0.50
            }
            property JsonObject border: JsonObject {
                property real width: 1.5
                property int accentBarHeight: 0
                property int accentBarWidth: 0
                property real coverage: 0.0
                property real opacity: 0.0
                property real hoverOpacity: 0.0
                property real activeOpacity: 0.0
                property int insetGlowHeight: 0
                property real insetGlowOpacity: 0.0
            }
            property JsonObject surface: JsonObject {
                property int panelBorderWidth: 0
                property int cardBorderWidth: 1
                property real panelBorderOpacity: 0.0
                property real cardBorderOpacity: 0.30
            }
            property JsonObject glow: JsonObject {
                property real opacity: 0.80
                property real strongOpacity: 0.65
            }
            property JsonObject rounding: JsonObject {
                property int small: 10
                property int normal: 15
                property int large: 25
            }
            property real colorStrength: 1.0
            property string customPreset: ""
        }
        // Corner style preference per global style (0=Hug, 1=Float, 2=Rect, 3=Card)
        property JsonObject globalStyleCornerStyles: JsonObject {
            property int material: 1
            property int cards: 3
            property int aurora: 0
            property int inir: 1
            property int angel: 1
            property int regalia: 1
            property int zzz: 0
            property int cookie: 1
            property int editorial: 1
        }
        property JsonObject transparency: JsonObject {
            property bool enable: false
            property bool automatic: true
            property real backgroundTransparency: 0.11
            property real contentTransparency: 0.57
        }
        property string iiMotionProfile: "contextual" // "classic" | "contextual"
        property JsonObject desaturation: JsonObject {
            property bool enable: false
            property real saturation: -0.7  // -1 to 0 (0 = normal, -1 = full grayscale)
            property real brightness: -0.15 // -1 to 1 (0 = normal)
            property string scope: "all"    // "all" | "panels" | "custom"
            property bool bar: true
            property bool dock: true
            property bool sidebars: true
            property bool overlays: true
            property bool popups: true
        }
        property bool extraBackgroundTint: true
        // Per-category multipliers on top of Appearance.animation.* base durations.
        // 1.0 = default speed, <1 faster, >1 slower. Zeroed regardless when
        // performance.reduceAnimations disables animations.
        property JsonObject animationSpeed: JsonObject {
            property real movement: 1.0   // elementMove, elementResize
            property real enterExit: 1.0  // elementMoveEnter, elementMoveExit
            property real clickBounce: 1.0 // clickBounce, elementMoveFast
            property real scroll: 1.0     // scroll, menuDecel
        }
        // Curve override per category. "default" keeps the existing style/motion-profile
        // aware pick in Appearance.animation.*; any other value forces that curve everywhere.
        property JsonObject animationCurve: JsonObject {
            property string movement: "default"
            property string enterExit: "default"
            property string clickBounce: "default"
            property string scroll: "default"
        }
    }
    property JsonObject lock: JsonObject {
        property JsonObject blur: JsonObject {
            property bool enable: true
            property real radius: 100
            property real extraZoom: 1.1
        }
        property bool centerClock: true
        property bool showLockedText: true
        property bool materialShapeChars: true
        property JsonObject dim: JsonObject {
            property bool enable: false
            property real opacity: 0.3 // 0.0 = no dim, 1.0 = full black
        }
        property JsonObject clock: JsonObject {
            property string style: "default" // "default", "minimal", "analog"
            property string position: "center" // "center", "topLeft", "bottomLeft"
        }
        property JsonObject notifications: JsonObject {
            property bool enable: false
            property int maxCount: 3
            property bool showBody: true
            property string position: "auto" // "auto" (center ii, right waffle), "center", "left", "right"
        }
        property JsonObject status: JsonObject {
            property bool enable: true
        }
        property JsonObject widgets: JsonObject {
            property bool weather: true
            property bool media: true
            property bool powerButtons: true
            property bool hintText: true
        }
    }
    property JsonObject notifications: JsonObject {
        // Posición del popup de notificaciones: topRight, bottomRight, topLeft, bottomLeft
        property string position: "topRight"
        // Margen respecto a los bordes de pantalla (px)
        property int edgeMargin: 4
        // Slightly enlarge notifications when the mouse hovers over them
        property bool scaleOnHover: false
    }
}
