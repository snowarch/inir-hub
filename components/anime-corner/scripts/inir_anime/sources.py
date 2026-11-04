"""The person's sources: the Corner plays from none of its own.

Python files in $XDG_DATA_HOME/inir/anime-corner/sources/ (each sets SOURCES, and may set HOSTS and PAGE_FILTERS,
see sdk.py) and the Stremio add-ons saved in the Corner's settings. A file named _something.py is a helper the
others import. A file that fails to load is reported and skipped; the rest still play.
"""

import importlib
import os
import sys

from . import addons, hosts, providers

LOADED = []  # {"file", "sources", "error"} per file, for `inir-anime.py sources`


def folder():
    base = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
    return os.path.join(base, "inir", "anime-corner", "sources")


def load(where=None):
    where = os.path.abspath(where or folder())
    try:
        names = sorted(n for n in os.listdir(where) if n.endswith(".py") and not n.startswith("."))
    except OSError:
        names = []
    if names and where not in sys.path:
        sys.path.append(where)  # after Python's own modules: a file can't stand in for one
    for name in names:
        stem = name[:-3]
        row = {"file": name, "sources": [], "error": ""}
        try:
            module = importlib.import_module(stem)
            if os.path.dirname(os.path.abspath(getattr(module, "__file__", "") or "")) != where:
                raise ImportError("Python has a module of that name; rename the file")
            found = [p for p in getattr(module, "SOURCES", []) if isinstance(p, providers.Provider)]
            hosts.HOSTS.extend(h for h in getattr(module, "HOSTS", []) if h not in hosts.HOSTS)
            hosts.PAGE_FILTERS.extend(f for f in getattr(module, "PAGE_FILTERS", []) if f not in hosts.PAGE_FILTERS)
        except Exception as error:  # a broken file is its own row, never the Corner's crash
            row["error"] = "%s: %s" % (type(error).__name__, error)
            LOADED.append(row)
            continue
        row["sources"] = providers.add(found)
        if not stem.startswith("_"):
            if not found:
                row["error"] = "no SOURCES in it"
            LOADED.append(row)
    providers.add(addons.saved())
    return LOADED
