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

Your file loads inside the person's running shell, on Qt 6.12 (iNiR's runtime) and on Quickshell with the distro's
Qt on older installs. A file that fails to load shows nothing and logs errors on every desktop that installed it.

## Imports and types

- Import the base (`qs`, `qs.services`, `qs.modules.common`, `.widgets`, `.functions`) and only what a family offers
  items: `qs.modules.iris.style`, `.components`, `.frame`; `qs.modules.waffle.looks`; `qs.modules.ii.kit`.
- A shell singleton needs the module that holds it imported in every file that names it: `GlobalStates` is `qs`;
  `Config`, `Directories` and `Appearance` are `qs.modules.common`; `Translation` is `qs.services`. Without it the
  file loads and fails at the first use (`ReferenceError`).
- Every folder that holds types has a `qmldir` listing all of them; a `pragma Singleton` file is listed as
  `singleton Name 1.0 Name.qml`. Quickshell trusts the qmldir whole: a type left out is "not a type".
  `inir hub validate --fix` writes the missing lines.
- Names Qt 6.10 and older reserve are not property, function or id names: `long`, `int`, `short`, `char`, `float`,
  `double`, `native`. Never an `id` called `scale` or `state`, nor own properties named `left`, `top`, `baseline`.
- The JavaScript engine has no `Object.fromEntries`, `Array.flat`/`flatMap`/`at`, `replaceAll`, `structuredClone`.
- No `Qt5Compat.GraphicalEffects` (use `QtQuick.Effects`), no `Qt.createQmlObject`, no `eval`, no QML from a URL.

## Cost: nothing runs while nobody looks

- A window exists only while it is open: `LazyLoader { active: root.open }` around it. Closed, nothing of it runs.
- A `Timer`, `Process`, fetch or animation runs only while what it feeds is on screen (`running: root.open &&
  …`, a widget's `visible`). Polling while closed (new-episode checks every 30 minutes, a watcher of a file) is a
  service the person turns on, says so in Settings, and runs at the longest interval that works.
- Clocks tick by the minute when minutes are enough (`SystemClock.Minutes`).
- What doesn't paint isn't built: effects and shapes behind `visible: false` still cost; put them in a `Loader` whose
  `active` is the paint condition. Long lists use a `ListView` (delegates made on demand), not a `Repeater`.
- Per-row bindings never parse or stringify JSON, nor walk the config: compute once in a property.

## Bindings and lifecycle

- `Connections { target: cond ? X : null }`: a disabled Connections still evaluates its target.
- `Qt.callLater` can run on an object that is gone: use your own `Timer { interval: 0 }`.
- A `Loader`'s `onLoaded` runs once and a `Repeater` reuses delegates: pass changing values with `Binding`, never by
  assignment in `onLoaded`.
- `foo: src` plus `onFooChanged: src = foo` breaks the binding. A binding-loop warning is a bug, never noise.
- No `Behavior` on a property something sets every frame (a drag, a scroll, a spring): it restarts each frame and lags.
- A control is never unloaded inside its own click handler: close on the next turn.
- One `IpcHandler` per target in the whole shell (the id prefix keeps yours apart); two answering the same target
  break the component.

## Windows (layer shell)

- `PanelWindow` with a `WlrLayershell.namespace` of `quickshell:<id>`. Never re-anchor, resize per frame or change
  the layer of a live window: unload it and load it again. Limit input with `mask`, not by resizing.
- Keyboard focus `OnDemand` for a window people type in, and Escape closes it.

## Processes

- Commands are arrays (`["inir", "my-corner", "open"]`), never `sh -c` with text built from data: a title or a file
  name with a quote runs as code.
- Never start `qs`, `quickshell` or `qs -c inir ipc call …`: use `["inir", "<target>", "<function>"]`.
- Read output with `StdioCollector` or `SplitParser`; check the exit code and show the failure in words.
- Long work runs in the process, never on the GUI thread: a loop over thousands of items in QML freezes every panel.

## Drawing

Colours, corners, spacing, type and motion come from the family's tokens (`IrisStyle.*`, `Looks.*`,
`Appearance.*`): no `"#rrggbb"`, no numeric `Qt.rgba`, no fixed `font.pixelSize`. A literal that is the point ends its
line with `// literal: <why>` (in iRiS `// iris-literal: <why>`). Every state has words: empty, loading, failed.
