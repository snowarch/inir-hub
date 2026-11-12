---
paths:
  - "components/**"
---

# Components

A component is a feature of its own (a panel, a corner, a tool) that sits beside a family and never edits it.
Removing it takes all of it away and leaves the person's desktop and settings exactly as they were.

## Shape (`inir hub new component <id>` gives it)

- `plugin.json`: `"kind": "component"`, `"parts": {"panel": "Panel.qml"}`, `"families": ["iris"]` for the families
  it is worn with (empty for every family), `version` equal to `hub.json`'s.
- `hub.json`: `"provides": "modules/<id>"`, its permissions and hosts.
- `Panel.qml`: a `Scope` the shell loads once the family's own panels are up, while one of its families is active.
  It holds the window (inside a `LazyLoader` on `open`) and the `IpcHandler` whose target is exactly the id, with a
  `toggle`.
- `qmldir` in every folder of types, listing each one.
- People open it with the mouse: the shell lists every component with a panel in each family's app launcher, by
  `plugin.json`'s `name` and `summary` (with `icon.svg` or `icon.png` from the folder when it ships one), and a click
  runs `inir <id> toggle`; `inir hub check` refuses a panel without that handler. What lives on the desktop (a card, a
  player, a feed) is still a widget (`hub-widgets.md`). The README lists the IPC calls and a niri keybind
  (`Mod+Shift+P { spawn "inir" "<id>" "toggle"; }`) as extras.

## State and files

- Options the person changes: a `FileView` + `JsonAdapter` on `Directories.pluginFile("<id>")`, as the template does.
- Anything else it keeps (history, progress, a cache): files whose names start with the id, under
  `Directories.stateUserPath` or `$XDG_CACHE_HOME`. Never in `config.json`, never in another item's or a family's file.
- A family's own data (its follows, its lists, what it shows) is the family's: read what it offers, never change it.
  If the feature needs to, it is a change to the family: an issue.

## Worn with a family

- iRiS: draw with `IrisStyle.*` and the parts in `qs.modules.iris.components` and `qs.modules.iris.frame`, the way
  iRiS's own surfaces are built. Read an iRiS surface to learn the shape; never copy it into your folder.
- Material: `Appearance.*` and `qs.modules.ii.kit`. Waffle: `Looks.*` and the `W*` parts in `qs.modules.waffle.looks`.
- Every family: the shell's kit (`qs.modules.common`: `Appearance.*`, `StyledText`, `MaterialSymbol`,
  `RippleButton`).
- A family already has a feature like yours (iRiS has its own anime watching, Material its sidebars): yours must not
  run a second copy of it next to the first. Build on what the family offers, or make yours different.

## Talking to the shell and to other items

- Open, close or ask another item or the shell through IPC: `Quickshell.execDetached(["inir", "<target>",
  "<function>"])`. Check the other item is installed first (`Plugins.has("<id>")`) and hide the way to it when not.
- Never start `qs` or `quickshell`, never write another item's files, never import another item.

## Helpers

Scripts under `scripts/` follow `hub-scripts.md`: standard library only, arrays not shell strings, nothing installed.

## Size

A component that needs more than 2500 lines to be useful ships its first useful slice first: one page, one source,
the window and its IPC. Every next pull request adds one thing and raises the version. Each file stays under 600
lines: state, each page, each part on its own.
