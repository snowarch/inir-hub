# Anime Corner

Find any show on AniList, browse it by season, genre, popularity or your own list, and watch it in your language in
mpv. It is a corner of iRiS: Settings' body and layout, over the desktop or in a window.

- Open it: `inir anime-corner toggle` (bind it to a key in niri's config, e.g. `Mod+A { spawn "inir" "anime-corner" "toggle"; }`).
  An `inir` that does not know plugin targets yet takes `qs -c inir ipc call anime-corner toggle`.
- Worn with: iRiS. Needs `python3` and `mpv`; `ani-skip` skips openings; `ani-cli` adds English sources.
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

Watch opens a sheet over the Corner: finding the show, finding sources, your pick, opening the player. A failure stays
on the sheet with what to try next.

| Audio | Sites |
| --- | --- |
| Japanese + Spanish subs | AnimeAV1, Henaojara, JKAnime |
| Japanese + German / Italian / Portuguese / French / Arabic subs | AniWorld, AnimeWorld, Animes Digital, Anime-Sama, Anime4up |
| Japanese + English subs, English dub | ani-cli, AniWorld (subs), WatchAnimeWorld (dub) |
| Latin American Spanish | AnimeAV1, Henaojara, JKAnime |
| German, Italian, Brazilian Portuguese, French, Russian | AniWorld, AnimeWorld, Animes Digital, Anime-Sama, AniLiberty |
| Hindi, Tamil, Telugu | WatchAnimeWorld |

## Settings (the Corner's own place)

- **Audio, Subtitles, Source**: *Ask* lists every site that has the episode with its quality and subtitles; the pin
  makes one the default. *Check the sources* tries them all. Sites change without notice: when one breaks, the others
  still play.
- **Subtitles online**: OpenSubtitles and SubDL, each with your own free API key.
- **Accounts**: connect AniList or MyAnimeList with your own app's client ID (the row says how), or name a public list.
  A finished episode is marked on your list.
- **New episode alerts** (off until you turn them on) and **Open in a window**.
- Quality, the subtitle look and skipping intros are iRiS's own Anime settings, shared with its Continue bubble.

## Privacy

Keys and tokens live in your system keyring, never in a settings file or on a command line. Only HTTPS; nothing a site
sends is run; downloaded subtitles are size-checked and kept in the run's own folder.
