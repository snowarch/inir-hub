"""What a source file builds on: `from inir_movie.sdk import Site, Source, net`.

A source is a .py file in the sources folder (see sources.py) that sets SOURCES to a list of Site objects. Each one
has an id, a name, the audio languages it plays (`audios`, "original" for the film's own track) and
sources(item, audio, subs) -> [Source], where item is {kind, title, year, imdb, tmdb, season, episode}. A page
address goes through resolve(): a direct m3u8/mp4 or a page naming one; HOSTS and PAGE_FILTERS in a source file
teach it more hosts.
"""

from . import net  # noqa: F401  fetch, text, jsonof, alive, parallel, https, UA, Failed
from .hosts import Stream, origin, player_page, resolve  # noqa: F401
from .providers import SUB_NAMES, Site, Source, key  # noqa: F401
