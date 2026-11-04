# Anime Corner

Find any show on AniList, browse it by season, genre, popularity or your own list, and watch it in your language in
mpv. It is a corner of iRiS: Settings' body and layout, over the desktop or in a window.

- Open it: `inir anime-corner toggle` (bind it to a key in niri's config, e.g. `Mod+A { spawn "inir" "anime-corner" "toggle"; }`).
- Or from the app launcher: Settings › The Corner › *In the app launcher* (on by default) adds an Anime Corner entry.
- With the Movie Corner installed, the sidebar has a row that opens it.
- Worn with: iRiS. Needs `python3` and `mpv`; `ani-skip` skips openings; `ani-cli`, when installed, plays English.
- Its options live in `~/.config/inir/plugins/anime-corner.json`; keys and tokens in your system keyring.
- Needs an iNiR base with component panels (the 2.34 update).

| IPC (`inir anime-corner …`) | What it does |
| --- | --- |
| `toggle`, `open`, `close` | Open or close it |
| `search <text>` | Open it searching |
| `go <place>` | home, continue, mylist, following, popular, trending, top, season, calendar, genres, settings, `genre:<name>`, `anime:<AniList id>` |
| `watch <title> <episode>` | Watch a show; an empty episode asks which |
| `choose <value>` | Answer the question a run is asking |

## Watching

The Corner comes with **no video sources**. A show's page links to where it streams officially (Crunchyroll,
Netflix, HIDIVE… as AniList lists them), and Watch plays from the sources you add yourself (see below), or from
`ani-cli` when it is installed and the audio is English. Watch opens a sheet over the Corner: finding the show,
finding sources, your pick, opening the player. A failure stays on the sheet with what to try next.

## Sources

Settings › Sources lists what you added. There are two kinds, and both stay on your computer:

- **A Stremio add-on.** Paste its address (`https://…/manifest.json`) and press Add. The Corner reads the manifest and
  then asks it for an episode's streams by Kitsu id, the id Stremio's anime add-ons use. It reads JSON only: torrents
  and links meant for a browser are left out. An add-on plays in the Watch language set when you added it.
- **A source file.** A Python file in `~/.local/share/inir/anime-corner/sources/` (*Open folder* creates it) that
  sets `SOURCES`. The Corner loads every file there; one that fails is listed with its error and the rest still play.

A source file builds on the Corner's own pieces:

```python
from inir_anime.sdk import Provider, Show, Stream, net


class MyServer(Provider):
    id, name, site = "myserver", "My server", "https://media.example.com"
    offers = (("ja", "es"),)  # (audio, subtitles) pairs it plays: Japanese with Spanish subtitles

    def search(self, query, audio, subs, season):
        found = net.jsonof(self.site + "/api/search?q=" + query)
        return [Show(self, item["id"], item["title"], audio, subs, season) for item in found]

    def episodes(self, show):
        return [str(n) for n in net.jsonof(self.site + "/api/shows/" + show.key)["episodes"]]

    def servers(self, show, episode):
        url = "%s/api/shows/%s/%s.m3u8" % (self.site, show.key, episode)
        return [("Direct", Stream(url, self.site + "/"))]


SOURCES = [MyServer()]
```

`servers` returns a ready `Stream` or a page address. The Corner reads a page that names its video plainly (an m3u8
or mp4, a `<video>` source, one frame deep). A file can teach it more with `HOSTS = [(text in the address,
reader(url, referer) -> Stream or None)]` and `PAGE_FILTERS = [page -> text]`. Files named `_something.py` are
helpers the others import. `python3 ~/.config/quickshell/inir/modules/anime-corner/scripts/inir-anime.py doctor`
tries every source on one show, and `… sources` shows what loaded.

Add only sources you have the right to watch from. Nothing a source sends is run, and its addresses are its own: the
Corner's `hosts` list only names the services it uses itself.

## Settings (the Corner's own place)

- **Audio, Subtitles, Source**: *Ask* lists every source that has the episode with its quality and subtitles; the pin
  makes one the default.
- **Sources**: your add-ons and source files, a field to add an add-on and *Check the sources*, which tries them all.
- **Subtitles online**: OpenSubtitles and SubDL, each with your own free API key.
- **Accounts**: connect AniList or MyAnimeList with your own app's client ID (the row says how), or name a public list.
  A finished episode is marked on your list.
- **New episode alerts** (off until you turn them on) and **Open in a window**.
- Quality, the subtitle look and skipping intros are iRiS's own Anime settings, shared with its Continue bubble.

## Privacy

Keys and tokens live in your system keyring, never in a settings file or on a command line. Only HTTPS; nothing a source
sends is run; downloaded subtitles are size-checked and kept in the run's own folder.
