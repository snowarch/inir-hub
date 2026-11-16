# Media Corner

Anime, films and series in one place: browse them, see where each one streams officially, and play it in mpv from
sources you add. Anime comes from AniList; films and series from Cinemeta, Stremio's open catalogue. Worn with iRiS.

## Open it

- App launcher: **Media Corner**.
- Niri keybind: `Mod+Shift+M { spawn "inir" "media-corner" "toggle"; }`
- The window key at the top right switches between the desktop overlay and a window of its own.

## Three styles, the same features

Media Corner is based on iRiS's Settings window, in the layout of the same name:

| Style | Looks like |
|---|---|
| **Classic** | The places on a card with the search on top, each with its glyph in colour; the page's name over it |
| **Folio** | The places down the left under captions, the search over the page |
| **Prism** | Near-black, white for what is chosen, and a right rail with Yours and the player |

Classic and Folio share the page: the trending shows on one card, Every day's tiles, Yours and the Library rows.
Prism has its own: a hero, a deck of two cards and the places of every day.

Switch between them with the switch at the top right (Classic and Folio show it), in **Sources › Appearance**
(every style), or in Community Hub. You keep your place, the open title and what is playing.

## Pages

| Page | What it has |
|---|---|
| Home | Trending shows, a way back to what you were watching, the places you open every day, shelves of anime, films and series |
| Anime | Popular, airing now, trending, top rated, this season (‹ › walk the seasons), genres |
| Films and series | Films, series, top rated, by year, genres |
| A title | Synopsis, facts, where it streams officially, the trailer, related titles; Watch, Want to watch, Mark as watched, Reset progress; episodes with their seen marks |
| Watch | What your sources found for that title or episode. Subtitles come preselected in your language, and a menu changes them |
| Watch history | Everything you have watched, grouped by title |
| Upcoming episodes | The next episodes of the anime in Want to watch. AniList is asked only while the page is open |
| Sources | Your add-ons and web searches, Appearance, Subtitles |

Shelves show their shape while they load. If a catalogue fails, they say so and offer Retry. Title actions still
work when the full page fails to load.

## Playing

1. Add a source (see below).
2. Open a title and press **Watch**.
3. Pick a stream. You see its source and host before it opens; if there is saved progress, choose Continue or Start
   from beginning.

While mpv plays, the player card (on the rail, at the foot of the page, or on the title's page) seeks, pauses, skips
10 seconds, shifts subtitles, switches audio and subtitle tracks, goes fullscreen and stops. Progress is saved as you
watch, including when you change episodes mid-play.

## Sources

Media Corner ships with no sources, and nobody has reviewed the ones you add: you decide what to trust, and checking
the rights to what a source offers is up to you. In **Sources**:

- **Stremio add-on**: the HTTPS address of its `manifest.json`. Before saving, you review its name, capabilities and
  id prefixes. Capabilities that show up on a later refresh stay off until you turn them on.
- **Web search**: a search address with `%s` where the title goes. It opens in your browser.

You can reorder sources, give them a local alias, and turn streams and subtitles on or off for each one.

## Subtitles

In **Sources › Subtitles** pick a language and a fallback, and choose whether Watch preselects one or leaves it to
you. Subtitles come from your add-ons that offer them. As an option, add your own
[OpenSubtitles](https://www.opensubtitles.com/) API key. It is kept in Media Corner's private settings, never in
the repository. To download straight from OpenSubtitles, sign in there. Your password is not saved, and the session
ends when you sign out or close Media Corner.

## IPC

| Call | Does |
|---|---|
| `inir media-corner toggle` · `open` · `close` | Shows or hides it |
| `inir media-corner search "<text>"` | Searches anime, films and series |
| `inir media-corner go <place>` | Opens a place: `home`, `sources`, `history`, `schedule`, `anime:popular\|airing\|trending\|top\|season\|genres`, `movie:movies\|series\|top\|years\|genres`, `anime:<AniList id>`, `title:<movie\|series>:<IMDb id>` |
| `inir media-corner pause` · `resume` · `togglePause` | Pauses or resumes mpv |
| `inir media-corner seek <seconds>` | Jumps to a position |
| `inir media-corner stop` | Stops playback |

## Keys

| Key | Does |
|---|---|
| Tab · Return · Space | Move between places, posters and buttons; open the focused one |
| Ctrl+F | Search |
| Escape · Alt+Left | Clear the search, then go back (title, search, genre), then close |
| Alt+Right | Go forward again |

It opens where you left it.

## Files

- Options (style, overlay or window, languages, API key): `~/.config/inir/plugins/media-corner.json`.
- Want to watch, progress and seen marks: `media-corner-watchlist.json`, `media-corner-progress.json` and
  `media-corner-seen.json` in iNiR's state folder.
- Covers: up to 24 decoded images while it is open. Media Corner keeps no disk cache of its own.

Nothing runs while it is closed: no polling, no background checks.
