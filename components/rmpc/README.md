# Rmpc

A theme for the [rmpc](https://github.com/mierak/rmpc) music player that follows your iNiR colours. Every time iNiR applies a palette (a new wallpaper, a preset, light or dark), the theme is written again, so rmpc always wears the colours of your desktop.

It brings a layout made for small screens (tested at 130x32 characters):

```
+-------------+--------------------------+
| album art   | progress bar             |
+-------------+--------------------------+
| title       | tabs                     |
| artist      | queue / directories ...  |
| time        |                          |
+-------------+                          |
| lyrics      +--------------------------+
|             | cava                     |
+-------------+--------------------------+
```

This component only writes its own theme file. It never touches your MPD, your rmpc config or your services: the one-time setup below is yours to do, and each step is optional except the first two.

## What it needs

- iNiR and [rmpc](https://github.com/mierak/rmpc) 0.11 or newer
- `jq` (the theme is built from iNiR's palette)
- `cava` for the visualiser, and an MPD that can feed it (step 3)

## Install

```
inir hub install rmpc
```

It writes `~/.config/inir/plugins/rmpc/theme.ron` on the next theme change. To get it now, change the wallpaper, or run:

```
bash ~/.config/quickshell/inir/scripts/colors/apply-targets.sh rmpc
```

## Set it up (once)

### 1. Link the theme into rmpc

```
mkdir -p ~/.config/rmpc/themes
ln -sfn ~/.config/inir/plugins/rmpc/theme.ron ~/.config/rmpc/themes/inir.ron
```

In `~/.config/rmpc/config.ron`:

```ron
theme: "inir",
```

### 2. Free the panes the layout uses

rmpc refuses a pane that is in both the layout and a tab. The layout holds `AlbumArt` and `Lyrics`, so in `config.ron` replace the default `Queue` tab with this one (leave the other tabs as they are):

```ron
(
    name: "Queue",
    pane: Split(
        direction: Vertical,
        panes: [
            (size: "3", borders: "ALL", border_symbols: Inherited(parent: Rounded, bottom_left: "├", bottom_right: "┤",), pane: Pane(QueueHeader())),
            (size: "100%", borders: "LEFT | RIGHT | BOTTOM", border_symbols: Rounded, pane: Pane(Queue)),
        ],
    ),
),
```

### 3. The cava visualiser

rmpc runs its own cava, fed by an MPD output of type `fifo`. This does not touch iNiR's cava config. Add the output to your `mpd.conf` (keep your existing outputs), replacing `1000` with your user id (`id -u`):

```
audio_output {
    type    "fifo"
    name    "rmpc-cava"
    path    "/run/user/1000/mpd.fifo"
    format  "44100:16:2"
}
```

Restart MPD, then tell rmpc where to read, in `config.ron`:

```ron
cava: (
    framerate: 60,
    input: (method: Fifo, source: "/run/user/1000/mpd.fifo", sample_rate: 44100, channels: 2),
),
```

Without this, the cava pane stays empty; the rest of the layout works.

### 4. Synced lyrics (optional)

The lyrics pane shows `.lrc` files. Point rmpc at a folder in `config.ron`:

```ron
lyrics_dir: Some("/home/you/.local/share/rmpc/lyrics"),
```

The file for `Artist/Album/song.flac` is `<lyrics_dir>/Artist/Album/song.lrc`. rmpc's guide on [`on_song_change`](https://mierak.github.io/rmpc/next/guides/on_song_change) shows how to download them automatically while you listen.

### 5. Show what MPD plays in iNiR's media widgets (optional)

MPD does not speak MPRIS by itself. Install a bridge such as `mpd-mpris` and run it with your session (the package ships a systemd user unit; follow your distro's notes for it).

iNiR's media widgets and the `inir mpris` actions then see MPD like any other player.

### 6. Play from YouTube with yt-dlp (optional)

rmpc can add songs from YouTube:

```
rmpc addyt <url>
rmpc searchyt <search terms>
```

It needs `yt-dlp` and `ffmpeg` on your PATH (and `python3`), and a folder to keep what it downloads, in `config.ron`:

```ron
cache_dir: Some("/home/you/.cache/rmpc"),
```

Run `rmpc debuginfo` and read the "Youtube playback" section: it lists what is installed and what is missing (for example `python-mutagen`). Only download what you have the right to.

### 7. A keybind to pause (optional)

In your Niri config (`inir` itself speaks MPRIS, but rmpc's own command works with plain MPD):

```kdl
Mod+Shift+P { spawn "rmpc" "togglepause"; }
```

## Layout

The default layout is made for about 130x32 characters. For smaller terminals (about 80x24 up to 110x28), turn on **Compact layout** on rmpc's page in the Hub: the cover and song info go in a left column, and the cava, tabs, lyrics, queue and progress bar share the rest. The choice is saved in `~/.config/inir/plugins/rmpc.json`. With seven tabs the tab bar can be cut in the compact layout; switch tabs with `1` to `7` or `Tab`.

## Cava style

Pick how the visualiser moves and looks on rmpc's page in the Hub. The three groups combine freely:

- **Shape:** `spectrum` (bars from the bottom, the default), `mirror` (bars from the centre), `top` (bars hanging from the top), `dense` (no gap between bars), `chunky` (wider bars) and `densemirror` (no gaps, from the centre).
- **Colour:** `gradient` (the default), `solid` (one colour) and `layers` (a colour band per row).
- **Symbols:** `blocks` (the default), `braille` and `shades`. Braille and shades need a font that has those characters, and with `top` and the mirrored shapes rmpc warns that non-default symbols can look wrong.

Every colour comes from your palette and follows it live. Your choices are saved in `~/.config/inir/plugins/rmpc.json` and stay if you remove the component. The cava pane needs step 3 above.

## Progress bar and Directories

Two more choices on rmpc's page in the Hub:

- **Progress bar:** `plain` (the default), `line`, `dots` and `rounded`. `rounded` uses round caps that need a Nerd Font.
- **Directories:** `columns` (the default) or `tree`. rmpc has no real folder tree, so `tree` gives the closest look: folder and branch symbols (`├─`) on the entries and a wider preview column that lists what is inside the selected folder. It needs a Nerd Font for the icons.

## Song notifications (optional)

The page in the Hub has a **Song notifications** switch. It only saves your preference, `"notify": "on"` or `"off"`, in `~/.config/inir/plugins/rmpc.json`; it does not show anything by itself. To get a notification on every song change, point rmpc's `on_song_change` at a small script of yours that reads that preference:

```bash
#!/usr/bin/env bash
# rmpc gives the hook ARTIST, ALBUM and TITLE
grep -qs '"notify"[[:space:]]*:[[:space:]]*"off"' "${XDG_CONFIG_HOME:-$HOME/.config}/inir/plugins/rmpc.json" && exit 0
notify-send -a rmpc "$TITLE" "$ARTIST"
```

In `config.ron`:

```ron
on_song_change: ["/home/you/.config/rmpc/on-song-change"],
```

Notifications arrive through the shell's service, so its Do Not Disturb mode silences them too. They are only sent while rmpc is open, because it is rmpc that runs the hook.

## What it does to your system

- Writes `~/.config/inir/plugins/rmpc/theme.ron` and, when you pick a cava style, `~/.config/inir/plugins/rmpc.json`; it tells a running rmpc to reload the theme (`rmpc remote set theme`).
- Needs the `process` permission (it runs a small script when iNiR applies a palette) and `files` (it writes that one file).
- Does not use the network.

## Remove

```
inir hub remove rmpc
rm ~/.config/rmpc/themes/inir.ron
```

and set `theme: None,` in `config.ron`. Your MPD and rmpc settings stay as you left them.
