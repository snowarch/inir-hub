"""Which sites play right now: the same path a run takes, on one well-known show per language."""

import concurrent.futures
import json
import time

from . import engine, providers

# A long, widely licensed show every site carries, under the names they file it as.
PROBE = {"titles": ["Sousou no Frieren", "Frieren: Beyond Journey's End", "Frieren"], "season": 1}


def languages():
    out = {}
    for audio, subs in providers.languages():
        sites = [p.id for p in providers.offering(audio, subs)]
        if (audio, subs) in (("ja", "en"), ("en", "")):
            sites.append(engine.ANICLI)
        out.setdefault(audio, {})[subs] = sites
    print(json.dumps(out, ensure_ascii=False))
    return 0


def _check(provider):
    started = time.monotonic()
    audio, subs = provider.offers[0]
    run = engine.Run(audio, subs, provider.id, "best", PROBE, PROBE["titles"][0])
    try:
        found = run._search(provider)
        if not found:
            return provider.id, "no search result", time.monotonic() - started
        show = found[0][1]
        shows = {provider.id: show}
        lists = run.episodes(shows)
        if "1" not in lists.get(provider.id, []):
            return provider.id, "no episode 1 (%s)" % show.title, time.monotonic() - started
        options = run.options(shows, lists, "1")
        if not options:
            return provider.id, "no video answered (%s)" % show.title, time.monotonic() - started
        label = options[0][0]
        return provider.id, "OK %s · %sp · %d sources" % (label["server"], label["height"] or "?", len(options)), time.monotonic() - started
    except Exception as error:  # a broken site is a row in the table, not a crash
        return provider.id, "error: %s" % error, time.monotonic() - started


def run(names):
    chosen = [providers.BY_ID[n] for n in names if n in providers.BY_ID] or providers.ALL
    if not chosen:
        print("No sources yet: add a file to the sources folder or a Stremio add-on in the Corner's settings")
        return 1
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        rows = list(pool.map(_check, chosen))
    for pid, verdict, seconds in rows:
        print("%-16s %5.1fs  %s" % (pid, seconds, verdict))
    return 0 if all(v.startswith("OK") for _, v, _ in rows) else 1
