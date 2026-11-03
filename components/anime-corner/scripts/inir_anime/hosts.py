"""Video hosts: an embed page in, a stream mpv can open out (or None).

Hosts move between mirror domains every few weeks, so a page is recognised by what it carries (a packed player,
a jwplayer setup, a robotlink) rather than by its name; the names here only pick the right reading first.
"""

import html
import json
import re
import urllib.parse

from . import net
from .unpack import unpack


class Stream:
    def __init__(self, url, referer, height=0, audio_lang="", sub_url="", sub_lang="", kind=""):
        self.url = url
        self.referer = referer
        self.height = height
        self.audio_lang = audio_lang
        self.sub_url = sub_url
        self.sub_lang = sub_lang
        self.kind = kind or ("hls" if ".m3u8" in url or "/hls" in url else "mp4")


MEDIA = re.compile(r"""(https?:)?//[^\s"'<>\\]+?\.(?:m3u8|mp4)(?:\?[^\s"'<>\\]*)?""")


def _origin(url):
    parts = urllib.parse.urlsplit(url)
    return "%s://%s/" % (parts.scheme, parts.netloc)


def _first_media(page):
    found = MEDIA.search(page)
    return net.https(found.group(0)) if found else None


def player_page(url, referer, hops=1):
    """A jwplayer-style page, packed or not (StreamWish, FileLions, VidHide, Uqload, Vidmoly), a <video> page
    (Krakenfiles), or a frame around one (Filemoon): followed one frame deep, no further."""
    final, body = net.fetch(url, referer=referer)
    page = body.decode("utf-8", errors="replace")
    url = final  # a redirect (AniWorld's /redirect/<n>) lands on the host that wants to be the referer
    found = _first_media(unpack(page)) or _first_media(page)
    if found:
        return Stream(found, _origin(url))
    source = re.search(r'<source[^>]+src="(https://[^"]+)"[^>]*type="video/mp4"', page)
    if source:
        return Stream(html.unescape(source.group(1)), _origin(url), kind="mp4")
    frame = re.search(r'<iframe[^>]+src="(https://[^"]+)"', page)
    if frame and hops > 0:
        return player_page(html.unescape(frame.group(1)), _origin(url), hops - 1)
    return None


def mp4upload(url, referer):
    page = net.text(url, referer=referer)
    found = re.search(r'src:\s*"(https?://[^"]+\.mp4)"|"(https?://[^"]+/video\.mp4)"', page)
    return Stream(found.group(1) or found.group(2), "https://www.mp4upload.com/") if found else None


def yourupload(url, referer):
    page = net.text(url, referer=referer)
    found = re.search(r"file:\s*'(https?://[^']+)'", page)
    return Stream(found.group(1), "https://www.yourupload.com/") if found else None


def streamtape(url, referer):
    """The page writes the link as a literal plus a slice of a second literal; both are read, nothing is run."""
    page = net.text(url, referer=referer)
    found = re.search(r"""getElementById\('(?:robotlink|ideoooolink)'\)\.innerHTML\s*=\s*['"]([^'"]+)['"]\s*\+\s*\(?['"]([^'"]+)['"]\)?((?:\.substring\(\d+\))*)""", page)
    if not found:
        return None
    tail = found.group(2)
    for cut in re.findall(r"\.substring\((\d+)\)", found.group(3)):
        tail = tail[int(cut):]
    return Stream(net.https(found.group(1) + tail) + "&stream=1", "https://streamtape.com/", kind="mp4")


def okru(url, referer):
    page = net.text(url.replace("/video/", "/videoembed/"), referer=referer)
    found = re.search(r'data-options="([^"]+)"', page)
    if not found:
        return None
    try:
        options = json.loads(html.unescape(found.group(1)))
        metadata = json.loads(options["flashvars"]["metadata"])
    except (ValueError, KeyError, TypeError):
        return None
    if metadata.get("hlsManifestUrl"):
        return Stream(metadata["hlsManifestUrl"], "https://ok.ru/")
    order = ["mobile", "lowest", "low", "sd", "hd", "full", "quad", "ultra"]
    videos = sorted(metadata.get("videos") or [], key=lambda v: order.index(v["name"]) if v.get("name") in order else -1)
    return Stream(videos[-1]["url"], "https://ok.ru/", kind="mp4") if videos else None


def fireplayer(url, referer):
    """FirePlayer hands its stream to the page it embeds in, over a small POST."""
    found = re.search(r"/video/([0-9a-f]{16,64})", url)
    if not found:
        return None
    origin = _origin(url)
    reply = net.jsonof(origin + "player/index.php?data=%s&do=getVideo" % found.group(1), referer=origin,
                       data={"hash": found.group(1), "r": referer or ""}, headers={"X-Requested-With": "XMLHttpRequest"})
    link = reply.get("securedLink") or reply.get("videoSource")
    return Stream(net.https(link), origin) if link else None


HOSTS = [
    ("mp4upload.", mp4upload),
    ("yourupload.", yourupload),
    ("streamtape.", streamtape),
    ("ok.ru/", okru),
    ("zephyrix.", fireplayer),
]


def resolve(url, referer=None):
    """The stream behind an embed, or None. Every failure is a None: one dead mirror never stops the others."""
    try:
        url = net.https(url)
    except net.Failed:
        return None
    # Uqload's short /e/<code> page is a form; its embed page is the player.
    short = re.match(r"^(https://[^/]*uqload\.[a-z]+)/e/([a-z0-9]+)$", url)
    if short:
        url = "%s/embed-%s.html" % short.groups()
    try:
        for name, reader in HOSTS:
            if name in url:
                return reader(url, referer)
        return player_page(url, referer)
    except net.Failed:
        return None
