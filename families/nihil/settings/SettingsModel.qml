pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// What NiHiL's Settings holds, page by page: every line names its control, its key and the key's default. The window
// draws from here, search reads from here, and a page's restore key puts back what is listed here.
Singleton {
    id: root

    function shell(args: var): void { Quickshell.execDetached([Quickshell.shellPath("scripts/inir")].concat(args)) }
    function run(action: string): void {
        if (action === "wallpaper") root.shell(["wallpaperSelector", "toggle"])
        else if (action === "editDesktop") root.shell(["background", "setEditMode", "true"])
    }
    // What a key needs done once it is written.
    function after(hook: string, value: var): void {
        if (hook !== "palette" || ThemeService.isAutoTheme) return
        MaterialThemeLoader.applySchemeVariant(MaterialThemeLoader.colorToHex(Appearance.m3colors.m3primary), value,
            Appearance.m3colors.darkmode ? "dark" : "light")
    }

    function format(value: real, kind: string): string {
        if (kind === "percent") return Math.round(value * 100) + "%"
        if (kind === "pct") return Math.round(value) + "%"
        if (kind === "kelvin") return Math.round(value) + " K"
        if (kind === "seconds") return Math.round(value / 1000) + " s"
        return String(Math.round(value * 100) / 100)
    }

    readonly property string accentWord: ({
        signal: Translation.tr("Signal"), dynamic: Translation.tr("Wallpaper"), tertiary: Translation.tr("Second colour"),
        ink: Translation.tr("Ink"), custom: Translation.tr("Your hue")
    })[NihilStyle.accentMode] ?? Translation.tr("Signal")

    readonly property var languages: [{ value: "auto", label: Translation.tr("System") }]
        .concat(Translation.allAvailableLanguages.map(code => ({ value: code, label: Translation.languageDisplayName(code) })))

    // The shell's names for pages other families have.
    readonly property var aliases: ({
        themes: "look", appearance: "look", background: "wallpaper", modules: "system", about: "system", hub: "system",
        quick: "home", general: "system", interface: "bar", services: "apps", shortcuts: "keys", time: "region"
    })
    function resolve(key: string): string {
        const name = root.aliases[key] ?? key
        if (root.pages.some(entry => entry.key === name)) return name
        const index = Number(key)
        return Number.isInteger(index) && key.length > 0 ? (root.pages[index]?.key ?? "home") : "home"
    }
    function page(key: string): var { return root.pages.find(entry => entry.key === key) ?? root.pages[0] }

    function defaultsOf(entry: var): var {
        const kept = {}
        for (const section of entry?.sections ?? [])
            for (const row of section.rows)
                if (row.key && row.type !== "view" && row.type !== "action") kept[row.key] = row.fallback
        return kept
    }

    // Rows that answer every word of the search, by page. Home only repeats what other pages hold.
    function search(query: string): var {
        const words = query.toLowerCase().trim().split(/\s+/).filter(word => word.length > 0)
        if (words.length === 0) return []
        const seen = {}
        const groups = []
        for (const entry of root.pages) {
            if (entry.key === "home") continue
            const rows = []
            for (const section of entry.sections) {
                for (const row of section.rows) {
                    const said = [row.label, row.desc, row.words, section.title, entry.label].join(" ").toLowerCase()
                    if (seen[row.key] || !words.every(word => said.includes(word))) continue
                    seen[row.key] = true
                    rows.push(row)
                }
            }
            if (rows.length > 0) groups.push({ page: entry, rows: rows })
        }
        return groups
    }

    function sw(key: string, label: string, desc: string, fallback: bool, extra: var): var {
        return Object.assign({ type: "switch", key, label, desc, fallback }, extra ?? {})
    }
    function pick(key: string, label: string, desc: string, fallback: var, options: var, extra: var): var {
        return Object.assign({ type: "choice", key, label, desc, fallback, options }, extra ?? {})
    }
    function chips(key: string, label: string, desc: string, fallback: var, options: var, extra: var): var {
        return Object.assign({ type: "chips", key, label, desc, fallback, options, weight: 2 }, extra ?? {})
    }
    function level(key: string, label: string, desc: string, fallback: real, from: real, to: real, step: real, format: string, extra: var): var {
        return Object.assign({ type: "slider", key, label, desc, fallback, from, to, step, format }, extra ?? {})
    }
    function line(key: string, label: string, desc: string, fallback: string, extra: var): var {
        return Object.assign({ type: "field", key, label, desc, fallback }, extra ?? {})
    }
    function clock(key: string, label: string, fallback: string, extra: var): var {
        return Object.assign({ type: "time", key, label, desc: "", fallback }, extra ?? {})
    }
    function view(name: string, words: string, weight: int, extra: var): var {
        return Object.assign({ type: "view", key: "view:" + name, view: name, words, weight }, extra ?? {})
    }
    function act(label: string, desc: string, actionLabel: string, action: string, glyph: string): var {
        return { type: "action", key: "action:" + action, label, desc, actionLabel, action, glyph }
    }

    readonly property var idleChoices: [
        { value: 0, label: Translation.tr("Never") }, { value: 60, label: "1 min" }, { value: 120, label: "2 min" },
        { value: 300, label: "5 min" }, { value: 600, label: "10 min" }, { value: 900, label: "15 min" },
        { value: 1800, label: "30 min" }, { value: 3600, label: "1 h" }
    ]

    readonly property var pages: [
        {
            key: "home", label: Translation.tr("Home"), glyph: "home", line: Translation.tr("What you reach for most."),
            sections: [
                { title: Translation.tr("Right now"), wide: true, rows: [root.view("QuickKeys", "dark night disturb power", 2)] },
                { title: Translation.tr("Signal"), rows: [root.view("AccentPicker", "accent colour color hue", 3)] },
                { title: Translation.tr("Wallpaper"), rows: [root.view("WallpaperCard", "wallpaper background picture", 5)] }
            ]
        },
        {
            key: "look", label: Translation.tr("Look"), glyph: "palette", line: Translation.tr("Make NiHiL yours, one choice at a time."),
            sections: [
                { wide: true, rows: [root.view("Specimen", "preview", 3)] },
                { title: Translation.tr("Signal"), rows: [
                    root.view("AccentPicker", "accent colour color hue", 3),
                    root.level("nihil.theme.vividness", Translation.tr("Strength"), Translation.tr("How loud the signal is."), 1, 0.4, 1, 0.05, "percent"),
                    root.pick("nihil.theme.reach", Translation.tr("Reach"), Translation.tr("How much of NiHiL it lights."), "balanced", [
                        { value: "quiet", label: "Quiet" }, { value: "balanced", label: "Balanced" }, { value: "vivid", label: "Vivid" }])
                ] },
                { title: Translation.tr("Pieces"), rows: [
                    root.level("nihil.theme.tint", Translation.tr("Wallpaper tint"), Translation.tr("Lets the wallpaper's hue into the greys."), 0, 0, 0.35, 0.01, "percent"),
                    root.level("nihil.theme.opacity", Translation.tr("Solidity"), Translation.tr("How much wallpaper shows through."), 1, 0.55, 1, 0.01, "percent"),
                    root.level("nihil.theme.corners", Translation.tr("Corners"), Translation.tr("From tight to soft."), 1, 0.35, 1.25, 0.05, "percent"),
                    root.pick("nihil.theme.keys", Translation.tr("Keys"), "", "round", [{ value: "round", label: "Round" }, { value: "soft", label: "Soft" }])
                ] },
                { title: Translation.tr("Type and dots"), rows: [
                    root.pick("nihil.theme.dotShape", Translation.tr("Dots"), "", "round", [{ value: "round", label: "Round" }, { value: "square", label: "Square" }]),
                    root.pick("nihil.theme.font", Translation.tr("Reading type"), "", "grotesk", [{ value: "grotesk", label: "Grotesk" }, { value: "mono", label: "Mono" }]),
                    root.pick("nihil.theme.scale", Translation.tr("Size"), "", 1, [{ value: 0.9, label: "90%" }, { value: 1, label: "100%" }, { value: 1.1, label: "110%" }, { value: 1.25, label: "125%" }]),
                    root.pick("nihil.theme.motion", Translation.tr("Motion"), "", "full", [{ value: "full", label: "Full" }, { value: "calm", label: "Calm" }, { value: "off", label: "Off" }])
                ] },
                { title: Translation.tr("Colour scheme"), rows: [
                    root.view("LightDark", "light dark mode theme", 1, { label: Translation.tr("Light or dark") }),
                    root.sw("appearance.wallpaperTheming.autoDarkLightMode", Translation.tr("Follow the wallpaper"), Translation.tr("Light or dark, by how bright it is."), false),
                    root.chips("appearance.palette.type", Translation.tr("Palette"), "", "auto", [
                        { value: "auto", label: "Auto" }, { value: "scheme-content", label: "Content" }, { value: "scheme-expressive", label: "Expressive" },
                        { value: "scheme-fidelity", label: "Fidelity" }, { value: "scheme-fruit-salad", label: "Fruit salad" }, { value: "scheme-monochrome", label: "Monochrome" },
                        { value: "scheme-neutral", label: "Neutral" }, { value: "scheme-rainbow", label: "Rainbow" }, { value: "scheme-tonal-spot", label: "Tonal" }
                    ], { after: "palette" }),
                    root.level("appearance.wallpaperTheming.colorStrength", Translation.tr("Colour strength"), "", 1, 0.6, 1.8, 0.05, "percent")
                ] },
                { title: Translation.tr("Colour your apps"), rows: [
                    root.sw("appearance.wallpaperTheming.enableAppsAndShell", Translation.tr("GTK apps"), "", true),
                    root.sw("appearance.wallpaperTheming.enableQtApps", Translation.tr("Qt apps"), "", true),
                    root.sw("appearance.wallpaperTheming.enableTerminal", Translation.tr("Terminal"), "", true),
                    root.sw("appearance.wallpaperTheming.enableVSCode", Translation.tr("Code editors"), "", true),
                    root.sw("appearance.wallpaperTheming.enableChrome", Translation.tr("Chrome"), "", true),
                    root.sw("appearance.wallpaperTheming.enableFirefox", Translation.tr("Firefox"), "", true),
                    root.sw("appearance.wallpaperTheming.enableSpicetify", Translation.tr("Spotify"), "", true)
                ] }
            ]
        },
        {
            key: "wallpaper", label: Translation.tr("Wallpaper"), glyph: "wallpaper", line: Translation.tr("The picture everything sits on."),
            sections: [
                { title: Translation.tr("In use"), rows: [root.view("WallpaperCard", "wallpaper background picture", 5)] },
                { title: Translation.tr("Around it"), rows: [
                    root.sw("nihil.lock.blur", Translation.tr("Blur on the lock screen"), "", true),
                    root.sw("nihil.settings.backdrop", Translation.tr("Behind this window"), Translation.tr("Shows it, dimmed, behind Settings."), true)
                ] }
            ]
        },
        {
            key: "bar", label: Translation.tr("Bar"), glyph: "dock_to_bottom", line: Translation.tr("Round keys, floating at the edge."),
            sections: [
                { title: Translation.tr("Place"), rows: [
                    root.pick("nihil.bar.bottom", Translation.tr("Edge"), "", true, [{ value: true, label: "Bottom" }, { value: false, label: "Top" }]),
                    root.sw("nihil.bar.autoHide", Translation.tr("Hide until needed"), Translation.tr("Comes back when the pointer reaches the edge."), false)
                ] },
                { title: Translation.tr("On the bar"), rows: [
                    root.sw("nihil.bar.showSearch", Translation.tr("Search"), "", true),
                    root.sw("nihil.bar.showApps", Translation.tr("Open and pinned apps"), "", true),
                    root.sw("nihil.bar.monochromeIcons", Translation.tr("One-colour icons"), Translation.tr("Draws app icons in ink."), true)
                ] },
                { title: Translation.tr("Screens"), rows: [root.view("ScreensPicker", "monitor screen display output", 2, { label: Translation.tr("Show the bar on") })] }
            ]
        },
        {
            key: "widgets", label: Translation.tr("Widgets"), glyph: "widgets", line: Translation.tr("What lives on the desktop."),
            sections: [
                { title: Translation.tr("Faces"), rows: [
                    root.chips("nihil.widgets.design", Translation.tr("Widget faces"), "", "nihil", [
                        { value: "nihil", label: "NiHiL" }, { value: "material", label: "Material" }, { value: "instrument", label: "Instrument" }, { value: "readout", label: "Readout" }]),
                    root.pick("nihil.clock.style", Translation.tr("Clock"), "", "dots", [{ value: "dots", label: "Dots" }, { value: "fused", label: "Fused" }]),
                    root.sw("nihil.clock.twoTone", Translation.tr("Two-tone clock"), Translation.tr("Lights the minutes in the signal."), true)
                ] },
                { title: Translation.tr("Desktop"), rows: [
                    root.act(Translation.tr("Add or arrange widgets"), Translation.tr("Opens the desktop for editing."), Translation.tr("Edit"), "editDesktop", "dashboard_customize")
                ] }
            ]
        },
        {
            key: "notifications", label: Translation.tr("Notifications"), glyph: "notifications", line: Translation.tr("What may interrupt you, and when."),
            sections: [
                { title: Translation.tr("Attention"), rows: [
                    root.sw("notifications.silent", Translation.tr("Do not disturb"), Translation.tr("Keeps them in the list, without popups."), false),
                    root.sw("notifications.quietHours.enable", Translation.tr("Quiet hours"), Translation.tr("Do not disturb on a schedule."), false),
                    root.clock("notifications.quietHours.start", Translation.tr("From"), "22:00", { when: { key: "notifications.quietHours.enable", fallback: false, is: true } }),
                    root.clock("notifications.quietHours.end", Translation.tr("Until"), "08:00", { when: { key: "notifications.quietHours.enable", fallback: false, is: true } })
                ] },
                { title: Translation.tr("Popups"), rows: [
                    root.level("notifications.timeoutNormal", Translation.tr("Stay on screen"), "", 7000, 2000, 20000, 1000, "seconds"),
                    root.chips("notifications.timeoutCritical", Translation.tr("Urgent ones stay"), "", 0, [
                        { value: 0, label: Translation.tr("Until dismissed") }, { value: 15000, label: "15 s" }, { value: 30000, label: "30 s" }, { value: 60000, label: "60 s" }]),
                    root.sw("notifications.ignoreAppTimeout", Translation.tr("Ignore each app's own time"), "", false)
                ] },
                { title: Translation.tr("Sound"), rows: [
                    root.sw("sounds.notifications", Translation.tr("Play a sound"), "", true),
                    root.level("sounds.volume", Translation.tr("Volume"), "", 0.5, 0, 1, 0.05, "percent", { when: { key: "sounds.notifications", fallback: true, is: true } })
                ] }
            ]
        },
        {
            key: "sound", label: Translation.tr("Sound"), glyph: "volume_up", line: Translation.tr("What plays, what listens, how loud."),
            sections: [
                { title: Translation.tr("Devices"), rows: [root.view("SoundDevices", "volume output input microphone speaker headphones mute", 6)] },
                { title: Translation.tr("Protect your ears"), rows: [
                    root.sw("audio.protection.enable", Translation.tr("Limit sudden jumps"), "", true),
                    root.level("audio.protection.maxAllowed", Translation.tr("Highest volume"), "", 100, 50, 150, 5, "pct", { when: { key: "audio.protection.enable", fallback: true, is: true } }),
                    root.level("audio.protection.maxAllowedIncrease", Translation.tr("Largest jump"), "", 10, 5, 30, 1, "pct", { when: { key: "audio.protection.enable", fallback: true, is: true } })
                ] }
            ]
        },
        {
            key: "display", label: Translation.tr("Display"), glyph: "desktop_windows", line: Translation.tr("Sharpness, size and light."),
            sections: [
                { title: Translation.tr("Screens"), rows: [root.view("Displays", "resolution refresh rate scale monitor", 7)] },
                { title: Translation.tr("Brightness"), rows: [
                    root.view("BrightnessView", "brightness backlight", 2),
                    root.sw("light.antiFlashbang.enable", Translation.tr("Soften bright windows"), Translation.tr("Dims the screen when a white page opens."), false)
                ] },
                { title: Translation.tr("Night light"), rows: [
                    root.sw("light.night.automatic", Translation.tr("On a schedule"), "", false),
                    root.clock("light.night.from", Translation.tr("From"), "19:00", { when: { key: "light.night.automatic", fallback: false, is: true } }),
                    root.clock("light.night.to", Translation.tr("Until"), "06:30", { when: { key: "light.night.automatic", fallback: false, is: true } }),
                    root.level("light.night.colorTemperature", Translation.tr("Warmth"), Translation.tr("Lower is warmer."), 6000, 2500, 6500, 100, "kelvin")
                ] }
            ]
        },
        {
            key: "power", label: Translation.tr("Power"), glyph: "bolt", line: Translation.tr("When to rest, and how far to go."),
            sections: [
                { title: Translation.tr("When idle"), rows: [
                    root.chips("idle.screenOffTimeout", Translation.tr("Turn the screen off"), "", 300, root.idleChoices),
                    root.chips("idle.lockTimeout", Translation.tr("Lock"), "", 600, root.idleChoices),
                    root.chips("idle.suspendTimeout", Translation.tr("Sleep"), "", 0, root.idleChoices),
                    root.sw("idle.lockBeforeSleep", Translation.tr("Lock before sleeping"), "", true)
                ] },
                { title: Translation.tr("On battery"), rows: [
                    root.sw("idle.onBattery.enable", Translation.tr("Use shorter times"), "", false),
                    root.chips("idle.onBattery.screenOffTimeout", Translation.tr("Turn the screen off"), "", 120, root.idleChoices, { when: { key: "idle.onBattery.enable", fallback: false, is: true } }),
                    root.chips("idle.onBattery.lockTimeout", Translation.tr("Lock"), "", 300, root.idleChoices, { when: { key: "idle.onBattery.enable", fallback: false, is: true } }),
                    root.chips("idle.onBattery.suspendTimeout", Translation.tr("Sleep"), "", 600, root.idleChoices, { when: { key: "idle.onBattery.enable", fallback: false, is: true } })
                ] },
                { title: Translation.tr("Battery"), rows: [
                    root.level("battery.low", Translation.tr("Warn at"), "", 20, 5, 40, 1, "pct"),
                    root.level("battery.critical", Translation.tr("Urgent at"), "", 5, 2, 20, 1, "pct"),
                    root.sw("battery.automaticSuspend", Translation.tr("Sleep when almost empty"), "", false),
                    root.level("battery.suspend", Translation.tr("Sleep at"), "", 3, 1, 15, 1, "pct", { when: { key: "battery.automaticSuspend", fallback: false, is: true } }),
                    root.sw("battery.chargeLimit.enable", Translation.tr("Limit charging"), Translation.tr("Helps the battery last longer."), false),
                    root.level("battery.chargeLimit.threshold", Translation.tr("Stop charging at"), "", 80, 50, 100, 5, "pct", { when: { key: "battery.chargeLimit.enable", fallback: false, is: true } })
                ] },
                { title: Translation.tr("Session"), rows: [
                    root.sw("lock.security.requirePasswordToPower", Translation.tr("Password to power off"), Translation.tr("Asks for it on the lock screen."), false),
                    root.line("nihil.power.greeting", Translation.tr("Power card greeting"), Translation.tr("Leave empty for your name."), "", { placeholder: SystemInfo.username })
                ] }
            ]
        },
        {
            key: "keys", label: Translation.tr("Shortcuts"), glyph: "keyboard", line: Translation.tr("Every key combination, in one place."),
            sections: [{ wide: true, rows: [root.view("Shortcuts", "keybinds keyboard shortcuts keys", 8)] }]
        },
        {
            key: "region", label: Translation.tr("Region"), glyph: "language", line: Translation.tr("Language, time and weather."),
            sections: [
                { title: Translation.tr("Language"), rows: [root.chips("language.ui", Translation.tr("Language"), "", "auto", [], { optionsFrom: "languages" })] },
                { title: Translation.tr("Time"), rows: [
                    root.pick("time.format", Translation.tr("Clock"), "", "hh:mm", [{ value: "hh:mm", label: "24h" }, { value: "h:mm ap", label: "12h am" }, { value: "h:mm AP", label: "12h AM" }]),
                    root.sw("time.secondPrecision", Translation.tr("Keep time to the second"), "", false),
                    root.line("time.dateFormat", Translation.tr("Long date"), Translation.tr("ddd is the day, dd/MM the date."), "ddd, dd/MM", { mono: true, stacked: true })
                ] },
                { title: Translation.tr("Weather"), rows: [
                    root.sw("weather.enable", Translation.tr("Show the weather"), "", true),
                    root.pick("weather.useUSCS", Translation.tr("Units"), "", false, [{ value: false, label: "°C" }, { value: true, label: "°F" }]),
                    root.sw("weather.enableGPS", Translation.tr("Find my location"), "", false),
                    root.line("weather.city", Translation.tr("City"), "", "", { placeholder: Translation.tr("Your city"), when: { key: "weather.enableGPS", fallback: false, is: false } }),
                    root.sw("weather.hideLocation", Translation.tr("Hide the place name"), "", false)
                ] }
            ]
        },
        {
            key: "apps", label: Translation.tr("Apps"), glyph: "apps", line: Translation.tr("What opens when NiHiL asks for something."),
            sections: [
                { title: Translation.tr("Default apps"), rows: [
                    root.line("apps.terminal", Translation.tr("Terminal"), "", "kitty", { mono: true }),
                    root.line("apps.browser", Translation.tr("Browser"), "", "firefox", { mono: true }),
                    root.line("apps.volumeMixer", Translation.tr("Volume mixer"), "", "pavucontrol", { mono: true }),
                    root.line("apps.taskManager", Translation.tr("Task manager"), "", "missioncenter", { mono: true }),
                    root.line("apps.network", Translation.tr("Network"), "", "nm-connection-editor", { mono: true }),
                    root.line("apps.bluetooth", Translation.tr("Bluetooth"), "", "blueman-manager", { mono: true })
                ] },
                { title: Translation.tr("Search"), rows: [
                    root.line("search.engineBaseUrl", Translation.tr("Web search"), Translation.tr("The address your words are added to."), "https://www.google.com/search?q=", { mono: true, stacked: true }),
                    root.sw("search.sloppy", Translation.tr("Forgive typos"), Translation.tr("Finds apps from loose spelling."), false)
                ] }
            ]
        },
        {
            key: "system", label: Translation.tr("System"), glyph: "memory", line: Translation.tr("The shell itself."),
            sections: [
                { title: Translation.tr("Families"), wide: true, rows: [root.view("Families", "family shell material iris waffle change", 4)] },
                { title: Translation.tr("Performance"), rows: [
                    root.sw("performance.lowPower", Translation.tr("Low power"), Translation.tr("Fewer effects, longer battery."), false),
                    root.sw("performance.reduceAnimations", Translation.tr("Reduce animations"), "", false),
                    root.sw("gameMode.autoDetect", Translation.tr("Notice games"), Translation.tr("Steps aside when a game goes fullscreen."), true),
                    root.sw("gameMode.suppressNotifications", Translation.tr("Silence popups in games"), "", true)
                ] },
                { title: Translation.tr("About"), rows: [root.view("About", "version update about", 4)] }
            ]
        }
    ]
}
