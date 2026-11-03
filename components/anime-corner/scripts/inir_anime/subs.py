"""Subtitles in any language from OpenSubtitles and SubDL, for the episode that is playing.

Each service needs the person's own free key. Keys arrive in the environment (INIR_OPENSUBTITLES_KEY,
INIR_SUBDL_KEY), never as arguments, and are never printed: what goes out is the list of subtitles, or a file path.
A download is a subtitle file or a zip of them; only subtitle files leave it, flattened into the run's folder.
"""

import io
import json
import os
import re
import sys
import urllib.parse
import zipfile

from . import net

OPENSUBTITLES = "https://api.opensubtitles.com/api/v1"
SUBDL = "https://api.subdl.com/api/v1/subtitles"
SUBDL_FILES = "https://dl.subdl.com"
# OpenSubtitles asks every app to name itself.
APP = "iNiR v2"
KINDS = (".srt", ".ass", ".ssa", ".vtt")
FILE_MAX = 5 * 1024 * 1024
ZIP_MAX = 20 * 1024 * 1024

# Our codes -> each service's.
OS_CODES = {"pt-BR": "pt-br", "es-419": "es", "zh": "zh-cn"}
SUBDL_CODES = {"en": "EN", "es": "ES", "es-419": "ES", "pt-BR": "BR_PT", "pt": "PT", "fr": "FR", "de": "DE", "it": "IT",
               "ar": "AR", "ru": "RU", "ja": "JA", "tr": "TR", "id": "ID", "vi": "VI", "ko": "KO", "zh": "ZH", "pl": "PL",
               "uk": "UK", "hi": "HI", "he": "HE"}


def _opensubtitles(key, title, season, episode, langs):
    query = {"query": title, "languages": ",".join(sorted({OS_CODES.get(l, l.lower()) for l in langs})),
             "episode_number": episode, "season_number": season or 1, "type": "episode"}
    reply = net.jsonof(OPENSUBTITLES + "/subtitles?" + "&".join("%s=%s" % (k, urllib.parse.quote(str(v)))
                                                                 for k, v in sorted(query.items())),
                       headers={"Api-Key": key, "User-Agent": APP, "Accept": "application/json"})
    out = []
    for item in reply.get("data") or []:
        a = item.get("attributes") or {}
        for f in (a.get("files") or [])[:1]:
            out.append({"service": "opensubtitles", "id": str(f.get("file_id")), "lang": a.get("language") or "",
                        "name": a.get("release") or f.get("file_name") or "", "downloads": int(a.get("download_count") or 0)})
    return out


def _subdl(key, title, season, episode, langs):
    codes = ",".join(sorted({SUBDL_CODES[l] for l in langs if l in SUBDL_CODES})) or "EN"
    query = {"api_key": key, "film_name": title, "type": "tv", "season_number": season or 1, "episode_number": episode,
             "languages": codes, "subs_per_page": 30}
    reply = net.jsonof(SUBDL + "?" + urllib.parse.urlencode(query), headers={"Accept": "application/json"})
    out = []
    for item in reply.get("subtitles") or []:
        url = str(item.get("url") or "")
        if re.match(r"^/subtitle/[\w.-]+\.zip$", url):
            out.append({"service": "subdl", "id": url, "lang": str(item.get("lang") or item.get("language") or ""),
                        "name": item.get("release_name") or item.get("name") or "", "downloads": 0})
    return out


def search(title, season, episode, langs):
    """Every subtitle both services have for this episode, preferred languages first. {"results": [...], "notes": [...]}"""
    keys = {"opensubtitles": os.environ.get("INIR_OPENSUBTITLES_KEY", "").strip(),
            "subdl": os.environ.get("INIR_SUBDL_KEY", "").strip()}
    readers = {"opensubtitles": _opensubtitles, "subdl": _subdl}
    asked = [name for name in readers if keys[name]]
    notes = ["no key for %s" % name for name in readers if not keys[name]]

    def one(name):
        try:
            return readers[name](keys[name], title, season, episode, langs)
        except net.Failed as error:
            refused = str(error) in ("HTTP 401", "HTTP 403")
            return "%s refused the key" % name if refused else "%s: %s" % (name, error)

    found = net.parallel(one, asked, 20)
    results = []
    for name, got in zip(asked, found):
        if got is None:
            notes.append("%s did not answer" % name)
        elif isinstance(got, str):
            notes.append(got)
        else:
            results += got
    order = {l.lower(): i for i, l in enumerate(langs)}
    results.sort(key=lambda r: (order.get(str(r["lang"]).lower(), order.get(str(r["lang"]).lower()[:2], 99)), -r["downloads"]))
    return {"results": results[:40], "notes": notes}


def _safe_name(name):
    base = os.path.basename(str(name).replace("\\", "/"))
    base = re.sub(r"[^\w.\- ]+", "_", base).strip(" .")[:120]
    return base or "subtitle.srt"


def _write(folder, name, data):
    if len(data) > FILE_MAX:
        raise net.Failed("subtitle too large")
    path = os.path.join(folder, _safe_name(name))
    with open(path, "wb") as out:
        out.write(data)
    return path


def unpack_zip(data, folder):
    """The first subtitle file in a zip, written flat into folder. Paths inside the zip are ignored; a zip that
    would grow past ZIP_MAX is refused before anything is read out of it."""
    try:
        archive = zipfile.ZipFile(io.BytesIO(data))
    except zipfile.BadZipFile:
        raise net.Failed("not a zip") from None
    members = [m for m in archive.infolist() if not m.is_dir() and m.filename.lower().endswith(KINDS)]
    if sum(m.file_size for m in archive.infolist()) > ZIP_MAX:
        raise net.Failed("zip too large")
    if not members:
        raise net.Failed("no subtitle in the zip")
    member = members[0]
    if member.file_size > FILE_MAX:
        raise net.Failed("subtitle too large")
    with archive.open(member) as handle:
        data = handle.read(FILE_MAX + 1)
    return _write(folder, member.filename, data)


def get(service, ident, folder):
    """Download one subtitle into folder (created 0700): its path."""
    os.makedirs(folder, mode=0o700, exist_ok=True)
    if service == "opensubtitles":
        key = os.environ.get("INIR_OPENSUBTITLES_KEY", "").strip()
        if not key or not ident.isdigit():
            raise net.Failed("no key for opensubtitles")
        reply = json.loads(net.fetch(OPENSUBTITLES + "/download", data=json.dumps({"file_id": int(ident)}).encode(),
                                     headers={"Api-Key": key, "User-Agent": APP, "Content-Type": "application/json",
                                              "Accept": "application/json"})[1])
        link = reply.get("link")
        if not link:
            raise net.Failed(str(reply.get("message") or "no download left today"))
        name = reply.get("file_name") or "opensubtitles.srt"
        data = net.fetch(link, limit=FILE_MAX)[1]
        return _write(folder, name if name.lower().endswith(KINDS) else name + ".srt", data)
    if service == "subdl":
        if not re.match(r"^/subtitle/[\w.-]+\.zip$", ident):
            raise net.Failed("bad subtitle id")
        return unpack_zip(net.fetch(SUBDL_FILES + ident, limit=ZIP_MAX)[1], folder)
    raise net.Failed("unknown service")


def main(argv):
    """subs search <title> <season> <episode> <lang,lang...> | subs get <service> <id> <folder>"""
    try:
        if argv[:1] == ["search"] and len(argv) == 5:
            from .engine import season_of
            langs = [l for l in argv[4].split(",") if l]
            season = int(argv[2] or 0) or season_of([argv[1]])
            print(json.dumps(search(argv[1], season, int(float(argv[3])), langs or ["en"]), ensure_ascii=False))
            return 0
        if argv[:1] == ["get"] and len(argv) == 4:
            print(get(argv[1], argv[2], argv[3]))
            return 0
    except (net.Failed, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 1
    print(main.__doc__, file=sys.stderr)
    return 2
