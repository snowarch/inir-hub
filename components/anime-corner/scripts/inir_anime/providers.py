"""Every site the engine can play from, by the languages it offers.

A provider answers four questions: which of its shows match these titles in this language, which episodes a show
has, and where an episode's video sits (embed pages for hosts.resolve, or a ready Stream). Each language pair is
(audio, subtitles): ("es-419", "") is the Latin American dub, ("ja", "es") Japanese with Spanish subtitles burned in.
Sites change without warning; one that stops answering only drops out of the list, it never stops the others.
"""

import html
import json
import re
import urllib.parse

from . import net
from .hosts import Stream


class Show:
    def __init__(self, provider, key, title, audio, subs, season=1, extra=None):
        self.provider = provider
        self.key = key
        self.title = title
        self.audio = audio
        self.subs = subs
        self.season = season
        self.extra = extra or {}


def clean(text):
    return html.unescape(re.sub(r"<[^>]+>", "", str(text or ""))).strip()


def number(value):
    value = float(value)
    return str(int(value)) if value.is_integer() else str(value)


def quoted(text):
    return urllib.parse.quote(str(text))


class Provider:
    id = ""
    name = ""
    site = ""
    offers = ()  # (audio, subs) pairs
    burned = True  # subtitles, where any, are part of the picture

    def search(self, query, audio, subs, season):
        return []

    def episodes(self, show):
        return []

    def servers(self, show, episode):
        """[(server name, embed url or Stream)]"""
        return []


class AnimeAV1(Provider):
    id, name, site = "animeav1", "AnimeAV1", "https://animeav1.com"
    offers = (("es-419", ""), ("ja", "es"))

    def _data(self, path):
        body = net.jsonof(self.site + path)
        node = [n for n in body.get("nodes") or [] if n and n.get("data")][-1]
        table = node["data"]

        def value(at):
            item = table[at]
            if isinstance(item, dict):
                return {k: value(v) for k, v in item.items()}
            if isinstance(item, list):
                return [value(v) for v in item]
            return item

        return value(0)

    def search(self, query, audio, subs, season):
        found = self._data("/catalogo/__data.json?" + urllib.parse.urlencode({"search": query})).get("results") or []
        return [Show(self, s["slug"], s["title"], audio, subs) for s in found]

    def episodes(self, show):
        media = self._data("/media/%s/__data.json" % show.key)["media"]
        show.extra["malId"] = media.get("malId")
        return [number(e["number"]) for e in sorted(media.get("episodes") or [], key=lambda e: e["number"])]

    def servers(self, show, episode):
        embeds = self._data("/media/%s/%s/__data.json" % (show.key, episode)).get("embeds") or {}
        side = "DUB" if show.audio == "es-419" else "SUB"
        return [(s["server"], s["url"]) for s in embeds.get(side) or [] if s.get("server") not in ("HLS", "UPNShare", "Voe")]


class Henaojara(Provider):
    id, name, site = "henaojara", "Henaojara", "https://henaojara.com"
    offers = (("es-419", ""), ("ja", "es"))

    def search(self, query, audio, subs, season):
        page = net.text(self.site + "/?s=" + quoted(query))
        want = "espanol-latino" if audio == "es-419" else "sub-espanol"
        out = []
        for slug in dict.fromkeys(re.findall(r'href="https://henaojara\.com/view/([a-z0-9-]+)/"', page)):
            if want in slug:
                title = re.sub(r"-(espanol-latino|sub-espanol)(-hd)?$", "", slug).replace("-", " ")
                out.append(Show(self, slug, title, audio, subs))
        return out

    def episodes(self, show):
        page = net.text(self.site + "/view/%s/" % show.key)
        found = re.findall(r"/view/episode/%s-(\d+)x(\d+)/" % re.escape(show.key), page)
        show.extra["eps"] = {number(e): s for s, e in found}
        return sorted(show.extra["eps"], key=float)

    def servers(self, show, episode):
        season = show.extra.get("eps", {}).get(episode, "1")
        page = net.text(self.site + "/view/episode/%s-%sx%s/" % (show.key, season, episode))
        trid = re.search(r"trid=(\d+)", page)
        if not trid:
            return []
        def frame(slot):
            page = net.text(self.site + "/?trembed=%d&trid=%s&trtype=2" % (slot, trid.group(1)), referer=self.site + "/")
            found = re.search(r'<iframe[^>]+src="\s*([^"]+)"', page)
            return html.unescape(found.group(1)).strip() if found else None

        urls = [u for u in net.parallel(frame, range(6), 10) if u]
        # Their own player (streamhj) hides its link.
        return [(urllib.parse.urlsplit(u).hostname or "", u) for u in urls if "streamhj." not in u]


class JKAnime(Provider):
    id, name, site = "jkanime", "JKAnime", "https://jkanime.net"
    offers = (("ja", "es"), ("es-419", ""))

    def search(self, query, audio, subs, season):
        # Their search is slow (20 s is common), not broken.
        page = net.text(self.site + "/buscar/%s" % quoted(query), timeout=30)
        slugs = dict.fromkeys(re.findall(r'href="https://jkanime\.net/([a-z0-9-]+)/"', page))
        out = []
        for slug in slugs:
            latino = slug.endswith("-latino")
            if latino == (audio == "es-419") and slug not in ("buscar", "directorio", "horario", "top"):
                out.append(Show(self, slug, slug.replace("-latino", "").replace("-", " "), audio, subs))
        return out

    def episodes(self, show):
        page = net.text(self.site + "/%s/" % show.key)
        found = re.search(r"Episodios:?\s*</span>\s*(\d+)", page)
        return [str(n) for n in range(1, int(found.group(1)) + 1)] if found else []

    def servers(self, show, episode):
        page = net.text(self.site + "/%s/%s/" % (show.key, episode))
        out = []
        for src in re.findall(r"video\[\d+\]\s*=\s*'<iframe[^>]+src=\"([^\"]+)\"", page):
            src = html.unescape(src)
            if "/jkplayer/" in src:
                player = net.text(urllib.parse.urljoin(self.site, src), referer=self.site + "/")
                found = re.search(r"url:\s*'(https://[^']+\.m3u8[^']*)'", player)
                if found:
                    out.append(("JKPlayer", Stream(found.group(1), self.site + "/")))
            elif "jkokru.php" in src:
                found = re.search(r"u=(\d+)", src)
                if found:
                    out.append(("OK.ru", "https://ok.ru/videoembed/" + found.group(1)))
        return out


class AniWorld(Provider):
    id, name, site = "aniworld", "AniWorld", "https://aniworld.to"
    offers = (("de", ""), ("ja", "de"), ("ja", "en"))
    KEYS = {("de", ""): "1", ("ja", "en"): "2", ("ja", "de"): "3"}

    def search(self, query, audio, subs, season):
        found = net.jsonof(self.site + "/ajax/search", data={"keyword": query},
                           headers={"X-Requested-With": "XMLHttpRequest"})
        out = []
        for item in found if isinstance(found, list) else []:
            link = re.match(r"^/anime/stream/([a-z0-9-]+)$", str(item.get("link") or ""))
            if link:
                out.append(Show(self, link.group(1), clean(item.get("title")), audio, subs, season))
        return out

    def episodes(self, show):
        page = net.text(self.site + "/anime/stream/%s/staffel-%d" % (show.key, show.season))
        pattern = r'href="/anime/stream/%s/staffel-%d/episode-(\d+)"' % (re.escape(show.key), show.season)
        return sorted(set(re.findall(pattern, page)), key=int)

    def servers(self, show, episode):
        page = net.text(self.site + "/anime/stream/%s/staffel-%d/episode-%s" % (show.key, show.season, episode))
        key = self.KEYS.get((show.audio, show.subs))
        out = []
        for lang, target, name in re.findall(
                r'data-lang-key="(\d)"[^>]*data-link-target="(/redirect/\d+)"[^>]*>.*?<h4>([^<]+)</h4>', page, re.S):
            if lang == key and name.strip() not in ("VOE", "Doodstream"):
                out.append((name.strip(), self.site + target))
        return out


class AnimeWorld(Provider):
    id, name, site = "animeworld", "AnimeWorld", "https://www.animeworld.ac"
    offers = (("it", ""), ("ja", "it"))

    def search(self, query, audio, subs, season):
        page = net.text(self.site + "/search?keyword=" + quoted(query))
        out = []
        for slug, title in re.findall(r'href="/play/([^"]+)"[^>]*class="name"[^>]*>([^<]+)', page):
            title = clean(title)
            dub = title.endswith("(ITA)")
            if dub == (audio == "it"):
                out.append(Show(self, slug, title.replace("(ITA)", "").strip(), audio, subs))
        return list({s.key: s for s in out}.values())

    def episodes(self, show):
        page = net.text(self.site + "/play/" + show.key)
        found = re.findall(r'data-id="([^"]+)" data-episode-num="([^"]+)"', page)
        show.extra["ids"] = {number(n) if re.match(r"^[\d.]+$", n) else n: i for i, n in found}
        return sorted(show.extra["ids"], key=lambda n: float(n) if re.match(r"^[\d.]+$", n) else 1e9)

    def servers(self, show, episode):
        if "ids" not in show.extra:
            self.episodes(show)
        at = show.extra["ids"].get(episode)
        if not at:
            return []
        info = net.jsonof(self.site + "/api/episode/info?id=%s&alt=0" % quoted(at), referer=self.site + "/")
        link = info.get("grabber") or ""
        return [("AnimeWorld", Stream(net.https(link), self.site + "/", kind="mp4"))] if link.endswith(".mp4") else []


class AnimesDigital(Provider):
    id, name, site = "animesdigital", "Animes Digital", "https://animesdigital.org"
    offers = (("pt-BR", ""), ("ja", "pt-BR"))

    def search(self, query, audio, subs, season):
        page = net.text(self.site + "/pesquisa/%s/" % quoted(query))
        out = []
        for slug in dict.fromkeys(re.findall(r'href="https://animesdigital\.org/anime/a/([a-z0-9-]+)"', page)):
            dub = "dublado" in slug
            if dub == (audio == "pt-BR"):
                title = re.sub(r"-(dublado|todos-episodios)", "", slug).replace("-", " ")
                out.append(Show(self, slug, title, audio, subs))
        return out

    def episodes(self, show):
        page = net.text(self.site + "/anime/a/%s" % show.key)
        found = re.findall(r'href="https://animesdigital\.org/video/a/(\d+)/".{0,400}?Epis[oó]dio\s*(\d+)', page, re.S)
        show.extra["ids"] = {number(n): i for i, n in found}
        return sorted(show.extra["ids"], key=float)

    def servers(self, show, episode):
        if "ids" not in show.extra:
            self.episodes(show)
        at = show.extra["ids"].get(episode)
        if not at:
            return []
        page = net.text(self.site + "/video/a/%s/" % at)
        found = re.search(r"videohls\.php\?d=(https://[^&\"']+\.m3u8)", page)
        return [("HLS", Stream(found.group(1), self.site + "/"))] if found else []


class AnimeSama(Provider):
    id, name, site = "animesama", "Anime-Sama", "https://anime-sama.to"
    offers = (("fr", ""), ("ja", "fr"))

    def search(self, query, audio, subs, season):
        page = net.text(self.site + "/template-php/defaut/fetch.php", data={"query": query})
        out = []
        for slug, title in re.findall(r'href="https://anime-sama\.to/catalogue/([a-z0-9-]+)/?".*?<h3[^>]*>([^<]+)', page, re.S):
            out.append(Show(self, slug, clean(title), audio, subs, season))
        return out

    def _players(self, show):
        if "players" not in show.extra:
            side = "vf" if show.audio == "fr" else "vostfr"
            base = self.site + "/catalogue/%s/saison%d/%s/" % (show.key, show.season, side)
            script = net.text(base + "episodes.js", referer=base)
            players = []
            for name, body in re.findall(r"var\s+(eps\d+)\s*=\s*\[(.*?)\];", script, re.S):
                players.append((name, re.findall(r"'(https?://[^']+)'", body)))
            show.extra["players"] = players
            show.extra["referer"] = base
        return show.extra["players"]

    def episodes(self, show):
        players = self._players(show)
        count = max((len(links) for _, links in players), default=0)
        return [str(n) for n in range(1, count + 1)]

    def servers(self, show, episode):
        at = int(episode) - 1
        out = []
        for _, links in self._players(show):
            if 0 <= at < len(links):
                out.append((urllib.parse.urlsplit(links[at]).hostname or "", links[at]))
        return out


class AniLiberty(Provider):
    id, name, site = "aniliberty", "AniLiberty", "https://anilibria.top"
    offers = (("ru", ""),)
    burned = False

    def search(self, query, audio, subs, season):
        found = net.jsonof(self.site + "/api/v1/app/search/releases?query=" + quoted(query))
        out = []
        for item in found if isinstance(found, list) else []:
            names = item.get("name") or {}
            out.append(Show(self, item.get("alias"), names.get("english") or names.get("main") or item.get("alias"), audio, subs))
        return [s for s in out if s.key]

    def _release(self, show):
        if "release" not in show.extra:
            show.extra["release"] = net.jsonof(self.site + "/api/v1/anime/releases/" + quoted(show.key))
        return show.extra["release"]

    def episodes(self, show):
        return [number(e["ordinal"]) for e in self._release(show).get("episodes") or [] if e.get("ordinal") is not None]

    def servers(self, show, episode):
        for item in self._release(show).get("episodes") or []:
            if item.get("ordinal") is not None and number(item["ordinal"]) == episode:
                for height in ("1080", "720", "480"):
                    if item.get("hls_" + height):
                        return [("AniLiberty", Stream(item["hls_" + height], self.site + "/", height=int(height)))]
        return []


class Anime4up(Provider):
    id, name, site = "anime4up", "Anime4up", "https://w1.anime4up.rest"
    offers = (("ja", "ar"),)

    def search(self, query, audio, subs, season):
        page = net.text(self.site + "/?search_param=animes&s=" + quoted(query))
        out = []
        for slug, title in re.findall(r'<h3><a href="https://w1\.anime4up\.rest/anime/([^"/]+)/"[^>]*>([^<]+)', page):
            out.append(Show(self, slug, clean(title), audio, subs))
        if not out:
            for slug in dict.fromkeys(re.findall(r'href="https://w1\.anime4up\.rest/anime/([^"/]+)/"', page)):
                out.append(Show(self, slug, re.sub(r"-[a-z]{4,5}$", "", slug).replace("-", " "), audio, subs))
        return out

    def episodes(self, show):
        page = net.text(self.site + "/anime/%s/" % show.key)
        found = {}
        for link in re.findall(r'href="(https://w1\.anime4up\.rest/episode/[^"]+)"', page):
            n = re.search(r"%D8%AD%D9%84%D9%82%D8%A9-(\d+)", link, re.I)
            if n:
                found[str(int(n.group(1)))] = link
        show.extra["links"] = found
        return sorted(found, key=int)

    def servers(self, show, episode):
        if "links" not in show.extra:
            self.episodes(show)
        link = show.extra["links"].get(episode)
        if not link:
            return []
        page = net.text(link)
        return [(urllib.parse.urlsplit(u).hostname or "", html.unescape(u))
                for u in re.findall(r'<iframe[^>]+src="(https://[^"]+)"', page)
                if any(h in u for h in ("mp4upload.", "uqload.", "streamwish", "filelions", "vidmoly"))]


class WatchAnimeWorld(Provider):
    """One stream carries several dubs; mpv is told which to start with."""
    id, name, site = "watchanimeworld", "WatchAnimeWorld", "https://watchanimeworld.one"
    offers = (("hi", ""), ("ta", ""), ("te", ""), ("en", ""))
    burned = False
    TRACK = {"hi": "hin", "ta": "tam", "te": "tel", "en": "eng"}

    def search(self, query, audio, subs, season):
        page = net.text(self.site + "/?s=" + quoted(query))
        out = []
        for kind, slug in dict.fromkeys(re.findall(r'href="https://watchanimeworld\.one/(series|movies)/([a-z0-9-]+)/"', page)):
            out.append(Show(self, slug, slug.replace("-", " "), audio, subs, season, {"kind": kind}))
        return out

    def episodes(self, show):
        if show.extra.get("kind") == "movies":
            return ["1"]
        page = net.text(self.site + "/series/%s/" % show.key)
        post = re.search(r'data-post="(\d+)"', page)
        if post:  # the page lists its latest season; any other comes from their season picker
            page = net.text(self.site + "/wp-admin/admin-ajax.php", referer=self.site + "/",
                            data={"action": "action_select_season", "season": show.season, "post": post.group(1)})
        pattern = r'/episode/%s-%dx(\d+)/' % (re.escape(show.key), show.season)
        return sorted(set(re.findall(pattern, page)), key=int)

    def servers(self, show, episode):
        if show.extra.get("kind") == "movies":
            url = self.site + "/movies/%s/" % show.key
        else:
            url = self.site + "/episode/%s-%dx%s/" % (show.key, show.season, episode)
        page = net.text(url)
        return [("Multi-Audio", u) for u in re.findall(r'<iframe[^>]+(?:data-)?src="(https://play\.zephyrix\.org/video/[0-9a-f]+)"', page)]


ALL = [AnimeAV1(), Henaojara(), JKAnime(), AniWorld(), AnimeWorld(), AnimesDigital(), AnimeSama(), AniLiberty(),
       Anime4up(), WatchAnimeWorld()]
BY_ID = {p.id: p for p in ALL}


def offering(audio, subs):
    """Providers with exactly this (audio, subs) pair."""
    return [p for p in ALL if (audio, subs) in p.offers]


def languages():
    """Every (audio, subs) pair some provider offers, plus ani-cli's two."""
    pairs = {("ja", "en"), ("en", "")}
    for p in ALL:
        pairs.update(p.offers)
    return sorted(pairs)
