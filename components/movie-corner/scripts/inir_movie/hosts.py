"""Video hosts: an embed page in, a stream mpv can open out (or None).

The Corner reads only what any page states plainly: a direct m3u8/mp4, a <video> source, a frame around one. A
source file teaches it the rest: HOSTS [(text in the address, reader)] and PAGE_FILTERS [page -> page text to read
too], which sources.py adds here. Nothing a page sends is ever run.
"""

import html
import re
import urllib.parse

from . import net


class Stream:
    def __init__(self, url, referer, height=0, audio_lang="", sub_url="", sub_lang="", kind=""):
        self.url = url
        self.referer = referer
        self.height = height
        self.audio_lang = audio_lang
        self.sub_url = sub_url
        self.sub_lang = sub_lang
        self.kind = kind or ("hls" if ".m3u8" in url or "/hls" in url else "mp4")


HOSTS = []  # [(text in the address, reader(url, referer) -> Stream or None)], from the sources
PAGE_FILTERS = []  # [page -> text], from the sources

MEDIA = re.compile(r"""(https?:)?//[^\s"'<>\\]+?\.(?:m3u8|mp4)(?:\?[^\s"'<>\\]*)?""")


def origin(url):
    parts = urllib.parse.urlsplit(url)
    return "%s://%s/" % (parts.scheme, parts.netloc)


def _first_media(page):
    found = MEDIA.search(page)
    return net.https(found.group(0)) if found else None


def _filtered(page):
    for read in PAGE_FILTERS:
        try:
            found = _first_media(read(page))
        except Exception:  # a source's filter breaking only skips that reading
            found = None
        if found:
            return found
    return None


def player_page(url, referer, hops=1):
    """A page that names its stream (a jwplayer setup, a <video> source) or a frame around one: followed one frame
    deep, no further. Each PAGE_FILTERS reading of the page is tried first."""
    final, body = net.fetch(url, referer=referer)
    page = body.decode("utf-8", errors="replace")
    url = final  # a redirect lands on the host that wants to be the referer
    found = _filtered(page) or _first_media(page)
    if found:
        return Stream(found, origin(url))
    source = re.search(r'<source[^>]+src="(https://[^"]+)"[^>]*type="video/mp4"', page)
    if source:
        return Stream(html.unescape(source.group(1)), origin(url), kind="mp4")
    frame = re.search(r'<iframe[^>]+src="(https://[^"]+)"', page)
    if frame and hops > 0:
        return player_page(html.unescape(frame.group(1)), origin(url), hops - 1)
    return None


def resolve(url, referer=None):
    """The stream behind an embed, or None. Every failure is a None: one dead mirror never stops the others."""
    try:
        url = net.https(url)
    except net.Failed:
        return None
    for name, reader in HOSTS:
        if name in url:
            try:
                found = reader(url, referer)
            except Exception:  # a source's reader breaking is that source's problem, never the run's
                found = None
            if found:
                return found
    try:
        return player_page(url, referer)
    except net.Failed:
        return None
