"""What a site a film or an episode plays from looks like. The Corner ships none: they come from the person's
sources folder and from the Stremio add-ons they add (sources.py fills ALL). Each one turns what Cinemeta knows
(IMDb id, TMDB id, title, year, season, episode) into Sources, or nothing: one dead site never stops the others.
"""

import html
import re
import unicodedata



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
    probe_subs = ""  # the subtitles `doctor` asks it for with the original audio
    kind = "python"

    def sources(self, item, audio, subs):
        return []


# Subtitle languages by their English names (OpenSubtitles' own), by our codes.
SUB_NAMES = {"en": "English", "es": "Spanish", "pt-BR": "Portuguese", "pt": "Portuguese", "fr": "French", "de": "German", "it": "Italian",
             "ar": "Arabic", "ru": "Russian", "tr": "Turkish", "ja": "Japanese", "ko": "Korean", "zh": "Chinese",
             "hi": "Hindi", "id": "Indonesian", "vi": "Vietnamese", "pl": "Polish", "uk": "Ukrainian", "he": "Hebrew",
             "nl": "Dutch"}


ALL = []
BY_ID = {}


def add(found):
    """The sites joined, in order; an id already taken keeps its first owner."""
    added = []
    for site in found:
        if site.id and site.id not in BY_ID:
            ALL.append(site)
            BY_ID[site.id] = site
            added.append(site.id)
    return added


def languages():
    """Every audio language and the sites that have it."""
    out = {}
    for site in ALL:
        for audio in site.audios:
            out.setdefault(audio, []).append(site.id)
    return out
