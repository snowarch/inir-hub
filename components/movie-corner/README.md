# Movie Corner

Find any film or series on Cinemeta, browse it by popularity, rating, year or genre, follow it, see where it streams,
and watch it from your own sources in mpv. It is a corner of iRiS: Settings' body and layout, over the desktop or in a window.

- Open it: `inir movie-corner toggle` (bind it in niri's config, e.g.
  `Mod+M { spawn "inir" "movie-corner" "toggle"; }`), or find it in the app launcher (Settings › The Corner ›
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

The Corner comes with **no video sources**. With your free TMDB key (Settings › Sources), a title's page lists where
it streams officially in your country (data by JustWatch) and opens TMDB's page with the links. Watch plays from
the sources you add yourself (see below). It asks every source of the language at once and lists what plays, with
its picture and subtitles; the pin makes one the default. Films and episodes resume where you stopped.

With the original audio, a source that lacks your subtitle language gets it from OpenSubtitles through Stremio's open
add-on (no account, no key), when someone has made them.

## Sources

Settings › Sources lists what you added. There are two kinds, and both stay on your computer:

- **A Stremio add-on.** Paste its address (`https://…/manifest.json`) and press Add. The Corner reads the manifest and
  then asks it for a film's or an episode's streams by IMDb id, as Stremio does. It reads JSON only: torrents and
  links meant for a browser are left out. An add-on plays in the audio language set when you added it.
- **A source file.** A Python file in `~/.local/share/inir/movie-corner/sources/` (*Open folder* creates it) that
  sets `SOURCES`. The Corner loads every file there; one that fails is listed with its error and the rest still play.

```python
from inir_movie.sdk import Site, Source, net


class MyServer(Site):
    id, name = "myserver", "My server"
    audios = ("original",)  # "original" is the film's own track; or "es-419", "es-ES"

    def sources(self, item, audio, subs):
        # item: kind ("movie" or "series"), title, year, imdb, tmdb, season, episode
        found = net.jsonof("https://media.example.com/api/by-imdb/" + item["imdb"])
        return [Source(self.id, "Direct", audio, found["m3u8"], "https://media.example.com/")]


SOURCES = [MyServer()]
```

A page address goes through `resolve()` from the same `sdk`: it reads a page that names its video plainly (an m3u8 or
mp4, a `<video>` source, one frame deep), and a file can teach it more with `HOSTS = [(text in the address,
reader(url, referer) -> Stream or None)]` and `PAGE_FILTERS = [page -> text]`. Files named `_something.py` are
helpers the others import. `python3 ~/.config/quickshell/inir/modules/movie-corner/scripts/inir-movie.py doctor`
tries every source on one film, and `… list` shows what loaded.

Add only sources you have the right to watch from. Nothing a source sends is run, and its addresses are its own: the
Corner's `hosts` list only names the services it uses itself.

## Privacy

Only HTTPS; nothing a source sends is run or decoded. The TMDB key lives in your system keyring. mpv gets the stream after `--`, with only the Corner's own options.
