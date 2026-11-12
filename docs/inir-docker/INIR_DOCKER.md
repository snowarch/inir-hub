# iNiR Docker

Docker containers on your iNiR desktop, with three layouts for monitoring and
controlling them.

The Docker model, parser and command helpers are adapted from devgtv's Docker
widget (MIT).

## What it does

- **Monitoring summary**: running/total containers, aggregate CPU, aggregate
  memory, a CPU history sparkline and a memory bar.
- **Per-container monitoring**: state, CPU bar/percentage and memory bar/usage.
- **Three layouts**: Dashboard, Compact and Tiles.
- Click a container to select it.
- Start, stop or restart it with a confirmation step.
- Open the last 200 log lines, or follow logs, in your terminal.
- Filter by name, image, state or Compose project.
- A compact line on the iRiS Island shows `running/total`.

Resource-limit sliders are not in this version. The collector and Docker
command helpers already support them, so they can be added next.

## Layouts

| Layout | What it shows |
|---|---|
| **Dashboard** | Stat strip with running/CPU/memory, CPU sparkline, and rows with per-container bars |
| **Compact** | A dense one-line summary and tighter rows, for small widgets |
| **Tiles** | Two-column cards with a CPU ring, memory bar and state per container |

Set **Layout** in the widget options.

## Install

From a Hub source:

```bash
inir hub install inir-docker
```

Or from a checkout of this folder:

```bash
mkdir -p ~/.config/inir/widgets
cp -r inir-docker ~/.config/inir/widgets/inir-docker
```

Then open **Settings → Desktop Widgets**, enable **iNiR Docker**, or add it from
edit mode. The widget id is `inir-docker`.

To reload after editing:

```bash
inir restart
```

## Configuration

| Key | Default | Meaning |
|---|---|---|
| `layout` | `dashboard` | `dashboard`, `compact` or `tiles` |
| `refreshSeconds` | `3` | How often the card reads Docker while visible |
| `maxContainers` | `6` | Rows/tiles shown before the `+N more` line |
| `showStopped` | `true` | Include exited/created containers |
| `showSummary` | `true` | Show the running/CPU/memory summary strip |
| `showSparkline` | `true` | Show the CPU history line |
| `filter` | empty | Literal text matched against name, image, state and Compose labels |

## Sidebar support

The current iNiR family sidebars do not expose a plugin-widget slot. The
Material left sidebar loads a fixed widget list, the Material right sidebar
loads a fixed tab list, and the iRiS sidebars use a fixed section catalogue.
Adding a Hub widget to those sidebars needs a family-side change, not a change
to this widget.

The drawing is split into `DockerBackend.qml`, `DockerView.qml` and the layout
components so a family sidebar host can reuse it once such a slot exists.

## Requirements

- Docker CLI and a reachable Docker daemon.
- Access to the daemon, usually by being in the `docker` group or using rootless
  Docker. Membership in the `docker` group is effectively root-level access.
- `xdg-terminal-exec` for the log buttons. iNiR ships it on supported desktops;
  if it is missing, the lifecycle/status parts still work.

## Permissions

`process` — the widget runs the Docker CLI (`docker ps`, `inspect`, `stats`,
`start`, `stop`, `restart`, `logs`) and opens a terminal for logs.

It does not request `network`, `files` or `inject`. A remote Docker context can
still make the Docker CLI use the network; that is Docker's own configuration.

## Official Hub compatibility

The item is shaped like an official iNiR Hub widget:

- `widget.json` / `hub.json` follow the Hub schema.
- `translations/en_US.json` covers every `Translation.tr(…)` string.
- The code imports only the base and the widget SDK, not a family's internals.
- It uses no desktop-specific files, services, paths or launcher commands.

The only optional external helper is `xdg-terminal-exec` for logs.

## Credits

- devgtv — original Docker model, parser and command helpers. MIT notice kept
  in [LICENSE](LICENSE).
- iNiR's widget SDK and Hub conventions.

## License

MIT. The original copyright notice is preserved in [LICENSE](LICENSE).
