# Display Projection

A small card like the one a projector key opens: **PC screen only**, **Duplicate**, **Extend** or **Second screen
only**. It finds your displays by itself, marks the mode in use, and switches with one click or one key. Worn with
every family, on niri.

## Open it

- App launcher: **Display Projection**.
- Niri keybind: `Mod+P { spawn "inir" "display-projection" "toggle"; }`
- Close it with its × button, Escape, or a click beside the card.

## The four modes

| Mode | What happens |
|---|---|
| **PC screen only** | The second screen is turned off; this one stays on |
| **Duplicate** | Both screens on, and [wl-mirror](https://github.com/Ferdi265/wl-mirror) shows this screen fullscreen on the second |
| **Extend** | Both screens on, each with its own workspaces: niri's usual way |
| **Second screen only** | The second screen stays on and this one is turned off |

The main screen is the built-in panel (`eDP`, `LVDS` or `DSI`), or the first one by name when there is none.
With several screens plugged in, chips under the modes choose which one is the second. With no second screen, only
**PC screen only** can be picked and the card says so.

Switching runs `niri msg output <name> on` or `off`. A screen turned off stays off until you pick another mode or
niri restarts; your niri config is never changed. Leaving Duplicate stops the wl-mirror it started.

## Keys

| Key | Does |
|---|---|
| Arrows, Tab | Move between the modes |
| Enter, Space | Pick the mode shown |
| 1 to 4 | Pick a mode directly |
| I | Show or hide About |
| Escape | Close |

## IPC

```sh
inir display-projection toggle       # open or close the card
inir display-projection open
inir display-projection close
inir display-projection mode extend  # pcOnly, duplicate, extend or secondOnly, without opening the card
```

## What it needs

- **niri**: on another compositor the card opens and says it needs niri.
- **wl-mirror** for Duplicate (`pacman -S wl-mirror`, or your distribution's package). Without it the card says
  Duplicate won't work; the other modes still do.

## Permissions

`process`: it runs `niri msg` to read and switch the displays, `pgrep` to find a running wl-mirror, `kill` to stop
it, and `wl-mirror` itself. It reads the displays only while the card is open, every two seconds; closed, nothing
runs.

## Credits

Duplicate is done by [wl-mirror](https://github.com/Ferdi265/wl-mirror), by Ferdinand Bachmann (Ferdi265),
GPL-3.0-or-later. Display Projection only starts and stops it; it isn't bundled. Display Projection is
GPL-3.0-or-later as well (`LICENSE`), and is the QML version of
[wl-mirror-ui](https://github.com/kaz-py/wl-mirror-ui).
