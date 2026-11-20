---
name: hub-item
description: Make or change an iNiR Hub item (widget, component, Design, colour theme, iRiS theme or web app) from the first idea to a pull request that passes CI. Use when asked to create, port, fix, update or send one, or when `inir hub check` fails.
---

# Making an iNiR Hub item

Read `AGENTS.md` first if you have not this session. The steps below are in order; none is skipped.

## 1. Settle what it is

- Ask the person, in one message, only what you can't decide: what it shows or does, which families it is for (Material,
  iRiS, Waffle, all), and, for a feature that fetches anything, the source.
- Pick the kind (`CONTRIBUTING.md › What to make`). A change to a family itself is an issue: say so and stop.
- Before the first file, write in one line per family where a person finds it and opens it with the mouse (Material's
  desktop and sidebars, the iRiS Island, Waffle's Widgets panel, the app launcher for a component). If the kind gives it
  no such place, the kind is wrong: what people use is a widget. Never change a family or the base to fit the item.
- Check the source: an official API, or a site whose terms allow the use, with no key you would have to ship. If there is
  none, say so and stop.
- Write the plan as a short list of files, each with its one job, each under the 600-line limit (`hub-items.md › Size`).

## 2. Start

```sh
git switch -c <id> origin/main
inir hub new <kind> <id> --author <github-handle>
```

`<kind>` is `widget`, `component`, `design`, `theme`, `iris-theme` or `webapp`.

Read the template it wrote, the example of the kind (`widgets/countdown`, `components/fastfetch`, `designs/airisu`,
`themes/tidepool`, `iris-themes/moss-garden`, `webapps/excalidraw`), and the rules for what you will touch:
`.claude/rules/hub-items.md` and `hub-qml.md` always, then the rule for the kind.

## 3. Write

- Build on the template's shape. Import the shell's parts (`hub-qml.md › Imports`). Read a family's surface to learn how
  it is built; never copy it.
- Every visible string goes through `Translation.tr("…")`, every key is in `translations/en_US.json`, and every language
  you ship is complete.
- `hub.json`: honest `permissions`, every host in `hosts`, and a `summary` that says what it does.
- `README.md` and `docs/<id>/` (`docs.json` and a `<NAME>.md` page), as `hub-items.md › Files` describes.

## 4. Check, until it prints `nothing to fix`

```sh
inir hub check
```

Fix each error the way its message says, and run it after every round of edits. For an error you think is wrong, read the
rule in `CONTRIBUTING.md › What inir hub check holds you to` and in `AGENTS.md`. If it still blocks something that is
right, stop and tell the person to raise it in an issue. Never dodge it.

## 5. Try it running

```sh
inir hub build && INIR_HUB_SOURCES=$PWD/dist inir hub install <id>
inir restart        # components only: their panel loads at start
```

Go through it in each family it is worn with: reach it from the Hub page with the mouse, as someone who never opened a
terminal; open and close it there (IPC and keybind last, as extras); then each state the item has (empty, loading,
failed: no network, a missing program), long text, light and dark, small and large scale. Then:

```sh
inir logs --issues  # nothing new from your item
INIR_HUB_SOURCES=$PWD/dist inir hub remove <id>
```

If you can't see the screen, give the person this list and wait for what they saw. Report only what was seen.

## 6. Preview

A real screenshot with nothing private in it: `inir hub preview <folder> --shot <screenshot>`. For a widget, follow
`hub-widgets.md › Preview`.

## 7. Send

```sh
inir hub submit <kind-folder>/<id>      # --dry-run shows the steps without running them
```

It checks once more, commits on its own branch, pushes to the person's fork and opens the pull request. Fill "Tried on"
with the families, looks and states actually gone through.

## After review

Once `inir hub check` passes, a reviewer either merges the item or leaves one comment listing each fix with its file and
line. Make every listed fix on the same branch, run `inir hub check` and push: the check and the reviewer run again, and
it merges when nothing is left. Do not reply to the reviewer inside the item's files. A later feature is a new branch and
a new pull request, with `version` and its `changes` line raised in `hub.json` (and the native file's `version`).
