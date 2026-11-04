"""Stremio add-ons the person adds by their manifest's address. What they send is JSON, read and never run.

An add-on finds a show by its Kitsu id (the id Stremio's anime add-ons use), which Kitsu's public mappings give for
AniList's and MyAnimeList's ids. Only streams with an https address play; torrents (infoHash) and pages meant for a
browser (externalUrl) are left out. shortcut: no torrents and no per-stream headers but the Referer; add them if
an add-on people use needs them.
"""

import json
import os
import re
import urllib.parse

from . import net
from .hosts import Stream
from .providers import Provider, Show

KITSU = "https://kitsu.app/api/edge"


def options_path():
    base = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    return os.path.join(base, "inir", "plugins", "anime-corner.json")


def base_of(url):
    """The add-on's root from its manifest address, or None when it isn't one."""
    url = str(url or "").strip()
    if not re.fullmatch(r"https://[^\s/?#]+(/[^\s?#]*)?/manifest\.json", url):
        return None
    return url[: -len("/manifest.json")]


def ident_of(name, taken):
    slug = "addon-" + (re.sub(r"[^a-z0-9]+", "-", str(name).lower()).strip("-")[:24] or "stremio")
    ident, n = slug, 2
    while ident in taken:
        ident, n = "%s-%d" % (slug, n), n + 1
    return ident


def streams(base, path):
    """[(name, Stream)] an add-on lists for one video."""
    body = net.jsonof("%s/stream/%s.json" % (base, path))
    out = []
    for item in body.get("streams") or [] if isinstance(body, dict) else []:
        if not isinstance(item, dict) or not str(item.get("url") or "").startswith("https://"):
            continue
        hints = item.get("behaviorHints") if isinstance(item.get("behaviorHints"), dict) else {}
        request = ((hints.get("proxyHeaders") or {}).get("request") or {}) if isinstance(hints.get("proxyHeaders"), dict) else {}
        referer = str(request.get("Referer") or request.get("referer") or "") if isinstance(request, dict) else ""
        name = " · ".join(str(item[k]).split("\n")[0] for k in ("name", "title") if item.get(k))[:60] or "Stream"
        out.append((name, Stream(str(item["url"]), referer)))
    return out


def kitsu_of(meta):
    """(Kitsu id, episode count or 0, is a film, title) for AniList's ids, or None."""
    for site, value in (("anilist/anime", meta.get("anilistId")), ("myanimelist/anime", meta.get("malId"))):
        if not str(value or "").isdigit() or not int(value):
            continue
        query = urllib.parse.urlencode({"filter[externalSite]": site, "filter[externalId]": str(int(value)), "include": "item"})
        body = net.jsonof(KITSU + "/mappings?" + query)
        for item in body.get("included") or []:
            if item.get("type") == "anime" and str(item.get("id", "")).isdigit():
                about = item.get("attributes") or {}
                return (str(item["id"]), int(about.get("episodeCount") or 0), about.get("subtype") == "movie",
                        str(about.get("canonicalTitle") or ""))
    return None


class Addon(Provider):
    kind = "stremio"
    burned = False
    keep = ("count", "movie")

    def __init__(self, ident, name, base, types, audio, subs):
        self.id, self.name, self.site = ident, name, base
        self.types = types
        self.offers = ((audio, subs),)

    def by_id(self, meta, audio, subs, season):
        found = kitsu_of(meta)
        if not found:
            return []
        ident, count, movie, title = found
        return [Show(self, ident, title or ident, audio, subs, season, {"count": count, "movie": movie})]

    def episodes(self, show):
        if show.extra.get("movie"):
            return ["1"]
        count = int(show.extra.get("count") or 0)
        if not count:  # still airing: as many as Kitsu has listed
            listed = net.jsonof("%s/anime/%s/episodes?%s" % (KITSU, show.key, urllib.parse.urlencode({"page[limit]": "1"})))
            count = int((listed.get("meta") or {}).get("count") or 0)
        return [str(n) for n in range(1, count + 1)]

    def servers(self, show, episode):
        if show.extra.get("movie"):
            return streams(self.site, "movie/kitsu:%s" % show.key)
        kind = "anime" if "anime" in self.types else "series"
        return streams(self.site, "%s/kitsu:%s:%s" % (kind, show.key, episode))


def saved(path=None):
    """The add-ons saved in the Corner's options, as providers."""
    try:
        with open(path or options_path()) as handle:
            listed = json.load(handle).get("addons") or []
        if isinstance(listed, str):  # the Corner keeps them as JSON text
            listed = json.loads(listed or "[]")
    except (OSError, ValueError, AttributeError):
        return []
    out, taken = [], set()
    for entry in listed if isinstance(listed, list) else []:
        base = base_of(entry.get("url")) if isinstance(entry, dict) else None
        if not base:
            continue
        name = str(entry.get("name") or urllib.parse.urlsplit(base).hostname)
        ident = ident_of(name, taken)
        taken.add(ident)
        types = [str(t) for t in entry.get("types") or [] if isinstance(t, str)]
        out.append(Addon(ident, name, base, types, str(entry.get("audio") or "ja"), str(entry.get("subs") or "")))
    return out


def check(url):
    """`inir-anime.py addon <manifest url>`: what the Corner saves for it, or why it can't."""
    base = base_of(url)
    if not base:
        return {"ok": False, "error": "Not an add-on address: it ends in /manifest.json and starts with https://"}
    try:
        manifest = net.jsonof(base + "/manifest.json")
    except (net.Failed, ValueError) as error:
        return {"ok": False, "error": "It doesn't answer: %s" % error}
    if not isinstance(manifest, dict):
        return {"ok": False, "error": "It sends no add-on manifest"}
    resources = [r if isinstance(r, str) else (r or {}).get("name") for r in manifest.get("resources") or []]
    if "stream" not in resources:
        return {"ok": False, "error": "It lists no streams"}
    ids = [str(p) for p in manifest.get("idPrefixes") or []]
    if ids and not any(p.startswith("kitsu") for p in ids):
        return {"ok": False, "error": "It doesn't find anime by Kitsu id"}
    return {"ok": True, "url": base + "/manifest.json", "name": str(manifest.get("name") or "")[:40],
            "types": [str(t) for t in manifest.get("types") or []][:8]}
