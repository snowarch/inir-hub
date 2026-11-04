"""What a site the engine plays from looks like. The Corner ships none: they come from the person's sources
folder and from the Stremio add-ons they add (sources.py fills ALL).

A provider answers four questions: which of its shows match these titles in this language, which episodes a show
has, and where an episode's video sits (embed pages for hosts.resolve, or a ready Stream). Each language pair is
(audio, subtitles): ("es-419", "") is the Latin American dub, ("ja", "es") Japanese with Spanish subtitles burned in.
Sites change without warning; one that stops answering only drops out of the list, it never stops the others.
"""

import html
import re
import urllib.parse



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
    seasons_inside = False  # every season under one page: searched by the base title
    audio_tracks = {}  # one stream with several dubs: our audio code -> the track mpv starts with
    keep = ("kind",)  # Show.extra keys remembered with a match
    kind = "python"

    def by_id(self, meta, audio, subs, season):
        """Shows found by AniList's ids (meta: anilistId, malId) instead of by title; None to search by title."""
        return None

    def search(self, query, audio, subs, season):
        return []

    def episodes(self, show):
        return []

    def servers(self, show, episode):
        """[(server name, embed url or Stream)]"""
        return []


ALL = []
BY_ID = {}


def add(found):
    """The providers joined, in order; an id already taken keeps its first owner."""
    added = []
    for provider in found:
        if provider.id and provider.id not in BY_ID:
            ALL.append(provider)
            BY_ID[provider.id] = provider
            added.append(provider.id)
    return added


def offering(audio, subs):
    """Providers with exactly this (audio, subs) pair."""
    return [p for p in ALL if (audio, subs) in p.offers]


def languages():
    """Every (audio, subs) pair some provider offers, plus ani-cli's two."""
    pairs = {("ja", "en"), ("en", "")}
    for p in ALL:
        pairs.update(p.offers)
    return sorted(pairs)
