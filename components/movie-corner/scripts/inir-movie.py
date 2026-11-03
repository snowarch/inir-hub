#!/usr/bin/env python3
"""Films and series for iNiR's Movie Corner, from the sites that play them in each language.

  inir-movie.py sources --kind movie|series --title T [--year Y] [--imdb tt..] [--tmdb N] [-s S -e E]
                        [--audio original|es-419|es-ES] [--subs <code>] [--source ask|auto|<site>]
      one JSON line per source that plays (site, language, picture, stream, subtitles), then {"done": true}
  inir-movie.py doctor [site...]   tries every site live and says which ones play
  inir-movie.py languages          every audio language and the sites that have it

Nothing is played here: the Movie Corner opens the source the person picks in mpv.
"""

import os
import sys

sys.dont_write_bytecode = True  # the shell's config folder is not a cache
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

from inir_movie import engine  # noqa: E402


def main(argv):
    if argv[:1] == ["sources"]:
        return engine.sources(argv[1:])
    if argv[:1] == ["doctor"]:
        return engine.doctor(argv[1:])
    if argv[:1] == ["languages"]:
        return engine.languages()
    print(__doc__.strip(), file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
