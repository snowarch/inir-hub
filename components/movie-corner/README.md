# Movie Corner

Find any film or series on Cinemeta, browse it by popularity, rating, year or genre, follow it, and watch it in your
language in mpv. It is a corner of iRiS: Settings' body and layout, over the desktop or in a window.

- Open it: `qs -c inir ipc call movie-corner toggle` (bind it in niri's config, e.g.
  `Mod+M { spawn "qs" "-c" "inir" "ipc" "call" "movie-corner" "toggle"; }`), or find it in the app launcher (Settings › The Corner ›
  **In the app launcher**, on by default) and pin it to the Dock.
- Worn with: iRiS. Needs `python3` and `mpv`.
- Its options and the titles you follow live in `~/.config/inir/plugins/movie-corner.json`.
- Needs an iNiR base with component panels (the 2.34 update).

| IPC (`movie-corner …`) | What it does |
| --- | --- |
| `toggle`, `open`, `close` | Open or close it |
| `search <text>` | Open it searching |
| `go <place>` | home, continue, following, movies, series, top, years, genres, settings, `genre:<name>`, `title:<movie\|series>:<IMDb id>` |
| `stop` | Stop what is playing |

## Watching

| Audio | Sites |
| --- | --- |
| Original, subtitles in nearly any language (you can turn them off) | vidsrc.buzz |
| Original, Spanish subtitles in the picture | MagisTV24 |
| Latin American Spanish, Spain Spanish | MagisTV24 |

With the original audio, a site that lacks your subtitle language gets it from OpenSubtitles through Stremio's open
add-on (no account, no key): German, French, Italian, Portuguese and the rest of the list, when someone has made them.

Watch asks every site of the language at once and lists what plays, with its picture and subtitles; the pin makes one
the default. Films and episodes resume where you stopped. Sites change without notice: *Check the sources* tries them.

## Privacy

Only HTTPS; nothing a site sends is run or decoded. mpv gets the stream after `--`, with only the Corner's own options.
