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

An item is one folder, `<kind-folder>/<id>/`, plus its page in `docs/<id>/`. Nothing else of the repository changes
in its pull request. The id is lowercase letters, digits and dashes (3 to 48), free across every kind, and never
`common`, `shared` or `background` (a plugin lands at `modules/<id>` in the shell).

## The files

- The native file iNiR reads: `widget.json`, `theme.json`, `manifest.json` or `plugin.json` (`CONTRIBUTING.md ›
  Every item` has the table).
- `hub.json`, the listing: `version` (`x.y.z`, the same as the native file's), `summary` (8 to 80 characters, what it
  does), `authors` (GitHub handles), `license` (SPDX id), `tags` (up to 6), `permissions`, `hosts` (every host it
  talks to), `minInir` when it needs a recent iNiR (never newer than the released one: CI refuses it), `preview`,
  and for plugins `"provides": "modules/<id>"`.
- `README.md`: what it does, how to open and set it up, what each option means. People read it on GitHub.
- `preview.webp` (or PNG/JPEG): a real screenshot, 1280×800, under 700 KB, nothing private in it. Make it with
  `inir hub preview <folder> --shot <screenshot>`; a widget also with `inir background widgetSnapshot`.
- `translations/<locale>.json` when it shows text: `en_US.json` lists every `Translation.tr("…")` key as
  `"English": "English"`; every other file you ship holds all of them. Ship only languages you translate whole.
- `docs/<id>/`: the page inir.space shows: a `docs.json` (`id`, `order`, `groups` of page names) and one Markdown
  file per page, `<NAME>.md` in capitals (`docs/iris/` is the smallest example).

## Changing an item that is already in the hub

- Raise `version` in `hub.json` and the native file together. Installed copies update only when it moves, and a
  published version never changes its contents.
- Keep the change to one thing, described in one sentence in the pull request.
- The lines you did not touch are not yours to reformat: a diff that rewrites a file to change two lines is sent back.

## Size

- One file does one job, at most 600 lines: the item's state, each page, each part, each helper in its own file.
- From outside, a pull request adds at most 2500 lines of code (translations, docs and images not counted). A big
  feature ships as the smallest version that works (one page, one source) and grows by pull requests that each add
  one thing and raise the version.
- Two items that share most of their code are one item. Never ship the same file in two items.

## Permissions

`process` (runs commands: `Process`, `execDetached`, any script), `network` (talks to the internet), `files` (reads
or writes outside its folder and its own options file), `inject` (a web app's scripts in the page). Declare exactly
what the code does; CI greps for it and the Hub shows it before install. `hosts` names each host, nothing wider.

## Never

Secrets in the repository (API keys, tokens, client secrets: the person enters their own and it lives in the
plugin's file); anything that collects data the person did not ask for; content the source has no right to give
(streaming or download sites without the rights to what they host, DRM circumvention). The hub is public: one
takedown removes it for everyone.
