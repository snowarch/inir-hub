"""Stremio add-ons the person adds by their manifest's address. What they send is JSON, read and never run.

Films and series are asked for by IMDb id, as Stremio does (`movie/tt…`, `series/tt…:season:episode`). Only streams
with an https address play; torrents (infoHash) and pages meant for a browser (externalUrl) are left out.
shortcut: no torrents and no per-stream headers but the Referer; add them if an add-on people use needs them.
"""

import json
import os
import re
import urllib.parse

from . import net
from .providers import Site, Source


def options_path():
    base = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    return os.path.join(base, "inir", "plugins", "movie-corner.json")


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
    """[(name, url, referer)] an add-on lists for one video."""
    body = net.jsonof("%s/stream/%s.json" % (base, path))
    out = []
    for item in body.get("streams") or [] if isinstance(body, dict) else []:
        if not isinstance(item, dict) or not str(item.get("url") or "").startswith("https://"):
            continue
        hints = item.get("behaviorHints") if isinstance(item.get("behaviorHints"), dict) else {}
        request = ((hints.get("proxyHeaders") or {}).get("request") or {}) if isinstance(hints.get("proxyHeaders"), dict) else {}
        referer = str(request.get("Referer") or request.get("referer") or "") if isinstance(request, dict) else ""
        name = " · ".join(str(item[k]).split("\n")[0] for k in ("name", "title") if item.get(k))[:60] or "Stream"
        out.append((name, str(item["url"]), referer))
    return out


class Addon(Site):
    kind = "stremio"

    def __init__(self, ident, name, base, audio):
        self.id, self.name, self.site = ident, name, base
        self.audios = (audio,)

    def sources(self, item, audio, subs):
        imdb = str(item.get("imdb") or "")
        if not re.fullmatch(r"tt\d{5,10}", imdb):
            return []
        path = "movie/" + imdb if item["kind"] == "movie" else "series/%s:%d:%d" % (imdb, item["season"], item["episode"])
        return [Source(self.id, name, audio, url, referer) for name, url, referer in streams(self.site, path)]


def saved(path=None):
    """The add-ons saved in the Corner's options, as sites."""
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
        out.append(Addon(ident, name, base, str(entry.get("audio") or "original")))
    return out


def check(url):
    """`inir-movie.py addon <manifest url>`: what the Corner saves for it, or why it can't."""
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
    if ids and "tt" not in ids:
        return {"ok": False, "error": "It doesn't find films by IMDb id"}
    return {"ok": True, "url": base + "/manifest.json", "name": str(manifest.get("name") or "")[:40],
            "types": [str(t) for t in manifest.get("types") or []][:8]}
