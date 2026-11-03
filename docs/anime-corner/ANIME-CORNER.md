# Anime Corner

The Anime Corner is a component worn with iRiS: a place to find any show on AniList and watch it in your language in
mpv. It opens with Settings' body and layout, over the desktop or in a window of its own.

## Open it

- `inir anime-corner toggle`, bound to a key in niri's config: `Mod+A { spawn "inir" "anime-corner" "toggle"; }`.
- `inir anime-corner go <place>` opens it on home, continue, mylist, following, popular, trending, top, season,
  calendar, genres, settings, `genre:<name>` or `anime:<AniList id>`; `search <text>` opens it searching.

## Browse

- **Home**: the show you were watching, Continue watching, what airs now and what you follow.
- **Popular, Trending, Top rated, This season, Genres**: AniList's lists as posters; a poster opens the show with its
  episodes, related shows and characters.
- **Calendar**: the week's broadcasts at your local hour.
- **My list**: your AniList or MyAnimeList list, once connected or named in the Corner's Settings.
- **Following**: the shows you follow, shared with iRiS's Airing bubble.

## Watch

Watch opens a sheet over the Corner that walks through finding the show, finding sources, your pick and opening the
player. With *Source: Ask every time* it lists every site that has the episode, with its quality and subtitles; the pin
makes one the default. A failure stays on the sheet with what to try next: try again, or change the language or source.
While an episode plays, the sheet finds subtitles online (OpenSubtitles, SubDL) and steps to the next episode.

## Settings

The Corner's own Settings place keeps them in `~/.config/inir/plugins/anime-corner.json`:

- **Watch**: Audio (Japanese or a dub), Subtitles (with Japanese audio), Source, Check the sources.
- **Subtitles online**: your OpenSubtitles and SubDL keys, kept in the system keyring.
- **Accounts**: connect AniList or MyAnimeList with your own app's client ID, mark finished episodes, or name a public list.
- **The Corner**: new-episode alerts (off until you turn them on) and Open in a window.

Quality, the subtitle look and skipping intros are iRiS's own, in iRiS Settings › Anime, shared with the Continue bubble.
