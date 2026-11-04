#!/usr/bin/env python3
"""Anime for iNiR in many languages, from the sources the person adds (it ships none).

  inir-anime.py [--audio ja|en|es-419|...] [--subs es|en|...|""] [--source ask|auto|anicli|<site>]
                [--dub] [--skip] [-q quality] [-e episode] query...
      ani-cli's arguments and conversation: AnimeWatch links this file as `ani-cli` in a run's bin.
  inir-anime.py languages        every (audio, subtitles) pair and the sites that play it, as JSON
  inir-anime.py doctor [site...] tries each site live: search, episode 1, the video answering
  inir-anime.py sources          the sources folder, each file and add-on loaded and what failed, as JSON
  inir-anime.py addon <url>      checks a Stremio add-on's manifest address before it is saved, as JSON
  inir-anime.py subs search <title> <season> <episode> <lang,...> | subs get <service> <id> <folder>
      subtitles from OpenSubtitles and SubDL; keys only in INIR_OPENSUBTITLES_KEY / INIR_SUBDL_KEY
  inir-anime.py account ...      AniList and MyAnimeList (see inir_anime/accounts.py)
"""

import json
import os
import sys

sys.dont_write_bytecode = True  # the shell's config folder is not a cache
# Run through a link (a run's bin/ani-cli) or with -I, the package still comes from beside the real file only.
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

from inir_anime import accounts, addons, doctor, engine, providers, sources, subs  # noqa: E402


def main(argv):
    if argv[:1] == ["addon"]:
        print(json.dumps(addons.check(argv[1] if len(argv) > 1 else "")))
        return 0
    if argv[:1] == ["account"]:
        return accounts.main(argv[1:])
    if argv[:1] == ["subs"]:
        return subs.main(argv[1:])
    sources.load()
    if argv[:1] == ["sources"]:
        print(json.dumps({"folder": sources.folder(), "files": sources.LOADED,
                          "sources": [{"id": p.id, "name": p.name, "kind": p.kind, "site": p.site, "offers": [list(o) for o in p.offers]}
                                      for p in providers.ALL]}, ensure_ascii=False))
        return 0
    if argv[:1] == ["languages"]:
        return doctor.languages()
    if argv[:1] == ["doctor"]:
        return doctor.run(argv[1:])
    return engine.main(argv)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
