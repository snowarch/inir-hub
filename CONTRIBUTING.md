# Contributing

Most items here are written with an AI assistant, so this page is written for it as much as for you. Give your
assistant this file and what you want to make. It works in a loop: write, run `inir hub check`, fix what it prints, and
stop only when it prints `nothing to fix`. CI runs the same check on your pull request, with the same messages, so
an item that passes on your machine passes there, and one that doesn't comes back to you to fix.

Working in this repository, an assistant finds its instructions by itself: `AGENTS.md` (any agent), `CLAUDE.md`, the
`hub-item` skill and the rules in `.claude/rules/` (Claude Code). They hold what this page holds, plus how to write
QML, helpers and each kind so they never break the shell.

## What to make

| You want | Make | Folder |
| --- | --- | --- |
| A widget for the Material desktop, the iRiS Island or Waffle's Widgets panel | a widget | `widgets/<id>/` |
| Colours for Material, Waffle and the apps iNiR themes | a colour theme | `themes/<id>/` |
| A whole iRiS look: material, colour, shape, motion | an iRiS theme | `iris-themes/<id>/` |
| Another iRiS: its own colour, type, shapes, edges, motion and Island face over iRiS's components (like AIRISU) | a Design | `designs/<id>/` |
| A website as a tab in Material's sidebar | a web app | `webapps/<id>/` |
| A feature of its own for the desktop: a panel, a corner, a tool, with a keybind (like an anime finder) | a component | `components/<id>/` |
| Something the shell runs or sets up with no panel of its own (like `fastfetch`) | a component | `components/<id>/` |
| A fix to Material, iRiS or Waffle | an issue | [open one](https://github.com/snowarch/inir-hub/issues) |

Material (`ii`), iRiS and Waffle are the desktops every iNiR install gets. Their maintainers change them; a pull request
from outside that touches `families/` is refused by CI. What you want to add to one is a component worn with it
([Adding to a family](#adding-to-a-family)): it sits beside the family, so the family people installed stays exactly
as it was, and removing your component takes all of it away.

## What an item may touch

Every item lives in its own folder and its own lane. Nothing outside a family can:

- **change a family, the base or another item.** A pull request changes one item's folder (and `docs/<id>/`).
- **land inside the shell's folders.** A plugin installs to `modules/<id>` (`"provides": "modules/<id>"`), never
  inside a family or the base's `common`, `shared` or `background`, and its id is its own across the whole hub.
- **write the person's settings.** `config.json` is theirs and the families'. A widget's options are its
  `widget.json` `"options"`; a component keeps its own in `Directories.pluginFile("<id>")`
  (`~/.config/inir/plugins/<id>.json`), so removing it leaves their settings as they were.
- **answer for someone else's IPC.** Its `IpcHandler` targets start with its id (`my-corner`, `myCornerSearch`).
- **reach inside a family.** It imports the base (`qs`, `qs.services`, `qs.modules.common`) and only what a family
  offers items: `qs.modules.iris.style`, `qs.modules.iris.components`, `qs.modules.iris.frame`,
  `qs.modules.waffle.looks`, `qs.modules.ii.kit`. The rest of a family (`iris.state`, `iris.pieces`,
  `iris.settings`, `iris.field`…) changes with each of its releases, and an item that imports it stops loading for
  everyone. A family's own data (its follows, its lists) is never changed from outside.
- **carry a copy.** A file that is mostly another file of the hub (a family's surface, another item's code) drifts
  from its original the day either changes. Import the part, or ask in an issue for it to be offered; two items that
  share most of their code are one item.
- **start the shell's binary.** Never `qs`, `quickshell` or `qs -c inir ipc call`: the shell runs on its own runtime.
  Reach it, or another item, with `inir <target> <function>`.

`inir hub check` and CI hold every one of these.

## The path

0. Every step runs the `inir` command, version 0.2.2 or newer (`inir cli version`). The one an iNiR install carries
   may be older: take the binary from [its releases](https://github.com/snowarch/inir-cli/releases) or
   `go install github.com/snowarch/inir-cli/cmd/inir@latest`. An older one checks less than CI does. CI runs the
   check from inir-cli's `main` branch: if yours passes and CI doesn't, take the newest with
   `go install github.com/snowarch/inir-cli/cmd/inir@main`.

1. Fork this repository. For a new item, start from its template (the id is the folder name: 3 to 48 characters,
   lowercase letters, digits and dashes, and what people type in `inir hub install`):

   ```sh
   inir hub new widget my-clock --author your-github-handle    # or component, theme, iris-theme, webapp
   ```

2. Read before writing: the example of its kind (`widgets/countdown`, `widgets/shell-line`, `components/fastfetch`,
   `themes/tidepool`, `iris-themes/moss-garden`, `webapps/excalidraw`) and the template `inir hub new` gave you. Use
   the shell's parts (import them, pass them what they need); never copy one out of a family and edit the copy, or
   the shell ends up with two of the same thing that drift apart.

3. Check, and repeat until it prints `nothing to fix`:

   ```sh
   inir hub check
   ```

4. Try it running, the way people will get it:

   ```sh
   inir hub build && INIR_HUB_SOURCES=$PWD/dist inir hub install my-clock
   # a component's panel is loaded at start: restart the shell once after installing it
   inir restart
   ```

   Open what you made and go through every state: empty, loading, failed, full, light and dark, small and large scale,
   in every family it is worn with. `inir logs --issues` must show nothing new from it. Then go back:
   `INIR_HUB_SOURCES=$PWD/dist inir hub remove my-clock`.

5. Send it. With `gh` logged in this checks it once more, commits it on its own branch, pushes to your fork and opens
   the pull request with the reviewer's card as its body (`--dry-run` shows the steps first):

   ```sh
   inir hub submit widgets/my-clock
   ```

   Without `gh`: commit your item's folder on a branch, push it and open the pull request yourself.

Once it is merged, people vote and react on its page in their shell's Hub; installs, votes and reactions are counted
daily from what they publish, and downloads from the packages release. It
reaches people within the hour: inir.space/hub rebuilds from `main`, and `inir hub update` (or a family through
`inir update`) brings it.

## What `inir hub check` holds you to

It reads what your branch changed since `origin/main` (`--base REF` for another branch), committed or not.

| Rule | Why |
| --- | --- |
| One item per pull request: its folder, and its page under `docs/<id>/`, nothing else. | A pull request can't break what it doesn't touch. `dist/`, `schema/`, `tools/`, workflows and other items stay as they are on `main`. |
| No change to `families/` (maintainers only). | The families are the desktop every install gets: what you add to one is a component worn with it. |
| A new item's id is free in the whole hub, and not `common`, `shared` or `background`. | People install by id, and a plugin lands at `modules/<id>`. |
| A plugin's `"provides"` is `modules/<id>`; every file `plugin.json` names in `"parts"` exists; `"families"` lists family ids. | The base loads parts by those names; a missing one is a surface that silently never appears. |
| Outside a family, no `Config.setNestedValue(…)` or `Config.options.x = …`. | The person's settings are theirs: removing your item must leave them as they were. |
| Outside a family, every `IpcHandler` target starts with the item's id. | So it can never answer for the shell or another plugin. |
| The item validates (`inir hub validate <folder>`): its files, listing, preview and permissions. | What the Hub shows and installs comes from these. |
| A changed item raises its `version`, in `hub.json` and the native file alike. | Installed copies update only when the version moves, and a published version never changes its contents. |
| Each raise says what changed, in `hub.json` › `changes`: `{"1.1.0": ["Clock face follows the wallpaper"]}`, a line people understand. | The Hub, the update notice and inir.space show it beside the update; a new preview alone needs no raise. |
| Every `IpcHandler` has a `///` comment right above it (one line on what the target is for), and every function in it has one too. | `inir help` and the IPC reference on inir.space are built from them. |
| A language the item ships holds every string its `en_US.json` holds. | A language you don't ship shows English; one that is half there mixes two languages on one screen. |
| The lines you add take colours from the family's tokens: no `"#rrggbb"`, no `Qt.rgba(0.2, …)` with numbers. | The person's theme and light or dark scheme reach only what reads the tokens. |
| In a file that draws with `IrisStyle`, no alpha of its own: no `ColorUtils.applyAlpha(x, 0.4)`. | iRiS has a token for every fill, ink and veil; its looks and Designs restyle them. |
| No fixed font sizes (`font.pixelSize: 14`). | The person's scale reaches only the family's type tokens. |
| No `Qt5Compat.GraphicalEffects`. | It isn't on every distro iNiR runs on; `QtQuick.Effects` (`MultiEffect`) is. |
| Outside a family, imports of a family only from what it offers items (`iris.style`, `iris.components`, `iris.frame`, `waffle.looks`, `ii.kit`; a Design's Island face also `iris.bar.island`). | The rest of a family changes with its releases; an item that imports it stops loading on every desktop that installed it. |
| No file that is mostly another file of the hub. | Two copies drift apart, and the shell ends up with two of one thing. |
| Never `qs`, `quickshell` or `qs -c inir …` started from an item. | The shell runs on its own runtime; `inir <target> <function>` reaches it on every install. |
| At most 600 lines in a file the branch adds or changes, outside families. | A file that does one job can be read, reviewed and fixed. |
| From outside, at most 2500 lines of code in one pull request (translations and docs not counted). | Nobody can review more whole, and what nobody read reaches every desktop that installs it. Send the smallest version that works, then one addition per pull request. |
| A Design's `design.json` holds only values iRiS reads, in the forms its schema allows (`families/iris/designs/design.schema.json`); the colours it fixes read (text 7:1 on its paper, secondary text 4.5:1, an accent 3:1, ink on a fill 4.5:1); its `parts` are at most `preview`, `islandFace` and `insignia`; it ships no shader. | iRiS reads a Design, never runs one: one set of components serves every Design, and a value it doesn't read would silently do nothing. |
| Every QML file parses with Qt 6.12, the Qt iNiR runs on (CI). | A file that doesn't parse fails on every desktop that installed it, the moment someone opens it. |

A literal that is the point (a flag's own red, a gradient's fade) ends its line with why: `// literal: the flag's red`,
or in iRiS `// iris-literal: the banner's fade`. Token files themselves (a family's `style/` or `looks/` folder) are
where literals belong.

## Every item

An item is a folder with the file iNiR itself reads, plus `hub.json` for the listing:

| Kind | Folder | iNiR reads | Installs to |
| --- | --- | --- | --- |
| Widget | `widgets/<id>/` | `widget.json` and its QML | `~/.config/inir/widgets/<id>/` |
| Colour theme | `themes/<id>/` | `theme.json` | `~/.config/inir/themes/<id>.json` |
| iRiS theme | `iris-themes/<id>/` | `theme.json` | `~/.config/inir/iris/themes/<id>.json` |
| Web app | `webapps/<id>/` | `manifest.json` | `~/.config/inir/plugins/<id>/` |
| Family, component | `families/<id>/`, `components/<id>/` | `plugin.json` and its QML | `~/.local/share/inir/plugins/<id>/`, linked at its `provides` |
| Design | `designs/<id>/` | `plugin.json`, `design.json` and at most three parts | `~/.local/share/inir/plugins/<id>/`, linked at its `provides` |

`hub.json`:

| Field | |
| --- | --- |
| `version` | `x.y.z`. Raise it with every change. For widgets, web apps, families and components it matches the version in the native file. |
| `changes` | Optional on a first version, required from the next: each version's notes, 1-6 lines of up to 140 characters, newest first in the Hub. |
| `summary` | What the card says, 8 to 80 characters: two lines on the smallest card. Say what it does, not what it is. |
| `description` | Optional, up to 600 characters. Widgets and themes take it from their own file. |
| `authors` | GitHub handles. |
| `license` | An SPDX id: `MIT`, `GPL-3.0-or-later`, `CC-BY-4.0`… |
| `tags` | Up to 6 lowercase words people might search for. |
| `permissions` | What it does beyond drawing itself. See below. |
| `minInir` | The oldest iNiR it works on, if it needs something recent. |
| `preview` | The screenshot file. Optional for themes. |

`README.md` in the folder is the item's page on GitHub: what it does, how to set it up, what each setting means. It is
not installed.

## Widgets

One widget can have three faces. Give it the ones you can make well; the Hub says where it shows.

**Start with [the Material guide](guides/material.md).** It shows the shapes, bars, looks and states the built-in
widgets use, and what a widget needs to sit beside them. Every property and service a widget can read is in
[guides/widgets.md](guides/widgets.md), the Island face in [guides/iris-widgets.md](guides/iris-widgets.md).

| Face | `widget.json` | Draws with | Look at |
| --- | --- | --- | --- |
| Material desktop | `main` | `AbstractBackgroundWidget`, `MaterialShape`, `WidgetSurface`, the `Instrument*` parts, `Appearance.*` | `countdown/Countdown.qml`, [guide](guides/material.md) |
| iRiS Island | `iris.main`, `iris.slots` | `IrisStyle.*` tokens, `IrisText` and the other `Iris*` parts | `countdown/IrisCountdown.qml` |
| Waffle Widgets panel | `waffle.main` | `Looks.*`, `WText` and the other `W*` parts, Fluent icons | `countdown/WaffleCountdown.qml` |

What makes a widget belong:

- **Each face uses its family's own tokens.** A Material face reads `root.widgetInk` for ink, `root.widgetInkMuted` and
  `root.widgetInkSubtle` for quieter text, and `root.widgetAccent…` for colour, so it stays readable on any wallpaper.
- **Shared logic lives in one `.js` file** that every face imports, like `countdown.js`. Faces only lay things out, so
  they never disagree.
- **Settings are `configKeys`** in `widget.json`. iNiR draws the controls; faces read them with
  `root._readConfigKey(key)` (desktop) or `CustomWidgets.getConfigValue("<id>", key, fallback)` (Island and Waffle).
- **The desktop face's `configEntryName` is `"custom.<id>"`.** That is where its position and settings are saved.
- **It costs nothing while nobody looks.** Clocks tick by the minute when minutes are enough (`SystemClock.Minutes`);
  timers and processes run only while `visible` (and `motionActive` on the desktop, after a first run).
- **Every state has words.** Empty, loading and failed each show something useful, never a blank card. `shell-line`
  shows what a failing command printed.

## Colour themes

`theme.json` is a Material palette: `name`, `description`, `author`, `darkmode`, and every `m3…` colour as `#rrggbb`.
The template lists the ones iNiR needs. Applying it colours Material and Waffle and every app iNiR themes, and it lands
in Settings › Themes beside the user's own.

The Hub draws your theme as a small Material desktop wearing it: bar, media card, toggles and notification, all in your
colours. A real screenshot is welcome too: set `preview`.

## iRiS themes

An iRiS theme is a whole look: material, glass, colour, shape, type and motion. Make it in iRiS (Settings, or Customize
on the Island), then:

```sh
inir iris theme export        # the look on screen, as a theme file
```

Put that in `theme.json`, set `"id"` to your folder name and keep only the `values` your theme is about. iRiS's own
theme ids (`frost`, `afterglow`, `sakura`…) are taken.

The Hub draws a card from your accent, highlight and shape. A real screenshot says more: set `preview`.

## Web apps

`manifest.json`: `id` (the folder name), `name`, `url` (https only), `icon` (a
[Material Symbols](https://fonts.google.com/icons) name), `version`, `display: "tab"`. It opens as a tab in Material's
left sidebar, signed in as you, with the site's own storage.

A web app that ships scripts to run inside the page declares `inject`.

## Adding to a family

A feature for Material, iRiS or Waffle is a component worn with it. `inir hub new component my-corner` gives you one:

- **`plugin.json`** names its surface in `"parts": {"panel": "Panel.qml"}` and the families it is worn with in
  `"families": ["iris"]` (leave the list empty for every family). The shell loads the panel once the family's own
  panels are up, while one of those families is active, and keeps it while the shell runs.
- **`Panel.qml`** holds its windows and its `IpcHandler` (target: its id). A window exists only while it is open:
  nothing runs, polls or animates while it is closed.
- **It draws with the family it is worn with.** Worn with iRiS only: `import qs.modules.iris.style` and draw with
  `IrisStyle.*` and the `Iris*` parts, the way iRiS's own surfaces do. Worn with every family: the shell's kit
  (`qs.modules.common`: `Appearance.*`, `StyledText`, `MaterialSymbol`, `RippleButton`).
- **Its options live in its file**, a `FileView` with a `JsonAdapter` on `Directories.pluginFile("<id>")`, as the
  template does.
- **People open it** with `inir <id> toggle`, bound to a key in niri's config; the README says which call does what.
- **Every string is translated**, its IPC documented, its page in `docs/<id>/`: the rules of
  [changing a family](#changing-a-family) below hold for a component too.

## Changing a family

For maintainers. Material (`ii`), iRiS and Waffle are the shell itself: whatever merges here reaches everyone who uses
that family on their next `inir update`. A change to one keeps everything `inir hub check` holds, and:

- **It is one change.** One fix or one feature per pull request, described in a sentence. Raise the family's version in
  `hub.json` and `plugin.json`.
- **It draws with the family.** iRiS: `IrisStyle.*` tokens and the `Iris*` parts in `components/`, `style/`, `frame/`.
  Material: `Appearance.*` and the kit in `kit/`. Waffle: `Looks.*` and the `W*` parts. Read how the surface beside
  yours is built and build yours the same way.
- **It reuses what is there.** If your feature needs something a part of the family already does (a layout, a size, a
  list, a search field), import that part, or move the shared piece into its own file that both use, in the same pull
  request. A second copy of the same logic is sent back.
- **Its state has one home.** State the family keeps goes in its state singleton (`state/IrisState.qml` in iRiS);
  settings go in its config schema with a default, and in its Settings page if people should change them.
- **Every string is translated.** Wrap what people read in `Translation.tr("English text")`. Add each new key to
  `translations/en_US.json` and translate it in every other file in that folder: the three families ship all 18
  languages (`ar_SA de_DE en_US es_419 fr_FR he_HE hi_IN id_ID it_IT ja_JP kl_GL ko_KR pt_BR ru_RU tr_TR uk_UA vi_VN
  zh_CN`). Keep `%1` placeholders and the meaning; a proper name (AniList, ani-cli) stays as it is.
- **A new IPC target is documented** with `///` above it and above each function, and a ```` ```kdl ```` fence in the
  comment when a keybind for it makes sense:

  ```qml
  /// The Anime Corner: find any show on AniList and watch it with ani-cli.
  ///
  /// ```kdl
  /// Mod+A { spawn "inir" "irisAnime" "toggle"; }
  /// ```
  IpcHandler {
      target: "irisAnime"
      /// Open or close it
      function toggle(): void { … }
  }
  ```

- **It is quiet at rest.** Nothing fetched, polled or animated while it is closed or hidden; a timer or a `Process`
  runs only while what it feeds is on screen.
- **It has its page.** What people see changed is described in the family's docs, `docs/<id>/` (the same pull request).
- **It was tried running** (step 4 above) in the family's every look it touches. Say which in the pull request.

## Families, components and Designs: the files

These are shell code: `plugin.json` names the parts the base loads, and `hub.json` says where it links in the shell
(`provides`, like `modules/iris`). Every folder that holds types carries a `qmldir` listing all of them. Stock
Quickshell reads those instead of scanning your plugin at every start, and trusts them whole, so a type left out is
"not a type" for everyone on Quickshell. `inir hub validate --fix` writes the missing ones for you.

## Previews

- A real screenshot of the item running. No mockups.
- Widgets: `inir background widgetSnapshot custom.<id> shot.png` at 200 %, then `inir hub preview widgets/<id>
  --wallpaper <image> --shot shot.png` frames it the way every card is framed.
- Anything else (a web app, a family, a component): a screenshot of the screen with it open, then `inir hub preview
  <folder> --shot screenshot.png` crops it to fill the card.
- 1280×800 (16:10), the size of every card in the Hub and on inir.space; `inir hub validate` holds it and `inir hub
  preview` makes exactly that. WebP (or PNG or JPEG), under 700 KB.
- The item large enough to read when the card is small. Crop around it.
- A wallpaper that leaves it readable, and nothing private: no messages, notifications, names, places or file paths.

## Permissions

| Permission | Declare it when the code |
| --- | --- |
| `process` | runs commands (`Process`, `execDetached`, `sh -c`, any `.sh`, `.py` or `.fish` file) |
| `network` | talks to the internet (`XMLHttpRequest`, `curl`, `fetch`, `WebSocket`) |
| `files` | reads or writes files outside its folder (`FileView`, `FolderListModel`; in a script, `>` to a file, `cp`, `mv`, `rm`, `ln`, `tee`, `touch`, `mkdir`, `sed -i`, Python's `open(..., "w")`, `os` and `shutil`) |
| `inject` | (web apps) runs scripts inside the site it opens |

CI greps for these. Code that does something its `hub.json` does not declare fails; a permission nothing uses is a
warning. The Hub shows them on the card and before install.

Never accepted, whatever it declares:

- piping a download into a shell, `eval()`, `Qt.createQmlObject()`
- loading QML from the internet
- decoding hidden content (`atob`, `base64 -d`)
- installing anything (`pip`, `npm`, a package manager) or `sudo`; Python helpers use the standard library only
- secrets in the repository: API keys, tokens, client secrets (the person enters their own, kept in the item's file)
- anything that collects data the person did not ask it to
- content the source has no right to give: streaming or download sites without the rights to what they host, DRM
  circumvention. The hub is public; one takedown removes it for everyone

## Review

A colour theme or an iRiS theme is data (nothing in it runs), so its pull request merges by itself once Check passes,
when it changes that one theme and its `docs/<id>/` only. Everything else waits for a maintainer.

`inir hub check` and CI hold the rules above; for code, a maintainer reads what no check can:

- it does what the summary says, in each family it claims;
- it looks like it belongs there: the family's parts, sizes on the family's grid, every state worded;
- it reuses the family instead of copying it, and is quiet at idle;
- the permissions are honest and the license allows sharing;
- the preview is real.

A pull request that needs changes gets them listed, and its author makes them on the same branch: push again and CI
runs again. The item stays yours. You are listed as its author, and later changes come as pull requests that raise its
version. An item that breaks on a new iNiR and is not fixed may be hidden until it is.

## Translations

The key is the English text you pass to `Translation.tr()`. A plugin that lives in `modules/<id>` keeps its own strings
in `translations/<locale>.json`, one file per language, each holding `"English text": "translated text"` and nothing
else; `en_US.json` lists every key. The shell reads them while the plugin is installed. Ship only the languages you can
translate whole: one you leave out shows English. A change to a family adds its strings to every language the family
ships.
