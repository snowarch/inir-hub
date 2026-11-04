"""Offline checks of what the engine must never get wrong: python3 -I test_inir_anime.py"""

import os
import sys
import tempfile
import unittest
import urllib.request

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

from inir_anime import accounts, addons, engine, hosts, net, providers, sources, subs  # noqa: E402


class Hosts(unittest.TestCase):
    def test_only_https(self):
        self.assertEqual(net.https("//video.example.com/c"), "https://video.example.com/c")
        self.assertEqual(net.https("http://video.example.com/c"), "https://video.example.com/c")
        for bad in ("file:///srv/notes.txt", "ftp://video.example.com/c", "javascript:x", ""):
            with self.assertRaises(net.Failed):
                net.https(bad)
        self.assertIsNone(hosts.resolve("file:///srv/notes.txt"))


class Redirects(unittest.TestCase):
    def test_credentials_stay_on_their_host(self):
        handler = net._SameHost()
        request = urllib.request.Request("https://graphql.anilist.co/x", headers={"Authorization": "Bearer secret", "Api-Key": "k"})
        moved = handler.redirect_request(request, None, 302, "Found", {}, "https://example.com/y")
        self.assertNotIn("Authorization", moved.headers)
        self.assertNotIn("Api-key", moved.headers)

    def test_no_redirect_off_https(self):
        handler = net._SameHost()
        request = urllib.request.Request("https://graphql.anilist.co/x")
        with self.assertRaises(net.Failed):
            handler.redirect_request(request, None, 302, "Found", {}, "http://graphql.anilist.co/y")


class Player(unittest.TestCase):
    def test_site_link_is_never_an_option(self):
        stream = hosts.Stream("--script=hook.lua", "https://video.example.com/")
        args = engine.player_args({"id": "some-site"}, stream, "Show", "1", False, None, "es-419")
        self.assertEqual(args[-2:], ["--", "--script=hook.lua"])
        self.assertIn("--ytdl=no", args)

    def test_multi_audio_picks_the_dub(self):
        class Multi(providers.Provider):
            id, audio_tracks = "multi", {"hi": "hin"}
        providers.add([Multi()])
        stream = hosts.Stream("https://video.example.com/master.m3u8", "https://video.example.com/")
        args = engine.player_args({"id": "multi"}, stream, "Show", "2", False, None, "hi")
        self.assertIn("--alang=hin", args)
        self.assertIn("--force-media-title=Show Episode 2", args)


class Arguments(unittest.TestCase):
    def test_empty_subtitles_do_not_swallow_the_next_flag(self):
        seen = {}
        original = engine.Run
        class Stop(Exception):
            pass
        def fake(audio, subs, source, quality, meta, query):
            seen.update(audio=audio, subs=subs, source=source, query=query)
            raise Stop()
        class Latino(providers.Provider):
            id, offers = "latino", (("es-419", ""),)
        providers.add([Latino()])
        engine.Run = fake
        try:
            with self.assertRaises(Stop):
                engine.main(["--audio=es-419", "--subs=", "--source=ask", "-e", "1", "Frieren"])
        finally:
            engine.Run = original
        self.assertEqual(seen, {"audio": "es-419", "subs": "", "source": "ask", "query": "Frieren"})


class Matching(unittest.TestCase):
    def test_season_from_titles(self):
        self.assertEqual(engine.season_of(["Sousou no Frieren 2nd Season"]), 2)
        self.assertEqual(engine.season_of(["Attack on Titan Season 3"]), 3)
        self.assertEqual(engine.season_of(["Frieren"]), 1)
        self.assertEqual(engine.season_of(["Mob Psycho 100"]), 1)

    def test_scores_prefer_the_same_show(self):
        wanted = ["Sousou no Frieren", "Frieren: Beyond Journey's End"]
        self.assertGreater(engine.score("Frieren: Beyond Journey's End", wanted), 0.95)
        self.assertLess(engine.score("Black Clover", wanted), 0.5)

    def test_every_pair_has_a_site(self):
        for audio, subs in providers.languages():
            if (audio, subs) not in (("ja", "en"), ("en", "")):
                self.assertTrue(providers.offering(audio, subs), (audio, subs))


class History(unittest.TestCase):
    def test_one_line_per_title_written_whole(self):
        with tempfile.TemporaryDirectory() as folder:
            os.environ["ANI_CLI_HIST_DIR"] = folder
            path = os.path.join(folder, "ani-hsts")
            with open(path, "w") as handle:
                handle.write("3\tsomeid\tOther Show\n2\tav1-frieren\tSousou no Frieren\n")
            engine.history("mysite", "frieren", "Sousou no Frieren", "4")
            with open(path) as handle:
                lines = handle.read().splitlines()
            self.assertEqual(lines, ["3\tsomeid\tOther Show", "4\tinir-mysite-frieren\tSousou no Frieren"])
            self.assertEqual(os.listdir(folder), ["ani-hsts"])


class Subtitles(unittest.TestCase):
    def _zip(self, files):
        import io
        import zipfile
        data = io.BytesIO()
        with zipfile.ZipFile(data, "w", zipfile.ZIP_DEFLATED) as archive:
            for name, body in files:
                archive.writestr(name, body)
        return data.getvalue()

    def test_zip_paths_are_flattened(self):
        with tempfile.TemporaryDirectory() as folder:
            path = subs.unpack_zip(self._zip([("../../evil/../x.srt", "1\n00:00:01,000 --> 00:00:02,000\nhola\n")]), folder)
            self.assertEqual(os.path.dirname(path), folder)
            self.assertEqual(os.listdir(folder), ["x.srt"])

    def test_zip_bomb_and_strays_are_refused(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaises(net.Failed):
                subs.unpack_zip(self._zip([("a.srt", "0" * (subs.ZIP_MAX + 1))]), folder)
            with self.assertRaises(net.Failed):
                subs.unpack_zip(self._zip([("run.sh", "echo not a subtitle")]), folder)
            with self.assertRaises(net.Failed):
                subs.unpack_zip(b"not a zip", folder)
            self.assertEqual(os.listdir(folder), [])

    def test_names_stay_names(self):
        self.assertEqual(subs._safe_name("/srv/outside/name"), "name")
        self.assertEqual(subs._safe_name("..\\..\\x.ass"), "x.ass")
        self.assertEqual(subs._safe_name("../.."), "subtitle.srt")

    def test_no_key_no_request(self):
        os.environ.pop("INIR_OPENSUBTITLES_KEY", None)
        os.environ.pop("INIR_SUBDL_KEY", None)
        found = subs.search("Frieren", 1, 1, ["es"])
        self.assertEqual(found["results"], [])
        self.assertEqual(len(found["notes"]), 2)


class MalLogin(unittest.TestCase):
    def test_listener_takes_only_its_own_state_on_loopback(self):
        import threading
        import urllib.error
        import urllib.parse
        opened, result = [], {}
        exchange = accounts._mal_exchange
        accounts._mal_exchange = lambda fields: {"access": "a", "refresh": "r", "expires": 1, "code": fields["code"],
                                                  "verifier": fields["code_verifier"]}
        try:
            worker = threading.Thread(target=lambda: result.update(accounts.mal_login("client", opened.append, wait=20)))
            worker.start()
            for _ in range(100):
                if opened:
                    break
                worker.join(0.05)
            query = urllib.parse.parse_qs(urllib.parse.urlsplit(opened[0]).query)
            self.assertEqual(query["code_challenge_method"], ["plain"])
            self.assertEqual(query["redirect_uri"], [accounts.MAL_REDIRECT])
            local = accounts.MAL_REDIRECT + "?"
            with self.assertRaises(urllib.error.HTTPError):
                urllib.request.urlopen(local + "code=stolen&state=wrong", timeout=5)
            urllib.request.urlopen(local + urllib.parse.urlencode({"code": "good", "state": query["state"][0]}), timeout=5)
            worker.join(10)
        finally:
            accounts._mal_exchange = exchange
        self.assertEqual(result["code"], "good")
        self.assertEqual(result["verifier"], query["code_challenge"][0])


class Sources(unittest.TestCase):
    """The person's files: one that breaks never stops the rest, and a file can't stand in for Python's own."""

    FILES = {
        "_shared.py": "from inir_anime.sdk import Stream\nHOSTS = [('cdn.example.com', lambda url, ref: Stream(url + '#read', ref))]\n",
        "good.py": "import _shared\nfrom inir_anime.sdk import Provider\n"
                   "class Good(Provider):\n    id, name, offers = 'good', 'Good', (('es-419', ''),)\nSOURCES = [Good()]\n",
        "broken.py": "SOURCES = [1 / 0]\n",
        "empty.py": "x = 1\n",
        "json.py": "SOURCES = []\n",
    }

    def test_loads_what_works_and_says_what_doesnt(self):
        with tempfile.TemporaryDirectory() as folder:
            for name, body in self.FILES.items():
                with open(os.path.join(folder, name), "w") as handle:
                    handle.write(body)
            saved = list(providers.ALL), dict(providers.BY_ID), list(hosts.HOSTS)
            os.environ["XDG_CONFIG_HOME"] = folder  # no add-ons saved there
            try:
                rows = {row["file"]: row for row in sources.load(folder)}
                self.assertEqual(rows["good.py"]["sources"], ["good"])
                self.assertIn("ZeroDivisionError", rows["broken.py"]["error"])
                self.assertEqual(rows["empty.py"]["error"], "no SOURCES in it")
                self.assertIn("rename", rows["json.py"]["error"])
                self.assertNotIn("_shared.py", rows)
                self.assertIn(providers.BY_ID["good"], providers.offering("es-419", ""))
                self.assertTrue(hosts.resolve("https://cdn.example.com/v.m3u8").url.endswith("#read"))
            finally:
                providers.ALL[:], hosts.HOSTS[:] = saved[0], saved[2]
                providers.BY_ID.clear()
                providers.BY_ID.update(saved[1])
                sources.LOADED.clear()


class Addons(unittest.TestCase):
    def _with(self, replies, work):
        original = net.jsonof
        net.jsonof = lambda url, **kw: replies[url]
        try:
            return work()
        finally:
            net.jsonof = original

    def test_only_manifest_addresses_over_https(self):
        self.assertEqual(addons.base_of("https://addon.example.com/x/manifest.json"), "https://addon.example.com/x")
        for bad in ("http://addon.example.com/manifest.json", "https://addon.example.com/", "file:///manifest.json",
                    "https://a.example.com/manifest.json?x=1", ""):
            self.assertIsNone(addons.base_of(bad), bad)

    def test_check_wants_streams_by_kitsu_id(self):
        url = "https://addon.example.com/manifest.json"
        good = {url: {"name": "Mine", "resources": ["stream"], "types": ["anime"], "idPrefixes": ["kitsu"]}}
        self.assertEqual(self._with(good, lambda: addons.check(url))["name"], "Mine")
        imdb = {url: {"name": "Films", "resources": [{"name": "stream"}], "idPrefixes": ["tt"]}}
        self.assertFalse(self._with(imdb, lambda: addons.check(url))["ok"])
        catalog = {url: {"name": "List", "resources": ["catalog"]}}
        self.assertFalse(self._with(catalog, lambda: addons.check(url))["ok"])

    def test_streams_keep_https_links_only(self):
        base = "https://addon.example.com"
        reply = {base + "/stream/anime/kitsu:7:3.json": {"streams": [
            {"name": "Mine", "title": "1080p\nmore", "url": "https://cdn.example.com/3.m3u8",
             "behaviorHints": {"proxyHeaders": {"request": {"Referer": "https://cdn.example.com/"}}}},
            {"name": "Torrent", "infoHash": "abc"},
            {"name": "Page", "externalUrl": "https://example.com/watch"},
            {"name": "Plain", "url": "http://cdn.example.com/3.mp4"},
        ]}}
        addon = addons.Addon("addon-mine", "Mine", base, ["anime"], "ja", "")
        show = providers.Show(addon, "7", "Show", "ja", "", 1, {"count": 12, "movie": False})
        found = self._with(reply, lambda: addon.servers(show, "3"))
        self.assertEqual([(n, s.url, s.referer) for n, s in found],
                         [("Mine · 1080p", "https://cdn.example.com/3.m3u8", "https://cdn.example.com/")])
        self.assertEqual(addon.episodes(show)[-1], "12")

    def test_kitsu_id_from_anilist(self):
        query = "filter%5BexternalSite%5D=anilist%2Fanime&filter%5BexternalId%5D=154587&include=item"
        reply = {addons.KITSU + "/mappings?" + query: {"included": [
            {"type": "anime", "id": "46474", "attributes": {"episodeCount": 28, "subtype": "TV", "canonicalTitle": "Frieren"}}]}}
        self.assertEqual(self._with(reply, lambda: addons.kitsu_of({"anilistId": 154587})), ("46474", 28, False, "Frieren"))

    def test_saved_addons_get_stable_ids(self):
        with tempfile.TemporaryDirectory() as folder:
            path = os.path.join(folder, "anime-corner.json")
            with open(path, "w") as handle:
                handle.write('{"addons": [{"url": "https://a.example.com/manifest.json", "name": "My Add-on", "audio": "es-419"},'
                             '{"url": "https://b.example.com/manifest.json", "name": "My Add-on"}, {"url": "nope"}]}')
            found = addons.saved(path)
        self.assertEqual([a.id for a in found], ["addon-my-add-on", "addon-my-add-on-2"])
        self.assertEqual(found[0].offers, (("es-419", ""),))


if __name__ == "__main__":
    unittest.main()
