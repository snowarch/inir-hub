---
paths:
  - "widgets/**"
---

# Widgets

One widget, up to four faces: the desktop card (`main`), a card in Material's sidebars (`ii.main`), the iRiS Island
(`iris.main`), and a card in Waffle's Widgets panel (`waffle.main`). Under iRiS, a desktop widget can also carry one
face per iRiS widget design (`iris.desktop`). Ship the faces you can make well; the Hub says where each one shows.

## Read first

- `guides/material.md`: shapes, bars, looks and states of the built-in desktop widgets.
- `guides/widgets.md`: every property and service a widget reads. `guides/iris-widgets.md`: the Island face.
- `widgets/countdown/`: the four faces and the shared `countdown.js`.

## widget.json

- Declares its faces: `main` (the desktop; left out, it is the PascalCase id with `.qml`), `ii` (`main`, `slots`), `iris`
  (`main`, `slots`), `waffle` (`main`). A widget with no face is refused, and every file it names must exist.
- Declares `defaultConfig`, `configKeys` or `options`, `sizes`, `resizableAxes`, `defaultSize` and `service`.
- The engine sizes and places the widget from these. The widget never moves or resizes itself.
- `configKeys` are the person's options. `options`, when present, are the rows the sheet shows (`guides/widgets.md`).

## Desktop: a face per iRiS widget design

Under iRiS the person picks the widget's design (iRiS or Prism) in its sheet. A face per design is named in the `iris`
block:

```json
"iris": { "main": "IrisCompact.qml", "slots": ["island.desktop"],
          "desktop": { "iris": "IrisFace.qml", "prism": "PrismFace.qml" } }
```

- Each file is loaded inside the Material `main` with `widget` set to it. It fills that space and draws the whole widget
  in every size the widget declares (`sizes`). Its root is `IrisWidgetFace` (`qs.modules.iris.widgets`: plate, glass,
  blur, the inks `ink`, `inkSecondary`, `inkTertiary` and `accent`, and the parts `FaceText`, `FaceHeader`, `FaceAction`),
  or, for Prism, `PrismFolder` (`qs.modules.iris.widgets.prism`).
- The Material `main` stops drawing while a face is worn: `visible: !root.familyFaced` on its drawing, and on the sheet
  rows that only the Material card reads.
- A design with no file shows the Material card. An older iNiR ignores the key.
- `inir hub check` does not open these files. Test each design.
- The desktop `main` file sets `configEntryName` to `"custom.<id>"`.
- Examples: `widgets/radio/IrisRadioFace.qml` and `widgets/radio/PrismRadio.qml`.

## Logic and options

- Logic lives once, in a `.js` file that every face imports. Faces only lay out.
- Read options with `root._readConfigKey(key)` on the desktop, or with `CustomWidgets.getConfigValue("<id>", key, fallback)`
  in the sidebars, the Island and Waffle. Write with `CustomWidgets.setConfigValue("<id>", key, value)`.
  `Config.setNestedValue` and `Config.options… =` are refused in a widget.

## Ink and type from the face's tokens

- Material desktop: `root.widgetInk`, `widgetInkMuted`, `widgetInkSubtle`, `root.widgetAccent…`.
- Material sidebars: `SidebarStyle.*` from `qs.modules.ii.kit`.
- iRiS: `IrisStyle.*` and `IrisText`.
- Waffle: `Looks.*` and `WText`.

## Cost and service

- The cost rules of `hub-qml.md › Cost` apply. On the desktop, timers and processes also wait for `motionActive`; the
  first run happens anyway, so a widget behind a window is not stuck on its first state.
- `"service"` names a file for what must answer with no face on screen, such as an `IpcHandler` a keybind calls. The file
  holds a reference to the widget's singleton and starts nothing itself: no timer, fetch or process. An older iNiR
  ignores the key.
- A reload replaces the singleton with a fresh copy, and the old copy is never destroyed. So the singleton retires itself
  once the list stops pointing at its folder: it stops what it plays and turns its `IpcHandler` off. Copy the pattern in
  `widgets/radio/Radio.qml` (`installed`, `retired`).

## Imports

- Desktop: the base, `qs.modules.shared.background.widgets` (`AbstractBackgroundWidget`), and the `Instrument*` parts from
  `qs.modules.shared.background.widgets.instrument`.
- Material sidebars: `qs.modules.ii.kit`. iRiS Island: `qs.modules.iris.style`, `qs.modules.iris.components` and
  `qs.modules.iris.frame`. iRiS desktop face: `qs.modules.iris.widgets` and `.prism`. Waffle: `qs.modules.waffle.looks`.
- Nothing else of a family (`hub-qml.md › Imports`).

## Preview

Install it, put it on the desktop, set it to 200 % in edit mode in the state worth showing, then:

```sh
inir background widgetSnapshot custom.<id> shot.png
inir hub preview widgets/<id> --wallpaper <image> --shot shot.png
```
