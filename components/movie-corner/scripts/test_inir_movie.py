#!/usr/bin/env python3
"""Offline checks for the Movie Corner's engine: python3 -I scripts/test_inir_movie.py"""

import io
import json
import os
import sys
import unittest
from contextlib import redirect_stdout
from unittest import mock

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

from inir_movie import engine, hosts, net, providers  # noqa: E402

SEARCH = """
<article class="post movies"><h2 class="entry-title">El Origen</h2><span class="year">2010</span>
<a href="https://magistv24.com/pelicula/el-origen/" class="lnk-blk"></a></article>
<article class="post movies"><h2 class="entry-title">Otra</h2><span class="year">1999</span>
<a href="https://magistv24.com/pelicula/otra/" class="lnk-blk"></a></article>
"""
PAGE = """
<div id="options-0" class="video"><iframe src="https://magistv24.com/?trembed=0&#038;trid=1&trtype=1"></iframe></div>
<div id="options-1" class="video"><iframe data-src="https://magistv24.com/?trembed=1&#038;trid=1&trtype=1"></iframe></div>
<a class="btn on" href="#options-0">Opcion <span>1</span> <span class="server"> -Latino </span></a>
<a class="btn" href="#options-1">Opcion <span>2</span> <span class="server">
-Castellano </span></a>
"""


class MagisTV(unittest.TestCase):
    def pages(self, url, **kw):
        if "?s=" in url:
            return SEARCH
        if url.endswith("/pelicula/el-origen/"):
            return "<h1>El Origen</h1><span>Inception</span>" + PAGE
        if "trembed=1" in url:
            return '<IFRAME SRC="https://fastream.to/embed-castellano.html">'
        if "trembed=0" in url:
            return '<IFRAME SRC="https://fastream.to/embed-latino.html">'
        raise net.Failed("unexpected " + url)

    def test_each_language_plays_its_own_option(self):
        item = {"kind": "movie", "title": "Inception", "year": "2010", "season": 0, "episode": 0}
        seen = []
        with mock.patch.object(net, "text", side_effect=self.pages), \
                mock.patch.object(hosts, "resolve", side_effect=lambda url, ref: seen.append(url) or hosts.Stream("https://fastream.to/hls/" + url[-20:] + ".m3u8", ref)):
            latino = providers.MagisTV().sources(item, "es-419", "")
            spain = providers.MagisTV().sources(item, "es-ES", "")
            none = providers.MagisTV().sources(item, "original", "en")
        self.assertEqual([s.audio for s in latino], ["es-419"])
        self.assertEqual([s.audio for s in spain], ["es-ES"])
        self.assertEqual(none, [])  # VOSE only answers Spanish subtitles
        self.assertEqual(seen, ["https://fastream.to/embed-latino.html", "https://fastream.to/embed-castellano.html"])

    def test_a_title_of_another_year_is_not_taken(self):
        item = {"kind": "movie", "title": "Otra", "year": "2020", "season": 0, "episode": 0}
        with mock.patch.object(net, "text", side_effect=self.pages):
            self.assertIsNone(providers.MagisTV()._find(item))


class Engine(unittest.TestCase):
    def test_bad_ids_are_refused(self):
        for args in (["--imdb", "tt1; rm"], ["--tmdb", "12a"]):
            with self.assertRaises(SystemExit), redirect_stdout(io.StringIO()), mock.patch("sys.stderr", io.StringIO()):
                engine.sources(["--kind", "movie", "--title", "X", *args])

    def test_subtitled_and_sharper_sources_come_first(self):
        a = providers.Source("vidsrc", "A", "original", "https://vidsrc.buzz/a/1.m3u8", "https://vidsrc.buzz/a/", height=480,
                             subtitles=[{"lang": "Spanish", "url": "https://vidsrc.buzz/a/s"}])
        b = providers.Source("vidsrc", "B", "original", "https://vidsrc.buzz/b/1.m3u8", "https://vidsrc.buzz/b/", height=1080)
        with mock.patch.object(providers, "ALL", [mock.Mock(audios=("original",), id="x", sources=lambda *_: [b, a])]), \
                mock.patch.object(engine, "height_of", side_effect=lambda s: s.height):
            found = engine.find({}, "original", "es")
        self.assertEqual([s.name for s in found], ["A", "B"])

    def test_opensubtitles_fill_a_missing_language(self):
        listed = {"subtitles": [
            {"lang": "ger", "url": "https://subs5.strem.io/de/cam", "releaseFormat": "Cam"},
            {"lang": "ger", "url": "https://subs5.strem.io/de/bluray"},
            {"lang": "ger", "url": "https://www.imdb.com/de"},
            {"lang": "eng", "url": "https://subs5.strem.io/en"}]}
        item = {"kind": "series", "imdb": "tt0903747", "season": 2, "episode": 3}
        with mock.patch.object(net, "jsonof", return_value=listed) as asked:
            got = engine.opensubs(item, "de")
        self.assertIn("/series/tt0903747:2:3.json", asked.call_args[0][0])
        self.assertEqual([t["url"] for t in got], ["https://subs5.strem.io/de/bluray", "https://subs5.strem.io/de/cam"])
        self.assertEqual(engine.opensubs(dict(item, imdb="tt1; rm"), "de"), [])
        site = mock.Mock(audios=("original",), id="x",
                         sources=lambda *_: [providers.Source("vidsrc", "A", "original", "https://vidsrc.buzz/a.m3u8", "")])
        with mock.patch.object(providers, "ALL", [site]), mock.patch.object(net, "jsonof", return_value=listed), \
                mock.patch.object(engine, "height_of", return_value=720):
            found = engine.find(item, "original", "de")
        self.assertEqual([t["lang"] for t in found[0].subtitles], ["German", "German"])

    def test_every_line_is_json(self):
        with mock.patch.object(engine, "find", return_value=[]), redirect_stdout(io.StringIO()) as out:
            engine.sources(["--kind", "series", "--title", "X", "-s", "2", "-e", "3"])
        rows = [json.loads(line) for line in out.getvalue().splitlines()]
        self.assertEqual(rows[-1], {"done": True, "count": 0})


if __name__ == "__main__":
    unittest.main()
