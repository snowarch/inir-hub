---
name: hub-item
description: Make or change an iNiR Hub item (desktop widget, component, colour theme, iRiS theme, web app) from the first idea to a pull request that passes CI. Use when asked to create, port, fix, update or send a plugin, widget, theme or web app for iNiR, or when `inir hub check` fails.
---

# Making an iNiR Hub item

Read `AGENTS.md` first if you have not this session. The steps below are in order; none is skipped.

## 1. Settle what it is

- Ask the person, in one message, only what you can't decide: what it shows or does, which families it is for
  (Material, iRiS, Waffle, all), and for a feature that fetches anything, the source.
- Pick the kind (`CONTRIBUTING.md › What to make`). A change to a family itself is an issue: say so and stop.
- Before the first file, write in one line per family where a person finds it and opens it with the mouse (Material's
  widget shelf, the iRiS Island, Waffle's Widgets panel). If the kind you picked gives it no such place, the kind is
  wrong: what people use is a widget. Never change a family or the base to fit the item.
- Check the source: an official API or a site whose terms allow the use, no key you would have to ship. If none,
  say so and stop.
- Plan the first version so it is useful and under 2500 lines of code: one page, one source. Write the plan as a
  short list of files, each with its one job, none near 600 lines. Later features are later pull requests.

## 2. Start

```sh
git switch -c <id> origin/main
inir hub new <kind> <id> --author <github-handle>
```

Read the template it wrote, the example of the kind and the rules in `.claude/rules/` for what you will touch
(`hub-items.md`, then `hub-qml.md` for any QML and the kind's own file).

## 3. Write

- Build on the template's shape. Use the shell's parts by importing them; read a family's surface to learn how it is
  built, never copy it.
- Every visible string through `Translation.tr("…")`, every key in `translations/en_US.json`, and the other languages
  you ship whole.
- `hub.json`: honest `permissions`, every host in `hosts`, `summary` that says what it does.
- `README.md` and `docs/<id>/` (a `docs.json` and a `<NAME>.md` page).

## 4. Check, until it prints `nothing to fix`

```sh
inir hub check
```

Fix each error the way its message says. Run it after every round of edits. An error you think is wrong: read the
rule in `CONTRIBUTING.md › What inir hub check holds you to` and in `AGENTS.md`; if it still blocks something that is
right, stop and tell the person to raise it in an issue. Never dodge it.

## 5. Try it running

```sh
inir hub build && INIR_HUB_SOURCES=$PWD/dist inir hub install <id>
inir restart        # components only: their panel loads at start
```

Go through, in each family it is worn with: reach it from the Hub page with the mouse as someone who never opened a
terminal, open and close it there (IPC and keybind last, as extras), empty, loading, failed (no network,
a missing program), full, long text, light and dark, small and large scale. Then:

```sh
inir logs --issues  # nothing new from your item
INIR_HUB_SOURCES=$PWD/dist inir hub remove <id>
```

If you can't see the screen, give the person this list and wait for what they saw. Report only what was seen.

## 6. Preview

A real screenshot, nothing private: `inir hub preview <folder> --shot <screenshot>` (a widget:
`inir background widgetSnapshot custom.<id> shot.png` first, then `--wallpaper <image> --shot shot.png`).

## 7. Send

```sh
inir hub submit <kind-folder>/<id>      # --dry-run first shows the steps
```

It checks once more, commits on its own branch, pushes to the person's fork and opens the pull request. Fill
"Tried on" with the families, looks and states actually gone through.

## After review

Once Check passes, a reviewer reads the item and either merges it or leaves one comment listing each fix with its
file and line. Make every fix it lists on the same branch, `inir hub check`, push: Check and the reviewer run again,
and it merges when nothing is left. Never answer the reviewer inside the item's files. A later feature is a new branch, a new pull request
and a raised `version` in `hub.json` and the native file.
