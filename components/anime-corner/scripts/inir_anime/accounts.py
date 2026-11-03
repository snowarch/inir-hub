"""AniList and MyAnimeList: your list in the Corner, and progress saved there when an episode ends.

Tokens come in the environment (INIR_ANILIST_TOKEN; INIR_MAL_TOKEN as the JSON the login printed) with the
person's own app ids (INIR_ANILIST_CLIENT, INIR_MAL_CLIENT); none is ever an argument or printed back, except a
MAL login or refresh, whose new tokens go to stdout for the shell to put in the keyring.

AniList: implicit grant with its PIN page (AniList has no PKCE, and the code grant needs a secret no app can ship),
so the person pastes the token. MAL: authorization code with PKCE; MAL only takes the plain method, so the
verifier itself travels through the browser to a listener on 127.0.0.1 that takes one request, checks the state,
and stops after five minutes at most.
"""

import http.server
import json
import os
import secrets
import sys
import time
import urllib.parse

from . import net

ANILIST = "https://graphql.anilist.co"
ANILIST_AUTH = "https://anilist.co/api/v2/oauth/authorize"
MAL_AUTH = "https://myanimelist.net/v1/oauth2/authorize"
MAL_TOKEN = "https://myanimelist.net/v1/oauth2/token"
MAL_API = "https://api.myanimelist.net/v2"
MAL_PUBLIC = "https://myanimelist.net/animelist/%s/load.json?status=7&offset=%d"
MAL_PORT = 47823
MAL_REDIRECT = "http://127.0.0.1:%d/callback" % MAL_PORT
STATUSES = ("CURRENT", "PLANNING", "COMPLETED", "PAUSED", "REPEATING", "DROPPED")
MAL_STATUS = {1: "CURRENT", 2: "COMPLETED", 3: "PAUSED", 4: "DROPPED", 6: "PLANNING"}
MAL_STATUS_NAME = {"watching": "CURRENT", "completed": "COMPLETED", "on_hold": "PAUSED", "dropped": "DROPPED",
                   "plan_to_watch": "PLANNING"}


def _anilist(query, variables, token=""):
    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    reply = json.loads(net.fetch(ANILIST, data=json.dumps({"query": query, "variables": variables}).encode(),
                                 headers=headers, timeout=15)[1])
    if reply.get("errors"):
        raise net.Failed(str(reply["errors"][0].get("message") or "AniList refused"))
    return reply.get("data") or {}


MEDIA = "id idMal title{romaji english} coverImage{large} episodes format status nextAiringEpisode{episode}"


def _shape(media, status, progress):
    title = media.get("title") or {}
    return {"id": media.get("id"), "idMal": media.get("idMal"), "title": title.get("english") or title.get("romaji") or "",
            "titleRomaji": title.get("romaji") or "", "titleEnglish": title.get("english") or "",
            "image": (media.get("coverImage") or {}).get("large") or "", "episodes": media.get("episodes") or "?",
            "type": media.get("format") or "", "listStatus": status, "progress": int(progress or 0)}


def anilist_viewer(token):
    data = _anilist("query{Viewer{id name avatar{medium}}}", {}, token)
    viewer = data.get("Viewer") or {}
    return {"id": viewer.get("id"), "name": viewer.get("name") or "", "avatar": (viewer.get("avatar") or {}).get("medium") or ""}


def anilist_list(token="", user=""):
    if token:
        user_id = anilist_viewer(token)["id"]
        args, variables = "userId:$u", {"u": user_id}
        declare = "$u:Int"
    else:
        args, variables, declare = "userName:$u", {"u": user}, "$u:String"
    query = "query(%s){MediaListCollection(%s,type:ANIME){lists{entries{status progress media{%s}}}}}" % (declare, args, MEDIA)
    try:
        data = _anilist(query, variables, token)
    except net.Failed as error:
        if str(error) == "HTTP 404":
            raise net.Failed("no such AniList user, or the list is private") from None
        raise
    out = []
    for group in (data.get("MediaListCollection") or {}).get("lists") or []:
        for entry in group.get("entries") or []:
            out.append(_shape(entry.get("media") or {}, entry.get("status") or "", entry.get("progress")))
    return out


def anilist_progress(token, anilist_id, episode):
    data = _anilist("mutation($m:Int,$p:Int){SaveMediaListEntry(mediaId:$m,progress:$p,status:CURRENT){id progress}}",
                    {"m": int(anilist_id), "p": int(episode)}, token)
    return {"saved": bool(data.get("SaveMediaListEntry"))}


def _mal_tokens():
    try:
        tokens = json.loads(os.environ.get("INIR_MAL_TOKEN") or "{}")
    except ValueError:
        tokens = {}
    return tokens if isinstance(tokens, dict) else {}


def _mal_exchange(fields):
    reply = json.loads(net.fetch(MAL_TOKEN, data=fields, headers={"Accept": "application/json"}, timeout=15)[1])
    if not reply.get("access_token"):
        raise net.Failed("MyAnimeList refused the login")
    return {"access": reply["access_token"], "refresh": reply.get("refresh_token") or "",
            "expires": int(time.time()) + int(reply.get("expires_in") or 3600)}


def mal_fresh(client):
    """A token that works, refreshed when it ran out; (tokens, renewed)."""
    tokens = _mal_tokens()
    if not tokens.get("access"):
        raise net.Failed("not connected to MyAnimeList")
    if int(tokens.get("expires") or 0) - 60 > time.time():
        return tokens, False
    if not client or not tokens.get("refresh"):
        raise net.Failed("the MyAnimeList login ran out")
    return _mal_exchange({"client_id": client, "grant_type": "refresh_token", "refresh_token": tokens["refresh"]}), True


def mal_list(client, user=""):
    """Your list (logged in), or anyone's public one by name, as AniList-shaped shows."""
    out = []
    if user:
        for offset in range(0, 3000, 300):
            batch = net.jsonof(MAL_PUBLIC % (urllib.parse.quote(user), offset), headers={"Accept": "application/json"})
            if not isinstance(batch, list) or not batch:
                break
            for item in batch:
                out.append({"idMal": item.get("anime_id"), "title": item.get("anime_title_eng") or item.get("anime_title") or "",
                            "titleRomaji": item.get("anime_title") or "", "titleEnglish": item.get("anime_title_eng") or "",
                            "image": item.get("anime_image_path") or "", "episodes": item.get("anime_num_episodes") or "?",
                            "listStatus": MAL_STATUS.get(item.get("status"), ""), "progress": int(item.get("num_watched_episodes") or 0)})
            if len(batch) < 300:
                break
        return out, None
    tokens, renewed = mal_fresh(client)
    url = MAL_API + "/users/@me/animelist?fields=list_status,num_episodes,alternative_titles&limit=1000&nsfw=true"
    while url and len(out) < 5000:
        page = net.jsonof(url, headers={"Authorization": "Bearer " + tokens["access"], "Accept": "application/json"})
        for item in page.get("data") or []:
            node, status = item.get("node") or {}, item.get("list_status") or {}
            english = ((node.get("alternative_titles") or {}).get("en")) or ""
            out.append({"idMal": node.get("id"), "title": english or node.get("title") or "", "titleRomaji": node.get("title") or "",
                        "titleEnglish": english, "image": (node.get("main_picture") or {}).get("large") or "",
                        "episodes": node.get("num_episodes") or "?", "listStatus": MAL_STATUS_NAME.get(status.get("status"), ""),
                        "progress": int(status.get("num_episodes_watched") or 0)})
        next_url = (page.get("paging") or {}).get("next")
        url = next_url if next_url and next_url.startswith(MAL_API + "/") else None
    return out, tokens if renewed else None


def mal_progress(client, mal_id, episode):
    tokens, renewed = mal_fresh(client)
    net.fetch(MAL_API + "/anime/%d/my_list_status" % int(mal_id), method="PATCH",
              data={"num_watched_episodes": int(episode), "status": "watching"},
              headers={"Authorization": "Bearer " + tokens["access"], "Accept": "application/json"})
    return {"saved": True}, tokens if renewed else None


def mal_login(client, opened=print, wait=300):
    """Prints the address to open first (one line), then waits for MAL to come back to 127.0.0.1."""
    if not client:
        raise net.Failed("no MyAnimeList client id")
    verifier = secrets.token_urlsafe(64)[:96]
    state = secrets.token_urlsafe(24)
    got = {}

    class Callback(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            query = urllib.parse.parse_qs(urllib.parse.urlsplit(self.path).query)
            if urllib.parse.urlsplit(self.path).path == "/callback" and secrets.compare_digest(
                    (query.get("state") or [""])[0], state):
                got["code"] = (query.get("code") or [""])[0]
                body = b"<!doctype html><meta charset=utf-8><title>iNiR</title><p>Connected. You can close this tab."
                self.send_response(200)
            else:
                body = b"<!doctype html><meta charset=utf-8><title>iNiR</title><p>This link is not the one iNiR opened."
                self.send_response(400)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *args):
            pass  # the request line carries the code; nothing is logged

    server = http.server.HTTPServer(("127.0.0.1", MAL_PORT), Callback)
    server.timeout = 5
    opened(MAL_AUTH + "?" + urllib.parse.urlencode({"response_type": "code", "client_id": client, "state": state,
                                                    "code_challenge": verifier, "code_challenge_method": "plain",
                                                    "redirect_uri": MAL_REDIRECT}))
    sys.stdout.flush()
    end = time.monotonic() + wait
    try:
        while "code" not in got and time.monotonic() < end:
            server.handle_request()
    finally:
        server.server_close()
    if not got.get("code"):
        raise net.Failed("the MyAnimeList login timed out")
    return _mal_exchange({"client_id": client, "grant_type": "authorization_code", "code": got["code"],
                          "code_verifier": verifier, "redirect_uri": MAL_REDIRECT})


def anilist_login_url(client):
    if not str(client).isdigit():
        raise net.Failed("no AniList client id")
    return ANILIST_AUTH + "?" + urllib.parse.urlencode({"client_id": client, "response_type": "token"})


def main(argv):
    """account anilist-url | anilist-viewer | list anilist|mal [user] | progress anilist|mal <id> <episode> | mal-login
    Output: one JSON object per line; {"tokens": ...} when MyAnimeList handed out new ones."""
    env = os.environ
    anilist_token = env.get("INIR_ANILIST_TOKEN", "").strip()
    mal_client = env.get("INIR_MAL_CLIENT", "").strip()

    def say(value):
        print(json.dumps(value, ensure_ascii=False))
        sys.stdout.flush()

    try:
        command = argv[0] if argv else ""
        if command == "anilist-url":
            say({"url": anilist_login_url(env.get("INIR_ANILIST_CLIENT", "").strip())})
        elif command == "anilist-viewer":
            say(anilist_viewer(anilist_token))
        elif command == "list" and argv[1:2] == ["anilist"]:
            user = argv[2] if len(argv) > 2 else ""
            say({"shows": anilist_list("" if user else anilist_token, user)})
        elif command == "list" and argv[1:2] == ["mal"]:
            shows, renewed = mal_list(mal_client, argv[2] if len(argv) > 2 else "")
            if renewed:
                say({"tokens": renewed})
            say({"shows": shows})
        elif command == "progress" and len(argv) == 4 and argv[1] == "anilist":
            say(anilist_progress(anilist_token, argv[2], argv[3]))
        elif command == "progress" and len(argv) == 4 and argv[1] == "mal":
            saved, renewed = mal_progress(mal_client, argv[2], argv[3])
            if renewed:
                say({"tokens": renewed})
            say(saved)
        elif command == "mal-login":
            say({"tokens": mal_login(mal_client, opened=lambda url: say({"open": url}))})
        else:
            print(main.__doc__, file=sys.stderr)
            return 2
    except (net.Failed, ValueError, KeyError, TypeError, OSError) as error:
        say({"error": str(error)})
        return 1
    return 0
