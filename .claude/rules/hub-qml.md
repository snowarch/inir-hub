---
paths:
  - "components/**/*.qml"
  - "components/**/*.js"
  - "widgets/**/*.qml"
  - "widgets/**/*.js"
  - "designs/**/*.qml"
  - "templates/**/*.qml"
---

# QML that never breaks the shell

Your file loads inside the person's running shell: on Qt 6.12, the version CI compiles with, and on Quickshell with the
distro's Qt on installs that don't run iNiR's runtime. A file that fails to load shows nothing and logs errors on every
desktop that installed it.

## Imports

- Import the base (`qs`, `qs.services`, `qs.modules.common` with its `widgets` and `functions`) and only what a family
  offers items: `qs.modules.iris.style`, `qs.modules.iris.components`, `qs.modules.iris.frame`,
  `qs.modules.waffle.looks`, `qs.modules.ii.kit`. Two more are offered to one kind each: a widget's iRiS desktop face
  takes `qs.modules.iris.widgets` (and its `.prism`), and a Design's Island face takes `qs.modules.iris.bar.island`.
  Everything else of a family changes with its releases, and an import of it stops the item loading.
- A shell singleton needs the module that holds it, imported in every file that names it: `GlobalStates` is `qs`;
  `Config`, `Directories` and `Appearance` are `qs.modules.common`; `Translation` is `qs.services`. Without it the file
  loads and fails at the first use (`ReferenceError`).
- Every folder that holds types has a `qmldir` listing each one. A `pragma Singleton` file is listed as
  `singleton Name 1.0 Name.qml`. Quickshell trusts the qmldir whole: a type left out is "not a type".
  `inir hub validate --fix` writes a folder's missing qmldir; a qmldir that misses a type is fixed by hand.
- Names that Qt 6.10 and older reserve are not property, function or id names: `long`, `int`, `short`, `char`, `float`,
  `double`, `native`. Never an `id` called `scale` or `state`, nor own properties named `left`, `top` or `baseline`.
- The JavaScript engine has no `Object.fromEntries`, `Array.flat`, `flatMap`, `at`, `replaceAll` or `structuredClone`.
- A typed parameter has no default: `force: bool = false` stops the file loading. Left out by the caller, a `bool`
  arrives as `false` and an `int` as `0`, but a `string` arrives as the text `"undefined"`: pass every string.
- No `Qt5Compat.GraphicalEffects` (use `QtQuick.Effects`), no `Qt.createQmlObject`, no `eval`, no QML from a URL.

## Cost

- A window exists only while it is open: `LazyLoader { active: root.open }` around it.
- A `Timer`, `Process`, fetch or animation runs only while what it feeds is on screen (`running: root.open && …`, or a
  widget's `visible`). A service that polls while closed (a feed checked on an interval, a watched file) is one the
  person turns on in Settings, and it runs at the longest interval that works.
- Clocks tick by the minute when minutes are enough: `SystemClock.Minutes`.
- What doesn't paint isn't built: effects and shapes behind `visible: false` still cost. Put them in a `Loader` whose
  `active` is the paint condition. Long lists use a `ListView` (delegates made on demand), not a `Repeater`.
- Per-row bindings never parse or stringify JSON, nor walk the config: compute once in a property.
- Long work runs in the process, never on the GUI thread: a loop over thousands of items in QML freezes every panel.
- A shown picture never gets a new `source` in place: it empties while it decodes. Crossfade it (`WallpaperCrossfader`)
  or keep the old one until the new one is `Ready` (`retainWhileLoading`; status is `Loading` meanwhile, so a
  `visible: status === Image.Ready` gate still blinks).
- Blur a picture that changes with `layer.effect: MultiEffect` on the visible item. A `MultiEffect` over a hidden source
  whose children turn `visible` on and off keeps an empty texture.
- A crossfade keeps the outgoing picture opaque while the new one fades in: fading both dips to 75 % at the middle.
- Thumbnails come from `ThumbnailImage` at the size shown, never a whole picture decoded per tile.
- A layer, mask or blur is on only while it shows something. Wallpaper analysis reads the `WallpaperLuma` grid
  (`Lume.quietest`), never a process per widget.

## Bindings and lifecycle

- `Connections { target: cond ? X : null }`: a disabled Connections still evaluates its target.
- `Qt.callLater` can run on an object that is gone: use your own `Timer { interval: 0 }`.
- A `Loader`'s `onLoaded` runs once and a `Repeater` reuses delegates: pass changing values with `Binding`, never by
  assignment in `onLoaded`.
- `foo: src` plus `onFooChanged: src = foo` breaks the binding. A binding-loop warning is a bug, never noise.
- No `Behavior` on a property something sets every frame (a drag, a scroll, a spring): it restarts each frame and lags.
- A control is never unloaded inside its own click handler: close on the next turn.

## Windows (layer shell)

- `PanelWindow` with a `WlrLayershell.namespace` of `quickshell:<id>`. Never re-anchor, resize per frame or change the
  layer of a live window: unload it and load it again. Limit input with `mask`, not by resizing.
- A mode that covers the desktop (Edit Mode, an overview) closes when a fullscreen window takes focus, such as a game.
- Keyboard focus is `OnDemand` for a window people type in, and Escape closes it. A window that must hold the keys
  (`Exclusive`) gives them up while a password prompt asks: `PolkitService.active ? WlrKeyboardFocus.None :
  WlrKeyboardFocus.Exclusive`. On Niri the first exclusive window keeps the keys, and the prompt cannot be typed in.

## Processes

- Commands are arrays (`["inir", "my-corner", "open"]`), never `sh -c` with text built from data: a title or a file name
  with a quote runs as code.
- Never start `qs`, `quickshell` or `qs -c inir ipc call …`. The shell runs on its own runtime. Reach the shell, or
  another item, with `["inir", "<target>", "<function>"]`.
- Read output with `StdioCollector` or `SplitParser`. Check the exit code and show the failure in words.

## IPC

- Every `IpcHandler` target starts with the item's id (`my-corner`, `myCornerSearch`). One handler answers each target in
  the whole shell; two answering the same target break the component.
- Each `IpcHandler` has a `///` line right above it, and each function in it has one too: `inir help` and the IPC
  reference are built from them. A keybind example goes below the comment as a ```` ```kdl ```` fence.

## Drawing

- Colours, corners, spacing, type and motion come from the family's tokens: `IrisStyle.*`, `Looks.*`, `Appearance.*`,
  and `FamilyStyle.*` in every family. No `"#rrggbb"`, no numeric `Qt.rgba`, no fixed `font.pixelSize`.
- A literal that is the point ends its line with `// literal: <why>`; in iRiS, `// iris-literal: <why>`.
- In a file that imports `qs.modules.iris.style`, no alpha of its own: `ColorUtils.applyAlpha(x, 0.4)` is refused. Use
  IrisStyle's fills and inks.
- Every state has words: empty, loading and failed (show what failed). Never a blank card.
