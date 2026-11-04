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

from inir_movie import addons, engine, net, providers, sources  # noqa: E402

class Engine(unittest.TestCase):
    def test_bad_ids_are_refused(self):
        for args in (["--imdb", "tt1; rm"], ["--tmdb", "12a"]):
            with self.assertRaises(SystemExit), redirect_stdout(io.StringIO()), mock.patch("sys.stderr", io.StringIO()):
                engine.sources(["--kind", "movie", "--title", "X", *args])

    def test_subtitled_and_sharper_sources_come_first(self):
        a = providers.Source("mysite", "A", "original", "https://video.example.com/a/1.m3u8", "https://video.example.com/a/", height=480,
                             subtitles=[{"lang": "Spanish", "url": "https://video.example.com/a/s"}])
        b = providers.Source("mysite", "B", "original", "https://video.example.com/b/1.m3u8", "https://video.example.com/b/", height=1080)
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
                         sources=lambda *_: [providers.Source("mysite", "A", "original", "https://video.example.com/a.m3u8", "")])
        with mock.patch.object(providers, "ALL", [site]), mock.patch.object(net, "jsonof", return_value=listed), \
                mock.patch.object(engine, "height_of", return_value=720):
            found = engine.find(item, "original", "de")
        self.assertEqual([t["lang"] for t in found[0].subtitles], ["German", "German"])

    def test_every_line_is_json(self):
        with mock.patch.object(engine, "find", return_value=[]), redirect_stdout(io.StringIO()) as out:
            engine.sources(["--kind", "series", "--title", "X", "-s", "2", "-e", "3"])
        rows = [json.loads(line) for line in out.getvalue().splitlines()]
        self.assertEqual(rows[-1], {"done": True, "count": 0})


class Sources(unittest.TestCase):
    def test_loads_what_works_and_says_what_doesnt(self):
        import tempfile
        files = {"good.py": "from inir_movie.sdk import Site\nclass Good(Site):\n    id, name, audios = 'good', 'Good', ('es-419',)\nSOURCES = [Good()]\n",
                 "broken.py": "import nothing_like_this\n"}
        with tempfile.TemporaryDirectory() as folder:
            for name, body in files.items():
                with open(os.path.join(folder, name), "w") as handle:
                    handle.write(body)
            with mock.patch.object(providers, "ALL", []), mock.patch.object(providers, "BY_ID", {}), \
                    mock.patch.object(addons, "saved", return_value=[]), mock.patch.object(sources, "LOADED", []):
                rows = {row["file"]: row for row in sources.load(folder)}
                self.assertEqual(rows["good.py"]["sources"], ["good"])
                self.assertIn("ModuleNotFoundError", rows["broken.py"]["error"])
                self.assertEqual(providers.languages(), {"es-419": ["good"]})


class Addons(unittest.TestCase):
    def test_check_wants_streams_by_imdb_id(self):
        url = "https://addon.example.com/manifest.json"
        with mock.patch.object(net, "jsonof", return_value={"name": "Mine", "resources": ["stream"], "idPrefixes": ["tt"]}):
            self.assertTrue(addons.check(url)["ok"])
        with mock.patch.object(net, "jsonof", return_value={"name": "Anime", "resources": ["stream"], "idPrefixes": ["kitsu"]}):
            self.assertFalse(addons.check(url)["ok"])
        self.assertFalse(addons.check("http://addon.example.com/manifest.json")["ok"])

    def test_episode_asked_by_imdb_season_and_episode(self):
        reply = {"streams": [{"name": "Mine", "url": "https://cdn.example.com/e.m3u8"}, {"infoHash": "abc"},
                             {"name": "Page", "externalUrl": "https://example.com/watch"}]}
        site = addons.Addon("addon-mine", "Mine", "https://addon.example.com", "original")
        with mock.patch.object(net, "jsonof", return_value=reply) as asked:
            found = site.sources({"kind": "series", "imdb": "tt0903747", "season": 2, "episode": 3}, "original", "")
        self.assertEqual(asked.call_args[0][0], "https://addon.example.com/stream/series/tt0903747:2:3.json")
        self.assertEqual([(s.url, s.site, s.audio) for s in found], [("https://cdn.example.com/e.m3u8", "addon-mine", "original")])
        self.assertEqual(site.sources({"kind": "movie", "imdb": "tt1; rm"}, "original", ""), [])


if __name__ == "__main__":
    unittest.main()
