"""The run: find the show on every site of the chosen language, ask what to play, play it, ask what next.

It speaks ani-cli's side of the conversation iNiR's inir-ani sets up (the menu at ANI_CLI_MENU, the player at
ANI_CLI_PLAYER, the ani-hsts history, the same last words on failure), so AnimeWatch drives it as it drives ani-cli.
"""

import difflib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unicodedata

from . import hosts, net, providers

ANICLI = "anicli"
SEASON = re.compile(r"(?:\b(\d+)(?:st|nd|rd|th)\s+season\b|\bseason\s+(\d+)\b|\b(\d+)\s*$|\bpart\s+(\d+)\b)", re.I)


def die(message):
    print(message, file=sys.stderr)
    sys.exit(1)


def key(text):
    text = unicodedata.normalize("NFKD", str(text or "")).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", " ", text.lower()).strip()


def season_of(titles):
    """shortcut: the season is read from AniList's titles ("2nd Season", "Season 2", "... 2"); a show that numbers
    its seasons any other way plays season 1 on sites that keep every season under one page. Improve with AniList's
    relations if it shows up wrong."""
    for title in titles:
        found = SEASON.search(str(title))
        if found:
            value = int(next(g for g in found.groups() if g))
            if 1 < value < 30:
                return value
    return 1


def base_title(title):
    return SEASON.sub("", str(title)).strip(" :-")


def score(candidate, wanted):
    have = key(candidate)
    return max((difflib.SequenceMatcher(None, have, key(w)).ratio() for w in wanted if key(w)), default=0.0)


def ask(prompt, lines):
    """ani-cli's nth: a lone choice is taken unasked; the answer's first word is returned."""
    if len(lines) == 1:
        return lines[0].split(" ", 1)[0]
    menu = os.environ.get("ANI_CLI_MENU", "rofi")
    reply = subprocess.run([menu, "-p", prompt], input="\n".join(lines) + "\n",
                           capture_output=True, text=True).stdout.strip()
    return reply.split(" ", 1)[0] if reply else ""


def height_of(stream):
    """The best picture a stream offers, from its HLS master playlist; 0 when it doesn't say."""
    if stream.height or stream.kind != "hls":
        return stream.height
    try:
        playlist = net.fetch(stream.url, referer=stream.referer, limit=512 * 1024, timeout=8)[1].decode(errors="replace")
    except net.Failed:
        return -1
    if "#EXTM3U" not in playlist:
        return -1
    heights = [int(h) for h in re.findall(r"RESOLUTION=\d+x(\d+)", playlist)]
    stream.height = max(heights) if heights else 0
    return stream.height


def checked(stream):
    """The stream with its height when it answers, None when it doesn't."""
    if stream is None:
        return None
    if stream.kind == "hls":
        return stream if height_of(stream) >= 0 else None
    return stream if net.alive(stream.url, stream.referer) else None


def anilist_titles(query, anilist_id=0):
    """The other names AniList knows a show by (romaji, English, synonyms) and its MAL id: the sites file shows
    under any of them. By id when the Corner knows it, else by search. {} when AniList doesn't answer."""
    if anilist_id:
        body = json.dumps({"query": "query($i:Int){Media(id:$i,type:ANIME){idMal title{romaji english} synonyms}}",
                           "variables": {"i": int(anilist_id)}}).encode()
    else:
        body = json.dumps({"query": "query($q:String){Media(search:$q,type:ANIME){idMal title{romaji english} synonyms}}",
                           "variables": {"q": query}}).encode()
    try:
        reply = json.loads(net.fetch("https://graphql.anilist.co", data=body, timeout=8,
                                     headers={"Content-Type": "application/json", "Accept": "application/json"})[1])
        media = (reply.get("data") or {}).get("Media") or {}
    except (net.Failed, ValueError, AttributeError):
        return {}
    names = [media.get("title", {}).get("romaji"), media.get("title", {}).get("english"), *(media.get("synonyms") or [])]
    return {"titles": [n for n in names if n and n.isascii()][:6], "malId": media.get("idMal")}


class Cache:
    """Which show each site files a title under, so the next run (or episode) skips the search. A week at most."""

    WEEK = 7 * 24 * 3600
    DAY = 24 * 3600
    NONE = object()

    def __init__(self):
        folder = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"), "inir-anime")
        self.path = os.path.join(folder, "matches.json")
        try:
            with open(self.path) as handle:
                self.data = json.load(handle)
            if not isinstance(self.data, dict):
                self.data = {}
        except (OSError, ValueError):
            self.data = {}

    @staticmethod
    def _key(provider_id, audio, subs, season, title):
        return "|".join([provider_id, audio, subs, str(season), key(title)])

    def show(self, provider, audio, subs, season, title):
        import time
        entry = self.data.get(self._key(provider.id, audio, subs, season, title))
        if not isinstance(entry, dict) or time.time() - float(entry.get("at", 0)) > self.WEEK:
            return None
        if entry.get("none"):
            return self.NONE if time.time() - float(entry.get("at", 0)) < self.DAY else None
        return providers.Show(provider, str(entry.get("key")), str(entry.get("title")), audio, subs, season,
                              {k: v for k, v in (entry.get("extra") or {}).items() if k in ("kind",)})

    def titles(self, query):
        import time
        entry = self.data.get("titles|" + key(query))
        if isinstance(entry, dict) and time.time() - float(entry.get("at", 0)) < self.WEEK:
            return entry.get("found") or {}
        return None

    def keep_titles(self, query, found):
        import time
        self.data["titles|" + key(query)] = {"found": found, "at": time.time()}
        self._save()

    def lack(self, provider, audio, subs, season, title):
        import time
        self.data[self._key(provider.id, audio, subs, season, title)] = {"none": True, "at": time.time()}
        self._save()

    def keep(self, show, title):
        import time
        self.data[self._key(show.provider.id, show.audio, show.subs, show.season, title)] = {
            "key": show.key, "title": show.title, "at": time.time(),
            "extra": {k: v for k, v in show.extra.items() if k in ("kind",)}}
        self._save()

    def _save(self):
        import time
        now = time.time()
        self.data = {k: v for k, v in self.data.items() if isinstance(v, dict) and now - float(v.get("at", 0)) < self.WEEK}
        try:
            os.makedirs(os.path.dirname(self.path), exist_ok=True)
            handle, staging = tempfile.mkstemp(dir=os.path.dirname(self.path))
            with os.fdopen(handle, "w") as out:
                json.dump(self.data, out)
            os.replace(staging, self.path)
        except OSError:
            pass


class Run:
    def __init__(self, audio, subs, source, quality, meta, query):
        self.audio = audio
        self.subs = subs
        self.source = source
        self.quality = quality
        self.meta = meta
        self.query = query
        self.cache = Cache()
        titles = [t for t in (meta.get("titles") or []) if t]
        if not meta.get("malId"):
            anilist_id = int(meta.get("anilistId") or 0)
            asked = "id:%d" % anilist_id if anilist_id else query
            found = self.cache.titles(asked)
            if found is None:
                found = anilist_titles(query, anilist_id)
                if found:
                    self.cache.keep_titles(asked, found)
            titles += (found or {}).get("titles", [])
            meta.setdefault("malId", (found or {}).get("malId"))
        self.titles = list(dict.fromkeys([query] + titles))
        self.season = int(meta.get("season") or 0) or season_of(self.titles)

    # Finding the show
    def _search(self, provider):
        known = self.cache.show(provider, self.audio, self.subs, self.season, self.titles[0])
        if known is Cache.NONE:
            return []
        if known:
            return [(1.0, known)]
        seasons_inside = provider.id in ("aniworld", "animesama", "watchanimeworld")
        wanted = [base_title(t) for t in self.titles] if seasons_inside else self.titles
        found = []
        for title in list(dict.fromkeys(wanted))[:3]:
            try:
                found = provider.search(title, self.audio, self.subs, self.season)
            except (net.Failed, KeyError, IndexError, TypeError, ValueError):
                found = []
            if found:
                break
        return sorted(((score(s.title, wanted), s) for s in found), key=lambda pair: -pair[0])

    def shows(self):
        """{provider id: show}: each site's best match, or the one the person picks when none is sure."""
        wanted = [p for p in providers.offering(self.audio, self.subs)
                  if self.source in ("ask", "auto", ANICLI) or p.id == self.source] or providers.offering(self.audio, self.subs)
        # With a site already known for this title, a slow one gets a few seconds, not the full wait.
        known = any(isinstance(self.cache.show(p, self.audio, self.subs, self.season, self.titles[0]), providers.Show)
                    for p in wanted)
        results = dict(zip([p.id for p in wanted], net.parallel(self._search, wanted, 5 if known else 15)))
        for provider in wanted:
            if results.get(provider.id) == []:  # answered, and has nothing: don't ask again for a day
                self.cache.lack(provider, self.audio, self.subs, self.season, self.titles[0])
        results = {pid: found for pid, found in results.items() if found}
        sure = {pid: found[0][1] for pid, found in results.items() if found[0][0] >= 0.82}
        if sure:
            for show in sure.values():
                self.cache.keep(show, self.titles[0])
            return sure
        loose = [(s, show) for found in results.values() for s, show in found if s >= 0.45]
        loose.sort(key=lambda pair: -pair[0])
        if not loose:
            return {}
        if os.environ.get("INIR_ANI_EXPECT"):
            return {loose[0][1].provider.id: loose[0][1]}
        loose = loose[:20]
        picked = ask("Select anime: ", ["%d %s · %s" % (i + 1, show.title, show.provider.name) for i, (_, show) in enumerate(loose)])
        if not picked.isdigit() or not 0 < int(picked) <= len(loose):
            die("Invalid anime selection")
        show = loose[int(picked) - 1][1]
        self.cache.keep(show, self.titles[0])
        return {show.provider.id: show}

    def episodes(self, shows):
        def listed(show):
            try:
                return show.provider.episodes(show)
            except (net.Failed, KeyError, IndexError, TypeError, ValueError):
                return []
        lists = dict(zip(shows, net.parallel(listed, shows.values(), 15)))
        return {pid: eps for pid, eps in lists.items() if eps}

    # Finding the video
    def options(self, shows, episodes, episode):
        """[(label json, Stream)] for this episode, best picture first."""
        jobs = []
        for pid, show in shows.items():
            if episode in episodes.get(pid, []):
                jobs.append(show)

        def servers(show):
            try:
                return [(show, name, target) for name, target in show.provider.servers(show, episode)]
            except (net.Failed, KeyError, IndexError, TypeError, ValueError):
                return []

        found = [item for group in net.parallel(servers, jobs, 15) for item in group or []]

        def stream(item):
            show, name, target = item
            got = target if isinstance(target, hosts.Stream) else hosts.resolve(target, show.provider.site + "/")
            return show, name, checked(got)

        out = []
        for done in net.parallel(stream, found, 15):
            if done is None or done[2] is None:
                continue
            show, name, got = done
            provider = show.provider
            label = {"provider": provider.name, "id": provider.id, "server": name, "audio": show.audio,
                     "subs": show.subs, "burned": bool(show.subs) and provider.burned, "height": max(got.height, 0)}
            out.append((label, got))
        out.sort(key=lambda pair: (-pair[0]["height"], [p.id for p in providers.ALL].index(pair[0]["id"])))
        return out

    def choose(self, options, episode):
        """The option to play: asked, the default site's best, or simply the best."""
        if self.source not in ("ask", "auto", ANICLI):
            mine = [o for o in options if o[0]["id"] == self.source]
            if mine:
                return mine[0]
            print("%s has no episode %s, playing another source" % (providers.BY_ID[self.source].name, episode), file=sys.stderr)
        if self.source != "ask" or len(options) == 1:
            if self.quality not in ("best", ""):
                fits = [o for o in options if str(o[0]["height"]) == self.quality]
                if fits:
                    return fits[0]
            return options[0]
        lines = ["%d %s" % (i + 1, json.dumps(label, ensure_ascii=False)) for i, (label, _) in enumerate(options)]
        picked = ask("Select source: ", lines)
        if not picked.isdigit() or not 0 < int(picked) <= len(options):
            die("No source selected")
        return options[int(picked) - 1]


def history(provider, slug, title, episode):
    directory = os.environ.get("ANI_CLI_HIST_DIR") or os.path.join(
        os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state"), "ani-cli")
    os.makedirs(directory, exist_ok=True)
    path = os.path.join(directory, "ani-hsts")
    entry = "inir-%s-%s" % (provider, slug)
    try:
        with open(path) as handle:
            lines = handle.read().splitlines()
    except FileNotFoundError:
        lines = []
    # One line per show title: the engine finds it again on any site, so the site it last played from is not a key.
    lines = [line for line in lines if key(line.split("\t")[2] if line.count("\t") >= 2 else "") != key(title)]
    lines.append("%s\t%s\t%s" % (episode, entry, title.replace("\t", " ")))
    handle, staging = tempfile.mkstemp(dir=directory)
    with os.fdopen(handle, "w") as out:
        out.write("\n".join(lines) + "\n")
    os.replace(staging, path)


def anicli(argv):
    """Hand the run to the real ani-cli (English, HiAnime), found past the run's own `ani-cli` link."""
    run_bin = os.path.join(os.environ.get("INIR_ANI_RUN", ""), "bin")
    path = os.pathsep.join(p for p in os.environ.get("PATH", "").split(os.pathsep) if os.path.realpath(p) != os.path.realpath(run_bin))
    real = shutil.which("ani-cli", path=path)
    if not real:
        die("ani-cli is not installed")
    os.execv(real, [real, *argv])


def player_args(label, stream, title, episode, skip, mal_id, audio):
    args = ["--referrer=" + stream.referer, "--user-agent=" + net.UA, "--ytdl=no",
            "--force-media-title=%s Episode %s" % (title, episode)]
    if stream.kind == "hls":
        args.append("--demuxer-lavf-o=extension_picky=0")
    track = providers.WatchAnimeWorld.TRACK.get(audio)
    if label["id"] == "watchanimeworld" and track:
        args.append("--alang=" + track)
    if stream.sub_url:
        args.append("--sub-file=" + stream.sub_url)
    if skip and mal_id:
        args += subprocess.run(["ani-skip", "-i", str(mal_id), "-e", str(episode)], capture_output=True, text=True).stdout.split()
    # Whatever a site sends, it is the last argument and never an option.
    return [*args, "--", stream.url]


def main(argv):
    audio, subs, source, quality, episode, skip, dub, words = "ja", "en", "ask", "best", "", False, False, []
    # "--subs=" keeps an empty value: a launcher that drops empty arguments would make "--subs" swallow the next flag.
    split = []
    for arg in argv:
        name, eq, value = arg.partition("=")
        split += [name, value] if eq and name in ("--audio", "--subs", "--source", "--quality", "--episode") else [arg]
    args = iter(split)
    for arg in args:
        if arg == "--audio":
            audio = next(args, audio)
        elif arg == "--subs":
            subs = next(args, subs)
        elif arg == "--source":
            source = next(args, source)
        elif arg == "--dub":
            dub = True
        elif arg == "--skip":
            skip = True
        elif arg in ("-q", "--quality"):
            quality = next(args, quality)
        elif arg in ("-e", "--episode"):
            episode = next(args, "")
        else:
            words.append(arg)
    if dub and audio == "ja":
        audio, subs = "en", ""
    if audio != "ja":
        subs = ""  # a dub has no burned-in subtitles to pick
    query = " ".join(words).strip()
    if not query:
        die("No results found!")
    try:
        meta = json.loads(os.environ.get("INIR_ANIME_META") or "{}")
    except ValueError:
        meta = {}
    meta = meta if isinstance(meta, dict) else {}

    own = providers.offering(audio, subs)
    english = (audio, subs) in (("en", ""), ("ja", "en"))
    if source == ANICLI or (english and not own):
        anicli((["--dub"] if audio == "en" else []) + (["--skip"] if skip else [])
               + (["-q", quality] if quality != "best" else []) + (["-e", episode] if episode else []) + words)
    if not own:
        die("No source plays %s audio%s" % (audio, " with %s subtitles" % subs if subs else ""))

    run = Run(audio, subs, source, quality, meta, query)
    shows = run.shows()
    if not shows:
        die("No results found!")
    lists = run.episodes(shows)
    if not lists:
        die("Invalid episode!")
    every = sorted({e for eps in lists.values() for e in eps}, key=lambda e: float(e) if re.match(r"^[\d.]+$", e) else 1e9)
    if not episode:
        episode = ask("Select episode: ", every)
        if not episode:
            die("Invalid episode selection")
    if episode not in every:
        die("Episode not released!")

    player = os.environ.get("ANI_CLI_PLAYER", "mpv")
    choice = None
    while True:
        if choice is None:
            options = run.options(shows, lists, episode)
            if not options:
                die("No sources found")
            choice = run.choose(options, episode)
        label, stream = choice
        show = shows[label["id"]]
        subprocess.run([player, *player_args(label, stream, query, episode, skip, meta.get("malId") or show.extra.get("malId"), audio)])
        history(label["id"], show.key, query, episode)

        at = every.index(episode)
        command = ask("Playing episode %s of %s... " % (episode, query),
                      ["next", "replay", "previous", "select", "change_quality", "quit"])
        if command == "next":
            episode = every[at + 1] if at + 1 < len(every) else ""
        elif command == "previous":
            episode = every[at - 1] if at > 0 else ""
        elif command == "select":
            episode = ask("Select episode: ", every)
        elif command == "change_quality":
            run.source = "ask"
        elif command != "replay":
            return 0
        if not episode:
            die("Out of range")
        if command != "replay":
            choice = None
