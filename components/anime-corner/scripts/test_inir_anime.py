"""Offline checks of what the engine must never get wrong: python3 -I test_inir_anime.py"""

import os
import sys
import tempfile
import unittest
import urllib.request

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

from inir_anime import accounts, engine, hosts, net, providers, subs  # noqa: E402
from inir_anime.unpack import unpack  # noqa: E402


class Unpack(unittest.TestCase):
    def test_words_are_swapped_by_their_radix_number(self):
        packed = "}('0 1(\"2://3.4/5.6\")',36,7,'var|f|https|ok|ru|video|m3u8'.split('|'),0,{}))"
        self.assertEqual(unpack(packed), 'var f("https://ok.ru/video.m3u8")')

    def test_empty_slot_keeps_the_token(self):
        self.assertEqual(unpack("}('0 1',36,2,'|word'.split('|'),0,{}))"), "0 word")

    def test_nothing_packed_is_nothing(self):
        self.assertEqual(unpack("<html>plain</html>"), "")


class Hosts(unittest.TestCase):
    def test_streamtape_link_is_read_not_run(self):
        page = """document.getElementById('robotlink').innerHTML = '//streamtape.com/get_video?id=AB' + ('xyz&expires=1&token=t').substring(3);"""
        original = net.text
        net.text = lambda *a, **k: page
        try:
            stream = hosts.streamtape("https://streamtape.com/e/AB/", None)
        finally:
            net.text = original
        self.assertEqual(stream.url, "https://streamtape.com/get_video?id=AB&expires=1&token=t&stream=1")

    def test_only_https(self):
        self.assertEqual(net.https("//ok.ru/c"), "https://ok.ru/c")
        self.assertEqual(net.https("http://ok.ru/c"), "https://ok.ru/c")
        for bad in ("file:///srv/notes.txt", "ftp://ok.ru/c", "javascript:x", ""):
            with self.assertRaises(net.Failed):
                net.https(bad)
        self.assertIsNone(hosts.resolve("file:///srv/notes.txt"))


class Redirects(unittest.TestCase):
    def test_credentials_stay_on_their_host(self):
        handler = net._SameHost()
        request = urllib.request.Request("https://graphql.anilist.co/x", headers={"Authorization": "Bearer secret", "Api-Key": "k"})
        moved = handler.redirect_request(request, None, 302, "Found", {}, "https://animeav1.com/y")
        self.assertNotIn("Authorization", moved.headers)
        self.assertNotIn("Api-key", moved.headers)

    def test_no_redirect_off_https(self):
        handler = net._SameHost()
        request = urllib.request.Request("https://graphql.anilist.co/x")
        with self.assertRaises(net.Failed):
            handler.redirect_request(request, None, 302, "Found", {}, "http://graphql.anilist.co/y")


class Player(unittest.TestCase):
    def test_site_link_is_never_an_option(self):
        stream = hosts.Stream("--script=hook.lua", "https://ok.ru/")
        args = engine.player_args({"id": "animeav1"}, stream, "Show", "1", False, None, "es-419")
        self.assertEqual(args[-2:], ["--", "--script=hook.lua"])
        self.assertIn("--ytdl=no", args)

    def test_multi_audio_picks_the_dub(self):
        stream = hosts.Stream("https://ok.ru/master.m3u8", "https://ok.ru/")
        args = engine.player_args({"id": "watchanimeworld"}, stream, "Show", "2", False, None, "hi")
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
            engine.history("aniworld", "frieren", "Sousou no Frieren", "4")
            with open(path) as handle:
                lines = handle.read().splitlines()
            self.assertEqual(lines, ["3\tsomeid\tOther Show", "4\tinir-aniworld-frieren\tSousou no Frieren"])
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


if __name__ == "__main__":
    unittest.main()
