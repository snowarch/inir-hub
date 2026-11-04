"""Finding what plays: every site of the chosen language asked at once, each stream checked, one JSON line per source.

  sources --kind movie|series --title T [--year Y] [--imdb tt..] [--tmdb N] [-s S -e E]
          [--audio original|es-419|es-ES] [--subs <code>|""] [--source ask|auto|<site>]
  doctor [site...]   tries each site live on one well-known film and says which ones play
  languages          every audio language and the sites that have it
  list               the sources folder, each file and add-on loaded and what failed
  addon <url>        checks a Stremio add-on's manifest address before it is saved
"""

import argparse
import json
import re
import sys

from . import net, providers

DEADLINE = 25
# The film every site is tried on: well known, on every site, in every language.
PROBE = {"kind": "movie", "title": "Inception", "year": "2010", "imdb": "tt1375666", "tmdb": "27205", "season": 0, "episode": 0}


def say(row):
    sys.stdout.write(json.dumps(row, ensure_ascii=False) + "\n")
    sys.stdout.flush()


def height_of(source):
    """The best picture a stream offers, from its HLS master playlist; 0 when it doesn't say, -1 when it is dead."""
    if source.kind != "hls":
        return source.height if net.alive(source.url, source.referer) else -1
    try:
        playlist = net.fetch(source.url, referer=source.referer, limit=512 * 1024, timeout=8)[1].decode(errors="replace")
    except net.Failed:
        return -1
    if "#EXTM3U" not in playlist:
        return -1
    heights = [int(h) for h in re.findall(r"RESOLUTION=\d+x(\d+)", playlist)]
    return max(heights) if heights else source.height


# OpenSubtitles through Stremio's open add-on: no key, every language, files served from one host.
OPENSUBS = "https://opensubtitles-v3.strem.io/subtitles"
OPENSUBS_FILES = "https://subs5.strem.io/"
OPENSUBS_CODES = {"en": ("eng",), "es": ("spa", "spn"), "pt-BR": ("pob", "por"), "pt": ("por", "pob"), "fr": ("fre", "fra"),
                  "de": ("ger", "deu"), "it": ("ita",), "ar": ("ara",), "ru": ("rus",), "tr": ("tur",), "ja": ("jpn",),
                  "ko": ("kor",), "zh": ("chi", "zho", "zhs"), "hi": ("hin",), "id": ("ind",), "vi": ("vie",), "pl": ("pol",),
                  "uk": ("ukr",), "he": ("heb",), "nl": ("nld", "dut")}


def opensubs(item, subs, most=2):
    """Up to `most` subtitle files in `subs` for the item, by IMDb id; none when it has no id or the add-on is down."""
    codes = OPENSUBS_CODES.get(subs)
    if not codes or not re.fullmatch(r"tt\d{5,10}", str(item.get("imdb") or "")):
        return []
    ident = item["imdb"] if item["kind"] == "movie" else "%s:%d:%d" % (item["imdb"], item["season"], item["episode"])
    try:
        listed = net.jsonof("%s/%s/%s.json" % (OPENSUBS, "movie" if item["kind"] == "movie" else "series", ident)).get("subtitles") or []
    except (net.Failed, AttributeError):
        return []
    picked = [s for s in listed if isinstance(s, dict) and s.get("lang") in codes
              and str(s.get("url", "")).startswith(OPENSUBS_FILES)]
    # Their own order is by downloads; the closer language code first, and a camera rip's timing rarely fits.
    picked.sort(key=lambda s: (codes.index(s["lang"]), str(s.get("releaseFormat", "")).lower() in ("cam", "ts", "telesync")))
    name = providers.SUB_NAMES.get(subs, subs)
    return [{"lang": name, "url": str(s["url"])} for s in picked[:most]]


def find(item, audio, subs, only=""):
    """Every live source for the item, best picture first."""
    sites = [site for site in providers.ALL if audio in site.audios and (not only or site.id == only)]
    found = []
    jobs = [lambda site=site: site.sources(item, audio, subs) for site in sites]
    if audio == "original" and subs:
        jobs.append(lambda: opensubs(item, subs))
    answers = net.parallel(lambda job: job(), jobs, DEADLINE)
    extra = (answers.pop() or []) if audio == "original" and subs else []
    for listed in answers:
        found.extend(listed or [])
    # A site without the asked language gets OpenSubtitles' files as tracks mpv loads.
    name = providers.SUB_NAMES.get(subs, subs)
    for source in found:
        if extra and source.audio == "original" and not source.burned and not any(t.get("lang") == name for t in source.subtitles):
            source.subtitles = [t for t in extra] + source.subtitles
            source.subs = subs
    heights = net.parallel(height_of, found, 12)
    live = []
    for source, height in zip(found, heights):
        if height is not None and height >= 0:
            source.height = height
            live.append(source)
    # Subtitles the person asked for count before picture; then the bigger picture.
    return sorted(live, key=lambda s: (not s.subtitles and not s.burned and bool(subs), -s.height))


def item_of(args):
    return {"kind": args.kind, "title": args.title, "year": args.year, "imdb": args.imdb, "tmdb": args.tmdb,
            "season": args.season, "episode": args.episode}


def sources(argv):
    parser = argparse.ArgumentParser(prog="inir-movie.py sources")
    parser.add_argument("--kind", choices=("movie", "series"), required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--year", default="")
    parser.add_argument("--imdb", default="")
    parser.add_argument("--tmdb", default="")
    parser.add_argument("-s", "--season", type=int, default=1)
    parser.add_argument("-e", "--episode", type=int, default=1)
    parser.add_argument("--audio", default="original")
    parser.add_argument("--subs", default="")
    parser.add_argument("--source", default="ask")
    args = parser.parse_args(argv)
    if args.imdb and not re.fullmatch(r"tt\d{5,10}", args.imdb):
        parser.error("not an IMDb id")
    if args.tmdb and not args.tmdb.isdigit():
        parser.error("not a TMDB id")
    preferred = args.source if args.source in providers.BY_ID else ""
    item = item_of(args)
    found = find(item, args.audio, args.subs, preferred)
    if preferred and not found:
        # The pinned site doesn't have it: the others may.
        found = find(item, args.audio, args.subs)
        if found:
            say({"note": "fallback", "site": preferred})
    for source in found:
        say(dict(source.row(), title=providers.BY_ID[source.site].name))
    say({"done": True, "count": len(found)})
    return 0


def doctor(argv):
    """Each site, each language it claims, on the probe film: ok when a stream answers."""
    rows = []
    if not providers.ALL:
        say({"none": True})
        return 1
    for site in providers.ALL:
        if argv and site.id not in argv:
            continue
        for audio in site.audios:
            subs = site.probe_subs if audio == "original" else ""
            try:
                found = find(PROBE, audio, subs, site.id)
            except Exception:  # a site's breakage is its own row
                found = []
            rows.append({"site": site.id, "name": site.name, "audio": audio, "ok": bool(found),
                         "height": max((s.height for s in found), default=0)})
            say(rows[-1])
    return 0 if any(row["ok"] for row in rows) else 1


def languages():
    say(providers.languages())
    return 0
