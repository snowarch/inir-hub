"""What a source file builds on: `from inir_anime.sdk import Provider, Show, Stream, net`.

A source is a .py file in the sources folder (see sources.py) that sets SOURCES to a list of Provider objects. Each
one answers: search(query, audio, subs, season) -> [Show], episodes(show) -> ["1", "2", ...] and
servers(show, episode) -> [(server name, embed url or Stream)]. An embed url is read by resolve(): a direct
m3u8/mp4 or a page naming one; HOSTS and PAGE_FILTERS in a source file teach it more hosts.
"""

from . import net  # noqa: F401  fetch, text, jsonof, alive, parallel, https, UA, Failed
from .hosts import Stream, origin, player_page, resolve  # noqa: F401
from .providers import Provider, Show, clean, number, quoted  # noqa: F401
