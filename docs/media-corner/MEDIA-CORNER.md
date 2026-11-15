# Media Corner

A Place, worn with iRiS, to find any anime, film or series, see where it streams officially, and watch it with mpv
from sources you add. Anime comes from [AniList](https://anilist.co), films and series from Cinemeta (Stremio's open
catalogue, by IMDb id). It comes in two styles, **Normal** and **Prism**, with the same features in both.

## Open it

- From the app launcher: **Media Corner**.
- Or bind it in Niri: `Mod+Shift+M { spawn "inir" "media-corner" "toggle"; }`.
- The window key at the top right switches between the desktop overlay and a window of its own.

## IPC

| Call | Does |
|---|---|
| `inir media-corner toggle` / `open` / `close` | Shows or hides it |
| `inir media-corner search "<text>"` | Searches anime, films and series at once |
| `inir media-corner go <place>` | Opens a place: `home`, `anime:popular\|airing\|trending\|top\|season\|genres`, `movie:movies\|series\|top\|years\|genres`, `history`, `schedule`, `sources`, `anime:<AniList id>`, `title:<movie\|series>:<IMDb id>` |
| `inir media-corner pause` / `resume` / `togglePause` | Pauses or resumes what mpv plays |
| `inir media-corner seek <seconds>` | Jumps to a position |
| `inir media-corner stop` | Stops playback |

## Layout

- **Left**: the places. Home, then **Anime** and **Films and series** as groups that open while one of theirs is
  shown, then **Library** (Sources, Upcoming episodes, Watch history). The search is at the top (Ctrl+F).
- **Middle**: the page, under ‹ › (back and forward) and the window keys.
- **Right** (when the Corner is wide enough): a greeting, **Yours** (Want to watch and Watching, numbered, with a
  filter and a sort) and what mpv plays, with its scrubber and keys. Narrower, Yours moves under the places and what
  plays rides at the foot of the page.

## Pages

- **Home**: one trending show up front with Watch and Details; a deck with what you watched last and what plays (or
  a popular film); the places of every day; shelves of anime airing now, trending and in season, and popular films and
  series. Shelves show their shape while they load and say so, with Retry, when they fail.
- **Anime**: popular, airing now, trending, top rated, this season (‹ › walk the seasons), genres.
- **Films and series**: films, series, top rated, by year, genres.
- **A title**: synopsis, facts, genres, where it streams officially, the trailer, related or similar titles; Watch,
  Want to watch, Mark as watched and Reset progress (these work even when the full page fails to load); episodes with
  their seen marks.
- **Watch**: what your sources found for the title or episode, in one step. Subtitles come preselected in your
  language and a menu changes them. Before a stream opens you see its source and host, and Continue or Start from
  beginning when there is progress.
- **Watch history**: everything you watched, by title. **Upcoming episodes**: the next known episodes of the anime in
  Want to watch, asked of AniList only while the page is open.
- **Sources**: your Stremio add-ons and web searches, Appearance (Normal or Prism), and Subtitles.

## Sources

Media Corner ships no sources. In **Sources**, add the HTTPS address of a Stremio add-on manifest, or a web search
address with `%s` where the title goes (it opens in your browser). Nobody has checked what you add: you choose what to
trust, and the rights to what a source offers are yours to check. Before an add-on is saved you see its declared name,
capabilities and id prefixes and confirm them; capabilities that appear on a later refresh stay off until you turn
them on. Sources can be reordered, given a local alias, and have streams and subtitles turned on or off apiece.

## Subtitles

Choose a language and a fallback in **Sources › Subtitles**, and add an add-on that offers `subtitles`. Optionally,
request an API key from [OpenSubtitles](https://www.opensubtitles.com/) and enter it there; it is kept in the
Corner's private settings, never in the repository. To download from OpenSubtitles directly, sign in with your
account: the password is not kept, and the session ends when you sign out or close the Corner. While mpv plays you can
shift the subtitles earlier or later, switch audio and subtitle tracks, and go fullscreen.

## Keys

Tab walks the places, the posters and the buttons; Return or Space opens what is focused. Escape or Alt+Left steps
back (a title, a search, a genre) and then closes the Corner; Alt+Right steps forward again. It opens where you left
it.

## What it keeps

- Options (style, host, languages, the API key): `~/.config/inir/plugins/media-corner.json`.
- Want to watch, progress and seen marks: files starting with `media-corner` in iNiR's state folder.
- Covers: up to 24 decoded images while the Corner is open; nothing is cached on disk by the Corner itself.

Nothing runs while it is closed: no polling, no background checks.
