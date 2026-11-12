# iNiR Hub

iNiR's three families, plus widgets, colour themes, iRiS themes and web apps for [iNiR](https://github.com/snowarch/iNiR), made by the people who use it.

Browse them at **[inir.space/hub](https://inir.space/hub)**, or from your desktop (Settings, or `inir hub list`).

## Get something

In iNiR, open the Hub:

| Family | Where |
| --- | --- |
| Material | Settings › Hub |
| iRiS | Settings › Community Hub |
| Waffle | Settings › Hub |

Or from a terminal:

```sh
inir hub list                 # everything, ● marks what you have
inir hub search clock
inir hub info countdown
inir hub install countdown
inir hub update all
inir hub remove countdown
inir hub open countdown       # its page in Settings
```

An install puts the item where iNiR already reads it (your widgets, themes and sidebar folders), and a remove takes its files back. Its settings stay, so installing it again picks up where you left it. Before you install, the Hub says what an item can do beyond drawing itself: run commands, talk to the internet, read or write files outside its folder.

## What's here

| Kind | Folder | Shows up in |
| --- | --- | --- |
| Family | [`families/`](families) | The whole shell: Material, Waffle, iRiS. Setup installs the ones your config uses |
| Widget | [`widgets/`](widgets) | The Material desktop and sidebars, the iRiS Island, Waffle's Widgets panel (one widget can have a face for each) |
| Colour theme | [`themes/`](themes) | Material and Waffle, and the apps iNiR themes |
| iRiS theme | [`iris-themes/`](iris-themes) | A whole iRiS look: material, colour, shape, motion |
| Web app | [`webapps/`](webapps) | A tab in Material's left sidebar |
| Component | [`components/`](components) | Extras that plug into the shell: a look like `fastfetch`, or a panel worn with the families it names |

## Make something

[CONTRIBUTING.md](CONTRIBUTING.md) has the whole path. For widgets, [the Material guide](guides/material.md) shows how one earns its place beside the built-in ones, and [guides/widgets.md](guides/widgets.md) lists everything a widget can read. Making it with an AI assistant? Open it in a clone of this repository: it reads [AGENTS.md](AGENTS.md) by itself (Claude Code also `CLAUDE.md`, the `hub-item` skill and `.claude/rules/`), which keep it from breaking the shell. The short one:

```sh
inir hub new widget my-clock --author your-github-handle
inir hub check                # until it prints: nothing to fix
inir hub build && INIR_HUB_SOURCES=$PWD/dist inir hub install my-clock
inir hub submit widgets/my-clock
```

CI runs the same `inir hub check` on the pull request. The examples here (`countdown`, `shell-line`, `tidepool`, `moss-garden`, `excalidraw`) show the shape each kind takes; start from the template `inir hub new` writes, never from a copy of another item (the check refuses copies).

## Trust

Every item arrives by pull request. Colour themes and iRiS themes are data and merge once CI passes, and so do updates by an item's own authors that ask for nothing new. Anything else (a new widget, component, Design or web app, someone else's change, more permissions) is read by an AI reviewer against the rules in CONTRIBUTING.md and merges when it finds nothing to fix; a family, the tools or several items at once wait for a maintainer. A pull request adds or changes one item of its own: it can't change a family (the desktop every install gets, kept by its maintainers), iNiR itself, another item, or anyone's settings. CI checks that it changes only itself, validates it, checks that what the code does matches the permissions it declares, and builds the packages from this repository; iNiR checks each package's sha256 before installing it. That is a review, not a guarantee: read what you install, especially anything that runs commands.

Found something that misbehaves? [Report it](https://github.com/snowarch/inir-hub/issues/new?template=report.yml).

## Other hubs

iNiR reads more than one hub. Add the address of any `index.json` (or a local folder with one) in the Hub page under Sources, or in `hub.sources` in your config. `inir hub build` makes one from a repository laid out like this.

## Part of iNiR

iNiR is a few pieces, each with one job: [iNiR](https://github.com/snowarch/iNiR) is the shell base, in QML;
[qs-rs](https://github.com/snowarch/qs-rs) runs it; [inir-accel](https://github.com/snowarch/inir-accel) does what the
shell runs in the background; [inir-cli](https://github.com/snowarch/inir-cli) is the `inir` command, `inir hub`
included; this repo holds everything you install on top.

## License

The tools and templates are MIT. Each item carries its own license, shown on its page and in its `hub.json`.
