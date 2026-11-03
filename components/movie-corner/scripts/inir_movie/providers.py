"""The sites a film or an episode plays from. Each one turns what Cinemeta knows (IMDb id, TMDB id, title, year,
season, episode) into Sources, or nothing: one dead site never stops the others.

A site only joins when mpv plays it without a browser and nothing it sends has to be decoded or run.
"""

import html
import json
import re
import unicodedata
import urllib.parse

from . import hosts, net


class Source:
    """One way to watch: where it plays from, in which language, and what mpv needs to open it."""

    def __init__(self, site, name, audio, url, referer, subs="", burned=False, height=0, kind="", subtitles=None, flags=None):
        self.site = site
        self.name = name
        self.audio = audio
        self.subs = subs
        self.burned = burned
        self.url = url
        self.referer = referer
        self.height = height
        self.kind = kind or ("hls" if ".m3u8" in url or "/hls" in url or "_stream" in url else "mp4")
        self.subtitles = subtitles or []
        self.flags = flags or []

    def row(self):
        return {"site": self.site, "name": self.name, "audio": self.audio, "subs": self.subs, "burned": self.burned,
                "height": self.height, "url": self.url, "referer": self.referer, "subtitles": self.subtitles,
                "flags": self.flags}


def key(text):
    text = unicodedata.normalize("NFKD", html.unescape(str(text or ""))).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", " ", text.lower()).strip()


class Site:
    id = ""
    name = ""
    # The audio languages it has: "original" is the film's own track.
    audios = ()

    def sources(self, item, audio, subs):
        return []


# Subtitle languages as vidsrc.buzz names them (OpenSubtitles' English names), by our codes.
SUB_NAMES = {"en": "English", "es": "Spanish", "pt-BR": "Portuguese", "pt": "Portuguese", "fr": "French", "de": "German", "it": "Italian",
             "ar": "Arabic", "ru": "Russian", "tr": "Turkish", "ja": "Japanese", "ko": "Korean", "zh": "Chinese",
             "hi": "Hindi", "id": "Indonesian", "vi": "Vietnamese", "pl": "Polish", "uk": "Ukrainian", "he": "Hebrew",
             "nl": "Dutch"}


class VidsrcBuzz(Site):
    """The original audio by TMDB or IMDb id, with subtitles from OpenSubtitles in nearly every language."""

    id = "vidsrc"
    name = "vidsrc.buzz"
    audios = ("original",)
    BASE = "https://vidsrc.buzz"
    # Its segments are named like pictures; mpv's demuxer has to be told to read them anyway.
    FLAGS = ["--demuxer-lavf-o=extension_picky=0"]

    def sources(self, item, audio, subs):
        ident = item.get("tmdb") or item.get("imdb")
        if audio != "original" or not ident:
            return []
        path = "movie/%s" % ident if item["kind"] == "movie" else "tv/%s/%d/%d" % (ident, item["season"], item["episode"])
        page_url = "%s/embed/%s" % (self.BASE, path)
        page = net.text(page_url)
        at = page.find("var Q = ")
        if at < 0:
            return []
        try:
            q = json.JSONDecoder().raw_decode(page[at + 8:])[0]
        except ValueError:
            return []
        query = urllib.parse.urlencode({name: q.get(name, "") for name in ("type", "id", "s", "e", "t")})
        api = self.BASE + "/pl/api.php?"
        tracks = []
        wanted = [SUB_NAMES[code] for code in (subs, "en") if code in SUB_NAMES]
        if subs:
            try:
                listed = net.jsonof(api + "a=subs&" + query, referer=page_url).get("subs") or []
            except (net.Failed, AttributeError):
                listed = []
            for name in dict.fromkeys(wanted):
                match = next((s for s in listed if str(s.get("lang", "")).startswith(name) and s.get("ref")), None)
                if match:
                    tracks.append({"lang": name, "url": api + "a=sub&ref=" + urllib.parse.quote(str(match["ref"]))})
        servers = list((q.get("ssr") or {}).get("servers") or [])
        if not servers:
            try:
                servers = net.jsonof(api + "a=sources&" + query, referer=page_url, timeout=25).get("servers") or []
            except (net.Failed, AttributeError):
                servers = []
        out, seen = [], set()
        for server in servers[:4]:
            if server.get("k") in seen or not server.get("ref"):
                continue
            seen.add(server.get("k"))
            try:
                play = net.jsonof(api + "a=play&" + urllib.parse.urlencode({"ref": server["ref"], "t": q.get("t", "")}),
                                  referer=page_url)
            except (net.Failed, AttributeError):
                continue
            url = str(play.get("url") or "")
            if url.startswith("/"):
                url = self.BASE + url
            if url.startswith("https://"):
                out.append(Source(self.id, str(server.get("name") or self.name), "original", url, page_url,
                                  subs=subs if tracks else "", subtitles=tracks, flags=self.FLAGS, kind="hls"))
        return out


class MagisTV(Site):
    """Spanish: Latin American and Spain dubs, and the original with Spanish subtitles in the picture (VOSE)."""

    id = "magistv"
    name = "MagisTV24"
    audios = ("es-419", "es-ES", "original")
    BASE = "https://magistv24.com"
    LABELS = {"latino": "es-419", "castellano": "es-ES", "vose": "original", "subtitulado": "original"}

    def _find(self, item):
        """The site's page for the film or show: same kind and year, its original title on the page."""
        page = net.text(self.BASE + "/?s=" + urllib.parse.quote_plus(item["title"]))
        kind = "pelicula" if item["kind"] == "movie" else "serie"
        year = int(str(item.get("year") or "0")[:4] or 0)
        wanted = key(item["title"])
        for card in re.findall(r"<article\b.*?</article>", page, re.S):
            link = re.search(r'href="(%s/%s/[^"]+)"' % (re.escape(self.BASE), kind), card)
            if not link:
                continue
            found = re.search(r'class="year">\s*(\d{4})', card)
            if year and found and abs(int(found.group(1)) - year) > 1:
                continue
            detail = net.text(link.group(1))
            if wanted and wanted in key(detail):
                return link.group(1)
        return None

    def sources(self, item, audio, subs):
        if audio not in self.audios or (audio == "original" and subs not in ("es", "es-419")):
            return []
        page_url = self._find(item)
        if not page_url:
            return []
        if item["kind"] != "movie":
            slug = page_url.rstrip("/").rsplit("/", 1)[-1]
            page_url = "%s/capitulo/%s-temporada-%d-capitulo-%d/" % (self.BASE, slug, item["season"], item["episode"])
        page = net.text(page_url)
        frames = re.findall(r'id="options-(\d+)".*?(?:data-)?src="([^"]*\?trembed=[^"]+)"', page, re.S)
        labels = dict(re.findall(r'href="#options-(\d+)".*?class="server">\s*-?\s*([^<]+?)\s*</span>', page, re.S))
        out = []
        for at, frame in frames:
            language = self.LABELS.get(key(labels.get(at, "")).split(" ")[0] if labels.get(at) else "")
            if language != audio:
                continue
            embed = re.search(r'<iframe[^>]+src="(https://[^"]+)"', net.text(html.unescape(frame), referer=page_url), re.I)
            stream = hosts.resolve(html.unescape(embed.group(1)), self.BASE + "/") if embed else None
            if stream:
                out.append(Source(self.id, urllib.parse.urlsplit(embed.group(1)).hostname or self.name, audio, stream.url,
                                  stream.referer, subs="es" if audio == "original" else "", burned=audio == "original",
                                  height=stream.height, kind=stream.kind))
        return out


ALL = [VidsrcBuzz(), MagisTV()]
BY_ID = {site.id: site for site in ALL}


def languages():
    """Every audio language and the sites that have it."""
    out = {}
    for site in ALL:
        for audio in site.audios:
            out.setdefault(audio, []).append(site.id)
    return out
