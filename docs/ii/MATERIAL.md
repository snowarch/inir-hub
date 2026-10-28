# Material

Material (ii) is the default family: a bar on an edge, two sidebars, a dock and an overview, in nine global styles.
Everything here is set in **Settings**, which opens with **Super+,**.

<!-- preview shot=material-bar -->

## On your screen

- **Bar**: along the top by default. **Settings › Quick › Bar position** puts it on any edge, and **Settings › Bar**
  sets its look, its corners and which modules sit in each of its five zones.
- **Dock**: **Settings › Dock** turns it on and sets its position, how it reveals itself and the window previews.
  A hidden bar or dock opens when the pointer rests on its edge for a moment, not on a quick pass, and stays a
  little after the pointer leaves.
- **Left sidebar**: AI chat, YT Music, the Wallhaven browser, the translator and the world clock. On iNiR's runtime
  (qs-rs) it can also hold **Web Apps** (**Settings › Sidebars › Web Apps**): Discord, YouTube Music and the other web
  apps from the Hub. They need Qt WebEngine, a one-time download of about 110 MB that `inir update` brings while the
  tab is on. If it is missing, the tab says so and has a **Download** button.
- **Right sidebar**: quick toggles, sliders, the notification history and the calendar. Both sidebars are arranged in
  **Settings › Sidebars**.
- **Overview**: **Super+Space** shows your workspaces and searches apps and [actions](GLOBAL_ACTIONS.md).
- **Dashboard**, **Orbit** and the **Workspace Strip** are optional panels, each with its own page in Settings.

<!-- preview shot=material-sidebars -->

## Where things are in Settings

The sidebar groups the pages. **Edit navigation** in the header, or **Settings › Arrange**, reorders or hides them;
hidden pages stay in search.

| Group | Pages |
| --- | --- |
| Essentials | Quick (wallpaper, colours, bar position, Game Mode), Hub |
| Appearance | Themes, Effects, Wallpaper, Widgets, Ricelin |
| Shell | Bar, iRiS, Shell Layout, Orbit, Panels, Dock, Sidebars, Dashboard, Modules, Waffle Style, Workspace Strip, Mascot, Arrange |
| System | System (audio, battery, language), AI, Services, Tools, Compositor, Monitors, Advanced, Autostart |
| Reference | Shortcuts, About |

Easy mode shows only the essential pages and sections. The button in the Settings header switches between Easy and
Advanced.

## Its looks

**Settings › Themes › Global Style** changes the whole family at once: Material, Cards, Aurora, Inir, Angel, Regalia,
ZZZ, Cookie Shapes or [Editorial](EDITORIAL_STYLE.md). Some styles bring their own editor on the same page. Colours
follow the wallpaper or a colour theme: [Colours and themes](THEMING_PRESETS.md).

## Common changes

- Move everything around by hand: **Settings › Shell Layout**.
- Desktop widgets and their grid: **Settings › Widgets**.
- Blur, glass and animations: **Settings › Effects**. See [Optimization](OPTIMIZATION.md).
- Notifications, Alt+Tab and the floating tools (**Super+G**): **Settings › Panels**.
- Kira, the mascot: **Settings › Mascot**.
- Clipboard history: **Super+V** opens it (it needs `cliphist`); **Settings › Modules** turns the panel on or off.
- Screenshots, text and recording: **Super+Shift+S** opens the region toolbar. Where files go, the snip and the
  recording sound: **Settings › Tools**.
- Lock screen: **Super+Alt+L** locks; **Settings › System › Lock screen** sets what it shows.
- Weather: **Settings › Services › Weather** (place, units, how often it refreshes).
