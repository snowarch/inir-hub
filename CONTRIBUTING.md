# Contributing

Anything in the Hub installs with one command and removes cleanly. To keep it that way, every item follows the same shape, and CI checks it.

## The path

1. Fork this repository and start from a template:

   ```sh
   inir hub new widget my-clock --author your-github-handle
   ```

   Kinds: `widget`, `theme`, `iris-theme`, `webapp`. The id is the folder name: 3 to 48 characters, lowercase letters, digits and dashes. It is also what people type in `inir hub install`.

2. Make it, add a preview, and validate:

   ```sh
   inir hub validate widgets/my-clock
   ```

3. Try it installed, the way people will get it:

   ```sh
   inir hub build
   INIR_HUB_SOURCES=$PWD/dist inir hub install my-clock
   inir logs --issues            # nothing new from your item
   INIR_HUB_SOURCES=$PWD/dist inir hub remove my-clock
   ```

4. Open a pull request with only your item's folder. `dist/` is built by CI; leave it out.

## Every item

An item is a folder with the file iNiR itself reads, plus `hub.json` for the listing:

| Kind | Folder | iNiR reads | Installs to |
| --- | --- | --- | --- |
| Widget | `widgets/<id>/` | `widget.json` and its QML | `~/.config/inir/widgets/<id>/` |
| Colour theme | `themes/<id>/` | `theme.json` | `~/.config/inir/themes/<id>.json` |
| iRiS theme | `iris-themes/<id>/` | `theme.json` | `~/.config/inir/iris/themes/<id>.json` |
| Web app | `webapps/<id>/` | `manifest.json` | `~/.config/inir/plugins/<id>/` |

`hub.json`:

| Field | |
| --- | --- |
| `version` | `x.y.z`. Raise it with every change; CI compares it with `main`. For widgets and web apps it matches the version in the native file. |
| `summary` | What the card says, 8 to 80 characters: two lines on the smallest card. Say what it does, not what it is. |
| `description` | Optional, up to 600 characters. Widgets and themes take it from their own file. |
| `authors` | GitHub handles. |
| `license` | An SPDX id: `MIT`, `GPL-3.0-or-later`, `CC-BY-4.0`… |
| `tags` | Up to 6 lowercase words people might search for. |
| `permissions` | What it does beyond drawing itself. See below. |
| `minInir` | The oldest iNiR it works on, if it needs something recent. |
| `preview` | The screenshot file. Optional for themes. |

`README.md` in the folder is the item's page on GitHub: what it does, how to set it up, what each setting means. It is not installed.

## Widgets

One widget can have three faces. Give it the ones you can make well; the Hub says where it shows.

**Start with [the Material guide](guides/material.md).** It shows the shapes, bars, looks and states the built-in widgets use, and what a widget needs to sit beside them.

| Face | `widget.json` | Draws with | Look at |
| --- | --- | --- | --- |
| Material desktop | `main` | `AbstractBackgroundWidget`, `MaterialShape`, `WidgetSurface`, the `Instrument*` parts, `Appearance.*` | `countdown/Countdown.qml`, [guide](guides/material.md) |
| iRiS Island | `iris.main`, `iris.slots` | `IrisStyle.*` tokens, `IrisText` and the other `Iris*` parts | `countdown/IrisCountdown.qml` |
| Waffle Widgets panel | `waffle.main` | `Looks.*`, `WText` and the other `W*` parts, Fluent icons | `countdown/WaffleCountdown.qml` |

What makes a widget belong:

- **Each face uses its family's own tokens.** No hex colours, no hand-picked font sizes: the user's theme, scale and light or dark scheme must reach your widget. A Material face reads `root.widgetInk` for ink, so it stays readable on any wallpaper.
- **Shared logic lives in one `.js` file** that every face imports, like `countdown.js`. Faces only lay things out, so they never disagree.
- **Settings are `configKeys`** in `widget.json`. iNiR draws the controls; faces read them with `root._readConfigKey(key)` (desktop) or `CustomWidgets.getConfigValue("<id>", key, fallback)` (Island and Waffle).
- **The desktop face's `configEntryName` is `"custom.<id>"`.** That is where its position and settings are saved.
- **It costs nothing while nobody looks.** Clocks tick by the minute when minutes are enough (`SystemClock.Minutes`); timers and processes run only while `visible` (and `motionActive` on the desktop, after a first run).
- **Every state has words.** Empty, loading and failed each show something useful, never a blank card. `shell-line` shows what a failing command printed.

## Colour themes

`theme.json` is a Material palette: `name`, `description`, `author`, `darkmode`, and every `m3…` colour as `#rrggbb`. The template lists the ones iNiR needs. Applying it colours Material and Waffle and every app iNiR themes, and it lands in Settings › Themes beside the user's own.

The Hub draws your theme as a small Material desktop wearing it: bar, media card, toggles and notification, all in your colours. A real screenshot is welcome too: set `preview`.

## iRiS themes

An iRiS theme is a whole look: material, glass, colour, shape, type and motion. Make it in iRiS (Settings, or Customize on the Island), then:

```sh
inir iris theme export        # the look on screen, as a theme file
```

Put that in `theme.json`, set `"id"` to your folder name and keep only the `values` your theme is about. iRiS's own theme ids (`frost`, `afterglow`, `sakura`…) are taken.

The Hub draws a card from your accent, highlight and shape. A real screenshot says more: set `preview`.

## Web apps

`manifest.json`: `id` (the folder name), `name`, `url` (https only), `icon` (a [Material Symbols](https://fonts.google.com/icons) name), `version`, `display: "tab"`. It opens as a tab in Material's left sidebar, signed in as you, with the site's own storage.

A web app that ships scripts to run inside the page declares `inject`.

## Families, components and Designs

These are shell code: `plugin.json` names the parts the base loads, and `hub.json` says where it links in the shell
(`provides`, like `modules/iris`). Every folder that holds types carries a `qmldir` listing all of them. Stock
Quickshell reads those instead of scanning your plugin at every start, and trusts them whole, so a type left out is
"not a type" for everyone on Quickshell. `inir hub validate --fix` writes the missing ones for you.

## Previews

- A real screenshot of the item running. No mockups.
- Widgets: `inir background widgetSnapshot custom.<id> shot.png` at 200 %, then `inir hub preview widgets/<id> --wallpaper <image> --shot shot.png` frames it the way every card is framed.
- Anything else (a web app, a family, a component): a screenshot of the screen with it open, then `inir hub preview <folder> --shot screenshot.png` crops it to fill the card.
- 1280×800 (16:10), the size of every card in the Hub and on inir.space; `inir hub validate` holds it and `inir hub preview` makes exactly that. WebP (or PNG or JPEG), under 700 KB.
- The item large enough to read when the card is small. Crop around it.
- A wallpaper that leaves it readable, and nothing private: no messages, notifications, names, places or file paths.

## Permissions

| Permission | Declare it when the code |
| --- | --- |
| `process` | runs commands (`Process`, `execDetached`, `sh -c`) |
| `network` | talks to the internet (`XMLHttpRequest`, `curl`, `fetch`, `WebSocket`) |
| `files` | reads or writes files outside its folder (`FileView`, `FolderListModel`) |
| `inject` | (web apps) runs scripts inside the site it opens |

CI greps for these. Code that does something its `hub.json` does not declare fails; a permission nothing uses is a warning. The Hub shows them on the card and before install.

Never accepted, whatever it declares:

- piping a download into a shell, `eval()`, `Qt.createQmlObject()`
- loading QML from the internet
- decoding hidden content (`atob`, `base64 -d`)
- anything that collects data the person did not ask it to

## Review

A maintainer reads every pull request. What gets looked at:

- it does what the summary says, in each family it claims;
- it looks like it belongs there: the family's tokens and parts, sizes on the family's grid;
- it is quiet at idle;
- the permissions are honest and the license allows sharing;
- the preview is real.

The item stays yours. You are listed as its author, and later changes come as pull requests that raise its version. An item that breaks on a new iNiR and is not fixed may be hidden until it is.
