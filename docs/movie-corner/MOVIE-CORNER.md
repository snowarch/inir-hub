# Movie Corner

The Movie Corner is a component worn with iRiS: a place to find any film or series and watch it in your language in
mpv. It opens with Settings' body and layout, over the desktop or in a window of its own.

## Open it

- `qs -c inir ipc call movie-corner toggle`, bound to a key in niri's config:
  `Mod+M { spawn "qs" "-c" "inir" "ipc" "call" "movie-corner" "toggle"; }`. An `inir` that knows plugin targets takes
  `inir movie-corner toggle`.
- Settings › The Corner › **In the app launcher** (on by default) adds a Movie Corner entry to the launcher's search, which can then be
  pinned to the Dock. Turning it off removes the entry; if the Corner is removed first, the entry deletes itself the
  next time it is clicked.
- `go <place>` opens it on home, continue, following, movies, series, top, years, genres, settings, `genre:<name>` or
  `title:<movie|series>:<IMDb id>`; `search <text>` opens it searching.
- `watch movie:<IMDb id> ""` or `watch series:<IMDb id> <season>:<episode>` looks for sources at once; while it
  offers several, `choose <n>` plays the n-th (0 is the first). `stop` ends what plays.
- With the Anime Corner installed, its sidebar has a row that opens it.

## Browse

- **Home**: what you were watching, Continue watching, Following, popular films and series, new this year, top rated.
- **Films, Series, Top rated, By year, Genres**: Cinemeta's lists as posters. A poster opens the title: its backdrop,
  facts, cast, trailer, IMDb, more like it and, for a series, its episodes a season at a time.
- **Continue watching** and **Following** are kept by the Corner itself.

## Watch

Watch opens a sheet over the Corner that asks every site of your language at once, then lists the sources with their
picture and subtitles. With *Source: Ask every time* you pick; the pin makes a site the default. A source that won't
open sends you back to the others. Films and episodes resume where you stopped.

| Audio | Sites |
| --- | --- |
| Original, with subtitles in nearly any language you can turn off | vidsrc.buzz |
| Original with Spanish subtitles in the picture (VOSE) | MagisTV24 |
| Latin American Spanish, Spain Spanish | MagisTV24 |

With the original audio, a site that lacks your subtitle language gets it from OpenSubtitles through Stremio's open
add-on (no account, no key): German, French, Italian, Portuguese and the rest of the list, when someone has made them.

Sites change without notice: *Check the sources* in Settings tries each one on a well-known film.

## Settings

The Corner's own Settings place keeps them in `~/.config/inir/plugins/movie-corner.json`: audio, subtitles, source, the
launcher entry and opening in a window. Progress lives in `~/.local/state/quickshell/user/movie-corner-progress.json`.

## Privacy

Only HTTPS. Nothing a site sends is run or decoded: pages are read as text, and mpv gets the stream after `--` with only
the options the Corner itself sets.
