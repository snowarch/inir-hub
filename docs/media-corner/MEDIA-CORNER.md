# Media Corner

A Place, worn with iRiS, to find any anime, film or series and see where it streams officially. Anime comes from
[AniList](https://anilist.co), films and series from Cinemeta (Stremio's open catalogue, by IMDb id). It plays
no media itself: it shows titles and official services and can open a stream from a user-added source in mpv.

## Open it

- `inir media-corner toggle`, `open` or `close`, or bind it in niri:
  `Mod+Shift+M { spawn "inir" "media-corner" "toggle"; }`.
- `inir media-corner search "<text>"` opens it searching both catalogues.
- `inir media-corner go <place>` opens it on a place: `home`, `anime:popular`, `anime:airing`, `anime:trending`, `anime:top`,
  `anime:season`, `anime:genres`, `movie:movies`, `movie:series`, `movie:top`, `movie:years`, `movie:genres`,
  `anime:<AniList id>` or `title:<movie|series>:<IMDb id>`.

## What is in it

- **Home**: what is trending, then shelves of anime airing now, trending and in season, and of popular films and
  series.
- **Anime**: popular, airing now, trending, top rated, this season (‹ › walk the seasons) and every AniList genre.
- **Films and series**: popular films and series, top rated, by year and by genre.
- **Search**: one field searches both catalogues; «See all» opens the whole list.
- **A title's page**: banner, synopsis, facts, genres, the official streaming services AniList lists (they open in
  the browser), the AniList or IMDb page, the trailer, and what to see next.

## Library and upcoming episodes

Add or remove a title from **Want to watch** on its page. The saved filter searches titles and types locally in that
list and in **Watching**, without making a network request. The sort button cycles through title, date added and
recent playback activity. Entries saved before dates were recorded have no added date and sort last in that order.
**Watch history** shows all entries grouped by title. Watching shows up to five recent entries when the filter
is empty; a search can show more. Selecting an entry opens the source chooser for that title and episode. Its remove
button asks for confirmation before deleting that one history entry and its playback position. It does not remove the
title from Want to watch or delete manual watched marks; an active playback entry cannot be removed until playback stops.

Mark a title watched or unwatched from its page. To mark episodes, choose **Mark episodes watched or unwatched**,
select the episodes, then finish marking. Manual marks are stored separately from playback position: marking an
episode unwatched does not erase its progress. If the marks cannot be read, the page offers a retry without replacing
the file.

**Upcoming episodes** fetches the next known airings for saved anime from AniList when opened or refreshed. It lists
future episodes in local date and time order, excludes films, and shows when the schedule was checked. It does not
poll or send notifications in the background; leaving the page cancels an in-flight request.

## Sources

Media Corner includes no add-ons. In **Sources**, add an HTTPS Stremio manifest or a web search address containing
`%s` where the title goes. Web searches open in the browser. Review the terms and rights of sources you add.

Before saving an add-on, review its declared name, capabilities, types and ID prefixes and confirm the preview.
Refreshing a manifest shows the previous and new values before applying them. Reading a manifest does not establish
that a source is safe or legitimate. Newly announced capabilities remain disabled until enabled. The displayed check
date is the time of the confirmed manifest read, not a title search.

Move sources to set their priority, give them local aliases, and enable streams and subtitles separately when the
add-on advertises them. An alias does not change the manifest name or address. Streams follow source priority unless
the alphabetical sort is selected in Watch.

## Window and keys

The key at the foot of the places opens it over the desktop or in a window of its own; that choice is kept in
`~/.config/inir/plugins/media-corner.json`. It opens where you left it.

Tab walks the places, the posters and the buttons; Return or Space opens what is focused. Ctrl+F goes to the search.
Escape clears the search, steps back (a title, a search, a genre) and then closes it.
