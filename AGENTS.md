# Working in the iNiR Hub (for AI agents)

You are working in the hub of [iNiR](https://github.com/snowarch/iNiR), a desktop shell for the Niri compositor. Every
item here (widget, component, colour theme, iRiS theme, web app) is installed by people with `inir hub install` or
reaches them through `inir update`. Whatever you write runs inside their desktop shell: an item that fails to load,
loops, blocks or reaches into the rest of the shell does it on every desktop that installed it. Read this whole
file before writing anything. Claude Code loads it through `CLAUDE.md`; any other agent reads it from here.

## How you work

1. **Pick the kind** from the table in `CONTRIBUTING.md › What to make`. A fix to Material (`ii`), iRiS or Waffle is
   an issue, not a pull request; what people use is a widget (a face in each family: Material's shelf, the iRiS
   Island, Waffle's panel); a component is only work with no face, and never the way a person opens anything. Before the first file, write where a person
   finds and opens it with the mouse in each family; if the kind gives it no such place, the kind is wrong.
2. **Start from the template:** `inir hub new <kind> <id> --author <github-handle>`. The id is the folder name.
3. **Read before writing:** the template it gave you, the example of the kind (`widgets/countdown`,
   `components/fastfetch`, `designs/airisu`, `themes/tidepool`, `iris-themes/moss-garden`, `webapps/excalidraw`), and the
   rules for the files you touch in `.claude/rules/` (`hub-items.md` always; then `hub-qml.md`, `hub-components.md`,
   `hub-designs.md`, `hub-widgets.md`, `hub-themes.md`, `hub-webapps.md`, `hub-scripts.md` as they apply). They are plain Markdown:
   read them even if your tool does not load them by itself.
4. **Loop on the check** until it prints `nothing to fix`: `inir hub check`. CI runs the same check on the pull
   request, from inir-cli's main branch; if yours passes and CI does not, take the newest
   (`go install github.com/snowarch/inir-cli/cmd/inir@main`). Each error says what to do instead: do that. Never
   reshape code only to slip past a rule (a colour hidden in a variable, an import through another file); the rule
   is what a reviewer reads for, and the pull request comes back.
5. **Try it running**, the way people get it: `inir hub build && INIR_HUB_SOURCES=$PWD/dist inir hub install <id>`
   (a component: `inir restart` once), then find and open it from the Hub page with the mouse, as someone who never
   opened a terminal, in every family; then every state (empty, loading, failed, full, light and dark, small and
   large scale) in every family it is worn with. `inir logs --issues` shows nothing new from it. Then
   `INIR_HUB_SOURCES=$PWD/dist inir hub remove <id>`. If you cannot see the screen, tell the person exactly what to
   open and look at; never claim it works from the check alone.
6. **Send it:** `inir hub submit <kind-folder>/<id>` (with `gh` logged in), or a branch with only the item's folder
   and `docs/<id>/`.

The full step-by-step is the skill in `.claude/skills/hub-item/SKILL.md`.

## What an item never does

Each of these is held by `inir hub check` and CI, or by review where no machine can see it:

- **Touch anything but its own folder** and its page in `docs/<id>/`. Never `families/`, another item, `schema/`,
  `tools/`, `templates/`, `.github/`, `dist/` or these instruction files. One item per pull request.
- **Copy a file of the hub** (a family's surface, another item's code) and edit the copy. The shell ends up with two
  of one thing that drift apart. Import what a family offers items; if what you need is not offered, stop and tell
  the person to ask for it in an issue.
- **Import a family's inside.** Items import the base (`qs`, `qs.services`, `qs.modules.common` and its `widgets`,
  `functions`) and only what a family offers: `qs.modules.iris.style`, `qs.modules.iris.components`,
  `qs.modules.iris.frame`, `qs.modules.waffle.looks`, `qs.modules.ii.kit` (a Design's Island face also
  `qs.modules.iris.bar.island`). Everything else (`iris.state`,
  `iris.pieces`, `iris.settings`, `iris.field`, a family's bar or panels) changes with every release of that family,
  and the item then stops loading for everyone.
- **Write the person's settings or a family's state.** No `Config.setNestedValue(…)`, no `Config.options.x = …`, no
  calls that change a family's own data (its follows, its lists, its open panels). A widget's options are its
  `widget.json` `configKeys`; a component keeps its own in `Directories.pluginFile("<id>")`.
- **Answer for someone else's IPC.** Every `IpcHandler` target starts with the item's id.
- **Start the shell's binary.** Never `qs`, `quickshell` or `qs -c inir ipc call …`: on iNiR the shell runs on its
  own runtime, not a `qs` on the PATH. Reach the shell, or another item, with `["inir", "<target>", "<function>"]`.
- **Grow past what a reviewer can read.** At most 600 lines in one file (split by job: state, each page, each part)
  and, from outside, at most 2500 lines of code in one pull request (translations and docs not counted). A big
  feature lands as the smallest version that works, then each addition on its own pull request with a raised version.
- **Install, elevate or download code.** No `pip`, `npm`, package managers or `sudo` from the item; no `curl … | sh`,
  no `eval`, no `Qt.createQmlObject`, no QML from the internet, no `atob` or `base64 -d` on hidden content. Python
  helpers use the standard library only.
- **Run while nobody looks.** No timer, process, fetch or animation while its window is closed or its face hidden.
- **Carry secrets or someone's content.** No API keys, tokens or client secrets in the repo (the person enters their
  own, kept in the plugin's file); nothing private in a preview. Sources are official APIs or sites whose terms allow
  the use: no scraping of sites that host films, shows, music or games without the rights to them, no DRM
  circumvention. The hub is public; a takedown removes it for everyone.
- **Declare less than it does.** `permissions` in `hub.json` match the code (`process`, `network`, `files`,
  `inject`), and `hosts` lists every host it talks to.

## When you are stuck

If a rule can't be met without breaking another (the part you need is a family's inside, the feature can't fit in
2500 lines, the source has no API that allows the use), stop and tell the person why, with the rule's name. Never
work around it. The way forward is an issue on this repository, a smaller first version, or another source.

## Maintainers

Material, iRiS and Waffle under `families/` change only from the hub's maintainers (CI knows who they are):
`CONTRIBUTING.md › Changing a family` holds them to more. Everyone else builds a component worn with a family.
