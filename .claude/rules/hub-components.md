---
paths:
  - "components/**"
---

# Components

A component is a window or a service of its own that sits beside a family and never edits it: a window the app launcher
opens, work the shell does while nobody looks, or a tool set up once. Removing it takes all of it away and leaves the
person's desktop and settings as they were. What lives on the desktop (a card, a player, a feed) is a widget
(`hub-widgets.md`).

## Shape (`inir hub new component <id>` gives it)

- `plugin.json`: `"kind": "component"`, `"parts": {"panel": "Panel.qml"}`, `"families"` (the family ids it is worn with;
  `[]` for every family; `"ii"` for Material), and `version`.
- `hub.json`: `provides` (`modules/<id>`), `permissions`, `hosts`, and `requires` when it needs another plugin.
- `Panel.qml`: a `Scope` the shell loads while an active family is one that `families` names. Its window sits in a
  `LazyLoader` that is active while `open`, so nothing runs while it is closed. Its `IpcHandler` target is exactly the id,
  with a `toggle` function. `inir hub check` refuses a panel without it.
- `qmldir`: lists every type in its folder (`hub-qml.md`).

## People open it with the mouse

The app launcher of every family the component is worn with lists it by `plugin.json`'s `name` and `summary`, with
`icon.svg` or `icon.png` from its folder when it ships one. A click runs `inir <id> toggle`. The README lists the other
IPC calls, and a keybind in the compositor's config (`Mod+Shift+P { spawn "inir" "<id>" "toggle"; }`), as extras.

## State and files

- Options the person changes: a `FileView` with a `JsonAdapter` on `Directories.pluginFile("<id>")`, as the template does.
- Anything else it keeps (history, progress, a cache): files whose names start with the id, under
  `Directories.stateUserPath` or `$XDG_CACHE_HOME`. Never in `config.json`, never in another item's or a family's file.
- A family's own data (its follows, its lists, what it shows) is read, never changed. A feature that needs that change is
  a change to the family: an issue.

## Drawn with the family it is worn with

- iRiS: `IrisStyle.*` and the parts of `qs.modules.iris.components` and `qs.modules.iris.frame`, built the way iRiS's own
  surfaces are. Read an iRiS surface to learn the shape; never copy it.
- Material: `Appearance.*` and `qs.modules.ii.kit`. Waffle: `Looks.*` and the `W*` parts of `qs.modules.waffle.looks`.
- Every family: `FamilyStyle.*` (`qs.modules.common`) and the kit (`StyledText`, `MaterialSymbol`, `RippleButton`).
- What must be a family's own (its plate and glass, its switches) is one file per family, loaded by a `Loader` only while
  that family is active. A family that is not installed then never breaks the component.
- A family already has a feature like yours. Don't run a second copy beside it: build on what the family offers, or make
  yours different.

## Other items and the shell

- Ask the shell or another item through IPC: `Quickshell.execDetached(["inir", "<target>", "<function>"])`. Before
  reaching another item, check that it is installed (`Plugins.has("<id>")`), and hide the way to it when it isn't.
- Never write another item's files, and never import another item.

## Helpers

Scripts under `scripts/` follow `hub-scripts.md`.
