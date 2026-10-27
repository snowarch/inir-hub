# iNiR Hub

Widgets, colour themes, iRiS themes and web apps for [iNiR](https://github.com/snowarch/inir), made by the people who use it.

Browse them at **[inir.space/hub](https://inir.space/hub)**, or from your desktop (Settings, or `inir hub list`).

## Get something

In iNiR, open the Hub:

| Family | Where |
| --- | --- |
| Material | Settings › Hub |
| iRiS | Settings › More Settings › Community Hub |
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
| Widget | [`widgets/`](widgets) | The Material desktop, the iRiS Island, Waffle's Widgets panel (one widget can have all three faces) |
| Colour theme | [`themes/`](themes) | Material and Waffle, and the apps iNiR themes |
| iRiS theme | [`iris-themes/`](iris-themes) | A whole iRiS look: material, colour, shape, motion |
| Web app | [`webapps/`](webapps) | A tab in Material's left sidebar |

## Make something

[CONTRIBUTING.md](CONTRIBUTING.md) has the whole path, and [the Material guide](guides/material.md) shows how a widget earns its place beside the built-in ones. The short one:

```sh
inir hub new widget my-clock --author your-github-handle
inir hub validate widgets/my-clock
inir hub build && INIR_HUB_SOURCES=$PWD/dist inir hub install my-clock
```

Then open a pull request. The examples here (`countdown`, `shell-line`, `tidepool`, `moss-garden`, `excalidraw`) are written to be copied.

## Trust

Every item arrives by pull request and is read before it merges. CI validates it, checks that what the code does matches the permissions it declares, and builds the packages from this repository; iNiR checks each package's sha256 before installing it. That is a review, not a guarantee: read what you install, especially anything that runs commands.

Found something that misbehaves? [Report it](https://github.com/snowarch/inir-hub/issues/new?template=report.yml).

## Other hubs

iNiR reads more than one hub. Add the address of any `index.json` (or a local folder with one) in the Hub page under Sources, or in `hub.sources` in your config. `inir hub build` makes one from a repository laid out like this.

## License

The tools and templates are MIT. Each item carries its own license, shown on its page and in its `hub.json`.
