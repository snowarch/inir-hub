# Media Corner

Find any anime, film or series and see where it streams officially, in a Place worn with iRiS. Anime comes from
AniList, films and series from Cinemeta (Stremio's open catalogue); it plays nothing itself.

- Open it: `inir media-corner toggle`, or bind it in niri: `Mod+Shift+M { spawn "inir" "media-corner" "toggle"; }`.
- Search: `inir media-corner search "<text>"` (anime, films and series at once).
- Go to a place: `inir media-corner go <place>`: `home`, `anime:airing|trending|top|season|genres`,
  `movie:movies|series|top|years|genres`, `anime:<AniList id>` or `title:<movie|series>:<IMDb id>`.
- Worn with: iRiS.
- Its options (layout and window) live in `~/.config/inir/plugins/media-corner.json`.

## Pages

- **Home**: what is trending, then shelves of anime airing now, trending and in season, and popular films and series.
- **Anime**: airing now, trending, top rated, this season (‹ › walk the seasons), genres.
- **Films and series**: films, series, top rated, by year, genres.
- **A title**: synopsis, facts, genres, the official streaming services AniList lists, AniList or IMDb, the trailer,
  and related or similar titles.

## Options

The two keys at the foot of the places:

- **Layout** walks Classic, Folio, Pocket and Drawer (the same shapes as iRiS Settings).
- **Window** opens it over the desktop or in a window of its own.
