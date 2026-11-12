---
paths:
  - "widgets/**"
---

# Widgets

One widget, up to four faces: the Material desktop (`main`), Material's sidebars (`ii.main`, `ii.slots`), the iRiS
Island (`iris.main`, `iris.slots`) and Waffle's Widgets panel (`waffle.main`). Ship the faces you can make well; the Hub says where it shows.

## Read first

- `guides/material.md`: shapes, bars, looks and states of the built-in desktop widgets, and what a widget needs to sit
  beside them. `guides/widgets.md`: every property and service a widget reads. `guides/iris-widgets.md`: the Island.
- `widgets/countdown/`: all four faces and one shared `countdown.js`.

## Rules

- **`widget.json` declares** the faces (`main`, `ii`, `iris`, `waffle`), `defaultConfig`, `configKeys` (iNiR draws their
  controls), `resizableAxes` and `defaultSize`. The engine sizes and places the widget from it; the widget never
  moves or resizes itself.
- **A desktop widget wears the family's widget designs** (iNiR 3.1.0): under iRiS the Material `main` sits on its own
  card, without the glass, blur and ink the built-in widgets share. `"iris": { "desktop": { "iris": "IrisFace.qml",
  "prism": "PrismFace.qml" } }` names a face per design, each drawn in the widget's three sizes from
  `IrisWidgetFace` / `PrismFolder` (`radio/IrisRadioFace.qml`, `radio/PrismRadio.qml`; `guides/widgets.md`). The
  Material `main` stops drawing while `root.familyFaced`. An older iNiR ignores the key.
- **Logic lives once**, in a `.js` file every face imports. Faces only lay out.
- **Options** are `configKeys`. Read them with `root._readConfigKey(key)` (desktop) or
  `CustomWidgets.getConfigValue("<id>", key, fallback)` (sidebars, Island, Waffle); write with
  `CustomWidgets.setConfigValue("<id>", key, value)`. Never `Config.setNestedValue` or `Config.options… =`.
- **The desktop face's `configEntryName` is `"custom.<id>"`.**
- **Ink from the face's tokens.** Material: `root.widgetInk`, `widgetInkMuted`, `widgetInkSubtle`, `widgetAccent…`
  (they stay readable on any wallpaper). Material's sidebars: `SidebarStyle.*` (`guides/widgets.md › Material
  sidebar card`). iRiS: `IrisStyle.*`, `IrisText`. Waffle: `Looks.*`, `WText`.
- **Quiet while nobody looks:** timers and processes run only while `visible` (and, on the desktop, `motionActive`
  after a first run). Minute clocks for minutes.
- **`"service"` only for what must answer with no face on screen** (a keybind's `IpcHandler`; iNiR 3.1.0, see
  `guides/widgets.md`): a file that holds a reference to the widget's singleton and runs nothing on its own. No
  timer, fetch or process starts there; an older iNiR ignores the key.
- **Every state has words:** empty, loading, failed (show what failed), never a blank card.
- **Imports:** the base and `qs.modules.shared.background.widgets` (`AbstractBackgroundWidget`, the `Instrument*`
  parts) for the desktop, `qs.modules.ii.kit` for Material's sidebars, `qs.modules.iris.style` / `.components` for the Island, `qs.modules.iris.widgets` (and `.prism`) for an iRiS
  desktop face, `qs.modules.waffle.looks` for
  Waffle. Nothing else of a family.

## Preview

Install it, place it, set it to 200 % in edit mode in the state worth showing, then
`inir background widgetSnapshot custom.<id> shot.png` and
`inir hub preview widgets/<id> --wallpaper <image> --shot shot.png`.
