# Media Corner

A Place, worn with iRiS, to find any anime, film or series and see where it streams officially. Anime comes from
[AniList](https://anilist.co), films and series from Cinemeta (Stremio's open catalogue, by IMDb id). It plays
nothing itself: it shows what a title is and the official services that carry it.

## Open it

- `inir media-corner toggle`, or bind it in niri: `Mod+Shift+M { spawn "inir" "media-corner" "toggle"; }`.
- `inir media-corner search "<text>"` opens it searching both catalogues.
- `inir media-corner go <place>` opens it on a place: `home`, `anime:airing`, `anime:trending`, `anime:top`,
  `anime:season`, `anime:genres`, `movie:movies`, `movie:series`, `movie:top`, `movie:years`, `movie:genres`,
  `anime:<AniList id>` or `title:<movie|series>:<IMDb id>`.

## What is in it

- **Home**: what is trending, then shelves of anime airing now, trending and in season, and of popular films and
  series.
- **Anime**: airing now, trending, top rated, this season (‹ › walk the seasons) and every AniList genre.
- **Films and series**: popular films and series, top rated, by year and by genre.
- **Search**: one field searches both catalogues; «See all» opens the whole list.
- **A title's page**: banner, synopsis, facts, genres, the official streaming services AniList lists (they open in
  the browser), the AniList or IMDb page, the trailer, and what to see next.

## Layout and window

The keys at the foot of the places change its layout (Classic, Folio, Pocket, Drawer, the shapes iRiS Settings has)
and open it over the desktop or in a window of its own. Both are kept in `~/.config/inir/plugins/media-corner.json`;
removing the component removes them.
