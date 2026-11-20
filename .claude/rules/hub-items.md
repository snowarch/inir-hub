---
paths:
  - "components/**"
  - "widgets/**"
  - "themes/**"
  - "iris-themes/**"
  - "webapps/**"
  - "designs/**"
  - "docs/**"
---

# Every hub item

An item is one folder, `<kind-folder>/<id>/`, plus its page in `docs/<id>/`. Its pull request changes nothing else of
the repository. The id is 3 to 48 characters of lowercase letters, digits and dashes, free across every kind, and never
`common`, `shared` or `background`: a plugin installs to `modules/<id>` in the shell, and those are the base's own folders.

The kind sets the native file and its rules: `widget.json` (`hub-widgets.md`), `plugin.json` of a component
(`hub-components.md`) or of a Design (`hub-designs.md`), `theme.json` (`hub-themes.md`), `manifest.json` of a web app
(`hub-webapps.md`).

## hub.json

The listing. Its fields:

- `version`: `x.y.z`. A widget's and a web app's native `version` must equal it; CI checks both.
- `summary`: 8 to 80 characters, what it does.
- `description`: optional, up to 600 characters. A `description` in the native file is used first.
- `authors`: GitHub handles. `license`: an SPDX id. `tags`: up to 6 lowercase words.
- `permissions` and `hosts`: see Permissions.
- `minInir`: the oldest iNiR it needs, when it needs something recent. CI refuses a value newer than the VERSION on
  iNiR's main.
- `preview`: the screenshot file. Required except for colour themes and iRiS themes.
- `provides`: for a plugin, `modules/<id>`. `requires`: for a plugin, the ids of the plugins it needs. A Design names
  the family it dresses.
- `changes`: see Changing an item in the hub.

## Files

- `README.md`: what it does, how to open and set it up, what each option means. People read it on GitHub. It is not
  installed.
- The preview: `preview.webp`, `.png` or `.jpg`; 1280×800, under 700 KB; a real screenshot of it running, with nothing
  private in it. `inir hub preview <folder> --shot <screenshot>` makes it. A widget's preview: `hub-widgets.md › Preview`.
- `translations/<locale>.json` when it shows text. `en_US.json` lists every `Translation.tr("…")` key as
  `"text": "text"`. Every other file holds every key, translated. A language that is only partly translated is refused:
  leave the file out, and the shell shows English.
- `docs/<id>/`: the page inir.space shows. `docs.json` holds `id`, `edit`, `order` and `groups`; each group is
  `{"label": …, "pages": ["NAME"]}`. Each page is `<NAME>.md` in capitals beside it. `docs/countdown/` is the shape to copy.

## Changing an item in the hub

- Any change raises `version` in `hub.json`, and in the native file where it has one. CI refuses a changed item whose
  version did not move. Installed copies update only when it moves, and a published version never changes its contents.
- The raised version gets its line in `hub.json` `changes`: `{"1.1.0": ["Clock face follows the wallpaper"]}`. Each
  version holds 1 to 6 lines of up to 140 characters, and no version in `changes` may be above `version`.
- One change per pull request, described in one sentence.
- Do not reformat lines you did not change.

## Size

- Each file does one job. Outside a family, a file that the pull request adds or changes holds at most 600 lines: split
  by job (state, each page, each part, each helper).
- A pull request has no size cap. A diff too big for the reviewer to read whole goes to a maintainer.
- Two items that share most of their code are one item. Never ship the same file in two items.

## Permissions

`permissions` in `hub.json` lists what the code does beyond drawing itself:

- `process`: runs commands (`Process`, `execDetached`, `sh -c`, any script).
- `network`: talks to the internet (`XMLHttpRequest`, `curl`, `fetch`, `WebSocket`).
- `files`: reads or writes outside its folder and its own options file.
- `inject`: runs scripts inside a web app's page.

Declare exactly what the code does. `inir hub check` looks for each one: a permission the code uses and the listing
does not declare is an error, and a declared one that no code uses is a warning. `hosts` names each host the code
reaches, a domain covering its subdomains, and nothing wider. The Hub shows both before install.

## Never

- Touch anything but its own folder and its `docs/<id>/` page: never `families/`, another item, `schema/`, `tools/`,
  `templates/`, `.github/`, `dist/`, or the instruction files.
- Copy a file of the hub and edit the copy. Import only what a family offers (`hub-qml.md › Imports`).
- Write the person's settings or a family's state. Answer for someone else's IPC: every `IpcHandler` target starts with
  the item's id (`hub-qml.md › IPC`).
- Install, elevate or download code: no `pip`, `npm` or other package manager, no `sudo`, no `curl … | sh`, no `eval`,
  no `Qt.createQmlObject`, no QML from the internet, no `atob` or `base64 -d` on hidden content. Python helpers use the
  standard library only.
- Carry secrets: no API keys, tokens or client secrets in the repository. The person enters their own, and it is kept in
  the item's file.
- Collect data the person did not ask for.
- Use content the source has no right to give: no scraping or streaming of sites that host films, shows, music or games
  without the rights to them, no DRM circumvention. The hub is public: one takedown removes an item for everyone.
- Declare less than it does: `permissions` and `hosts` match the code.
