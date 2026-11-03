"""HTTPS only, bounded in time and size, nothing a page sends is ever run."""

import json
import urllib.error
import urllib.parse
import urllib.request

UA = "Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0"
LIMIT = 4 * 1024 * 1024
TIMEOUT = 12


class Failed(Exception):
    pass


class _SameHost(urllib.request.HTTPRedirectHandler):
    """Credentials never follow a redirect to another host."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        new = super().redirect_request(req, fp, code, msg, headers, newurl)
        if new is None:
            return None
        if not newurl.startswith("https://"):
            raise Failed("refused a redirect off HTTPS")
        if urllib.parse.urlsplit(newurl).hostname != urllib.parse.urlsplit(req.full_url).hostname:
            for name in ("Authorization", "Api-key", "X-mal-client-id"):
                new.headers.pop(name, None)
                new.unredirected_hdrs.pop(name, None)
        return new


_opener = urllib.request.build_opener(_SameHost)


def https(url):
    url = str(url or "").strip()
    if url.startswith("//"):
        url = "https:" + url
    elif url.startswith("http://"):
        url = "https://" + url[7:]
    if not url.startswith("https://"):
        raise Failed("not an https address")
    return url


def fetch(url, referer=None, data=None, headers=None, limit=LIMIT, timeout=TIMEOUT, method=None):
    """(final url, bytes). data: dict (form) or bytes. Raises Failed."""
    url = https(url)
    sent = {"User-Agent": UA}
    if referer:
        sent["Referer"] = referer
    sent.update(headers or {})
    if isinstance(data, dict):
        data = urllib.parse.urlencode(data).encode()
    request = urllib.request.Request(url, data=data, headers=sent, method=method)
    try:
        with _opener.open(request, timeout=timeout) as reply:
            body = reply.read(limit + 1)
            if len(body) > limit:
                raise Failed("reply too large")
            return reply.geturl(), body
    except urllib.error.HTTPError as error:
        raise Failed("HTTP %d" % error.code) from None
    except (urllib.error.URLError, OSError, ValueError) as error:
        raise Failed(str(getattr(error, "reason", error))) from None


def text(url, **kw):
    return fetch(url, **kw)[1].decode("utf-8", errors="replace")


def jsonof(url, **kw):
    try:
        return json.loads(fetch(url, **kw)[1])
    except ValueError:
        raise Failed("not JSON") from None


def alive(url, referer=None, headers=None):
    """Whether a stream answers: the first KiB of it."""
    try:
        fetch(url, referer=referer, headers=dict(headers or {}, Range="bytes=0-1023"), limit=1 << 20, timeout=8)
        return True
    except Failed:
        return False


def parallel(work, items, deadline):
    """[work(item) or None] in items' order; what isn't done within deadline seconds is None.
    Daemon threads, so a site still answering never holds the run (or its exit) back."""
    import threading
    import time

    items = list(items)
    out = [None] * len(items)

    def one(at, item):
        try:
            out[at] = work(item)
        except Exception:  # a site's failure is its own missing row
            out[at] = None

    threads = [threading.Thread(target=one, args=(at, item), daemon=True) for at, item in enumerate(items)]
    for thread in threads:
        thread.start()
    end = time.monotonic() + deadline
    for thread in threads:
        thread.join(max(0.0, end - time.monotonic()))
    return list(out)
